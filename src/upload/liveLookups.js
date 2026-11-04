'use strict';
/**
 * Dropdowns that stay correct on their own.
 *
 * Every column with a foreign key to a static (st_) table that is in the workbook becomes a dropdown of
 * "id – name" entries. Nothing is hardcoded: which columns get a dropdown comes from the schema's foreign keys, and
 * which column of the static table is the "name" is picked automatically (LABEL_COLUMNS overrides it).
 *
 * The hidden Lookups sheet is made of formulas that read the static sheets, not a pasted copy of them. So when
 * someone adds, renames or deactivates a row on a static sheet in Excel, every dropdown that uses it updates at once,
 * with no need to run anything. Inactive rows (rstatus = 0) are left out of the dropdown but still accepted if
 * already used. The formulas only use INDEX/MATCH/OFFSET/COUNTIF, so they work in every Excel version and in
 * LibreOffice. Each formula also carries its current result, so the file reads correctly even before Excel opens it.
 */

const config = require('../config');

const LOOKUP_SHEET = 'Lookups';

/** Pin the "name" column of a static table here if the automatic pick is wrong, e.g. { st_pg_state: 'scode' }. */
const LABEL_COLUMNS = {};

/**
 * Columns whose dropdown offers only some rows of their static table, e.g. a bed can only be Vacant, Reserved or
 * Occupied: { 'dy_pg_bed_info.bed_status': [3, 4, 5] }. Lists already in a workbook's Lookups sheet (a header
 * like "dy_pg_bed_info.bed_status") are kept automatically, so this is only needed to add or change one.
 */
const COLUMN_SUBSETS = {};

const DASH = ' – ';
const quoteSheet = (name) => `'${name.replace(/'/g, "''")}'`;

function colLetter(n) {
  let s = '';
  for (; n > 0; n = Math.floor((n - 1) / 26)) s = String.fromCharCode(65 + ((n - 1) % 26)) + s;
  return s;
}

/** The column that names a row: the override, else the longest text column, else the first plain column. */
function labelColumn(t) {
  if (LABEL_COLUMNS[t.name] && t.columnMap[LABEL_COLUMNS[t.name].toLowerCase()]) return t.columnMap[LABEL_COLUMNS[t.name].toLowerCase()];
  const skip = new Set([...t.primaryKey, ...t.softDeleteColumns, ...t.foreignKeys.map((f) => f.column)]);
  const plain = t.columns.filter((c) => !skip.has(c.name) && !c.generated);
  const text = plain.filter((c) => c.kind === 'string');
  if (text.length) return text.reduce((a, b) => ((b.maxLength || 0) > (a.maxLength || 0) ? b : a));
  return plain[0] || null;
}

/** First soft-delete column (rstatus, is_active, active) of the table, or null. */
const activeColumn = (t) => (t.softDeleteColumns[0] ? t.columnMap[t.softDeleteColumns[0].toLowerCase()] : null);

/**
 * Which static tables need a dropdown: those referenced by a foreign key from any table sheet in the workbook,
 * and present in the workbook themselves (the dropdown reads the sheet).
 * @param {object} schema
 * @param {Map<string, {ws, header}>} sheets  table name → its worksheet and header map (column name → index)
 */
function lookupTables(schema, sheets) {
  const out = new Set();
  for (const name of sheets.keys()) {
    for (const fk of schema.tables[name].foreignKeys) {
      const ref = schema.tables[fk.refTable];
      if (ref && ref.kind === 'static' && sheets.has(ref.name) && sheets.get(name).header.has(fk.column)) out.add(ref.name);
    }
  }
  return [...out].sort();
}

/**
 * Writes the Lookups sheet. `rows` is table → [{ sheetRow, id, name, active }] as read from that static sheet.
 * `ends` is table → last sheet row the formulas should cover (data rows plus room for new rows).
 * @returns {object} table → list formula for Excel data validation
 */
function writeLookupSheet(wb, schema, sheets, blocks, rows, ends) {
  const old = wb.getWorksheet(LOOKUP_SHEET);
  if (old) wb.removeWorksheet(old.id);
  const ws = wb.addWorksheet(LOOKUP_SHEET, { state: 'hidden' });
  const lists = {};

  blocks.forEach(({ key, table: name, onlyIds }, i) => {
    const t = schema.tables[name];
    const { header } = sheets.get(name);
    const label = labelColumn(t);
    const active = activeColumn(t);
    const src = quoteSheet(name);
    const idL = colLetter(header.get(t.primaryKey[0]));
    const nameL = label && header.has(label.name) ? colLetter(header.get(label.name)) : null;
    const actL = active && header.has(active.name) ? colLetter(header.get(active.name)) : null;
    const end = ends[name];

    const [cLabel, cId, cIdx] = [i * 3 + 1, i * 3 + 2, i * 3 + 3].map(colLetter);
    ws.getCell(`${cLabel}1`).value = key;
    ws.getCell(`${cId}1`).value = 'id';
    ws.getCell(`${cIdx}1`).value = '#';
    ws.getColumn(i * 3 + 1).width = 30;

    // What the formulas evaluate to right now, so the cached results are correct.
    const offered = new Map(); // sheet row → position in the dropdown
    const entries = [];
    for (const r of rows[name]) {
      if (r.id == null || !r.active || r.name == null || String(r.name).trim() === '') continue;
      if (onlyIds && !onlyIds.includes(r.id)) continue;
      entries.push(r);
      offered.set(r.sheetRow, entries.length);
    }

    const pos = `MATCH(ROW()-1,$${cIdx}$2:$${cIdx}$${end},0)`;
    for (let r = 2; r <= end; r++) {
      // "#": the row's position in the dropdown, or blank when it is empty, has no name or is inactive.
      const conds = [`${src}!$${idL}${r}<>""`, nameL ? `${src}!$${nameL}${r}<>""` : 'TRUE'];
      if (actL) conds.push(`NOT(AND(${src}!$${actL}${r}<>"",${src}!$${actL}${r}=0))`);
      if (onlyIds) conds.push(`ISNUMBER(MATCH(${src}!$${idL}${r},{${onlyIds.join(',')}},0))`);
      const k = offered.get(r);
      ws.getCell(`${cIdx}${r}`).value = {
        formula: `IF(AND(${conds.join(',')}),MAX($${cIdx}$1:$${cIdx}${r - 1})+1,"")`,
        result: k ?? '',
      };
      const e = entries[r - 2];
      const nameExpr = nameL ? `&"${DASH}"&INDEX(${src}!$${nameL}$2:$${nameL}$${end},${pos})` : '';
      ws.getCell(`${cLabel}${r}`).value = {
        formula: `IFERROR(INDEX(${src}!$${idL}$2:$${idL}$${end},${pos})${nameExpr},"")`,
        result: e ? labelOf(e) : '',
      };
      ws.getCell(`${cId}${r}`).value = {
        formula: `IFERROR(INDEX(${src}!$${idL}$2:$${idL}$${end},${pos}),"")`,
        result: e ? e.id : '',
      };
    }
    // The dropdown is only as long as the entries that exist, so it has no blank lines at the bottom.
    lists[key] = `OFFSET(${LOOKUP_SHEET}!$${cLabel}$2,0,0,MAX(1,COUNTIF(${LOOKUP_SHEET}!$${cLabel}$2:$${cLabel}$${end},"?*")),1)`;
  });
  return lists;
}

/** "table.column" lists found on an existing Lookups sheet → { 'dy_pg_bed_info.bed_status': [3, 5, 4] }. */
function readSubsets(wb, schema) {
  const ws = wb.getWorksheet(LOOKUP_SHEET);
  const out = { ...COLUMN_SUBSETS };
  if (!ws) return out;
  const row1 = ws.getRow(1);
  for (let c = 1; c <= row1.cellCount; c++) {
    const m = /^(\w+)\.(\w+)$/.exec(String(row1.getCell(c).value ?? '').trim());
    if (!m || out[m[0]] || !schema.tables[m[1]] || !schema.tables[m[1]].columnMap[m[2].toLowerCase()]) continue;
    const ids = [];
    for (let r = 2; r <= ws.rowCount; r++) {
      const v = ws.getRow(r).getCell(c).value;
      const raw = v && typeof v === 'object' && 'result' in v ? v.result : v;
      const n = /^(\d+)/.exec(String(raw ?? '').trim());
      if (n) ids.push(Number(n[1]));
    }
    if (ids.length) out[m[0]] = ids;
  }
  return out;
}

const norm = (s) => String(s ?? '').trim().toLowerCase();

/**
 * A dropdown entry ("12 – hyderabad"), a plain name ("hyderabad") or an id ("12", 12) → { value: 12 } | { error }.
 * Names match case-insensitively and must be exact. Unknown ids pass through to the link check, which knows
 * about rows added in the same file. `rows` is the output of toResolveRows().
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
  const byLabel = rows.filter((r) => norm(r.label) === norm(text));
  const hits = byLabel.length ? byLabel : rows.filter((r) => norm(r.name) === norm(text));
  if (hits.length === 1) return { value: hits[0].id };
  if (hits.length > 1) return { error: `${column} "${text}" could be ${hits.map((r) => `"${r.label}"`).join(' or ')}. Pick one from the dropdown.` };
  return { error: `${column} "${text}" is not in the list. Pick a value from the dropdown.` };
}

const labelOf = (r) => `${r.id}${DASH}${String(r.name).trim()}`;

/** Lookup rows in the shape lookups.resolveLookup() expects. */
function toResolveRows(rows) {
  return rows.filter((r) => r.id != null).map((r) => ({ id: r.id, name: String(r.name ?? ''), label: labelOf(r), active: r.active }));
}

module.exports = { resolveLookup, LOOKUP_SHEET, LABEL_COLUMNS, COLUMN_SUBSETS, readSubsets, labelColumn, activeColumn, lookupTables, writeLookupSheet, toResolveRows, labelOf, colLetter, quoteSheet, staticPrefix: config.staticPrefix };
