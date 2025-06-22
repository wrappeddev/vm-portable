@echo off
REM ============================================================================
REM Installation Verification Launcher
REM ============================================================================
REM This script launches the PowerShell verification script to check if all
REM development tools are properly installed and configured.
REM ============================================================================

setlocal

set "SCRIPT_DIR=%~dp0"
set "VERIFY_SCRIPT=%SCRIPT_DIR%scripts\verify-installation.ps1"

echo ============================================================================
echo Portable Dev Setup - Installation Verification
echo ============================================================================
echo.

REM Check if verification script exists
if not exist "%VERIFY_SCRIPT%" (
    echo ERROR: Verification script not found at: %VERIFY_SCRIPT%
    echo Please ensure the scripts folder is present.
    pause
    exit /b 1
)

REM Ask for detailed output
set /p "DETAILED=Show detailed information? (y/N): "

REM Run verification script
if /i "%DETAILED%"=="y" (
    powershell -ExecutionPolicy Bypass -File "%VERIFY_SCRIPT%" -Detailed
) else (
    powershell -ExecutionPolicy Bypass -File "%VERIFY_SCRIPT%"
)

echo.
pause
