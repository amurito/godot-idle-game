<#
.SYNOPSIS
    Benchmark antes/despues: corre los mismos escenarios del simulador sobre dos copias del
    proyecto (p.ej. un commit viejo en un worktree y el actual) y deja un JSON por corrida.

.DESCRIPTION
    ASCII puro a proposito (ver nota en run_sandboxed.ps1).

    Para comparar con justicia, la copia "before" debe usar el MISMO harness que la actual:
    copiar tests/sim, tests/golden y tools/sim del codigo actual al worktree viejo.

      git worktree add --detach C:\tmp\baseline <commit>
      Copy-Item -Recurse tests\sim, tests\golden C:\tmp\baseline\tests\ -Force
      Copy-Item tools\sim\*.ps1 C:\tmp\baseline\tools\sim\ -Force
      .\tools\sim\run_benchmark.ps1 -BeforeDir C:\tmp\baseline -OutDir C:\tmp\bench
      python tools\sim\bench_analyze.py C:\tmp\bench

    Las corridas ya presentes en OutDir se saltean (se puede cortar y retomar).
    max_t=400: antes de los 420 s de la Masa Critica, para que ambas versiones procesen la
    misma carga aunque una cierre la run y la otra no.
#>
param(
    [Parameter(Mandatory = $true)][string]$BeforeDir,
    [string]$AfterDir = "",
    [Parameter(Mandatory = $true)][string]$OutDir,
    [int]$Reps = 3,
    [int]$MaxT = 400
)
$ErrorActionPreference = "Stop"
if ($AfterDir -eq "") { $AfterDir = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path }
$builds = @{ "before" = $BeforeDir; "after" = $AfterDir }
$configs = @(
    @{ id = "buyall_desktop"; sc = "fresh_buy_all";      plat = "desktop" },
    @{ id = "buyall_web";     sc = "fresh_buy_all";      plat = "web" },
    @{ id = "hiper_desktop";  sc = "fresh_hiper";        plat = "desktop" },
    @{ id = "fusion_desktop"; sc = "ng_fusion_player";   plat = "desktop" },
    @{ id = "legacy_desktop"; sc = "ng_legacy_showcase"; plat = "desktop" }
)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
foreach ($rep in 1..$Reps) {
    foreach ($b in @("before", "after")) {
        $runner = Join-Path $builds[$b] "tools\sim\run_sandboxed.ps1"
        foreach ($c in $configs) {
            $out = Join-Path $OutDir ("{0}_{1}_r{2}.json" -f $b, $c.id, $rep)
            if (Test-Path $out) { continue }
            # Ojo: cada argumento entre parentesis; "a" + $x, "b" concatenaria el array entero.
            $params = @{ Instance = "bench_$b"; TimeoutSec = 900; SkipImport = $true
                SceneArgs = @(("--scenario=" + $c.sc), ("--platform=" + $c.plat), ("--max_t=" + $MaxT),
                              "--seed=1337", ("--out=" + $out)) }
            & $runner @params 2>&1 | Out-Null
            Write-Host ("{0} r{1} {2}: {3}" -f $b, $rep, $c.id, (Test-Path $out))
        }
    }
}
