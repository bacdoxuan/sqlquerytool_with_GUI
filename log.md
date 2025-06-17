# SQL Query Tool – Changelog

Dự án: PowerShell GUI + Python engine để truy vấn dữ liệu từ SQLite thông qua file `.sql` → Xuất `.csv` tự động

---

## [v1.1.0] – 2025-06-17

### Nâng cấp mới
- Hiển thị số lượng file SQL đã chọn / tổng số trên giao diện
- Cải tiến sự kiện cập nhật CheckedListBox để phản ánh chính xác số lượng khi chọn/bỏ chọn
- Ghi log quá trình chạy truy vấn vào `LogFile/query_log.csv` với thông tin:
  - Thời gian thực thi
  - Tên file SQL và database
  - File output `.csv`
- Tự động tạo thư mục `LogFile` nếu chưa tồn tại
- Thêm mục menu “Analyze Log” để gọi `analyze_log.py` đọc log và hiển thị biểu đồ phân tích hiệu suất
- Vẽ biểu đồ dạng thanh ngang (horizontal bar chart) hiển thị thời gian chạy của các SQL theo thứ tự giảm dần

---

## [v1.0.0] – 2025-06-15

### Tính năng chính
- Giao diện PowerShell thân thiện người dùng (`.ps1`)
- Chọn nhiều file `.sql`, `.db`, thư mục output và file mapping `.json`
- Tích chọn từng query SQL để chạy riêng
- Tích hợp `run_queries.py` xử lý nội dung file `.sql` → kết nối SQLite3 → xuất `.csv`
- Mapping file (`.json`) ánh xạ từng query đến database tương ứng
- Progress bar hiển thị tiến độ thực tế đọc từ stdout Python
- Hỗ trợ cấu hình mặc định `app_config.json` để load tự động khi chạy
- Nút “Save Configuration” để lưu lại config cho lần chạy sau

---

### Tri thức & quyết định thiết kế
- PowerShell dùng `Windows.Forms` để build GUI thủ công, nhẹ, dễ đóng gói
- Encoding: toàn bộ chuỗi hiển thị sử dụng tiếng Anh để tránh lỗi Unicode
- Phân tách nhiệm vụ:
  - `.ps1`: giao diện và truyền tham số
  - `.py`: xử lý logic dữ liệu
- Tương thích chạy offline, không cần internet
- Dễ mở rộng để:
  - Xuất log mỗi lần chạy
  - Mở file CSV tự động
  - Dashboard thống kê hoặc preview dữ liệu

---

## Ý tưởng phát triển tiếp theo
- Cho phép chọn nhiều file mapping (multi-config)
- Giao diện hỗ trợ Dark Mode
- Tự động mở file CSV đầu ra sau khi chạy
- Tích hợp xem trước dữ liệu truy vấn trong GUI
- Mở rộng hỗ trợ các cơ sở dữ liệu khác như MySQL, SQL Server, PostgreSQL