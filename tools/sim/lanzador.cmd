@echo off
rem Abre el lanzador visual del simulador y los golden tests (sin consola).
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0launcher.ps1"
