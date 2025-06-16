### Bypass Scope cho current user để có thể thực hiện các lệnh Install-Module và chạy ps2exe. Nếu không sẽ gặp lỗi cấp quyền

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser

---

### Cài module chuyển đổi (chạy trong PowerShell):

Install-Module -Name ps2exe -Scope CurrentUser -Force

---

### Chuyển script .ps1 thành .exe:

ps2exe "E:\PowerShell\FileExplorerMini.ps1" "E:\PowerShell\FileExplorerMini.exe" -icon "E:\PowerShell\AppIcon.ico"

- (Icon là tuỳ chọn, nếu bạn có file .ico, thêm vào cho chuẩn Windows app 👌)

- Chạy .exe như ứng dụng bình thường!

---