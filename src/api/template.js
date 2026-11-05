'use strict';
/**
 * Builds the workbook an admin downloads and edits: the sheets and columns of the layout file
 * (templates/upload-template.xlsx, headers only) filled with the database's current rows, then passed through
 * prepareWorkbook so it gets the dropdowns, type rules and automatic ids.
 *
 * To change which tables or columns admins get, edit the header rows of the layout file: add or remove a sheet
 * (named exactly like the table) or a column header. No code change is needed.
 */

const path = require('path');
const ExcelJS = require('exceljs');
const config = require('../config');
const { q } = require('../db/pool');
const { fromDbValue } = require('../excel/normalize');
const { prepareWorkbook } = require('../upload/prepare');

const DEFAULT_LAYOUT = path.join(config.projectRoot, 'templates', 'upload-template.xlsx');

async function buildTemplate(db, schema, { layoutFile = DEFAULT_LAYOUT, now = new Date() } = {}) {
  const wb = new ExcelJS.Workbook();
  await wb.xlsx.readFile(layoutFile);
  const missing = [];
  for (const ws of wb.worksheets) {
    const t = schema.tables[ws.name];
    if (!t) continue; // _README, Lookups, notes
    const header = [];
    ws.getRow(1).eachCell({ includeEmpty: false }, (cell, c) => {
      const col = t.columnMap[String(cell.value).trim().toLowerCase()];
      if (col) header.push({ c, col });
      else missing.push(`${ws.name}.${cell.value}`);
    });
    if (ws.rowCount > 1) ws.spliceRows(2, ws.rowCount - 1);
    if (!header.length) continue;
    const pk = t.primaryKey[0];
    const [rows] = await db.query(`SELECT ${header.map((h) => q(h.col.name)).join(', ')} FROM ${q(t.name)} ORDER BY ${q(pk)}`);
    rows.forEach((r, i) => {
      const row = ws.getRow(i + 2);
      for (const { c, col } of header) {
        const v = fromDbValue(col, r[col.name]);
        // Numbers stay numbers; text, dates and decimals' exact digits stay as the database has them.
        row.getCell(c).value = v === null ? null : col.kind === 'decimal' || col.kind === 'float' ? Number(v) : v;
      }
    });
  }
  const result = await prepareWorkbook(Buffer.from(await wb.xlsx.writeBuffer()), schema, { now });
  return { ...result, missingColumns: missing };
}

module.exports = { buildTemplate, DEFAULT_LAYOUT };
