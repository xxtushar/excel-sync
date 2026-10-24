#!/usr/bin/env node
'use strict';
/**
 * Adds data validation to an existing workbook, so each column only accepts its MySQL type (see
 * src/excel/validation.js). The data is not changed. Types are read from the database in config.json.
 *
 *   node scripts/constrain-workbook.js <workbook.xlsx> [--out=other.xlsx]
 *
 * Without --out the workbook is updated in place, after a copy is saved as <workbook>.bak.
 * Close the workbook in Excel / LibreOffice first, or saving it there would drop the validation again.
 */

const fs = require('fs');
const path = require('path');
const ExcelJS = require('exceljs');
const config = require('../src/config');
const { createPool, connectionHint } = require('../src/db');
const { introspect, findTable } = require('../src/schema/introspect');
const { addValidation, lastDataRow, EXTRA_ROWS } = require('../src/excel/validation');

async function main() {
  const args = process.argv.slice(2);
  const file = args.find((a) => !a.startsWith('--'));
  if (!file) {
    console.error('Usage: node scripts/constrain-workbook.js <workbook.xlsx> [--out=other.xlsx]');
    process.exit(2);
  }
  const src = path.resolve(file);
  const outArg = (args.find((a) => a.startsWith('--out=')) || '').slice('--out='.length);
  const out = outArg ? path.resolve(outArg) : src;

  const pool = createPool(config.db);
  let schema;
  try {
    schema = await introspect(pool, config.db.database);
  } finally {
    await pool.end();
  }

  const wb = new ExcelJS.Workbook();
  await wb.xlsx.readFile(src);
  let sheets = 0;
  let columns = 0;
  const unmatched = [];
  wb.eachSheet((ws) => {
    if (config.ignoreSheets.includes(ws.name)) return;
    const t = findTable(schema, ws.name);
    if (!t) return;
    const n = addValidation(ws, t, lastDataRow(ws));
    const header = ws.getRow(1);
    for (let c = 1; c <= header.cellCount; c++) {
      const name = String(header.getCell(c).value ?? '').trim();
      if (name && !t.columnMap[name.toLowerCase()]) unmatched.push(`${ws.name}.${name}`);
    }
    sheets++;
    columns += n;
  });

  if (out === src) fs.copyFileSync(src, `${src}.bak`);
  await wb.xlsx.writeFile(out);
  console.log(`[excel-sync] ${columns} column(s) in ${sheets} sheet(s) now only accept their type (data rows + ${EXTRA_ROWS} blank rows each).`);
  console.log(`[excel-sync] wrote ${config.displayPath(out)}${out === src ? ` (the original is in ${config.displayPath(src)}.bak)` : ''}`);
  if (unmatched.length) console.log(`[excel-sync] not columns in the database, left without validation: ${unmatched.join(', ')}`);
}

main().catch((e) => {
  console.error(connectionHint(e, config.db) || e.message);
  process.exit(1);
});
