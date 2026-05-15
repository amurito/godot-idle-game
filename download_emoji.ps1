# Descarga PNGs de Twemoji para AntiIDLE web export
# Ejecutar desde el directorio del proyecto: .\download_emoji.ps1

$dest = "$PSScriptRoot\emoji"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$codes = @(
    "1f7e4","26aa","1f7e1","1f534","1f7e3","1f7e2","1f535",
    "1f3c1","2728","1f311","26a1",
    "2620-fe0f","26a0-fe0f","2623-fe0f","2696-fe0f",
    "1f578-fe0f","1f573-fe0f","26b1-fe0f","1f3db-fe0f","1f32a-fe0f",
    "1f4be","1f9ec","1f52c","1f525","1f49c","1f48e","1f49a",
    "1f4e1","1f9e0","1f680","1f47e","1f3ad","1f393","1f344",
    "1f480","1f9a0","1f33f","1f331","1f4e4","1f3e0","1f512",
    "1f4dc","1f4cb","1f41b","1f4b8","1f30b","1f6f8","1f6a9",
    "23e9","2705","1f91d","1f300","1f3af","1f4a5","1f3d7-fe0f"
)

$base = "https://cdnjs.cloudflare.com/ajax/libs/twemoji/14.0.2/72x72/"
$ok = 0; $fail = 0

foreach ($c in $codes) {
    $path = "$dest\$c.png"
    if (Test-Path $path) { $ok++; continue }
    try {
        Invoke-WebRequest -Uri "$base$c.png" -OutFile $path -ErrorAction Stop
        Write-Host "OK  $c.png"
        $ok++
    } catch {
        Write-Host "ERR $c.png — $_"
        $fail++
    }
}
Write-Host "`nListo: $ok OK, $fail errores"
