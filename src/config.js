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
  db: { host: env.DB_HOST, port: env.DB_PORT, user: env.DB_USER, password: env.DB_PASSWORD, database: env.DB_NAME },
  port: env.PORT,
  apiKey: env.API_KEY,
  maxUploadMb: env.MAX_UPLOAD_MB,
  previewMinutes: env.PREVIEW_MINUTES,

  // Table naming: which prefixes count as static / dynamic. Anything else is ignored.
  staticPrefix: env.STATIC_PREFIX,
  dynamicPrefix: env.DYNAMIC_PREFIX,
  // Columns that mark a row as switched off (0), first match wins.
  softDeleteColumns: env.SOFT_DELETE_COLUMNS,
  // Sheets to skip entirely.
  ignoreSheets: env.IGNORE_SHEETS,

  projectRoot: PROJECT_ROOT,
  resolvePath,
  displayPath,
};

module.exports = config;
