@echo off
title Autopilot HWID Harvester

:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Set PowerShell execution policy for the current process
powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned"

:: Run gethash.ps1 from the USB directory
powershell -ExecutionPolicy RemoteSigned -File "%~dp0gethash.ps1"

echo.
echo ============================================================
echo Process finished. Press any key to close this window.
echo ============================================================
pause >nul
