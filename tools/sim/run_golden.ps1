<#
.SYNOPSIS
    Graba o verifica los golden tests de caracterizacion (sandbox aislado).

.DESCRIPTION
    ASCII puro a proposito (ver nota en run_sandboxed.ps1).

    -Mode record : graba tests/golden/data/*.json con el comportamiento ACTUAL del codigo.
                   Hacerlo solo cuando el comportamiento actual es el que se quiere congelar
                   (antes de un refactor), nunca para "arreglar" un check que falla.
    -Mode check  : compara contra lo grabado. Cualquier diferencia (valor, tipo, campo nuevo
                   o faltante) falla con un diff legible.

    Cada suite y cada escenario de trayectoria corre en su propio proceso Godot con user://
    recien borrado: ningun caso hereda estado de otro.

.EXAMPLE
    .\tools\sim\run_golden.ps1 -Mode record
    .\tools\sim\run_golden.ps1
    .\tools\sim\run_golden.ps1 -Suites save
#>
param(
    [ValidateSet("record", "check")]
    [string]$Mode = "check",
    [string[]]$Suites = @("economy", "save", "close_run", "actions", "tick", "trajectory"),
    # Rutas que se recorren dentro de la ventana: Hiper, trampa de Masa Critica (ejercita
    # close_run), Ayuno (incluye Parasitismo hibrido) y Fusion Catabolica.
    [string[]]$TrajectoryScenarios = @("fresh_hiper", "fresh_buy_all", "ng_ayuno_player", "ng_fusion_player", "ng_caos_player", "ng_coro_player", "ng_micelio_player", "ng_huesped_player"),
    [int]$TrajectorySeconds = 450,
    [string]$Instance = "golden"
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Runner = Join-Path $PSScriptRoot "run_sandboxed.ps1"
$GoldenDir = Join-Path $RepoRoot "tests\golden\data"
$script:needImport = $true
$results = @()

function Invoke-GoldenScene([string]$Label, [string[]]$SceneArgs) {
    $sceneArgsFull = @("--mode=$Mode") + $SceneArgs
    if ($Mode -eq "record") { $sceneArgsFull += "--golden-dir=$GoldenDir" }
    $params = @{
        Instance  = $Instance
        Scene     = "res://tests/golden/GoldenRunner.tscn"
        SceneArgs = $sceneArgsFull
    }
    if (-not $script:needImport) { $params.SkipImport = $true }
    $script:needImport = $false
    Write-Host ("=== {0} ===" -f $Label)
    $output = & $Runner @params 2>&1
    $code = $LASTEXITCODE
    $output | ForEach-Object { "$_" } |
        Where-Object { $_ -match '^\s*\[(OK|DIFF|REC|FALTA)\]|^\[Golden\]|^\s{5}|^---- |^\s+\d+\s+at:|SCRIPT ERROR|\[sandbox\] escena' } |
        ForEach-Object { Write-Host $_ }
    return $code
}

foreach ($suite in $Suites) {
    if ($suite -eq "trajectory") {
        foreach ($sc in $TrajectoryScenarios) {
            $code = Invoke-GoldenScene ("trajectory " + $sc) @("--suite=trajectory", "--scenario=$sc", "--t=$TrajectorySeconds")
            $results += [pscustomobject]@{ Suite = "trajectory:$sc"; Exit = $code }
        }
    } else {
        $code = Invoke-GoldenScene $suite @("--suite=$suite")
        $results += [pscustomobject]@{ Suite = $suite; Exit = $code }
    }
}

Write-Host ""
Write-Host ("Golden {0}:" -f $Mode)
$results | ForEach-Object {
    $status = "OK"
    if ($_.Exit -ne 0) { $status = "FALLA (exit " + $_.Exit + ")" }
    Write-Host ("  {0,-34} {1}" -f $_.Suite, $status)
}
$failed = @($results | Where-Object { $_.Exit -ne 0 }).Count
if ($failed -gt 0) { exit 1 }
exit 0
