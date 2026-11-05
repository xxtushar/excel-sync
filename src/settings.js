'use strict';
/**
 * Every setting the toolkit reads, with its type and default. Each one is looked up in, highest first:
 *   1. the environment (variables set in the shell or by the host)
 *   2. config.json in the project folder (or the file named by CONFIG_FILE)
 *   3. .env in the project folder (or the file named by DOTENV_CONFIG_PATH)
 *   4. the default below
 * config.json holds typed JSON values (["a", "b"], not "a,b"); the environment and .env hold text, which is parsed
 * into the same types. Any value of the wrong type, and any unknown key in config.json, stops startup.
 */

const SETTINGS = {
  // Database the admin upload API reads and writes. The check-upload command never connects to it.
  DB_HOST: { type: 'string', default: 'localhost' },
  DB_PORT: { type: 'int', min: 1, max: 65535, default: 3306 },
  DB_USER: { type: 'string', default: 'root' },
  DB_PASSWORD: { type: 'secret', default: '' },
  DB_NAME: { type: 'string', default: 'avyra' },

  // The standalone API server (npm start). A backend that mounts the router uses its own port and login.
  PORT: { type: 'int', min: 1, max: 65535, default: 4000 },
  // When set, every request to the standalone server needs the header  x-api-key: <this value>
  API_KEY: { type: 'secret', default: '' },
  MAX_UPLOAD_MB: { type: 'int', min: 1, max: 200, default: 20 },
  // How long a preview's confirmation token stays valid
  PREVIEW_MINUTES: { type: 'int', min: 1, max: 1440, default: 15 },

  // Which tables and sheets the check looks at
  SOFT_DELETE_COLUMNS: { type: 'list', default: ['is_active', 'rstatus', 'active'] },
  IGNORE_SHEETS: { type: 'list', default: ['_README'] },
  STATIC_PREFIX: { type: 'string', default: 'st_' },
  DYNAMIC_PREFIX: { type: 'string', default: 'dy_' },
};

const BAD = Symbol('bad');

/** What a setting must look like, for error messages. */
function expected(s, fromJson) {
  if (s.type === 'list') return fromJson ? 'a list of names, like ["a", "b"]' : 'a comma-separated list of names';
  if (s.type === 'int') return `a whole number from ${s.min} to ${s.max}${fromJson ? ' (no quotes)' : ''}`;
  return fromJson ? 'text in quotes' : 'text';
}

function fromJson(s, v) {
  if (s.type === 'list') return Array.isArray(v) && v.every((x) => typeof x === 'string') ? v.map((x) => x.trim()).filter(Boolean) : BAD;
  if (s.type === 'int') return Number.isInteger(v) ? v : BAD;
  if (s.type === 'secret') return typeof v === 'string' ? v : BAD; // passwords may start or end with spaces
  return typeof v === 'string' ? v.trim() : BAD;
}

function fromText(s, text) {
  if (s.type === 'secret') return text;
  const t = text.trim();
  if (s.type === 'int') return /^\d+$/.test(t) ? Number(t) : BAD;
  return s.type === 'list' ? t.split(',').map((x) => x.trim()).filter(Boolean) : t;
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
  if (s.type === 'int') return v >= s.min && v <= s.max;
  return s.type !== 'string' || v !== '';
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
    // An empty variable counts as not set, so `DB_NAME=` in .env falls through to the default.
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
      errors.push(`${name} in ${where} must be ${expected(s, typed)}, got ${s.type === 'secret' ? 'something else' : JSON.stringify(raw)}.`);
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
