'use strict';
const os = require('os');
const path = require('path');

// The project folder, wherever it lives on this machine. Nothing below depends on where the
// project was cloned or which directory the app is started from.
const PROJECT_ROOT = path.resolve(__dirname, '..');

// Load .env from the project folder (not from the current directory), unless one was given explicitly.
require('dotenv').config({ path: process.env.DOTENV_CONFIG_PATH || path.join(PROJECT_ROOT, '.env'), quiet: true });

/** Relative paths are relative to the project folder; `~/...` is the user's home folder. */
function resolvePath(p) {
  if (!p) return '';
  if (p === '~' || p.startsWith('~/') || p.startsWith('~\\')) p = path.join(os.homedir(), p.slice(1));
  return path.isAbsolute(p) ? path.normalize(p) : path.resolve(PROJECT_ROOT, p);
}

/** How to show a path in logs: relative when it is inside the project folder. */
function displayPath(p) {
  const rel = path.relative(PROJECT_ROOT, p);
  return rel && !rel.startsWith('..') && !path.isAbsolute(rel) ? rel : p;
}

function bool(v, def) {
  if (v === undefined || v === '') return def;
  return ['1', 'true', 'yes', 'on'].includes(String(v).toLowerCase());
}

function list(v, def) {
  if (v === undefined || v === '') return def;
  return String(v).split(',').map((s) => s.trim()).filter(Boolean);
}

const config = {
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'avyra',
  },
  port: Number(process.env.PORT || 4000),
  apiKey: process.env.API_KEY || '',

  // Table naming: which prefixes count as static / dynamic. Anything else is ignored.
  staticPrefix: process.env.STATIC_PREFIX || 'st_',
  dynamicPrefix: process.env.DYNAMIC_PREFIX || 'dy_',

  // What happens to rows that exist in the DB but were removed from the Excel sheet.
  //   soft : set the soft-delete column to 0 when the table has one; otherwise leave the row and report it
  //   hard : soft where possible, otherwise DELETE (cascades through every child table!)
  //   none : never delete, only report
  deleteMode: process.env.DELETE_MODE || 'soft',
  // Columns used for soft delete, first match wins. dy_user has both is_active and rstatus: both are set.
  softDeleteColumns: list(process.env.SOFT_DELETE_COLUMNS, ['is_active', 'rstatus', 'active']),

  // Rows with an empty id cell:
  //   reject : stop and tell the user which id to use (safe: no duplicates on the next save)
  //   insert : insert with AUTO_INCREMENT (the row will be inserted AGAIN on the next sync unless you add the id)
  blankIdMode: process.env.BLANK_ID_MODE || 'reject',

  // Columns in the sheet that do not exist in the table: 'warn' (ignore them) or 'error'.
  unknownColumnMode: process.env.UNKNOWN_COLUMN_MODE || 'warn',

  // Sheets to skip entirely.
  ignoreSheets: list(process.env.IGNORE_SHEETS, ['_README']),

  // File watcher. Default: avyra.xlsx in the project folder. Relative paths resolve against the
  // project folder, so the same .env works on every machine.
  watchFile: resolvePath(process.env.WATCH_FILE || 'avyra.xlsx'),
  watchDebounceMs: Number(process.env.WATCH_DEBOUNCE_MS || 2000),
  watchEnabled: bool(process.env.WATCH_ENABLED, true),

  projectRoot: PROJECT_ROOT,
  resolvePath,
  displayPath,

  maxUploadMb: Number(process.env.MAX_UPLOAD_MB || 20),
  pageLimitMax: Number(process.env.PAGE_LIMIT_MAX || 500),

  // Internal bookkeeping tables (created automatically, hidden from the table API).
  logTable: '_excel_sync_log',
  stateTable: '_excel_sync_state',
};

module.exports = config;
