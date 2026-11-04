# avyra Excel upload

Checks an avyra Excel workbook and makes it ready to upload in the **admin UI**. It never connects to a database and never writes to one: the admin UI's import is the only thing that changes data.

## Setup

Requirements: Node 18.17+. No MySQL, no passwords, no `config.json`.

```bash
npm install
npm run check-upload -- avyra_N.xlsx
```

(Tip: type `npm run check-upload -- ` and drag the Excel file from Finder into the terminal.)

## What you get

It writes a new file next to yours and never changes your original:

| Result | File | Then |
|---|---|---|
| Everything checks out | `YYYY-MM-DD-avyra_N-ready-to-upload.xlsx` | Upload it in the admin UI. |
| Something is wrong | `YYYY-MM-DD-avyra_N-needs-fixes.xlsx` | Fix the red cells (each has a note), or use the links on the `_Check` sheet. Run the command again on that file. |

What it checks: every column's type and length, required columns, duplicate ids and unique values, dropdown values that exist in their static sheet (and are allowed for that column), and ids that point at another sheet in the file (a room's `pg_info` must be a PG in `dy_pg_info`). Links to tables that aren't in the file, like `pg_owner` → `dy_user`, are listed as notes; the admin UI checks those on import.

New rows get the next free id. Values typed as a plain name (`hyderabad`) or id (`198`) are rewritten as the dropdown entry (`198 – Hyderabad`). Add `--ids` if the admin UI wants plain ids in those columns instead.

Other options: `--out=file.xlsx` (choose the output name), `--json` (machine-readable result).

## Dropdowns that stay up to date

- **Automatic.** Every column with a foreign key to a static (`st_`) sheet in the file becomes a dropdown of `id – name`. A new column or static table gets a dropdown on the next run, with no code change.
- **Live in Excel.** The hidden `Lookups` sheet is formulas that read the static sheets. Add a city to `st_pg_ctys`, rename a status, or set a row's `rstatus` to 0, and every dropdown changes straight away, before you run anything. Works in all Excel versions and LibreOffice.
- **Column-specific lists are kept.** A list like `dy_pg_bed_info.bed_status` (only Vacant / Reserved / Occupied) is read from the file's Lookups sheet and kept. Add more in `COLUMN_SUBSETS` in `src/upload/liveLookups.js`.
- **Name column.** Picked automatically (the longest text column, e.g. `name` rather than `scode` in `st_pg_state`). Pin a different one in `LABEL_COLUMNS` in the same file.
- Rules and dropdowns cover the data plus 1,000 blank rows. Run the command again after adding more.

## When the database's tables change

Table definitions come from `schema/avyra.schema.json`, made from a mysqldump. When a column or table is added or changed, get a fresh dump and run:

```bash
npm run schema -- path/to/new-dump.sql
```

Commit the new JSON so everyone checks against the same definitions.

## Tests

`npm test` needs no database. It covers settings, the per-column rules, reading the schema from the dump, a clean workbook being ready, bad values being flagged on their cells, new rows getting ids, and `--ids`.

## Layout

```
scripts/check-upload.js     npm run check-upload
scripts/build-schema.js     npm run schema (dump → schema/avyra.schema.json)
schema/avyra.schema.json    table definitions the checker uses
src/upload/prepare.js       check a workbook and write the ready-to-upload / needs-fixes copy
src/upload/liveLookups.js   self-updating dropdowns: Lookups sheet formulas, auto-detected from foreign keys
src/schema/fromDump.js      table definitions from a mysqldump
src/schema/introspect.js    shared helpers (type kinds, table order)
src/excel/validation.js     per-column Excel rules (whole number, text length, date…)
src/excel/normalize.js      cell value → the shape the database stores
src/config.js, settings.js  optional settings (STATIC_PREFIX, DYNAMIC_PREFIX, IGNORE_SHEETS…)
test/                       tests + fixtures (the dump and a workbook)
```

The earlier version synced straight into MySQL. That code was removed because changes now go through the admin UI.
