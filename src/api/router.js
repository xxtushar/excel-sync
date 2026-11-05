'use strict';
/**
 * The admin upload API, as an Express router the backend mounts behind its own admin login:
 *
 *   const { createAdminUploadRouter } = require('./avyra-excel-upload/src/api/router');
 *   app.use('/api/admin/excel', requireAdmin, createAdminUploadRouter({ pool }));
 *
 *   GET  /template   download the current data as the Excel file admins edit (dropdowns included)
 *   POST /preview    upload the edited file (multipart field "file"): problems, or every change it would make + a token
 *   POST /apply      { "token": "..." }: save exactly what the preview showed, in one transaction
 *
 * Nothing is written to the database by /template or /preview.
 */

const crypto = require('crypto');
const express = require('express');
const multer = require('multer');
const config = require('../config');
const { introspectDb } = require('../db/introspect');
const { connectionHint } = require('../db/pool');
const { prepareWorkbook } = require('../upload/prepare');
const { buildPlan, describePlan } = require('./plan');
const { applyPlan } = require('./apply');
const { buildTemplate, DEFAULT_LAYOUT } = require('./template');

const LOCK = 'avyra_excel_upload';
// The API checks links to tables outside the file against the database (plan.js), so that checker note is dropped.
const issueList = (list) => list.filter((i) => i.code !== 'unchecked-link').map(({ level, code, ...i }) => i);

/**
 * @param {object} opts
 * @param {object} opts.pool              mysql2/promise pool. It MUST use { dateStrings: true } (db/pool.js does).
 * @param {string} [opts.database]        database name (default: DB_NAME)
 * @param {number} [opts.previewMinutes]  how long a preview token stays valid
 * @param {number} [opts.maxUploadMb]
 * @param {string} [opts.layoutFile]      headers-only workbook that decides the sheets/columns of /template
 */
function createAdminUploadRouter(opts) {
  const { pool } = opts;
  if (!pool) throw new Error('createAdminUploadRouter: pass { pool } (a mysql2/promise pool with dateStrings: true).');
  const database = opts.database || config.db.database;
  const ttlMs = (opts.previewMinutes || config.previewMinutes) * 60000;
  const layoutFile = opts.layoutFile || DEFAULT_LAYOUT;
  const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: (opts.maxUploadMb || config.maxUploadMb) * 1024 * 1024, files: 1 } });

  // Previews waiting for confirmation: token → { file, hash, name, expires }. Kept in this process's memory.
  const previews = new Map();
  const sweep = () => {
    const now = Date.now();
    for (const [k, v] of previews) if (v.expires < now) previews.delete(k);
  };

  /** Checks the file and compares it with the database. */
  async function check(db, file, allowMassDelete) {
    const schema = await introspectDb(db, database);
    const checked = await prepareWorkbook(file, schema);
    if (!checked.ok) return { schema, checked, plan: null };
    const plan = await buildPlan(db, schema, checked.data, { allowMassDelete });
    return { schema, checked, plan };
  }

  const router = express.Router();

  router.get('/template', async (req, res) => {
    const schema = await introspectDb(pool, database);
    const t = await buildTemplate(pool, schema, { layoutFile });
    const name = `${new Date().toISOString().slice(0, 10)}-avyra-upload.xlsx`;
    res.set({
      'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'Content-Disposition': `attachment; filename="${name}"`,
      'X-Check-Errors': String(t.errors.length),
    });
    res.send(t.buffer);
  });

  router.post('/preview', upload.single('file'), async (req, res) => {
    if (!req.file) return res.status(400).json({ status: 'error', message: 'Send the workbook as multipart form field "file".' });
    if (!/\.xlsx$/i.test(req.file.originalname || '')) return res.status(400).json({ status: 'error', message: 'Only .xlsx files can be uploaded.' });
    const allowMassDelete = String(req.body?.allowMassDelete ?? req.query.allowMassDelete) === 'true';
    const { checked, plan } = await check(pool, req.file.buffer, allowMassDelete);
    const warnings = issueList([...checked.warnings, ...(plan ? plan.warnings : [])]);
    if (!checked.ok || plan.errors.length) {
      const errors = issueList(checked.ok ? plan.errors : checked.errors);
      return res.status(422).json({ status: 'invalid', message: `${errors.length} problem(s) to fix. Nothing was saved.`, errors, warnings });
    }
    if (!plan.summary.tablesChanged) return res.json({ status: 'no-changes', message: 'The database already matches this file.', warnings });

    sweep();
    const token = crypto.randomBytes(18).toString('base64url');
    const expires = Date.now() + ttlMs;
    previews.set(token, { file: req.file.buffer, hash: plan.hash, allowMassDelete, name: req.file.originalname, expires });
    res.json({
      status: 'preview',
      message: `${plan.summary.inserts} to add, ${plan.summary.updates} to change, ${plan.summary.deletes} to delete. Send the token to /apply to save.`,
      token,
      expiresAt: new Date(expires).toISOString(),
      summary: plan.summary,
      tables: describePlan(plan),
      warnings,
    });
  });

  router.post('/apply', express.json(), async (req, res) => {
    const token = req.body && req.body.token;
    const p = token && previews.get(token);
    if (!p || p.expires < Date.now()) {
      if (p) previews.delete(token);
      return res.status(410).json({ status: 'expired', message: 'This preview has expired or was already used. Upload the file to /preview again.' });
    }
    previews.delete(token); // one use only

    const conn = await pool.getConnection();
    try {
      const [[{ got }]] = await conn.query('SELECT GET_LOCK(?, 10) AS got', [LOCK]);
      if (got !== 1) return res.status(409).json({ status: 'busy', message: 'Another upload is being saved. Try again in a moment.' });
      try {
        // Check again inside the lock: if the database changed since the preview, the admin must see the new plan.
        const { schema, checked, plan } = await check(conn, p.file, p.allowMassDelete);
        if (!checked.ok || plan.errors.length || plan.hash !== p.hash)
          return res.status(409).json({ status: 'changed', message: 'The database changed since this preview, so nothing was saved. Upload the file to /preview again to see the new changes.' });
        const done = await applyPlan(conn, schema, plan);
        console.log(`[excel-upload] saved "${p.name}": ${done.inserts} added, ${done.updates} changed, ${done.deletes} deleted`);
        res.json({ status: 'applied', message: `Saved: ${done.inserts} added, ${done.updates} changed, ${done.deletes} deleted.`, summary: done, tables: describePlan(plan) });
      } finally {
        await conn.query('SELECT RELEASE_LOCK(?)', [LOCK]);
      }
    } finally {
      conn.release();
    }
  });

  // Errors from any route above, as JSON. Express 5 forwards errors thrown in async handlers here.
  router.use((err, req, res, next) => {
    if (err instanceof multer.MulterError) {
      const msg = err.code === 'LIMIT_FILE_SIZE' ? `The file is too big (limit ${opts.maxUploadMb || config.maxUploadMb} MB).` : `Upload problem: ${err.message}`;
      return res.status(400).json({ status: 'error', message: msg });
    }
    if (err && err.sqlMessage) {
      console.error('[excel-upload]', err);
      return res.status(409).json({ status: 'rejected', message: `The database refused a change, so nothing was saved: ${err.sqlMessage}` });
    }
    if (err && err.status === 400) return res.status(400).json({ status: 'error', message: err.message });
    const hint = connectionHint(err, config.db);
    console.error('[excel-upload]', err);
    res.status(hint ? 503 : 500).json({ status: 'error', message: hint || (err && err.message) || 'Something went wrong.' });
  });

  return router;
}

module.exports = { createAdminUploadRouter };
