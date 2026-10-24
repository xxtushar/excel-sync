'use strict';
/**
 * Orchestrates one sync run: lock → read schema → read workbook → diff → (add columns, apply in a transaction) → log.
 * Used by the upload endpoint, the file watcher and the CLI alike.
 */

const crypto = require('crypto');
const config = require('../config');
const { introspect } = require('../schema/introspect');
const { readWorkbook } = require('../excel/readWorkbook');
const { loadLookups } = require('../excel/lookups');
const { buildPlan, totals } = require('./diff');
const { applyPlan, addColumns, dropColumns, friendlyDbError } = require('./apply');
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
   * Runs fn(conn) while holding the sync lock, so syncs and column changes never overlap.
   * Throws SyncBusyError (409) instead of waiting if the lock is taken.
   */
  async function withLock(fn) {
    const conn = await pool.getConnection();
    let locked = false;
    try {
      const [[{ got }]] = await conn.query('SELECT GET_LOCK(?, 0) AS got', [lockName]);
      if (got !== 1) throw new SyncBusyError();
      locked = true;
      return await fn(conn);
    } finally {
      if (locked) await conn.query('SELECT RELEASE_LOCK(?)', [lockName]).catch(() => {});
      conn.release();
    }
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

    return withLock(async (conn) => {
      const schema = await getSchema(true); // pick up schema changes on every run
      const onlyTables = o.tables && o.tables.length ? new Set(o.tables) : null;
      const lookups = await loadLookups(conn, schema);
      const workbook = await readWorkbook(o.source, schema, { onlyTables, lookups });
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
        // ALTER TABLE commits on its own, so new columns go in before the transaction and come out again on failure.
        let added = [];
        try {
          added = await addColumns(conn, plan);
          await conn.beginTransaction();
          if (t.tablesChanged) await applyPlan(conn, schema, plan);
          await conn.commit();
          if (t.tablesChanged) {
            result.status = 'applied';
            result.message =
              `Applied: ${t.inserted} inserted, ${t.updated} updated, ${t.softDeleted} soft-deleted, ${t.hardDeleted} deleted` +
              (t.columnsAdded ? `, ${t.columnsAdded} column(s) added.` : '.');
          }
        } catch (e) {
          await conn.rollback().catch(() => {});
          await dropColumns(conn, added).catch((dropErr) =>
            result.warnings.push({ message: `Could not remove the column(s) this sync added: ${dropErr.message}` })
          );
          result.status = 'failed';
          result.message = 'The database rejected a change, so the whole sync was rolled back. Nothing was changed.';
          result.errors.push({ sheet: e.sheet, row: e.row, message: friendlyDbError(e), code: e.code });
        }
        if (t.columnsAdded) await getSchema(true); // the table API sees the new columns straight away
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
    });
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
            addedColumns: x.addColumns.map((c) => c.name),
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

  return { getSchema, runSync, withLock, pool };
}

module.exports = { createEngine, SyncBusyError };
