'use strict';
const mysql = require('mysql2/promise');

/**
 * Pool options matter for comparisons:
 *  - dateStrings: DATETIME/TIMESTAMP come back as 'YYYY-MM-DD HH:MM:SS' text, exactly like the Excel cells,
 *    with no timezone shifting.
 *  - decimalNumbers is left off: DECIMAL comes back as a string ('10400.00') and is compared at column scale.
 */
function createPool(dbConfig) {
  return mysql.createPool({
    ...dbConfig,
    waitForConnections: true,
    connectionLimit: 10,
    dateStrings: true,
    supportBigNumbers: true,
    bigNumberStrings: false,
    multipleStatements: false,
    charset: 'utf8mb4',
  });
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
