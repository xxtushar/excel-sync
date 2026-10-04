'use strict';
/**
 * Reads the workbook into normalised rows, one sheet per table.
 * Row 1 = column names (matched case-insensitively against the live schema), rows 2+ = data.
 */

const crypto = require('crypto');
const ExcelJS = require('exceljs');
const config = require('../config');
const { findTable } = require('../schema/introspect');
const { toDbValue, unwrapCell } = require('./normalize');

async function loadWorkbook(source) {
  const wb = new ExcelJS.Workbook();
  try {
    if (Buffer.isBuffer(source)) await wb.xlsx.load(source);
    else await wb.xlsx.readFile(source);
  } catch (e) {
    if (e.code === 'ENOENT') throw e;
    // Keep the original text: the watcher retries on zip errors (Excel still writing the file).
    const err = new Error(`Could not open the workbook. Is it a real .xlsx file that has finished saving? (${e.message})`);
    err.status = 400;
    throw err;
  }
  return wb;
}

function matchTable(schema, sheetName) {
  const t = findTable(schema, sheetName.trim());
  if (t) return t;
  // Excel caps sheet names at 31 characters.
  if (sheetName.length === 31) {
    const hits = Object.values(schema.tables).filter((x) => x.name.toLowerCase().startsWith(sheetName.toLowerCase()));
    if (hits.length === 1) return hits[0];
  }
  return null;
}

function isBlank(v) {
  const u = unwrapCell(v);
  return u === null || u === undefined || (typeof u === 'string' && u.trim() === '');
}

/**
 * @returns {{ sheets: object[], errors: object[], warnings: object[] }}
 *   errors/warnings: { sheet, row?, column?, message }
 */
async function readWorkbook(source, schema, { onlyTables } = {}) {
  const wb = await loadWorkbook(source);
  const errors = [];
  const warnings = [];
  const sheets = [];
  const seenTables = new Set();
  const ignore = new Set(config.ignoreSheets.map((s) => s.toLowerCase()));

  for (const ws of wb.worksheets) {
    const sheetName = ws.name;
    if (ignore.has(sheetName.toLowerCase())) continue;
    const table = matchTable(schema, sheetName);
    if (!table) {
      warnings.push({ sheet: sheetName, message: 'No st_/dy_ table with this name; sheet skipped.' });
      continue;
    }
    if (onlyTables && !onlyTables.has(table.name)) continue;
    if (seenTables.has(table.name)) {
      errors.push({ sheet: sheetName, message: `Second sheet for table ${table.name}.` });
      continue;
    }
    seenTables.add(table.name);
    if (table.readOnly) {
      warnings.push({ sheet: sheetName, message: `${table.name} has no single-column primary key; skipped.` });
      continue;
    }

    const sheetErrors = [];
    const sheetWarnings = [];
    const header = ws.getRow(1);
    const colIndex = []; // [{ idx, col }]
    const seenCols = new Set();
    const lastCol = Math.max(ws.columnCount, header.cellCount);
    for (let c = 1; c <= lastCol; c++) {
      const raw = unwrapCell(header.getCell(c).value);
      if (raw === null || String(raw).trim() === '') continue;
      const name = String(raw).trim();
      const col = table.columnMap[name.toLowerCase()];
      if (!col) {
        const msg = `Column "${name}" does not exist in ${table.name}; ignored.`;
        (config.unknownColumnMode === 'error' ? sheetErrors : sheetWarnings).push({ sheet: sheetName, column: name, message: msg });
        continue;
      }
      if (col.generated) {
        sheetWarnings.push({ sheet: sheetName, column: name, message: 'Generated column; ignored.' });
        continue;
      }
      if (seenCols.has(col.name)) {
        sheetErrors.push({ sheet: sheetName, column: name, message: `Column "${name}" appears twice in the header.` });
        continue;
      }
      seenCols.add(col.name);
      colIndex.push({ idx: c, col });
    }

    const pk = table.primaryKey[0];
    if (!seenCols.has(pk)) {
      sheetErrors.push({ sheet: sheetName, message: `Header row has no "${pk}" column, so rows cannot be matched to the table.` });
    }

    const rows = [];
    const idRows = new Map();
    if (!sheetErrors.length) {
      for (let r = 2; r <= ws.rowCount; r++) {
        const row = ws.getRow(r);
        if (colIndex.every(({ idx }) => isBlank(row.getCell(idx).value))) continue;

        const values = {};
        let rowOk = true;
        const nullRequired = [];
        for (const { idx, col } of colIndex) {
          const res = toDbValue(col, row.getCell(idx).value);
          if (res.error) {
            sheetErrors.push({ sheet: sheetName, row: r, column: col.name, message: res.error });
            rowOk = false;
            continue;
          }
          if (res.missingRequired && col.name !== pk) nullRequired.push(col.name);
          values[col.name] = res.value;
        }
        if (!rowOk) continue;

        const id = values[pk];
        if (id !== null && id !== undefined) {
          if (idRows.has(String(id))) {
            sheetErrors.push({
              sheet: sheetName,
              row: r,
              column: pk,
              message: `${pk} ${id} is also used on row ${idRows.get(String(id))}.`,
            });
            continue;
          }
          idRows.set(String(id), r);
        }
        rows.push({ rowNumber: r, values, nullRequired });
      }
    }

    // In-sheet duplicate check for unique keys (e.g. inv_id, univ_user_id) gives a clearer error than MySQL's.
    for (const uk of table.uniqueKeys) {
      if (!uk.columns.every((c) => seenCols.has(c))) continue;
      const seen = new Map();
      for (const row of rows) {
        const vals = uk.columns.map((c) => row.values[c]);
        if (vals.some((v) => v === null)) continue;
        const key = JSON.stringify(vals);
        if (seen.has(key)) {
          sheetErrors.push({
            sheet: sheetName,
            row: row.rowNumber,
            column: uk.columns.join(','),
            message: `Duplicate value ${vals.join(', ')} (unique key ${uk.name}); also on row ${seen.get(key)}.`,
          });
        } else seen.set(key, row.rowNumber);
      }
    }

    const columns = colIndex.map((x) => x.col.name);
    const hash = crypto
      .createHash('sha256')
      .update(JSON.stringify({ columns, rows: rows.map((r) => columns.map((c) => r.values[c])) }))
      .digest('hex');

    errors.push(...sheetErrors);
    warnings.push(...sheetWarnings);
    sheets.push({ sheetName, table: table.name, columns, rows, hash, hasErrors: sheetErrors.length > 0 });
  }

  return { sheets, errors, warnings };
}

module.exports = { readWorkbook, loadWorkbook };
