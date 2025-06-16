# Set-ExecutionPolicy RemoteSigned -Scope Process
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

# --- Initialize Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "SQL Query Tool"
$form.Size = New-Object System.Drawing.Size(800,600)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI",10)

# --- Global Data Holders ---
$dbFiles = @()
$sqlFiles = @()
$outputFolder = ""
$mappingFile = ""

# Load default config if available
$configPath = ".\app_config.json"
if (Test-Path $configPath) {
    $cfg = Get-Content $configPath | ConvertFrom-Json
    $dbFiles = $cfg.db_files
    $sqlFiles = $cfg.sql_files
    $outputFolder = $cfg.output_dir
    $mappingFile = $cfg.mapping_file
}

# Tạo MenuStrip
$menuStrip = New-Object System.Windows.Forms.MenuStrip

# --- Menu File ---
$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text = "File"

# Thêm mục con: Exit
$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitItem.Text = "Exit"
$exitItem.Add_Click({
    $form.Close()
})
$fileMenu.DropDownItems.Add($exitItem)

# --- Menu Analyze Log ---
$analyzeLogMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$analyzeLogMenu.Text = "Analyze Log"
$analyzeLogMenu.Add_Click({
    $pyAnalyze = Join-Path $PSScriptRoot "\analyze_log.py"
    Start-Process python $pyAnalyze
})

# --- Menu About ---
$aboutMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutMenu.Text = "About"
$aboutMenu.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("SQL Query Tool v1.0`nAuthor: Do Xuan Bac - Vietnamobile", "About", 0, 'Information')
})

# --- Menu Change Log ---
$changeLogMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$changeLogMenu.Text = "Change Log"
$changeLogMenu.Add_Click({
    $changeLogText = @"
Version 1.0:
- Create GUI for daily progressing data
- Mutli select sql file
- Mutil select db file
- Mapping sql - db
- Select output folder
- Save configuration for faster loading next time
- Progress bar
"@
    [System.Windows.Forms.MessageBox]::Show($changeLogText, "Change Log", 0, 'Information')
})

# Thêm các menu vào MenuStrip 
$menuStrip.Items.Add($fileMenu)
$menuStrip.Items.Add($analyzeLogMenu)
$menuStrip.Items.Add($aboutMenu)
$menuStrip.Items.Add($changeLogMenu)

# Gán MenuStrip cho Form
$form.MainMenuStrip = $menuStrip
$form.Controls.Add($menuStrip)

# --- Label: SQL Files ---
$lblSql = New-Object System.Windows.Forms.Label
$lblSql.Text = "Select SQL queries:"
$lblSql.Location = New-Object System.Drawing.Point(20,30)
$lblSql.Size = New-Object System.Drawing.Size(130,25)
$form.Controls.Add($lblSql)

# --- Label hiển thị số file được chọn / tổng số file ---
$lblFileCount = New-Object System.Windows.Forms.Label
$lblFileCount.Location = New-Object System.Drawing.Point(160,30)
$lblFileCount.Size = New-Object System.Drawing.Size(160,25)
$form.Controls.Add($lblFileCount)

# --- CheckedListBox for SQL List ---
$sqlList = New-Object System.Windows.Forms.CheckedListBox
$sqlList.Location = New-Object System.Drawing.Point(20,55)
$sqlList.Size = New-Object System.Drawing.Size(740,120)
$sqlList.CheckOnClick = $true
$form.Controls.Add($sqlList)

# Nếu có cấu hình mặc định đã load ở trước ($sqlFiles), thêm vào danh sách
if ($sqlFiles.Count -gt 0) {
    foreach ($s in $sqlFiles) {
        $i = $sqlList.Items.Add($s)
        $sqlList.SetItemChecked($i, $true)
    }
}

# --- Hàm cập nhật số lượng file đã chọn / tổng file ---
function UpdateFileCount {
    $selectedCount = ($sqlList.CheckedItems.Count)
    $totalCount = ($sqlList.Items.Count)
    $lblFileCount.Text = "Selected: $selectedCount / Total: $totalCount"
}

# Cập nhật số lượng file ngay khi form khởi động
UpdateFileCount{}

# --- Cập nhật số lượng khi có sự thay đổi trong danh sách ---
$sqlList.Add_SelectedIndexChanged({
    Start-Sleep -Milliseconds 50  # Cho phép danh sách cập nhật trước khi lấy số lượng chính xác
    UpdateFileCount{}
})

# --- Button: Select All in SQL List ---
$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Select All"
$btnSelectAll.Location = New-Object System.Drawing.Point(540, 30)
$btnSelectAll.Size = New-Object System.Drawing.Size(100, 25)
$form.Controls.Add($btnSelectAll)
$btnSelectAll.Add_Click({
    for ($i = 0; $i -lt $sqlList.Items.Count; $i++) {
        $sqlList.SetItemChecked($i, $true)
    }
    UpdateFileCount{}
})

# --- Button: Unselect All in SQL List ---
$btnUnselectAll = New-Object System.Windows.Forms.Button
$btnUnselectAll.Text = "Unselect All"
$btnUnselectAll.Location = New-Object System.Drawing.Point(430, 30)
$btnUnselectAll.Size = New-Object System.Drawing.Size(100, 25)
$form.Controls.Add($btnUnselectAll)
$btnUnselectAll.Add_Click({
    for ($i = 0; $i -lt $sqlList.Items.Count; $i++) {
        $sqlList.SetItemChecked($i, $false)
    }
    UpdateFileCount{}
})

# --- Button: Clear All SQL List ---
$btnClearAllSQL = New-Object System.Windows.Forms.Button
$btnClearAllSQL.Text = "Clear All SQL"
$btnClearAllSQL.Location = New-Object System.Drawing.Point(320, 30)
$btnClearAllSQL.Size = New-Object System.Drawing.Size(100,25)
$form.Controls.Add($btnClearAllSQL)
$btnClearAllSQL.Add_Click({
    $sqlList.Items.Clear()
    UpdateFileCount{}
})

# --- Load SQL Files ---
$btnLoadSQL = New-Object System.Windows.Forms.Button
$btnLoadSQL.Text = "Load SQL Files"
$btnLoadSQL.Location = New-Object System.Drawing.Point(650,30)
$btnLoadSQL.Size = New-Object System.Drawing.Size(110,25)
$form.Controls.Add($btnLoadSQL)
$btnLoadSQL.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "SQL Files (*.sql)|*.sql"
    $ofd.Multiselect = $true
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        foreach ($file in $ofd.FileNames) {
            $i = $sqlList.Items.Add($file)
            $sqlList.SetItemChecked($i, $true)
        }
    }
    UpdateFileCount{}
})

# --- Label: Database Files ---
$lblDb = New-Object System.Windows.Forms.Label
$lblDb.Text = "Select SQLite databases:"
$lblDb.Location = New-Object System.Drawing.Point(20,180)
$lblDb.Size = New-Object System.Drawing.Size(200,25)
$form.Controls.Add($lblDb)

# --- Button: Load Database Files ---
$btnLoadDB = New-Object System.Windows.Forms.Button
$btnLoadDB.Text = "Load DB Files"
$btnLoadDB.Location = New-Object System.Drawing.Point(650,180)
$btnLoadDB.Size = New-Object System.Drawing.Size(110,25)
$form.Controls.Add($btnLoadDB)
$btnLoadDB.Add_Click({
    $ofdDB = New-Object System.Windows.Forms.OpenFileDialog
    # Chỉ hiển thị các file có đuôi .sql và .sql3
    $ofdDB.Filter = "SQLite Database Files (*.db;*.db3)|*.db;*.db3"
    $ofdDB.Multiselect = $true
    if ($ofdDB.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        foreach ($file in $ofdDB.FileNames) {
            $i = $dbList.Items.Add($file)
            $dbList.SetItemChecked($i, $true)
        }
    }
})

# --- Button: Clear All Database List ---
$btnClearAllDB = New-Object System.Windows.Forms.Button
$btnClearAllDB.Text = "Clear All DB"
$btnClearAllDB.Location = New-Object System.Drawing.Point(540 ,180)  # Điều chỉnh vị trí theo ý muốn
$btnClearAllDB.Size = New-Object System.Drawing.Size(100,25)
$form.Controls.Add($btnClearAllDB)
$btnClearAllDB.Add_Click({
    $dbList.Items.Clear()
})

# --- CheckedListBox for Database Files ---
$dbList = New-Object System.Windows.Forms.CheckedListBox
$dbList.Location = New-Object System.Drawing.Point(20,205)
$dbList.Size = New-Object System.Drawing.Size(740,100)
$dbList.CheckOnClick = $true
$form.Controls.Add($dbList)

if ($dbFiles.Count -gt 0) {
    foreach ($d in $dbFiles) {
        $i = $dbList.Items.Add($d)
        $dbList.SetItemChecked($i, $true)
    }
}

# --- Mapping File Label ---
$lblMap = New-Object System.Windows.Forms.Label
$lblMap.Text = "Mapping file (.json):"
$lblMap.Location = New-Object System.Drawing.Point(20,320)
$lblMap.Size = New-Object System.Drawing.Size(200,25)
$form.Controls.Add($lblMap)

# --- TextBox for Mapping File ---
$txtMap = New-Object System.Windows.Forms.TextBox
$txtMap.Location = New-Object System.Drawing.Point(20,345)
$txtMap.Size = New-Object System.Drawing.Size(600,25)
$txtMap.Text = $mappingFile
$form.Controls.Add($txtMap)

# --- Button: Browse Mapping File ---
$btnMap = New-Object System.Windows.Forms.Button
$btnMap.Text = "Browse"
$btnMap.Location = New-Object System.Drawing.Point(640,345)
$btnMap.Size = New-Object System.Drawing.Size(100,25)
$form.Controls.Add($btnMap)
$btnMap.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog
    $fd.Filter = "JSON Mapping (*.json)|*.json"
    if ($fd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtMap.Text = $fd.FileName
    }
})

# --- Output Folder Label ---
$lblOut = New-Object System.Windows.Forms.Label
$lblOut.Text = "Output folder:"
$lblOut.Location = New-Object System.Drawing.Point(20,380)
$lblOut.Size = New-Object System.Drawing.Size(200,25)
$form.Controls.Add($lblOut)

# --- TextBox for Output Folder ---
$txtOut = New-Object System.Windows.Forms.TextBox
$txtOut.Location = New-Object System.Drawing.Point(20,405)
$txtOut.Size = New-Object System.Drawing.Size(600,25)
$txtOut.Text = $outputFolder
$form.Controls.Add($txtOut)

# --- Button: Browse Output Folder ---
$btnOut = New-Object System.Windows.Forms.Button
$btnOut.Text = "Browse"
$btnOut.Location = New-Object System.Drawing.Point(640,405)
$btnOut.Size = New-Object System.Drawing.Size(100,25)
$form.Controls.Add($btnOut)
$btnOut.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtOut.Text = $fbd.SelectedPath
    }
})

# --- Progress Bar ---
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(20,440)
$progress.Size = New-Object System.Drawing.Size(740,20)
$progress.Minimum = 0
$progress.Maximum = 100
$form.Controls.Add($progress)

# --- Run Button ---
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run Selected Queries"
$btnRun.Location = New-Object System.Drawing.Point(20,475)
$btnRun.Size = New-Object System.Drawing.Size(250,30)
$form.Controls.Add($btnRun)

# --- Save Config Button ---
$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Save Configuration"
$btnSave.Location = New-Object System.Drawing.Point(290,475)
$btnSave.Size = New-Object System.Drawing.Size(250,30)
$form.Controls.Add($btnSave)

# --- Run Queries Event (Phiên bản đơn giản hoá) ---
# Xác định đường dẫn tuyệt đối đến file run_queries.py nằm trong thư mục scripts
$pyFile = Join-Path $PSScriptRoot "\run_queries.py"

$btnRun.Add_Click({
    # Đặt lại progress bar
    $progress.Value = 0

    # Thu thập danh sách các file SQL được tick trong CheckedListBox
    $selectedSQL = @()
    foreach ($sql in $sqlList.CheckedItems) {
        $selectedSQL += $sql
    }

    if ($selectedSQL.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select at least one SQL file.", "Missing", 0, 'Warning')
        return
    }

    # Tính phần trăm cho mỗi file (100% chia đều cho số file)
    $perFilePercent = 100 / $selectedSQL.Count
    $fileIndex = 1

    # Lặp qua từng file SQL và gọi Python cho mỗi file
    foreach ($sqlFile in $selectedSQL) {
        # Xây dựng chuỗi đối số:
        #   Tham số 1: đường dẫn file SQL
        #   Tham số 2: thư mục output (lấy từ TextBox của GUI)
        $argument = "{0} ""{1}"" ""{2}""" -f $pyFile, $sqlFile, $txtOut.Text
        Write-Host "POWER SHELL DEBUG: Running Python with argument: $argument"

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "python"   # Đảm bảo lệnh 'python' có trong PATH
        $psi.Arguments = $argument
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        # Có thể hiển thị cửa sổ cmd để debug, sau này có thể đặt lại CreateNoWindow = $true
        $psi.CreateNoWindow = $false

        $proc = [System.Diagnostics.Process]::Start($psi)
        
        # Đọc output từ Python (dùng để debug, không ảnh hưởng đến progress bar)
        $output = ""
        while (-not $proc.HasExited) {
            $line = $proc.StandardOutput.ReadLine()
            if ($line) {
                $output += $line + "`n"
                Write-Host "PYTHON OUTPUT:" $line -ForegroundColor Blue
            }
            Start-Sleep -Milliseconds 50
        }
        Write-Host "Python process for $sqlFile exited." -ForegroundColor Green

        # Sau khi xử lý xong file, cập nhật progress bar
		$progress.Value = $fileIndex * $perFilePercent
        $fileIndex++
        # Đảm bảo progress không vượt quá 100%
        if ($progress.Value -gt 100) {
            $progress.Value = 100
        }
    }

    [System.Windows.Forms.MessageBox]::Show("All queries processed.", "Done", 0, 'Information')
})

# --- Save Configuration Event ---
$btnSave.Add_Click({
    $cfg = @{
        db_files     = @($dbList.Items)
        sql_files    = @($sqlList.Items)
        mapping_file = $txtMap.Text
        output_dir   = $txtOut.Text
    }
    $cfg | ConvertTo-Json -Depth 2 | Set-Content -Encoding UTF8 ".\app_config.json"
    [System.Windows.Forms.MessageBox]::Show("Configuration saved.","Saved",0,'Information')
})

[void]$form.ShowDialog()