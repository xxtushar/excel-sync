#!/usr/bin/env node
'use strict';
/**
 * Command-line sync.
 *   node scripts/sync-file.js <workbook.xlsx> [--dry-run] [--full] [--delete-mode=soft|hard|none]
 *                                            [--allow-mass-delete] [--tables=dy_user,dy_pg_info] [--json]
 */

const path = require('path');
const config = require('../src/config');
const { createPool, connectionHint } = require('../src/db');
const { createEngine } = require('../src/sync/engine');
const store = require('../src/sync/store');
const { printResult } = require('../src/sync/report');

async function main() {
  const args = process.argv.slice(2);
  const file = args.find((a) => !a.startsWith('--'));
  if (!file) {
    console.error('Usage: node scripts/sync-file.js <workbook.xlsx> [--dry-run] [--full] [--delete-mode=soft|hard|none] [--allow-mass-delete] [--tables=a,b] [--json]');
    process.exit(2);
  }
  const flag = (n) => args.includes(`--${n}`);
  const opt = (n) => (args.find((a) => a.startsWith(`--${n}=`)) || '').split('=')[1];

  const pool = createPool(config.db);
  try {
    await store.ensureTables(pool);
    const engine = createEngine(pool);
    const result = await engine.runSync({
      source: path.resolve(file),
      sourceName: path.basename(file),
      dryRun: flag('dry-run'),
      full: flag('full'),
      deleteMode: opt('delete-mode'),
      allowMassDelete: flag('allow-mass-delete'),
      tables: opt('tables') ? opt('tables').split(',') : undefined,
      trigger: 'cli',
    });
    if (flag('json')) console.log(JSON.stringify(result, null, 2));
    else printResult(result, console);
    process.exitCode = ['invalid', 'failed'].includes(result.status) ? 1 : 0;
  } finally {
    await pool.end();
  }
}

main().catch((e) => {
  console.error(connectionHint(e, config.db) || e.message);
  process.exit(1);
});
