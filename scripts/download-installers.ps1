# ============================================================================
# Automatic Installer Download Script
# ============================================================================
# This script automatically downloads the required installer files from
# official sources to make the setup completely portable and automated.
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$LogFile,
    
    [Parameter(Mandatory=$true)]
    [string]$InstallersDir,
    
    [switch]$Force
)

# Import utility functions
. "$PSScriptRoot\utils.ps1"

Write-Log "Starting automatic installer download..." $LogFile

# Define download URLs and file information
$Installers = @{
    "Node.js" = @{
        Name = "Node.js LTS"
        Pattern = "node-*.msi"
        FileName = "node-v20.10.0-x64.msi"
        Url = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
        Size = "~30 MB"
        Required = $true
    }
    "Rust" = @{
        Name = "Rust (rustup)"
        Pattern = "rustup-init.exe"
        FileName = "rustup-init.exe"
        Url = "https://win.rustup.rs/x86_64"
        Size = "~8 MB"
        Required = $true
    }
    "Git" = @{
        Name = "Git for Windows"
        Pattern = "Git-*.exe"
        FileName = "Git-2.47.1-64-bit.exe"
        Url = "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe"
        Size = "~50 MB"
        Required = $true
    }
    "GitHub CLI" = @{
        Name = "GitHub CLI"
        Pattern = "gh_*_windows_amd64.msi"
        FileName = "gh_2.62.0_windows_amd64.msi"
        Url = "https://github.com/cli/cli/releases/download/v2.62.0/gh_2.62.0_windows_amd64.msi"
        Size = "~15 MB"
        Required = $true
    }
    "VSCode" = @{
        Name = "Visual Studio Code"
        Pattern = "VSCodeUserSetup-*.exe"
        FileName = "VSCodeUserSetup-x64-1.96.2.exe"
        Url = "https://update.code.visualstudio.com/1.96.2/win32-x64-user/stable"
        Size = "~100 MB"
        Required = $false
    }
}

try {
    # Check internet connectivity
    Write-Log "Checking internet connectivity..." $LogFile
    Write-Host "Checking internet connectivity..."
    
    if (-not (Test-InternetConnection)) {
        throw "No internet connection available. Cannot download installers automatically."
    }
    
    Write-Log "Internet connection verified" $LogFile
    Write-Host "Internet connection verified"
    Write-Host ""
    
    # Create installers directory if it doesn't exist
    if (-not (New-DirectorySafe $InstallersDir)) {
        throw "Failed to create installers directory: $InstallersDir"
    }
    
    # Check which installers are missing or need updating
    $ToDownload = @()
    $ExistingFiles = @()
    
    foreach ($Key in $Installers.Keys) {
        $Installer = $Installers[$Key]
        $FilePath = Join-Path $InstallersDir $Installer.FileName
        $ExistingFile = Get-ChildItem -Path $InstallersDir -Filter $Installer.Pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($ExistingFile -and -not $Force) {
            Write-Log "Found existing installer: $($ExistingFile.Name)" $LogFile
            $ExistingFiles += @{
                Name = $Installer.Name
                File = $ExistingFile.Name
                Size = Format-FileSize $ExistingFile.Length
            }
        } else {
            $ToDownload += @{
                Key = $Key
                Installer = $Installer
                FilePath = $FilePath
            }
        }
    }
    
    # Display status
    if ($ExistingFiles.Count -gt 0) {
        Write-Host "Existing installers found:"
        foreach ($File in $ExistingFiles) {
            Write-Host "  Found: $($File.Name): $($File.File) ($($File.Size))" -ForegroundColor Green
        }
        Write-Host ""
    }
    
    if ($ToDownload.Count -eq 0) {
        Write-Log "All required installers are already present" $LogFile
        Write-Host "All required installers are already present!" -ForegroundColor Green

        if (-not $Force) {
            Write-Host ""
            Write-Host "Use -Force parameter to re-download all installers."
            Write-Host "Continuing with existing installers..."
            exit 0
        }
    }
    
    # Show download plan
    if ($ToDownload.Count -gt 0) {
        Write-Host "Installers to download:"
        foreach ($Item in $ToDownload) {
            Write-Host "  Download: $($Item.Installer.Name): $($Item.Installer.FileName) ($($Item.Installer.Size))" -ForegroundColor Yellow
        }
        Write-Host ""
        
        # Ask for confirmation
        if (-not $Force) {
            $Response = Read-Host "Do you want to download these installers? (Y/n)"
            if ($Response -match '^[Nn]') {
                Write-Log "Download cancelled by user" $LogFile
                Write-Host "Download cancelled."
                exit 1
            }
        }
        
        Write-Host "Starting downloads..."
        Write-Host ""
    }
    
    # Download each installer
    $SuccessCount = 0
    $FailureCount = 0
    
    foreach ($Item in $ToDownload) {
        $Installer = $Item.Installer
        $FilePath = $Item.FilePath
        
        Write-Log "Downloading $($Installer.Name) from $($Installer.Url)" $LogFile
        Write-Host "Downloading $($Installer.Name)..." -ForegroundColor Cyan
        Write-Host "  Source: $($Installer.Url)"
        Write-Host "  Target: $($Installer.FileName)"
        Write-Host ""
        
        try {
            # Use PowerShell's Invoke-WebRequest with progress
            $ProgressPreference = 'Continue'
            Invoke-WebRequest -Uri $Installer.Url -OutFile $FilePath -UserAgent "PowerShell/Portable-Dev-Setup"
            
            # Verify download
            if (Test-Path $FilePath) {
                $FileInfo = Get-Item $FilePath
                $ActualSize = Format-FileSize $FileInfo.Length
                
                Write-Log "Successfully downloaded $($Installer.Name): $ActualSize" $LogFile
                Write-Host "  Downloaded successfully: $ActualSize" -ForegroundColor Green
                $SuccessCount++
            } else {
                throw "File not found after download"
            }
            
        } catch {
            $ErrorMsg = "Failed to download $($Installer.Name): $($_.Exception.Message)"
            Write-Log $ErrorMsg $LogFile
            Write-Host "  Download failed: $($_.Exception.Message)" -ForegroundColor Red
            $FailureCount++
            
            # Clean up partial download
            if (Test-Path $FilePath) {
                Remove-Item $FilePath -Force -ErrorAction SilentlyContinue
            }
        }
        
        Write-Host ""
    }
    
    # Summary
    Write-Host "============================================================================"
    if ($FailureCount -eq 0) {
        Write-Log "All downloads completed successfully" $LogFile
        Write-Host "All downloads completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Downloaded files:"
        
        # List all installer files
        $AllInstallers = Get-ChildItem -Path $InstallersDir -Include "*.msi", "*.exe" -ErrorAction SilentlyContinue
        foreach ($File in $AllInstallers) {
            $Size = Format-FileSize $File.Length
            Write-Host "  File: $($File.Name) ($Size)" -ForegroundColor Green
        }
        
    } else {
        Write-Log "Download completed with $FailureCount failures" $LogFile
        Write-Host "Download completed with issues:" -ForegroundColor Yellow
        Write-Host "  Successful: $SuccessCount"
        Write-Host "  Failed: $FailureCount"
        Write-Host ""
        Write-Host "You may need to download failed installers manually."
        Write-Host "See DOWNLOAD-LINKS.md for manual download instructions."
    }
    
    Write-Host ""
    Write-Host "You can now run install.bat to begin the installation process."
    Write-Host "============================================================================"

} catch {
    $ErrorMessage = "Installer download failed: $($_.Exception.Message)"
    Write-Log $ErrorMessage $LogFile
    Write-Error $ErrorMessage
    Write-Host ""
    Write-Host "Fallback options:"
    Write-Host "1. Check your internet connection and try again"
    Write-Host "2. Download installers manually (see DOWNLOAD-LINKS.md)"
    Write-Host "3. Use a different network or VPN if downloads are blocked"
    exit 1
}
