'use strict';
/**
 * Embeddable entry point. In the backend you are handed later:
 *
 *   const { createExcelSync } = require('./avyra-excel-sync/src');
 *   const excelSync = await createExcelSync({ pool });          // reuse your mysql2/promise pool (dateStrings: true!)
 *   app.use('/api', excelSync.router);                         // add your own auth middleware before it
 *   excelSync.startWatcher();                                  // optional
 *
 * If you pass your own pool it MUST be created with { dateStrings: true }, otherwise DATETIME values come back as
 * JS Dates and every datetime cell looks changed. Without a pool, one is created from .env.
 */

const express = require('express');
const config = require('./config');
const { createPool } = require('./db');
const { createEngine } = require('./sync/engine');
const store = require('./sync/store');
const { createSyncRouter } = require('./api/syncRoutes');
const { createTableRouter } = require('./api/tableRoutes');
const { createWatcher } = require('./watcher');
const { apiKeyAuth, errorHandler } = require('./api/middleware');

async function createExcelSync(opts = {}) {
  const pool = opts.pool || createPool(opts.db || config.db);
  const dbName = opts.database || (opts.db && opts.db.database) || config.db.database;
  if (opts.pool && pool.pool && pool.pool.config && pool.pool.config.connectionConfig && !pool.pool.config.connectionConfig.dateStrings) {
    throw new Error('createExcelSync: the mysql2 pool must be created with { dateStrings: true }.');
  }

  await store.ensureTables(pool);
  const engine = createEngine(pool, dbName);
  const schema = await engine.getSchema();
  for (const p of schema.problems) console.warn(`[excel-sync] ${p}`);

  let watcher = null;
  const router = express.Router();
  if (opts.auth !== false) router.use(apiKeyAuth(opts.apiKey ?? config.apiKey));
  router.use(createSyncRouter({ engine, pool, getWatcher: () => watcher }));
  router.use(createTableRouter({ engine, pool }));
  router.use(errorHandler);

  return {
    router,
    engine,
    pool,
    startWatcher(wopts = {}) {
      const file = wopts.file || config.watchFile;
      if (!file) throw new Error('No file to watch: set WATCH_FILE or pass { file }.');
      watcher = createWatcher(engine, { ...wopts, file });
      watcher.start(wopts);
      return watcher;
    },
    async close() {
      if (watcher) await watcher.stop();
      if (!opts.pool) await pool.end();
    },
  };
}

module.exports = { createExcelSync };
