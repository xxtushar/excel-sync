'use strict';
/**
 * Works out what a hard DELETE would really do. Every FK in avyra is ON DELETE CASCADE, so deleting one
 * dy_user can silently remove bookings, invoices, payments, receipts, KYC… This walks the FK graph and
 * counts the rows that would go with it, before anything is deleted.
 */

const { q } = require('../db');

const CHUNK = 1000;

async function idsReferencing(conn, childTable, column, parentIds, pk) {
  const out = [];
  for (let i = 0; i < parentIds.length; i += CHUNK) {
    const [rows] = await conn.query(`SELECT ${q(pk)} AS id FROM ${q(childTable)} WHERE ${q(column)} IN (?)`, [
      parentIds.slice(i, i + CHUNK),
    ]);
    out.push(...rows.map((r) => r.id));
  }
  return out;
}

/**
 * @returns {{ cascade: Record<string, number>, setNull: Record<string, number>, blockedBy: Record<string, number>, total: number }}
 */
async function cascadeImpact(conn, schema, tableName, ids) {
  const cascade = {};
  const setNull = {};
  const blockedBy = {};
  const visited = new Map(); // table -> Set(id)
  const queue = [[tableName, ids.map(String)]];

  while (queue.length) {
    const [tname, tids] = queue.shift();
    const t = schema.tables[tname];
    if (!t || !tids.length) continue;
    for (const child of t.children) {
      const childT = schema.tables[child.table];
      if (!childT || childT.primaryKey.length !== 1) continue;
      const found = await idsReferencing(conn, child.table, child.column, tids, childT.primaryKey[0]);
      if (!found.length) continue;
      if (child.onDelete === 'CASCADE') {
        const seen = visited.get(child.table) || new Set();
        const fresh = found.map(String).filter((x) => !seen.has(x));
        fresh.forEach((x) => seen.add(x));
        visited.set(child.table, seen);
        if (fresh.length) {
          cascade[child.table] = (cascade[child.table] || 0) + fresh.length;
          queue.push([child.table, fresh]);
        }
      } else if (child.onDelete === 'SET NULL') {
        setNull[`${child.table}.${child.column}`] = (setNull[`${child.table}.${child.column}`] || 0) + found.length;
      } else {
        blockedBy[`${child.table}.${child.column}`] = (blockedBy[`${child.table}.${child.column}`] || 0) + found.length;
      }
    }
  }
  const total = Object.values(cascade).reduce((a, b) => a + b, 0);
  const idsByTable = Object.fromEntries([...visited].map(([t, s]) => [t, [...s]]));
  return { cascade, setNull, blockedBy, total, ids: idsByTable };
}

module.exports = { cascadeImpact };
