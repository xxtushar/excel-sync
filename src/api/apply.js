'use strict';
/**
 * Writes a plan (plan.js) to the database in ONE transaction: deletes first (children before parents), then new
 * and changed rows (parents before children). If any statement fails, everything is rolled back and the database
 * is exactly as it was.
 */

const { q } = require('../db/pool');

async function applyPlan(conn, schema, plan) {
  const done = { inserts: 0, updates: 0, deletes: 0 };
  await conn.beginTransaction();
  try {
    for (const p of [...plan.tables].reverse()) {
      if (!p.deletes.length) continue;
      const pk = schema.tables[p.table].primaryKey[0];
      const [r] = await conn.query(`DELETE FROM ${q(p.table)} WHERE ${q(pk)} IN (?)`, [p.deletes.map((x) => x.id)]);
      done.deletes += r.affectedRows;
    }
    for (const p of plan.tables) {
      const pk = schema.tables[p.table].primaryKey[0];
      for (const ins of p.inserts) {
        const cols = p.columns.filter((c) => ins.values[c] !== undefined);
        await conn.query(`INSERT INTO ${q(p.table)} (${cols.map(q).join(', ')}) VALUES (?)`, [cols.map((c) => ins.values[c])]);
        done.inserts++;
      }
      for (const up of p.updates) {
        const cols = Object.keys(up.changes);
        await conn.query(`UPDATE ${q(p.table)} SET ${cols.map((c) => `${q(c)} = ?`).join(', ')} WHERE ${q(pk)} = ?`, [...cols.map((c) => up.changes[c].to), up.id]);
        done.updates++;
      }
    }
    await conn.commit();
    return done;
  } catch (e) {
    await conn.rollback();
    throw e;
  }
}

module.exports = { applyPlan };
