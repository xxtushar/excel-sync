'use strict';
/**
 * Reads the live schema from INFORMATION_SCHEMA so nothing about the 51 tables is hardcoded.
 * Produces, per table: columns + types, primary key, outgoing FKs, incoming FKs (children),
 * soft-delete columns, static/dynamic kind, and a load order (parents before children).
 */

const config = require('../config');

const INTEGER_TYPES = new Set(['tinyint', 'smallint', 'mediumint', 'int', 'integer', 'bigint', 'year']);
const FLOAT_TYPES = new Set(['float', 'double', 'real']);
const DECIMAL_TYPES = new Set(['decimal', 'numeric']);
const DATETIME_TYPES = new Set(['datetime', 'timestamp']);
const DATE_TYPES = new Set(['date']);
const TIME_TYPES = new Set(['time']);

function kindOf(dataType) {
  if (INTEGER_TYPES.has(dataType)) return 'integer';
  if (FLOAT_TYPES.has(dataType)) return 'float';
  if (DECIMAL_TYPES.has(dataType)) return 'decimal';
  if (DATETIME_TYPES.has(dataType)) return 'datetime';
  if (DATE_TYPES.has(dataType)) return 'date';
  if (TIME_TYPES.has(dataType)) return 'time';
  if (dataType === 'json') return 'json';
  if (dataType === 'bit') return 'integer';
  return 'string';
}

function tableKind(name) {
  if (name.startsWith(config.staticPrefix)) return 'static';
  if (name.startsWith(config.dynamicPrefix)) return 'dynamic';
  return null;
}

/**
 * Kahn topological sort over FK edges (parent -> child). Ties are broken static-first, then by name,
 * so the order is stable. Self references are ignored; real cycles are reported.
 */
function loadOrder(tables) {
  const names = Object.keys(tables);
  const indeg = Object.fromEntries(names.map((n) => [n, 0]));
  const edges = Object.fromEntries(names.map((n) => [n, new Set()]));
  for (const t of Object.values(tables)) {
    for (const fk of t.foreignKeys) {
      if (fk.refTable === t.name || !tables[fk.refTable]) continue;
      if (!edges[fk.refTable].has(t.name)) {
        edges[fk.refTable].add(t.name);
        indeg[t.name]++;
      }
    }
  }
  const rank = (n) => (tables[n].kind === 'static' ? '0' : '1') + n;
  const ready = names.filter((n) => indeg[n] === 0).sort((a, b) => rank(a).localeCompare(rank(b)));
  const order = [];
  while (ready.length) {
    const n = ready.shift();
    order.push(n);
    for (const c of edges[n]) {
      if (--indeg[c] === 0) {
        ready.push(c);
        ready.sort((a, b) => rank(a).localeCompare(rank(b)));
      }
    }
  }
  const cyclic = names.filter((n) => !order.includes(n));
  return { order: order.concat(cyclic.sort()), cyclic };
}

async function introspect(pool, database) {
  const [colRows] = await pool.query(
    `SELECT TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION, DATA_TYPE, COLUMN_TYPE, IS_NULLABLE,
            COLUMN_DEFAULT, EXTRA, NUMERIC_SCALE, CHARACTER_MAXIMUM_LENGTH, COLUMN_KEY
       FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = ?
      ORDER BY TABLE_NAME, ORDINAL_POSITION`,
    [database]
  );
  const [fkRows] = await pool.query(
    `SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
       FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
      WHERE TABLE_SCHEMA = ? AND REFERENCED_TABLE_NAME IS NOT NULL`,
    [database]
  );
  const [ruleRows] = await pool.query(
    `SELECT CONSTRAINT_NAME, TABLE_NAME, DELETE_RULE, UPDATE_RULE
       FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS
      WHERE CONSTRAINT_SCHEMA = ?`,
    [database]
  );
  const [uniqueRows] = await pool.query(
    `SELECT TABLE_NAME, INDEX_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS cols
       FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = ? AND NON_UNIQUE = 0 AND INDEX_NAME <> 'PRIMARY'
      GROUP BY TABLE_NAME, INDEX_NAME`,
    [database]
  );

  const tables = {};
  for (const r of colRows) {
    const kind = tableKind(r.TABLE_NAME);
    if (!kind) continue;
    const t = (tables[r.TABLE_NAME] ||= {
      name: r.TABLE_NAME,
      kind,
      columns: [],
      columnMap: {},
      primaryKey: [],
      foreignKeys: [],
      children: [],
      uniqueKeys: [],
      softDeleteColumns: [],
    });
    const col = {
      name: r.COLUMN_NAME,
      dataType: r.DATA_TYPE,
      columnType: r.COLUMN_TYPE,
      kind: kindOf(r.DATA_TYPE),
      nullable: r.IS_NULLABLE === 'YES',
      hasDefault: r.COLUMN_DEFAULT !== null || r.IS_NULLABLE === 'YES' || /auto_increment|DEFAULT_GENERATED/i.test(r.EXTRA),
      autoIncrement: /auto_increment/i.test(r.EXTRA),
      generated: /VIRTUAL GENERATED|STORED GENERATED/i.test(r.EXTRA),
      scale: r.NUMERIC_SCALE == null ? null : Number(r.NUMERIC_SCALE),
      maxLength: r.CHARACTER_MAXIMUM_LENGTH == null ? null : Number(r.CHARACTER_MAXIMUM_LENGTH),
      unsigned: /unsigned/i.test(r.COLUMN_TYPE),
    };
    t.columns.push(col);
    t.columnMap[col.name.toLowerCase()] = col;
    if (r.COLUMN_KEY === 'PRI') t.primaryKey.push(col.name);
  }

  const rules = Object.fromEntries(ruleRows.map((r) => [`${r.TABLE_NAME}.${r.CONSTRAINT_NAME}`, r]));
  for (const r of fkRows) {
    const t = tables[r.TABLE_NAME];
    if (!t) continue;
    const rule = rules[`${r.TABLE_NAME}.${r.CONSTRAINT_NAME}`] || {};
    const fk = {
      constraint: r.CONSTRAINT_NAME,
      column: r.COLUMN_NAME,
      refTable: r.REFERENCED_TABLE_NAME,
      refColumn: r.REFERENCED_COLUMN_NAME,
      onDelete: rule.DELETE_RULE || 'RESTRICT',
      onUpdate: rule.UPDATE_RULE || 'RESTRICT',
    };
    t.foreignKeys.push(fk);
    if (tables[fk.refTable]) tables[fk.refTable].children.push({ table: t.name, ...fk });
  }

  for (const r of uniqueRows) {
    const t = tables[r.TABLE_NAME];
    if (!t) continue;
    const cols = String(r.cols).split(',');
    // A unique index on just the primary key adds nothing.
    if (cols.length === 1 && t.primaryKey.length === 1 && cols[0] === t.primaryKey[0]) continue;
    t.uniqueKeys.push({ name: r.INDEX_NAME, columns: cols });
  }

  const problems = [];
  for (const t of Object.values(tables)) {
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
  if (cyclic.length) problems.push(`FK cycle between: ${cyclic.join(', ')}. These load last.`);

  return { database, tables, order, problems, loadedAt: new Date().toISOString() };
}

/** Case-insensitive table lookup restricted to managed (st_/dy_) tables. */
function findTable(schema, name) {
  if (!name) return null;
  if (schema.tables[name]) return schema.tables[name];
  const lower = String(name).toLowerCase();
  return Object.values(schema.tables).find((t) => t.name.toLowerCase() === lower) || null;
}

module.exports = { introspect, findTable, loadOrder, kindOf };
