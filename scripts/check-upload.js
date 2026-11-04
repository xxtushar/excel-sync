#!/usr/bin/env node
'use strict';
/**
 * Checks a workbook and writes the copy to upload in the admin UI. No database connection, nothing is written to
 * any database.
 *
 *   node scripts/check-upload.js <workbook.xlsx> [--out=file.xlsx] [--ids] [--schema=schema/avyra.schema.json] [--json]
 *
 * Writes, next to the input (the input itself is never changed):
 *   YYYY-MM-DD-<name>-ready-to-upload.xlsx   when everything checks out   (exit code 0)
 *   YYYY-MM-DD-<name>-needs-fixes.xlsx       problem cells in red + a _Check sheet listing them   (exit code 1)
 * Fix the needs-fixes file and run the command on it again.
 *
 * --ids   write the plain id (12) instead of "12 – hyderabad" in dropdown columns, if the admin UI wants ids.
 */

const fs = require('fs');
const path = require('path');
const config = require('../src/config');
const { reviveSchema } = require('../src/schema/fromDump');
const { prepareWorkbook } = require('../src/upload/prepare');

function outputName(input, ok, now) {
  const base = path
    .basename(input)
    .replace(/\.xlsx$/i, '')
    .replace(/^[0-9a-f]{8}-/i, '') // upload prefixes some tools add
    .replace(/^\d{4}-\d{2}-\d{2}-/, '') // the date from an earlier run
    .replace(/-(ready-to-upload|needs-fixes)$/, '');
  const day = now.toISOString().slice(0, 10);
  return path.join(path.dirname(input), `${day}-${base}-${ok ? 'ready-to-upload' : 'needs-fixes'}.xlsx`);
}

async function main() {
  const args = process.argv.slice(2);
  const opt = (k) => (args.find((a) => a.startsWith(`--${k}=`)) || '').slice(k.length + 3);
  const file = args.find((a) => !a.startsWith('--'));
  if (!file) {
    console.error('Usage: npm run check-upload -- <workbook.xlsx> [--out=file.xlsx] [--ids] [--json]');
    process.exit(2);
  }
  const src = path.resolve(file);
  const schemaFile = path.resolve(opt('schema') || path.join(config.projectRoot, 'schema', 'avyra.schema.json'));
  if (!fs.existsSync(schemaFile)) {
    console.error(`No schema at ${config.displayPath(schemaFile)}. Make it from a dump: npm run schema -- <dump.sql>`);
    process.exit(2);
  }
  const schema = reviveSchema(JSON.parse(fs.readFileSync(schemaFile, 'utf8')));
  const now = new Date();
  const result = await prepareWorkbook(src, schema, { ids: args.includes('--ids'), now });
  const out = path.resolve(opt('out') || outputName(src, result.ok, now));
  // Re-checking a needs-fixes file that still has problems updates that same file; anything else is never overwritten.
  if (out === src && !/-needs-fixes\.xlsx$/i.test(src)) {
    console.error('Refusing to overwrite the input. Pass a different --out.');
    process.exit(2);
  }
  fs.writeFileSync(out, result.buffer);

  if (args.includes('--json')) {
    const { buffer, ...rest } = result;
    console.log(JSON.stringify({ ...rest, output: out }, null, 2));
  } else {
    for (const t of result.tables) console.log(`  ${t.kind === 'static' ? 'st' : 'dy'}  ${t.table.padEnd(28)} ${String(t.rows).padStart(5)} rows`);
    console.log(`  dropdowns from: ${result.dropdowns.join(', ') || 'none'}`);
    for (const i of result.info) console.log(`  ${i}`);
    const show = (list, label) => {
      for (const i of list.slice(0, 40)) console.log(`  ${label} ${i.sheet}${i.cell ? '!' + i.cell : ''}: ${i.message}`);
      if (list.length > 40) console.log(`  … and ${list.length - 40} more on the _Check sheet`);
    };
    show(result.errors, 'FIX ');
    show(result.warnings, 'note');
    console.log(
      result.ok
        ? `\n✔ Ready to upload in the admin UI: ${config.displayPath(out)}`
        : `\n✘ ${result.errors.length} problem(s). Fix the red cells in ${config.displayPath(out)} and run this again on that file.`
    );
  }
  process.exit(result.ok ? 0 : 1);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(2);
});
