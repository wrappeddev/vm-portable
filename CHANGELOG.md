# Changelog

All notable changes to the Portable Windows Dev Setup will be documented in this file.

## [1.3.0] - 2025-06-22

### Added
- **Visual Studio Code Integration**: New `install-vscode.ps1` script with automatic download and installation
- **VSCode Recovery Options**: Multiple recovery options for failed installations including:
  - Delete current installer and re-download
  - Remove existing VSCode installation and reinstall
  - Skip VSCode installation entirely
- **Automatic VSCode Download**: Script can download VSCode installer if not found in installers folder
- **Enhanced Verification**: Added VSCode verification to the verification script

### Enhanced
- Updated all documentation to include Visual Studio Code
- Added VSCode to download scripts and batch files
- Improved installer download functionality with VSCode support
- Updated README.md with VSCode installation information

## [1.2.0] - 2024-12-22

### Added
- **Uninstall Functionality**: New `uninstall.bat` script to completely remove all development tools
- **Pre-Installation Cleanup**: Install script now offers to uninstall existing tools before installation
- **Smart Conflict Resolution**: Better handling of existing installations and version conflicts
- **Enhanced Node.js Handling**: Improved logic for dealing with existing Node.js installations

### Enhanced
- Better error messages and recovery options for installation failures
- Improved PowerShell script syntax and error handling
- Updated documentation with uninstall instructions

## [1.1.0] - 2024-12-22

### Added
- **Automatic Installer Download**: New `download.bat` script automatically downloads all required installers
- **Smart Installation**: `install.bat` now offers to download missing installers automatically
- **Enhanced User Experience**: Multiple installation options (automatic download, manual download, or hybrid)

### Enhanced
- Updated documentation to reflect automatic download capabilities
- Improved error handling for missing installer files
- Better user prompts and guidance during installation

## [1.0.0] - 2024-12-22

### Added
- Initial release of Portable Windows Dev Setup
- Automated installation of Node.js from MSI installer
- Automated installation of Rust using rustup-init.exe
- Automated installation of Git with Windows-optimized configuration
- Automated installation of GitHub CLI with authentication support
- Windows Build Tools installation via npm
- PowerShell execution policy configuration
- Git global user configuration setup
- GitHub CLI credential helper integration
- Portable GitHub credentials export/import functionality
- Comprehensive logging system
- Installation verification script
- Detailed troubleshooting documentation
- Download links and instructions for all required installers

### Features
- **Automatic Downloads**: Can download all installers from official sources
- **Silent Installation**: All tools install without user interaction
- **Offline Capable**: Works without internet after initial setup (except for auth)
- **Portable Credentials**: Export/import GitHub authentication between VMs
- **Comprehensive Logging**: All operations logged for troubleshooting
- **Error Handling**: Robust error checking and recovery mechanisms
- **Verification Tools**: Built-in verification to ensure proper installation

### Components Installed
- Node.js LTS with npm
- Rust stable toolchain with Cargo
- Git for Windows with optimized settings
- GitHub CLI with credential helper integration
- Windows Build Tools for native npm modules
- PowerShell execution policy configuration

### Scripts Included
- `install.bat` - Main installation orchestrator
- `download.bat` - Automatic installer download launcher
- `verify.bat` - Installation verification launcher
- `uninstall.bat` - Complete development tools uninstaller
- `scripts/install-nodejs.ps1` - Node.js installation
- `scripts/install-rust.ps1` - Rust installation
- `scripts/install-git.ps1` - Git installation and configuration
- `scripts/install-github-cli.ps1` - GitHub CLI installation and auth
- `scripts/install-vscode.ps1` - Visual Studio Code installation
- `scripts/install-build-tools.ps1` - Windows Build Tools installation
- `scripts/download-installers.ps1` - Automatic installer download
- `scripts/uninstall-tools.ps1` - Development tools uninstaller
- `scripts/verify-installation.ps1` - Comprehensive verification
- `scripts/export-gh-auth.bat` - GitHub credentials export
- `scripts/import-gh-auth.bat` - GitHub credentials import
- `scripts/utils.ps1` - Shared utility functions

### Documentation
- `README.md` - Main documentation and quick start guide
- `DOWNLOAD-LINKS.md` - Links and instructions for downloading installers
- `TROUBLESHOOTING.md` - Comprehensive troubleshooting guide
- `CHANGELOG.md` - This changelog file

### Configuration
- Git configuration template with Windows optimizations
- Cargo configuration for Windows development
- GitHub CLI preferences and credential helper setup
- PowerShell execution policy configuration

### Requirements
- Windows 10 or later
- Administrator privileges (recommended for some installations)
- Internet connection for initial downloads and GitHub authentication
- Approximately 500MB disk space for all tools

### Known Limitations
- Windows Build Tools installation may require manual intervention
- Some antivirus software may interfere with installations
- GitHub authentication requires internet connectivity
- Visual Studio Build Tools may need separate installation for complex native modules

## Future Enhancements

### Planned for v1.4.0
- Support for additional development tools (Python, Java, etc.)
- Extension management for VS Code
- Docker Desktop integration
- WSL2 setup automation

### Planned for v1.5.0
- GUI installer interface
- Custom tool selection during installation
- Profile-based installations (web dev, systems programming, etc.)
- Automatic updates for installed tools
- Cloud backup integration for configurations

### Under Consideration
- Support for other package managers (Chocolatey, Scoop)
- Integration with Windows Package Manager (winget)
- Automated development environment templates
- Team configuration sharing
- CI/CD pipeline integration
