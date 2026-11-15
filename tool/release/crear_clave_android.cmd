@echo off
rem Doble clic: crea la clave de firma del APK y la sube a GitHub (una sola vez).
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0crear_clave_android.ps1"
echo.
pause
