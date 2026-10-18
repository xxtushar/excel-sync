'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const dotenv = require('dotenv');
const { resolveSettings, ConfigError } = require('./settings');

// The project folder, wherever it lives on this machine. Nothing below depends on where the
// project was cloned or which directory the app is started from.
const PROJECT_ROOT = path.resolve(__dirname, '..');

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

/** A file's text, or null when it does not exist (an error if the file was asked for explicitly). */
function readOptional(file, explicit) {
  try {
    return fs.readFileSync(file, 'utf8');
  } catch (e) {
    if (e.code === 'ENOENT' && !explicit) return null;
    throw new ConfigError([`Cannot read ${file}: ${e.message}`]);
  }
}

/** config.json and .env from the project folder (not the current directory), unless others were named. */
function loadSettings() {
  const jsonFile = process.env.CONFIG_FILE ? resolvePath(process.env.CONFIG_FILE) : path.join(PROJECT_ROOT, 'config.json');
  const dotenvFile = process.env.DOTENV_CONFIG_PATH ? resolvePath(process.env.DOTENV_CONFIG_PATH) : path.join(PROJECT_ROOT, '.env');
  const jsonName = displayPath(jsonFile);

  let json = null;
  const jsonText = readOptional(jsonFile, !!process.env.CONFIG_FILE);
  if (jsonText !== null) {
    try {
      json = JSON.parse(jsonText);
    } catch (e) {
      throw new ConfigError([`${jsonName} is not valid JSON: ${e.message}`]);
    }
    if (!json || typeof json !== 'object' || Array.isArray(json)) throw new ConfigError([`${jsonName} must hold one JSON object: { "DB_USER": "root", ... }`]);
  }
  const dotenvText = readOptional(dotenvFile, !!process.env.DOTENV_CONFIG_PATH);

  const { values, errors } = resolveSettings({
    env: process.env,
    json,
    dotenv: dotenvText === null ? {} : dotenv.parse(dotenvText),
    jsonName,
    dotenvName: displayPath(dotenvFile),
  });
  if (errors.length) throw new ConfigError(errors);
  return values;
}

const env = loadSettings();

const config = {
  db: {
    host: env.DB_HOST,
    port: env.DB_PORT,
    user: env.DB_USER,
    password: env.DB_PASSWORD,
    database: env.DB_NAME,
  },
  port: env.PORT,
  apiKey: env.API_KEY,

  // Table naming: which prefixes count as static / dynamic. Anything else is ignored.
  staticPrefix: env.STATIC_PREFIX,
  dynamicPrefix: env.DYNAMIC_PREFIX,

  // What happens to rows that exist in the DB but were removed from the Excel sheet.
  //   soft : set the soft-delete column to 0 when the table has one; otherwise leave the row and report it
  //   hard : soft where possible, otherwise DELETE (cascades through every child table!)
  //   none : never delete, only report
  deleteMode: env.DELETE_MODE,
  // Columns used for soft delete, first match wins. dy_user has both is_active and rstatus: both are set.
  softDeleteColumns: env.SOFT_DELETE_COLUMNS,

  // Rows with an empty id cell:
  //   reject : stop and tell the user which id to use (safe: no duplicates on the next save)
  //   insert : insert with AUTO_INCREMENT (the row will be inserted AGAIN on the next sync unless you add the id)
  blankIdMode: env.BLANK_ID_MODE,

  // Columns in the sheet that do not exist in the table:
  //   warn  : ignore them, with a warning
  //   error : stop the sync
  //   add   : add them to the table (nullable, type picked from the cells). Headers that are not valid
  //           column names (spaces, symbols) are still ignored, so they can hold your own notes.
  unknownColumnMode: env.UNKNOWN_COLUMN_MODE,

  // Sheets to skip entirely.
  ignoreSheets: env.IGNORE_SHEETS,

  // File watcher. Default: avyra.xlsx in the project folder. Relative paths resolve against the
  // project folder, so the same settings work on every machine.
  watchFile: resolvePath(env.WATCH_FILE),
  watchDebounceMs: env.WATCH_DEBOUNCE_MS,
  watchEnabled: env.WATCH_ENABLED,
  watchPoll: env.WATCH_POLL, // for network drives / WSL / Docker volumes, where file events don't arrive

  projectRoot: PROJECT_ROOT,
  resolvePath,
  displayPath,

  maxUploadMb: env.MAX_UPLOAD_MB,
  pageLimitMax: env.PAGE_LIMIT_MAX,

  // Throwaway database the tests rebuild before every test.
  testDbName: env.TEST_DB_NAME,

  // Internal bookkeeping tables (created automatically, hidden from the table API).
  logTable: '_excel_sync_log',
  stateTable: '_excel_sync_state',
};

module.exports = config;
