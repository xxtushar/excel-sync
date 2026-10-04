'use strict';
/**
 * Test helpers. Tests run against a throwaway database (TEST_DB_NAME, default avyra_test) that is rebuilt
 * from the original dump before every test, so they never touch your real `avyra` database.
 */

const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const ExcelJS = require('exceljs');
const config = require('../src/config');
const { createPool } = require('../src/db');

const TEST_DB = process.env.TEST_DB_NAME || 'avyra_test';
const DUMP = path.join(__dirname, 'fixtures', 'tusharDump.sql');
const WORKBOOK = path.join(__dirname, 'fixtures', 'pgdump1.xlsx');
const dbConfig = { ...config.db, database: TEST_DB };

let dumpSql;
async function resetDb() {
  dumpSql ||= fs.readFileSync(DUMP, 'utf8').replace(/`avyra`/g, '`' + TEST_DB + '`');
  const conn = await mysql.createConnection({ ...config.db, database: undefined, multipleStatements: true });
  try {
    await conn.query(`DROP DATABASE IF EXISTS \`${TEST_DB}\``);
    await conn.query(dumpSql);
  } finally {
    await conn.end();
  }
}

function testPool() {
  return createPool(dbConfig);
}

/** Load the original workbook, let `edit(wb)` change it, return the new xlsx as a Buffer. */
async function editedWorkbook(edit) {
  const wb = new ExcelJS.Workbook();
  await wb.xlsx.readFile(WORKBOOK);
  if (edit) await edit(wb);
  return Buffer.from(await wb.xlsx.writeBuffer());
}

/** Find the worksheet row whose first cell (id) equals `id`. */
function rowById(ws, id) {
  for (let r = 2; r <= ws.rowCount; r++) if (String(ws.getRow(r).getCell(1).value) === String(id)) return ws.getRow(r);
  throw new Error(`id ${id} not found in ${ws.name}`);
}

function colIndex(ws, name) {
  const header = ws.getRow(1);
  for (let c = 1; c <= header.cellCount; c++) if (header.getCell(c).value === name) return c;
  throw new Error(`column ${name} not in ${ws.name}`);
}

function setCell(ws, id, column, value) {
  rowById(ws, id).getCell(colIndex(ws, column)).value = value;
}

function deleteRowById(ws, id) {
  ws.spliceRows(rowById(ws, id).number, 1);
}

function appendRow(ws, obj) {
  const header = ws.getRow(1);
  const vals = [];
  for (let c = 1; c <= header.cellCount; c++) vals.push(obj[header.getCell(c).value] ?? null);
  // Put it right after the last non-empty row (some sheets have trailing blank rows).
  let last = 1;
  for (let r = 2; r <= ws.rowCount; r++) if (ws.getRow(r).getCell(1).value != null) last = r;
  ws.insertRow(last + 1, vals);
}

async function one(pool, sql, params) {
  const [rows] = await pool.query(sql, params);
  return rows[0];
}

module.exports = { TEST_DB, WORKBOOK, dbConfig, resetDb, testPool, editedWorkbook, setCell, deleteRowById, appendRow, rowById, one };
