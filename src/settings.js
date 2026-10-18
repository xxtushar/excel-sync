'use strict';
/**
 * Every setting the toolkit reads, with its type and default. Each one is looked up in, highest first:
 *   1. the environment (variables set in the shell or by the host)
 *   2. config.json in the project folder (or the file named by CONFIG_FILE)
 *   3. .env in the project folder (or the file named by DOTENV_CONFIG_PATH)
 *   4. the default below
 * config.json holds typed JSON values (3306, not "3306"); the environment and .env hold text, which is parsed
 * into the same types. Any value of the wrong type, and any unknown key in config.json, stops startup.
 */

const SETTINGS = {
  // Database
  DB_HOST: { type: 'string', default: 'localhost' },
  DB_PORT: { type: 'int', default: 3306, min: 1, max: 65535 },
  DB_USER: { type: 'string', default: 'root' },
  DB_PASSWORD: { type: 'string', default: '', empty: true, secret: true },
  DB_NAME: { type: 'string', default: 'avyra' },

  // API
  PORT: { type: 'int', default: 4000, min: 1, max: 65535 },
  API_KEY: { type: 'string', default: '', empty: true, secret: true },
  MAX_UPLOAD_MB: { type: 'int', default: 20, min: 1 },
  PAGE_LIMIT_MAX: { type: 'int', default: 500, min: 1 },

  // File watcher
  WATCH_FILE: { type: 'string', default: 'avyra.xlsx' },
  WATCH_ENABLED: { type: 'bool', default: true },
  WATCH_DEBOUNCE_MS: { type: 'int', default: 2000, min: 0 },
  WATCH_POLL: { type: 'bool', default: false },

  // Sync rules
  DELETE_MODE: { type: 'enum', values: ['soft', 'hard', 'none'], default: 'soft' },
  SOFT_DELETE_COLUMNS: { type: 'list', default: ['is_active', 'rstatus', 'active'] },
  BLANK_ID_MODE: { type: 'enum', values: ['reject', 'insert'], default: 'reject' },
  UNKNOWN_COLUMN_MODE: { type: 'enum', values: ['warn', 'error', 'add'], default: 'warn' },
  IGNORE_SHEETS: { type: 'list', default: ['_README'] },
  STATIC_PREFIX: { type: 'string', default: 'st_' },
  DYNAMIC_PREFIX: { type: 'string', default: 'dy_' },

  // Tests only
  TEST_DB_NAME: { type: 'string', default: 'avyra_test' },
};

const TRUE = new Set(['1', 'true', 'yes', 'on']);
const FALSE = new Set(['0', 'false', 'no', 'off']);
const BAD = Symbol('bad');

/** What a setting must look like, for error messages. */
function expected(s, fromJson) {
  switch (s.type) {
    case 'int': {
      const range =
        s.max !== undefined ? ` from ${s.min} to ${s.max}` : s.min !== undefined ? ` of at least ${s.min}` : '';
      return `a whole number${range}${fromJson ? ' (no quotes)' : ''}`;
    }
    case 'bool':
      return fromJson ? 'true or false (no quotes)' : 'true or false';
    case 'list':
      return fromJson ? 'a list of names, like ["a", "b"]' : 'a comma-separated list of names';
    case 'enum':
      return `one of ${s.values.map((v) => `"${v}"`).join(', ')}`;
    default:
      return fromJson ? 'text in quotes' : 'text';
  }
}

function fromJson(s, v) {
  switch (s.type) {
    case 'int':
      return Number.isInteger(v) ? v : BAD;
    case 'bool':
      return typeof v === 'boolean' ? v : BAD;
    case 'list':
      return Array.isArray(v) && v.every((x) => typeof x === 'string') ? v.map((x) => x.trim()).filter(Boolean) : BAD;
    default:
      return typeof v === 'string' ? v.trim() : BAD;
  }
}

function fromText(s, text) {
  const t = text.trim();
  switch (s.type) {
    case 'int':
      return /^-?\d+$/.test(t) ? Number(t) : BAD;
    case 'bool':
      return TRUE.has(t.toLowerCase()) ? true : FALSE.has(t.toLowerCase()) ? false : BAD;
    case 'list':
      return t.split(',').map((x) => x.trim()).filter(Boolean);
    default:
      return s.secret ? text : t; // a password may start or end with a space
  }
}

/** The setting name within two typos of `key` (case ignored), for "did you mean". */
function closest(key) {
  const k = key.toUpperCase();
  let best = null;
  let bestDist = 3;
  for (const name of Object.keys(SETTINGS)) {
    const d = editDistance(k, name);
    if (d < bestDist) [best, bestDist] = [name, d];
  }
  return best;
}

function editDistance(a, b) {
  let prev = Array.from({ length: b.length + 1 }, (_, j) => j);
  for (let i = 1; i <= a.length; i++) {
    const cur = [i];
    for (let j = 1; j <= b.length; j++) cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
    prev = cur;
  }
  return prev[b.length];
}

function inRange(s, v) {
  if (s.type === 'int') return (s.min === undefined || v >= s.min) && (s.max === undefined || v <= s.max);
  if (s.type === 'enum') return s.values.includes(v);
  if (s.type === 'string') return s.empty || v !== '';
  return true;
}

/**
 * Resolves every setting from the given sources. Pure, so it can be tested without files.
 * @param {object} o
 * @param {object} [o.env]       environment variables (text)
 * @param {object} [o.json]      parsed config.json (typed), or null when there is none
 * @param {object} [o.dotenv]    parsed .env (text)
 * @param {string} [o.jsonName]  how to name config.json in messages
 * @param {string} [o.dotenvName]
 * @returns {{ values: object, sources: object, errors: string[] }}
 */
function resolveSettings({ env = {}, json = null, dotenv = {}, jsonName = 'config.json', dotenvName = '.env' } = {}) {
  const values = {};
  const sources = {};
  const errors = [];

  if (json) {
    for (const key of Object.keys(json)) {
      if (SETTINGS[key]) continue;
      const near = closest(key);
      errors.push(`${jsonName}: unknown setting "${key}".${near ? ` Did you mean "${near}"?` : ' config.example.json lists them all.'}`);
    }
  }

  for (const [name, s] of Object.entries(SETTINGS)) {
    // An empty variable counts as not set, so `DB_HOST=` in .env falls through to the default.
    const candidates = [
      [env[name], 'the environment', false],
      [json ? json[name] : undefined, jsonName, true],
      [dotenv[name], dotenvName, false],
    ];
    const hit = candidates.find(([v, , typed]) => v !== undefined && v !== null && (typed || v !== ''));
    if (!hit) {
      values[name] = s.default;
      sources[name] = 'default';
      continue;
    }
    const [raw, where, typed] = hit;
    const v = typed ? fromJson(s, raw) : fromText(s, String(raw));
    if (v === BAD || !inRange(s, v)) {
      const shown = s.secret ? `a ${Array.isArray(raw) ? 'list' : typeof raw}` : JSON.stringify(raw);
      errors.push(`${name} in ${where} must be ${expected(s, typed)}, got ${shown}.`);
      values[name] = s.default;
      sources[name] = 'default';
      continue;
    }
    values[name] = v;
    sources[name] = where;
  }
  return { values, sources, errors };
}

class ConfigError extends Error {
  #errors;
  constructor(errors) {
    super(`Invalid settings:\n  - ${errors.join('\n  - ')}`);
    this.name = 'ConfigError';
    this.#errors = errors;
    this.stack = `${this.name}: ${this.message}`; // no stack trace: when startup fails, Node prints just the list
  }

  get errors() {
    return this.#errors;
  }
}

module.exports = { SETTINGS, resolveSettings, ConfigError };
