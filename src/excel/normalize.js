'use strict';
/**
 * Value coercion shared by the Excel reader and the table API.
 *
 * Every value is turned into the exact shape MySQL hands back (with dateStrings: true), so that
 * "did this cell change?" is a plain comparison:
 *   integer  -> Number (or digit string beyond 2^53)
 *   float    -> Number
 *   decimal  -> string fixed to the column scale, e.g. '10400.00'
 *   datetime -> 'YYYY-MM-DD HH:MM:SS'
 *   date     -> 'YYYY-MM-DD'
 *   string   -> string, kept byte-for-byte (trailing spaces are data)
 *   empty    -> null
 */

const pad = (n, w = 2) => String(n).padStart(w, '0');

/** Unwrap an ExcelJS cell value (formulas, rich text, hyperlinks, errors) into a primitive. */
function unwrapCell(v) {
  if (v === null || v === undefined) return null;
  if (v instanceof Date || typeof v !== 'object') return v;
  if ('result' in v) return unwrapCell(v.result); // formula / shared formula
  if (Array.isArray(v.richText)) return v.richText.map((p) => p.text).join('');
  if ('text' in v) return unwrapCell(v.text); // hyperlink
  if ('error' in v) return { __error: v.error };
  return String(v);
}

// ExcelJS turns date cells into JS Dates whose UTC fields hold the wall-clock time typed in Excel.
function dateToDatetime(d) {
  return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())} ${pad(d.getUTCHours())}:${pad(
    d.getUTCMinutes()
  )}:${pad(d.getUTCSeconds())}`;
}

function excelSerialToDate(n) {
  // Excel's 1900 date system; 25569 = 1970-01-01. Round to whole seconds.
  return new Date(Math.round((n - 25569) * 86400) * 1000);
}

function validYmd(y, m, d) {
  const dt = new Date(Date.UTC(+y, +m - 1, +d));
  return dt.getUTCFullYear() === +y && dt.getUTCMonth() === +m - 1 && dt.getUTCDate() === +d;
}

/** Parse the datetime spellings people actually type. Returns 'YYYY-MM-DD HH:MM:SS' or null. */
function parseDatetimeString(s) {
  s = s.trim();
  let m = s.match(/^(\d{4})-(\d{1,2})-(\d{1,2})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?(Z|[+-]\d{2}:?\d{2})?)?$/);
  if (!m) {
    // Day-first (Indian / UK locale): 25-08-2026, 25/08/2026 16:55, 25.08.2026
    const d = s.match(/^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?$/);
    if (d) m = [d[0], d[3], d[2], d[1], d[4], d[5], d[6]];
  }
  if (!m) return null;
  const [, y, mo, da, h = '0', mi = '0', se = '0', tz] = m;
  if (tz) {
    const dt = new Date(s);
    if (isNaN(dt)) return null;
    return dateToDatetime(dt); // stored as UTC wall time
  }
  if (!validYmd(y, mo, da) || +h > 23 || +mi > 59 || +se > 59) return null;
  return `${y}-${pad(mo)}-${pad(da)} ${pad(h)}:${pad(mi)}:${pad(se)}`;
}

const INT_RE = /^[-+]?\d+$/;
const NUM_RE = /^[-+]?(\d+\.?\d*|\.\d+)(e[-+]?\d+)?$/i;

function cleanNumericString(s) {
  s = s.trim();
  // Allow grouping commas: 10,400.00 or Indian 1,00,000
  if (/^[-+]?\d{1,3}(,\d{2,3})+(\.\d+)?$/.test(s)) s = s.replace(/,/g, '');
  return s;
}

/**
 * Convert an incoming value (Excel cell or JSON body field) to the DB shape for this column.
 * Returns { value } or { error }.
 */
function toDbValue(col, raw) {
  let v = unwrapCell(raw);
  if (v && typeof v === 'object' && v.__error) return { error: `cell contains an Excel error (${v.__error})` };
  if (v === null || v === undefined || v === '') return checkNull(col, null);

  switch (col.kind) {
    case 'integer': {
      if (typeof v === 'boolean') return { value: v ? 1 : 0 };
      if (typeof v === 'number') {
        if (!Number.isFinite(v) || !Number.isInteger(v)) return { error: `expected a whole number, got ${v}` };
        return rangeCheck(col, v);
      }
      if (v instanceof Date) return { error: 'expected a whole number, got a date' };
      const s = cleanNumericString(String(v));
      if (s === '') return checkNull(col, null);
      if (/^(true|false)$/i.test(s)) return { value: /^true$/i.test(s) ? 1 : 0 };
      if (!INT_RE.test(s)) {
        if (NUM_RE.test(s) && Number.isInteger(Number(s))) return rangeCheck(col, Number(s));
        return { error: `expected a whole number, got "${v}"` };
      }
      const n = Number(s);
      return Number.isSafeInteger(n) ? rangeCheck(col, n) : { value: s.replace(/^\+/, '') };
    }
    case 'float': {
      if (typeof v === 'number') return Number.isFinite(v) ? { value: v } : { error: `invalid number ${v}` };
      if (typeof v === 'boolean') return { value: v ? 1 : 0 };
      const s = cleanNumericString(String(v));
      if (!NUM_RE.test(s)) return { error: `expected a number, got "${v}"` };
      return { value: Number(s) };
    }
    case 'decimal': {
      let n;
      if (typeof v === 'number') n = v;
      else if (typeof v === 'boolean') n = v ? 1 : 0;
      else {
        const s = cleanNumericString(String(v));
        if (!NUM_RE.test(s)) return { error: `expected a number, got "${v}"` };
        n = Number(s);
      }
      if (!Number.isFinite(n)) return { error: `invalid number ${v}` };
      if (col.unsigned && n < 0) return { error: `negative value ${n} in an unsigned column` };
      return { value: n.toFixed(col.scale ?? 0) };
    }
    case 'datetime':
    case 'date': {
      let out;
      if (v instanceof Date) out = isNaN(v) ? null : dateToDatetime(v);
      else if (typeof v === 'number') out = v > 0 && v < 2958466 ? dateToDatetime(excelSerialToDate(v)) : null;
      else out = parseDatetimeString(String(v));
      if (!out) return { error: `expected a date like 2026-08-25 16:55:13, got "${v instanceof Date ? v.toISOString() : v}"` };
      return { value: col.kind === 'date' ? out.slice(0, 10) : out };
    }
    case 'time': {
      if (v instanceof Date) return { value: `${pad(v.getUTCHours())}:${pad(v.getUTCMinutes())}:${pad(v.getUTCSeconds())}` };
      return { value: String(v).trim() };
    }
    case 'json': {
      const s = typeof v === 'string' ? v : JSON.stringify(v);
      try {
        JSON.parse(s);
      } catch {
        return { error: 'invalid JSON' };
      }
      return { value: s };
    }
    default: {
      let s;
      if (v instanceof Date) s = dateToDatetime(v);
      else if (typeof v === 'number') s = Number.isInteger(v) && Math.abs(v) >= 1e21 ? BigInt(v).toString() : String(v);
      else if (typeof v === 'boolean') s = v ? 'TRUE' : 'FALSE';
      else if (typeof v === 'object') s = JSON.stringify(v);
      else s = String(v);
      if (col.maxLength != null && [...s].length > col.maxLength)
        return { error: `text is ${[...s].length} characters, column allows ${col.maxLength}` };
      return { value: s };
    }
  }
}

function checkNull(col, value) {
  if (value === null && !col.nullable && !col.autoIncrement) {
    return { value: null, missingRequired: true };
  }
  return { value };
}

const INT_RANGES = {
  tinyint: [-128, 127, 255],
  smallint: [-32768, 32767, 65535],
  mediumint: [-8388608, 8388607, 16777215],
  int: [-2147483648, 2147483647, 4294967295],
  integer: [-2147483648, 2147483647, 4294967295],
};
function rangeCheck(col, n) {
  const r = INT_RANGES[col.dataType];
  if (r) {
    const [min, max, umax] = r;
    if (col.unsigned ? n < 0 || n > umax : n < min || n > max)
      return { error: `${n} is out of range for ${col.columnType}` };
  }
  return { value: n };
}

/** Normalise a value read from MySQL into the same shape toDbValue produces. */
function fromDbValue(col, v) {
  if (v === null || v === undefined) return null;
  switch (col.kind) {
    case 'integer':
      return typeof v === 'number' ? v : Number.isSafeInteger(Number(v)) ? Number(v) : String(v);
    case 'float':
      return Number(v);
    case 'decimal':
      return Number(v).toFixed(col.scale ?? 0);
    case 'datetime':
      return String(v).replace(/\.\d+$/, '');
    case 'date':
      return String(v).slice(0, 10);
    case 'json':
      return typeof v === 'string' ? v : JSON.stringify(v);
    default:
      return Buffer.isBuffer(v) ? v.toString('utf8') : String(v);
  }
}

function sameValue(col, a, b) {
  if (a === null || b === null) return a === b;
  if (col.kind === 'float') return Math.abs(Number(a) - Number(b)) <= 1e-9 * Math.max(1, Math.abs(Number(a)));
  if (col.kind === 'json') {
    try {
      return JSON.stringify(JSON.parse(a)) === JSON.stringify(JSON.parse(b));
    } catch {
      return a === b;
    }
  }
  return String(a) === String(b);
}

module.exports = { toDbValue, fromDbValue, sameValue, unwrapCell, parseDatetimeString };
