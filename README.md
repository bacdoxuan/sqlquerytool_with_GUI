# SQL Query Tool

**A hybrid PowerShell + Python toolkit** for running `.sql` queries against SQLite databases through a
Windows GUI, with automatic CSV export, execution logging, and visual performance analysis.

Current version: **v1.6.0** (2026-10-25)

## Features

### GUI (PowerShell / Windows.Forms)
- **No installer required** – a single `.ps1` script plus the bundled SQLite .NET assemblies.
- **SQL selection list** with checkboxes:
  - `Selected: x / Total: y` counter.
  - **View SQL** button, **double-click**, or **right-click** on a row opens the query in a built-in viewer.
  - **Select All** / **Unselect All**.
  - Quick filters **Select 3G queries** (`3G_*.sql`) and **Select 4G queries** (`4G_*.sql`).
  - **Load SQL Files** (multi-select) and **Clear All SQL**.
- **Embedded text viewer** (SQL files *and* the changelog):
  - Header with full path, line count and file size.
  - **Copy Content** button, `Ctrl+C` to copy, `Esc` to close, single reused window.
  - Encoding detection: UTF-8 (with/without BOM), UTF-16 LE/BE, fallback to system ANSI
    (legacy Vietnamese `.sql` files display correctly).
  - Word-wrap for `.md`/`.txt`, no-wrap with both scrollbars for `.sql`.
- **Database list** (ListView): `Check` / `ID` / `Database File` / `Status`.
  - Connection status **OK/NOK** is tested automatically when configs are loaded.
  - **Load DB Files** (`*.db`, `*.db3`) and **Clear All DB**.
- **Configuration panel**: mapping file (`.json`) and output folder.
- **Configuration management** (File menu): *Save Default Config*, *Save User Config As...*,
  *Load User Config...*, *Exit*.
- **Real-time progress**: current SQL file + database, `% / 100%`, and elapsed runtime via `Stopwatch`.
- Menus: **Analyze Log**, **Change Logs** (opens `log.md` in the built-in viewer), **About**.

### Execution engine (Python)
- Maps each `.sql` file to its database via a JSON file (key = SQL file name).
- Executes the query and writes the result set to `<query_name>.csv`.
- Appends one row per run to `LogFile/query_log.csv`.
- SQLite tuned for read-only OLAP workloads:
  `PRAGMA query_only`, `cache_size = -128000` (128 MB), `mmap_size = 10 GB`, `temp_store = MEMORY`.

### Log analysis (Python / matplotlib)
- Two synchronized panels: **latest day** and **all-time maximum** execution time per query.
- Fixed-size scrollable viewport – row pitch and bar thickness stay constant regardless of query count.
- Browse with the scrollbar, mouse wheel, `PageUp`/`PageDown`, `Home`/`End`.
- Screen-aware sizing (fits a 1366×768 laptop), zebra rows, clipped value labels,
  shared row ordering so both panels stay aligned.

## Project Structure

```text
├── config/
│   ├── sql_to_db_mapping_new.json        # SQL → DB mapping (active)
│   └── sql_to_db_mapping_new - backup.json
├── databases/                            # SQLite sample .db3 files (git-ignored)
├── sql_queries/                          # 65 .sql scripts
│   ├── 3G_*.sql                          # 18 files
│   ├── 4G_*.sql                          # 17 files
│   ├── KPI_3G_*.sql / KPI_4G_*.sql       # 29 files (daily, avg_7days, avg_30days, bad-site checks)
│   └── import.sql
├── query_results/                        # Generated CSV output (git-ignored)
├── LogFile/
│   └── query_log.csv                     # Execution log (git-ignored)
├── scripts/
│   ├── SQLQuerytool.1.6.0.ps1            # ★ current GUI
│   ├── SQLQuerytool.ps1                  # legacy v1.0-era entry point (kept for reference)
│   ├── SQLQuerytool.1.2.0 – 1.5.0.ps1    # archived GUI versions
│   ├── run_queries.py                    # query execution engine
│   ├── analyze_log.py                    # performance charts
│   ├── app_config.json                   # default config, written by the GUI (git-ignored)
│   ├── user_config.json                  # additional saved configs
│   ├── bacdx_work_config.json
│   ├── bacdx_move_db_to_D.json
│   └── lib/
│       ├── System.Data.SQLite.dll
│       └── SQLite.Interop.dll
├── log.md                                # full changelog
├── notes.md                              # PowerShell execution-policy notes
├── build exe.md                          # optional ps2exe packaging notes
└── README.md
```

## Requirements

- **Windows 10/11**
- **PowerShell 5.1+** with .NET Framework (for `System.Windows.Forms` and `System.Data.SQLite`)
- **Python 3.x** with:
  - `sqlite3` (built-in)
  - `pandas`
  - `matplotlib`
- **`PYTHON_HOME` environment variable** (User scope) pointing to the Python installation folder.
  The GUI launches `<PYTHON_HOME>\python.exe`; without it, *Run Queries* stops with
  `PYTHON_HOME is not set.`

```powershell
pip install pandas matplotlib
[Environment]::SetEnvironmentVariable("PYTHON_HOME", "C:\Python312", "User")
```

## Getting Started

1. Open PowerShell in the **`scripts`** folder (required: `app_config.json` is read from the
   current working directory):

   ```powershell
   cd .\scripts
   powershell -ExecutionPolicy Bypass -File .\SQLQuerytool.1.6.0.ps1
   ```

   If script execution is blocked, see [`notes.md`](./notes.md).

2. Load SQL files (**Load SQL Files** or from the saved config) and tick the queries to run.

3. Check the **Database Connections** list – every entry should show **OK**.

4. Select the **mapping file** and **output folder**.

5. Click **Run Queries** and follow the progress bar / current-query label.

> The database list is a configuration and health check view. The database actually used for each
> query is resolved from the **mapping file** (`run_queries.py` looks up the SQL file name).

## Mapping File Format

Keys are SQL **file names**, values are absolute database paths:

```json
{
  "3G_Utilization_Nation.sql": "D:\\DataBase\\2026_3G Site traffic Utilization_new.db3",
  "4G_Utilization_Nation.sql": "D:\\DataBase\\2026_4G site traffic Utilization_new.db3",
  "KPI_4G_Site.sql": "D:\\DataBase\\2026_4G Cell User Throughput_new.db3"
}
```

## App Config Format

Saved by *Save Default Config* / *Save User Config As...* and loaded with *Load User Config...*:

```json
{
  "db_files": ["D:\\DataBase\\db1.db3"],
  "sql_files": ["C:\\path\\to\\3G_Utilization_Nation.sql"],
  "mapping_file": "C:\\...\\config\\sql_to_db_mapping_new.json",
  "output_dir": "C:\\...\\query_results"
}
```

Only **checked** SQL and DB entries are saved.

## Output & Logs

- **Results:** `query_results/<sql_name>.csv`, UTF-8, **without a header row**
  (the header line is intentionally disabled in `run_queries.py`).
- **Log:** `LogFile/query_log.csv`, appended, UTF-8, columns:

  | datetime | sql_file | db_file | csv_file | elapsed_sec |
  |----------|----------|---------|----------|-------------|

  `datetime` has minute resolution (`YYYY-MM-DD HH:MM`).

## Log Analysis

From the GUI: **Analyze Log** (runs `analyze_log.py` with the Python on `PATH`).
It reads `LogFile/query_log.csv` and shows a horizontal bar chart with:

- **Left panel:** execution time on the most recent day present in the log.
- **Right panel:** maximum execution time across the whole log.

Queries are listed alphabetically and numbered (`1._name`), so the same row means the same query
in both panels. A query with no run on the latest day keeps its row but draws no bar.

## Version Tracker

| Version | Date       | Type  | Highlights                                                                 |
|---------|------------|-------|----------------------------------------------------------------------------|
| 1.6.0   | 2026-10-25 | Minor | Built-in SQL/changelog viewer, encoding detection, scrollable log analysis  |
| 1.5.1   | 2026-04-22 | Minor | 3G/4G quick filters, real-time progress (SQL, DB, %, runtime)              |
| 1.4.0   | 2025-06-26 | Minor | Log analysis charts (latest/max), pandas + matplotlib, performance boost   |
| 1.3.0   | 2025-06-20 | Major | GUI refactor, emoji cleanup, menu restructure, config management updates   |
| 1.2.0   | 2025-06-17 | Minor | ListView-based DB management, auto-check SQLite status                     |
| 1.1.0   | 2025-06-16 | Minor | SQL count display, CSV execution log, performance chart                    |
| 1.0.0   | 2025-06-15 | Init  | Run `.sql` on `.db` files and export to CSV                                |

_See the full changelog in [`log.md`](./log.md) (also available from the **Change Logs** menu)._

## Known Limitations

- The GUI reads/writes `app_config.json` relative to the **current working directory**, so start the
  script from the `scripts` folder.
- `.sql` files are read as **strict UTF-8** by `run_queries.py`; ANSI-encoded legacy queries may fail
  even though the built-in viewer can display them.
- One SQL statement per file (the whole file is passed to a single `cursor.execute`).
- Exported CSVs contain **no header row**; column names must be known by the consumer.
- The window is fixed at 820×680 and cannot be maximized.

## Future Enhancements

- Dark mode support
- Open/edit SQL files directly from the app (editing, not just viewing)
- Embedded data preview panel
- Multi-config / batch SQL mapping support
- Expanded DB backend support (MySQL, PostgreSQL, etc.)
- Optional CSV header row and configurable output format
