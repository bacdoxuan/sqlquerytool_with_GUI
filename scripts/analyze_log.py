import os
import matplotlib.pyplot as plt
from pandas import read_csv, errors

# Đường dẫn đến log file
LOG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "LogFile", "query_log.csv")

# Kiểm tra tồn tại
if not os.path.exists(LOG_FILE):
    print("Log file not found:", LOG_FILE)
    exit(1)

# Đọc log vào DataFrame
try:
    df = read_csv(LOG_FILE, encoding="utf-8", parse_dates=["datetime"])
except errors.ParserError as e:
    # Handle specific parsing errors with a user-friendly message
    raise ValueError(f"Failed to parse log file '{LOG_FILE}'. It may be corrupted or incorrectly formatted.") from e
except Exception as e:
    # For any other exception, re-raise it while preserving the original traceback
    # This provides more context for debugging.
    raise RuntimeError(f"Failed to read log file '{LOG_FILE}'") from e

if df.empty:
    print("Log file is empty.")
    exit(0)

# Trích xuất ngày gần nhất
df["date"] = df["datetime"].dt.date
latest_date = df["date"].max()
df_latest = df[df["date"] == latest_date]
# df_latest['sql_file'] = [".".join([str(k+1), str(v)]) for (k,v) in enumerate(df_latest['sql_file'])]

# Lấy thời gian lớn nhất cho mỗi SQL trong ngày gần nhất
df_latest_grouped =df_latest.groupby("sql_file", as_index=False)["elapsed_sec"].max().sort_values("sql_file")
df_latest_grouped['sql_file'] = ["._".join([str(k+1), str(v)]) for (k,v) in enumerate(df_latest_grouped['sql_file'])]

# Lấy thời gian lớn nhất cho mỗi SQL trong toàn bộ log
df_max_all =df.groupby("sql_file", as_index=False)["elapsed_sec"].max().sort_values("sql_file")
df_max_all['sql_file'] = ["._".join([str(k+1), str(v)]) for (k,v) in enumerate(df_max_all['sql_file'])]

# Tạo biểu đồ
# fig, axes = plt.subplots(nrows=1, ncols=2, figsize=(16, 10), sharey=True)
fig, axes = plt.subplots(nrows=1, ncols=2, sharey=True, figsize=(14, 9))

# Biểu đồ bên trái: ngày gần nhất
bars1 = axes[0].barh(df_latest_grouped["sql_file"], df_latest_grouped["elapsed_sec"], color="skyblue")
axes[0].set_title(f"{latest_date} (latest day)")
axes[0].set_xlabel("Elapsed time (s)")
axes[0].invert_yaxis()
axes[0].bar_label(bars1, fmt="%.1f", label_type="edge", padding=3)

# Biểu đồ bên phải: max toàn log
bars2 = axes[1].barh(df_max_all["sql_file"], df_max_all["elapsed_sec"], color="red")
axes[1].set_title("Max query time")
axes[1].set_xlabel("Elapsed time (s)")
axes[1].bar_label(bars2, fmt="%.1f", label_type="edge", padding=3)

plt.tight_layout()
plt.show()
