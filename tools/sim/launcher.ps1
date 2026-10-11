<#
.SYNOPSIS
    Lanzador visual del simulador y los golden tests de HYPHAE (ventana WinForms).

.DESCRIPTION
    Abrir con doble click en tools\sim\lanzador.cmd (o: powershell -ExecutionPolicy Bypass -File launcher.ps1).
    Guardado en UTF-8 CON BOM: Windows PowerShell 5.1 sólo lee bien los acentos de un .ps1 si tiene BOM.

    Cada tarea corre en un proceso PowerShell aparte que escribe su salida a un archivo; un timer
    de la ventana lo va leyendo (los eventos .NET de otros hilos no son seguros en WinForms+PS).
    Todo pasa por run_sandboxed.ps1: nunca toca saves, banco ni telemetría reales.
#>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$SimDir   = $PSScriptRoot
$RepoRoot = (Resolve-Path (Join-Path $SimDir "..\..")).Path
$LogFile  = Join-Path $env:TEMP "hyphae_launcher_run.log"
$script:proc = $null
$script:readPos = 0

# ── Escenarios: se leen de Scenarios.gd (fuente de verdad) ─────────────────────
function Get-Scenarios {
    $src = [IO.File]::ReadAllText((Join-Path $RepoRoot "tests\sim\Scenarios.gd"), [Text.Encoding]::UTF8)
    $rx = [regex]'(?m)^\t"(\w+)": \{\s*\r?\n\t\t"desc": "((?:[^"\\]|\\.)*)"'
    $list = @()
    foreach ($m in $rx.Matches($src)) {
        $list += [pscustomobject]@{ Id = $m.Groups[1].Value; Desc = $m.Groups[2].Value }
    }
    return $list
}
$scenarios = Get-Scenarios

# ── Ventana ────────────────────────────────────────────────────────────────────
$form = New-Object Windows.Forms.Form
$form.Text = "HYPHAE · Simulador y golden tests"
$form.Size = New-Object Drawing.Size(980, 720)
$form.StartPosition = "CenterScreen"
$form.BackColor = [Drawing.Color]::FromArgb(18, 22, 26)
$form.ForeColor = [Drawing.Color]::FromArgb(220, 230, 225)
$form.Font = New-Object Drawing.Font("Segoe UI", 10)

function New-Label($text, $x, $y, $w, $h, $bold = $false) {
    $l = New-Object Windows.Forms.Label
    $l.Text = $text; $l.Location = New-Object Drawing.Point($x, $y); $l.Size = New-Object Drawing.Size($w, $h)
    if ($bold) { $l.Font = New-Object Drawing.Font("Segoe UI", 11, [Drawing.FontStyle]::Bold) }
    $form.Controls.Add($l); return $l
}
function New-Button($text, $x, $y, $w, $color) {
    $b = New-Object Windows.Forms.Button
    $b.Text = $text; $b.Location = New-Object Drawing.Point($x, $y); $b.Size = New-Object Drawing.Size($w, 34)
    $b.FlatStyle = "Flat"; $b.BackColor = $color; $b.ForeColor = [Drawing.Color]::White
    $b.FlatAppearance.BorderSize = 0
    $form.Controls.Add($b); return $b
}

New-Label "SIMULACIÓN" 16 12 300 24 $true | Out-Null
New-Label "Escenario:" 16 44 80 24 | Out-Null
$cbScenario = New-Object Windows.Forms.ComboBox
$cbScenario.Location = New-Object Drawing.Point(100, 41); $cbScenario.Size = New-Object Drawing.Size(240, 26)
$cbScenario.DropDownStyle = "DropDownList"
foreach ($s in $scenarios) { [void]$cbScenario.Items.Add($s.Id) }
$form.Controls.Add($cbScenario)

New-Label "Velocidad:" 356 44 75 24 | Out-Null
$cbSpeed = New-Object Windows.Forms.ComboBox
$cbSpeed.Location = New-Object Drawing.Point(432, 41); $cbSpeed.Size = New-Object Drawing.Size(80, 26)
$cbSpeed.DropDownStyle = "DropDownList"
foreach ($v in @("1", "2", "5", "10", "20", "40", "80")) { [void]$cbSpeed.Items.Add($v + "x") }
$cbSpeed.SelectedIndex = 3
$form.Controls.Add($cbSpeed)

$lblDesc = New-Label "" 16 74 940 40
$lblDesc.ForeColor = [Drawing.Color]::FromArgb(150, 165, 160)
$cbScenario.add_SelectedIndexChanged({ $lblDesc.Text = $scenarios[$cbScenario.SelectedIndex].Desc })
if ($scenarios.Count -gt 0) { $cbScenario.SelectedIndex = 0 }

$btnVisual = New-Button "▶  Ver en ventana" 16 116 200 ([Drawing.Color]::FromArgb(40, 140, 90))
$btnFast   = New-Button "⚡  Correr rápido (reporte)" 228 116 230 ([Drawing.Color]::FromArgb(50, 90, 140))
$btnAll    = New-Button "Todos los escenarios" 470 116 190 ([Drawing.Color]::FromArgb(50, 90, 140))

New-Label "GOLDEN TESTS" 16 166 300 24 $true | Out-Null
New-Label "Suite:" 16 198 50 24 | Out-Null
$cbSuite = New-Object Windows.Forms.ComboBox
$cbSuite.Location = New-Object Drawing.Point(70, 195); $cbSuite.Size = New-Object Drawing.Size(140, 26)
$cbSuite.DropDownStyle = "DropDownList"
foreach ($v in @("todas", "economy", "save", "trajectory")) { [void]$cbSuite.Items.Add($v) }
$cbSuite.SelectedIndex = 0
$form.Controls.Add($cbSuite)
$btnCheck  = New-Button "✔  Verificar" 228 191 150 ([Drawing.Color]::FromArgb(40, 140, 90))
$btnRecord = New-Button "●  Grabar" 390 191 130 ([Drawing.Color]::FromArgb(150, 70, 50))

$chkImport = New-Object Windows.Forms.CheckBox
$chkImport.Text = "Reimportar (si agregaste scripts o assets nuevos)"
$chkImport.Location = New-Object Drawing.Point(540, 196); $chkImport.Size = New-Object Drawing.Size(420, 24)
$form.Controls.Add($chkImport)

$btnStop    = New-Button "■  Detener" 16 240 130 ([Drawing.Color]::FromArgb(110, 40, 40))
$btnReports = New-Button "Abrir reportes" 158 240 150 ([Drawing.Color]::FromArgb(60, 60, 70))
$lblStatus  = New-Label "Listo." 324 247 620 24
$btnStop.Enabled = $false

$txtLog = New-Object Windows.Forms.TextBox
$txtLog.Multiline = $true; $txtLog.ScrollBars = "Vertical"; $txtLog.ReadOnly = $true; $txtLog.WordWrap = $false
$txtLog.Location = New-Object Drawing.Point(16, 286); $txtLog.Size = New-Object Drawing.Size(932, 380)
$txtLog.Anchor = "Top, Bottom, Left, Right"
$txtLog.BackColor = [Drawing.Color]::FromArgb(8, 10, 12); $txtLog.ForeColor = [Drawing.Color]::FromArgb(170, 240, 190)
$txtLog.Font = New-Object Drawing.Font("Consolas", 9)
$form.Controls.Add($txtLog)

# ── Ejecución de tareas ────────────────────────────────────────────────────────
function Set-Busy([bool]$busy) {
    foreach ($b in @($btnVisual, $btnFast, $btnAll, $btnCheck, $btnRecord)) { $b.Enabled = -not $busy }
    $btnStop.Enabled = $busy
}

# run_sandboxed/run_golden/run_scenarios toman parámetros con nombre: se arma la llamada con splatting.
function Invoke-Script([string]$label, [string]$scriptName, [hashtable]$params) {
    $parts = @()
    foreach ($k in $params.Keys) {
        $v = $params[$k]
        if ($v -is [bool]) { if ($v) { $parts += "-$k" } }
        elseif ($v -is [array]) { $parts += "-$k @(" + (($v | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ",") + ")" }
        else { $parts += "-$k '" + ($v -replace "'", "''") + "'" }
    }
    if ($script:proc -ne $null -and -not $script:proc.HasExited) { return }
    Set-Content -Path $LogFile -Value "" -Encoding UTF8
    $script:readPos = 0
    $txtLog.Clear()
    $scriptPath = Join-Path $SimDir $scriptName
    $cmd = "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & '" + $scriptPath + "' " + ($parts -join " ") +
           " *>&1 | ForEach-Object { `"`$_`" } | Out-File -FilePath '" + $LogFile + "' -Encoding utf8 -Append; " +
           "exit `$LASTEXITCODE"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -EncodedCommand " + $encoded
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $script:proc = [Diagnostics.Process]::Start($psi)
    $lblStatus.Text = "Corriendo: " + $label
    Set-Busy $true
}

function Get-SkipImport([string]$instance) {
    if ($chkImport.Checked) { return $false }
    return (Test-Path (Join-Path $env:LOCALAPPDATA ("HyphaeSimSandbox\" + $instance + "\project\.godot")))
}

$btnVisual.add_Click({
    $sc = [string]$cbScenario.SelectedItem
    $speed = ([string]$cbSpeed.SelectedItem).TrimEnd("x")
    Invoke-Script ("ventana: " + $sc) "run_sandboxed.ps1" @{
        Instance = "visual"; Visual = $true; SkipImport = (Get-SkipImport "visual")
        Scene = "res://tests/sim/BotSimulator.tscn"
        SceneArgs = @("--visual", "--scenario=$sc", "--speed=$speed")
    }
})
$btnFast.add_Click({
    $sc = [string]$cbScenario.SelectedItem
    Invoke-Script ("escenario rápido: " + $sc) "run_scenarios.ps1" @{ Instance = "batch"; Scenarios = @($sc) }
})
$btnAll.add_Click({
    Invoke-Script "todos los escenarios" "run_scenarios.ps1" @{ Instance = "batch" }
})
function Get-SuiteParams([string]$mode) {
    $p = @{ Mode = $mode }
    $suite = [string]$cbSuite.SelectedItem
    if ($suite -ne "todas") { $p.Suites = @($suite) }
    return $p
}
$btnCheck.add_Click({ Invoke-Script "golden check" "run_golden.ps1" (Get-SuiteParams "check") })
$btnRecord.add_Click({
    $msg = "Grabar reemplaza los goldens con el comportamiento ACTUAL del código.`n`n" +
           "Hacelo sólo si el cambio de comportamiento es intencional y ya revisaste el diff de 'Verificar'.`n`n¿Grabar?"
    $r = [Windows.Forms.MessageBox]::Show($msg, "Grabar goldens", "YesNo", "Warning")
    if ($r -eq "Yes") { Invoke-Script "golden record" "run_golden.ps1" (Get-SuiteParams "record") }
})
$btnStop.add_Click({
    if ($script:proc -ne $null -and -not $script:proc.HasExited) {
        & taskkill.exe /T /F /PID $script:proc.Id | Out-Null
        $lblStatus.Text = "Detenido."
    }
})
$btnReports.add_Click({
    $dir = Join-Path $RepoRoot "tests\sim\reports"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Start-Process explorer.exe $dir
})

# ── Tail del log + fin de proceso ──────────────────────────────────────────────
$timer = New-Object Windows.Forms.Timer
$timer.Interval = 300
$timer.add_Tick({
    if (Test-Path $LogFile) {
        $fs = New-Object IO.FileStream($LogFile, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        if ($fs.Length -gt $script:readPos) {
            [void]$fs.Seek($script:readPos, [IO.SeekOrigin]::Begin)
            $sr = New-Object IO.StreamReader($fs, [Text.Encoding]::UTF8)
            $chunk = $sr.ReadToEnd()
            $script:readPos = $fs.Length
            $sr.Close()
            if ($chunk.Length -gt 0) {
                $txtLog.AppendText(($chunk -replace "`r?`n", "`r`n").TrimStart([char]0xFEFF))
            }
        } else { $fs.Close() }
    }
    if ($script:proc -ne $null -and $script:proc.HasExited -and $btnStop.Enabled) {
        $code = $script:proc.ExitCode
        $lblStatus.Text = if ($code -eq 0) { "✔ Terminó OK" } else { "✖ Terminó con errores (exit $code) — mirá el log" }
        Set-Busy $false
        if ($env:HYPHAE_LAUNCHER_SELFTEST) { $script:selftestExit = $code; $form.Close() }
    }
})
$timer.Start()

# Autoprueba (sin clicks): HYPHAE_LAUNCHER_SELFTEST=check-save abre la ventana, corre
# "Verificar" sobre la suite save y se cierra devolviendo el exit code de la tarea.
$script:selftestExit = 0
$form.add_Shown({
    if ($env:HYPHAE_LAUNCHER_SELFTEST -eq "check-save") {
        $cbSuite.SelectedItem = "save"
        $btnCheck.PerformClick()
    }
})
$form.add_FormClosing({
    if ($script:proc -ne $null -and -not $script:proc.HasExited) { & taskkill.exe /T /F /PID $script:proc.Id | Out-Null }
})
[void]$form.ShowDialog()
if ($env:HYPHAE_LAUNCHER_SELFTEST) {
    Get-Content $LogFile -Encoding UTF8 | Select-Object -Last 12
    exit $script:selftestExit
}
