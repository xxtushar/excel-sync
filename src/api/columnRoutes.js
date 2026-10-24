'use strict';
/**
 * Column management for every st_/dy_ table, so the tables can grow with what the PG owner needs.
 *
 *  GET    /tables/:table/columns                  columns with type, default, and why a column is locked (if it is)
 *  POST   /tables/:table/columns                  { name, type, nullable?, default?, after? } → add a column
 *  PATCH  /tables/:table/columns/:column          { name?, type?, nullable?, default? } → rename and/or redefine it
 *  DELETE /tables/:table/columns/:column          drop it; ?confirm=true when it still holds data
 *
 * Primary keys, foreign keys and columns other tables point at are locked. Before a type change every stored
 * value is converted the way the import would convert it: values that cannot be converted stop the change, and
 * values that would come out different (rounded, time cut off, leading zero lost…) are listed and need
 * ?confirm=true. Each change runs under the sync lock, so it never overlaps a sync.
 */

const express = require('express');
const { q } = require('../db');
const { findTable } = require('../schema/introspect');
const {
  TYPE_HELP,
  NO_LITERAL_DEFAULT,
  isValidColumnName,
  parseType,
  pendingColumn,
  columnDefinition,
  lockedReason,
} = require('../schema/columns');
const { toDbValue, fromDbValue, sameValue } = require('../excel/normalize');
const { HttpError, truthy } = require('./middleware');

const SAMPLE = 20; // problem rows listed in an error response
const KEEP_DEFAULT_HINT = ' That is the current default; send a new "default" (or null for none).';

function columnInfo(t, c) {
  return { name: c.name, type: c.columnType, nullable: c.nullable, default: c.defaultValue, locked: lockedReason(t, c) };
}

function tableOf(schema, name) {
  const t = findTable(schema, name);
  if (!t) throw new HttpError(404, `Unknown table "${name}". GET /tables lists them.`);
  return t;
}

function columnOf(t, name) {
  const col = t.columnMap[String(name).toLowerCase()];
  if (!col) throw new HttpError(404, `${t.name} has no column "${name}".`);
  return col;
}

function readBody(body, allowed) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) throw new HttpError(400, 'Send a JSON object.');
  const unknown = Object.keys(body).filter((k) => !allowed.includes(k));
  if (unknown.length) throw new HttpError(400, `Unknown field(s) ${unknown.join(', ')}. Allowed: ${allowed.join(', ')}.`);
  if ('nullable' in body && typeof body.nullable !== 'boolean') throw new HttpError(400, '"nullable" must be true or false.');
  return body;
}

function checkName(t, name, current = null) {
  if (!isValidColumnName(name))
    throw new HttpError(400, '"name" must be a column name: letters, digits and _, not starting with a digit, at most 64 characters.');
  const clash = t.columnMap[name.toLowerCase()];
  if (clash && clash !== current) throw new HttpError(409, `${t.name} already has a column "${clash.name}".`);
}

function checkType(spec) {
  const type = parseType(spec);
  if (!type) throw new HttpError(400, `Unsupported type ${JSON.stringify(spec ?? null)}. ${TYPE_HELP}`);
  return type;
}

/** A default in the shape MySQL stores for `col`, or null for none. */
function coerceDefault(col, raw, hint = '') {
  if (raw === null || raw === undefined) return null;
  if (NO_LITERAL_DEFAULT.has(col.dataType)) throw new HttpError(400, `${col.columnType} columns cannot have a default.${hint}`);
  const r = toDbValue({ ...col, nullable: true }, raw);
  if (r.error) throw new HttpError(400, `Default ${JSON.stringify(raw)} does not fit ${col.columnType}: ${r.error}.${hint}`);
  return r.value;
}

/**
 * Converts every stored value from column `from` to column `to` the way the import would.
 * nulls: rows without a value (a problem only if `to` is NOT NULL); invalid: values that cannot be converted;
 * changed: values that convert but would not read back the same.
 */
async function checkValues(conn, t, from, to) {
  const [rows] = await conn.query(`SELECT ${q(t.primaryKey[0])} AS id, ${q(from.name)} AS v FROM ${q(t.name)}`);
  const typeChanged = from.columnType !== to.columnType;
  const out = { nulls: [], invalid: [], changed: [] };
  for (const r of rows) {
    const v = fromDbValue(from, r.v);
    if (v === null) {
      if (!to.nullable) out.nulls.push(r.id);
      continue;
    }
    if (!typeChanged) continue;
    const converted = toDbValue(to, v);
    if (converted.error) {
      out.invalid.push({ id: r.id, value: v, message: converted.error });
      continue;
    }
    const back = toDbValue(from, converted.value);
    if (back.error || !sameValue(from, back.value, v)) out.changed.push({ id: r.id, from: v, to: converted.value });
  }
  return out;
}

function createColumnRouter({ engine }) {
  const router = express.Router();
  const json = express.json({ limit: '1mb' });

  /**
   * Under the sync lock: re-reads the schema, lets build(conn, t) validate and return { sql, name }, runs the
   * ALTER TABLE, then refreshes the cached schema so the table API and the next sync see the change.
   */
  function alter(req, build) {
    return engine.withLock(async (conn) => {
      const t = tableOf(await engine.getSchema(true), req.params.table);
      if (t.readOnly) throw new HttpError(400, `${t.name} has no single-column primary key.`);
      const { sql, name } = await build(conn, t);
      await conn.query(sql);
      const fresh = (await engine.getSchema(true)).tables[t.name];
      return { t: fresh, name, column: fresh.columnMap[name.toLowerCase()] || null };
    });
  }

  router.get('/tables/:table/columns', async (req, res) => {
    const t = tableOf(await engine.getSchema(truthy(req.query.refresh)), req.params.table);
    res.json({ table: t.name, columns: t.columns.map((c) => columnInfo(t, c)) });
  });

  router.post('/tables/:table/columns', json, async (req, res) => {
    const { t, column } = await alter(req, async (conn, t) => {
      const body = readBody(req.body, ['name', 'type', 'nullable', 'default', 'after']);
      checkName(t, body.name);
      const col = pendingColumn(body.name, checkType(body.type).columnType, { nullable: body.nullable ?? true });
      const def = coerceDefault(col, body.default);
      if (!col.nullable && def === null)
        throw new HttpError(400, 'A NOT NULL column needs a "default", so the rows already in the table get a value.');
      let position = '';
      if (body.after !== undefined) {
        const after = t.columnMap[String(body.after).toLowerCase()];
        if (!after) throw new HttpError(400, `"after": ${t.name} has no column "${body.after}".`);
        position = ` AFTER ${q(after.name)}`;
      }
      return { sql: `ALTER TABLE ${q(t.name)} ADD COLUMN ${columnDefinition(col, def)}${position}`, name: col.name };
    });
    res.status(201).json({ table: t.name, column: columnInfo(t, column) });
  });

  router.patch('/tables/:table/columns/:column', json, async (req, res) => {
    const { t, column } = await alter(req, async (conn, t) => {
      const body = readBody(req.body, ['name', 'type', 'nullable', 'default']);
      if (!Object.keys(body).length) throw new HttpError(400, 'Send at least one of: name, type, nullable, default.');
      const col = columnOf(t, req.params.column);
      const locked = lockedReason(t, col);
      if (locked) throw new HttpError(409, `${col.name} cannot be changed: ${locked}.`);
      const name = body.name ?? col.name;
      checkName(t, name, col);

      // A rename alone keeps everything else about the column exactly as it is.
      if (!['type', 'nullable', 'default'].some((k) => k in body))
        return { sql: `ALTER TABLE ${q(t.name)} RENAME COLUMN ${q(col.name)} TO ${q(name)}`, name };

      // Redefining rebuilds the whole definition, which cannot reproduce MySQL-managed extras
      // (AUTO_INCREMENT, DEFAULT CURRENT_TIMESTAMP, ON UPDATE…), so those columns are left alone.
      if (col.extra) throw new HttpError(409, `${col.name} has "${col.extra}", which this API cannot keep; change it in MySQL directly.`);
      const next = { ...col, ...(body.type !== undefined ? checkType(body.type) : {}), name, nullable: body.nullable ?? col.nullable };
      const typeChanged = next.columnType !== col.columnType;

      let def = col.defaultValue; // as MySQL stores it
      if ('default' in body) def = coerceDefault(next, body.default);
      else if (def !== null && typeChanged) def = coerceDefault(next, def, KEEP_DEFAULT_HINT) ?? def;

      if (typeChanged || (col.nullable && !next.nullable)) {
        const { nulls, invalid, changed } = await checkValues(conn, t, col, next);
        if (nulls.length)
          throw new HttpError(409, `${nulls.length} row(s) have no ${col.name}, so it cannot be NOT NULL. Fill them in first.`, {
            ids: nulls.slice(0, SAMPLE),
          });
        if (invalid.length)
          throw new HttpError(409, `${invalid.length} value(s) cannot be stored as ${next.columnType}. Fix them first.`, {
            invalid: invalid.slice(0, SAMPLE),
          });
        if (changed.length && !truthy(req.query.confirm))
          throw new HttpError(409, `${changed.length} value(s) would change when stored as ${next.columnType}. Repeat with ?confirm=true to go ahead.`, {
            changed: changed.slice(0, SAMPLE),
          });
      }
      return { sql: `ALTER TABLE ${q(t.name)} CHANGE COLUMN ${q(col.name)} ${columnDefinition(next, def)}`, name };
    });
    res.json({ table: t.name, column: columnInfo(t, column) });
  });

  router.delete('/tables/:table/columns/:column', async (req, res) => {
    const { t, name } = await alter(req, async (conn, t) => {
      const col = columnOf(t, req.params.column);
      const locked = lockedReason(t, col);
      if (locked) throw new HttpError(409, `${col.name} cannot be dropped: ${locked}.`);
      const uk = t.uniqueKeys.find((k) => k.columns.includes(col.name));
      if (uk) throw new HttpError(409, `${col.name} cannot be dropped: it is part of unique key ${uk.name}.`);
      const [[{ n }]] = await conn.query(`SELECT COUNT(*) AS n FROM ${q(t.name)} WHERE ${q(col.name)} IS NOT NULL`);
      if (n > 0 && !truthy(req.query.confirm))
        throw new HttpError(409, `${col.name} holds data in ${n} row(s). Repeat with ?confirm=true to drop it with its data.`, { rowsWithData: n });
      return { sql: `ALTER TABLE ${q(t.name)} DROP COLUMN ${q(col.name)}`, name: col.name };
    });
    res.json({ table: t.name, dropped: name });
  });

  return router;
}

module.exports = { createColumnRouter };
