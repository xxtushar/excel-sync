'use strict';
/** Standalone server: `npm start`. */

const fs = require('fs');
const express = require('express');
const config = require('./config');
const { createExcelSync } = require('./index');
const { connectionHint } = require('./db');

async function main() {
  const app = express();
  app.disable('x-powered-by');
  const excelSync = await createExcelSync();

  app.get('/health', async (req, res) => {
    await excelSync.pool.query('SELECT 1');
    res.json({ ok: true, database: config.db.database });
  });
  app.use('/api', excelSync.router);
  app.use((req, res) => res.status(404).json({ error: `No route ${req.method} ${req.path}` }));

  if (config.watchEnabled) {
    if (fs.existsSync(config.watchFile)) excelSync.startWatcher();
    else
      console.log(
        `[excel-sync] watcher off: no workbook at ${config.displayPath(config.watchFile)}. ` +
          'Put avyra.xlsx in the project folder, or set WATCH_FILE in .env (relative to the project folder, or a full path).'
      );
  }

  const server = app.listen(config.port, () => {
    console.log(`[excel-sync] API on http://localhost:${config.port}/api  (database: ${config.db.database}, deleteMode: ${config.deleteMode})`);
    if (!config.apiKey) console.log('[excel-sync] API_KEY is not set: the API is open to anyone who can reach this port.');
  });

  const shutdown = async () => {
    server.close();
    await excelSync.close();
    process.exit(0);
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

main().catch((e) => {
  console.error('[excel-sync] failed to start:', connectionHint(e, config.db) || e.message);
  process.exit(1);
});
