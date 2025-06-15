# SQL Query Tool – Changelog

Dự án: PowerShell GUI + Python engine để truy vấn dữ liệu từ SQLite thông qua file .sql → Xuất .csv tự động

---

## [v1.0.0] – 2025-06-15

### Tính năng chính
- Giao diện PowerShell thân thiện người dùng (UI `.ps1`)
- Chọn nhiều file `.sql`, `.db`, thư mục output và file mapping `.json`
- Tích chọn từng query SQL để chạy riêng
- Tích hợp `run_queries.py` để xử lý nội dung file `.sql` → kết nối SQLite3 → xuất `.csv`
- Mapping file (.json) ánh xạ từng query đến database tương ứng
- Progress bar hiển thị tiến độ thực tế đọc từ stdout Python
- Hỗ trợ cấu hình mặc định `app_config.json` để load tự động khi chạy
- Nút "Save Configuration" để lưu lại config cho lần chạy sau

---

## Tri thức & quyết định thiết kế

- **PowerShell** dùng `Windows.Forms` để build GUI thủ công, nhẹ, dễ đóng gói
- **Encoding**: toàn bộ chuỗi hiển thị trong GUI sử dụng tiếng Anh để tránh lỗi Unicode
- **Phân tách nhiệm vụ**:
  - `.ps1` đảm nhận UI và truyền tham số
  - `.py` đảm nhận logic xử lý dữ liệu
- Tương thích chạy offline, không cần internet
- Dễ mở rộng để:
  - Xuất log mỗi lần chạy
  - Mở file CSV tự động
  - Dashboard thống kê hoặc preview dữ liệu

---

## Ý tưởng phát triển tiếp theo
- Cho phép chọn nhiều file mapping (multi-config)
- Giao diện hỗ trợ Dark Mode
- Tự động mở file CSV đầu ra
- Tích hợp xem trước dữ liệu truy vấn trong GUI
- Tích hợp thêm nhiều loại cơ sở dữ liệu khác (mysql, sqlserver, postgre...)

---

_Được tạo bởi Copilot cùng Bắc – một người dùng kiên nhẫn, quyết đoán và có tư duy hệ thống rất rõ ràng 