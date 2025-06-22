# Download Links for Portable Dev Setup

You have two options for getting the required installer files:

## Option 1: Automatic Download (Recommended)

Run the automatic download script:
```cmd
download.bat
```

This will automatically download all required installers from official sources to the `installers/` folder.

## Option 2: Manual Download

If you prefer to download manually or the automatic download fails, download the following installer files and place them in the `installers/` folder.

## Required Downloads

### 1. Node.js
- **Download**: [Node.js LTS](https://nodejs.org/en/download/)
- **File**: `node-v20.x.x-x64.msi` (or latest LTS version)
- **Size**: ~30 MB
- **Notes**: Download the Windows Installer (.msi) for x64

### 2. Rust
- **Download**: [rustup-init.exe](https://rustup.rs/)
- **File**: `rustup-init.exe`
- **Size**: ~8 MB
- **Notes**: Direct download link: https://win.rustup.rs/x86_64

### 3. Git
- **Download**: [Git for Windows](https://git-scm.com/download/win)
- **File**: `Git-x.x.x-64-bit.exe` (e.g., `Git-2.42.0-64-bit.exe`)
- **Size**: ~50 MB
- **Notes**: Download the 64-bit standalone installer

### 4. GitHub CLI
- **Download**: [GitHub CLI](https://cli.github.com/)
- **File**: `gh_x.x.x_windows_amd64.msi` (e.g., `gh_2.32.1_windows_amd64.msi`)
- **Size**: ~15 MB
- **Notes**: Download the Windows MSI installer

## Download Instructions

1. Create the `installers/` folder in your portable-dev-setup directory
2. Download each file using the links above
3. Place all downloaded files in the `installers/` folder
4. Verify you have all four files before running `install.bat`

## Expected Folder Structure

```
portable-dev-setup/
├── installers/
│   ├── node-v20.x.x-x64.msi
│   ├── rustup-init.exe
│   ├── Git-x.x.x-64-bit.exe
│   └── gh_x.x.x_windows_amd64.msi
├── scripts/
├── config/
└── install.bat
```

## Verification

The installation script will automatically check for these files and report any missing installers before starting the installation process.

## Alternative Download Methods

If you prefer to download via command line:

### PowerShell Download Script
```powershell
# Create installers directory
New-Item -ItemType Directory -Path "installers" -Force

# Note: These are example URLs - always download from official sources
# You'll need to update the URLs to the latest versions

# Download Node.js (check nodejs.org for latest LTS URL)
# Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.x.x/node-v20.x.x-x64.msi" -OutFile "installers/node-v20.x.x-x64.msi"

# Download Rust
Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile "installers/rustup-init.exe"

# Download Git (check git-scm.com for latest URL)
# Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.x.x.windows.1/Git-2.x.x-64-bit.exe" -OutFile "installers/Git-2.x.x-64-bit.exe"

# Download GitHub CLI (check cli.github.com for latest URL)
# Invoke-WebRequest -Uri "https://github.com/cli/cli/releases/download/v2.x.x/gh_2.x.x_windows_amd64.msi" -OutFile "installers/gh_2.x.x_windows_amd64.msi"
```

## Security Notes

- Always download from official sources
- Verify file integrity if checksums are provided
- Scan downloaded files with antivirus software
- The installation script will verify file extensions and basic integrity

## Offline Usage

Once downloaded, these installers can be used completely offline. The portable dev setup is designed to work without internet connectivity except for:
- Initial GitHub authentication
- npm package installations
- Rust crate downloads
- Git operations with remote repositories
