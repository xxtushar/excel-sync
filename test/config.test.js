'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const { SETTINGS, resolveSettings } = require('../src/settings');

test('config.json values are typed; the environment and .env are parsed into the same types', () => {
  const { values, sources, errors } = resolveSettings({
    json: { DB_PORT: 3307, WATCH_ENABLED: false, IGNORE_SHEETS: ['_README', 'notes'], DB_PASSWORD: ' p@ss ' },
    dotenv: { PORT: '4100', WATCH_POLL: 'yes', SOFT_DELETE_COLUMNS: 'is_active, rstatus' },
  });
  assert.deepEqual(errors, []);
  assert.equal(values.DB_PORT, 3307);
  assert.equal(values.WATCH_ENABLED, false);
  assert.deepEqual(values.IGNORE_SHEETS, ['_README', 'notes']);
  assert.equal(values.PORT, 4100);
  assert.equal(values.WATCH_POLL, true);
  assert.deepEqual(values.SOFT_DELETE_COLUMNS, ['is_active', 'rstatus']);
  assert.equal(values.DB_HOST, 'localhost');
  assert.equal(sources.DB_HOST, 'default');
  assert.equal(sources.PORT, '.env');
});

test('the environment beats config.json, which beats .env; an empty variable counts as not set', () => {
  const { values, sources } = resolveSettings({
    env: { DB_USER: 'from_env', DB_NAME: '' },
    json: { DB_USER: 'from_json', DB_NAME: 'json_db', DB_HOST: 'json_host' },
    dotenv: { DB_USER: 'from_dotenv', DB_NAME: 'dotenv_db', DB_HOST: 'dotenv_host' },
  });
  assert.equal(values.DB_USER, 'from_env');
  assert.equal(values.DB_NAME, 'json_db');
  assert.equal(values.DB_HOST, 'json_host');
  assert.equal(sources.DB_HOST, 'config.json');
});

test('wrong types, out-of-range values and unknown keys are all reported, without showing secrets', () => {
  const { errors } = resolveSettings({
    json: { DB_PORT: '3306', WATCH_ENABLED: 'true', DELETE_MODE: 'wipe', DB_PASSWORD: 12345, DB_HOST: '', DB_PROT: 3306 },
    dotenv: { PORT: '70000', WATCH_DEBOUNCE_MS: 'soon', WATCH_POLL: 'maybe' },
  });
  const msg = errors.join('\n');
  assert.equal(errors.length, 9, msg);
  assert.match(msg, /DB_PORT in config\.json must be a whole number from 1 to 65535 \(no quotes\), got "3306"/);
  assert.match(msg, /WATCH_ENABLED in config\.json must be true or false \(no quotes\)/);
  assert.match(msg, /DELETE_MODE in config\.json must be one of "soft", "hard", "none", got "wipe"/);
  assert.match(msg, /DB_PASSWORD in config\.json must be text in quotes, got a number\./);
  assert.doesNotMatch(msg, /12345/);
  assert.match(msg, /DB_HOST in config\.json must be text in quotes, got ""/);
  assert.match(msg, /unknown setting "DB_PROT"\. Did you mean "DB_PORT"\?/);
  assert.match(msg, /PORT in \.env must be a whole number from 1 to 65535, got "70000"/);
  assert.match(msg, /WATCH_DEBOUNCE_MS in \.env must be a whole number of at least 0, got "soon"/);
  assert.match(msg, /WATCH_POLL in \.env must be true or false, got "maybe"/);
});

test('config.example.json lists every setting with its default', () => {
  const example = JSON.parse(fs.readFileSync(require.resolve('../config.example.json'), 'utf8'));
  assert.deepEqual(Object.keys(example).sort(), Object.keys(SETTINGS).sort());
  for (const [name, s] of Object.entries(SETTINGS)) assert.deepEqual(example[name], s.default, name);
});
