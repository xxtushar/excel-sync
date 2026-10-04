'use strict';
/**
 * Compares each sheet with its table (matched on the primary key) and builds a change plan.
 * Nothing is written here. The plan is what /preview returns and what apply.js executes.
 */

const config = require('../config');
const { q } = require('../db');
const { fromDbValue, sameValue } = require('../excel/normalize');
const { cascadeImpact } = require('./cascade');

const MASS_DELETE_RATIO = 0.5;
const MASS_DELETE_MIN_ROWS = 10;

async function fetchRows(conn, table, columns) {
  const [rows] = await conn.query(`SELECT ${columns.map(q).join(', ')} FROM ${q(table.name)}`);
  const pk = table.primaryKey[0];
  const pkCol = table.columnMap[pk.toLowerCase()];
  const map = new Map();
  for (const r of rows) {
    const norm = {};
    for (const c of columns) norm[c] = fromDbValue(table.columnMap[c.toLowerCase()], r[c]);
    map.set(String(fromDbValue(pkCol, r[pk])), norm);
  }
  return map;
}

function isSoftDeleted(table, dbRow) {
  return table.softDeleteColumns.length > 0 && table.softDeleteColumns.every((c) => dbRow[c] !== null && Number(dbRow[c]) === 0);
}

/**
 * @param conn      mysql2 connection
 * @param schema    from introspect()
 * @param workbook  from readWorkbook()
 * @param opts      { states, full, deleteMode, allowMassDelete }
 */
async function buildPlan(conn, schema, workbook, opts = {}) {
  const deleteMode = opts.deleteMode || config.deleteMode;
  const states = opts.states || {};
  const errors = [];
  const warnings = [];
  const tables = [];

  const sheets = [...workbook.sheets].sort((a, b) => schema.tables[a.table].order - schema.tables[b.table].order);

  for (const sheet of sheets) {
    const table = schema.tables[sheet.table];
    const pk = table.primaryKey[0];
    const pkCol = table.columnMap[pk.toLowerCase()];
    const entry = {
      table: table.name,
      sheet: sheet.sheetName,
      kind: table.kind,
      status: 'changed',
      sheetRows: sheet.rows.length,
      dbRows: 0,
      inserts: [],
      updates: [],
      softDeletes: [],
      hardDeletes: [],
      notDeleted: [],
      cascade: null,
      hash: sheet.hash,
    };
    tables.push(entry);

    if (sheet.hasErrors) {
      entry.status = 'invalid';
      continue;
    }
    if (!opts.full && states[table.name] && states[table.name].sheet_hash === sheet.hash) {
      entry.status = 'unchanged';
      continue;
    }

    const fetchCols = [...new Set([pk, ...sheet.columns, ...table.softDeleteColumns])];
    const dbRows = await fetchRows(conn, table, fetchCols);
    entry.dbRows = dbRows.size;

    // Next free id, for blank-id rows.
    let nextId = 1;
    for (const k of dbRows.keys()) if (Number(k) >= nextId) nextId = Number(k) + 1;
    for (const r of sheet.rows) if (r.values[pk] != null && Number(r.values[pk]) >= nextId) nextId = Number(r.values[pk]) + 1;

    // Required columns that the sheet does not carry at all.
    const missingRequired = table.columns
      .filter((c) => !c.nullable && !c.hasDefault && !c.autoIncrement && !c.generated && !sheet.columns.includes(c.name))
      .map((c) => c.name);

    const seen = new Set();
    for (const row of sheet.rows) {
      const id = row.values[pk];
      const where = { sheet: sheet.sheetName, row: row.rowNumber };

      if (id === null || id === undefined) {
        if (config.blankIdMode !== 'insert' || !pkCol.autoIncrement) {
          errors.push({ ...where, column: pk, message: `Empty ${pk}. Type an id for this new row, e.g. ${nextId}.` });
          nextId++;
          continue;
        }
        warnings.push({
          ...where,
          message: 'Inserted with an automatic id. Copy the new id into the sheet, or the row is inserted again next time.',
        });
      }

      const dbRow = id != null ? dbRows.get(String(id)) : undefined;
      if (id != null) seen.add(String(id));

      if (!dbRow) {
        // INSERT
        const values = {};
        let bad = false;
        for (const c of sheet.columns) {
          const v = row.values[c];
          if (v === null && row.nullRequired.includes(c)) {
            const col = table.columnMap[c.toLowerCase()];
            if (col.hasDefault) continue; // let MySQL fill its default
            errors.push({ ...where, column: c, message: `${c} is required for a new row.` });
            bad = true;
            continue;
          }
          if (c === pk && v == null) continue;
          values[c] = v;
        }
        if (missingRequired.length) {
          errors.push({ ...where, message: `New row, but the sheet has no ${missingRequired.join(', ')} column(s), which are required.` });
          bad = true;
        }
        if (!bad) entry.inserts.push({ id, rowNumber: row.rowNumber, values });
        continue;
      }

      // UPDATE (only the columns that differ)
      const set = {};
      const before = {};
      for (const c of sheet.columns) {
        if (c === pk) continue;
        const col = table.columnMap[c.toLowerCase()];
        if (!sameValue(col, row.values[c], dbRow[c])) {
          if (row.values[c] === null && row.nullRequired.includes(c)) {
            errors.push({ ...where, column: c, message: `${c} cannot be empty.` });
            continue;
          }
          set[c] = row.values[c];
          before[c] = dbRow[c];
        }
      }
      if (Object.keys(set).length) entry.updates.push({ id, rowNumber: row.rowNumber, set, before });
    }

    // Rows in the DB that are no longer in the sheet.
    const missing = [...dbRows.keys()].filter((k) => !seen.has(k));
    if (missing.length) {
      if (table.kind === 'static' || deleteMode === 'none') {
        entry.notDeleted = missing;
        if (table.kind === 'static')
          warnings.push({ sheet: sheet.sheetName, message: `${missing.length} row(s) are in the DB but not in the sheet. Static tables are never deleted from; left as is.` });
      } else {
        for (const k of missing) {
          const dbRow = dbRows.get(k);
          if (table.softDeleteColumns.length) {
            if (!isSoftDeleted(table, dbRow)) entry.softDeletes.push({ id: k, columns: table.softDeleteColumns });
          } else if (deleteMode === 'hard') {
            entry.hardDeletes.push({ id: k });
          } else {
            entry.notDeleted.push(k);
          }
        }
        if (entry.notDeleted.length)
          warnings.push({
            sheet: sheet.sheetName,
            message: `${entry.notDeleted.length} row(s) removed from the sheet were kept: ${table.name} has no soft-delete column. Use deleteMode=hard to delete them (cascades to child tables).`,
          });
      }

      const removing = entry.softDeletes.length + entry.hardDeletes.length;
      if (
        !opts.allowMassDelete &&
        removing >= MASS_DELETE_MIN_ROWS &&
        removing / Math.max(1, dbRows.size) >= MASS_DELETE_RATIO
      ) {
        errors.push({
          sheet: sheet.sheetName,
          message: `This would remove ${removing} of ${dbRows.size} rows from ${table.name}. If that is intended, re-run with allowMassDelete=true.`,
        });
      }
    }

    if (entry.hardDeletes.length) {
      entry.cascade = await cascadeImpact(conn, schema, table.name, entry.hardDeletes.map((d) => d.id));
      if (entry.cascade.total)
        warnings.push({
          sheet: sheet.sheetName,
          message: `Hard-deleting ${entry.hardDeletes.length} row(s) also deletes ${entry.cascade.total} child row(s): ${Object.entries(entry.cascade.cascade).map(([t, n]) => `${t} ${n}`).join(', ')}.`,
        });
    }

    if (!entry.inserts.length && !entry.updates.length && !entry.softDeletes.length && !entry.hardDeletes.length)
      entry.status = 'no-changes';
  }

  await checkForeignKeys(conn, schema, tables, errors);
  checkCascadeAgainstSheets(schema, workbook, tables, errors);

  return { tables, errors, warnings };
}

/**
 * A hard delete cascades in MySQL. If a cascaded child row is still listed in its own sheet, the DB and the
 * workbook would disagree right after the sync (and the next sync would re-insert it). Refuse instead.
 */
function checkCascadeAgainstSheets(schema, workbook, planTables, errors) {
  const sheetIds = {};
  for (const s of workbook.sheets) {
    const pk = schema.tables[s.table].primaryKey[0];
    sheetIds[s.table] = { sheet: s.sheetName, rows: new Set(s.rows.map((r) => String(r.values[pk]))) };
  }
  for (const p of planTables) {
    if (!p.cascade || !p.cascade.ids) continue;
    for (const [child, ids] of Object.entries(p.cascade.ids)) {
      const s = sheetIds[child];
      if (!s) continue;
      const still = ids.filter((id) => s.rows.has(String(id)));
      if (still.length)
        errors.push({
          sheet: s.sheet,
          message: `Deleting rows from ${p.table} would cascade-delete ${child} id(s) ${still.slice(0, 20).join(', ')}${still.length > 20 ? '…' : ''}, which are still in this sheet. Remove them from the sheet too (or keep the parent).`,
        });
    }
  }
}

/**
 * Every FK value written by the plan must point at a row that will exist afterwards:
 * existing DB rows + rows inserted in this sync − rows hard-deleted in this sync.
 * Catching this here gives "sheet X row 12: pg_id 99 not found in dy_pg_info" instead of a MySQL error.
 */
async function checkForeignKeys(conn, schema, planTables, errors) {
  const byTable = Object.fromEntries(planTables.map((t) => [t.table, t]));
  const idCache = new Map();
  async function finalIds(tableName) {
    if (idCache.has(tableName)) return idCache.get(tableName);
    const t = schema.tables[tableName];
    const pk = t.primaryKey[0];
    const [rows] = await conn.query(`SELECT ${q(pk)} AS id FROM ${q(tableName)}`);
    const set = new Set(rows.map((r) => String(r.id)));
    const p = byTable[tableName];
    if (p) {
      p.inserts.forEach((i) => i.id != null && set.add(String(i.id)));
      p.hardDeletes.forEach((d) => set.delete(String(d.id)));
    }
    idCache.set(tableName, set);
    return set;
  }

  for (const p of planTables) {
    const t = schema.tables[p.table];
    if (!t.foreignKeys.length) continue;
    const writes = [
      ...p.inserts.map((i) => ({ rowNumber: i.rowNumber, values: i.values })),
      ...p.updates.map((u) => ({ rowNumber: u.rowNumber, values: u.set })),
    ];
    for (const fk of t.foreignKeys) {
      if (!schema.tables[fk.refTable]) continue;
      const ids = await finalIds(fk.refTable);
      for (const w of writes) {
        if (!(fk.column in w.values)) continue;
        const v = w.values[fk.column];
        if (v === null || v === undefined) continue;
        if (!ids.has(String(v)))
          errors.push({
            sheet: p.sheet,
            row: w.rowNumber,
            column: fk.column,
            message: `${fk.column} = ${v}, but ${fk.refTable} has no row with ${fk.refColumn} ${v}.`,
          });
      }
    }
  }
}

function totals(plan) {
  const t = { inserted: 0, updated: 0, softDeleted: 0, hardDeleted: 0, cascaded: 0, tablesChanged: 0 };
  for (const e of plan.tables) {
    t.inserted += e.inserts.length;
    t.updated += e.updates.length;
    t.softDeleted += e.softDeletes.length;
    t.hardDeleted += e.hardDeletes.length;
    t.cascaded += e.cascade ? e.cascade.total : 0;
    if (e.status === 'changed') t.tablesChanged++;
  }
  return t;
}

module.exports = { buildPlan, totals };
