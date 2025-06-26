# SQLQueryTool_v1.3.0.ps1

Set-ExecutionPolicy RemoteSigned -Scope Process
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

# Load SQLite Assembly
Add-Type -Path "$PSScriptRoot\lib\System.Data.SQLite.dll"

# Initialize Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "SQL Query Tool v1.4.0"
$form.Size = New-Object System.Drawing.Size(820, 660)
$form.StartPosition = "CenterScreen"
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

# --- Menu About ---
$aboutMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutMenu.Text = "About"
$aboutMenu.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("SQL Query Tool v1.4.0`nAuthor: Do Xuan Bac - Vietnamobile", "About", 0, 'Information')
})

# --- Menu Change Log ---
$changeLogMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$changeLogMenu.Text = "Change Logs"
$changeLogMenu.Add_Click({
    $changeLogText = @"
Check the change log in file 'CHANGELOG.md' in the project directory.
"@
    [System.Windows.Forms.MessageBox]::Show($changeLogText, "Change Log", 0, 'Information')
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
$lblFileCount.Size = New-Object System.Drawing.Size(300, 20)
$grpSQL.Controls.Add($lblFileCount)

# CheckedListBox: SQL List
$sqlList = New-Object System.Windows.Forms.CheckedListBox
$sqlList.Location = New-Object System.Drawing.Point(10, 50)
$sqlList.Size = New-Object System.Drawing.Size(600, 200)
$sqlList.CheckOnClick = $true
$grpSQL.Controls.Add($sqlList)

# Button: Select All
$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Select All"
$btnSelectAll.Location = New-Object System.Drawing.Point(620, 110)
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
$btnUnselectAll.Location = New-Object System.Drawing.Point(620, 80)
$btnUnselectAll.Size = New-Object System.Drawing.Size(140, 25)
$btnUnselectAll.Add_Click({
    for ($i = 0; $i -lt $sqlList.Items.Count; $i++) {
        $sqlList.SetItemChecked($i, $false)
    }
    UpdateFileCount
})
$grpSQL.Controls.Add($btnUnselectAll)

# Button: Load SQL Files
$btnLoadSQL = New-Object System.Windows.Forms.Button
$btnLoadSQL.Text = "Load SQL Files"
$btnLoadSQL.Location = New-Object System.Drawing.Point(620, 50)
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
$btnClearAllSQL.Location = New-Object System.Drawing.Point(620, 140)
$btnClearAllSQL.Size = New-Object System.Drawing.Size(140, 25)
$btnClearAllSQL.Add_Click({
    $sqlList.Items.Clear()
    UpdateFileCount
})
$grpSQL.Controls.Add($btnClearAllSQL)

# Button: Run Queries
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run Queries"
$btnRun.Location = New-Object System.Drawing.Point(620, 175)
$btnRun.Size = New-Object System.Drawing.Size(140, 30)
$grpSQL.Controls.Add($btnRun)

# Function: Update file count
function UpdateFileCount {
    $selected = $sqlList.CheckedItems.Count
    $total = $sqlList.Items.Count
    $lblFileCount.Text = "Selected: $selected / Total: $total"
}
$sqlList.Add_SelectedIndexChanged({ Start-Sleep -Milliseconds 50; UpdateFileCount })

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
$form.Controls.Add($progress)

# Run Logic (Button đã nằm ở GroupBox SQL - gọi chung biến $btnRun)
$pyFile = Join-Path $PSScriptRoot "\run_queries.py"
$btnRun.Add_Click({
    $progress.Value = 0
    $selectedSQL = @()
    foreach ($sql in $sqlList.CheckedItems) { $selectedSQL += $sql }

    if ($selectedSQL.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select at least one SQL file.","Missing",0,'Warning')
        return
    }

    $perFile = 100 / $selectedSQL.Count
    $idx = 1

    foreach ($sqlFile in $selectedSQL) {
        $arg = "{0} ""{1}"" ""{2}""" -f $pyFile, $sqlFile, $txtOut.Text

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "python"
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
        $idx++
    }
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
