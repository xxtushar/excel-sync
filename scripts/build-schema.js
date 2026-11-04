#!/usr/bin/env node
'use strict';
/**
 * Reads the table definitions from a mysqldump file and saves them as schema/avyra.schema.json, which the upload
 * checker uses instead of a database connection.
 *
 *   node scripts/build-schema.js [dump.sql] [--out=schema/avyra.schema.json]
 *
 * Run it again whenever the database's tables change (new column, longer varchar, new lookup table...), with a
 * fresh dump, and commit the JSON so everyone checks against the same definitions.
 */

const fs = require('fs');
const path = require('path');
const config = require('../src/config');
const { schemaFromDump, schemaToJson } = require('../src/schema/fromDump');

const args = process.argv.slice(2);
const dump = path.resolve(args.find((a) => !a.startsWith('--')) || path.join(config.projectRoot, 'test/fixtures/tusharDump.sql'));
const outArg = (args.find((a) => a.startsWith('--out=')) || '').slice('--out='.length);
const out = path.resolve(outArg || path.join(config.projectRoot, 'schema', 'avyra.schema.json'));

const schema = schemaFromDump(fs.readFileSync(dump, 'utf8'));
const n = Object.keys(schema.tables).length;
if (!n) {
  console.error(`[excel-sync] no st_/dy_ CREATE TABLE statements found in ${dump}.`);
  process.exit(1);
}
for (const p of schema.problems) console.warn(`[excel-sync] ${p}`);
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, JSON.stringify(schemaToJson(schema), null, 1) + '\n');
console.log(`[excel-sync] ${n} tables from ${config.displayPath(dump)} → ${config.displayPath(out)}`);
