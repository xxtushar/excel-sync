'use strict';
/**
 * Compares a checked workbook (prepareWorkbook().data) with the database and works out exactly what saving it
 * would do: rows to add, cells to change, rows to delete. Nothing is written here.
 *
 * Only tables that are sheets in the file are touched, and only the columns in those sheets. A row that is in the
 * database but missing from its sheet is deleted, but only when nothing else still uses it: a delete that would
 * leave other rows pointing at nothing is refused, so the database's ON DELETE CASCADE never takes PGs, rooms or
 * beds with it.
 */

const crypto = require('crypto');
const { q } = require('../db/pool');
const { fromDbValue, sameValue } = require('../excel/normalize');

const MASS_DELETE_MIN_ROWS = 10;

const listIds = (ids, max = 10) => ids.slice(0, max).join(', ') + (ids.length > max ? ` and ${ids.length - max} more` : '');

/**
 * @param {object} db       mysql2 pool or connection
 * @param {object} schema   introspectDb()
 * @param {object[]} data   prepareWorkbook().data
 * @param {{ allowMassDelete?: boolean }} [opts]
 * @returns {Promise<{ tables: object[], errors: object[], warnings: object[], summary: object, hash: string }>}
 */
async function buildPlan(db, schema, data, { allowMassDelete = false } = {}) {
  const errors = [];
  const warnings = [];
  const inFile = new Map(data.map((d) => [d.table, d]));
  const plans = new Map();

  // ── What changes in each sheet's table ──
  for (const d of data) {
    const t = schema.tables[d.table];
    if (t.readOnly) {
      errors.push({ sheet: d.sheet, message: `${t.name} has no single-column primary key, so it can't be uploaded. Remove this sheet.` });
      continue;
    }
    const pk = t.primaryKey[0];
    const cols = [...new Set([pk, ...d.columns])];
    const [rows] = await db.query(`SELECT ${cols.map(q).join(', ')} FROM ${q(t.name)}`);
    const pkCol = t.columnMap[pk.toLowerCase()];
    const inDb = new Map(rows.map((r) => [String(fromDbValue(pkCol, r[pk])), r]));

    const plan = { table: t.name, sheet: d.sheet, kind: t.kind, columns: d.columns, inserts: [], updates: [], deletes: [], dbCount: rows.length };
    const inSheet = new Set();
    for (const row of d.rows) {
      const id = row.values[pk];
      inSheet.add(String(id));
      const existing = inDb.get(String(id));
      if (!existing) {
        plan.inserts.push({ row: row.row, id, values: row.values });
        continue;
      }
      const changes = {};
      for (const c of d.columns) {
        if (c === pk) continue;
        const col = t.columnMap[c.toLowerCase()];
        const from = fromDbValue(col, existing[c]);
        const to = row.values[c] ?? null;
        if (!sameValue(col, from, to)) changes[c] = { from, to };
      }
      if (Object.keys(changes).length) plan.updates.push({ row: row.row, id, changes });
    }
    for (const [key, r] of inDb) if (!inSheet.has(key)) plan.deletes.push({ id: fromDbValue(pkCol, r[pk]) });

    if (plan.deletes.length >= MASS_DELETE_MIN_ROWS && plan.deletes.length * 2 >= rows.length && !allowMassDelete) {
      errors.push({
        sheet: d.sheet,
        message: `This would delete ${plan.deletes.length} of the ${rows.length} rows in ${t.name}. That usually means rows were cleared or filtered out by mistake. Put them back, or preview again with allowMassDelete=true if you really mean it.`,
      });
    }
    plans.set(t.name, plan);
  }

  // ── Ids that point at tables not in the file must exist in the database ──
  for (const plan of plans.values()) {
    const t = schema.tables[plan.table];
    const d = inFile.get(plan.table);
    for (const fk of t.foreignKeys) {
      if (!plan.columns.includes(fk.column) || inFile.has(fk.refTable)) continue;
      const uses = [];
      for (const ins of plan.inserts) if (ins.values[fk.column] != null) uses.push({ row: ins.row, v: ins.values[fk.column] });
      for (const up of plan.updates) if (up.changes[fk.column] && up.changes[fk.column].to != null) uses.push({ row: up.row, v: up.changes[fk.column].to });
      if (!uses.length) continue;
      const values = [...new Set(uses.map((u) => u.v))];
      const [found] = await db.query(`SELECT ${q(fk.refColumn)} AS v FROM ${q(fk.refTable)} WHERE ${q(fk.refColumn)} IN (?)`, [values]);
      const ok = new Set(found.map((r) => String(r.v)));
      for (const u of uses)
        if (!ok.has(String(u.v)))
          errors.push({ sheet: plan.sheet, row: u.row, column: fk.column, cell: `${d.cellOf[fk.column]}${u.row}`, message: `${fk.column} = ${u.v}, but ${fk.refTable} has no row with ${fk.refColumn} ${u.v}.` });
    }
  }

  // ── Deletes are only allowed when nothing still uses the row ──
  for (const plan of plans.values()) {
    if (!plan.deletes.length) continue;
    const t = schema.tables[plan.table];
    const ids = plan.deletes.map((x) => x.id);
    for (const child of t.children) {
      const c = schema.tables[child.table];
      const childPlan = plans.get(child.table);
      // A child sheet that has this column was already checked against the file by prepareWorkbook.
      if (childPlan && childPlan.columns.includes(child.column)) continue;
      const [rows] = await db.query(`SELECT ${q(c.primaryKey[0] || child.column)} AS id, ${q(child.column)} AS ref FROM ${q(child.table)} WHERE ${q(child.column)} IN (?)`, [ids]);
      const deletedThere = new Set(childPlan ? childPlan.deletes.map((x) => String(x.id)) : []);
      const still = rows.filter((r) => !deletedThere.has(String(r.id)));
      const byRef = new Map();
      for (const r of still) byRef.set(String(r.ref), [...(byRef.get(String(r.ref)) || []), r.id]);
      for (const [ref, users] of byRef)
        errors.push({
          sheet: plan.sheet,
          message: `Can't delete ${plan.table} id ${ref}: ${users.length} row(s) in ${child.table} still use it (${child.column}; ids ${listIds(users)}). Change those rows first, or keep this row in the sheet.`,
        });
    }
  }

  const tables = [...plans.values()].sort((a, b) => schema.tables[a.table].order - schema.tables[b.table].order);
  const summary = {
    inserts: tables.reduce((n, p) => n + p.inserts.length, 0),
    updates: tables.reduce((n, p) => n + p.updates.length, 0),
    deletes: tables.reduce((n, p) => n + p.deletes.length, 0),
  };
  summary.tablesChanged = tables.filter((p) => p.inserts.length + p.updates.length + p.deletes.length).length;
  for (const p of tables) if (p.deletes.length) warnings.push({ sheet: p.sheet, message: `${p.deletes.length} row(s) of ${p.table} are not in the sheet and will be deleted: ids ${listIds(p.deletes.map((x) => x.id))}.` });

  const hash = crypto
    .createHash('sha256')
    .update(JSON.stringify(tables.map((p) => [p.table, p.inserts.map((i) => i.values), p.updates.map((u) => [u.id, u.changes]), p.deletes.map((x) => x.id)])))
    .digest('hex');
  return { tables, errors, warnings, summary, hash };
}

/** The plan as the API shows it: counts per table plus every change, without internal fields. */
function describePlan(plan) {
  return plan.tables
    .filter((p) => p.inserts.length + p.updates.length + p.deletes.length)
    .map((p) => ({
      table: p.table,
      counts: { inserts: p.inserts.length, updates: p.updates.length, deletes: p.deletes.length },
      inserts: p.inserts.map((i) => ({ row: i.row, id: i.id, values: i.values })),
      updates: p.updates.map((u) => ({ row: u.row, id: u.id, changes: u.changes })),
      deletes: p.deletes.map((x) => x.id),
    }));
}

module.exports = { buildPlan, describePlan, MASS_DELETE_MIN_ROWS };
