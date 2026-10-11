<#
.SYNOPSIS
    Corre escenarios del simulador de bots en lote (sandbox aislado) y deja un reporte por escenario.

.DESCRIPTION
    ASCII puro a proposito (ver nota en run_sandboxed.ps1).
    Cada escenario corre en su propio proceso Godot con user:// del sandbox recien borrado,
    asi ningun escenario hereda estado (logros, banco) de otro.

    Salida: tests/sim/reports/<fecha>/<escenario>.json + <escenario>.txt (resumen) + index.txt

.EXAMPLE
    .\tools\sim\run_scenarios.ps1
    .\tools\sim\run_scenarios.ps1 -Scenarios fresh_active,ng_ayuno_lazy -Platform web
#>
param(
    [string[]]$Scenarios = @(),
    [string]$Platform = "desktop",
    [int]$Seed = 1337,
    [string]$Instance = "batch",
    [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Runner = Join-Path $PSScriptRoot "run_sandboxed.ps1"
if ($OutDir -eq "") {
    $OutDir = Join-Path $RepoRoot ("tests\sim\reports\" + (Get-Date -Format "yyyy-MM-dd_HHmm"))
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Lista de escenarios: la fuente de verdad es Scenarios.gd (via --list)
if ($Scenarios.Count -eq 0) {
    $listing = & $Runner -Instance $Instance -SceneArgs @("--list") 2>&1
    $Scenarios = @($listing | ForEach-Object { "$_" } | Where-Object { $_ -match '^([a-z0-9_]+)\s{2,}\S' } |
        ForEach-Object { ($_ -split '\s+')[0] })
    if ($Scenarios.Count -eq 0) {
        Write-Error "No se pudo obtener la lista de escenarios."
        exit 1
    }
}

$index = @()
$failed = 0
foreach ($sc in $Scenarios) {
    Write-Host ("=== escenario {0} ({1}) ===" -f $sc, $Platform)
    $json = Join-Path $OutDir ($sc + ".json")
    $txt = Join-Path $OutDir ($sc + ".txt")
    $sceneArgs = @("--scenario=$sc", "--seed=$Seed", "--platform=$Platform", "--out=$json")
    $output = & $Runner -Instance $Instance -SkipImport -SceneArgs $sceneArgs 2>&1
    $code = $LASTEXITCODE
    $output | ForEach-Object { "$_" } | Set-Content -Path $txt -Encoding UTF8
    $summary = @($output | ForEach-Object { "$_" } | Where-Object { $_ -match '^(Resultado|Reloj|logic tick|ui tick|click |velocidad|Ayuno|Fusi)' })
    $summary | ForEach-Object { Write-Host ("  " + $_) }
    if ($code -ne 0) { $failed++; Write-Warning "  exit $code" }
    $index += ("{0,-22} exit {1}  {2}" -f $sc, $code, (($summary | Select-Object -First 1) -join ""))
}

$index | Set-Content -Path (Join-Path $OutDir "index.txt") -Encoding UTF8
Write-Host ""
Write-Host ("Reportes en {0}  ({1} escenarios, {2} con error)" -f $OutDir, $Scenarios.Count, $failed)
if ($failed -gt 0) { exit 1 }
exit 0
