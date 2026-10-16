'use strict';
const mysql = require('mysql2/promise');

/**
 * Pool options matter for comparisons:
 *  - dateStrings: DATETIME/TIMESTAMP come back as 'YYYY-MM-DD HH:MM:SS' text, exactly like the Excel cells,
 *    with no timezone shifting.
 *  - decimalNumbers is left off: DECIMAL comes back as a string ('10400.00') and is compared at column scale.
 */
function createPool(dbConfig) {
  const pool = mysql.createPool({
    ...dbConfig,
    waitForConnections: true,
    connectionLimit: 10,
    dateStrings: true,
    supportBigNumbers: true,
    bigNumberStrings: false,
    multipleStatements: false,
    charset: 'utf8mb4',
  });
  // MySQL converts TIMESTAMP columns to the session time zone. The dump and the workbook hold UTC, so every
  // connection uses UTC; with the machine's zone (e.g. IST) each timestamp would read 5h30m off and be rewritten.
  // mysql2 emits 'connection' before handing the connection out, so this runs before any other query on it.
  pool.on('connection', (conn) => {
    conn.query("SET time_zone = '+00:00'", (err) => {
      if (err) console.error(`[excel-sync] could not set the session time zone to UTC: ${err.message}`);
    });
  });
  return pool;
}

/** Backtick-quote an identifier. Only ever called with names that came from INFORMATION_SCHEMA. */
function q(name) {
  return '`' + String(name).replace(/`/g, '``') + '`';
}

/** Turn the usual connection failures into a next step. */
function connectionHint(e, cfg = {}) {
  switch (e && e.code) {
    case 'ECONNREFUSED':
      return `Nothing is listening on ${cfg.host || 'localhost'}:${cfg.port || 3306}. Start MySQL (Mac: System Settings → MySQL → Start, or \`brew services start mysql\`) and check DB_HOST/DB_PORT in .env.`;
    case 'ER_ACCESS_DENIED_ERROR':
      return `MySQL refused user "${cfg.user}". Check DB_USER and DB_PASSWORD in .env (put the password in single quotes).`;
    case 'ER_BAD_DB_ERROR':
      return `Database "${cfg.database}" does not exist yet. Load it with: npm run load-dump`;
    case 'ENOTFOUND':
      return `Host "${cfg.host}" not found. Check DB_HOST in .env.`;
    default:
      return null;
  }
}

module.exports = { createPool, q, connectionHint };
