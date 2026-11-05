'use strict';
/**
 * The MySQL connection pool for the admin upload API.
 *  - dateStrings: DATETIME/TIMESTAMP come back as 'YYYY-MM-DD HH:MM:SS' text, the same shape as the checked
 *    Excel values, so "did this cell change?" is a plain comparison.
 *  - Every connection uses UTC, so TIMESTAMP columns are not shifted by the server's time zone (e.g. IST).
 */

const mysql = require('mysql2/promise');

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
  pool.on('connection', (conn) => {
    conn.query("SET time_zone = '+00:00'", (err) => {
      if (err) console.error(`[excel-upload] could not set the session time zone to UTC: ${err.message}`);
    });
  });
  return pool;
}

/** Backtick-quotes an identifier. Only called with names read from INFORMATION_SCHEMA. */
const q = (name) => '`' + String(name).replace(/`/g, '``') + '`';

/** The usual connection failures, as a next step. */
function connectionHint(e, cfg = {}) {
  switch (e && e.code) {
    case 'ECONNREFUSED':
      return `Nothing is listening on ${cfg.host || 'localhost'}:${cfg.port || 3306}. Start MySQL and check DB_HOST / DB_PORT in config.json.`;
    case 'ER_ACCESS_DENIED_ERROR':
      return `MySQL refused user "${cfg.user}". Check DB_USER and DB_PASSWORD in config.json.`;
    case 'ER_BAD_DB_ERROR':
      return `Database "${cfg.database}" does not exist. Check DB_NAME in config.json.`;
    case 'ENOTFOUND':
      return `Host "${cfg.host}" not found. Check DB_HOST in config.json.`;
    default:
      return null;
  }
}

module.exports = { createPool, q, connectionHint };
