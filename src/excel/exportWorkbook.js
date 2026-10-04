'use strict';
/**
 * Writes the current database back out as a workbook in the same layout the sync reads:
 * one sheet per table, row 1 = column names, static tabs blue, dynamic tabs green.
 * Use it to refresh your Excel after changes made through the table API.
 */

const ExcelJS = require('exceljs');
const { q } = require('../db');
const { fromDbValue } = require('./normalize');

async function exportWorkbook(pool, schema, { tables } = {}) {
  const wb = new ExcelJS.Workbook();
  wb.creator = 'avyra-excel-sync';
  wb.created = new Date();

  const names = schema.order.filter((n) => !tables || tables.includes(n));
  const readme = wb.addWorksheet('_README');
  readme.getColumn(1).width = 6;
  readme.getColumn(2).width = 30;
  readme.getColumn(3).width = 10;
  readme.getColumn(4).width = 8;
  readme.addRow([`${schema.database} database — exported ${new Date().toISOString().slice(0, 19).replace('T', ' ')}`]).font = { bold: true, size: 14 };
  readme.addRow([]);
  readme.addRow(['Each sheet = one table. Row 1 = exact column names. Empty cell = NULL. Keep the id column; give new rows a new id.']);
  readme.addRow(['Static (st_, blue) tables are never deleted from by sync. Rows removed from dynamic (dy_, green) sheets are soft-deleted where the table supports it.']);
  readme.addRow([]);
  const h = readme.addRow(['#', 'Table (sheet)', 'Type', 'Rows']);
  h.font = { bold: true };

  for (const [i, name] of names.entries()) {
    const t = schema.tables[name];
    const cols = t.columns.filter((c) => !c.generated);
    const [rows] = await pool.query(`SELECT ${cols.map((c) => q(c.name)).join(', ')} FROM ${q(name)} ORDER BY ${q(t.primaryKey[0] || cols[0].name)}`);
    readme.addRow([i + 1, name, t.kind === 'static' ? 'Static' : 'Dynamic', rows.length]);

    const ws = wb.addWorksheet(name.slice(0, 31), {
      properties: { tabColor: { argb: t.kind === 'static' ? 'FF4472C4' : 'FF70AD47' } },
      views: [{ state: 'frozen', ySplit: 1 }],
    });
    ws.columns = cols.map((c) => ({
      header: c.name,
      key: c.name,
      width: Math.min(45, Math.max(10, c.name.length + 2, c.kind === 'datetime' ? 20 : 0)),
      // Text columns stay text so Excel does not turn phone numbers into 9.91E+09 or strip leading zeros.
      style: ['string', 'datetime', 'date', 'time', 'json'].includes(c.kind) ? { numFmt: '@' } : {},
    }));
    ws.getRow(1).font = { bold: true };

    for (const r of rows) {
      ws.addRow(
        cols.map((c) => {
          const v = fromDbValue(c, r[c.name]);
          if (v === null) return null;
          if (c.kind === 'decimal' || c.kind === 'float') return Number(v);
          return v;
        })
      );
    }
  }
  return wb.xlsx.writeBuffer();
}

module.exports = { exportWorkbook };
