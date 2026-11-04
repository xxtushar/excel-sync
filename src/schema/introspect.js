'use strict';
/**
 * Schema helpers shared by fromDump.js: the kind of each MySQL column type, and a load order
 * (parents before children).
 */

const INTEGER_TYPES = new Set(['tinyint', 'smallint', 'mediumint', 'int', 'integer', 'bigint', 'year']);
const FLOAT_TYPES = new Set(['float', 'double', 'real']);
const DECIMAL_TYPES = new Set(['decimal', 'numeric']);
const DATETIME_TYPES = new Set(['datetime', 'timestamp']);
const DATE_TYPES = new Set(['date']);
const TIME_TYPES = new Set(['time']);

function kindOf(dataType) {
  if (INTEGER_TYPES.has(dataType)) return 'integer';
  if (FLOAT_TYPES.has(dataType)) return 'float';
  if (DECIMAL_TYPES.has(dataType)) return 'decimal';
  if (DATETIME_TYPES.has(dataType)) return 'datetime';
  if (DATE_TYPES.has(dataType)) return 'date';
  if (TIME_TYPES.has(dataType)) return 'time';
  if (dataType === 'json') return 'json';
  if (dataType === 'bit') return 'integer';
  return 'string';
}

/**
 * Kahn topological sort over FK edges (parent -> child). Ties are broken static-first, then by name,
 * so the order is stable. Self references are ignored; real cycles are reported.
 */
function loadOrder(tables) {
  const names = Object.keys(tables);
  const indeg = Object.fromEntries(names.map((n) => [n, 0]));
  const edges = Object.fromEntries(names.map((n) => [n, new Set()]));
  for (const t of Object.values(tables)) {
    for (const fk of t.foreignKeys) {
      if (fk.refTable === t.name || !tables[fk.refTable]) continue;
      if (!edges[fk.refTable].has(t.name)) {
        edges[fk.refTable].add(t.name);
        indeg[t.name]++;
      }
    }
  }
  const rank = (n) => (tables[n].kind === 'static' ? '0' : '1') + n;
  const ready = names.filter((n) => indeg[n] === 0).sort((a, b) => rank(a).localeCompare(rank(b)));
  const order = [];
  while (ready.length) {
    const n = ready.shift();
    order.push(n);
    for (const c of edges[n]) {
      if (--indeg[c] === 0) {
        ready.push(c);
        ready.sort((a, b) => rank(a).localeCompare(rank(b)));
      }
    }
  }
  const cyclic = names.filter((n) => !order.includes(n));
  return { order: order.concat(cyclic.sort()), cyclic };
}

module.exports = { loadOrder, kindOf };
