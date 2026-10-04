# avyra-excel-sync

Keeps the `avyra` MySQL database in step with an Excel workbook, and exposes a REST API to maintain it.

- Edit the workbook and save. A watcher picks up the save, works out exactly which rows changed, and applies only those, inside one transaction.
- Or upload the workbook to `POST /api/sync` (with `POST /api/sync/preview` to see the changes first).
- Read and edit any `st_`/`dy_` table directly through `/api/tables/...`, and download the database back as a workbook with `GET /api/export`.

Nothing about the 51 tables is hardcoded. Columns, types, keys, foreign keys and the load order are read from MySQL on every sync, so it keeps working when the schema changes.

---

## 1. Setup

Requirements: Node 18.17+ and MySQL 8+.

```bash
# 1. install
npm install
cp .env.example .env        # fill in DB_* (and WATCH_FILE if you want auto-sync)

# 2. load the database from the dump. No `mysql` command-line client needed.
#    If the database already has tables it does nothing; add -- --force to wipe and reload.
npm run load-dump

# 3. check the workbook matches the database. Expect "The database already matches the workbook."
npm run sync -- path/to/pgdump1.xlsx --dry-run

# 4. run the API (+ watcher if WATCH_FILE is set)
npm start
```

The first run creates two bookkeeping tables, `_excel_sync_state` and `_excel_sync_log`. They don't start with `st_`/`dy_`, so the sync and the table API ignore them.

## 2. How a sync works

```
read schema from MySQL ─► read workbook ─► diff each sheet vs its table (by id) ─► validate ─► apply in ONE transaction ─► log
```

1. **Lock.** Only one sync runs at a time (MySQL `GET_LOCK`), whether it came from the watcher, an upload or the CLI.
2. **Read the workbook.** Each sheet is matched to the table with the same name, and row 1 to the column names (case doesn't matter). `_README` and sheets with no matching table are skipped. Blank rows are skipped.
3. **Skip unchanged sheets.** A hash of every sheet's data is stored after each successful sync. Sheets that haven't changed since then are not compared at all. A save that only changes formatting never touches the DB.
4. **Diff by `id`.**
   - The id is in the sheet but not the DB → **insert**.
   - The id is in both → **update** only the cells that differ.
   - The id is in the DB but not the sheet → **delete rules** (below).
5. **Validate before writing.** Every foreign key in an inserted or updated row must point at a row that will exist afterwards. Unique values (`inv_id`, `payment_id`, `receipt_id`, `univ_user_id`) must not repeat. Required columns must be filled. Problems are reported as *sheet / row / column: message*.
6. **Apply.** Inserts and updates run parents → children; deletes run children → parents. **If anything fails, everything is rolled back.** The database is never left half-synced.

### Static vs dynamic tables

| | `st_` (static, 29 tables) | `dy_` (dynamic, 22 tables) |
|---|---|---|
| New rows | inserted | inserted |
| Edited cells | updated | updated |
| Rows removed from the sheet | **never deleted** (reported as a warning) | depends on `DELETE_MODE` ↓ |

### Delete rules (`DELETE_MODE`)

**Every foreign key in avyra is `ON DELETE CASCADE`.** Hard-deleting one `dy_user` would also delete their bookings, invoices, payments, receipts, KYC and so on. So:

- **`soft` (default):** if the table has `is_active`, `rstatus` or `active`, those columns are set to `0` (`dy_user`, `dy_user_profile`, `dy_user_roles`). Tables without one keep the row and you get a warning.
- **`hard`:** soft where possible; otherwise a real `DELETE`. The preview shows exactly which child rows will cascade. If any of those child rows are still listed in their own sheets, the sync is refused. Remove them from the sheet too, or keep the parent.
- **`none`:** never delete, only report.

**Safety net:** if one sheet would remove ≥50% of a table's rows (and at least 10 rows), the sync stops. This usually means the sheet was cleared by accident. Re-run with `allowMassDelete=true` if you meant it.

### Rules for editing the workbook

- **Keep the `id` column.** For a new row, type a new id. If you leave it empty, the sync stops and suggests the next free id (e.g. "Empty id. Type an id for this new row, e.g. 786."). This stops the same row being inserted again on every save. (`BLANK_ID_MODE=insert` allows automatic ids, but then you must copy the id back into the sheet.)
- **Empty cell = NULL.**
- **Dates:** `2026-08-25 16:55:13`, `2026-08-25`, `25-08-2026 16:55` and real Excel date cells are all understood.
- **Numbers:** `10400`, `10400.00` and `10,400` are all fine for money columns. Phone numbers and KYC numbers are stored as text, so keep those cells formatted as Text in Excel.
- **Extra columns** (e.g. your own notes) are ignored with a warning.
- Text is stored exactly as typed, including trailing spaces. The dump already contains some (e.g. `dy_user` ids 10 and 12, `last_name`).

### Excel vs the table API

Excel is the source of truth **for the sheets you change**. If you edit a row through the API and later edit that same sheet in Excel, the next sync makes the DB match Excel and your API edit is overwritten. Sheets you haven't touched since the last sync are skipped, so API edits there survive. After editing through the API, download `GET /api/export` to bring your workbook up to date.

## 3. API reference

All routes are under `/api`. If `API_KEY` is set, send `x-api-key: <key>`.

### Sync

| Method & path | What it does |
|---|---|
| `POST /sync/preview` | Upload a workbook (multipart field `file`). Returns every insert, update and delete it *would* make. Writes nothing. |
| `POST /sync` | Upload and apply. `200` applied / no changes · `422` workbook has problems (nothing written) · `409` MySQL rejected a change (rolled back) or another sync is running |
| `POST /sync/watched-file` | Sync the server-side `WATCH_FILE` now (`?dryRun=true` to preview) |
| `GET /sync/status` | Watcher state, last run, delete mode |
| `GET /sync/logs` · `GET /sync/logs/:id` | Run history. One run in full includes the ids inserted, updated and removed per table. |
| `POST /sync/reset` | Forget the stored sheet hashes, so the next sync compares every sheet (`?tables=a,b` for some) |
| `GET /export` | Download the current DB as a workbook in the same layout (`?tables=a,b` for some) |

Options for the sync routes (query string or form fields): `full=true` (compare every sheet), `deleteMode=soft|hard|none`, `allowMassDelete=true`, `tables=dy_user,dy_pg_info` (only these sheets), `details=false` (counts only).

```bash
curl -F file=@avyra.xlsx http://localhost:4000/api/sync/preview
curl -F file=@avyra.xlsx http://localhost:4000/api/sync
curl -F file=@avyra.xlsx "http://localhost:4000/api/sync?deleteMode=hard"
curl -o avyra-latest.xlsx http://localhost:4000/api/export
```

Example preview response (trimmed):

```json
{
  "status": "preview",
  "message": "1 table(s) would change.",
  "totals": { "inserted": 0, "updated": 1, "softDeleted": 0, "hardDeleted": 0, "cascaded": 0, "tablesChanged": 1 },
  "errors": [],
  "warnings": [],
  "tables": [{
    "table": "dy_pg_info", "kind": "dynamic", "status": "changed",
    "counts": { "inserts": 0, "updates": 1, "softDeletes": 0, "hardDeletes": 0, "keptMissingFromSheet": 0 },
    "updates": [{ "id": 10, "row": 3, "changes": { "pg_landmark": { "from": "Near Apollo Hospital", "to": "Opp. Apollo Hospital" } } }]
  }],
  "unchangedSheets": ["st_pg_alert_priority", "..."]
}
```

Example error (nothing is written):

```json
{ "sheet": "dy_pg_events_info", "row": 2, "column": "pg_id", "message": "pg_id = 9999, but dy_pg_info has no row with id 9999." }
```

### Tables

| Method & path | What it does |
|---|---|
| `GET /tables` | All 51 tables in load order: columns, types, required flags, FKs, which tables reference it, soft-delete columns |
| `GET /tables/:table` | Rows. `?page=1&limit=50&sort=col&order=desc&search=text&excludeDeleted=true&<column>=<value>` (`<column>=null` for IS NULL) |
| `GET /tables/:table/:id` | One row |
| `GET /tables/:table/:id/impact` | What a hard delete would cascade into |
| `POST /tables/:table` | Insert (JSON body). Values go through the same checks as Excel cells. |
| `PATCH /tables/:table/:id` (or `PUT`) | Update only the columns you send |
| `DELETE /tables/:table/:id` | Soft delete. `?hard=true` for a real delete, and `&confirm=true` as well if it cascades into other rows. |

```bash
curl "localhost:4000/api/tables/st_pg_ctys?state_id=1&limit=10&sort=city"
curl -X POST localhost:4000/api/tables/dy_pg_events_info -H 'content-type: application/json' \
     -d '{"id":700,"event_date":"25-12-2026 19:00","event_title":"Christmas","pg_id":9}'
curl -X PATCH localhost:4000/api/tables/dy_pg_info/9 -H 'content-type: application/json' -d '{"pg_landmark":"Opp. Metro"}'
curl localhost:4000/api/tables/dy_pg_room_info/279/impact
# → {"hardDeleteWouldAlsoRemove":{"cascade":{"dy_pg_bed_info":2,"dy_pg_bookings":1},"total":3,...}}
```

Table and column names are checked against the live schema before they reach SQL, and every value is a bound parameter.

## 4. Plugging into the backend you'll be given

```js
const { createExcelSync } = require('./avyra-excel-sync/src');

// Reuse the backend's pool. It MUST have dateStrings: true (checked at startup).
const excelSync = await createExcelSync({ pool, database: 'avyra', auth: false /* use the backend's own auth */ });
app.use('/api/admin/excel', requireAdmin, excelSync.router);
excelSync.startWatcher({ file: process.env.WATCH_FILE }); // optional
```

Or skip the HTTP layer and call the engine directly:

```js
const result = await excelSync.engine.runSync({ source: bufferOrPath, dryRun: true });
```

The routes are written for **Express 5**, which forwards errors from async handlers by itself. If you merge this code into a backend whose `package.json` pins Express 4, add `require('express-async-errors')` at the top of the backend, or upgrade it to Express 5.

## 5. CLI

```bash
npm run sync -- avyra.xlsx --dry-run
npm run sync -- avyra.xlsx
npm run sync -- avyra.xlsx --delete-mode=hard --tables=dy_pg_events_info
npm run sync -- avyra.xlsx --full --json > result.json
```

## 6. Tests

`npm test` runs 20 integration tests against a throwaway database (`TEST_DB_NAME`, default `avyra_test`). It is rebuilt from `test/fixtures/tusharDump.sql` before every test, so your real `avyra` DB is never touched. The DB user needs permission to create and drop that database. The tests cover:

- The untouched workbook matches the dump exactly: all 51 sheets, 2,209 rows, zero differences.
- Edits, new rows, soft deletes, the static-table protection, and idempotency.
- Dates typed several ways.
- Bad FKs, bad values and empty ids are reported and nothing is written.
- Hard deletes with cascade checks, and the mass-delete guard.
- A MySQL error rolls back the whole sync.
- Parent and child rows added in one save.
- Every API route, export → re-import being a no-op, the API key, and the file watcher reacting to a save.

## 7. Layout

```
src/
  config.js                 settings from .env
  db.js                     mysql2 pool (dateStrings) + identifier quoting
  schema/introspect.js      columns, keys, FKs, soft-delete columns, load order (topological sort)
  excel/readWorkbook.js     workbook → validated rows per table
  excel/normalize.js        cell/JSON value → MySQL shape (ints, decimals, dates, text)
  excel/exportWorkbook.js   DB → workbook
  sync/diff.js              build the change plan + FK / cascade / mass-delete checks
  sync/cascade.js           what a hard delete would take with it
  sync/apply.js             run the plan (parents first, deletes last)
  sync/engine.js            lock → read → diff → transaction → log
  sync/store.js             _excel_sync_state / _excel_sync_log
  sync/report.js            CLI output and API response shape
  api/syncRoutes.js         /sync, /export
  api/tableRoutes.js        /tables CRUD
  api/middleware.js         API key, error handling
  watcher.js                file watcher (debounced, retries while Excel is still writing)
  index.js                  createExcelSync() for embedding
  server.js                 standalone server
scripts/sync-file.js        CLI
test/                       integration tests + fixtures (your dump and workbook)
```

## 8. Data quirks in the dump (loaded as-is, not fixed)

The workbook's `_README` lists 13 issues: cities mapped to the wrong state, duplicate lookup values, 197 users with a placeholder password, a duplicate user→PG mapping, and `dy_pg_guest_history.guest_info` values pointing at guests that don't exist. The sync loads the data exactly as it is. Fix them in the workbook when you're ready, and the next save applies the fixes.
