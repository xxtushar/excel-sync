'use strict';
/**
 * Executes a plan inside the caller's transaction.
 * Inserts/updates run parents → children; deletes run children → parents.
 */

const { q } = require('../db');

const CHUNK = 500;

async function applyPlan(conn, schema, plan) {
  const ordered = plan.tables
    .filter((t) => t.status === 'changed')
    .sort((a, b) => schema.tables[a.table].order - schema.tables[b.table].order);

  for (const t of ordered) {
    const pk = schema.tables[t.table].primaryKey[0];
    const at = (rowNumber, err) => {
      err.sheet = t.sheet;
      err.row = rowNumber;
      return err;
    };

    // Group inserts by column set so each group is one multi-row INSERT.
    const groups = new Map();
    for (const ins of t.inserts) {
      const cols = Object.keys(ins.values);
      const key = cols.join('\u0000');
      if (!groups.has(key)) groups.set(key, { cols, rows: [] });
      groups.get(key).rows.push(ins);
    }
    for (const { cols, rows } of groups.values()) {
      for (let i = 0; i < rows.length; i += CHUNK) {
        const batch = rows.slice(i, i + CHUNK);
        try {
          const [res] = await conn.query(`INSERT INTO ${q(t.table)} (${cols.map(q).join(', ')}) VALUES ?`, [
            batch.map((r) => cols.map((c) => r.values[c])),
          ]);
          // Rows inserted with an automatic id: report the ids MySQL assigned (consecutive within one INSERT).
          batch.forEach((r, j) => {
            if (r.id == null) r.assignedId = res.insertId + j;
          });
        } catch (e) {
          throw at(batch.length === 1 ? batch[0].rowNumber : `${batch[0].rowNumber}–${batch[batch.length - 1].rowNumber}`, e);
        }
      }
    }

    for (const u of t.updates) {
      const cols = Object.keys(u.set);
      try {
        await conn.query(`UPDATE ${q(t.table)} SET ${cols.map((c) => `${q(c)} = ?`).join(', ')} WHERE ${q(pk)} = ?`, [
          ...cols.map((c) => u.set[c]),
          u.id,
        ]);
      } catch (e) {
        throw at(u.rowNumber, e);
      }
    }
  }

  for (const t of [...ordered].reverse()) {
    const pk = schema.tables[t.table].primaryKey[0];
    if (t.softDeletes.length) {
      const cols = t.softDeletes[0].columns;
      const ids = t.softDeletes.map((d) => d.id);
      for (let i = 0; i < ids.length; i += CHUNK)
        await conn.query(`UPDATE ${q(t.table)} SET ${cols.map((c) => `${q(c)} = 0`).join(', ')} WHERE ${q(pk)} IN (?)`, [
          ids.slice(i, i + CHUNK),
        ]);
    }
    if (t.hardDeletes.length) {
      const ids = t.hardDeletes.map((d) => d.id);
      for (let i = 0; i < ids.length; i += CHUNK)
        await conn.query(`DELETE FROM ${q(t.table)} WHERE ${q(pk)} IN (?)`, [ids.slice(i, i + CHUNK)]);
    }
  }
}

/** Turn a MySQL error into a sentence a person can act on. */
function friendlyDbError(e) {
  const where = e.sheet ? `Sheet ${e.sheet}${e.row ? ` row ${e.row}` : ''}: ` : '';
  switch (e.code) {
    case 'ER_DUP_ENTRY':
      return `${where}duplicate value. ${e.sqlMessage}`;
    case 'ER_NO_REFERENCED_ROW_2':
    case 'ER_NO_REFERENCED_ROW':
      return `${where}points to a parent row that does not exist. ${e.sqlMessage}`;
    case 'ER_ROW_IS_REFERENCED_2':
      return `${where}other rows still reference this row. ${e.sqlMessage}`;
    case 'ER_DATA_TOO_LONG':
    case 'ER_TRUNCATED_WRONG_VALUE':
    case 'ER_TRUNCATED_WRONG_VALUE_FOR_FIELD':
    case 'ER_WARN_DATA_OUT_OF_RANGE':
    case 'ER_BAD_NULL_ERROR':
      return `${where}${e.sqlMessage}`;
    default:
      return `${where}${e.sqlMessage || e.message}`;
  }
}

module.exports = { applyPlan, friendlyDbError };
