'use strict';
/**
 * Reads the live database's table definitions from INFORMATION_SCHEMA, in the same shape as
 * schema/avyra.schema.json (fromDump.js), so the checker and the API agree on columns, types and links.
 * Reading the live database (not the committed JSON) means a column added there is picked up at once.
 */

const config = require('../config');
const { kindOf, loadOrder } = require('../schema/introspect');

function tableKind(name) {
  if (name.startsWith(config.staticPrefix)) return 'static';
  if (name.startsWith(config.dynamicPrefix)) return 'dynamic';
  return null;
}

async function introspectDb(db, database) {
  const [colRows] = await db.query(
    `SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, EXTRA,
            NUMERIC_SCALE, CHARACTER_MAXIMUM_LENGTH, COLUMN_KEY
       FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? ORDER BY TABLE_NAME, ORDINAL_POSITION`,
    [database]
  );
  const [fkRows] = await db.query(
    `SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
       FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = ? AND REFERENCED_TABLE_NAME IS NOT NULL`,
    [database]
  );
  const [uniqueRows] = await db.query(
    `SELECT TABLE_NAME, INDEX_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS cols
       FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = ? AND NON_UNIQUE = 0 AND INDEX_NAME <> 'PRIMARY'
      GROUP BY TABLE_NAME, INDEX_NAME`,
    [database]
  );
  const [autoRows] = await db.query(
    'SELECT TABLE_NAME, AUTO_INCREMENT FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ?',
    [database]
  );
  const nextIds = Object.fromEntries(autoRows.map((r) => [r.TABLE_NAME, r.AUTO_INCREMENT == null ? null : Number(r.AUTO_INCREMENT)]));

  const tables = {};
  for (const r of colRows) {
    const kind = tableKind(r.TABLE_NAME);
    if (!kind) continue;
    const t = (tables[r.TABLE_NAME] ||= {
      name: r.TABLE_NAME, kind, columns: [], columnMap: {}, primaryKey: [], foreignKeys: [], children: [],
      uniqueKeys: [], softDeleteColumns: [], nextId: nextIds[r.TABLE_NAME] ?? null,
    });
    const extra = r.EXTRA || '';
    const col = {
      name: r.COLUMN_NAME,
      dataType: r.DATA_TYPE,
      columnType: r.COLUMN_TYPE,
      kind: kindOf(r.DATA_TYPE),
      nullable: r.IS_NULLABLE === 'YES',
      hasDefault: r.COLUMN_DEFAULT !== null || r.IS_NULLABLE === 'YES' || /auto_increment|DEFAULT_GENERATED/i.test(extra),
      autoIncrement: /auto_increment/i.test(extra),
      generated: /VIRTUAL GENERATED|STORED GENERATED|VIRTUAL|PERSISTENT/i.test(extra) && !/DEFAULT_GENERATED/i.test(extra),
      scale: r.NUMERIC_SCALE == null ? null : Number(r.NUMERIC_SCALE),
      maxLength: r.CHARACTER_MAXIMUM_LENGTH == null ? null : Number(r.CHARACTER_MAXIMUM_LENGTH),
      unsigned: /unsigned/i.test(r.COLUMN_TYPE),
      defaultValue: r.COLUMN_DEFAULT,
      extra,
    };
    t.columns.push(col);
    t.columnMap[col.name.toLowerCase()] = col;
    if (r.COLUMN_KEY === 'PRI') t.primaryKey.push(col.name);
  }
  for (const r of fkRows) {
    const t = tables[r.TABLE_NAME];
    if (!t) continue;
    const fk = { constraint: r.CONSTRAINT_NAME, column: r.COLUMN_NAME, refTable: r.REFERENCED_TABLE_NAME, refColumn: r.REFERENCED_COLUMN_NAME };
    t.foreignKeys.push(fk);
  }
  for (const t of Object.values(tables)) for (const fk of t.foreignKeys) if (tables[fk.refTable]) tables[fk.refTable].children.push({ table: t.name, ...fk });
  for (const r of uniqueRows) {
    const t = tables[r.TABLE_NAME];
    if (!t) continue;
    const cols = String(r.cols).split(',');
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
      problems.push(`${t.name}: needs a single-column primary key, so it can't be uploaded.`);
      t.readOnly = true;
    }
  }
  const { order } = loadOrder(tables);
  order.forEach((n, i) => (tables[n].order = i));
  return { database, tables, order, problems, loadedAt: new Date().toISOString(), source: 'database' };
}

module.exports = { introspectDb };
