#!/usr/bin/env node
'use strict';
/**
 * Writes the current database out as the workbook template (the same file as GET /api/export).
 *   node scripts/export-template.js [out.xlsx] [--ods]
 *
 * --ods also writes <out>.ods for LibreOffice Calc, with instant city search: headless LibreOffice runs
 * scripts/make-ods.py. It needs LibreOffice installed; SOFFICE points at soffice if it is not in the usual place.
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');
const config = require('../src/config');
const { createPool, connectionHint } = require('../src/db');
const { introspect } = require('../src/schema/introspect');
const { exportWorkbook } = require('../src/excel/exportWorkbook');

const MAC_SOFFICE = '/Applications/LibreOffice.app/Contents/MacOS/soffice';

async function main() {
  const args = process.argv.slice(2);
  const out = path.resolve(args.find((a) => !a.startsWith('--')) || path.join(config.projectRoot, 'avyra-template.xlsx'));

  const pool = createPool(config.db);
  try {
    const schema = await introspect(pool, config.db.database);
    fs.writeFileSync(out, Buffer.from(await exportWorkbook(pool, schema)));
  } finally {
    await pool.end();
  }
  console.log(`[excel-sync] wrote ${config.displayPath(out)}`);

  if (args.includes('--ods')) makeOds(out, out.replace(/\.xlsx$/i, '') + '.ods');
}

/** Starts a headless LibreOffice with its own throwaway profile (an open LibreOffice window is not disturbed). */
function makeOds(xlsx, ods) {
  const soffice = process.env.SOFFICE || (fs.existsSync(MAC_SOFFICE) ? MAC_SOFFICE : 'soffice');
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'excel-sync-lo-'));
  const result = path.join(profile, 'result.txt');
  try {
    fs.mkdirSync(path.join(profile, 'user', 'Scripts', 'python'), { recursive: true });
    fs.copyFileSync(path.join(__dirname, 'make-ods.py'), path.join(profile, 'user', 'Scripts', 'python', 'make_ods.py'));
    execFileSync(
      soffice,
      ['--headless', '--invisible', '--norestore', `-env:UserInstallation=file://${profile}`,
        'vnd.sun.star.script:make_ods.py$main?language=Python&location=user'],
      {
        stdio: 'ignore',
        timeout: 180000,
        env: {
          ...process.env,
          MAKE_ODS_SRC: xlsx,
          MAKE_ODS_OUT: ods,
          MAKE_ODS_BAS: path.join(__dirname, 'city-picker.bas'),
          MAKE_ODS_RESULT: result,
          // .pyc files written inside LibreOffice.app break its code signature
          PYTHONDONTWRITEBYTECODE: '1',
        },
      }
    );
    const msg = fs.existsSync(result) ? fs.readFileSync(result, 'utf8') : 'LibreOffice exited without running scripts/make-ods.py.';
    if (msg !== 'ok') throw new Error(`Could not make the .ods:\n${msg}`);
  } finally {
    fs.rmSync(profile, { recursive: true, force: true });
  }
  console.log(`[excel-sync] wrote ${config.displayPath(ods)} (city search for LibreOffice; enable macros when you open it)`);
}

main().catch((e) => {
  console.error(connectionHint(e, config.db) || e.message);
  process.exit(1);
});
