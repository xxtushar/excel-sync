'use strict';
/**
 * Admin upload API against a real MySQL (or MariaDB). Each test starts from a fresh copy of the dump in a
 * throwaway database (TEST_DB_NAME, default avyra_test), so your real database is never touched. Login comes
 * from config.json like the server. Without a reachable server these tests are skipped, not failed.
 */

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const express = require('express');
const ExcelJS = require('exceljs');
const mysql = require('mysql2/promise');
const config = require('../src/config');
const { createPool } = require('../src/db/pool');
const { createAdminUploadRouter } = require('../src/api/router');

const TEST_DB = process.env.TEST_DB_NAME || 'avyra_test';
if (TEST_DB === config.db.database) throw new Error(`TEST_DB_NAME must not be your real database (${TEST_DB}): the tests drop and rebuild it.`);
const DUMP = path.join(__dirname, 'fixtures', 'tusharDump.sql');

let admin; // connection without a database, for creating the test database
let available = true;

test.before(async () => {
  try {
    admin = await mysql.createConnection({ ...config.db, database: undefined, multipleStatements: true });
  } catch (e) {
    available = false;
    console.log(`# admin API tests skipped: no database at ${config.db.host}:${config.db.port} (${e.code || e.message})`);
  }
});
test.after(async () => {
  if (admin) {
    await admin.query(`DROP DATABASE IF EXISTS \`${TEST_DB}\``);
    await admin.end();
  }
});

/** Fresh database from the dump, a server on a free port, and helpers to call it. */
async function setup() {
  // The dump starts with CREATE DATABASE avyra / USE avyra: strip them, or it would reload the real database.
  let sql = fs.readFileSync(DUMP, 'utf8').replace(/^\s*(CREATE DATABASE|USE)\b[^;]*;\s*$/gim, '');
  const [[{ v }]] = await admin.query('SELECT VERSION() AS v');
  if (/mariadb/i.test(v)) sql = sql.replace(/utf8mb4_0900_ai_ci/g, 'utf8mb4_unicode_ci'); // MariaDB lacks MySQL 8's default collation
  await admin.query(`DROP DATABASE IF EXISTS \`${TEST_DB}\`; CREATE DATABASE \`${TEST_DB}\`; USE \`${TEST_DB}\`;`);
  await admin.query(sql);

  const pool = createPool({ ...config.db, database: TEST_DB });
  const app = express();
  app.use('/x', createAdminUploadRouter({ pool, database: TEST_DB }));
  const server = await new Promise((resolve) => {
    const s = app.listen(0, () => resolve(s));
  });
  const base = `http://127.0.0.1:${server.address().port}/x`;

  const call = async (method, url, body) => {
    const r = await fetch(base + url, { method, body, headers: body && !(body instanceof FormData) ? { 'content-type': 'application/json' } : {} });
    const type = r.headers.get('content-type') || '';
    return { status: r.status, body: type.includes('json') ? await r.json() : Buffer.from(await r.arrayBuffer()) };
  };
  const template = async () => (await call('GET', '/template')).body;
  const preview = async (buf, extra = {}) => {
    const fd = new FormData();
    fd.append('file', new Blob([buf]), 'upload.xlsx');
    for (const [k, v] of Object.entries(extra)) fd.append(k, v);
    return call('POST', '/preview', fd);
  };
  const apply = (token) => call('POST', '/apply', JSON.stringify({ token }));
  const rows = async (sqlText, params) => (await pool.query(sqlText, params))[0];
  const close = async () => {
    await new Promise((r) => server.close(r));
    await pool.end();
  };
  return { template, preview, apply, rows, close, pool };
}

/** Opens a workbook buffer, lets `fn` change it, returns the new buffer. */
async function edit(buf, fn) {
  const wb = new ExcelJS.Workbook();
  await wb.xlsx.load(buf);
  await fn(wb);
  return Buffer.from(await wb.xlsx.writeBuffer());
}

/** Row number of the sheet row whose first cell (the id) equals id. */
function rowOf(ws, id) {
  for (let r = 2; r <= ws.rowCount; r++) {
    const v = ws.getRow(r).getCell(1).value;
    if (v === id) return r;
  }
  throw new Error(`no row with id ${id} in ${ws.name}`);
}

const dbTest = (name, fn) =>
  test(name, async (t) => {
    if (!available) return t.skip('no database');
    const ctx = await setup();
    try {
      await fn(ctx);
    } finally {
      await ctx.close();
    }
  });

dbTest('the downloaded template matches the database: preview says no changes', async ({ template, preview }) => {
  const r = await preview(await template());
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'no-changes');
});

dbTest('edits, a new row and removed rows: preview shows exactly those, apply saves them, nothing else changes', async ({ template, preview, apply, rows }) => {
  const before = await rows('SELECT COUNT(*) AS n FROM dy_pg_room_info');
  const buf = await edit(await template(), (wb) => {
    const pg = wb.getWorksheet('dy_pg_info');
    pg.getCell(`K${rowOf(pg, 10)}`).value = 'Opp. Apollo Hospital'; // pg_landmark
    const cat = wb.getWorksheet('st_pg_cat');
    for (const id of [7, 6, 5]) cat.spliceRows(rowOf(cat, id), 1); // the three "Boys PG"
    const rooms = wb.getWorksheet('dy_pg_room_info');
    let r = 2;
    while (rooms.getRow(r).getCell(2).value) r++;
    rooms.getRow(r).getCell(1).value = null; // no id: the checker gives the next free one
    rooms.getCell(`B${r}`).value = 'F3-R01-PG009';
    rooms.getCell(`C${r}`).value = 9;
    rooms.getCell(`D${r}`).value = 'single';
  });

  const p = await preview(buf);
  assert.equal(p.status, 200, JSON.stringify(p.body));
  assert.equal(p.body.status, 'preview');
  assert.deepEqual(p.body.summary, { inserts: 1, updates: 1, deletes: 3, tablesChanged: 3 });
  const byTable = Object.fromEntries(p.body.tables.map((t) => [t.table, t]));
  assert.deepEqual(byTable.st_pg_cat.deletes, [5, 6, 7]);
  assert.deepEqual(byTable.dy_pg_info.updates[0].changes, { pg_landmark: { from: 'Near Apollo Hospital', to: 'Opp. Apollo Hospital' } });
  assert.equal(byTable.dy_pg_room_info.inserts[0].values.room_type, 1); // "single" saved as its id

  const a = await apply(p.body.token);
  assert.equal(a.status, 200, JSON.stringify(a.body));
  assert.deepEqual(a.body.summary, { inserts: 1, updates: 1, deletes: 3 });
  assert.deepEqual((await rows('SELECT id FROM st_pg_cat ORDER BY id')).map((r) => r.id), [1, 2, 3, 4]);
  assert.equal((await rows('SELECT pg_landmark FROM dy_pg_info WHERE id = 10'))[0].pg_landmark, 'Opp. Apollo Hospital');
  assert.equal((await rows('SELECT COUNT(*) AS n FROM dy_pg_room_info'))[0].n, before[0].n + 1);
  assert.equal((await rows('SELECT COUNT(*) AS n FROM dy_pg_info'))[0].n, 9);

  assert.equal((await apply(p.body.token)).status, 410, 'a token works once');
  assert.equal((await preview(await template())).body.status, 'no-changes');
});

dbTest('a delete that would leave other rows pointing at nothing is refused, even when those rows are not in the file', async ({ template, preview, rows }) => {
  const buf = await edit(await template(), (wb) => {
    for (const ws of [...wb.worksheets]) if (ws.name !== 'st_pg_cat' && ws.name !== 'Lookups' && ws.name !== '_README') wb.removeWorksheet(ws.id);
    const cat = wb.getWorksheet('st_pg_cat');
    cat.spliceRows(rowOf(cat, 1), 1); // "economy" is used by PGs 9, 13, 17
  });
  const p = await preview(buf);
  assert.equal(p.status, 422, JSON.stringify(p.body));
  assert.match(p.body.errors.map((e) => e.message).join('\n'), /Can't delete st_pg_cat id 1: \d+ row\(s\) in dy_pg_info still use it \(pg_cat/);
  assert.equal((await rows('SELECT COUNT(*) AS n FROM st_pg_cat'))[0].n, 7, 'nothing was saved');
});

dbTest('problems in the file come back with sheet and cell, and nothing is saved', async ({ template, preview, rows }) => {
  const buf = await edit(await template(), (wb) => {
    const pg = wb.getWorksheet('dy_pg_info');
    pg.getCell(`I${rowOf(pg, 10)}`).value = 'hyderbad';
    pg.getCell(`N${rowOf(pg, 13)}`).value = '98765432109876543210';
    pg.getCell(`D${rowOf(pg, 14)}`).value = 99999; // pg_owner: no such user (dy_user is not in the file)
  });
  const p = await preview(buf);
  assert.equal(p.status, 422);
  const at = (cell) => p.body.errors.find((e) => e.cell === cell);
  assert.match(at(`I${3}`).message, /not in the list/);
  assert.match(at(`N${4}`).message, /allows 15/);
  assert.equal(p.body.errors.length, 2, 'the checker stops at file problems; links are checked once the file is clean');

  const fixed = await edit(buf, (wb) => {
    const pg = wb.getWorksheet('dy_pg_info');
    pg.getCell('I3').value = 'hyderabad';
    pg.getCell('N4').value = '9876543210';
  });
  const p2 = await preview(fixed);
  assert.equal(p2.status, 422);
  assert.match(p2.body.errors[0].message, /pg_owner = 99999, but dy_user has no row/);
  assert.equal((await rows('SELECT pg_owner FROM dy_pg_info WHERE id = 14'))[0].pg_owner, 12);
});

dbTest('clearing most of a sheet is refused unless allowMassDelete=true', async ({ template, preview }) => {
  const buf = await edit(await template(), (wb) => {
    const ws = wb.getWorksheet('dy_pg_amns_map'); // select all rows and press Delete
    for (let r = 2; r <= 91; r++) for (let c = 1; c <= 3; c++) ws.getRow(r).getCell(c).value = null;
  });
  const p = await preview(buf);
  assert.equal(p.status, 422);
  assert.match(p.body.errors[0].message, /would delete 90 of the 90 rows in dy_pg_amns_map/);
  const p2 = await preview(buf, { allowMassDelete: 'true' });
  assert.equal(p2.status, 200);
  assert.equal(p2.body.summary.deletes, 90);
});

dbTest('if the database changes between preview and apply, nothing is saved', async ({ template, preview, apply, rows, pool }) => {
  const buf = await edit(await template(), (wb) => {
    const pg = wb.getWorksheet('dy_pg_info');
    pg.getCell(`K${rowOf(pg, 10)}`).value = 'Opp. Apollo Hospital';
  });
  const p = await preview(buf);
  await pool.query("UPDATE dy_pg_info SET pg_major_area = 'Changed meanwhile' WHERE id = 9");
  await pool.query("INSERT INTO st_pg_cat (id, category) VALUES (8, 'luxury')");
  const a = await apply(p.body.token);
  assert.equal(a.status, 409);
  assert.equal(a.body.status, 'changed');
  assert.equal((await rows('SELECT pg_landmark FROM dy_pg_info WHERE id = 10'))[0].pg_landmark, 'Near Apollo Hospital');
});

dbTest('a database error during apply rolls everything back', async ({ template, preview, apply, rows, pool }) => {
  const buf = await edit(await template(), (wb) => {
    const cat = wb.getWorksheet('st_pg_cat');
    cat.spliceRows(rowOf(cat, 7), 1);
    const pg = wb.getWorksheet('dy_pg_info');
    pg.getCell(`K${rowOf(pg, 10)}`).value = 'Opp. Apollo Hospital';
  });
  const p = await preview(buf);
  assert.equal(p.status, 200);
  await pool.query("CREATE TRIGGER no_updates BEFORE UPDATE ON dy_pg_info FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'blocked for the test'");
  const a = await apply(p.body.token);
  assert.equal(a.status, 409);
  assert.match(a.body.message, /blocked for the test/);
  assert.equal((await rows('SELECT COUNT(*) AS n FROM st_pg_cat'))[0].n, 7, 'the delete that ran first was rolled back');
});

dbTest('a file that is not a real .xlsx gets a clear message', async ({ preview }) => {
  const p = await preview(Buffer.from('not a spreadsheet'));
  assert.equal(p.status, 400);
  assert.match(p.body.message, /Could not open the file/);
});
