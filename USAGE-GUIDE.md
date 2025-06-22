# Usage Guide - Portable Windows Dev Setup

This guide explains all the different ways to use the Portable Windows Dev Setup.

## 🚀 Quick Start Options

### Option 1: Fully Automatic (Recommended)
```cmd
# Download all installers automatically, then install
download.bat
install.bat
```

### Option 2: One-Command Install
```cmd
# Run install directly - it will offer to download missing files
install.bat
```

### Option 3: Manual Download + Install
```cmd
# Download installers manually (see DOWNLOAD-LINKS.md)
# Place files in installers/ folder
install.bat
```

## 📥 Download Options

### Automatic Download
- **Command**: `download.bat`
- **Requirements**: Internet connection
- **Downloads**: All 4 required installer files (~100MB total)
- **Sources**: Official websites only
- **Features**: 
  - Progress indicators
  - Automatic retry on failure
  - File verification
  - Resume capability

### Manual Download
- **Guide**: See `DOWNLOAD-LINKS.md`
- **Advantage**: Can download on different machine/network
- **Use case**: Restricted networks, offline preparation

## 🛠️ Installation Process

### Standard Installation
```cmd
install.bat
```

**What it does:**
1. Checks for installer files
2. Offers to download missing files automatically
3. Sets PowerShell execution policy
4. Installs Node.js, Rust, Git, GitHub CLI
5. Installs Windows Build Tools
6. Configures Git and GitHub CLI integration
7. Creates comprehensive logs

### Installation Steps in Detail

1. **Pre-flight Checks**
   - Verifies installer files exist
   - Checks admin privileges
   - Creates log directories

2. **Node.js Installation**
   - Silent MSI installation
   - Updates npm to latest
   - Verifies installation

3. **Rust Installation**
   - Installs stable toolchain
   - Adds common components (clippy, rustfmt)
   - Creates Cargo configuration

4. **Git Installation**
   - Silent installation with Windows optimizations
   - Prompts for user name/email
   - Configures for GitHub CLI integration

5. **GitHub CLI Installation**
   - Silent MSI installation
   - Sets up credential helper
   - Handles authentication (login or import)

6. **Build Tools Installation**
   - Installs via npm (windows-build-tools)
   - Fallback to manual instructions if needed
   - Tests compilation capability

## ✅ Verification

### Quick Verification
```cmd
verify.bat
```

### Detailed Verification
```cmd
verify.bat
# Choose "y" when prompted for detailed information
```

**What it checks:**
- All tools are installed and in PATH
- Version information
- Git configuration
- GitHub CLI authentication
- Build tools functionality
- System information

## 🔐 Credential Management

### Export GitHub Credentials
```cmd
scripts\export-gh-auth.bat
```
- Saves GitHub CLI authentication to `config/gh-hosts-backup.yml`
- Makes credentials portable between VMs

### Import GitHub Credentials
```cmd
scripts\import-gh-auth.bat
```
- Restores GitHub CLI authentication from backup
- Verifies authentication works

### Credential Workflow
1. **First VM**: Install → Authenticate → Export
2. **Copy**: Transfer entire portable-dev-setup folder
3. **Second VM**: Install → Import credentials

## 📁 File Organization

### Main Scripts
- `install.bat` - Main installation orchestrator
- `download.bat` - Automatic installer download
- `verify.bat` - Installation verification

### PowerShell Scripts (scripts/ folder)
- `download-installers.ps1` - Downloads installer files
- `install-*.ps1` - Individual tool installations
- `verify-installation.ps1` - Comprehensive verification
- `utils.ps1` - Shared utility functions

### Credential Scripts
- `export-gh-auth.bat` - Export GitHub credentials
- `import-gh-auth.bat` - Import GitHub credentials

### Configuration
- `config/` - Configuration templates and backups
- `logs/` - Installation and operation logs
- `installers/` - Downloaded installer files

## 🔧 Advanced Usage

### Force Re-download
```cmd
download.bat
# Choose "y" when asked about re-downloading existing files
```

### Selective Installation
The scripts are modular. You can run individual PowerShell scripts:
```powershell
# Install only Node.js
scripts\install-nodejs.ps1 -LogFile "logs\nodejs.log" -InstallersDir "installers"
```

### Custom Configuration
- Edit `config/git-config-template.txt` for Git defaults
- Modify PowerShell scripts for custom tool versions
- Update download URLs in `scripts/download-installers.ps1`

## 🚨 Troubleshooting

### Common Issues
1. **Missing Installers**: Use `download.bat` or see `DOWNLOAD-LINKS.md`
2. **Permission Errors**: Run as administrator
3. **Network Issues**: Check firewall/proxy settings
4. **Antivirus Blocking**: Add exclusions for the setup folder

### Getting Help
1. Check `logs/install_TIMESTAMP.log` for detailed errors
2. Run `verify.bat` to identify specific issues
3. See `TROUBLESHOOTING.md` for comprehensive solutions
4. Check system requirements in `README.md`

### Log Files
- `logs/install_TIMESTAMP.log` - Main installation log
- `logs/download_TIMESTAMP.log` - Download operation log
- Individual component logs in temp directories

## 🎯 Use Cases

### Development VM Setup
- Fresh Windows VM → Run `download.bat` → Run `install.bat` → Start coding

### Team Onboarding
- Prepare setup with downloaded installers
- Share folder → Team members run `install.bat`
- Import shared GitHub credentials if needed

### Offline Installation
- Download installers on connected machine
- Transfer complete folder to offline machine
- Run `install.bat` (skips download, installs from local files)

### Multiple VM Management
- Set up first VM completely
- Export GitHub credentials
- Clone setup folder to other VMs
- Import credentials for seamless GitHub access

## 📊 What You Get

After successful installation:
- **Node.js** with npm for JavaScript development
- **Rust** with Cargo for systems programming
- **Git** configured for GitHub integration
- **GitHub CLI** for repository management
- **Build tools** for native module compilation
- **Portable credentials** for easy VM switching

All tools are properly configured, in PATH, and ready to use immediately.
