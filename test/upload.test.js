'use strict';
// The upload checker: no database needed, so these run anywhere (npm run test:upload).

const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');
const ExcelJS = require('exceljs');
const { schemaFromDump } = require('../src/schema/fromDump');
const { prepareWorkbook } = require('../src/upload/prepare');

const FIX = path.join(__dirname, 'fixtures');
const schema = schemaFromDump(fs.readFileSync(path.join(FIX, 'tusharDump.sql'), 'utf8'));

async function edited(edit) {
  const wb = new ExcelJS.Workbook();
  await wb.xlsx.readFile(path.join(FIX, 'pgdump1.xlsx'));
  edit(wb);
  return Buffer.from(await wb.xlsx.writeBuffer());
}

test('schema comes from the dump: columns, keys and foreign keys', () => {
  assert.strictEqual(Object.keys(schema.tables).length, 51);
  const pg = schema.tables.dy_pg_info;
  assert.deepStrictEqual(pg.primaryKey, ['id']);
  assert.strictEqual(pg.columnMap.pg_primary_contact_no.maxLength, 15);
  assert.ok(pg.foreignKeys.some((f) => f.column === 'pg_city' && f.refTable === 'st_pg_ctys'));
  assert.deepStrictEqual(schema.tables.dy_invoices.uniqueKeys[0].columns, ['inv_id']);
});

test('the untouched workbook is ready to upload, with a dropdown for every static table it uses', async () => {
  const r = await prepareWorkbook(path.join(FIX, 'pgdump1.xlsx'), schema);
  assert.strictEqual(r.ok, true, JSON.stringify(r.errors.slice(0, 3)));
  for (const t of ['st_pg_ctys', 'st_pg_state', 'st_pg_cur_sts', 'st_pg_room_type']) assert.ok(r.dropdowns.includes(t), t);
  const out = new ExcelJS.Workbook();
  await out.xlsx.load(r.buffer);
  assert.ok(!out.getWorksheet('_Check'), 'a ready file has no _Check sheet');
  assert.match(String(out.getWorksheet('Lookups').getCell('A2').value.formula), /INDEX\('st_pg_/);
});

test('bad values are flagged on their cell and nothing is called ready', async () => {
  const buf = await edited((wb) => {
    wb.getWorksheet('dy_pg_room_info').getCell('C2').value = 999; // no such PG
    wb.getWorksheet('dy_pg_info').getCell('I3').value = 'hyderbad'; // typo in a dropdown column
    wb.getWorksheet('dy_pg_info').getCell('N4').value = '98765432109876543210'; // longer than varchar(15)
  });
  const r = await prepareWorkbook(buf, schema);
  assert.strictEqual(r.ok, false);
  const at = (sheet, cell) => r.errors.find((e) => e.sheet === sheet && e.cell === cell);
  assert.match(at('dy_pg_room_info', 'C2').message, /no row with id 999/);
  assert.match(at('dy_pg_info', 'I3').message, /not in the list/);
  assert.match(at('dy_pg_info', 'N4').message, /allows 15/);
  const out = new ExcelJS.Workbook();
  await out.xlsx.load(r.buffer);
  assert.ok(out.getWorksheet('_Check'));
  assert.ok(String(out.getWorksheet('dy_pg_info').getCell('I3').note).length > 0 || out.getWorksheet('dy_pg_info').getCell('I3').note);
});

test('a new row without an id gets the next free one, and a name is turned into "id – name"', async () => {
  let row;
  const buf = await edited((wb) => {
    const ws = wb.getWorksheet('dy_pg_room_info');
    row = ws.rowCount + 1;
    ws.getRow(row).values = [null, 'F9-R01-PG009', 9, 'single'];
  });
  const r = await prepareWorkbook(buf, schema);
  assert.strictEqual(r.ok, true, JSON.stringify(r.errors.slice(0, 3)));
  const out = new ExcelJS.Workbook();
  await out.xlsx.load(r.buffer);
  const ws = out.getWorksheet('dy_pg_room_info');
  assert.ok(ws.getCell(`A${row}`).value >= schema.tables.dy_pg_room_info.nextId);
  assert.strictEqual(ws.getCell(`D${row}`).value, '1 – single');
});

test('--ids writes plain ids in dropdown columns', async () => {
  const r = await prepareWorkbook(path.join(FIX, 'pgdump1.xlsx'), schema, { ids: true });
  const out = new ExcelJS.Workbook();
  await out.xlsx.load(r.buffer);
  assert.strictEqual(typeof out.getWorksheet('dy_pg_info').getCell('I2').value, 'number');
});
