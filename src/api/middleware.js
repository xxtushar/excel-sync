'use strict';
const crypto = require('crypto');
const config = require('../config');

/** Optional shared-key auth. When API_KEY is set, every request needs header `x-api-key`. */
function apiKeyAuth(apiKey = config.apiKey) {
  return (req, res, next) => {
    if (!apiKey) return next();
    const given = req.get('x-api-key') || '';
    const a = Buffer.from(given);
    const b = Buffer.from(apiKey);
    if (a.length === b.length && crypto.timingSafeEqual(a, b)) return next();
    res.status(401).json({ error: 'Missing or wrong x-api-key header.' });
  };
}

class HttpError extends Error {
  constructor(status, message, extra) {
    super(message);
    this.status = status;
    this.extra = extra;
  }
}

const DB_ERROR_STATUS = {
  ER_DUP_ENTRY: 409,
  ER_NO_REFERENCED_ROW_2: 400,
  ER_NO_REFERENCED_ROW: 400,
  ER_ROW_IS_REFERENCED_2: 409,
  ER_DATA_TOO_LONG: 400,
  ER_BAD_NULL_ERROR: 400,
  ER_TRUNCATED_WRONG_VALUE: 400,
  ER_TRUNCATED_WRONG_VALUE_FOR_FIELD: 400,
  ER_WARN_DATA_OUT_OF_RANGE: 400,
  ER_NO_DEFAULT_FOR_FIELD: 400,
};

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  if (err.code === 'LIMIT_FILE_SIZE') return res.status(413).json({ error: `File is larger than ${config.maxUploadMb} MB.` });
  if (err.code && DB_ERROR_STATUS[err.code]) return res.status(DB_ERROR_STATUS[err.code]).json({ error: err.sqlMessage, code: err.code });
  const status = err.status || 500;
  if (status >= 500) console.error('[excel-sync]', err);
  res.status(status).json({ error: status >= 500 && !err.expose ? 'Internal error: ' + err.message : err.message, ...(err.extra || {}) });
}

const truthy = (v) => ['1', 'true', 'yes', 'on'].includes(String(v ?? '').toLowerCase());

module.exports = { apiKeyAuth, errorHandler, HttpError, truthy };
