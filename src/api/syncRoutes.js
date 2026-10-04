'use strict';
/**
 *  POST /sync/preview        multipart "file" → what would change (nothing written)
 *  POST /sync                multipart "file" → apply
 *  POST /sync/watched-file   sync the server-side WATCH_FILE now (add ?dryRun=true to preview)
 *  GET  /sync/status         watcher state + last run
 *  GET  /sync/logs           run history       GET /sync/logs/:id  one run in full
 *  POST /sync/reset          forget sheet hashes so the next sync compares every sheet
 *  GET  /export              download the DB as a workbook (?tables=a,b)
 *
 *  Options (query string or multipart fields): full, deleteMode=soft|hard|none, allowMassDelete,
 *  tables=a,b, details=true|false
 */

const express = require('express');
const multer = require('multer');
const config = require('../config');
const store = require('../sync/store');
const { toResponse } = require('../sync/report');
const { exportWorkbook } = require('../excel/exportWorkbook');
const { HttpError, truthy } = require('./middleware');

function syncOptions(req) {
  const p = { ...req.query, ...(req.body || {}) };
  return {
    full: truthy(p.full),
    deleteMode: p.deleteMode || undefined,
    allowMassDelete: truthy(p.allowMassDelete),
    tables: p.tables ? String(p.tables).split(',').map((s) => s.trim()).filter(Boolean) : undefined,
    details: p.details === undefined ? true : truthy(p.details),
  };
}

const HTTP_STATUS = { invalid: 422, failed: 409 };

function createSyncRouter({ engine, pool, getWatcher }) {
  const router = express.Router();
  const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: config.maxUploadMb * 1024 * 1024, files: 1 },
    fileFilter: (req, file, cb) => {
      if (/\.xlsx$/i.test(file.originalname) || /spreadsheetml/.test(file.mimetype)) return cb(null, true);
      cb(new HttpError(400, 'Upload an .xlsx file (field name "file"). .xls and .csv are not supported.'));
    },
  });

  async function handle(req, res, dryRun) {
    if (!req.file) throw new HttpError(400, 'No file uploaded. Send multipart/form-data with the workbook in a field named "file".');
    const o = syncOptions(req);
    const result = await engine.runSync({
      ...o,
      source: req.file.buffer,
      sourceName: req.file.originalname,
      dryRun,
      trigger: 'upload',
    });
    res.status(HTTP_STATUS[result.status] || 200).json(toResponse(result, { details: o.details }));
  }

  router.post('/sync/preview', upload.single('file'), (req, res) => handle(req, res, true));
  router.post('/sync', upload.single('file'), (req, res) => handle(req, res, false));

  router.post('/sync/watched-file', async (req, res) => {
    if (!config.watchFile) throw new HttpError(400, 'WATCH_FILE is not set on the server.');
    const o = syncOptions(req);
    const result = await engine.runSync({ ...o, source: config.watchFile, sourceName: config.watchFile, dryRun: truthy(req.query.dryRun), trigger: 'api' });
    res.status(HTTP_STATUS[result.status] || 200).json(toResponse(result, { details: o.details }));
  });

  router.get('/sync/status', async (req, res) => {
    const [last] = await store.listLogs(pool, { limit: 1 });
    const states = await store.getStates(pool);
    const w = getWatcher && getWatcher();
    res.json({
      deleteMode: config.deleteMode,
      blankIdMode: config.blankIdMode,
      watcher: w ? w.status() : { enabled: false },
      lastRun: last || null,
      sheetsTracked: Object.keys(states).length,
    });
  });

  router.get('/sync/logs', async (req, res) => {
    const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 20));
    const offset = Math.max(0, Number(req.query.offset) || 0);
    res.json(await store.listLogs(pool, { limit, offset }));
  });

  router.get('/sync/logs/:id', async (req, res) => {
    const log = await store.getLog(pool, Number(req.params.id));
    if (!log) throw new HttpError(404, 'No such sync log.');
    res.json(log);
  });

  router.post('/sync/reset', async (req, res) => {
    const tables = req.query.tables ? String(req.query.tables).split(',') : null;
    await store.clearStates(pool, tables);
    res.json({ ok: true, message: 'Sheet hashes cleared; the next sync compares every sheet.' });
  });

  router.get('/export', async (req, res) => {
    const schema = await engine.getSchema(true);
    const tables = req.query.tables ? String(req.query.tables).split(',').map((s) => s.trim()) : undefined;
    if (tables) for (const t of tables) if (!schema.tables[t]) throw new HttpError(404, `Unknown table ${t}.`);
    const buf = await exportWorkbook(pool, schema, { tables });
    const stamp = new Date().toISOString().slice(0, 16).replace(/[:T]/g, '-');
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${schema.database}-${stamp}.xlsx"`);
    res.send(Buffer.from(buf));
  });

  return router;
}

module.exports = { createSyncRouter };
