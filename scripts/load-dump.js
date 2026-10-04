#!/usr/bin/env node
'use strict';
/**
 * Loads a mysqldump file through Node, so you don't need the `mysql` command-line client.
 *
 *   npm run load-dump                          loads test/fixtures/tusharDump.sql into DB_NAME (from .env)
 *   npm run load-dump -- path/to/dump.sql      another dump file
 *   npm run load-dump -- --force               replace a database that already has tables (DROPs them!)
 *
 * The dump's own database name is rewritten to DB_NAME, so it always lands where .env points.
 */

const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const config = require('../src/config');
const { connectionHint } = require('../src/db');

async function main() {
  const args = process.argv.slice(2);
  const force = args.includes('--force');
  const file = path.resolve(args.find((a) => !a.startsWith('--')) || path.join(__dirname, '..', 'test', 'fixtures', 'tusharDump.sql'));
  const db = config.db.database;

  if (!fs.existsSync(file)) throw new Error(`Dump file not found: ${file}`);
  let sql = fs.readFileSync(file, 'utf8');
  const m = sql.match(/^USE `([^`]+)`;/m) || sql.match(/CREATE DATABASE\s+(?:IF NOT EXISTS\s+)?`([^`]+)`/i);
  if (m && m[1] !== db) sql = sql.split('`' + m[1] + '`').join('`' + db + '`');
  if (!/^USE `/m.test(sql)) sql = `CREATE DATABASE IF NOT EXISTS \`${db}\`;\nUSE \`${db}\`;\n` + sql;

  const conn = await mysql.createConnection({ ...config.db, database: undefined, multipleStatements: true });
  try {
    const [[{ n }]] = await conn.query(
      'SELECT COUNT(*) AS n FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_TYPE = "BASE TABLE"',
      [db]
    );
    if (n > 0 && !force) {
      console.log(`Database "${db}" already exists with ${n} tables, so nothing was loaded.`);
      console.log('That is usually what you want: run  npm run sync -- avyra.xlsx --dry-run  next.');
      console.log(`To wipe it and reload from the dump instead:  npm run load-dump -- --force`);
      return;
    }
    if (n > 0) console.log(`--force: replacing the ${n} tables in "${db}"…`);
    console.log(`Loading ${path.basename(file)} into "${db}"…`);
    await conn.query(sql);
    const [rows] = await conn.query(
      'SELECT COUNT(*) AS n FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_TYPE = "BASE TABLE"',
      [db]
    );
    console.log(`Done: "${db}" now has ${rows[0].n} tables.`);
  } finally {
    await conn.end();
  }
}

main().catch((e) => {
  console.error('Load failed: ' + (connectionHint(e, config.db) || e.sqlMessage || e.message));
  process.exit(1);
});
