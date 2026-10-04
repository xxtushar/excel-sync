'use strict';
/** Bookkeeping tables: per-sheet hashes of the last successful sync, and a log of every run. */

const config = require('../config');
const { q } = require('../db');

async function ensureTables(pool) {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS ${q(config.stateTable)} (
      table_name  VARCHAR(64) NOT NULL PRIMARY KEY,
      sheet_hash  CHAR(64)    NOT NULL,
      row_count   INT         NOT NULL,
      synced_at   DATETIME    NOT NULL,
      log_id      INT         NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS ${q(config.logTable)} (
      id            INT AUTO_INCREMENT PRIMARY KEY,
      started_at    DATETIME     NOT NULL,
      finished_at   DATETIME     NOT NULL,
      duration_ms   INT          NOT NULL,
      \`trigger\`     VARCHAR(20)  NOT NULL,
      source        VARCHAR(255) NULL,
      status        VARCHAR(20)  NOT NULL,
      inserted      INT NOT NULL DEFAULT 0,
      updated       INT NOT NULL DEFAULT 0,
      soft_deleted  INT NOT NULL DEFAULT 0,
      hard_deleted  INT NOT NULL DEFAULT 0,
      tables_changed INT NOT NULL DEFAULT 0,
      summary       JSON NULL,
      errors        JSON NULL,
      warnings      JSON NULL,
      KEY idx_started (started_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);
}

async function getStates(conn) {
  const [rows] = await conn.query(`SELECT table_name, sheet_hash, row_count, synced_at FROM ${q(config.stateTable)}`);
  return Object.fromEntries(rows.map((r) => [r.table_name, r]));
}

async function saveStates(conn, sheets, logId) {
  if (!sheets.length) return;
  const values = sheets.map((s) => [s.table, s.hash, s.rows.length, new Date(), logId]);
  await conn.query(
    `INSERT INTO ${q(config.stateTable)} (table_name, sheet_hash, row_count, synced_at, log_id) VALUES ?
     ON DUPLICATE KEY UPDATE sheet_hash = VALUES(sheet_hash), row_count = VALUES(row_count),
                             synced_at = VALUES(synced_at), log_id = VALUES(log_id)`,
    [values]
  );
}

async function clearStates(pool, tables) {
  if (tables && tables.length) await pool.query(`DELETE FROM ${q(config.stateTable)} WHERE table_name IN (?)`, [tables]);
  else await pool.query(`DELETE FROM ${q(config.stateTable)}`);
}

const cap = (arr, n = 500) => (arr && arr.length > n ? arr.slice(0, n).concat([{ message: `…and ${arr.length - n} more` }]) : arr);

async function writeLog(conn, entry) {
  const t = entry.totals || {};
  const [res] = await conn.query(
    `INSERT INTO ${q(config.logTable)}
       (started_at, finished_at, duration_ms, \`trigger\`, source, status, inserted, updated, soft_deleted, hard_deleted,
        tables_changed, summary, errors, warnings)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      entry.startedAt,
      entry.finishedAt,
      entry.durationMs,
      entry.trigger,
      entry.source ? String(entry.source).slice(0, 255) : null,
      entry.status,
      t.inserted || 0,
      t.updated || 0,
      t.softDeleted || 0,
      t.hardDeleted || 0,
      t.tablesChanged || 0,
      JSON.stringify(entry.summary || null),
      JSON.stringify(cap(entry.errors) || []),
      JSON.stringify(cap(entry.warnings) || []),
    ]
  );
  return res.insertId;
}

async function listLogs(pool, { limit = 20, offset = 0 } = {}) {
  const [rows] = await pool.query(
    `SELECT id, started_at, finished_at, duration_ms, \`trigger\`, source, status, inserted, updated, soft_deleted,
            hard_deleted, tables_changed, JSON_LENGTH(errors) AS error_count, JSON_LENGTH(warnings) AS warning_count
       FROM ${q(config.logTable)} ORDER BY id DESC LIMIT ? OFFSET ?`,
    [limit, offset]
  );
  return rows;
}

async function getLog(pool, id) {
  const [rows] = await pool.query(`SELECT * FROM ${q(config.logTable)} WHERE id = ?`, [id]);
  return rows[0] || null;
}

module.exports = { ensureTables, getStates, saveStates, clearStates, writeLog, listLogs, getLog };
