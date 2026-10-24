'use strict';
/**
 * Lookup columns: a foreign key to a table listed in LOOKUPS shows the row's name in the workbook (not its id), gets
 * a dropdown of the active names (kept on a hidden "Lookups" sheet, with each id beside it), and the import turns
 * the name back into the id. A name used by several rows is shown with its qualifier, e.g. "bilaspur (Chhattisgarh)".
 */

const { q } = require('../db');

// table → its name column, the column that marks a row active (inactive rows stay valid, just not offered), and
// where to find the text that tells rows with the same name apart
const LOOKUPS = {
  st_pg_ctys: { label: 'city', active: 'rstatus', qualify: { column: 'state_id', table: 'st_pg_state', label: 'name' } },
};

const LOOKUP_SHEET = 'Lookups';

const norm = (s) => String(s ?? '').trim().toLowerCase();

/** @returns {Promise<object>} table → [{ id, name, label, active }], for the lookup tables that exist in the schema */
async function loadLookups(db, schema) {
  const out = {};
  for (const [table, l] of Object.entries(LOOKUPS)) {
    if (!schema.tables[table]) continue;
    const qf = l.qualify && schema.tables[l.qualify.table] ? l.qualify : null;
    const [rows] = await db.query(
      `SELECT t.${q(schema.tables[table].primaryKey[0])} AS id, t.${q(l.label)} AS name, t.${q(l.active)} AS active` +
        (qf ? `, x.${q(qf.label)} AS qualifier FROM ${q(table)} t LEFT JOIN ${q(qf.table)} x ON x.id = t.${q(qf.column)}` : ` FROM ${q(table)} t`) +
        ' ORDER BY 1'
    );
    const count = {};
    for (const r of rows) count[norm(r.name)] = (count[norm(r.name)] || 0) + 1;
    out[table] = rows.map((r) => {
      const name = r.name ?? '';
      const label = count[norm(name)] > 1 && r.qualifier ? `${name.trim()} (${r.qualifier})` : name.trim();
      return { id: Number(r.id), name, label, active: r.active !== 0 && r.active !== '0' };
    });
  }
  return out;
}

/** The lookup rows a column resolves against, or undefined when it is not a lookup column. */
function lookupFor(t, col, lookups) {
  const fk = t.foreignKeys.find((f) => f.column === col.name);
  return fk && lookups[fk.refTable];
}

/** Writes the hidden Lookups sheet: names in one column, ids beside them. @returns {object} table → dropdown range */
function addLookupSheet(wb, lookups) {
  const old = wb.getWorksheet(LOOKUP_SHEET);
  if (old) wb.removeWorksheet(old.id);
  const ws = wb.addWorksheet(LOOKUP_SHEET, { state: 'hidden' });
  const ranges = {};
  Object.entries(lookups).forEach(([table, rows], i) => {
    const names = ws.getColumn(i * 2 + 1);
    const ids = ws.getColumn(i * 2 + 2);
    const active = rows.filter((r) => r.active);
    names.values = [table, ...active.map((r) => r.label)];
    ids.values = ['id', ...active.map((r) => r.id)];
    names.width = 30;
    ranges[table] = `${LOOKUP_SHEET}!$${names.letter}$2:$${names.letter}$${Math.max(active.length, 1) + 1}`;
  });
  return ranges;
}

/**
 * A name from the dropdown ("bilaspur (Chhattisgarh)"), a plain name ("hyderabad") or an id ("12", 12, also the
 * older "12 – hyderabad") → { value: 12 } | { error }. Blank cells are left to the caller.
 * Names match case-insensitively and must be exact. Unknown ids pass through to the foreign-key check, which knows
 * about rows added in the same save.
 */
function resolveLookup(rows, raw, column) {
  const text = String(raw).trim();
  const m = /^(\d+)(?:\s*[-–—]\s*(.*))?$/.exec(text);
  if (m) {
    const row = rows.find((r) => r.id === Number(m[1]));
    if (!row) return { value: Number(m[1]) };
    if (m[2] && ![norm(row.name), norm(row.label)].includes(norm(m[2])))
      return { error: `${column} "${text}": id ${row.id} is "${row.label}", not "${m[2].trim()}".` };
    return { value: row.id };
  }
  // shortcut: two rows with the same name AND qualifier still collide; give those by id
  const byLabel = rows.filter((r) => norm(r.label) === norm(text));
  const hits = byLabel.length ? byLabel : rows.filter((r) => norm(r.name) === norm(text));
  if (hits.length === 1) return { value: hits[0].id };
  if (hits.length > 1)
    return { error: `${column} "${text}" could be ${hits.map((r) => `"${r.label}"`).join(' or ')}. Pick one from the dropdown.` };
  return { error: `${column} "${text}" is not in the list. Pick a value from the dropdown.` };
}

module.exports = { LOOKUPS, LOOKUP_SHEET, loadLookups, lookupFor, addLookupSheet, resolveLookup };
