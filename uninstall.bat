@echo off
REM ============================================================================
REM Development Tools Uninstaller
REM ============================================================================
REM This script uninstalls development tools installed by the portable setup.
REM Use this to clean up before reinstalling or when no longer needed.
REM ============================================================================

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "SCRIPTS_DIR=%SCRIPT_DIR%scripts"
set "LOGS_DIR=%SCRIPT_DIR%logs"

echo ============================================================================
echo Portable Windows Dev Setup - Uninstaller
echo ============================================================================
echo.
echo This script will uninstall the following development tools:
echo - Node.js (and npm)
echo - Rust (rustup, cargo, and toolchains)
echo - Git for Windows
echo - GitHub CLI
echo.
echo WARNING: This will remove these tools and their configurations!
echo Make sure you have backed up any important data or configurations.
echo.

REM Set log file
set "timestamp=%RANDOM%_%RANDOM%"
set "LOG_FILE=%LOGS_DIR%\uninstall_%timestamp%.log"

REM Ensure logs directory exists
if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"

echo Log file: %LOG_FILE%
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo WARNING: Not running as administrator.
    echo Some uninstallation steps may fail without admin privileges.
    echo.
    set /p "CONTINUE_NO_ADMIN=Continue anyway? (y/N): "
    if /i not "!CONTINUE_NO_ADMIN!"=="y" (
        echo.
        echo To run as administrator:
        echo 1. Right-click on uninstall.bat
        echo 2. Select "Run as administrator"
        echo.
        pause
        exit /b 1
    )
    echo.
)

REM Final confirmation
echo Are you absolutely sure you want to uninstall all development tools?
echo This action cannot be undone!
echo.
set /p "FINAL_CONFIRM=Type 'yes' to confirm uninstallation: "

if not "!FINAL_CONFIRM!"=="yes" (
    echo Uninstallation cancelled.
    pause
    exit /b 0
)

echo.
echo Starting uninstallation process...
echo.

REM Set PowerShell execution policy
echo Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force" 2>&1
echo.

REM Run uninstall script
echo ============================================================================
echo Running Uninstaller
echo ============================================================================
powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\uninstall-tools.ps1" -LogFile "%LOG_FILE%"

if %errorLevel% neq 0 (
    echo.
    echo ============================================================================
    echo Uninstallation completed with some errors.
    echo ============================================================================
    echo.
    echo Some tools may need to be uninstalled manually:
    echo.
    echo 1. Open "Add or remove programs" in Windows Settings
    echo 2. Search for and uninstall:
    echo    - Node.js
    echo    - Git
    echo    - GitHub CLI
    echo.
    echo 3. For Rust, if still present, run: rustup self uninstall
    echo.
    echo Check the log file for detailed information: %LOG_FILE%
    echo.
) else (
    echo.
    echo ============================================================================
    echo Uninstallation completed successfully!
    echo ============================================================================
    echo.
    echo All development tools have been removed.
    echo.
    echo Next steps:
    echo 1. Restart your command prompt to refresh PATH
    echo 2. You can now run install.bat for a fresh installation
    echo 3. Or manually install individual tools as needed
    echo.
    echo Log file saved to: %LOG_FILE%
    echo.
)

echo ============================================================================
echo.
echo Press any key to exit...
pause >nul
