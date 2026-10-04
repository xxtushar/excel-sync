'use strict';
/**
 * Watches the workbook on disk and syncs a couple of seconds after each save.
 *  - Waits for Excel to finish writing (awaitWriteFinish + debounce), handles Excel's save-via-rename.
 *  - Retries if the file is half-written or locked.
 *  - Never runs two syncs at once; a save during a sync queues exactly one more run.
 */

const fs = require('fs');
const path = require('path');
const chokidar = require('chokidar');
const config = require('./config');
const { printResult } = require('./sync/report');

function createWatcher(engine, opts = {}) {
  const file = opts.file ? config.resolvePath(opts.file) : config.watchFile;
  const shown = config.displayPath(file);
  const debounceMs = opts.debounceMs ?? config.watchDebounceMs;
  const logger = opts.logger || console;
  const onResult = opts.onResult || (() => {});

  let watcher = null;
  let timer = null;
  let running = false;
  let pending = false;
  const state = { file, enabled: false, runs: 0, lastEventAt: null, lastRunAt: null, lastStatus: null, lastMessage: null, lastErrorCount: 0 };

  async function run(reason) {
    if (running) {
      pending = true;
      return;
    }
    running = true;
    state.lastRunAt = new Date().toISOString();
    try {
      for (let attempt = 1; attempt <= 4; attempt++) {
        try {
          if (!fs.existsSync(file)) throw Object.assign(new Error(`Workbook not found: ${shown}`), { fatal: true });
          const buf = await fs.promises.readFile(file); // read once so a save mid-sync cannot mix versions
          const result = await engine.runSync({ source: buf, sourceName: path.basename(file), trigger: 'watch' });
          state.runs++;
          state.lastStatus = result.status;
          state.lastMessage = result.message;
          state.lastErrorCount = result.errors.length;
          if (result.status !== 'no-changes' || reason === 'startup') printResult(result, logger);
          onResult(result);
          break;
        } catch (e) {
          const retryable = !e.fatal && e.status !== 409 && /zip|end of central directory|corrupt|EBUSY|EPERM|EACCES|Invalid|unexpected/i.test(e.message);
          if (e.status === 409) {
            pending = true; // another sync (e.g. an upload) holds the lock; run again afterwards
            await new Promise((r) => setTimeout(r, 1500));
            break;
          }
          if (retryable && attempt < 4) {
            await new Promise((r) => setTimeout(r, 1000 * attempt));
            continue;
          }
          state.lastStatus = 'error';
          state.lastMessage = e.message;
          logger.error(`[excel-sync] watch sync failed: ${e.message}`);
          break;
        }
      }
    } finally {
      running = false;
      if (pending) {
        pending = false;
        setTimeout(() => run('queued'), 200);
      }
    }
  }

  function schedule(event) {
    state.lastEventAt = new Date().toISOString();
    clearTimeout(timer);
    timer = setTimeout(() => run(event), debounceMs);
  }

  function start({ syncOnStart = true } = {}) {
    if (watcher) return;
    watcher = chokidar.watch(file, {
      ignoreInitial: true,
      usePolling: !!(opts.poll ?? process.env.WATCH_POLL === 'true'), // for network drives / WSL / Docker volumes
      interval: 1000,
      awaitWriteFinish: { stabilityThreshold: 800, pollInterval: 100 },
      atomic: true,
    });
    watcher.on('add', () => schedule('add')).on('change', () => schedule('change'));
    watcher.on('error', (e) => logger.error(`[excel-sync] watcher error: ${e.message}`));
    state.enabled = true;
    logger.log(`[excel-sync] watching ${shown}`);
    if (syncOnStart) run('startup');
  }

  async function stop() {
    clearTimeout(timer);
    state.enabled = false;
    if (watcher) await watcher.close();
    watcher = null;
  }

  return { start, stop, runNow: () => run('manual'), status: () => ({ ...state, running }) };
}

module.exports = { createWatcher };
