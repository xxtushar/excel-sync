'use strict';
/**
 * Checks a workbook and makes it ready to upload in the admin UI. It never connects to a database and never
 * writes to one: the admin UI's import is the only thing that changes data. Table definitions come from
 * schema/avyra.schema.json (built from a dump by scripts/build-schema.js).
 *
 *   workbook ─► give new rows their ids ─► check every cell ─► refresh dropdowns + rules ─► output workbook
 *
 * Checks: column types and lengths, required columns, duplicate ids and unique values, dropdown values that exist
 * in their static sheet, and ids that point at another sheet in the file (a room's pg_info must be a PG in
 * dy_pg_info). Problems are highlighted on the cell, with a note, and listed on a _Check sheet.
 */

const fs = require('fs');
const ExcelJS = require('exceljs');
const JSZip = require('jszip');
const config = require('../config');
const { toDbValue, unwrapCell } = require('../excel/normalize');
const { addValidation, EXTRA_ROWS } = require('../excel/validation');
const { resolveLookup, LOOKUP_SHEET, readSubsets, lookupTables, writeLookupSheet, toResolveRows, labelColumn, activeColumn, labelOf, colLetter } = require('./liveLookups');

const CHECK_SHEET = '_Check';
const README_SHEET = '_README';
const MARK = '⚠ Check: ';
const MARK_FILL = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFC7CE' } };
const WARN_FILL = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFEB9C' } };

const isFormula = (v) => v && typeof v === 'object' && ('formula' in v || 'sharedFormula' in v);
// A formula that was never calculated (file saved by a tool other than Excel) has no result: treat it as empty.
const val = (v) => (isFormula(v) ? unwrapCell(v.result ?? null) : unwrapCell(v));
const isBlank = (v) => {
  const u = val(v);
  return u === null || u === undefined || (typeof u === 'string' && u.trim() === '');
};
const noteText = (n) => (typeof n === 'string' ? n : n && Array.isArray(n.texts) ? n.texts.map((t) => t.text).join('') : '');

function findTable(schema, sheetName) {
  const lower = sheetName.trim().toLowerCase();
  return Object.values(schema.tables).find((t) => t.name.toLowerCase() === lower) || null;
}

/** Removes highlights and notes left by an earlier check, so fixed cells don't stay red. */
function clearMarks(ws) {
  ws.eachRow({ includeEmpty: false }, (row) =>
    row.eachCell({ includeEmpty: false }, (cell) => {
      // Our mark: the note we wrote, or (when a tool dropped the notes) our exact highlight colour.
      const argb = cell.fill && cell.fill.fgColor && cell.fill.fgColor.argb;
      if (!noteText(cell.note).startsWith(MARK) && argb !== MARK_FILL.fgColor.argb && argb !== WARN_FILL.fgColor.argb) return;
      cell._comment = undefined;
      const { fill, ...style } = cell.style || {};
      cell.style = style;
    })
  );
}

/** The highest "MAX(n," seed in the sheet's id formulas: the next-id start the original export knew about. */
function formulaSeed(ws, idx) {
  let seed = 0;
  ws.getColumn(idx).eachCell((cell) => {
    const v = cell.value;
    const f = isFormula(v) && (v.formula || '');
    const m = f && /MAX\((\d+),/.exec(f);
    if (m) seed = Math.max(seed, Number(m[1]));
  });
  return seed;
}

/**
 * Opens the workbook. Some tools save cell notes in a form ExcelJS can't read; then the notes (only ever check
 * marks or hints) are dropped and the file is opened without them, instead of failing.
 */
async function loadTolerant(buf) {
  const wb = new ExcelJS.Workbook();
  try {
    await wb.xlsx.load(buf);
    return wb;
  } catch (e) {
    if (!/comment|note|vml/i.test(e.message)) throw e;
  }
  const zip = await JSZip.loadAsync(buf);
  for (const name of Object.keys(zip.files)) {
    if (/^xl\/(comments\d*\.xml|drawings\/vmlDrawing\d*\.vml|threadedComments\/)/i.test(name)) zip.remove(name);
    else if (/^xl\/worksheets\/_rels\/.+\.rels$/i.test(name)) {
      const xml = await zip.file(name).async('string');
      zip.file(name, xml.replace(/<Relationship\b[^>]*(comments|vmlDrawing|threadedComment)[^>]*\/>/gi, ''));
    } else if (/^xl\/worksheets\/sheet\d+\.xml$/i.test(name)) {
      const xml = await zip.file(name).async('string');
      zip.file(name, xml.replace(/<legacyDrawing\b[^>]*\/>/g, ''));
    }
  }
  const ct = await zip.file('[Content_Types].xml').async('string');
  zip.file('[Content_Types].xml', ct.replace(/<Override\b[^>]*(comments|vmlDrawing|threadedComment)[^>]*\/>/gi, ''));
  const fixed = new ExcelJS.Workbook();
  await fixed.xlsx.load(await zip.generateAsync({ type: 'nodebuffer' }));
  return fixed;
}

/**
 * @param {Buffer|string} source  workbook buffer or path
 * @param {object} schema         reviveSchema(require('schema/avyra.schema.json'))
 * @param {{ ids?: boolean, now?: Date }} [opts]  ids: write plain ids instead of "id – name" in dropdown columns
 */
async function prepareWorkbook(source, schema, opts = {}) {
  const wb = await loadTolerant(Buffer.isBuffer(source) ? source : fs.readFileSync(source));

  const issues = [];
  const info = [];
  const add = (level, sheet, message, at = {}) => issues.push({ level, sheet, ...at, message });
  const skip = new Set([README_SHEET, LOOKUP_SHEET, CHECK_SHEET, ...config.ignoreSheets].map((s) => s.toLowerCase()));

  const subsets = readSubsets(wb, schema); // before the Lookups sheet is rebuilt
  const oldCheck = wb.getWorksheet(CHECK_SHEET);
  if (oldCheck) wb.removeWorksheet(oldCheck.id);

  // ── 1. Sheets and headers ─────────────────────────────────────────────────────────────────────────────
  const sheets = new Map(); // table name → { ws, t, header: Map(column → index), cols: [{ idx, col }] }
  for (const ws of wb.worksheets) {
    if (skip.has(ws.name.toLowerCase())) continue;
    clearMarks(ws);
    const t = findTable(schema, ws.name);
    if (!t) {
      add('warning', ws.name, 'No table with this name in the schema, so this sheet was not checked. The admin UI may reject it.');
      continue;
    }
    if (sheets.has(t.name)) {
      add('error', ws.name, `A second sheet for ${t.name}. Keep one.`);
      continue;
    }
    const header = new Map();
    const cols = [];
    const row1 = ws.getRow(1);
    for (let c = 1; c <= Math.max(ws.columnCount, row1.cellCount); c++) {
      const raw = val(row1.getCell(c).value);
      if (raw === null || String(raw).trim() === '') continue;
      const col = t.columnMap[String(raw).trim().toLowerCase()];
      const at = { cell: `${colLetter(c)}1`, column: String(raw).trim() };
      if (!col) add('error', ws.name, `"${String(raw).trim()}" is not a column of ${t.name}. Rename it or remove it.`, at);
      else if (header.has(col.name)) add('error', ws.name, `Column "${col.name}" appears twice.`, at);
      else {
        header.set(col.name, c);
        cols.push({ idx: c, col });
      }
    }
    const pk = t.primaryKey[0];
    if (!header.has(pk)) {
      add('error', ws.name, `There is no "${pk}" column, so rows can't be matched. Put "${pk}" back in row 1.`);
      continue;
    }
    for (const col of t.columns)
      if (!col.nullable && !col.hasDefault && !col.autoIncrement && !header.has(col.name))
        add('error', ws.name, `Required column "${col.name}" is missing from the sheet.`);
    sheets.set(t.name, { ws, t, header, cols, rows: [] });
  }

  // ── 2. Ids: keep the ones there, give new rows the next free id ───────────────────────────────────────
  for (const s of sheets.values()) {
    const { ws, t, header, cols } = s;
    const pkIdx = header.get(t.primaryKey[0]);
    s.seed = Math.max(formulaSeed(ws, pkIdx), (t.nextId || 1) - 1);
    let maxId = 0;
    let assigned = 0;
    for (let r = 2; r <= ws.rowCount; r++) {
      const row = ws.getRow(r);
      const idCell = row.getCell(pkIdx);
      const hasData = cols.some(({ idx }) => idx !== pkIdx && !isBlank(row.getCell(idx).value)) || (!isFormula(idCell.value) && !isBlank(idCell.value));
      if (!hasData) continue;
      let id = val(idCell.value);
      if (isBlank(id)) {
        id = Math.max(s.seed, maxId) + 1;
        assigned++;
      }
      if (typeof id === 'string' && /^\d+$/.test(id.trim())) id = Number(id);
      if (typeof id === 'number' && Number.isInteger(id)) {
        idCell.value = id; // a plain value: the import should not depend on a formula
        maxId = Math.max(maxId, id);
      }
      s.rows.push({ r, id });
    }
    s.lastRow = s.rows.length ? s.rows[s.rows.length - 1].r : 1;
    s.maxId = maxId;
    if (assigned) info.push(`${ws.name}: gave ${assigned} new row(s) an id.`);
  }

  // ── 3. Dropdown sources, read from the static sheets in this file ─────────────────────────────────────
  const lkTables = lookupTables(schema, sheets);
  const lkRows = {};
  for (const name of lkTables) {
    const { ws, t, header } = sheets.get(name);
    const label = labelColumn(t);
    const active = activeColumn(t);
    lkRows[name] = sheets.get(name).rows.map(({ r, id }) => {
      const row = ws.getRow(r);
      const nameVal = label && header.has(label.name) ? val(row.getCell(header.get(label.name)).value) : null;
      const actVal = active && header.has(active.name) ? val(row.getCell(header.get(active.name)).value) : null;
      return { sheetRow: r, id: typeof id === 'number' ? id : null, name: nameVal, active: !(actVal === 0 || actVal === '0') };
    });
  }
  const resolveRows = Object.fromEntries(Object.entries(lkRows).map(([n, rows]) => [n, toResolveRows(rows)]));

  // ── 4. Check every cell ───────────────────────────────────────────────────────────────────────────────
  const unchecked = new Set();
  for (const s of sheets.values()) {
    const { ws, t, header, cols } = s;
    const pk = t.primaryKey[0];
    const seenIds = new Map();
    for (const rowInfo of s.rows) {
      const row = ws.getRow(rowInfo.r);
      rowInfo.values = {};
      for (const { idx, col } of cols) {
        const cell = row.getCell(idx);
        const at = { row: rowInfo.r, column: col.name, cell: `${colLetter(idx)}${rowInfo.r}` };
        let v = cell.value;
        const fk = t.foreignKeys.find((f) => f.column === col.name);
        const lk = fk && resolveRows[fk.refTable];
        if (lk && !isBlank(v)) {
          const hit = resolveLookup(lk, val(v), col.name);
          if (hit.error) {
            add('error', ws.name, hit.error, at);
            continue;
          }
          const entry = lk.find((e) => e.id === hit.value);
          const only = subsets[`${t.name}.${col.name}`];
          if (entry && only && !only.includes(entry.id)) {
            const allowed = lk.filter((e) => only.includes(e.id)).map((e) => `"${e.label}"`).join(', ');
            add('error', ws.name, `"${entry.label}" is not a choice for ${col.name}. Use one of: ${allowed}.`, at);
            continue;
          }
          if (entry && !entry.active) add('warning', ws.name, `"${entry.label}" is switched off (rstatus 0) in ${fk.refTable}. Pick an active one if you can.`, at);
          v = hit.value;
          rowInfo.lookupCells = rowInfo.lookupCells || [];
          rowInfo.lookupCells.push({ cell, id: hit.value, entry });
        }
        const res = toDbValue(col, val(v));
        if (res.error) add('error', ws.name, `${col.name}: ${res.error}.`, at);
        else if (res.missingRequired && col.name !== pk) add('error', ws.name, `${col.name} is required.`, at);
        else rowInfo.values[col.name] = res.value;
      }
      const id = rowInfo.values[pk];
      if (id != null) {
        if (seenIds.has(id)) add('error', ws.name, `${pk} ${id} is also used on row ${seenIds.get(id)}.`, { row: rowInfo.r, column: pk, cell: `${colLetter(header.get(pk))}${rowInfo.r}` });
        else seenIds.set(id, rowInfo.r);
      }
    }
    s.ids = new Set(seenIds.keys());

    for (const uk of t.uniqueKeys) {
      if (!uk.columns.every((c) => header.has(c))) continue;
      const seen = new Map();
      for (const ri of s.rows) {
        const vals = uk.columns.map((c) => ri.values[c]);
        if (vals.some((x) => x == null)) continue;
        const key = JSON.stringify(vals);
        const c0 = uk.columns[0];
        if (seen.has(key)) add('error', ws.name, `${uk.columns.join(', ')} "${vals.join(', ')}" must be unique; also on row ${seen.get(key)}.`, { row: ri.r, column: c0, cell: `${colLetter(header.get(c0))}${ri.r}` });
        else seen.set(key, ri.r);
      }
    }
  }

  // Ids that point at another sheet in this file must exist there.
  for (const s of sheets.values()) {
    for (const fk of s.t.foreignKeys) {
      if (!s.header.has(fk.column)) continue;
      const target = sheets.get(fk.refTable);
      if (!target) {
        if (s.rows.some((ri) => ri.values[fk.column] != null)) unchecked.add(`${s.ws.name}.${fk.column} → ${fk.refTable}`);
        continue;
      }
      for (const ri of s.rows) {
        const v = ri.values[fk.column];
        if (v == null || target.ids.has(v)) continue;
        add('error', s.ws.name, `${fk.column} = ${v}, but ${target.ws.name} has no row with id ${v}.`, { row: ri.r, column: fk.column, cell: `${colLetter(s.header.get(fk.column))}${ri.r}` });
      }
    }
  }
  for (const u of unchecked) add('warning', u.split('.')[0], `${u}: that table is not in this file, so these ids could not be checked. The admin UI will check them on import.`);

  const errors = issues.filter((i) => i.level === 'error');
  const warnings = issues.filter((i) => i.level === 'warning');

  // ── 5. Write the output ───────────────────────────────────────────────────────────────────────────────
  // Dropdown cells get one consistent spelling: "id – name" (or the plain id with --ids).
  for (const s of sheets.values())
    for (const ri of s.rows) for (const lc of ri.lookupCells || []) lc.cell.value = opts.ids || !lc.entry ? lc.id : lc.entry.label;

  const ends = Object.fromEntries([...sheets].map(([n, s]) => [n, s.lastRow + EXTRA_ROWS]));
  const blocks = lkTables.map((n) => ({ key: n, table: n }));
  for (const [key, onlyIds] of Object.entries(subsets)) {
    const [tname, cname] = key.split('.');
    const fk = sheets.has(tname) && sheets.get(tname).header.has(cname) && schema.tables[tname].foreignKeys.find((f) => f.column === cname);
    if (fk && lkTables.includes(fk.refTable)) blocks.push({ key, table: fk.refTable, onlyIds });
  }
  const lists = blocks.length ? writeLookupSheet(wb, schema, sheets, blocks, lkRows, ends) : {};
  if (!lkTables.length && wb.getWorksheet(LOOKUP_SHEET)) wb.removeWorksheet(wb.getWorksheet(LOOKUP_SHEET).id);

  for (const s of sheets.values()) {
    writeIdFormulas(s, ends[s.t.name]);
    addValidation(s.ws, s.t, s.lastRow, opts.ids ? {} : lists);
  }

  // Highlights and the _Check sheet only go into a needs-fixes file; a ready file stays clean for the import.
  const marked = new Set();
  for (const i of errors.length ? issues : []) {
    if (!i.cell) continue;
    const s = [...sheets.values()].find((x) => x.ws.name === i.sheet);
    const ws = s ? s.ws : wb.getWorksheet(i.sheet);
    if (!ws) continue;
    const cell = ws.getCell(i.cell);
    const key = `${i.sheet}!${i.cell}`;
    const prev = marked.has(key) ? noteText(cell.note).slice(MARK.length) + '\n' : '';
    cell.note = MARK + prev + i.message;
    if (i.level === 'error' || !marked.has(key)) cell.fill = i.level === 'error' ? MARK_FILL : WARN_FILL;
    marked.add(key);
  }

  const now = opts.now || new Date();
  writeReadme(wb, sheets, { errors, warnings, now, ids: opts.ids });
  if (errors.length) writeCheckSheet(wb, issues);
  wb.calcProperties = { ...(wb.calcProperties || {}), fullCalcOnLoad: true };

  return {
    ok: errors.length === 0,
    errors,
    warnings,
    info,
    tables: [...sheets.values()].map((s) => ({ table: s.t.name, kind: s.t.kind, rows: s.rows.length })),
    dropdowns: lkTables,
    buffer: Buffer.from(await wb.xlsx.writeBuffer()),
  };
}

/** The blank rows under the data get an id formula: type in the row and the next free id appears. */
function writeIdFormulas(s, end) {
  const { ws, t, header } = s;
  const pkIdx = header.get(t.primaryKey[0]);
  const others = [...header.values()].filter((i) => i !== pkIdx).sort((a, b) => a - b);
  if (!others.length) return;
  const pkL = colLetter(pkIdx);
  const seed = Math.max(s.seed, s.maxId);
  // Contiguous runs of the other columns, so COUNTA never includes the id cell itself (a circular reference).
  const runs = [];
  for (const i of others) {
    const last = runs[runs.length - 1];
    if (last && last[1] === i - 1) last[1] = i;
    else runs.push([i, i]);
  }
  for (let r = s.lastRow + 1; r <= end; r++) {
    const cell = ws.getCell(`${pkL}${r}`);
    if (!isBlank(cell.value) && !isFormula(cell.value)) continue;
    const counta = runs.map(([a, b]) => `COUNTA(${colLetter(a)}${r}:${colLetter(b)}${r})`).join('+');
    cell.value = { formula: `IF(${counta}=0,"",MAX(${seed},${pkL}$1:${pkL}${r - 1})+1)`, result: '' };
  }
}

function writeReadme(wb, sheets, { errors, warnings, now, ids }) {
  const old = wb.getWorksheet(README_SHEET);
  if (old) wb.removeWorksheet(old.id);
  const ws = wb.addWorksheet(README_SHEET);
  ws.orderNo = -1; // first tab
  ws.getColumn(1).width = 6;
  ws.getColumn(2).width = 30;
  ws.getColumn(3).width = 10;
  ws.getColumn(4).width = 8;
  ws.getColumn(5).width = 14;
  const stamp = now.toISOString().slice(0, 16).replace('T', ' ');
  ws.addRow(['avyra upload workbook']).font = { bold: true, size: 14 };
  const status = errors.length
    ? `Checked ${stamp} UTC: ${errors.length} problem(s) to fix before uploading. Red cells and the _Check sheet show them.`
    : `Checked ${stamp} UTC: ready to upload in the admin UI${warnings.length ? ` (${warnings.length} note(s) at the bottom of this sheet)` : ''}.`;
  ws.addRow([status]).font = { bold: true, color: { argb: errors.length ? 'FFC00000' : 'FF2E7D32' } };
  ws.addRow([]);
  for (const line of [
    'How to use: edit the sheets, run  npm run check-upload -- <this file>,  then upload the "-ready-to-upload" file in the admin UI. Nothing here changes the database; the admin UI import does that.',
    'Each sheet = one table. Row 1 = exact column names: do not rename them. Empty cell = NULL.',
    ids
      ? 'Columns that point at a static table hold the plain id (e.g. 12).'
      : 'Columns that point at a static table (city, state, status, room type…) are a dropdown of "id – name" entries, e.g. "12 – hyderabad". Pick one, or type the id or the name; the checker fixes the spelling.',
    'The dropdowns read the static (st_) sheets live: add or rename a row there and it shows up in every dropdown at once. Rows with rstatus = 0 are left out of the dropdowns.',
    'New rows get their id automatically: type in the first empty row and the id column fills in with the next free id. Leave that formula alone.',
    'Each column only accepts its type (whole number, date, text up to its length). Excel does not check pasted values; the checker does.',
  ])
    ws.addRow([line]);
  ws.addRow([]);
  ws.addRow(['#', 'Table (sheet)', 'Type', 'Rows', 'Problems']).font = { bold: true };
  [...sheets.values()].forEach((s, i) => {
    const n = errors.filter((e) => e.sheet === s.ws.name).length;
    ws.addRow([i + 1, s.ws.name, s.t.kind === 'static' ? 'Static' : 'Dynamic', s.rows.length, n || '']);
  });
  if (!errors.length && warnings.length) {
    ws.addRow([]);
    ws.addRow(['Notes (fine to upload, worth a look)']).font = { bold: true };
    for (const w of warnings) ws.addRow([`${w.sheet}${w.cell ? '!' + w.cell : ''}: ${w.message}`]);
  }
}

function writeCheckSheet(wb, issues) {
  const ws = wb.addWorksheet(CHECK_SHEET, { properties: { tabColor: { argb: 'FFC00000' } }, views: [{ state: 'frozen', ySplit: 1 }] });
  ws.columns = [
    { header: 'Level', key: 'level', width: 10 },
    { header: 'Sheet', key: 'sheet', width: 20 },
    { header: 'Cell', key: 'cell', width: 8 },
    { header: 'Column', key: 'column', width: 22 },
    { header: 'What to do', key: 'message', width: 110 },
  ];
  ws.getRow(1).font = { bold: true };
  const sorted = [...issues].sort((a, b) => (a.level === b.level ? 0 : a.level === 'error' ? -1 : 1));
  for (const i of sorted) {
    const row = ws.addRow({ level: i.level === 'error' ? 'Fix' : 'Note', sheet: i.sheet, cell: i.cell || '', column: i.column || '', message: i.message });
    if (i.cell) row.getCell('cell').value = { text: i.cell, hyperlink: `#'${i.sheet}'!${i.cell}` };
    row.getCell('level').fill = i.level === 'error' ? MARK_FILL : WARN_FILL;
  }
}

module.exports = { prepareWorkbook, CHECK_SHEET, MARK };
