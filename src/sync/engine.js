'use strict';
/**
 * Orchestrates one sync run: lock → read schema → read workbook → diff → (apply in a transaction) → log.
 * Used by the upload endpoint, the file watcher and the CLI alike.
 */

const crypto = require('crypto');
const config = require('../config');
const { introspect } = require('../schema/introspect');
const { readWorkbook } = require('../excel/readWorkbook');
const { buildPlan, totals } = require('./diff');
const { applyPlan, friendlyDbError } = require('./apply');
const store = require('./store');

class SyncBusyError extends Error {
  constructor() {
    super('Another sync is already running. Try again in a moment.');
    this.status = 409;
  }
}

function createEngine(pool, dbName = config.db.database) {
  let schemaCache = null;
  const lockName = `excel_sync:${dbName}`;

  async function getSchema(refresh = false) {
    if (!schemaCache || refresh) schemaCache = await introspect(pool, dbName);
    return schemaCache;
  }

  /**
   * @param {object} o
   * @param {Buffer|string} o.source        workbook buffer or file path
   * @param {string}  [o.sourceName]
   * @param {boolean} [o.dryRun]            build the plan only
   * @param {boolean} [o.full]              diff every sheet, even ones whose hash has not changed
   * @param {'soft'|'hard'|'none'} [o.deleteMode]
   * @param {boolean} [o.allowMassDelete]
   * @param {string[]} [o.tables]           limit to these tables
   * @param {'upload'|'watch'|'cli'|'api'} [o.trigger]
   */
  async function runSync(o) {
    const startedAt = new Date();
    const trigger = o.trigger || 'api';
    const deleteMode = o.deleteMode || config.deleteMode;
    if (!['soft', 'hard', 'none'].includes(deleteMode)) {
      const e = new Error(`deleteMode must be soft, hard or none (got "${deleteMode}")`);
      e.status = 400;
      throw e;
    }

    const conn = await pool.getConnection();
    let locked = false;
    try {
      const [[{ got }]] = await conn.query('SELECT GET_LOCK(?, 0) AS got', [lockName]);
      if (got !== 1) throw new SyncBusyError();
      locked = true;

      const schema = await getSchema(true); // pick up schema changes on every run
      const onlyTables = o.tables && o.tables.length ? new Set(o.tables) : null;
      const workbook = await readWorkbook(o.source, schema, { onlyTables });
      // The remembered hash covers the sheet content AND the delete mode, so re-running an unchanged sheet with
      // deleteMode=hard (after a soft run kept some rows) is not skipped.
      for (const s of workbook.sheets) s.hash = crypto.createHash('sha256').update(`${s.hash}|${deleteMode}`).digest('hex');
      const states = await store.getStates(conn);
      const plan = await buildPlan(conn, schema, workbook, {
        states,
        full: !!o.full,
        deleteMode,
        allowMassDelete: !!o.allowMassDelete,
      });

      const errors = [...workbook.errors, ...plan.errors];
      const warnings = [...workbook.warnings, ...plan.warnings];
      const t = totals(plan);
      const result = {
        status: 'ok',
        dryRun: !!o.dryRun,
        trigger,
        source: o.sourceName || (typeof o.source === 'string' ? o.source : 'upload'),
        deleteMode,
        totals: t,
        tables: plan.tables,
        errors,
        warnings,
      };

      if (errors.length) {
        result.status = 'invalid';
        result.message = `Nothing was changed: fix the ${errors.length} problem(s) listed in errors and save again.`;
      } else if (o.dryRun) {
        result.status = 'preview';
        result.message = t.tablesChanged ? `${t.tablesChanged} table(s) would change.` : 'The database already matches the workbook.';
      } else if (!t.tablesChanged) {
        result.status = 'no-changes';
        result.message = 'The database already matches the workbook.';
      }

      if (!o.dryRun && result.status !== 'invalid') {
        await conn.beginTransaction();
        try {
          if (t.tablesChanged) await applyPlan(conn, schema, plan);
          await conn.commit();
          if (t.tablesChanged) {
            result.status = 'applied';
            result.message = `Applied: ${t.inserted} inserted, ${t.updated} updated, ${t.softDeleted} soft-deleted, ${t.hardDeleted} deleted.`;
          }
        } catch (e) {
          await conn.rollback().catch(() => {});
          result.status = 'failed';
          result.message = 'The database rejected a change, so the whole sync was rolled back. Nothing was changed.';
          result.errors.push({ sheet: e.sheet, row: e.row, message: friendlyDbError(e), code: e.code });
        }
      }

      // Hashes are remembered only after a successful apply, so a sheet is re-checked until it goes in cleanly.
      if (['applied', 'no-changes'].includes(result.status)) {
        const good = workbook.sheets.filter((s) => !s.hasErrors);
        result.logId = await writeLogSafe(conn, result, startedAt);
        await store.saveStates(conn, good, result.logId).catch(() => {});
      } else if (!o.dryRun) {
        result.logId = await writeLogSafe(conn, result, startedAt);
      }

      result.durationMs = Date.now() - startedAt.getTime();
      return result;
    } finally {
      if (locked) await conn.query('SELECT RELEASE_LOCK(?)', [lockName]).catch(() => {});
      conn.release();
    }
  }

  async function writeLogSafe(conn, result, startedAt) {
    const finishedAt = new Date();
    try {
      return await store.writeLog(conn, {
        startedAt,
        finishedAt,
        durationMs: finishedAt - startedAt,
        trigger: result.trigger,
        source: result.source,
        status: result.status,
        totals: result.totals,
        summary: result.tables
          .filter((x) => x.status === 'changed' || x.status === 'invalid')
          .map((x) => ({
            table: x.table,
            status: x.status,
            inserted: x.inserts.length,
            updated: x.updates.length,
            softDeleted: x.softDeletes.length,
            hardDeleted: x.hardDeletes.length,
            kept: x.notDeleted.length,
            insertedIds: x.inserts.map((i) => i.id ?? i.assignedId),
            updatedIds: x.updates.map((u) => u.id),
            removedIds: [...x.softDeletes, ...x.hardDeletes].map((d) => d.id),
          })),
        errors: result.errors,
        warnings: result.warnings,
      });
    } catch (e) {
      result.warnings.push({ message: `Could not write the sync log: ${e.message}` });
      return null;
    }
  }

  return { getSchema, runSync, pool };
}

module.exports = { createEngine, SyncBusyError };
