'use strict';
/**
 * Excel data validation built from each column's MySQL type, so Excel refuses a value the database would refuse:
 * text in a number column, a fraction in a whole-number column, a number outside the column's range, text longer
 * than the column, or a date that is not a date. A note on each column says what it takes.
 *
 * Validation covers the rows with data plus EXTRA_ROWS blank rows below them. Not whole columns: ExcelJS turns
 * every validated cell into its own entry when it reads a workbook, so a million-row range would make every sync
 * read a million entries per column. Excel does not check pasted values; the sync still checks every cell.
 */

const EXTRA_ROWS = 1000;

const INT_RANGES = {
  tinyint: [-128, 127, 255],
  smallint: [-32768, 32767, 65535],
  mediumint: [-8388608, 8388607, 16777215],
  int: [-2147483648, 2147483647, 4294967295],
  integer: [-2147483648, 2147483647, 4294967295],
  // Excel keeps 15 significant digits, so a bigint is limited to what Excel can hold exactly.
  bigint: [-999999999999999, 999999999999999, 999999999999999],
};

const MAX_EXCEL_TEXT = 32767;

/** The [min, max] a column accepts as a whole number, or null when it is not a whole-number column. */
function intRange(col) {
  if (col.dataType === 'year') return [1901, 2155];
  if (col.dataType === 'bit') return [0, 2 ** Math.min(Number(/\d+/.exec(col.columnType) || 1), 48) - 1];
  const r = INT_RANGES[col.dataType];
  if (!r) return null;
  return col.unsigned ? [0, r[2]] : [r[0], r[1]];
}

/** decimal(p,s): the largest value p digits with s after the point can hold. */
function decimalRange(col) {
  const m = /\((\d+)(?:,(\d+))?\)/.exec(col.columnType);
  const p = m ? Number(m[1]) : 10;
  const s = m && m[2] ? Number(m[2]) : 0;
  const max = Number((10 ** (p - s) - 10 ** -s).toFixed(s));
  return [col.unsigned ? 0 : -max, max, s];
}

/** enum('a','b') → ['a', 'b'], or null when a value would not fit an Excel list (commas, too long). */
function enumValues(col) {
  if (col.dataType !== 'enum') return null;
  const values = [...col.columnType.matchAll(/'((?:[^']|'')*)'/g)].map((m) => m[1].replace(/''/g, "'"));
  const list = values.join(',');
  return values.some((v) => v.includes(',') || v.includes('"')) || list.length > 255 ? null : values;
}

const fmt = (n) => n.toLocaleString('en-US', { maximumFractionDigits: 10 });

// Date formulas run against the first cell of the range; Excel shifts them for every other row. A date is either
// a real Excel date, or text the sync reads: YYYY-MM-DD, with HH:MM or HH:MM:SS for date-times.
// Excel and LibreOffice evaluate every argument of AND/OR, so one VALUE() error would turn the whole formula into
// an error; each branch is wrapped to read as FALSE instead.
const orFalse = (f) => `IFERROR(${f},FALSE)`;

function isoDateText(a) {
  return `AND(ISTEXT(${a}),MID(${a},5,1)="-",MID(${a},8,1)="-",ISNUMBER(DATEVALUE(LEFT(${a},10))))`;
}
function dateFormula(a, withTime) {
  // TIMEVALUE alone lets 25:00 through (it wraps past midnight), so the hours, minutes and seconds are checked too.
  const time = orFalse(
    `AND(OR(LEN(${a})=16,LEN(${a})=19),MID(${a},11,1)=" ",ISNUMBER(TIMEVALUE(MID(${a},12,8))),` +
      `VALUE(MID(${a},12,2))<24,VALUE(MID(${a},15,2))<60,IF(LEN(${a})=16,TRUE,VALUE(MID(${a},18,2))<60))`
  );
  const text = orFalse(withTime ? `AND(${isoDateText(a)},OR(LEN(${a})=10,${time}))` : `AND(${isoDateText(a)},LEN(${a})=10)`);
  return `OR(${orFalse(`AND(ISNUMBER(${a}),${a}>=1)`)},${text})`;
}

/**
 * The validation for one column, written against `firstCell` (e.g. 'C2'), or null when there is nothing to check.
 * @returns {{ rule: object, takes: string } | null}  rule is an ExcelJS data validation; takes describes it
 */
function columnRule(col, firstCell) {
  const range = intRange(col);
  if (range) {
    const [min, max] = range;
    return {
      takes: `a whole number from ${fmt(min)} to ${fmt(max)}`,
      rule: { type: 'whole', operator: 'between', formulae: [min, max] },
    };
  }
  switch (col.kind) {
    case 'decimal': {
      const [min, max, scale] = decimalRange(col);
      return {
        takes: `a number from ${fmt(min)} to ${fmt(max)}${scale ? `, rounded to ${scale} decimal place(s)` : ''}`,
        rule: { type: 'decimal', operator: 'between', formulae: [min, max] },
      };
    }
    case 'float':
      return {
        takes: 'a number',
        rule: { type: 'decimal', operator: 'between', formulae: [col.unsigned ? 0 : -1e307, 1e307] },
      };
    case 'datetime':
      return { takes: 'a date and time, like 2026-08-25 16:55:13', rule: { type: 'custom', formulae: [dateFormula(firstCell, true)] } };
    case 'date':
      return { takes: 'a date, like 2026-08-25', rule: { type: 'custom', formulae: [dateFormula(firstCell, false)] } };
    case 'time':
      return {
        takes: 'a time, like 16:55:13',
        rule: { type: 'custom', formulae: [`OR(ISNUMBER(${firstCell}),ISNUMBER(TIMEVALUE(${firstCell})))`] },
      };
    case 'json':
      return { takes: 'JSON text, like {"key": "value"}', rule: { type: 'custom', formulae: [`ISTEXT(${firstCell})`] } };
    default: {
      const values = enumValues(col);
      if (values) return { takes: `one of: ${values.join(', ')}`, rule: { type: 'list', formulae: [`"${values.join(',')}"`] } };
      if (!col.maxLength) return null;
      const max = Math.min(col.maxLength, MAX_EXCEL_TEXT);
      return { takes: `text, at most ${fmt(max)} characters`, rule: { type: 'textLength', operator: 'lessThanOrEqual', formulae: [max] } };
    }
  }
}

/** Short type label for the note title (Excel allows 32 characters). */
const titleOf = (col) => `${col.name} (${col.columnType})`.slice(0, 32);

/**
 * Validates every column of `t` found in the sheet's header row, from row 2 down to `lastRow` + EXTRA_ROWS.
 * Validation this function wrote earlier on those columns is replaced; other validation is left alone.
 * @param {import('exceljs').Worksheet} ws
 * @param {object} t        table from introspect
 * @param {number} lastRow  last row holding data (1 when the sheet is empty)
 * @param {object} [lookupRanges]  table → list range (lookups.js); a foreign key to one of them becomes a dropdown
 * @returns {number} columns validated
 */
function addValidation(ws, t, lastRow, lookupRanges = {}) {
  const end = Math.max(lastRow, 1) + EXTRA_ROWS;
  const header = ws.getRow(1);
  let count = 0;
  for (let c = 1; c <= header.cellCount; c++) {
    const col = t.columnMap[String(header.getCell(c).value ?? '').trim().toLowerCase()];
    if (!col || col.generated) continue;
    const letter = ws.getColumn(c).letter;
    clearColumn(ws, letter);
    const fk = t.foreignKeys.find((f) => f.column === col.name);
    const list = fk && lookupRanges[fk.refTable];
    const r = list
      ? { takes: `a name from the ${fk.refTable} dropdown`, rule: { type: 'list', formulae: [list] } }
      : columnRule(col, `${letter}2`);
    if (!r) continue;
    const notes = [
      `Takes ${r.takes}.`,
      fk ? `Must be an id in ${fk.refTable}.` : '',
      col.name === t.primaryKey[0] ? 'Row id: unique, never reuse one.' : '',
      col.nullable || col.autoIncrement ? '' : 'Required.',
    ].filter(Boolean);
    ws.dataValidations.add(`${letter}2:${letter}${end}`, {
      ...r.rule,
      allowBlank: true, // an empty cell means NULL; the sync reports required columns left empty
      showInputMessage: true,
      promptTitle: titleOf(col),
      prompt: notes.join(' ').slice(0, 255),
      showErrorMessage: true,
      errorStyle: 'stop',
      errorTitle: `Not allowed in ${col.name}`.slice(0, 32),
      error: `${col.name} takes ${r.takes}.`.slice(0, 255),
    });
    count++;
  }
  return count;
}

/** Remove validation on one column (as read back by ExcelJS: one entry per cell, or a range we added). */
function clearColumn(ws, letter) {
  const model = ws.dataValidations.model;
  const re = new RegExp(`^${letter}\\d+(:${letter}\\d+)?$`);
  for (const key of Object.keys(model)) if (re.test(key)) delete model[key];
}

/** Last row with anything in the first column (the id), ignoring trailing blank rows. */
function lastDataRow(ws) {
  for (let r = ws.rowCount; r > 1; r--) {
    const v = ws.getRow(r).getCell(1).value;
    if (v !== null && v !== undefined && v !== '') return r;
  }
  return 1;
}

module.exports = { EXTRA_ROWS, columnRule, addValidation, lastDataRow };
