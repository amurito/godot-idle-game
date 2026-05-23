# fix_web_export.ps1
# Ejecutar DESPUES de cada export web desde Godot.
# Parchea: 1) canvasResizePolicy 0->2  2) inyecta audio-unlock JS en <head>

$ErrorActionPreference = "Stop"
$htmlPath = Join-Path $PSScriptRoot "builds\web\index.html"

if (-not (Test-Path $htmlPath)) {
    Write-Host "ERROR: No se encontro $htmlPath - exporta el juego primero."
    Read-Host "Presiona Enter para salir"
    exit 1
}

$html = Get-Content $htmlPath -Raw -Encoding UTF8

# --- 1. canvasResizePolicy 0 -> 2 ---
if ($html -like '*"canvasResizePolicy":0*') {
    $html = $html -replace '"canvasResizePolicy":0', '"canvasResizePolicy":2'
    Write-Host "OK: canvasResizePolicy -> 2"
} else {
    Write-Host "INFO: canvasResizePolicy ya es 2 (o no encontrado)"
}

# --- 2. Audio unlock en <head> ---
# Intercepta window.AudioContext ANTES de que Godot lo cree.
# Cuando el usuario hace click, el flag queda activado.
# Cuando Godot crea el AudioContext (lazy, al primer play), lo resumimos
# inmediatamente dentro de la ventana de transient user activation del browser.
$audioHead = @'
<script>/* __audio_unlock_v3 */
(function(){
  var _activated=false, _ctxs=[];
  var _Orig=window.AudioContext||window.webkitAudioContext;
  if(_Orig){
    var _Wrap=function AudioContext(){
      var c=new _Orig();
      _ctxs.push(c);
      if(_activated && c.state!=='running') c.resume().catch(function(){});
      return c;
    };
    _Wrap.prototype=_Orig.prototype;
    window.AudioContext=window.webkitAudioContext=_Wrap;
  }
  function activate(){
    if(_activated) return;
    _activated=true;
    _ctxs.forEach(function(c){if(c.state!=='running')c.resume().catch(function(){});});
    if(typeof GodotAudio!=='undefined'&&GodotAudio.ctx&&GodotAudio.ctx.state!=='running')
      GodotAudio.ctx.resume().catch(function(){});
  }
  ['pointerdown','click','touchstart'].forEach(function(e){
    document.addEventListener(e,activate,{capture:true});
  });
})();
</script>
'@

if ($html -like '*__audio_unlock_v3*') {
    Write-Host "SKIP: audio unlock v3 ya presente"
} else {
    # Limpiar versiones anteriores si existen
    $html = $html -replace '<script>/\* __godot_audio_unlock \*/[\s\S]*?</script>\s*', ''
    $html = $html -replace '<script>/\* __audioUnlockInjected \*/[\s\S]*?</script>\s*', ''
    # Inyectar en <head> (despues del tag <head>)
    $html = $html -replace '<head>', ('<head>' + $audioHead)
    Write-Host "OK: audio unlock v3 inyectado en <head>"
}

Set-Content $htmlPath $html -Encoding UTF8

Write-Host ""
Write-Host "Listo! Subi la carpeta builds\web\ al servidor."
Write-Host ""
Read-Host "Presiona Enter para cerrar"
