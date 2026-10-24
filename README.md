# avyra-excel-sync

Keeps the `avyra` MySQL database in step with an Excel workbook, and exposes a REST API to maintain it.

- Edit the workbook and save. A watcher picks up the save, works out exactly which rows changed, and applies only those, inside one transaction.
- Or upload the workbook to `POST /api/sync` (with `POST /api/sync/preview` to see the changes first).
- Read and edit any `st_`/`dy_` table directly through `/api/tables/...`, and download the database back as a workbook with `GET /api/export`.
- Change the tables themselves: add, rename, retype or drop columns through `/api/tables/:table/columns`, or (opt-in) just add a new column header in the workbook.

Nothing about the 51 tables is hardcoded. Columns, types, keys, foreign keys and the load order are read from MySQL on every sync, so it keeps working when the schema changes.

---

## 1. Setup

Requirements: Node 18.17+ and MySQL 8+.

```bash
# 1. install
npm install
cp config.example.json config.json   # fill in DB_USER / DB_PASSWORD

# 2. load the database from the dump. No `mysql` command-line client needed.
#    If the database already has tables it does nothing; add -- --force to wipe and reload.
npm run load-dump

# 3. your working copy of the workbook, next to package.json (it is git-ignored)
cp test/fixtures/pgdump1.xlsx avyra.xlsx

# 4. check the workbook matches the database. Expect "The database already matches the workbook."
npm run sync -- avyra.xlsx --dry-run

# 5. run the API, plus the watcher on avyra.xlsx
npm start
```

Nothing is tied to one machine. `config.json` is read from the project folder, whichever directory you start the app from. `WATCH_FILE` defaults to `avyra.xlsx` in the project folder, and relative paths in it are resolved against the project folder. A full path or `~/...` also works if you keep the workbook somewhere else. If the workbook isn't there, the API still starts and tells you the watcher is off.

### Settings: `config.json`

All settings, including the database login and the API key, live in `config.json` in the project folder. It is git-ignored, so the password never reaches GitHub. `config.example.json` is the committed template with every setting at its default.

Values are typed. Write numbers and true/false without quotes:

| Setting | Type | Default | Meaning |
|---|---|---|---|
| `DB_HOST` | text | `"localhost"` | MySQL server |
| `DB_PORT` | whole number, 1–65535 | `3306` | MySQL port |
| `DB_USER` | text | `"root"` | MySQL user |
| `DB_PASSWORD` | text (may be empty) | `""` | MySQL password |
| `DB_NAME` | text | `"avyra"` | database to sync |
| `PORT` | whole number, 1–65535 | `4000` | API port |
| `API_KEY` | text (may be empty) | `""` | when set, every request needs the header `x-api-key` |
| `MAX_UPLOAD_MB` | whole number ≥ 1 | `20` | largest workbook upload |
| `PAGE_LIMIT_MAX` | whole number ≥ 1 | `500` | largest `?limit` on the table API |
| `WATCH_FILE` | text | `"avyra.xlsx"` | workbook to watch; relative to the project folder, a full path, or `~/...` |
| `WATCH_ENABLED` | true / false | `true` | run the watcher with `npm start` |
| `WATCH_DEBOUNCE_MS` | whole number ≥ 0 | `2000` | wait this long after a save before syncing |
| `WATCH_POLL` | true / false | `false` | poll instead of file events (network drives, WSL, Docker) |
| `DELETE_MODE` | `"soft"`, `"hard"` or `"none"` | `"soft"` | what happens to rows removed from a sheet (section 2) |
| `SOFT_DELETE_COLUMNS` | list of names | `["is_active", "rstatus", "active"]` | columns set to 0 by a soft delete |
| `BLANK_ID_MODE` | `"reject"` or `"insert"` | `"reject"` | rows with an empty id |
| `UNKNOWN_COLUMN_MODE` | `"warn"`, `"error"` or `"add"` | `"warn"` | sheet headers that are not columns (section 2) |
| `IGNORE_SHEETS` | list of names | `["_README"]` | sheets to skip |
| `STATIC_PREFIX` / `DYNAMIC_PREFIX` | text | `"st_"` / `"dy_"` | which tables count as static / dynamic |
| `TEST_DB_NAME` | text | `"avyra_test"` | throwaway database for `npm test` |

A wrong type, a value outside the allowed range, or a misspelled name stops startup and says exactly what to fix:

```
ConfigError: Invalid settings:
  - config.json: unknown setting "DB_PROT". Did you mean "DB_PORT"?
  - DB_PORT in config.json must be a whole number from 1 to 65535 (no quotes), got "3306".
```

Each setting is looked up in this order, first match wins: a variable set in the shell or by the host (`DB_PASSWORD=... npm start`), then `config.json`, then `.env` (still supported, see `.env.example`), then the default. `CONFIG_FILE=/path/to/other.json` uses a different file.

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
- **Extra columns** (e.g. your own notes) are ignored with a warning, unless `UNKNOWN_COLUMN_MODE=add` (below).
- Text is stored exactly as typed, including trailing spaces. The dump already contains some (e.g. `dy_user` ids 10 and 12, `last_name`).

### Each column only takes its type

Workbooks from `GET /api/export`, and any workbook you run `npm run constrain` on, carry Excel data validation built from each column's MySQL type. Excel and LibreOffice refuse a value of the wrong type as you type it, and clicking a cell shows what its column takes:

| MySQL type | The cell accepts |
|---|---|
| `int`, `tinyint`, `smallint`, `bigint`, `year`… | a whole number within the type's range (`tinyint`: −128 to 127; `int`: about ±2.1 billion; unsigned: from 0) |
| `decimal(p,s)` | a number that fits: `decimal(10,2)` is −99,999,999.99 to 99,999,999.99 |
| `float`, `double` | any number |
| `varchar(n)`, `char(n)`, `text`… | text of at most n characters |
| `enum(...)` | a dropdown of its values |
| `datetime`, `timestamp` | `2026-08-25 16:55:13`, `2026-08-25 16:55`, `2026-08-25`, or a real Excel date |
| `date` | `2026-08-25` or a real Excel date |
| `json` | text |

The note on a cell also says when the column is required, and which table an id must exist in. The rules cover the rows with data plus 1,000 blank rows below them for new rows. They don't cover whole columns, because the sync would then read a million rules per column. Excel doesn't check values that are pasted in, so the sync still checks every cell before it writes anything.

```bash
npm run constrain -- avyra.xlsx                      # add the rules in place (the original is kept as avyra.xlsx.bak)
npm run constrain -- avyra.xlsx --out=checked.xlsx   # or write a new file
```

Close the workbook in Excel or LibreOffice first. Saving the old copy from there would drop the rules again. Run it again after adding columns, or after adding more than 1,000 rows.

### Adding columns from the workbook (`UNKNOWN_COLUMN_MODE=add`)

With `"UNKNOWN_COLUMN_MODE": "add"` in `config.json`, a header that isn't a column yet becomes a new column on the next sync. Type a header such as `parking_slots` in the next free column of the sheet, fill in the rows that need a value, and save.

- The column is added as nullable, so rows left empty get NULL.
- Its type is picked from the cells: whole numbers → `int` (`bigint` if too big), numbers with up to 2 decimals → `decimal(15,2)`, other numbers → `double`, dates → `date` (or `datetime` if any has a time), TRUE/FALSE → `boolean`, anything else → `varchar(255)` (`text` if longer). Keep a column formatted as Text in Excel if it must stay text (phone numbers, codes with leading zeros).
- The preview lists every column it would add (`addColumns` per table) before anything is written.
- Headers that aren't valid column names (spaces, symbols, e.g. `My notes`) are still ignored, so you can keep your own notes columns.
- MySQL can't add a column inside a transaction. The columns are added just before the data transaction, and if that transaction fails they are dropped again, so a failed sync still changes nothing.
- Renaming, retyping and dropping columns is done through the column API, not the workbook. A sheet that is missing a column leaves that column alone.

### Excel vs the table API

Excel is the source of truth **for the sheets you change**. If you edit a row through the API and later edit that same sheet in Excel, the next sync makes the DB match Excel and your API edit is overwritten. Sheets you haven't touched since the last sync are skipped, so API edits there survive. After editing through the API, download `GET /api/export` to bring your workbook up to date.

This matters most for columns. If you rename or drop a column through the API and then edit that sheet with the old header still in it, `UNKNOWN_COLUMN_MODE=add` adds the old column back. Download a fresh export after any column change.

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
  "totals": { "columnsAdded": 0, "inserted": 0, "updated": 1, "softDeleted": 0, "hardDeleted": 0, "cascaded": 0, "tablesChanged": 1 },
  "errors": [],
  "warnings": [],
  "tables": [{
    "table": "dy_pg_info", "kind": "dynamic", "status": "changed",
    "addColumns": [],
    "counts": { "addColumns": 0, "inserts": 0, "updates": 1, "softDeletes": 0, "hardDeletes": 0, "keptMissingFromSheet": 0 },
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

### Columns

| Method & path | What it does |
|---|---|
| `GET /tables/:table/columns` | Columns with type, nullable, default, and `locked` (why it can't be changed, or `null`) |
| `POST /tables/:table/columns` | Add a column. Body: `name`, `type`, optional `nullable` (default `true`), `default`, `after` (column to put it after) |
| `PATCH /tables/:table/columns/:column` | Rename and/or redefine. Body: any of `name`, `type`, `nullable`, `default` (`null` removes the default) |
| `DELETE /tables/:table/columns/:column` | Drop the column. Add `?confirm=true` if any row has a value in it |

Types: `int`, `bigint`, `tinyint`, `smallint`, `mediumint` (optionally `unsigned`), `boolean`, `decimal(p,s)`, `float`, `double`, `varchar(n)`, `char(n)`, `text`, `tinytext`, `mediumtext`, `longtext`, `date`, `datetime`, `timestamp`, `time`, `year`, `json`.

Safety rules:

- **Locked columns:** the primary key, foreign-key columns, columns other tables reference, generated and AUTO_INCREMENT columns can't be renamed, retyped or dropped. Columns in a unique key can't be dropped.
- **Type changes check the data first.** Every stored value is converted the way the import converts it. If a value can't be stored in the new type (text into `int`, too long for `varchar(10)`), nothing changes and the response lists the rows. If a value would come out different (time of day dropped, decimals rounded, leading zero lost), the response lists `from` → `to` per row, and you repeat with `?confirm=true` to go ahead.
- **NOT NULL:** a new NOT NULL column needs a `default`, which fills the rows already there. Making an existing column NOT NULL is refused while any row has no value in it.
- A rename alone keeps everything else about the column. Changing the type, nullability or default rebuilds the definition and keeps its default, collation and comment. Columns with MySQL-managed extras (`DEFAULT CURRENT_TIMESTAMP`, `ON UPDATE …`) can only be renamed here.
- Column changes and syncs never overlap: whichever starts second gets `409` (the watcher simply retries).

```bash
curl -X POST localhost:4000/api/tables/dy_pg_info/columns -H 'content-type: application/json' \
     -d '{"name":"parking_slots","type":"int","nullable":false,"default":0,"after":"pg_landmark"}'
curl -X PATCH localhost:4000/api/tables/dy_pg_info/columns/parking_slots -H 'content-type: application/json' -d '{"name":"parking_spaces"}'
curl -X PATCH "localhost:4000/api/tables/dy_pg_events_info/columns/event_date?confirm=true" -H 'content-type: application/json' -d '{"type":"date"}'
curl -X DELETE "localhost:4000/api/tables/dy_pg_info/columns/parking_spaces?confirm=true"
```

## 4. Plugging into the backend you'll be given

```js
const { createExcelSync } = require('./excel-sync/src');

// Reuse the backend's pool. It MUST have dateStrings: true (checked at startup), and its connections must use
// UTC (SET time_zone = '+00:00'), or TIMESTAMP columns read 5h30m off on a machine set to IST.
const excelSync = await createExcelSync({ pool, database: 'avyra', auth: false /* use the backend's own auth */ });
app.use('/api/admin/excel', requireAdmin, excelSync.router);
excelSync.startWatcher();                                  // optional: watches WATCH_FILE (default avyra.xlsx in this project)
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
npm run constrain -- avyra.xlsx            # each column only accepts its type (section 2)
npm run template -- --ods                  # avyra-template.xlsx, plus avyra-template.ods with instant city search
```

The `.ods` city search is a macro: in LibreOffice set Tools → Options → Security → Macro Security → Medium, then click "Enable Macros" when you open the file.

## 6. Tests

`npm test` runs 6 unit tests (settings, cell validation) and 25 integration tests against a throwaway database (`TEST_DB_NAME`, default `avyra_test`). It is rebuilt from `test/fixtures/tusharDump.sql` before every test, so your real `avyra` DB is never touched. The DB user needs permission to create and drop that database. The tests cover:

- The untouched workbook matches the dump exactly: all 51 sheets, 2,209 rows, zero differences.
- Edits, new rows, soft deletes, the static-table protection, and idempotency.
- Dates typed several ways.
- Bad FKs, bad values and empty ids are reported and nothing is written.
- Hard deletes with cascade checks, and the mass-delete guard.
- A MySQL error rolls back the whole sync.
- Parent and child rows added in one save.
- Every API route, export → re-import being a no-op, the API key, and the file watcher reacting to a save.
- Every column of an export only accepting its type, and those rules being replaced, not duplicated, when added again.
- Adding columns from the workbook (types, preview, removed again on rollback), and the column API: add, rename, retype, drop, and every refusal.

## 7. Layout

```
src/
  settings.js               every setting: type, allowed values, default
  config.js                 settings from the environment, config.json and .env
  db.js                     mysql2 pool (dateStrings) + identifier quoting
  schema/introspect.js      columns, keys, FKs, soft-delete columns, load order (topological sort)
  schema/columns.js         allowed column types, type inference for new sheet columns, column DDL
  excel/readWorkbook.js     workbook → validated rows per table
  excel/normalize.js        cell/JSON value → MySQL shape (ints, decimals, dates, text)
  excel/validation.js       Excel data validation from each column's MySQL type
  excel/exportWorkbook.js   DB → workbook
  sync/diff.js              build the change plan + FK / cascade / mass-delete checks
  sync/cascade.js           what a hard delete would take with it
  sync/apply.js             run the plan (new columns, then parents first, deletes last)
  sync/engine.js            lock → read → diff → transaction → log
  sync/store.js             _excel_sync_state / _excel_sync_log
  sync/report.js            CLI output and API response shape
  api/syncRoutes.js         /sync, /export
  api/tableRoutes.js        /tables CRUD
  api/columnRoutes.js       /tables/:table/columns (add, rename, retype, drop)
  api/middleware.js         API key, error handling
  watcher.js                file watcher (debounced, retries while Excel is still writing)
  index.js                  createExcelSync() for embedding
  server.js                 standalone server
scripts/sync-file.js        CLI
scripts/constrain-workbook.js  add the type rules to an existing workbook
test/                       integration tests + fixtures (your dump and workbook)
```

## 8. Data quirks in the dump (loaded as-is, not fixed)

The workbook's `_README` lists 13 issues: cities mapped to the wrong state, duplicate lookup values, 197 users with a placeholder password, a duplicate user→PG mapping, and `dy_pg_guest_history.guest_info` values pointing at guests that don't exist. The sync loads the data exactly as it is. Fix them in the workbook when you're ready, and the next save applies the fixes.
