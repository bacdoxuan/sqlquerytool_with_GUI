# SQL Query Tool – Changelog

Dự án: PowerShell GUI + Python engine để truy vấn dữ liệu từ SQLite thông qua file `.sql` → Xuất `.csv` tự động

---

## [v1.4.0] – 2025-06-26

### Nâng cấp mới
- Refactor script `analyze_log.py`:
  - Sử dụng `pandas` để xử lý `query_log.csv`
  - Hiển thị hai biểu đồ so sánh:
    - **Biểu đồ trái**: Thời gian chạy truy vấn theo từng SQL trong **ngày gần nhất**
    - **Biểu đồ phải**: Thời gian truy vấn lâu nhất cho từng SQL từ **toàn bộ log**
  - Biểu đồ hiển thị song song (subplots), có **label thời gian (giây)** trên từng thanh
  - Trục Y sắp xếp theo **tên SQL tăng dần (A → Z)**
- Tối ưu hiệu năng SQL đáng kể (một số truy vấn giảm từ >40s xuống còn 0.05s)
- Đặt nền tảng phân tích log hiệu suất cho các bản build lớn sau

---

## [v1.3.0] – 2025-06-20

### Nâng cấp mới
- Tái cấu trúc toàn bộ giao diện:
  - Nâng chiều cao vùng `SQL Queries` và tích hợp nút `"Run Queries"` ngay bên dưới danh sách SQL
  - Di chuyển `GroupBox Database` và `GroupBox Configuration` xuống thấp hơn để phù hợp bố cục
- Tái cấu trúc lại chức năng quản lý cấu hình, chuyển toàn bộ lên Menu File:
  - Save Default Config: Lưu lại cấu hình hiện tại vào file app_config.json trong thư mục scripts
  - Save User Config/Load User Config: cho phép người dùng lựa chọn save/load file cấu hình theo tên và thư mục tự chọn
- Refactor lại toàn bộ mã nguồn để tương thích PowerShell:
  - **Xoá toàn bộ emoji/ký tự đặc biệt**
  - **Sử dụng `ListView` cho database**, `CheckedListBox` cho danh sách SQL

---

## [v1.2.0] – 2025-06-17

### Nâng cấp mới
- Chuyển từ `CheckedListBox` sang `ListView` để hiển thị danh sách database SQLite với 4 cột:
  - Checkbox
  - STT
  - Tên database
  - Trạng thái kết nối (OK/NOK)
- Tự động kiểm tra trạng thái kết nối đến từng database khi load từ file cấu hình mặc định
- Thêm nút “Load DB Files” để người dùng chọn thêm database thủ công
- Thêm nút “Clear All DB” để xoá toàn bộ danh sách đang hiển thị
- Kết nối trực tiếp đến SQLite database bằng thư viện `System.Data.SQLite.dll` và `SQLite.Interop.dll`
- Cho phép cấu hình thư viện thủ công từ thư mục `scripts\lib\`
- Tăng tính ổn định khi khởi động chương trình và chuẩn bị sẵn cho modular hóa giao diện

---

## [v1.1.0] – 2025-06-16

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