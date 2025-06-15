# Nếu chạy trực tiếp file SQLQuerytool.ps1 mà lỗi
## PowerShell mặc định có thể không cho phép chạy script chưa được ký. Bạn có thể cho phép tạm thời bằng:

Set-ExecutionPolicy RemoteSigned -Scope Process

---

## Mở PowerShell với quyền Administrator nếu có, rồi chạy lệnh này:

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

---

## Các mức cho phép:
| **Chính sách**  | **Mức độ an toàn** | **Cho chạy script?** |
|-----------------|--------------------|----------------------|
| Restricted     | Rất cao           | ❌ Không           |
| AllSigned      | Cao               | ✅ (Chỉ script đã ký) |
| RemoteSigned   | Trung bình        | ✅ (Script từ internet phải được ký) |
| Bypass        | Thấp (cho dev)    | ✅ Không kiểm tra gì |


---

## Để chạy script mà không cần phải Set-ExecutionPolicy:
powershell.exe -ExecutionPolicy Bypass -File .\sqlquerytool.ps1

