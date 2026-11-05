'use strict';
/**
 * Standalone server for trying the admin upload API (npm start). In production the backend mounts
 * createAdminUploadRouter() behind its own admin login instead (see README).
 *
 * Database login comes from config.json (DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME).
 * If API_KEY is set, every request needs the header  x-api-key: <API_KEY>.
 */

const crypto = require('crypto');
const express = require('express');
const config = require('../config');
const { createPool, connectionHint } = require('../db/pool');
const { createAdminUploadRouter } = require('./router');

const BASE = '/api/admin/excel';

function apiKeyCheck(key) {
  if (!key) return (req, res, next) => next();
  const want = Buffer.from(key);
  return (req, res, next) => {
    const got = Buffer.from(String(req.get('x-api-key') || ''));
    if (got.length === want.length && crypto.timingSafeEqual(got, want)) return next();
    res.status(401).json({ status: 'error', message: 'Missing or wrong x-api-key header.' });
  };
}

function createApp(pool) {
  const app = express();
  app.get('/health', async (req, res) => {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', database: config.db.database });
  });
  app.use(BASE, apiKeyCheck(config.apiKey), createAdminUploadRouter({ pool }));
  return app;
}

if (require.main === module) {
  const pool = createPool(config.db);
  pool
    .query('SELECT 1')
    .then(() => {
      createApp(pool).listen(config.port, () => {
        console.log(`[excel-upload] admin upload API on http://localhost:${config.port}${BASE}  (database: ${config.db.database})`);
        if (!config.apiKey) console.log('[excel-upload] API_KEY is not set: anyone who can reach this port can upload. Set it before sharing.');
      });
    })
    .catch((e) => {
      console.error(connectionHint(e, config.db) || e.message);
      process.exit(1);
    });
}

module.exports = { createApp, BASE };
