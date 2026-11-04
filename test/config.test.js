'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const { SETTINGS, resolveSettings } = require('../src/settings');

test('config.json values are typed; the environment and .env are parsed into the same types', () => {
  const { values, sources, errors } = resolveSettings({
    json: { IGNORE_SHEETS: ['_README', 'notes'], STATIC_PREFIX: ' s_ ' },
    dotenv: { SOFT_DELETE_COLUMNS: 'is_active, rstatus' },
  });
  assert.deepEqual(errors, []);
  assert.deepEqual(values.IGNORE_SHEETS, ['_README', 'notes']);
  assert.equal(values.STATIC_PREFIX, 's_');
  assert.deepEqual(values.SOFT_DELETE_COLUMNS, ['is_active', 'rstatus']);
  assert.equal(values.DYNAMIC_PREFIX, 'dy_');
  assert.equal(sources.DYNAMIC_PREFIX, 'default');
  assert.equal(sources.SOFT_DELETE_COLUMNS, '.env');
});

test('the environment beats config.json, which beats .env; an empty variable counts as not set', () => {
  const { values, sources } = resolveSettings({
    env: { STATIC_PREFIX: 'env_', DB_NAME: '' },
    json: { STATIC_PREFIX: 'json_', DB_NAME: 'json_db', DYNAMIC_PREFIX: 'jdy_' },
    dotenv: { STATIC_PREFIX: 'dotenv_', DB_NAME: 'dotenv_db', DYNAMIC_PREFIX: 'ddy_' },
  });
  assert.equal(values.STATIC_PREFIX, 'env_');
  assert.equal(values.DB_NAME, 'json_db');
  assert.equal(values.DYNAMIC_PREFIX, 'jdy_');
  assert.equal(sources.DYNAMIC_PREFIX, 'config.json');
});

test('wrong types, empty values and unknown keys are all reported', () => {
  const { errors } = resolveSettings({
    json: { IGNORE_SHEETS: '_README', SOFT_DELETE_COLUMNS: ['ok', 1], DB_NAME: 12345, STATIC_PREFIX: '', STATIC_PREFX: 'st_' },
  });
  const msg = errors.join('\n');
  assert.equal(errors.length, 5, msg);
  assert.match(msg, /IGNORE_SHEETS in config\.json must be a list of names, like \["a", "b"\], got "_README"/);
  assert.match(msg, /SOFT_DELETE_COLUMNS in config\.json must be a list of names/);
  assert.match(msg, /DB_NAME in config\.json must be text in quotes, got 12345\./);
  assert.match(msg, /STATIC_PREFIX in config\.json must be text in quotes, got ""/);
  assert.match(msg, /unknown setting "STATIC_PREFX"\. Did you mean "STATIC_PREFIX"\?/);
});

test('config.example.json lists every setting with its default', () => {
  const example = JSON.parse(fs.readFileSync(require.resolve('../config.example.json'), 'utf8'));
  assert.deepEqual(Object.keys(example).sort(), Object.keys(SETTINGS).sort());
  for (const [name, s] of Object.entries(SETTINGS)) assert.deepEqual(example[name], s.default, name);
});
