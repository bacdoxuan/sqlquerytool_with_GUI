# SQLQueryTool_v1.6.0.ps1

Set-ExecutionPolicy RemoteSigned -Scope Process
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

# Load SQLite Assembly
Add-Type -Path "$PSScriptRoot\lib\System.Data.SQLite.dll"

# Initialize Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "SQL Query Tool v1.6.0"
$form.Size = New-Object System.Drawing.Size(820, 680)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Global Data Holders
$dbFiles = @()
$sqlFiles = @()
$outputFolder = ""
$mappingFile = ""

# Load default config if available
$configPath = ".\app_config.json"
if (Test-Path $configPath) {
    try {
        $cfg = Get-Content $configPath | ConvertFrom-Json
        $dbFiles = $cfg.db_files
        $sqlFiles = $cfg.sql_files
        $outputFolder = $cfg.output_dir
        $mappingFile = $cfg.mapping_file
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Cannot parse app_config.json","Config Error",0,'Error')
    }
}

# Create MenuStrip
$menuStrip = New-Object System.Windows.Forms.MenuStrip

# Menu: File
$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text = "File"

# Submenu: Save Default Config
$saveDefault = New-Object System.Windows.Forms.ToolStripMenuItem
$saveDefault.Text = "Save Default Config"
$saveDefault.Add_Click({
    Save-Config ".\app_config.json"
    [System.Windows.Forms.MessageBox]::Show("Save successful to file <app_config.json> in folder scripts","Config Saved",0,'Information')
})

# Submenu: Save User Config As...
$saveUser = New-Object System.Windows.Forms.ToolStripMenuItem
$saveUser.Text = "Save User Config As..."
$saveUser.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "JSON config (*.json)|*.json"
    $sfd.Title = "Save User Config As..."
    if ($sfd.ShowDialog() -eq "OK") {
        Save-Config $sfd.FileName
    }
})

# Submenu: Load User Config
$loadUser = New-Object System.Windows.Forms.ToolStripMenuItem
$loadUser.Text = "Load User Config..."
$loadUser.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "JSON config (*.json)|*.json"
    $ofd.Title = "Load User Config"
    if ($ofd.ShowDialog() -eq "OK") {
        Load-Config $ofd.FileName
    }
})

# Submenu: Exit
$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitItem.Text = "Exit"
$exitItem.Add_Click({ $form.Close() })

# --- Menu Analyze Log ---
$analyzeLogMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$analyzeLogMenu.Text = "Analyze Log"
$analyzeLogMenu.Add_Click({
    $pyAnalyze = Join-Path $PSScriptRoot "\analyze_log.py"
    Start-Process python $pyAnalyze
})

# --- Menu View SQL ---
# Read a text file as UTF-8 when possible, otherwise fall back to the system
# ANSI codepage (many legacy .sql files on Windows are still ANSI/1252/1258).
function Read-TextFileSmart([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    # 1) BOM-based detection
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
    }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
    }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        return [System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)
    }
    # 2) No BOM: decode as strict UTF-8, fall back to ANSI if the bytes are invalid
    try {
        $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
        return $strictUtf8.GetString($bytes)
    } catch {
        return [System.Text.Encoding]::Default.GetString($bytes)
    }
}

# Generic read-only text viewer (used for .sql files and for the change log)
function Show-TextViewer {
    param(
        [string]$Path,
        [string]$WindowTitle,
        [string]$MissingMessage = "Please select a file first."
    )
    if ([string]::IsNullOrWhiteSpace($Path)) {
        [System.Windows.Forms.MessageBox]::Show($MissingMessage,"No Selection",0,'Warning')
        return
    }
    if (-not (Test-Path $Path)) {
        [System.Windows.Forms.MessageBox]::Show("File not found:`n$Path","File Not Found",0,'Error')
        return
    }

    $sqlPath = $Path
    $v = New-Object System.Windows.Forms.Form
    if ($WindowTitle) {
        $v.Text = $WindowTitle
    } else {
        $v.Text = "SQL Viewer - " + [System.IO.Path]::GetFileName($sqlPath)
    }
    $v.Size = New-Object System.Drawing.Size(860, 560)
    $v.StartPosition = "CenterParent"
    $v.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $content = ""
    try {
        $content = Read-TextFileSmart $sqlPath
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Cannot read file:`n$($_.Exception.Message)","Read Error",0,'Error')
        $v.Dispose()
        return
    }

    # Modal dialog: ShowDialog keeps the message loop alive until the window is
    # closed, so X / ESC / Close always work. Event handlers still must not use
    # locals like $v or $content (a handler can fire later, or from another
    # scope, and would throw "The variable '$v' cannot be retrieved...");
    # they use $this (the sending control) and the form Tag instead.
    $v.Tag = $content
    $v.KeyPreview = $true
    $v.ShowInTaskbar = $false
    $v.MinimizeBox = $false

    # Single instance: close a viewer that is already open
    if ($script:sqlViewerForm -and -not $script:sqlViewerForm.IsDisposed) {
        try { $script:sqlViewerForm.Close() } catch { }
    }
    $script:sqlViewerForm = $v

    # Header: full path + size + line count
    $lines = $content -split "`r?`n"
    $info = New-Object System.Windows.Forms.Label
    $info.Text = "Path: $sqlPath   |   $($lines.Count) lines   |   $([System.IO.FileInfo]::new($sqlPath).Length.ToString('N0')) bytes"
    $info.Location = New-Object System.Drawing.Point(10, 8)
    $info.Size = New-Object System.Drawing.Size(830, 20)
    $info.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Regular)
    $info.AutoEllipsis = $true
    $v.Controls.Add($info)

    # Read-only multiline text box, monospace, with scrollbars
    # Markdown/log text reads better wrapped; .sql keeps no wrap so long queries
    # are not broken visually.
    $isMarkdown = ([System.IO.Path]::GetExtension($sqlPath) -in @('.md', '.markdown', '.txt'))
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Multiline = $true
    $tb.ReadOnly = $true
    $tb.WordWrap = $isMarkdown
    $tb.ScrollBars = if ($isMarkdown) { "Vertical" } else { "Both" }
    $tb.BackColor = [System.Drawing.Color]::White
    $tb.Font = New-Object System.Drawing.Font("Consolas", 10)
    $tb.Location = New-Object System.Drawing.Point(10, 32)
    $tb.Size = New-Object System.Drawing.Size(830, 470)
    $tb.Text = $content
    $v.Controls.Add($tb)

    # Footer buttons — handlers use $this / Tag only (see note above)
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Location = New-Object System.Drawing.Point(760, 508)
    $btnClose.Size = New-Object System.Drawing.Size(80, 28)
    # Close the OWNER form (the button's parent), not a scope variable
    $btnClose.Add_Click({ $this.Parent.Close() })
    $v.Controls.Add($btnClose)

    $btnCopy = New-Object System.Windows.Forms.Button
    $btnCopy.Text = "Copy Content"
    $btnCopy.Location = New-Object System.Drawing.Point(660, 508)
    $btnCopy.Size = New-Object System.Drawing.Size(95, 28)
    $btnCopy.Add_Click({
        try {
            [System.Windows.Forms.Clipboard]::SetText([string]$this.Parent.Tag)
            $this.Text = "Copied!"
            $this.Refresh()
            Start-Sleep -Milliseconds 700
            $this.Text = "Copy Content"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Cannot copy to clipboard: $($_.Exception.Message)","Copy Error",0,'Warning')
        }
    })
    $v.Controls.Add($btnCopy)

    # ESC or F5(close) closes the viewer; Ctrl+C copies content
    $v.Add_KeyDown({
        if ($_.KeyCode -eq 'Escape') {
            $this.Close()
        } elseif ($_.Control -and $_.KeyCode -eq 'C') {
            try { [System.Windows.Forms.Clipboard]::SetText([string]$this.Tag) } catch { }
        }
    })

    # Release the single-instance reference when closed
    $v.Add_FormClosed({
        if ($script:sqlViewerForm -eq $this) { $script:sqlViewerForm = $null }
    })

    # Modal: keeps this function alive until the viewer is closed, so the dialog
    # is always responsive and can be dismissed (X button, ESC, or Close).
    [void]$v.ShowDialog()
}

# Backwards-compatible wrapper: the SQL list / View menu still call Show-SqlViewer
function Show-SqlViewer($sqlPath) {
    Show-TextViewer -Path $sqlPath -WindowTitle $null -MissingMessage "Please select a SQL file first."
}

# Helper: SQL file to display = highlighted item, else first checked item
function Get-SqlSelection {
    if ($sqlList.SelectedItem) { return $sqlList.SelectedItem }
    foreach ($it in $sqlList.CheckedItems) { return $it }
    return $null
}


# --- Menu About ---
$aboutMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutMenu.Text = "About"
$aboutMenu.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("SQL Query Tool v1.6.0`nAuthor: Do Xuan Bac - Vietnamobile", "About", 0, 'Information')
})

# --- Menu Change Log ---
$changeLogMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$changeLogMenu.Text = "Change Logs"
$changeLogMenu.Add_Click({
    # log.md lives in the project root (one level above the scripts folder)
    $candidates = @(
        (Join-Path $PSScriptRoot "..\log.md"),
        (Join-Path $PSScriptRoot "log.md"),
        (Join-Path $PSScriptRoot "..\CHANGELOG.md"),
        (Join-Path $PSScriptRoot "CHANGELOG.md")
    )
    $logPath = $null
    foreach ($c in $candidates) {
        if (Test-Path $c) { $logPath = (Resolve-Path $c).Path; break }
    }
    if (-not $logPath) {
        [System.Windows.Forms.MessageBox]::Show("Cannot find log.md in the project directory.","Change Log",0,'Warning')
        return
    }
    Show-TextViewer -Path $logPath -WindowTitle ("Change Logs - " + [System.IO.Path]::GetFileName($logPath))
})

# Add all submenu items to File menu
$fileMenu.DropDownItems.AddRange(@($saveDefault, $saveUser, $loadUser, $exitItem))
$menuStrip.Items.Add($fileMenu)
$menuStrip.Items.Add($analyzeLogMenu)
$menuStrip.Items.Add($changeLogMenu)
$menuStrip.Items.Add($aboutMenu)

$form.MainMenuStrip = $menuStrip
$form.Controls.Add($menuStrip)

# GroupBox: SQL Queries
$grpSQL = New-Object System.Windows.Forms.GroupBox
$grpSQL.Text = "SQL Queries"
$grpSQL.Location = New-Object System.Drawing.Point(10, 35)
$grpSQL.Size = New-Object System.Drawing.Size(780, 260)
$form.Controls.Add($grpSQL)

# Label: File Count
$lblFileCount = New-Object System.Windows.Forms.Label
$lblFileCount.Location = New-Object System.Drawing.Point(10, 25)
$lblFileCount.AutoSize = $true
$lblFileCount.Text = "Selected: 0 / Total: 0"
$grpSQL.Controls.Add($lblFileCount)

# Button: View SQL (sits right next to the "Selected: x / Total: y" label)
# Prefers the highlighted row; falls back to the first checked item.
$btnViewSQL = New-Object System.Windows.Forms.Button
$btnViewSQL.Text = "View SQL"
$btnViewSQL.Location = New-Object System.Drawing.Point(200, 22)
$btnViewSQL.Size = New-Object System.Drawing.Size(95, 25)
$btnViewSQL.Add_Click({
    $target = $null
    if ($sqlList.SelectedIndex -ge 0) {
        $target = $sqlList.Items[$sqlList.SelectedIndex]
    } elseif ($sqlList.CheckedItems.Count -gt 0) {
        $target = $sqlList.CheckedItems[0]
    }
    Show-SqlViewer $target
})
$grpSQL.Controls.Add($btnViewSQL)

# CheckedListBox: SQL List
$sqlList = New-Object System.Windows.Forms.CheckedListBox
$sqlList.Location = New-Object System.Drawing.Point(10, 50)
$sqlList.Size = New-Object System.Drawing.Size(600, 200)
$sqlList.CheckOnClick = $true
$grpSQL.Controls.Add($sqlList)

# Button: Select All
$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Select All"
$btnSelectAll.Location = New-Object System.Drawing.Point(620, 85)
$btnSelectAll.Size = New-Object System.Drawing.Size(140, 25)
$btnSelectAll.Add_Click({
    for ($i = 0; $i -lt $sqlList.Items.Count; $i++) {
        $sqlList.SetItemChecked($i, $true)
    }
    UpdateFileCount
})
$grpSQL.Controls.Add($btnSelectAll)

# Button: Unselect All
$btnUnselectAll = New-Object System.Windows.Forms.Button
$btnUnselectAll.Text = "Unselect All"
$btnUnselectAll.Location = New-Object System.Drawing.Point(620, 110)
$btnUnselectAll.Size = New-Object System.Drawing.Size(140, 25)
$btnUnselectAll.Add_Click({
    for ($i = 0; $i -lt $sqlList.Items.Count; $i++) {
        $sqlList.SetItemChecked($i, $false)
    }
    UpdateFileCount
})
$grpSQL.Controls.Add($btnUnselectAll)

# Button: Select 3G
$btnSelect3G = New-Object System.Windows.Forms.Button
$btnSelect3G.Text = "Select 3G queries"
$btnSelect3G.Location = New-Object System.Drawing.Point(620, 145)
$btnSelect3G.Size = New-Object System.Drawing.Size(140, 25)
$btnSelect3G.Add_Click({
    for ($i = 0; $i -lt $sqlList.Items.Count; $i++) {
        $fileName = [System.IO.Path]::GetFileName($sqlList.Items[$i])
        if ($fileName.StartsWith("3G_")) {
            $sqlList.SetItemChecked($i, $true)
        } else {
            $sqlList.SetItemChecked($i, $false)
        }
    }
    UpdateFileCount
})
$grpSQL.Controls.Add($btnSelect3G)

# Button: Select 4G
$btnSelect4G = New-Object System.Windows.Forms.Button
$btnSelect4G.Text = "Select 4G queries"
$btnSelect4G.Location = New-Object System.Drawing.Point(620, 170)
$btnSelect4G.Size = New-Object System.Drawing.Size(140, 25)
$btnSelect4G.Add_Click({
    for ($i = 0; $i -lt $sqlList.Items.Count; $i++) {
        $fileName = [System.IO.Path]::GetFileName($sqlList.Items[$i])
        if ($fileName.StartsWith("4G_")) {
            $sqlList.SetItemChecked($i, $true)
        } else {
            $sqlList.SetItemChecked($i, $false)
        }
    }
    UpdateFileCount
})
$grpSQL.Controls.Add($btnSelect4G)

# Button: Load SQL Files
$btnLoadSQL = New-Object System.Windows.Forms.Button
$btnLoadSQL.Text = "Load SQL Files"
$btnLoadSQL.Location = New-Object System.Drawing.Point(620, 25)
$btnLoadSQL.Size = New-Object System.Drawing.Size(140, 25)
$btnLoadSQL.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "SQL Files (*.sql)|*.sql"
    $ofd.Multiselect = $true
    if ($ofd.ShowDialog() -eq "OK") {
        foreach ($file in $ofd.FileNames) {
            if (-not $sqlList.Items.Contains($file)) {
                $i = $sqlList.Items.Add($file)
                $sqlList.SetItemChecked($i, $true)
            }
        }
    }
    UpdateFileCount
})
$grpSQL.Controls.Add($btnLoadSQL)

# Button: Clear All SQL
$btnClearAllSQL = New-Object System.Windows.Forms.Button
$btnClearAllSQL.Text = "Clear All SQL"
$btnClearAllSQL.Location = New-Object System.Drawing.Point(620, 50)
$btnClearAllSQL.Size = New-Object System.Drawing.Size(140, 25)
$btnClearAllSQL.Add_Click({
    $sqlList.Items.Clear()
    UpdateFileCount
})
$grpSQL.Controls.Add($btnClearAllSQL)

# Button: Run Queries
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run Queries"
$btnRun.Location = New-Object System.Drawing.Point(620, 205)
$btnRun.Size = New-Object System.Drawing.Size(140, 30)
$grpSQL.Controls.Add($btnRun)

# Value-change watcher for the SQL list (keeps label + View SQL button in sync)

# Function: Update file count
function UpdateFileCount {
    $selected = $sqlList.CheckedItems.Count
    $total = $sqlList.Items.Count
    $lblFileCount.Text = "Selected: $selected / Total: $total"
    # Keep the View SQL button right next to the label, whatever the count width is
    if ($btnViewSQL) {
        $btnViewSQL.Left = $lblFileCount.Right + 8
        $btnViewSQL.Top = $lblFileCount.Top
    }
}
$sqlList.Add_SelectedIndexChanged({ Start-Sleep -Milliseconds 50; UpdateFileCount })
# Double-click into a SQL list item -> open the content viewer right in the GUI
$sqlList.Add_MouseDoubleClick({
    if ($sqlList.SelectedIndex -ge 0) {
        Show-SqlViewer $sqlList.SelectedItem
    }
})

# --- Right-click a SQL file = same viewer as double-click ---
# CheckedListBox does NOT move the selection on a right click, so the row under
# the cursor is resolved with IndexFromPoint on MouseDown; without that the
# viewer would open whatever row happened to be selected before.
$sqlList.Add_MouseDown({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
        $idx = $sender.IndexFromPoint($e.Location)
        if ($idx -ge 0) {
            $sender.SelectedIndex = $idx
            # Show the dialog right away, exactly like a double-click.
            Show-SqlViewer $sender.Items[$idx]
        }
    }
})

# Load SQL from config if present
if ($sqlFiles.Count -gt 0) {
    foreach ($s in $sqlFiles) {
        $i = $sqlList.Items.Add($s)
        $sqlList.SetItemChecked($i, $true)
    }
    UpdateFileCount
}

# GroupBox: Database Connections
$grpDB = New-Object System.Windows.Forms.GroupBox
$grpDB.Text = "Database Connections"
$grpDB.Location = New-Object System.Drawing.Point(10, 305)
$grpDB.Size = New-Object System.Drawing.Size(780, 140)
$form.Controls.Add($grpDB)

# ListView for DBs
$listViewDB = New-Object System.Windows.Forms.ListView
$listViewDB.Location = New-Object System.Drawing.Point(10, 25)
$listViewDB.Size = New-Object System.Drawing.Size(600, 100)
$listViewDB.View = "Details"
$listViewDB.CheckBoxes = $true
$listViewDB.FullRowSelect = $true
$listViewDB.GridLines = $true

$listViewDB.Columns.Add("Check", 60)
$listViewDB.Columns.Add("ID", 40)
$listViewDB.Columns.Add("Database File", 380)
$listViewDB.Columns.Add("Status", 100)
$grpDB.Controls.Add($listViewDB)

# Function: Test DB connection
function Test-DBConnection($dbPath) {
    if (-Not (Test-Path $dbPath)) {
        return "NOK"
    }
    try {
        $connStr = "Data Source=$dbPath;Version=3;"
        $conn = New-Object System.Data.SQLite.SQLiteConnection($connStr)
        $conn.Open()
        $conn.Close()
        return "OK"
    } catch {
        return "NOK"
    }
}

# Function: Load DB list into ListView
function Load-DBList($dbFiles) {
    $listViewDB.Items.Clear()
    $i = 1
    foreach ($db in $dbFiles) {
        $status = Test-DBConnection $db
        $item = New-Object System.Windows.Forms.ListViewItem ""
        $item.SubItems.Add($i.ToString())
        $item.SubItems.Add($db)
        $item.SubItems.Add($status)
        $item.Checked = $true
        $listViewDB.Items.Add($item)
        $i++
    }
}

# Load from config if present
if ($dbFiles -and $dbFiles.Count -gt 0) {
    Load-DBList $dbFiles
}

# Button: Load DB Files
$btnLoadDB = New-Object System.Windows.Forms.Button
$btnLoadDB.Text = "Load DB Files"
$btnLoadDB.Location = New-Object System.Drawing.Point(620, 30)
$btnLoadDB.Size = New-Object System.Drawing.Size(140, 30)
$btnLoadDB.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "SQLite (*.db;*.db3)|*.db;*.db3"
    $ofd.Multiselect = $true
    if ($ofd.ShowDialog() -eq "OK") {
        $iStart = $listViewDB.Items.Count + 1
        foreach ($file in $ofd.FileNames) {
            $status = Test-DBConnection $file
            $item = New-Object System.Windows.Forms.ListViewItem ""
            $item.SubItems.Add($iStart.ToString())
            $item.SubItems.Add($file)
            $item.SubItems.Add($status)
            $item.Checked = $true
            $listViewDB.Items.Add($item)
            $iStart++
        }
    }
})
$grpDB.Controls.Add($btnLoadDB)

# Button: Clear All DB
$btnClearDB = New-Object System.Windows.Forms.Button
$btnClearDB.Text = "Clear All DB"
$btnClearDB.Location = New-Object System.Drawing.Point(620, 70)
$btnClearDB.Size = New-Object System.Drawing.Size(140, 30)
$btnClearDB.Add_Click({
    $listViewDB.Items.Clear()
})
$grpDB.Controls.Add($btnClearDB)

# GroupBox: Configuration
$grpConfig = New-Object System.Windows.Forms.GroupBox
$grpConfig.Text = "Configuration"
$grpConfig.Location = New-Object System.Drawing.Point(10, 455)
$grpConfig.Size = New-Object System.Drawing.Size(780, 110)
$form.Controls.Add($grpConfig)

# Label: Mapping File
$lblMap = New-Object System.Windows.Forms.Label
$lblMap.Text = "Mapping file (.json):"
$lblMap.Location = New-Object System.Drawing.Point(10, 25)
$lblMap.Size = New-Object System.Drawing.Size(150, 20)
$grpConfig.Controls.Add($lblMap)

# TextBox: Mapping
$txtMap = New-Object System.Windows.Forms.TextBox
$txtMap.Location = New-Object System.Drawing.Point(160, 25)
$txtMap.Size = New-Object System.Drawing.Size(490, 25)
$txtMap.Text = $mappingFile
$txtMap.ReadOnly = $true
$grpConfig.Controls.Add($txtMap)

# Button: Browse Mapping
$btnMap = New-Object System.Windows.Forms.Button
$btnMap.Text = "Browse"
$btnMap.Location = New-Object System.Drawing.Point(660, 25)
$btnMap.Size = New-Object System.Drawing.Size(100, 25)
$btnMap.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog
    $fd.Filter = "JSON (*.json)|*.json"
    if ($fd.ShowDialog() -eq "OK") {
        $txtMap.Text = $fd.FileName
    }
})
$grpConfig.Controls.Add($btnMap)

# Label: Output Folder
$lblOut = New-Object System.Windows.Forms.Label
$lblOut.Text = "Output folder:"
$lblOut.Location = New-Object System.Drawing.Point(10, 60)
$lblOut.Size = New-Object System.Drawing.Size(150, 20)
$grpConfig.Controls.Add($lblOut)

# TextBox: Output Path
$txtOut = New-Object System.Windows.Forms.TextBox
$txtOut.Location = New-Object System.Drawing.Point(160, 60)
$txtOut.Size = New-Object System.Drawing.Size(490, 25)
$txtOut.Text = $outputFolder
$txtOut.ReadOnly = $true
$grpConfig.Controls.Add($txtOut)

# Button: Browse Output
$btnOut = New-Object System.Windows.Forms.Button
$btnOut.Text = "Browse"
$btnOut.Location = New-Object System.Drawing.Point(660, 60)
$btnOut.Size = New-Object System.Drawing.Size(100, 25)
$btnOut.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($fbd.ShowDialog() -eq "OK") {
        $txtOut.Text = $fbd.SelectedPath
    }
})
$grpConfig.Controls.Add($btnOut)

# Progress Bar
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(10, 570)
$progress.Size = New-Object System.Drawing.Size(780, 20)
$progress.Minimum = 0
$progress.Maximum = 100
$progress.Style = 'Continuous'
$form.Controls.Add($progress)

# Label: Current Query Info
$lblCurrentQuery = New-Object System.Windows.Forms.Label
$lblCurrentQuery.Location = New-Object System.Drawing.Point(10, 600)
$lblCurrentQuery.Size = New-Object System.Drawing.Size(780, 20)
$lblCurrentQuery.Text = ""
$form.Controls.Add($lblCurrentQuery)

# Label: Progress Percentage
$lblProgressPercent = New-Object System.Windows.Forms.Label
$lblProgressPercent.Location = New-Object System.Drawing.Point(10, 620)
$lblProgressPercent.Size = New-Object System.Drawing.Size(780, 20)
$lblProgressPercent.Text = ""
$form.Controls.Add($lblProgressPercent)

# Run Logic (Button đã nằm ở GroupBox SQL - gọi chung biến $btnRun)
$pyFile = Join-Path $PSScriptRoot "\run_queries.py"
$btnRun.Add_Click({
	$pythonHome = [System.Environment]::GetEnvironmentVariable("PYTHON_HOME","User")
	if (-not $pythonHome) {
		[System.Windows.Forms.MessageBox]::Show("PYTHON_HOME is not set.","Error",0,'Error')
		return
	}
    $progress.Value = 0
    $selectedSQL = @()
    foreach ($sql in $sqlList.CheckedItems) { $selectedSQL += $sql }

    if ($selectedSQL.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select at least one SQL file.","Missing",0,'Warning')
        return
    }

    # Load mapping info to display DB name
    $mapping = @{}
    if (Test-Path $txtMap.Text) {
        try {
            $mapping = Get-Content $txtMap.Text | ConvertFrom-Json -ErrorAction Stop
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Warning: Cannot read mapping file for display.","Mapping Error",0,'Warning')
        }
    }

    $perFile = 100 / $selectedSQL.Count
    $idx = 1
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    foreach ($sqlFile in $selectedSQL) {
        $sqlName = [System.IO.Path]::GetFileName($sqlFile)
        $dbPath = "Unknown"
        
        # Look up DB in mapping (mapping keys are usually filenames)
        if ($mapping.PSObject.Properties[$sqlName]) {
            $dbPath = $mapping.$sqlName
        }
        $dbName = [System.IO.Path]::GetFileName($dbPath)
        
        $lblCurrentQuery.Text = "Running: $sqlName - DB: $dbName"
        $elapsed = $sw.Elapsed.TotalSeconds.ToString("F1")
        $lblProgressPercent.Text = "Progress: $([math]::Min(100, [int](($idx-1) * $perFile)))% / 100% | Runtime: $elapsed second(s)"
        $form.Refresh()

        $arg = "{0} ""{1}"" ""{2}"" ""{3}""" -f $pyFile, $sqlFile, $txtMap.Text, $txtOut.Text

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = Join-Path $pythonHome "python.exe"
        $psi.Arguments = $arg
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($psi)
        while (-not $proc.HasExited) {
            $null = $proc.StandardOutput.ReadLine()
            Start-Sleep -Milliseconds 50
        }

        $progress.Value = [math]::Min(100, [int]($idx * $perFile))
        $elapsed = $sw.Elapsed.TotalSeconds.ToString("F1")
        $lblProgressPercent.Text = "Progress: $($progress.Value)% / 100% | Runtime: $elapsed second(s)"
        $form.Refresh()
        $idx++
    }
    $sw.Stop()
    $totalTime = $sw.Elapsed.TotalSeconds.ToString("F1")
    $lblCurrentQuery.Text = "Finished all queries in $totalTime second(s)."
    [System.Windows.Forms.MessageBox]::Show("All queries executed.","Done",0,'Information')
})

# Helper: Save Config
function Save-Config($path) {
    $checkedDBs = @()
    foreach ($i in $listViewDB.Items) {
        if ($i.Checked) { $checkedDBs += $i.SubItems[2].Text }
    }

    $checkedSQL = @()
    foreach ($s in $sqlList.CheckedItems) {
        $checkedSQL += $s
    }

    $cfg = @{
        db_files     = $checkedDBs
        sql_files    = $checkedSQL
        mapping_file = $txtMap.Text
        output_dir   = $txtOut.Text
    }
    $cfg | ConvertTo-Json -Depth 2 | Set-Content -Encoding UTF8 $path
}

# Helper: Load Config
function Load-Config($path) {
    try {
        $cfg = Get-Content $path | ConvertFrom-Json
        if (-not $cfg.sql_files -or -not $cfg.db_files) {
            throw "Invalid config"
        }

        $sqlList.Items.Clear()
        foreach ($sql in $cfg.sql_files) {
            $i = $sqlList.Items.Add($sql)
            $sqlList.SetItemChecked($i, $true)
        }

        Load-DBList $cfg.db_files
        $txtMap.Text = $cfg.mapping_file
        $txtOut.Text = $cfg.output_dir
        UpdateFileCount
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Invalid or missing config file.","Config Error",0,'Error')
    }
}

[void]$form.ShowDialog()
