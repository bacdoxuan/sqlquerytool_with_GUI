import sys, os, json, sqlite3, csv, time, datetime, argparse

# Thư mục log
LOG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "LogFile")
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, "query_log.csv")

start_time = time.time()

# --- Argument Parsing ---
# Script giờ sẽ nhận 3 tham số: file SQL, file mapping, và thư mục output.
parser = argparse.ArgumentParser(description="Run a single SQL query against a mapped SQLite database.")
parser.add_argument("sql_file", help="The absolute path to the .sql file to be executed.")
parser.add_argument("mapping_file", help="The absolute path to the .json mapping file.")
parser.add_argument("output_dir", help="The absolute path to the directory where results will be saved.")
args = parser.parse_args()

sql_file_path = args.sql_file
MAPPING_FILE = args.mapping_file
OUTPUT_FOLDER = os.path.abspath(args.output_dir)

sql_filename = os.path.basename(sql_file_path)
print(f"PYTHON DEBUG: Received SQL file: {sql_file_path}", flush=True)
print(f"PYTHON DEBUG: Received Mapping file: {MAPPING_FILE}", flush=True)
print(f"PYTHON DEBUG: Received Output folder: {OUTPUT_FOLDER}", flush=True)

# Đọc file mapping
try:
    with open(MAPPING_FILE, "r", encoding="utf-8") as f:
        mapping = json.load(f)
except Exception as e:
    print(f"ERROR: Cannot read mapping file: {str(e)}", flush=True)
    sys.exit(1)

if sql_filename not in mapping.keys():
    print(f"ERROR: No mapping found for {sql_filename}", flush=True)
    sys.exit(1)

db_file = mapping[sql_filename]
print(f"DEBUG: Mapped DB file: {db_file}", flush=True)

# Đọc nội dung file SQL
try:
    with open(sql_file_path, 'r', encoding='utf-8') as f:
        query = f.read()
except Exception as e:
    print(f"ERROR: Cannot read SQL file: {str(e)}", flush=True)
    sys.exit(1)

# Thực hiện query trên database
try:
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    cursor.execute(query)
    results = cursor.fetchall()
    headers = [desc[0] for desc in cursor.description]
    conn.close()
    print("DEBUG: Query executed successfully.", flush=True)
except Exception as e:
    print(f"ERROR: Query failed: {str(e)}", flush=True)
    sys.exit(1)

elapsed = round(time.time() - start_time, 3)

# Lưu kết quả ra file CSV
csv_filename = os.path.splitext(sql_filename)[0] + ".csv"
csv_path = os.path.join(OUTPUT_FOLDER, csv_filename)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

try:
    with open(csv_path, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        # writer.writerow(headers)
        writer.writerows(results)
    print(f"DEBUG: Saved results to {csv_path}", flush=True)
except Exception as e:
    print(f"ERROR: Failed to write CSV: {str(e)}", flush=True)
    sys.exit(1)

# --- Ghi log ---
log_row = [
    datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
    sql_filename,
    db_file,
    csv_filename,
    elapsed
]
log_header = ["datetime", "sql_file", "db_file", "csv_file", "elapsed_sec"]

if not os.path.exists(LOG_FILE):
    with open(LOG_FILE, "w", newline='', encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(log_header)
with open(LOG_FILE, "a", newline='', encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(log_row)

print("DONE", flush=True)
