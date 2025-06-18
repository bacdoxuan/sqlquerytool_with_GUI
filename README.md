# SQL Query Tool

**A hybrid PowerShell + Python toolkit** for executing `.sql` queries on SQLite databases via a user-friendly GUI, with automatic CSV export, execution logging, and visual performance analysis.

## Features

- **PowerShell GUI (Windows.Forms)** – no installer needed
- Select and execute multiple `.sql` files on one or more `.db` files
- **Database management upgrades in v1.2.0**:
  - New **ListView database selection** with 4 columns:
    - Checkbox
    - ID
    - Database Name
    - Connection Status (OK/NOK)
  - Auto-check SQLite connection upon loading configs
  - **Load DB Files**: manually select additional databases
  - **Clear All DB**: remove all entries from DB list
- **Mapping file (.json)** to associate each SQL file with a specific database
- Auto-export results to `.csv` in selected output folder
- **Execution logs** written to `LogFile/query_log.csv`
- Analyze logs via **performance charts** using Python (`matplotlib`)

 ## Project Structure
 
```bash
├── config/              # SQL → DB mapping (.json)
├── databases/           # SQLite database files (.db)
├── sql_queries/         # SQL query scripts
├── query_results/       # Output CSV files
├── LogFile/
│   └── query_log.csv    # Execution logs
├── scripts/
│   ├── SQLQuerytool.ps1 # Main GUI script
│   ├── run_queries.py   # Python execution engine
│   ├── analyze_log.py   # Performance visualization
│   ├── app_config.json  # Saved app settings
│   └── lib/             # Contains System.Data.SQLite.dll
```

## Requirements

- **Windows 10 or 11**
- **PowerShell 5.1+**
- **Python 3.x** with:
  - `sqlite3` (built-in)
  - `pandas`
  - `matplotlib`

Install Python packages with:

```bash
pip install pandas matplotlib
```

## Log Analysis

From the GUI: **File → Analyze Log**
This triggers `analyze_log.py`, which reads the execution log and plots a **horizontal bar chart** showing which SQL files take the longest to execute.

## Version Tracker

| Version | Date       | Type    | Highlights                                                             |
|---------|------------|---------|------------------------------------------------------------------------|
| 1.2.0   | 2025-06-17 | Minor | ListView-based DB management, auto-check SQLite status, GUI improvements |
| 1.1.0   | 2025-06-16 | Minor | SQL count display, CSV execution log, performance chart                |
| 1.0.0   | 2025-06-15 | Init  | GUI tool to run .sql on .db files and export to CSV                    |

_See full changelog in [`log.md`](./log.md)_

## Future Enhancements

- Dark Mode support
- Auto-open output .csv files after run
- Embedded data preview panel
- Multi-config / batch SQL mapping support
- Expanded DB backend support (MySQL, PostgreSQL, etc.)