@echo off
REM Parchea el HTML exportado tras cada export web desde Godot.
REM Llama al .ps1 que maneja todo el procesamiento limpiamente.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix_web_export.ps1"
