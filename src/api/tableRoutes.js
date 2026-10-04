'use strict';
/**
 * Generic, schema-driven CRUD over every st_/dy_ table. Table and column names are only accepted if they
 * exist in the live schema, and values go through the same coercion as the Excel import.
 *
 *  GET    /tables                         every table with columns, keys, row counts
 *  GET    /tables/:table                  ?page&limit&sort&order&search&excludeDeleted&<column>=<value>
 *  GET    /tables/:table/:id
 *  GET    /tables/:table/:id/impact       what a hard delete would cascade into
 *  POST   /tables/:table                  JSON body → insert
 *  PATCH  /tables/:table/:id              JSON body → update only the given columns (PUT works the same)
 *  DELETE /tables/:table/:id              soft delete; ?hard=true to DELETE; ?hard=true&confirm=true if it cascades
 */

const express = require('express');
const config = require('../config');
const { q } = require('../db');
const { findTable } = require('../schema/introspect');
const { toDbValue, fromDbValue } = require('../excel/normalize');
const { cascadeImpact } = require('../sync/cascade');
const { HttpError, truthy } = require('./middleware');

const RESERVED = new Set(['page', 'limit', 'sort', 'order', 'search', 'excludeDeleted']);

function describe(t, rowCount) {
  return {
    name: t.name,
    kind: t.kind,
    loadOrder: t.order + 1,
    primaryKey: t.primaryKey[0] || null,
    softDeleteColumns: t.softDeleteColumns,
    rowCount,
    columns: t.columns.map((c) => ({
      name: c.name,
      type: c.columnType,
      nullable: c.nullable,
      required: !c.nullable && !c.hasDefault && !c.autoIncrement,
      autoIncrement: c.autoIncrement,
    })),
    foreignKeys: t.foreignKeys.map((f) => ({ column: f.column, references: `${f.refTable}.${f.refColumn}`, onDelete: f.onDelete })),
    referencedBy: t.children.map((c) => ({ table: c.table, column: c.column, onDelete: c.onDelete })),
    uniqueKeys: t.uniqueKeys,
  };
}

function createTableRouter({ engine, pool }) {
  const router = express.Router();
  router.use(express.json({ limit: '1mb' }));

  async function ctx(req) {
    const schema = await engine.getSchema();
    const t = findTable(schema, req.params.table);
    if (!t) throw new HttpError(404, `Unknown table "${req.params.table}". GET /tables lists them.`);
    if (t.readOnly) throw new HttpError(400, `${t.name} has no single-column primary key.`);
    const pk = t.primaryKey[0];
    const pkCol = t.columnMap[pk.toLowerCase()];
    let id;
    if (req.params.id !== undefined) {
      const r = toDbValue(pkCol, req.params.id);
      if (r.error || r.value === null) throw new HttpError(400, `Invalid ${pk}: ${r.error || 'empty'}`);
      id = r.value;
    }
    return { schema, t, pk, pkCol, id };
  }

  const shape = (t, row) => (row ? Object.fromEntries(t.columns.map((c) => [c.name, fromDbValue(c, row[c.name])])) : null);

  async function getRow(t, pk, id) {
    const [rows] = await pool.query(`SELECT * FROM ${q(t.name)} WHERE ${q(pk)} = ?`, [id]);
    return shape(t, rows[0]);
  }

  /** Validate a JSON body against the table. Returns { values } or throws 400 with every problem listed. */
  function coerceBody(t, body, { insert }) {
    if (!body || typeof body !== 'object' || Array.isArray(body)) throw new HttpError(400, 'Send a JSON object of column: value.');
    const values = {};
    const problems = [];
    for (const [k, raw] of Object.entries(body)) {
      const col = t.columnMap[k.toLowerCase()];
      if (!col) {
        problems.push({ column: k, message: 'no such column' });
        continue;
      }
      if (col.generated) {
        problems.push({ column: k, message: 'generated column, cannot be set' });
        continue;
      }
      const r = toDbValue(col, raw);
      if (r.error) problems.push({ column: col.name, message: r.error });
      else if (r.missingRequired) problems.push({ column: col.name, message: 'cannot be empty' });
      else values[col.name] = r.value;
    }
    if (insert) {
      for (const c of t.columns) {
        if (!c.nullable && !c.hasDefault && !c.autoIncrement && !c.generated && !(c.name in values))
          problems.push({ column: c.name, message: 'required' });
      }
    }
    if (problems.length) throw new HttpError(400, 'Invalid row.', { problems });
    return values;
  }

  router.get('/tables', async (req, res) => {
    const schema = await engine.getSchema(truthy(req.query.refresh));
    const [counts] = await pool.query(
      `SELECT TABLE_NAME AS t, TABLE_ROWS AS n FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ?`,
      [schema.database]
    );
    const approx = Object.fromEntries(counts.map((r) => [r.t, Number(r.n)]));
    res.json({
      database: schema.database,
      problems: schema.problems,
      note: 'rowCount is MySQL’s estimate; GET /tables/:table returns the exact total.',
      tables: schema.order.map((n) => describe(schema.tables[n], approx[n] ?? null)),
    });
  });

  router.get('/tables/:table', async (req, res) => {
    const { t, pk } = await ctx(req);
    const limit = Math.min(config.pageLimitMax, Math.max(1, Number(req.query.limit) || 50));
    const page = Math.max(1, Number(req.query.page) || 1);
    const sortCol = req.query.sort ? t.columnMap[String(req.query.sort).toLowerCase()] : t.columnMap[pk.toLowerCase()];
    if (!sortCol) throw new HttpError(400, `Cannot sort by "${req.query.sort}": no such column.`);
    const order = String(req.query.order || 'asc').toLowerCase() === 'desc' ? 'DESC' : 'ASC';

    const where = [];
    const params = [];
    for (const [k, v] of Object.entries(req.query)) {
      if (RESERVED.has(k)) continue;
      const col = t.columnMap[k.toLowerCase()];
      if (!col) throw new HttpError(400, `Unknown filter "${k}": no such column in ${t.name}.`);
      if (String(v).toLowerCase() === 'null') where.push(`${q(col.name)} IS NULL`);
      else {
        where.push(`${q(col.name)} = ?`);
        params.push(String(v));
      }
    }
    if (req.query.search) {
      const textCols = t.columns.filter((c) => c.kind === 'string');
      if (textCols.length) {
        where.push(`(${textCols.map((c) => `${q(c.name)} LIKE ?`).join(' OR ')})`);
        const like = `%${String(req.query.search).replace(/[\\%_]/g, (m) => '\\' + m)}%`;
        params.push(...textCols.map(() => like));
      }
    }
    if (truthy(req.query.excludeDeleted) && t.softDeleteColumns.length)
      where.push(t.softDeleteColumns.map((c) => `(${q(c)} IS NULL OR ${q(c)} <> 0)`).join(' AND '));

    const w = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const [[{ total }]] = await pool.query(`SELECT COUNT(*) AS total FROM ${q(t.name)} ${w}`, params);
    const [rows] = await pool.query(
      `SELECT * FROM ${q(t.name)} ${w} ORDER BY ${q(sortCol.name)} ${order} LIMIT ? OFFSET ?`,
      [...params, limit, (page - 1) * limit]
    );
    res.json({ table: t.name, kind: t.kind, page, limit, total, pages: Math.ceil(total / limit), rows: rows.map((r) => shape(t, r)) });
  });

  router.get('/tables/:table/:id', async (req, res) => {
    const { t, pk, id } = await ctx(req);
    const row = await getRow(t, pk, id);
    if (!row) throw new HttpError(404, `${t.name} has no row with ${pk} ${id}.`);
    res.json(row);
  });

  router.get('/tables/:table/:id/impact', async (req, res) => {
    const { schema, t, pk, id } = await ctx(req);
    if (!(await getRow(t, pk, id))) throw new HttpError(404, `${t.name} has no row with ${pk} ${id}.`);
    res.json({ table: t.name, id, hardDeleteWouldAlsoRemove: await cascadeImpact(pool, schema, t.name, [id]) });
  });

  router.post('/tables/:table', async (req, res) => {
    const { t, pk } = await ctx(req);
    const values = coerceBody(t, req.body, { insert: true });
    const cols = Object.keys(values);
    if (!cols.length) throw new HttpError(400, 'Empty body.');
    const [r] = await pool.query(`INSERT INTO ${q(t.name)} (${cols.map(q).join(', ')}) VALUES (?)`, [cols.map((c) => values[c])]);
    const id = values[pk] ?? r.insertId;
    res.status(201).json(await getRow(t, pk, id));
  });

  async function update(req, res) {
    const { t, pk, id } = await ctx(req);
    const values = coerceBody(t, req.body, { insert: false });
    if (pk in values && String(values[pk]) !== String(id)) throw new HttpError(400, `${pk} cannot be changed.`);
    delete values[pk];
    const cols = Object.keys(values);
    if (!cols.length) throw new HttpError(400, 'No columns to update.');
    if (!(await getRow(t, pk, id))) throw new HttpError(404, `${t.name} has no row with ${pk} ${id}.`);
    await pool.query(`UPDATE ${q(t.name)} SET ${cols.map((c) => `${q(c)} = ?`).join(', ')} WHERE ${q(pk)} = ?`, [
      ...cols.map((c) => values[c]),
      id,
    ]);
    res.json(await getRow(t, pk, id));
  }
  router.patch('/tables/:table/:id', update);
  router.put('/tables/:table/:id', update);

  router.delete('/tables/:table/:id', async (req, res) => {
    const { schema, t, pk, id } = await ctx(req);
    if (!(await getRow(t, pk, id))) throw new HttpError(404, `${t.name} has no row with ${pk} ${id}.`);
    const hard = truthy(req.query.hard);

    if (!hard) {
      if (!t.softDeleteColumns.length)
        throw new HttpError(409, `${t.name} has no soft-delete column. Check GET /tables/${t.name}/${id}/impact, then DELETE with ?hard=true.`);
      await pool.query(`UPDATE ${q(t.name)} SET ${t.softDeleteColumns.map((c) => `${q(c)} = 0`).join(', ')} WHERE ${q(pk)} = ?`, [id]);
      return res.json({ deleted: 'soft', table: t.name, id, columnsSetToZero: t.softDeleteColumns });
    }

    const impact = await cascadeImpact(pool, schema, t.name, [id]);
    if (Object.keys(impact.blockedBy).length)
      throw new HttpError(409, 'Other rows reference this row and the FK does not cascade.', { impact });
    if (impact.total > 0 && !truthy(req.query.confirm))
      throw new HttpError(409, `Deleting this row also deletes ${impact.total} child row(s). Repeat with &confirm=true to go ahead.`, { impact });
    await pool.query(`DELETE FROM ${q(t.name)} WHERE ${q(pk)} = ?`, [id]);
    res.json({ deleted: 'hard', table: t.name, id, cascaded: impact });
  });

  return router;
}

module.exports = { createTableRouter };
