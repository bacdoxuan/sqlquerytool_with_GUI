import os, csv
import matplotlib.pyplot as plt

LOG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "LogFile", "query_log.csv")

if not os.path.exists(LOG_FILE):
    print("Log file not found.")
    exit(1)

# Đọc log
data = []
with open(LOG_FILE, encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        data.append(row)

# Gom theo sql_file, lấy lần chạy lâu nhất (hoặc trung bình tuỳ ý)
from collections import defaultdict
sql_times = defaultdict(float)
for row in data:
    sql = row["sql_file"]
    t = float(row["elapsed_sec"])
    if t > sql_times[sql]:
        sql_times[sql] = t

# Sắp xếp giảm dần theo thời gian
sorted_items = sorted(sql_times.items(), key=lambda x: x[1], reverse=True)
sqls = [x[0] for x in sorted_items]
times = [x[1] for x in sorted_items]

# Vẽ biểu đồ
plt.figure(figsize=(10,6))
plt.barh(sqls, times, color="skyblue")
plt.xlabel("Elapsed time (seconds)")
plt.ylabel("SQL file")
plt.title("Query execution time (max per SQL)")
plt.gca().invert_yaxis()
plt.tight_layout()
plt.show()