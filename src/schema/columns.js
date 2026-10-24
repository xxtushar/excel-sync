'use strict';
/**
 * Column types and definitions, shared by the column API and by Excel sheets that add columns.
 *
 * DDL cannot take bound parameters, so types are never passed through as typed: parseType() accepts a fixed
 * list of MySQL types and rebuilds the SQL from it. Names must be plain identifiers, defaults go through escape().
 */

const { escape } = require('mysql2/promise');
const { q } = require('../db');
const { kindOf } = require('./introspect');

const NAME_RE = /^[A-Za-z_][A-Za-z0-9_]{0,63}$/;
const TYPE_RE = /^\s*([a-z]+)\s*(?:\(\s*(\d+)\s*(?:,\s*(\d+)\s*)?\))?\s*(unsigned)?\s*$/i;

const INTEGER_TYPES = ['tinyint', 'smallint', 'mediumint', 'int', 'bigint'];
const PLAIN_TYPES = ['float', 'double', 'date', 'datetime', 'timestamp', 'time', 'year', 'json'];
const TEXT_TYPES = { tinytext: 255, text: 65535, mediumtext: 16777215, longtext: 4294967295 };
const LENGTH_TYPES = { char: 255, varchar: 16383 };
const STRING_TYPES = new Set([...Object.keys(TEXT_TYPES), ...Object.keys(LENGTH_TYPES)]);
// MySQL only allows expression defaults on these, so a literal default is refused.
const NO_LITERAL_DEFAULT = new Set([...Object.keys(TEXT_TYPES), 'json']);

const TYPE_HELP =
  'Use one of: int, bigint, tinyint, smallint, mediumint (optionally unsigned), boolean, decimal(p,s), float, double, ' +
  'varchar(n), char(n), text, tinytext, mediumtext, longtext, date, datetime, timestamp, time, year, json.';

const INT_MIN = -2147483648;
const INT_MAX = 2147483647;

function isValidColumnName(name) {
  return typeof name === 'string' && NAME_RE.test(name);
}

/** 'Decimal(10, 2)' → { dataType: 'decimal', columnType: 'decimal(10,2)', kind, scale: 2, ... }, or null if not allowed. */
function parseType(spec) {
  const m = TYPE_RE.exec(String(spec ?? ''));
  if (!m) return null;
  const [, rawName, a, b, unsignedWord] = m;
  const unsigned = !!unsignedWord;
  let name = rawName.toLowerCase();
  if (name === 'integer') name = 'int';
  if (name === 'numeric') name = 'decimal';

  const type = (dataType, columnType, extra = {}) => ({
    dataType,
    columnType,
    kind: kindOf(dataType),
    scale: null,
    maxLength: null,
    unsigned,
    ...extra,
  });

  // tinyint(1) is how MySQL lists a boolean, so it is accepted back as one.
  const isBool = name === 'bool' || name === 'boolean' ? a === undefined : name === 'tinyint' && a === '1' && b === undefined;
  if (isBool) return unsigned ? null : type('tinyint', 'tinyint(1)');
  if (INTEGER_TYPES.includes(name)) return a ? null : type(name, unsigned ? `${name} unsigned` : name);
  if (unsigned) return null;
  if (name === 'decimal') {
    const precision = a === undefined ? 10 : Number(a);
    const scale = b === undefined ? 0 : Number(b);
    if (precision < 1 || precision > 65 || scale > 30 || scale > precision) return null;
    return type('decimal', `decimal(${precision},${scale})`, { scale });
  }
  if (name in LENGTH_TYPES) {
    const n = Number(a);
    if (a === undefined || b !== undefined || n < 1 || n > LENGTH_TYPES[name]) return null;
    return type(name, `${name}(${n})`, { maxLength: n });
  }
  if (a !== undefined) return null;
  if (name in TEXT_TYPES) return type(name, name, { maxLength: TEXT_TYPES[name] });
  if (PLAIN_TYPES.includes(name)) return type(name, name);
  return null;
}

/**
 * Picks a type for a new column from the Excel cells under its header (blank cells already removed).
 * It goes by the cell type Excel stored, so a phone number kept as Text stays text.
 */
function inferType(values) {
  if (!values.length) return 'varchar(255)';
  if (values.every((v) => v instanceof Date && !isNaN(v))) {
    const midnight = (d) => d.getUTCHours() === 0 && d.getUTCMinutes() === 0 && d.getUTCSeconds() === 0;
    return values.every(midnight) ? 'date' : 'datetime';
  }
  if (values.every((v) => typeof v === 'boolean')) return 'boolean';
  if (values.every((v) => typeof v === 'number' && Number.isFinite(v))) {
    if (values.every(Number.isSafeInteger)) return values.every((n) => n >= INT_MIN && n <= INT_MAX) ? 'int' : 'bigint';
    if (values.every((n) => Math.abs(n) < 1e13 && Number(n.toFixed(2)) === n)) return 'decimal(15,2)';
    return 'double';
  }
  const longest = values.reduce((max, v) => Math.max(max, [...String(v)].length), 0);
  return longest <= 255 ? 'varchar(255)' : 'text';
}

/** A column that does not exist yet, shaped like the ones introspect() returns. */
function pendingColumn(name, spec, { nullable = true } = {}) {
  const type = parseType(spec);
  if (!type) throw new Error(`Unsupported column type "${spec}".`);
  return {
    name,
    ...type,
    nullable,
    hasDefault: nullable,
    autoIncrement: false,
    generated: false,
    defaultValue: null,
    extra: '',
    collation: null,
    comment: '',
  };
}

/**
 * SQL for one column definition. `col.columnType` is either rebuilt by parseType() or read from
 * INFORMATION_SCHEMA; `defaultValue` is escaped. The collation is kept when the column stays text.
 */
function columnDefinition(col, defaultValue) {
  let sql = `${q(col.name)} ${col.columnType}`;
  if (col.collation && STRING_TYPES.has(col.dataType) && /^\w+$/.test(col.collation)) sql += ` COLLATE ${col.collation}`;
  sql += col.nullable ? ' NULL' : ' NOT NULL';
  if (defaultValue !== null && defaultValue !== undefined) sql += ` DEFAULT ${escape(defaultValue)}`;
  if (col.comment) sql += ` COMMENT ${escape(col.comment)}`;
  return sql;
}

/** Why a column cannot be renamed, retyped or dropped, or null if it can. */
function lockedReason(table, col) {
  if (table.primaryKey.includes(col.name)) return 'it is the primary key';
  const fk = table.foreignKeys.find((f) => f.column === col.name);
  if (fk) return `it is a foreign key to ${fk.refTable}.${fk.refColumn}`;
  const child = table.children.find((c) => c.refColumn === col.name);
  if (child) return `${child.table}.${child.column} references it`;
  if (col.generated) return 'it is a generated column';
  if (col.autoIncrement) return 'it is AUTO_INCREMENT';
  return null;
}

module.exports = {
  TYPE_HELP,
  NO_LITERAL_DEFAULT,
  isValidColumnName,
  parseType,
  inferType,
  pendingColumn,
  columnDefinition,
  lockedReason,
};
