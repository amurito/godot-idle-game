<#
.SYNOPSIS
    Ejecuta una escena de test/simulacion de HYPHAE en un SANDBOX aislado.

.DESCRIPTION
    NOTA: este archivo es ASCII puro a proposito. Windows PowerShell 5.1 lee los .ps1 sin BOM
    como ANSI (cp1252) y caracteres UTF-8 como el guion largo contienen bytes que cp1252
    interpreta como comillas tipograficas, rompiendo el parseo.

    Seguridad por construccion: copia el proyecto a un directorio sandbox y renombra
    application/config/name en el project.godot de la copia. Godot deriva user:// del nombre
    del proyecto, asi que la escena corre con un user:// propio y NUNCA puede leer ni escribir
    los saves, el banco de legado, la meta de slots, los settings ni la telemetria del jugador.

    Pasos:
      1. robocopy del repo al sandbox (sin builds/, docs/, .git, .godot, etc.)
      2. Parcheo de config/name en el project.godot de la copia
      3. Borrado del user:// del sandbox (estado limpio y determinista) salvo -KeepUserData
      4. godot --headless --import (registra class_name nuevos e importa assets) salvo -SkipImport
      5. godot --headless --path <sandbox> <Scene> -- <SceneArgs>

    Codigos de salida: el de la escena (0 = OK, 1 = fallas, 2 = guard aborto), 10+ = error del runner.

.EXAMPLE
    .\tools\sim\run_sandboxed.ps1 -Scene res://tests/sim/BotSimulator.tscn -SceneArgs @("--scenario=fresh_active")
#>
param(
    [string]$Scene = "res://tests/sim/BotSimulator.tscn",
    [string[]]$SceneArgs = @(),
    [string]$Godot = "C:\Users\nicol\Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe",
    # Instancias independientes (copia + user:// propios) permiten correr en paralelo.
    [ValidatePattern('^[A-Za-z0-9_]+$')]
    [string]$Instance = "default",
    [string]$SandboxRoot = "",
    [switch]$KeepUserData,
    [switch]$SkipImport,
    [int]$TimeoutSec = 3600
)

$ErrorActionPreference = "Stop"
# SimGuard exige que user:// contenga HYPHAE_SIM_SANDBOX; el sufijo separa instancias.
$SANDBOX_NAME = "HYPHAE_SIM_SANDBOX_" + $Instance
if ($SandboxRoot -eq "") {
    $SandboxRoot = Join-Path (Join-Path $env:LOCALAPPDATA "HyphaeSimSandbox") $Instance
}

# --- Resolucion de paths ---------------------------------------------------
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$SandboxProject = Join-Path $SandboxRoot "project"
$SandboxUserDir = Join-Path $env:APPDATA ("Godot\app_userdata\" + $SANDBOX_NAME)

if (-not (Test-Path $Godot)) {
    Write-Error "No se encontro Godot en '$Godot'. Pasa -Godot <ruta al _console.exe>."
    exit 10
}
if (-not (Test-Path (Join-Path $RepoRoot "project.godot"))) {
    Write-Error "RepoRoot '$RepoRoot' no contiene project.godot."
    exit 11
}

# --- Guardas: el sandbox jamas puede solaparse con el repo ni con datos reales ---
$repoFull = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\') + '\'
$sbFull = [System.IO.Path]::GetFullPath($SandboxProject).TrimEnd('\') + '\'
if ($sbFull.StartsWith($repoFull, [StringComparison]::OrdinalIgnoreCase) -or
    $repoFull.StartsWith($sbFull, [StringComparison]::OrdinalIgnoreCase)) {
    Write-Error "El sandbox ($sbFull) se solapa con el repo ($repoFull). Abortado."
    exit 12
}
if (-not $SandboxUserDir.EndsWith($SANDBOX_NAME)) {
    Write-Error "user:// del sandbox inesperado: $SandboxUserDir. Abortado."
    exit 13
}

# --- 1. Copia selectiva ----------------------------------------------------
New-Item -ItemType Directory -Force -Path $SandboxProject | Out-Null
$excludeDirs = @(".git", ".claude", ".godot", "builds", "docs", "screens para subir", "screens",
                 "analysis_output", "runs", "telemetry_fetched", "export", "tools", "node_modules",
                 "reports")
$excludeFiles = @(".git", "*.tmp", "_cmsg.txt", "override.cfg")
$rcArgs = @($RepoRoot, $SandboxProject, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NP", "/R:1", "/W:1",
            "/XD") + $excludeDirs + @("/XF") + $excludeFiles
& robocopy @rcArgs | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Error "robocopy fallo con codigo $LASTEXITCODE"
    exit 14
}

# --- 2. Renombrar el proyecto en la copia -> user:// propio ---------------
$projFile = Join-Path $SandboxProject "project.godot"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$proj = [System.IO.File]::ReadAllText($projFile, [System.Text.Encoding]::UTF8)
$patched = [regex]::Replace($proj, '(?m)^config/name=.*$', ('config/name="' + $SANDBOX_NAME + '"'))
if (-not $patched.Contains('config/name="' + $SANDBOX_NAME + '"')) {
    Write-Error "No se pudo parchear config/name en la copia. Abortado por seguridad."
    exit 15
}
if ($patched -match 'use_custom_user_dir\s*=\s*true') {
    Write-Error "project.godot usa custom_user_dir: el renombrado no aislaria user://. Abortado."
    exit 16
}
[System.IO.File]::WriteAllText($projFile, $patched, $utf8NoBom)

# --- 3. Estado limpio ------------------------------------------------------
if (-not $KeepUserData -and (Test-Path $SandboxUserDir)) {
    Remove-Item -Recurse -Force $SandboxUserDir
}

# --- Ejecutar Godot con timeout, log a archivo -----------------------------
function Invoke-Godot([string[]]$GodotArgs, [string]$LogName, [int]$Timeout) {
    $logOut = Join-Path $SandboxRoot ($LogName + ".out.log")
    $logErr = Join-Path $SandboxRoot ($LogName + ".err.log")
    $quoted = $GodotArgs | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }
    $p = Start-Process -FilePath $Godot -ArgumentList $quoted -NoNewWindow -PassThru `
        -RedirectStandardOutput $logOut -RedirectStandardError $logErr
    $null = $p.Handle  # sin esto ExitCode queda vacio (quirk de Start-Process -PassThru)
    if (-not $p.WaitForExit($Timeout * 1000)) {
        $p.Kill()
        Write-Warning ("Timeout de " + $Timeout + " s: proceso Godot terminado.")
        return 20
    }
    return $p.ExitCode
}

# --- 4. Import (registra class_name nuevos + importa assets) ---------------
if (-not $SkipImport) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $code = Invoke-Godot @("--headless", "--path", $SandboxProject, "--import") "import" 900
    Write-Host ("[sandbox] import listo en {0:N1}s (exit {1})" -f $sw.Elapsed.TotalSeconds, $code)
}

# --- 5. Escena -------------------------------------------------------------
$sw = [Diagnostics.Stopwatch]::StartNew()
$godotArgs = @("--headless", "--path", $SandboxProject, $Scene)
if ($SceneArgs.Count -gt 0) { $godotArgs += @("--") + $SceneArgs }
$exit = Invoke-Godot $godotArgs "scene" $TimeoutSec
$elapsed = $sw.Elapsed.TotalSeconds

$outLog = Join-Path $SandboxRoot "scene.out.log"
$errLog = Join-Path $SandboxRoot "scene.err.log"
if (Test-Path $outLog) { Get-Content $outLog -Encoding UTF8 }

# Una escena que tira SCRIPT ERROR produce datos invalidos aunque salga con 0:
# se cuentan, se resumen por ubicacion y la corrida falla con exit 3.
$scriptErrors = 0
if ((Test-Path $errLog) -and ((Get-Item $errLog).Length -gt 0)) {
    $errLines = Get-Content $errLog -Encoding UTF8
    $scriptErrors = @($errLines | Where-Object { $_ -like "SCRIPT ERROR*" }).Count
    $engineErrors = @($errLines | Where-Object { $_ -like "ERROR:*" -and $_ -notlike "*leaked*" -and $_ -notlike "*still in use at exit*" }).Count
    if ($scriptErrors -gt 0 -or $engineErrors -gt 0) {
        Write-Host ("---- stderr: {0} SCRIPT ERROR, {1} ERROR de motor (sin contar leaks de salida) ----" -f $scriptErrors, $engineErrors)
        $errLines | Select-Object -First 25 | ForEach-Object { Write-Host $_ }
        Write-Host "---- ubicaciones mas frecuentes ----"
        $errLines | Where-Object { $_ -match '^\s+at: .*\(res://' } |
            Group-Object | Sort-Object Count -Descending | Select-Object -First 10 |
            ForEach-Object { Write-Host ("{0,6}  {1}" -f $_.Count, $_.Name.Trim()) }
    }
}
if ($scriptErrors -gt 0 -and $exit -eq 0) { $exit = 3 }
Write-Host ("[sandbox] escena termino en {0:N1}s con exit {1}" -f $elapsed, $exit)
exit $exit
