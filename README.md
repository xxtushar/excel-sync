# avyra Excel upload

Two parts:

1. **Admin upload API.** The admin panel uploads an Excel file, sees exactly what would change, and confirms. Only then is anything saved to the database, in one transaction.
2. **`check-upload` command.** Checks an Excel file on your own computer and writes a ready-to-upload copy. It never connects to a database.

Both use the same checks and the same dropdowns.

## 1. Admin upload API

### How it works

```
GET  /template   → admin downloads the current data as Excel (with dropdowns)
                   … edits it …
POST /preview    → upload the file: either the problems to fix, or every change it would make + a token
POST /apply      → send the token: those exact changes are saved, all or nothing
```

`/template` and `/preview` never write anything.

### Plugging it into the backend

```js
const { createPool } = require('./avyra-excel-upload/src/db/pool');
const { createAdminUploadRouter } = require('./avyra-excel-upload/src/api/router');

const pool = createPool({ host, port, user, password, database: 'avyra' });
app.use('/api/admin/excel', requireAdmin, createAdminUploadRouter({ pool }));
```

- `requireAdmin` is the backend's own admin-login middleware. The router does no login itself.
- If the backend already has a mysql2/promise pool, it can pass that instead, as long as it was created with `dateStrings: true` and its connections use UTC (`SET time_zone = '+00:00'`). `createPool` does both.
- Options: `database` (default `DB_NAME`), `previewMinutes` (default 15), `maxUploadMb` (default 20), `layoutFile` (see "Which sheets and columns").
- The routes are written for Express 5. On Express 4, add `require('express-async-errors')` to the backend.

### Trying it on its own

```bash
npm install
cp config.example.json config.json     # fill in DB_USER, DB_PASSWORD, DB_NAME
npm start                              # http://localhost:4000/api/admin/excel
```

Set `API_KEY` in `config.json` before anyone else can reach the port. Every request then needs the header `x-api-key: <API_KEY>`.

```bash
curl -o avyra.xlsx http://localhost:4000/api/admin/excel/template
curl -F file=@avyra.xlsx http://localhost:4000/api/admin/excel/preview
curl -X POST -H 'content-type: application/json' -d '{"token":"<token from preview>"}' http://localhost:4000/api/admin/excel/apply
```

### Responses

**`POST /preview`** (multipart form, field `file`, an `.xlsx`):

| Status | `status` | Meaning |
|---|---|---|
| 200 | `preview` | The file is fine. `summary` has the counts, `tables` lists every row to add, every cell to change (`from` → `to`) and every id to delete, and `token` confirms it. |
| 200 | `no-changes` | The database already matches the file. |
| 422 | `invalid` | `errors` lists each problem with `sheet`, `cell` and a message. Nothing is saved. |
| 400 | `error` | No file, not an `.xlsx`, or too big. |

```json
{
  "status": "preview",
  "message": "0 to add, 1 to change, 3 to delete. Send the token to /apply to save.",
  "token": "q3J9…",
  "expiresAt": "2026-11-05T12:15:00.000Z",
  "summary": { "inserts": 0, "updates": 1, "deletes": 3, "tablesChanged": 2 },
  "tables": [
    { "table": "st_pg_cat", "counts": { "inserts": 0, "updates": 0, "deletes": 3 }, "inserts": [], "updates": [], "deletes": [5, 6, 7] },
    { "table": "dy_pg_info", "counts": { "inserts": 0, "updates": 1, "deletes": 0 },
      "updates": [{ "row": 3, "id": 10, "changes": { "pg_landmark": { "from": "Near Apollo Hospital", "to": "Opp. Apollo Hospital" } } }] }
  ],
  "warnings": [{ "sheet": "st_pg_cat", "message": "3 row(s) of st_pg_cat are not in the sheet and will be deleted: ids 5, 6, 7." }]
}
```

```json
{ "status": "invalid", "message": "1 problem(s) to fix. Nothing was saved.",
  "errors": [{ "sheet": "dy_pg_info", "row": 3, "column": "pg_city", "cell": "I3", "message": "pg_city \"hyderbad\" is not in the list. Pick a value from the dropdown." }] }
```

**`POST /apply`** (JSON `{ "token": "…" }`):

| Status | `status` | Meaning |
|---|---|---|
| 200 | `applied` | Saved. `summary` has what was written. |
| 410 | `expired` | The token is unknown, expired (default 15 minutes) or already used. Preview again. |
| 409 | `changed` | The database changed since the preview. Nothing saved. Preview again to see the new changes. |
| 409 | `busy` | Another upload is being saved. Try again. |
| 409 | `rejected` | MySQL refused a change. Everything was rolled back. |

**`GET /template`** returns the `.xlsx` file. The header `X-Check-Errors` is the number of problems found in the database's own data (normally 0).

### Rules

- **Only what's in the file is touched.** Only tables that are sheets in the file, and only the columns in those sheets. Other tables and columns stay as they are.
- **Rows are matched by `id`.** An id in the file but not the database is added; a changed cell is updated.
- **Deletes are safe.** A row in the database but missing from its sheet is deleted, but only if nothing else still uses it. If, say, a category is still used by a PG, the whole upload is refused with the ids that use it. The database's `ON DELETE CASCADE` never gets to remove PGs, rooms or beds.
- **Clearing a sheet by accident is caught.** If one sheet would delete half or more of its table's rows (at least 10 rows), the preview is refused. Send `allowMassDelete=true` with the preview if it's intended.
- **All checks run before saving.** These are the checks from part 2, plus ids that point at tables outside the file (e.g. `pg_owner` must exist in `dy_user`).
- **All or nothing.** Saving is one transaction: deletes first (children before parents), then adds and changes (parents first). Any error rolls everything back.
- **The preview is what gets saved.** `/apply` re-checks inside a lock. If the result differs from the preview in any way, it saves nothing.
- **Tokens live in the server's memory.** They work once and expire. If the backend runs several copies behind a load balancer, send `/preview` and `/apply` to the same one (sticky sessions), or ask for a shared token store.

### Which sheets and columns

`/template` uses the sheets and column headers of `templates/upload-template.xlsx`, which holds only header rows and no data. To give admins different tables or columns, edit that file: add or remove a sheet (named exactly like the table) or a column header. No code change is needed. Its hidden `Lookups` sheet holds column-specific dropdown lists, like `dy_pg_bed_info.bed_status` (Vacant / Reserved / Occupied).

Table definitions are read from the live database on every request, so a new column or table is picked up at once.

## 2. `check-upload` (no database)

```bash
npm install
npm run check-upload -- avyra.xlsx
```

It writes a new file next to yours and never changes the original:

| Result | File | Then |
|---|---|---|
| Everything checks out | `YYYY-MM-DD-avyra-ready-to-upload.xlsx` | Upload it. |
| Something is wrong | `YYYY-MM-DD-avyra-needs-fixes.xlsx` | Fix the red cells (each has a note), or use the links on the `_Check` sheet. Run the command again on that file. |

What it checks: every column's type and length, required columns, duplicate ids and unique values, dropdown values that exist in their static sheet (and are allowed for that column), and ids that point at another sheet in the file (a room's `pg_info` must be a PG in `dy_pg_info`).

New rows get the next free id. Values typed as a plain name (`hyderabad`) or id (`198`) are rewritten as the dropdown entry (`198 – Hyderabad`). Other options: `--ids` (plain ids instead of "id – name"), `--out=file.xlsx`, `--json`.

The command uses `schema/avyra.schema.json` for table definitions. When the database changes, refresh it from a new dump: `npm run schema -- path/to/dump.sql`.

## Dropdowns

- **Automatic.** Every column with a foreign key to a static (`st_`) sheet becomes a dropdown of `id – name`.
- **Live in Excel.** The hidden `Lookups` sheet is formulas reading the static sheets. Add a city to `st_pg_ctys` or set a row's `rstatus` to 0, and the dropdowns change straight away.
- **Work everywhere.** They're plain cell ranges, which work in Excel (Windows and Mac), LibreOffice, Numbers and Google Sheets. Each list has 50 spare slots for rows added later. Run the check again after adding more.
- **Configurable.** `COLUMN_SUBSETS` and `LABEL_COLUMNS` in `src/upload/liveLookups.js` set column-specific lists and which column is the "name".

## Settings (`config.json`)

| Setting | Default | Meaning |
|---|---|---|
| `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` | `localhost`, `3306`, `root`, empty, `avyra` | Database for the API (not used by `check-upload`) |
| `PORT` | `4000` | Standalone server port |
| `API_KEY` | empty | Standalone server: required `x-api-key` header when set |
| `MAX_UPLOAD_MB` | `20` | Largest upload |
| `PREVIEW_MINUTES` | `15` | How long a preview token is valid |
| `SOFT_DELETE_COLUMNS` | `["is_active","rstatus","active"]` | Columns meaning "switched off"; rows with 0 are left out of dropdowns |
| `IGNORE_SHEETS`, `STATIC_PREFIX`, `DYNAMIC_PREFIX` | `["_README"]`, `st_`, `dy_` | Which sheets and tables count |

Order of priority: shell variables, then `config.json`, then `.env`, then the defaults. `config.json` is git-ignored, so the password never reaches GitHub.

## Tests

```bash
npm test
```

- The checker and settings tests need no database.
- The API tests run against a throwaway database (`TEST_DB_NAME`, default `avyra_test`), rebuilt from `test/fixtures/tusharDump.sql` before each test, using the login in `config.json`. They never touch `DB_NAME`, and refuse to run if `TEST_DB_NAME` equals it. Without a reachable MySQL they're skipped.
- What they cover: template → preview shows no changes; edits, a new row and the three "Boys PG" deletes previewed and saved exactly; a delete still in use refused; file problems reported by cell; links to `dy_user` checked; mass-delete guard; database changed between preview and apply; rollback on a database error; bad files.

## Layout

```
src/api/router.js           the admin upload API (template, preview, apply)
src/api/plan.js             compare a checked file with the database; safe-delete and link checks
src/api/apply.js            save a plan in one transaction
src/api/template.js         current data → the Excel file admins edit
src/api/server.js           standalone server (npm start)
src/db/pool.js              MySQL pool (dateStrings, UTC)
src/db/introspect.js        table definitions from the live database
templates/upload-template.xlsx  which sheets and columns admins get
src/upload/prepare.js       the checks + dropdowns + ready-to-upload / needs-fixes file
src/upload/liveLookups.js   self-updating dropdowns
src/schema/fromDump.js      table definitions from a mysqldump (for check-upload)
src/excel/validation.js     per-column Excel rules
src/excel/normalize.js      cell value ↔ database value
scripts/check-upload.js     npm run check-upload
scripts/build-schema.js     npm run schema
test/                       tests + fixtures
```
