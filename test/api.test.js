'use strict';
const { test, before, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const express = require('express');
const { createExcelSync } = require('../src');
const h = require('./helpers');

let server;
let base;
let excelSync;

async function start(opts = {}) {
  const app = express();
  excelSync = await createExcelSync({ db: h.dbConfig, ...opts });
  app.use('/api', excelSync.router);
  await new Promise((r) => (server = app.listen(0, r)));
  base = `http://127.0.0.1:${server.address().port}/api`;
}
async function stop() {
  if (server) await new Promise((r) => server.close(r));
  if (excelSync) await excelSync.close();
  server = excelSync = null;
}

const upload = (url, buf, name = 'pgdump1.xlsx', headers = {}) => {
  const fd = new FormData();
  fd.append('file', new Blob([buf]), name);
  return fetch(base + url, { method: 'POST', body: fd, headers });
};
const json = (method, url, body) =>
  fetch(base + url, { method, headers: { 'content-type': 'application/json' }, body: body && JSON.stringify(body) });

before(async () => {
  await h.resetDb();
  await start();
});
beforeEach(async () => {
  await stop();
  await h.resetDb();
  await start();
});
after(stop);

test('upload: preview → apply → status/logs', async () => {
  const buf = await h.editedWorkbook((wb) => h.setCell(wb.getWorksheet('dy_pg_info'), 10, 'pg_landmark', 'Opp. Apollo Hospital'));

  let res = await upload('/sync/preview', buf);
  let body = await res.json();
  assert.equal(res.status, 200);
  assert.equal(body.status, 'preview');
  assert.equal(body.tables.length, 1);
  assert.deepEqual(body.tables[0].updates[0], {
    id: 10,
    row: 3,
    changes: { pg_landmark: { from: 'Near Apollo Hospital', to: 'Opp. Apollo Hospital' } },
  });

  res = await upload('/sync', buf);
  body = await res.json();
  assert.equal(body.status, 'applied');
  assert.ok(body.logId);

  const row = await (await fetch(`${base}/tables/dy_pg_info/10`)).json();
  assert.equal(row.pg_landmark, 'Opp. Apollo Hospital');

  const logs = await (await fetch(`${base}/sync/logs`)).json();
  assert.equal(logs[0].status, 'applied');
  assert.equal(logs[0].updated, 1);
  const log = await (await fetch(`${base}/sync/logs/${logs[0].id}`)).json();
  assert.deepEqual(log.summary[0].updatedIds, [10]);

  const status = await (await fetch(`${base}/sync/status`)).json();
  assert.equal(status.lastRun.status, 'applied');
});

test('upload: invalid workbook → 422 with errors; wrong file type → 400', async () => {
  const buf = await h.editedWorkbook((wb) => h.setCell(wb.getWorksheet('dy_pg_bed_info'), 127, 'room_info', 4242));
  const res = await upload('/sync', buf);
  assert.equal(res.status, 422);
  const body = await res.json();
  assert.equal(body.status, 'invalid');
  assert.match(body.errors[0].message, /dy_pg_room_info has no row with id 4242/);

  const bad = await upload('/sync', Buffer.from('a,b\n1,2'), 'data.csv');
  assert.equal(bad.status, 400);
  const corrupt = await upload('/sync', Buffer.from('not a zip'), 'x.xlsx');
  assert.equal(corrupt.status, 400);
  assert.match((await corrupt.json()).error, /Could not open the workbook/);
});

test('tables: list, filter, paginate, search', async () => {
  const list = await (await fetch(`${base}/tables`)).json();
  assert.equal(list.tables.length, 51);
  assert.equal(list.tables[0].kind, 'static');
  const bookings = list.tables.find((t) => t.name === 'dy_pg_bookings');
  assert.ok(bookings.foreignKeys.some((f) => f.references === 'dy_pg_bed_info.id'));

  const page = await (await fetch(`${base}/tables/st_pg_ctys?state_id=1&limit=5&page=2&sort=city`)).json();
  assert.equal(page.limit, 5);
  assert.equal(page.page, 2);
  assert.ok(page.rows.every((r) => r.state_id === 1));

  const s = await (await fetch(`${base}/tables/dy_user?search=jas%40gmail`)).json();
  assert.equal(s.total, 1);
  assert.equal(s.rows[0].id, 785);

  assert.equal((await fetch(`${base}/tables/nope`)).status, 404);
  assert.equal((await fetch(`${base}/tables/dy_user%60;DROP%20TABLE%20x`)).status, 404);
  assert.equal((await fetch(`${base}/tables/dy_user?no_such_col=1`)).status, 400);
});

test('tables: create, update, soft delete, hard delete with cascade confirmation', async () => {
  let res = await json('POST', '/tables/dy_pg_events_info', { id: 700, event_date: '25-12-2026 19:00', event_title: 'Christmas', pg_id: 9 });
  assert.equal(res.status, 201);
  assert.equal((await res.json()).event_date, '2026-12-25 19:00:00');

  res = await json('POST', '/tables/dy_invoices', { inv_id: 'INV-X' });
  assert.equal(res.status, 400);
  const prob = await res.json();
  assert.ok(prob.problems.some((p) => p.column === 'booking_id' && p.message === 'required'));

  res = await json('POST', '/tables/dy_pg_events_info', { id: 701, pg_id: 4242 });
  assert.equal(res.status, 400); // FK violation from MySQL

  res = await json('PATCH', '/tables/dy_pg_events_info/700', { event_title: 'Christmas Party' });
  assert.equal((await res.json()).event_title, 'Christmas Party');
  assert.equal((await json('PATCH', '/tables/dy_pg_events_info/700', { id: 5 })).status, 400);

  // dy_user has is_active/rstatus → soft delete
  res = await json('DELETE', '/tables/dy_user/12');
  assert.deepEqual(await res.json(), { deleted: 'soft', table: 'dy_user', id: 12, columnsSetToZero: ['is_active', 'rstatus'] });

  // dy_pg_room_info has no soft-delete column → needs ?hard=true, and confirm because it cascades
  assert.equal((await json('DELETE', '/tables/dy_pg_room_info/279')).status, 409);
  const impact = await (await fetch(`${base}/tables/dy_pg_room_info/279/impact`)).json();
  assert.equal(impact.hardDeleteWouldAlsoRemove.total, 3);
  res = await json('DELETE', '/tables/dy_pg_room_info/279?hard=true');
  assert.equal(res.status, 409);
  res = await json('DELETE', '/tables/dy_pg_room_info/279?hard=true&confirm=true');
  assert.equal((await res.json()).deleted, 'hard');
  assert.equal((await fetch(`${base}/tables/dy_pg_bed_info/127`)).status, 404);
});

test('export → re-upload is a no-op', async () => {
  await json('PATCH', '/tables/dy_pg_info/9', { pg_major_area: 'Madhapur West' });
  const res = await fetch(`${base}/export`);
  assert.equal(res.status, 200);
  const buf = Buffer.from(await res.arrayBuffer());
  const r = await (await upload('/sync?full=true', buf, 'export.xlsx')).json();
  assert.equal(r.status, 'no-changes', JSON.stringify(r.errors));
  assert.equal(r.unchangedSheets.length, 51);
});

test('API key is enforced when configured', async () => {
  await stop();
  await start({ apiKey: 's3cret' });
  assert.equal((await fetch(`${base}/tables`)).status, 401);
  assert.equal((await fetch(`${base}/tables`, { headers: { 'x-api-key': 's3cret' } })).status, 200);
});

test('watcher: saving the workbook updates the database', async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'xlsync-'));
  const file = path.join(dir, 'avyra.xlsx');
  fs.copyFileSync(h.WORKBOOK, file);
  const quiet = { log() {}, error() {} };
  const results = [];
  const w = excelSync.startWatcher({ file, debounceMs: 300, logger: quiet, onResult: (r) => results.push(r) });
  const waitFor = async (pred, ms = 15000) => {
    const t0 = Date.now();
    while (Date.now() - t0 < ms) {
      if (pred()) return;
      await new Promise((r) => setTimeout(r, 100));
    }
    throw new Error('timed out; watcher status: ' + JSON.stringify(w.status()));
  };
  await waitFor(() => results.length >= 1); // startup sync
  assert.equal(results[0].status, 'no-changes');

  // "Save" in Excel: write to a temp file and rename over the original (what Excel does).
  const buf = await h.editedWorkbook((wb) => h.setCell(wb.getWorksheet('dy_pg_info'), 9, 'pg_name', 'Saved From Excel'));
  fs.writeFileSync(file + '.tmp', buf);
  fs.renameSync(file + '.tmp', file);
  await waitFor(() => results.length >= 2);
  assert.equal(results[1].status, 'applied', JSON.stringify(results[1].errors));
  const row = await (await fetch(`${base}/tables/dy_pg_info/9`)).json();
  assert.equal(row.pg_name, 'Saved From Excel');

  // A save that only changes formatting does not touch the DB.
  fs.writeFileSync(file, buf);
  await waitFor(() => results.length >= 3);
  assert.ok(['no-changes'].includes(results[2].status));
  assert.ok(results[2].tables.every((t) => t.status === 'unchanged'));
  fs.rmSync(dir, { recursive: true, force: true });
});
