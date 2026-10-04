'use strict';
const { test, before, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');
const store = require('../src/sync/store');
const { createEngine } = require('../src/sync/engine');
const h = require('./helpers');

let pool;
let engine;

before(() => {
  pool = h.testPool();
});
beforeEach(async () => {
  await h.resetDb();
  await store.ensureTables(pool);
  engine = createEngine(pool, h.TEST_DB);
});
after(async () => {
  await pool.end();
});

const sync = (source, o = {}) => engine.runSync({ source, trigger: 'cli', ...o });
const tableOf = (r, name) => r.tables.find((t) => t.table === name);

test('untouched workbook matches the dump exactly (all 51 sheets, 2209 rows)', async () => {
  const r = await sync(h.WORKBOOK);
  assert.equal(r.status, 'no-changes', JSON.stringify(r.errors));
  assert.equal(r.tables.length, 51);
  assert.ok(r.tables.every((t) => t.status === 'no-changes'));
  assert.equal(r.tables.reduce((a, t) => a + t.sheetRows, 0), 2209);
  assert.equal(r.tables.reduce((a, t) => a + t.dbRows, 0), 2209);
  assert.deepEqual(r.errors, []);
});

test('second sync skips sheets whose content has not changed', async () => {
  await sync(h.WORKBOOK);
  const r = await sync(h.WORKBOOK);
  assert.ok(r.tables.every((t) => t.status === 'unchanged'));
  const full = await sync(h.WORKBOOK, { full: true });
  assert.ok(full.tables.every((t) => t.status === 'no-changes'));
});

test('edit + new row + removed row: preview changes nothing, apply does exactly that', async () => {
  const buf = await h.editedWorkbook((wb) => {
    h.setCell(wb.getWorksheet('dy_pg_info'), 9, 'pg_name', 'Green Valley Residency (renovated)');
    h.appendRow(wb.getWorksheet('dy_pg_events_info'), { id: 500, event_date: '2026-10-20 18:00:00', event_title: 'Diwali Night', event_description: 'Lights and sweets', pg_id: 9 });
    h.deleteRowById(wb.getWorksheet('dy_user'), 12); // has soft-delete columns
    h.deleteRowById(wb.getWorksheet('st_pg_gen'), 3); // static: never deleted
  });

  const preview = await sync(buf, { dryRun: true });
  assert.equal(preview.status, 'preview', JSON.stringify(preview.errors));
  assert.deepEqual(
    { i: preview.totals.inserted, u: preview.totals.updated, s: preview.totals.softDeleted, h: preview.totals.hardDeleted },
    { i: 1, u: 1, s: 1, h: 0 }
  );
  const upd = tableOf(preview, 'dy_pg_info').updates[0];
  assert.deepEqual(upd.set, { pg_name: 'Green Valley Residency (renovated)' });
  assert.equal(upd.before.pg_name, 'Green Valley Residency');
  assert.deepEqual(tableOf(preview, 'st_pg_gen').notDeleted, ['3']);
  assert.equal((await h.one(pool, 'SELECT pg_name FROM dy_pg_info WHERE id=9')).pg_name, 'Green Valley Residency');

  const r = await sync(buf);
  assert.equal(r.status, 'applied', JSON.stringify(r.errors));
  assert.equal((await h.one(pool, 'SELECT pg_name FROM dy_pg_info WHERE id=9')).pg_name, 'Green Valley Residency (renovated)');
  assert.deepEqual(await h.one(pool, 'SELECT event_title, pg_id, event_date FROM dy_pg_events_info WHERE id=500'), {
    event_title: 'Diwali Night',
    pg_id: 9,
    event_date: '2026-10-20 18:00:00',
  });
  assert.deepEqual(await h.one(pool, 'SELECT is_active, rstatus FROM dy_user WHERE id=12'), { is_active: 0, rstatus: 0 });
  assert.ok(await h.one(pool, 'SELECT id FROM dy_pg_guest_info WHERE user_id=12'), 'soft delete must not cascade');
  assert.ok(await h.one(pool, 'SELECT id FROM st_pg_gen WHERE id=3'));

  const again = await sync(buf, { full: true });
  assert.equal(again.status, 'no-changes', 'sync is idempotent');
});

test('dates typed as real Excel dates or dd-mm-yyyy text are understood', async () => {
  const buf = await h.editedWorkbook((wb) => {
    const ws = wb.getWorksheet('dy_pg_events_info');
    h.setCell(ws, 1, 'event_date', new Date(Date.UTC(2026, 7, 15, 10, 0, 0))); // same instant as the text
    h.setCell(ws, 2, 'event_date', '16-09-2026 11:30');
  });
  const r = await sync(buf, { dryRun: true });
  const t = tableOf(r, 'dy_pg_events_info');
  assert.equal(t.updates.length, 1);
  assert.equal(t.updates[0].id, 2);
  assert.deepEqual(t.updates[0].set, { event_date: '2026-09-16 11:30:00' });
});

test('a bad foreign key stops the whole sync and changes nothing', async () => {
  const buf = await h.editedWorkbook((wb) => {
    h.setCell(wb.getWorksheet('dy_pg_info'), 9, 'pg_name', 'Should not be saved');
    h.setCell(wb.getWorksheet('dy_pg_events_info'), 1, 'pg_id', 9999);
  });
  const r = await sync(buf);
  assert.equal(r.status, 'invalid');
  assert.match(r.errors[0].message, /dy_pg_info has no row with id 9999/);
  assert.equal(r.errors[0].sheet, 'dy_pg_events_info');
  assert.equal((await h.one(pool, 'SELECT pg_name FROM dy_pg_info WHERE id=9')).pg_name, 'Green Valley Residency');
});

test('bad cell values are reported with sheet, row and column', async () => {
  const buf = await h.editedWorkbook((wb) => {
    h.setCell(wb.getWorksheet('dy_pg_bed_info'), 127, 'bed_number', 'two');
    h.setCell(wb.getWorksheet('dy_pg_events_info'), 1, 'event_date', '31-02-2026');
  });
  const r = await sync(buf);
  assert.equal(r.status, 'invalid');
  const bed = r.errors.find((e) => e.sheet === 'dy_pg_bed_info');
  assert.equal(bed.column, 'bed_number');
  assert.match(bed.message, /whole number/);
  assert.ok(r.errors.find((e) => e.sheet === 'dy_pg_events_info' && /expected a date/.test(e.message)));
});

test('a new row with an empty id is rejected with a suggested id', async () => {
  const buf = await h.editedWorkbook((wb) => h.appendRow(wb.getWorksheet('st_pg_gen'), { gender_type: 'Other' }));
  const r = await sync(buf);
  assert.equal(r.status, 'invalid');
  assert.match(r.errors[0].message, /Empty id.*e\.g\. 4/);
});

test('rows removed from a table without a soft-delete column are kept unless deleteMode=hard', async () => {
  const buf = await h.editedWorkbook((wb) => h.deleteRowById(wb.getWorksheet('dy_pg_events_info'), 3));
  const soft = await sync(buf); // applied in soft mode: row 3 is kept, sheet hash remembered
  assert.deepEqual(tableOf(soft, 'dy_pg_events_info').notDeleted, ['3']);
  assert.ok(soft.warnings.some((w) => /no soft-delete column/.test(w.message)));
  assert.ok(await h.one(pool, 'SELECT id FROM dy_pg_events_info WHERE id=3'));

  const hard = await sync(buf, { deleteMode: 'hard' });
  assert.equal(hard.status, 'applied', JSON.stringify(hard.errors));
  assert.equal(await h.one(pool, 'SELECT id FROM dy_pg_events_info WHERE id=3'), undefined);
});

test('hard delete that would cascade into rows still in other sheets is refused', async () => {
  const buf = await h.editedWorkbook((wb) => h.deleteRowById(wb.getWorksheet('dy_pg_room_info'), 279));
  const r = await sync(buf, { deleteMode: 'hard' });
  assert.equal(r.status, 'invalid');
  assert.deepEqual(tableOf(r, 'dy_pg_room_info').cascade.cascade, { dy_pg_bed_info: 2, dy_pg_bookings: 1 });
  assert.ok(r.errors.some((e) => e.sheet === 'dy_pg_bed_info' && /127/.test(e.message)));
  assert.ok(await h.one(pool, 'SELECT id FROM dy_pg_room_info WHERE id=279'));

  // Removing the children from their sheets too makes it consistent, and it goes through.
  const buf2 = await h.editedWorkbook((wb) => {
    h.deleteRowById(wb.getWorksheet('dy_pg_room_info'), 279);
    h.deleteRowById(wb.getWorksheet('dy_pg_bed_info'), 127);
    h.deleteRowById(wb.getWorksheet('dy_pg_bed_info'), 316);
    h.deleteRowById(wb.getWorksheet('dy_pg_bookings'), 826);
  });
  const r2 = await sync(buf2, { deleteMode: 'hard' });
  assert.equal(r2.status, 'applied', JSON.stringify(r2.errors));
  assert.equal(await h.one(pool, 'SELECT id FROM dy_pg_bed_info WHERE id IN (127,316)'), undefined);
});

test('emptying a sheet by accident is blocked unless allowMassDelete', async () => {
  const buf = await h.editedWorkbook((wb) => {
    // Select all data rows and press Delete: the cells are cleared, the rows stay (blank rows are skipped).
    const ws = wb.getWorksheet('dy_user_roles');
    for (let r = 2; r <= ws.rowCount; r++) ws.getRow(r).eachCell((c) => (c.value = null));
  });
  const r = await sync(buf);
  assert.equal(r.status, 'invalid');
  assert.match(r.errors[0].message, /allowMassDelete/);
  const ok = await sync(buf, { allowMassDelete: true, dryRun: true });
  assert.equal(ok.status, 'preview');
  assert.equal(tableOf(ok, 'dy_user_roles').softDeletes.length, 203);
});

test('if MySQL rejects any change, the whole sync is rolled back', async () => {
  const buf = await h.editedWorkbook((wb) => {
    h.setCell(wb.getWorksheet('dy_pg_info'), 9, 'pg_name', 'Should be rolled back');
    h.setCell(wb.getWorksheet('dy_invoices'), 275, 'inv_amount', 1e12); // too big for DECIMAL(10,2)
  });
  const r = await sync(buf);
  assert.equal(r.status, 'failed');
  assert.match(r.errors.at(-1).message, /dy_invoices.*Out of range/i);
  assert.equal((await h.one(pool, 'SELECT pg_name FROM dy_pg_info WHERE id=9')).pg_name, 'Green Valley Residency');
  const log = await h.one(pool, 'SELECT status FROM _excel_sync_log ORDER BY id DESC LIMIT 1');
  assert.equal(log.status, 'failed');
});

test('unknown columns are ignored with a warning; a sheet without the id column is an error', async () => {
  const buf = await h.editedWorkbook((wb) => {
    const ws = wb.getWorksheet('st_pg_gen');
    ws.getRow(1).getCell(3).value = 'my_notes';
    ws.getRow(2).getCell(3).value = 'scratch';
    wb.getWorksheet('st_pg_role').getRow(1).getCell(1).value = 'role_id';
  });
  const r = await sync(buf, { dryRun: true });
  assert.ok(r.warnings.some((w) => w.sheet === 'st_pg_gen' && /my_notes/.test(w.message)));
  assert.ok(r.errors.some((e) => e.sheet === 'st_pg_role' && /no "id" column/.test(e.message)));
});

test('sheets are applied parents-first: a new PG and its room in one save', async () => {
  const buf = await h.editedWorkbook((wb) => {
    h.appendRow(wb.getWorksheet('dy_pg_info'), { id: 900, pg_id: 'New_PG_900', pg_name: 'New PG', pg_owner: 779, pg_cat: 1, pg_type_id: 1, pg_desc_id: 1, pg_city: 1, pg_state: 1, pg_status: 1 });
    h.appendRow(wb.getWorksheet('dy_pg_room_info'), { id: 901, room_name: 'F1-R01-PG900', pg_info: 900, room_type: 1, bathroom_type: 1, floor_info: 1 });
  });
  const r = await sync(buf);
  assert.equal(r.status, 'applied', JSON.stringify(r.errors));
  assert.equal((await h.one(pool, 'SELECT pg_info FROM dy_pg_room_info WHERE id=901')).pg_info, 900);
});
