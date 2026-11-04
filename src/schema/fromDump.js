'use strict';
/**
 * Builds the same schema object as introspect.js, but from a mysqldump file instead of a live database.
 * The upload checker uses it so it never needs a database connection: columns, types, required flags, primary
 * keys, foreign keys and unique keys all come from the CREATE TABLE statements.
 *
 * The result is plain JSON (schema/avyra.schema.json), committed next to the code, so anyone who clones the repo
 * can check a workbook. When the database changes, take a fresh dump and run `npm run schema -- <dump.sql>`.
 */

const config = require('../config');
const { loadOrder, kindOf } = require('./introspect');

function tableKind(name) {
  if (name.startsWith(config.staticPrefix)) return 'static';
  if (name.startsWith(config.dynamicPrefix)) return 'dynamic';
  return null;
}

const unq = (s) => s.replace(/^`|`$/g, '').replace(/``/g, '`');
const colList = (s) => s.split(',').map((c) => unq(c.trim().replace(/\(\d+\)$/, '')));

/** One column line of a CREATE TABLE, e.g. "`city` varchar(45) DEFAULT NULL". */
function parseColumn(line) {
  const m = /^`((?:[^`]|``)+)`\s+([a-z]+)(\([^)]*\))?((?:\s+unsigned)?)(.*)$/i.exec(line);
  if (!m) return null;
  const [, rawName, dataTypeRaw, args = '', unsignedPart, rest] = m;
  const dataType = dataTypeRaw.toLowerCase();
  const columnType = `${dataType}${args}${unsignedPart ? ' unsigned' : ''}`;
  const notNull = /\bNOT NULL\b/i.test(rest);
  const autoIncrement = /\bAUTO_INCREMENT\b/i.test(rest);
  const generated = /\bGENERATED ALWAYS\b|\bAS \(/i.test(rest);
  const def = /\bDEFAULT\s+('(?:[^']|'')*'|[^\s,]+)/i.exec(rest);
  const defaultValue = def ? (def[1].toUpperCase() === 'NULL' ? null : def[1].replace(/^'|'$/g, '').replace(/''/g, "'")) : null;
  const nums = /\((\d+)(?:,(\d+))?\)/.exec(args);
  const isText = /char|text|enum|set|blob|binary/.test(dataType);
  const textMax = { tinytext: 255, text: 65535, mediumtext: 16777215, longtext: 4294967295 }[dataType];
  return {
    name: unq(`\`${rawName}\``),
    dataType,
    columnType,
    kind: kindOf(dataType),
    nullable: !notNull,
    hasDefault: !notNull || defaultValue !== null || autoIncrement,
    autoIncrement,
    generated,
    scale: /decimal|numeric/.test(dataType) ? Number(nums?.[2] || 0) : null,
    maxLength: isText ? (textMax ?? (nums ? Number(nums[1]) : null)) : null,
    unsigned: Boolean(unsignedPart),
    defaultValue,
    extra: autoIncrement ? 'auto_increment' : '',
    collation: null,
    comment: '',
  };
}

/** @param {string} sql  the whole dump  @returns {object} schema (same shape as introspect()) */
function schemaFromDump(sql, database = config.db.database) {
  const tables = {};
  const re = /CREATE TABLE `((?:[^`]|``)+)` \(([\s\S]*?)\n\)([^;]*);/g;
  let m;
  while ((m = re.exec(sql))) {
    const name = m[1];
    const kind = tableKind(name);
    if (!kind) continue;
    const t = {
      name,
      kind,
      columns: [],
      columnMap: {},
      primaryKey: [],
      foreignKeys: [],
      children: [],
      uniqueKeys: [],
      softDeleteColumns: [],
      nextId: Number((/AUTO_INCREMENT=(\d+)/.exec(m[3]) || [])[1] || 0) || null,
    };
    for (const raw of m[2].split('\n')) {
      const line = raw.trim().replace(/,$/, '');
      if (line.startsWith('`')) {
        const col = parseColumn(line);
        if (col) {
          t.columns.push(col);
          t.columnMap[col.name.toLowerCase()] = col;
        }
        continue;
      }
      let k;
      if ((k = /^PRIMARY KEY \((.+)\)/i.exec(line))) t.primaryKey = colList(k[1]);
      else if ((k = /^UNIQUE KEY `([^`]+)` \((.+?)\)/i.exec(line))) t.uniqueKeys.push({ name: k[1], columns: colList(k[2]) });
      else if ((k = /^CONSTRAINT `([^`]+)` FOREIGN KEY \(`([^`]+)`\) REFERENCES `([^`]+)` \(`([^`]+)`\)(.*)$/i.exec(line))) {
        const rule = (w) => ((new RegExp(`ON ${w} (CASCADE|SET NULL|RESTRICT|NO ACTION)`, 'i').exec(k[5]) || [])[1] || 'RESTRICT').toUpperCase();
        t.foreignKeys.push({ constraint: k[1], column: k[2], refTable: k[3], refColumn: k[4], onDelete: rule('DELETE'), onUpdate: rule('UPDATE') });
      }
    }
    tables[name] = t;
  }

  const problems = [];
  for (const t of Object.values(tables)) {
    for (const fk of t.foreignKeys) if (tables[fk.refTable]) tables[fk.refTable].children.push({ table: t.name, ...fk });
    // A unique index on just the primary key adds nothing.
    t.uniqueKeys = t.uniqueKeys.filter((u) => !(u.columns.length === 1 && t.primaryKey.length === 1 && u.columns[0] === t.primaryKey[0]));
    const lower = t.columns.map((c) => c.name.toLowerCase());
    for (const sd of config.softDeleteColumns) {
      const i = lower.indexOf(sd.toLowerCase());
      if (i >= 0) t.softDeleteColumns.push(t.columns[i].name);
    }
    if (t.primaryKey.length !== 1) {
      problems.push(`${t.name}: needs a single-column primary key (has ${t.primaryKey.length}); it will be read-only.`);
      t.readOnly = true;
    }
  }
  const { order, cyclic } = loadOrder(tables);
  order.forEach((n, i) => (tables[n].order = i));
  if (cyclic.length) problems.push(`FK cycle between: ${cyclic.join(', ')}.`);
  return { database, tables, order, problems, loadedAt: new Date().toISOString(), source: 'dump' };
}

/** Rebuilds columnMap after JSON.parse (it is derived, so it is not stored). */
function reviveSchema(json) {
  for (const t of Object.values(json.tables)) {
    t.columnMap = Object.fromEntries(t.columns.map((c) => [c.name.toLowerCase(), c]));
  }
  return json;
}

/** Strips derived fields so the committed JSON stays small and readable. */
function schemaToJson(schema) {
  const tables = {};
  for (const [n, t] of Object.entries(schema.tables)) {
    const { columnMap, children, ...rest } = t;
    tables[n] = rest;
  }
  return { database: schema.database, generatedAt: schema.loadedAt, order: schema.order, tables };
}

module.exports = { schemaFromDump, reviveSchema, schemaToJson, parseColumn };
