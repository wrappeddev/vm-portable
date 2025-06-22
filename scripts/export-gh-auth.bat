@echo off
REM ============================================================================
REM GitHub CLI Credentials Export Script
REM ============================================================================
REM This script exports GitHub CLI authentication credentials to make them
REM portable between different Windows VMs.
REM ============================================================================

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "CONFIG_DIR=%SCRIPT_DIR%..\config"

echo ============================================================================
echo GitHub CLI Credentials Export
echo ============================================================================
echo.
echo This script will export your GitHub CLI authentication credentials
echo to make them portable between VMs.
echo.

REM Check if GitHub CLI is installed
where gh >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: GitHub CLI (gh) is not installed or not in PATH.
    echo Please install GitHub CLI first.
    pause
    exit /b 1
)

REM Check if authenticated
gh auth status >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Not authenticated with GitHub CLI.
    echo Please run 'gh auth login' first.
    pause
    exit /b 1
)

echo Current GitHub CLI authentication status:
gh auth status
echo.

REM Create config directory if it doesn't exist
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

REM Export GitHub CLI hosts file
set "GH_CONFIG_DIR=%APPDATA%\GitHub CLI"
set "HOSTS_FILE=%GH_CONFIG_DIR%\hosts.yml"
set "BACKUP_FILE=%CONFIG_DIR%\gh-hosts-backup.yml"

if exist "%HOSTS_FILE%" (
    copy "%HOSTS_FILE%" "%BACKUP_FILE%" >nul
    if %errorLevel% equ 0 (
        echo ✓ GitHub CLI credentials exported to: %BACKUP_FILE%
        echo.
        echo You can now copy the entire 'config' folder to another VM
        echo and use the import script to restore your authentication.
        echo.
        echo Files exported:
        echo - %BACKUP_FILE%
        echo.
    ) else (
        echo ERROR: Failed to export GitHub CLI credentials.
        pause
        exit /b 1
    )
) else (
    echo ERROR: GitHub CLI hosts file not found at: %HOSTS_FILE%
    echo Make sure you are authenticated with GitHub CLI.
    pause
    exit /b 1
)

echo Export completed successfully!
echo.
echo To import on another VM:
echo 1. Copy the entire portable-dev-setup folder to the new VM
echo 2. Run scripts\import-gh-auth.bat
echo.
pause
