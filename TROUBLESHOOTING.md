# Troubleshooting Guide

This guide helps resolve common issues with the Portable Windows Dev Setup.

## Common Issues

### 1. "Not running as administrator" Warning

**Problem**: Installation script shows administrator warning.

**Solutions**:
- Right-click `install.bat` and select "Run as administrator"
- Some installations (like Visual Studio Build Tools) require admin privileges
- You can continue without admin rights, but some features may not install

### 2. Missing Installer Files

**Problem**: "Missing installer files" error.

**Solutions**:
- Check the `installers/` folder exists
- Download all required files (see DOWNLOAD-LINKS.md)
- Verify file names match expected patterns:
  - `node-*.msi`
  - `rustup-init.exe`
  - `Git-*.exe`
  - `gh_*_windows_amd64.msi`

### 3. PowerShell Execution Policy Error

**Problem**: "Execution of scripts is disabled on this system"

**Solutions**:
```powershell
# Option 1: Set for current user (recommended)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser

# Option 2: Run specific script
powershell -ExecutionPolicy Bypass -File "scripts\install-nodejs.ps1"
```

### 4. Node.js Installation Fails

**Problem**: Node.js MSI installation fails.

**Solutions**:
- Ensure you downloaded the correct MSI (x64 version)
- Check if Node.js is already installed: `node --version`
- Try manual installation of the MSI file
- Check Windows Event Viewer for detailed error messages

### 5. Rust Installation Issues

**Problem**: rustup-init.exe fails or Rust commands not found.

**Solutions**:
- Restart command prompt/PowerShell after installation
- Manually add to PATH: `%USERPROFILE%\.cargo\bin`
- Check if antivirus is blocking rustup-init.exe
- Run rustup-init.exe manually to see error messages

### 6. Git Configuration Problems

**Problem**: Git user configuration fails or credentials don't work.

**Solutions**:
```bash
# Check current configuration
git config --global --list

# Manually set user info
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Reset credential helper
git config --global credential.helper manager
```

### 7. GitHub CLI Authentication Issues

**Problem**: `gh auth login` fails or credentials don't import.

**Solutions**:
- Check internet connectivity
- Try manual authentication: `gh auth login --web`
- For import issues, verify backup file exists in `config/gh-hosts-backup.yml`
- Clear existing auth: `gh auth logout` then re-authenticate

### 8. Windows Build Tools Installation Fails

**Problem**: npm install windows-build-tools fails.

**Solutions**:
- Ensure Node.js is properly installed first
- Try alternative: Install Visual Studio Build Tools manually
- Check npm configuration: `npm config list`
- Clear npm cache: `npm cache clean --force`

### 9. PATH Environment Variable Issues

**Problem**: Commands not found after installation.

**Solutions**:
- Restart command prompt/PowerShell
- Manually refresh PATH in current session:
```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
```
- Check PATH manually: `echo $env:PATH`

### 10. Antivirus Interference

**Problem**: Antivirus blocks installations or executables.

**Solutions**:
- Temporarily disable real-time protection during installation
- Add portable-dev-setup folder to antivirus exclusions
- Whitelist specific executables: rustup-init.exe, node.exe, git.exe

## Log File Analysis

Installation logs are saved to `logs/install_TIMESTAMP.log`. Common error patterns:

### MSI Installation Errors
- **Exit Code 1603**: Generic installation failure - check admin privileges
- **Exit Code 1618**: Another installation in progress - wait and retry
- **Exit Code 3010**: Success but reboot required

### PowerShell Errors
- **UnauthorizedAccess**: Execution policy issue
- **FileNotFound**: Missing installer files
- **AccessDenied**: Insufficient permissions

## Manual Installation Steps

If automated installation fails, you can install components manually:

### 1. Manual Node.js Installation
1. Double-click the Node.js MSI file
2. Follow the installation wizard
3. Verify: `node --version` and `npm --version`

### 2. Manual Rust Installation
1. Run `rustup-init.exe`
2. Choose default installation (option 1)
3. Restart command prompt
4. Verify: `rustc --version` and `cargo --version`

### 3. Manual Git Installation
1. Run the Git installer EXE
2. Use recommended settings or customize as needed
3. Verify: `git --version`

### 4. Manual GitHub CLI Installation
1. Double-click the GitHub CLI MSI file
2. Follow the installation wizard
3. Authenticate: `gh auth login`
4. Verify: `gh --version`

## Getting Help

### Check System Information
Run this PowerShell command to gather system info:
```powershell
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory
```

### Collect Logs
When reporting issues, include:
- Installation log file from `logs/` folder
- Output of `systeminfo` command
- PowerShell version: `$PSVersionTable`
- Error messages (exact text)

### Reset Installation
To start fresh:
1. Uninstall previously installed tools
2. Clear environment variables
3. Delete `logs/` and `config/` folders
4. Run installation again

### Contact Information
- Check the project repository for issues and updates
- Include system information and log files when reporting problems
- Specify which step failed and any error messages
