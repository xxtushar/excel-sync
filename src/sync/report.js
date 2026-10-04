'use strict';
/** Human-readable output for the CLI and the watcher, plus a compact JSON shape for the API. */

function loc(e) {
  return [e.sheet, e.row && `row ${e.row}`, e.column].filter(Boolean).join(' / ');
}

function printResult(r, log = console) {
  log.log(`[excel-sync] ${r.status.toUpperCase()} (${r.trigger}, ${r.source}, ${r.durationMs ?? '?'} ms): ${r.message || ''}`);
  for (const t of r.tables.filter((x) => x.status === 'changed')) {
    const parts = [];
    if (t.inserts.length) parts.push(`+${t.inserts.length} inserted`);
    if (t.updates.length) parts.push(`~${t.updates.length} updated`);
    if (t.softDeletes.length) parts.push(`-${t.softDeletes.length} soft-deleted`);
    if (t.hardDeletes.length) parts.push(`-${t.hardDeletes.length} deleted (+${t.cascade?.total || 0} cascaded)`);
    log.log(`  ${t.table.padEnd(26)} ${parts.join(', ')}`);
  }
  for (const e of r.errors.slice(0, 50)) log.log(`  ERROR   ${loc(e)}: ${e.message}`);
  if (r.errors.length > 50) log.log(`  …and ${r.errors.length - 50} more errors`);
  for (const w of r.warnings.slice(0, 20)) log.log(`  warning ${loc(w)}: ${w.message}`);
  if (r.warnings.length > 20) log.log(`  …and ${r.warnings.length - 20} more warnings`);
}

/**
 * API response. With details=false only counts per table; with details=true every insert/update/delete,
 * capped per table so a huge change set does not produce a huge response.
 */
function toResponse(r, { details = true, cap = 200 } = {}) {
  const tables = r.tables
    .filter((t) => t.status === 'changed' || t.status === 'invalid')
    .map((t) => {
      const base = {
        table: t.table,
        sheet: t.sheet,
        kind: t.kind,
        status: t.status,
        sheetRows: t.sheetRows,
        dbRows: t.dbRows,
        counts: {
          inserts: t.inserts.length,
          updates: t.updates.length,
          softDeletes: t.softDeletes.length,
          hardDeletes: t.hardDeletes.length,
          keptMissingFromSheet: t.notDeleted.length,
        },
      };
      if (t.cascade && t.cascade.total) base.cascade = t.cascade;
      if (!details) return base;
      const c = (arr) => (arr.length > cap ? { items: arr.slice(0, cap), truncated: arr.length - cap } : arr);
      return {
        ...base,
        inserts: c(t.inserts.map((i) => ({ id: i.id ?? i.assignedId ?? null, row: i.rowNumber, values: i.values }))),
        updates: c(t.updates.map((u) => ({ id: u.id, row: u.rowNumber, changes: Object.fromEntries(Object.keys(u.set).map((k) => [k, { from: u.before[k], to: u.set[k] }])) }))),
        softDeletes: c(t.softDeletes.map((d) => d.id)),
        hardDeletes: c(t.hardDeletes.map((d) => d.id)),
        keptMissingFromSheet: c(t.notDeleted),
      };
    });
  // 'unchanged' = sheet identical to the last successful sync (skipped); 'no-changes' = compared, already matches.
  const unchanged = r.tables.filter((t) => t.status === 'unchanged' || t.status === 'no-changes').map((t) => t.table);
  return {
    status: r.status,
    message: r.message,
    dryRun: r.dryRun,
    trigger: r.trigger,
    source: r.source,
    deleteMode: r.deleteMode,
    durationMs: r.durationMs,
    logId: r.logId ?? null,
    totals: r.totals,
    errors: r.errors,
    warnings: r.warnings,
    tables,
    unchangedSheets: unchanged,
  };
}

module.exports = { printResult, toResponse };
