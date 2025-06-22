# Portable Windows Dev Setup

A complete portable development environment setup for Windows VMs that can be used offline (except for initial downloads and GitHub authentication). Features automatic downloads, smart recovery options, and comprehensive error handling.

## What's Included

- **Node.js** - JavaScript runtime with npm (latest LTS)
- **Rust** - Systems programming language with Cargo (stable toolchain)
- **Git** - Version control system with Windows optimizations
- **GitHub CLI** - Command-line interface for GitHub with credential helper
- **Visual Studio Code** - Modern code editor with extensions support
- **Windows Build Tools** - Required for native npm modules compilation
- **PowerShell Configuration** - Execution policy setup for script execution
- **GitHub Credentials** - Portable authentication setup between VMs

## Folder Structure

```
portable-dev-setup/
├── install.bat                    # Main installation script
├── download.bat                   # Automatic installer download script
├── verify.bat                     # Installation verification script
├── uninstall.bat                  # Uninstall development tools
├── README.md                      # This file
├── DOWNLOAD-LINKS.md              # Download instructions for installers
├── TROUBLESHOOTING.md             # Comprehensive troubleshooting guide
├── CHANGELOG.md                   # Version history and changes
├── .gitignore                     # Git ignore file for version control
├── installers/                    # Downloaded installer files
│   ├── README.md                  # Instructions for this directory
│   ├── node-v20.x.x-x64.msi      # Node.js installer (download separately)
│   ├── rustup-init.exe            # Rust installer (download separately)
│   ├── Git-x.x.x-64-bit.exe      # Git installer (download separately)
│   ├── gh_x.x.x_windows_amd64.msi # GitHub CLI installer (download separately)
│   └── VSCodeUserSetup-x64-x.x.x.exe # Visual Studio Code installer (download separately)
├── scripts/                       # PowerShell installation scripts
│   ├── install-nodejs.ps1         # Node.js installation
│   ├── install-rust.ps1           # Rust installation with toolchain setup
│   ├── install-git.ps1            # Git installation and configuration
│   ├── install-github-cli.ps1     # GitHub CLI installation and auth
│   ├── install-vscode.ps1         # Visual Studio Code installation
│   ├── install-build-tools.ps1    # Windows Build Tools installation
│   ├── download-installers.ps1    # Automatic installer download script
│   ├── uninstall-tools.ps1        # Development tools uninstaller
│   ├── verify-installation.ps1    # Comprehensive verification script
│   ├── export-gh-auth.bat         # GitHub credentials export utility
│   ├── import-gh-auth.bat         # GitHub credentials import utility
│   └── utils.ps1                  # Shared utility functions
├── config/                        # Configuration files and templates
│   ├── README.md                  # Configuration documentation
│   ├── git-config-template.txt    # Git configuration template
│   └── gh-hosts-backup.yml       # GitHub CLI hosts backup (created during export)
└── logs/                          # Installation and operation logs
    ├── README.md                  # Log documentation
    └── install_TIMESTAMP.log     # Installation logs with timestamps
```

## 📊 Installation Workflow

The installation system follows a structured workflow with multiple entry points and recovery options:

### Main Entry Points
```
📥 download.bat     → Downloads all installers automatically
🔧 install.bat      → Main installation orchestrator
✅ verify.bat       → Verifies all installations
🗑️ uninstall.bat    → Removes all installed tools
```

### Installation Flow
```
install.bat
    ├── Check for installer files
    ├── Set PowerShell execution policy
    ├── install-nodejs.ps1      (Node.js + npm)
    ├── install-rust.ps1        (Rust + Cargo + components)
    ├── install-git.ps1         (Git + Windows config)
    ├── install-github-cli.ps1  (GitHub CLI + auth)
    ├── install-vscode.ps1      (VSCode + recovery options)
    ├── install-build-tools.ps1 (Windows Build Tools)
    └── verify-installation.ps1 (Final verification)
```

### Recovery & Utilities
```
🔄 Each installer script offers:
   ├── Detect existing installations
   ├── Keep/Reinstall/Skip options
   ├── Auto-download missing installers
   ├── Retry/Re-download on failure
   └── Comprehensive error logging

📤 export-gh-auth.bat → Export GitHub credentials
📥 import-gh-auth.bat → Import GitHub credentials
🛠️ utils.ps1          → Shared utility functions
```

## Quick Start

### Option A: Automatic Download + Install (Recommended)
```cmd
# Download all installers automatically
download.bat

# Then run the installation
install.bat
```

### Option B: Manual Download + Install
1. **Download Required Installers** (see `DOWNLOAD-LINKS.md` for links):
   - **Node.js LTS** from https://nodejs.org/ (MSI installer)
   - **Rust** from https://rustup.rs/ (rustup-init.exe)
   - **Git** from https://git-scm.com/ (64-bit installer)
   - **GitHub CLI** from https://cli.github.com/ (MSI installer)
   - **Visual Studio Code** from https://code.visualstudio.com/ (User installer)

2. **Place files** in the `installers/` folder

3. **Run Installation**:
   ```cmd
   install.bat
   ```

### Option C: One-Step Install (with auto-download)
```cmd
# Run install.bat directly - it will offer to download missing files
install.bat
```

### Final Steps (All Options)
- Choose whether to uninstall existing tools (for clean install)
- Provide Git username and email when prompted
- Authenticate with GitHub CLI (or import existing credentials)
- Wait for installation to complete
- Verify with: `verify.bat`

## 🗑️ Uninstalling

### Complete Uninstall
```cmd
uninstall.bat
```
This will remove all installed development tools and clean up configurations.

### Uninstall During Installation
The install script now offers to uninstall existing tools before installing new ones for a clean setup.

## Key Features

- **🔧 Silent Installation**: All tools install without user interaction
- **📥 Automatic Downloads**: Can download all installers from official sources
- **📱 Offline Capable**: Works without internet after initial setup
- **🔐 Portable Credentials**: Export/import GitHub authentication between VMs
- **📝 Comprehensive Logging**: All operations logged for troubleshooting
- **🛡️ Error Handling**: Robust error checking and recovery mechanisms
- **🔄 Smart Recovery**: Multiple recovery options when installations fail
- **💻 Existing Installation Detection**: Smart handling of already installed tools
- **✅ Verification Tools**: Built-in verification to ensure proper installation
- **📚 Detailed Documentation**: Comprehensive guides and troubleshooting

## What Gets Installed

| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | Latest LTS | JavaScript runtime and npm package manager |
| Rust | Stable | Systems programming language with Cargo |
| Git | Latest | Version control with Windows optimizations |
| GitHub CLI | Latest | GitHub integration and credential helper |
| Visual Studio Code | Latest | Code editor with extensions support |
| Build Tools | Latest | Windows build tools for native npm modules |

## Manual Steps Required

1. **Download Installers**: Use `download.bat` for automatic download, or place files manually in `installers/` folder
2. **Git Configuration**: Provide username and email during setup
3. **GitHub Authentication**: Authenticate with GitHub (one-time or import existing)

## Credential Portability

### Export GitHub credentials from one VM:
```cmd
scripts\export-gh-auth.bat
```

### Import to another VM:
```cmd
scripts\import-gh-auth.bat
```

This allows you to maintain GitHub authentication across different VMs without re-authenticating each time.

## 🔄 Smart Installation & Recovery Features

### Automatic Download
- **Missing Installers**: If any installer is missing, the script offers to download it automatically
- **VSCode Auto-Download**: Visual Studio Code installer is downloaded on-demand if not found
- **Official Sources**: All downloads come from official vendor websites

### Recovery Options
When installations fail, you get multiple recovery options:

#### For All Tools:
- **Retry Installation**: Attempt installation again with current installer
- **Re-download**: Delete current installer and download fresh copy
- **Skip Installation**: Continue with other tools if one fails

#### For Existing Installations:
- **Keep Existing**: Preserve current installation (recommended)
- **Reinstall**: Remove existing version and install fresh
- **Upgrade**: Update to newer version when available

### Smart Detection
- **Existing Tools**: Automatically detects already installed development tools
- **Version Checking**: Shows current versions of installed tools
- **Conflict Resolution**: Handles version conflicts and installation issues
- **Path Integration**: Ensures all tools are properly added to system PATH

## System Requirements

- **OS**: Windows 10 or later (Windows 11 recommended)
- **Privileges**: Administrator privileges recommended for some installations
- **Internet**: Required for initial downloads and GitHub authentication
- **Disk Space**: Approximately 700MB for all tools (including VSCode)
- **Memory**: 4GB RAM minimum (8GB recommended)

## Installation Process

The installation follows this sequence with smart recovery options at each step:

### Step-by-Step Process
```
🚀 install.bat starts
    ↓
📋 Check for installer files
    ├── ❌ Missing files → Offer auto-download or manual download
    └── ✅ All found → Continue
    ↓
⚙️ Set PowerShell execution policy
    ↓
📦 Install Node.js
    ├── 🔍 Check if exists → Keep/Reinstall/Skip
    ├── 📦 Install silently
    └── ❌ Failed → Retry/Re-download/Skip
    ↓
🦀 Install Rust
    ├── 🔍 Check if exists → Keep/Reinstall/Skip
    ├── 📦 Install toolchain + components
    └── ❌ Failed → Retry/Re-download/Skip
    ↓
🛺 Install Git
    ├── 🔍 Check if exists → Keep/Reinstall/Skip
    ├── 📦 Install with Windows config
    └── ❌ Failed → Retry/Re-download/Skip
    ↓
🐙 Install GitHub CLI
    ├── 🔍 Check if exists → Keep/Reinstall/Skip
    ├── 📦 Install + setup auth
    └── ❌ Failed → Retry/Re-download/Skip
    ↓
💻 Install Visual Studio Code
    ├── 🔍 Check if exists → Keep/Reinstall/Skip
    ├── 📁 No installer → Auto-download from Microsoft
    ├── 📦 Install with PATH integration
    └── ❌ Failed → Retry/Re-download/Skip
    ↓
🔨 Install Windows Build Tools
    ├── 📦 Install via npm
    └── ❌ Failed → Retry/Skip
    ↓
✅ Verify all installations
    ↓
🎉 Installation Complete!
```

### Recovery Options Available
- **🔄 Retry**: Try installation again with current installer
- **📥 Re-download**: Delete current installer and download fresh copy
- **⏭️ Skip**: Continue with other tools if one fails
- **🔧 Keep Existing**: Preserve current installation when detected
- **🔄 Reinstall**: Remove existing and install fresh version

Each step includes comprehensive logging and error handling to ensure successful installation.

## Post-Installation

After installation completes:

1. **Restart Terminal**: Close and reopen command prompt/PowerShell to refresh PATH
2. **Verify Installation**: Run `verify.bat` to check all tools
3. **Test Tools**: Try basic commands:
   ```cmd
   node --version
   npm --version
   rustc --version
   cargo --version
   git --version
   gh --version
   code --version
   ```

## Usage Examples

### Node.js Development
```cmd
# Create a new project
mkdir my-project && cd my-project
npm init -y
npm install express

# Install global tools
npm install -g typescript nodemon
```

### Rust Development
```cmd
# Create a new Rust project
cargo new hello-rust
cd hello-rust
cargo run

# Add dependencies
cargo add serde tokio
```

### Git Operations
```cmd
# Clone a repository
git clone https://github.com/user/repo.git

# Configure for a project
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### GitHub CLI
```cmd
# Create a new repository
gh repo create my-new-repo --public

# Clone your repositories
gh repo clone user/repo

# Create issues and PRs
gh issue create --title "Bug report" --body "Description"
gh pr create --title "Feature" --body "Description"
```

### Visual Studio Code
```cmd
# Open current directory in VSCode
code .

# Open a specific file
code myfile.js

# Install extensions
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension rust-lang.rust-analyzer

# Open with specific settings
code --new-window --goto myfile.js:10:5
```

## Troubleshooting

If you encounter issues:

1. **Check Logs**: Review the installation log in `logs/install_TIMESTAMP.log`
2. **Run Verification**: Use `verify.bat` to identify specific problems
3. **Use Recovery Options**: The installer provides multiple recovery options for failed installations
4. **Consult Documentation**: See `TROUBLESHOOTING.md` for common solutions
5. **Manual Installation**: Install individual components manually if needed

### Common Recovery Scenarios

- **Download Failed**: Script will offer to retry download or skip the tool
- **Installation Failed**: Choose to retry, re-download installer, or skip
- **Existing Installation**: Keep current version, reinstall, or upgrade
- **Missing Dependencies**: Script will guide you through resolution steps

## File Organization

- **Scripts**: All PowerShell scripts are in the `scripts/` folder
- **Configuration**: Templates and backups in `config/` folder
- **Logs**: Installation logs in `logs/` folder with timestamps
- **Documentation**: Multiple markdown files for different aspects

## Security Considerations

- **Installer Verification**: Only download from official sources
- **Credential Storage**: GitHub credentials are stored securely by GitHub CLI
- **Execution Policy**: PowerShell execution policy is set to Bypass for current user only
- **Admin Privileges**: Some installations may require administrator rights

## Contributing

This is a standalone portable setup. To customize:

1. Modify scripts in the `scripts/` folder
2. Update configuration templates in `config/`
3. Add new tools by creating additional PowerShell scripts
4. Follow the existing patterns for logging and error handling

## License

This portable dev setup is provided as-is for educational and development purposes. Individual tools have their own licenses:

- Node.js: MIT License
- Rust: MIT/Apache 2.0
- Git: GPL v2
- GitHub CLI: MIT License
- Visual Studio Code: Microsoft Software License

## Version

Current version: 1.3.0 (see `CHANGELOG.md` for version history)
