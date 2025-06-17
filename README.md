# SQL Query Tool

**A hybrid PowerShell + Python toolkit** for executing `.sql` queries on SQLite databases via a user-friendly GUI, with automatic CSV export, execution logging, and visual performance analysis.

## Features

- GUI built in **PowerShell (Windows.Forms)**, lightweight and no installer needed
- Select and execute multiple `.sql` files across one or more `.db` files
- **Mapping file (.json)** to associate each SQL file with a specific database
- Auto-export results to `.csv` in selected output folder
- **Real-time progress bar** linked to Python stdout
- Save/load configuration via `app_config.json`
- Execution logs written to `LogFile/query_log.csv`
- Analyze logs with **performance charts** using Python's `matplotlib`

## Project Structure


├── config/
│   └── sql_to_db_mapping.json         # Maps .sql → .db
├── databases/                         # SQLite .db files
├── sql_queries/                       # .sql files to execute
├── query_results/                     # Output .csv files
├── LogFile/
│   └── query_log.csv                  # Execution log
├── scripts/
│   ├── SQLQuerytool.ps1              # Main GUI
│   ├── run_queries.py                # Executes SQL
│   ├── analyze_log.py                # Visualizes log performance
│   └── app_config.json               # Saved GUI settings


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

From the GUI:  
**File → Analyze Log**  
This triggers `analyze_log.py`, which reads the execution log and plots a **horizontal bar chart** showing which SQL files take the longest to execute.

## Version Tracker

| Version | Date       | Type    | Highlights                                                             |
|---------|------------|---------|------------------------------------------------------------------------|
| 1.1.0   | 2025-06-17 | Minor | SQL count display, CSV execution log, performance chart                |
| 1.0.0   | 2025-06-15 | Init  | GUI tool to run .sql on .db files and export to CSV                    |

_See full changelog in [`log.md`](./log.md)_

## Future Enhancements

- Dark Mode support
- Auto-open output .csv files after run
- Embedded data preview panel
- Multi-config / batch SQL mapping support
- Expanded DB backend support (MySQL, PostgreSQL, etc.)