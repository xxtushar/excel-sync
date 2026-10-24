'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const ExcelJS = require('exceljs');
const { columnRule, addValidation, lastDataRow, EXTRA_ROWS } = require('../src/excel/validation');
const { kindOf } = require('../src/schema/introspect');

/** A column the way introspect describes it, from its MySQL type. */
function col(name, columnType, extra = {}) {
  const dataType = columnType.replace(/\(.*$/, '').replace(/ unsigned$/, '');
  const len = /^(var)?char\((\d+)\)/.exec(columnType);
  const maxLength = len ? Number(len[2]) : { text: 65535, tinytext: 255 }[dataType] ?? null;
  return { name, columnType, dataType, kind: kindOf(dataType), unsigned: /unsigned/.test(columnType), maxLength, nullable: true, ...extra };
}

test('each MySQL type gets the matching Excel rule', () => {
  const rule = (c) => columnRule(c, 'B2').rule;
  assert.deepEqual(rule(col('id', 'int')), { type: 'whole', operator: 'between', formulae: [-2147483648, 2147483647] });
  assert.deepEqual(rule(col('n', 'int unsigned')).formulae, [0, 4294967295]);
  assert.deepEqual(rule(col('flag', 'tinyint')).formulae, [-128, 127]);
  assert.deepEqual(rule(col('amount', 'decimal(10,2)')), { type: 'decimal', operator: 'between', formulae: [-99999999.99, 99999999.99] });
  assert.deepEqual(rule(col('amount', 'decimal(5,2) unsigned')).formulae, [0, 999.99]);
  assert.equal(rule(col('score', 'double')).type, 'decimal');
  assert.deepEqual(rule(col('mobile', 'varchar(15)')), { type: 'textLength', operator: 'lessThanOrEqual', formulae: [15] });
  assert.deepEqual(rule(col('notes', 'text')).formulae, [32767]); // Excel's own cell limit
  assert.deepEqual(rule(col('size', "enum('s','m','l')")), { type: 'list', formulae: ['"s,m,l"'] });
  assert.equal(rule(col('at', 'datetime')).type, 'custom');
  assert.match(rule(col('at', 'datetime')).formulae[0], /ISNUMBER\(B2\)/);
  assert.deepEqual(rule(col('meta', 'json')), { type: 'custom', formulae: ['ISTEXT(B2)'] });
});

test('validation covers the data plus blank rows, and running it again replaces it', async () => {
  const t = {
    columnMap: {},
    primaryKey: ['id'],
    foreignKeys: [{ column: 'user_id', refTable: 'dy_user' }],
  };
  for (const c of [col('id', 'int', { nullable: false }), col('user_id', 'int'), col('mobile', 'varchar(15)')]) t.columnMap[c.name] = c;

  const wb = new ExcelJS.Workbook();
  const ws = wb.addWorksheet('dy_x');
  ws.addRow(['id', 'user_id', 'mobile', 'my notes']);
  ws.addRow([1, 10, '9876543210', 'anything']);
  ws.addRow([2, 11, '9876543211']);
  assert.equal(lastDataRow(ws), 3);
  assert.equal(addValidation(ws, t, lastDataRow(ws)), 3);

  const end = 3 + EXTRA_ROWS;
  assert.deepEqual(Object.keys(ws.dataValidations.model).sort(), [`A2:A${end}`, `B2:B${end}`, `C2:C${end}`]);
  assert.match(ws.dataValidations.model[`B2:B${end}`].prompt, /Must be an id in dy_user/);
  assert.equal(ws.dataValidations.model[`C2:C${end}`].errorStyle, 'stop');

  // Read back (ExcelJS expands ranges to single cells), then validate again: no leftovers, no duplicates.
  const again = new ExcelJS.Workbook();
  await again.xlsx.load(await wb.xlsx.writeBuffer());
  const ws2 = again.getWorksheet('dy_x');
  addValidation(ws2, t, lastDataRow(ws2));
  assert.deepEqual(Object.keys(ws2.dataValidations.model).sort(), [`A2:A${end}`, `B2:B${end}`, `C2:C${end}`]);
});
