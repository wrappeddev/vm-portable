# ============================================================================
# Development Tools Uninstaller Script
# ============================================================================
# This script uninstalls existing development tools to prepare for a clean
# installation and avoid conflicts.
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$LogFile
)

# Import utility functions
. "$PSScriptRoot\utils.ps1"

Write-Log "Starting development tools uninstallation..." $LogFile

Write-Host "============================================================================"
Write-Host "Development Tools Uninstaller"
Write-Host "============================================================================"
Write-Host ""
Write-Host "This will attempt to uninstall existing development tools:"
Write-Host "- Node.js"
Write-Host "- Rust (rustup)"
Write-Host "- Git for Windows"
Write-Host "- GitHub CLI"
Write-Host ""
Write-Host "WARNING: This will remove these tools and their configurations!"
Write-Host "Make sure you have backed up any important configurations."
Write-Host ""

$Confirm = Read-Host "Are you sure you want to proceed? (yes/no)"
if ($Confirm -ne "yes") {
    Write-Log "Uninstallation cancelled by user" $LogFile
    Write-Host "Uninstallation cancelled."
    exit 0
}

Write-Host ""
Write-Host "Starting uninstallation process..."
Write-Host ""

$UninstallErrors = 0

# Function to uninstall via Windows Programs and Features
function Uninstall-Program {
    param(
        [string]$DisplayName,
        [string]$ProductCode = $null
    )
    
    try {
        Write-Host "Attempting to uninstall: $DisplayName"
        Write-Log "Attempting to uninstall: $DisplayName" $LogFile
        
        if ($ProductCode) {
            # Use product code if available
            $Process = Start-Process -FilePath "msiexec" -ArgumentList @("/x", $ProductCode, "/quiet", "/norestart") -Wait -PassThru -NoNewWindow
            if ($Process.ExitCode -eq 0) {
                Write-Host "  Successfully uninstalled: $DisplayName" -ForegroundColor Green
                Write-Log "Successfully uninstalled: $DisplayName" $LogFile
                return $true
            }
        }
        
        # Try to find and uninstall via registry
        $UninstallKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        
        foreach ($Key in $UninstallKeys) {
            $Programs = Get-ItemProperty $Key -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$DisplayName*" }
            
            foreach ($Program in $Programs) {
                if ($Program.UninstallString) {
                    Write-Host "  Found: $($Program.DisplayName)"
                    
                    # Parse uninstall string
                    $UninstallString = $Program.UninstallString
                    if ($UninstallString -match 'msiexec') {
                        # MSI uninstall
                        if ($UninstallString -match '/I\{([^}]+)\}') {
                            $ProductGuid = $matches[1]
                            $Process = Start-Process -FilePath "msiexec" -ArgumentList @("/x", "{$ProductGuid}", "/quiet", "/norestart") -Wait -PassThru -NoNewWindow
                        }
                    } else {
                        # EXE uninstall
                        $UninstallString = $UninstallString -replace '"', ''
                        if ($UninstallString -match '^(.+\.exe)(.*)$') {
                            $ExePath = $matches[1]
                            $Args = $matches[2].Trim()
                            if ($Args) {
                                $Process = Start-Process -FilePath $ExePath -ArgumentList "$Args /S" -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue
                            } else {
                                $Process = Start-Process -FilePath $ExePath -ArgumentList "/S" -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue
                            }
                        }
                    }
                    
                    if ($Process -and $Process.ExitCode -eq 0) {
                        Write-Host "  Successfully uninstalled: $($Program.DisplayName)" -ForegroundColor Green
                        Write-Log "Successfully uninstalled: $($Program.DisplayName)" $LogFile
                        return $true
                    }
                }
            }
        }
        
        Write-Host "  Could not find or uninstall: $DisplayName" -ForegroundColor Yellow
        Write-Log "Could not find or uninstall: $DisplayName" $LogFile
        return $false
        
    } catch {
        Write-Host "  Error uninstalling $DisplayName`: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error uninstalling $DisplayName`: $($_.Exception.Message)" $LogFile
        return $false
    }
}

# Uninstall Node.js
Write-Host "1. Uninstalling Node.js..."
if (-not (Uninstall-Program "Node.js")) {
    $UninstallErrors++
}

# Uninstall Rust (rustup)
Write-Host ""
Write-Host "2. Uninstalling Rust..."
try {
    $RustupPath = Get-Command "rustup" -ErrorAction SilentlyContinue
    if ($RustupPath) {
        Write-Host "  Found rustup, running self-uninstall..."
        $Process = Start-Process -FilePath "rustup" -ArgumentList @("self", "uninstall", "-y") -Wait -PassThru -NoNewWindow
        if ($Process.ExitCode -eq 0) {
            Write-Host "  Successfully uninstalled Rust" -ForegroundColor Green
            Write-Log "Successfully uninstalled Rust via rustup" $LogFile
        } else {
            Write-Host "  Rustup self-uninstall failed" -ForegroundColor Yellow
            Write-Log "Rustup self-uninstall failed" $LogFile
            $UninstallErrors++
        }
    } else {
        Write-Host "  Rust/rustup not found in PATH" -ForegroundColor Yellow
        Write-Log "Rust/rustup not found in PATH" $LogFile
    }
} catch {
    Write-Host "  Error uninstalling Rust: $($_.Exception.Message)" -ForegroundColor Red
    Write-Log "Error uninstalling Rust: $($_.Exception.Message)" $LogFile
    $UninstallErrors++
}

# Uninstall Git for Windows
Write-Host ""
Write-Host "3. Uninstalling Git for Windows..."
if (-not (Uninstall-Program "Git")) {
    $UninstallErrors++
}

# Uninstall GitHub CLI
Write-Host ""
Write-Host "4. Uninstalling GitHub CLI..."
if (-not (Uninstall-Program "GitHub CLI")) {
    $UninstallErrors++
}

# Clean up remaining files and registry entries
Write-Host ""
Write-Host "5. Cleaning up remaining files..."

$CleanupPaths = @(
    "${env:ProgramFiles}\nodejs",
    "${env:ProgramFiles(x86)}\nodejs",
    "${env:ProgramFiles}\Git",
    "${env:ProgramFiles(x86)}\Git",
    "${env:ProgramFiles}\GitHub CLI",
    "${env:ProgramFiles(x86)}\GitHub CLI",
    "${env:USERPROFILE}\.cargo",
    "${env:USERPROFILE}\.rustup",
    "${env:APPDATA}\npm",
    "${env:APPDATA}\GitHub CLI"
)

foreach ($Path in $CleanupPaths) {
    if (Test-Path $Path) {
        try {
            Write-Host "  Removing: $Path"
            Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Removed directory: $Path" $LogFile
        } catch {
            Write-Host "  Could not remove: $Path" -ForegroundColor Yellow
            Write-Log "Could not remove: $Path - $($_.Exception.Message)" $LogFile
        }
    }
}

# Clean up PATH environment variable
Write-Host ""
Write-Host "6. Cleaning up PATH environment variable..."
try {
    $CurrentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $PathsToRemove = @(
        "${env:ProgramFiles}\nodejs",
        "${env:ProgramFiles(x86)}\nodejs", 
        "${env:ProgramFiles}\Git\bin",
        "${env:ProgramFiles(x86)}\Git\bin",
        "${env:ProgramFiles}\GitHub CLI\bin",
        "${env:ProgramFiles(x86)}\GitHub CLI\bin",
        "${env:USERPROFILE}\.cargo\bin"
    )
    
    $NewPath = $CurrentPath
    foreach ($PathToRemove in $PathsToRemove) {
        $NewPath = $NewPath -replace [regex]::Escape($PathToRemove + ";"), ""
        $NewPath = $NewPath -replace [regex]::Escape(";" + $PathToRemove), ""
        $NewPath = $NewPath -replace [regex]::Escape($PathToRemove), ""
    }
    
    if ($NewPath -ne $CurrentPath) {
        [System.Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
        Write-Host "  PATH environment variable cleaned" -ForegroundColor Green
        Write-Log "PATH environment variable cleaned" $LogFile
    } else {
        Write-Host "  No PATH cleanup needed" -ForegroundColor Green
    }
} catch {
    Write-Host "  Error cleaning PATH: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Log "Error cleaning PATH: $($_.Exception.Message)" $LogFile
}

# Summary
Write-Host ""
Write-Host "============================================================================"
if ($UninstallErrors -eq 0) {
    Write-Host "Uninstallation completed successfully!" -ForegroundColor Green
    Write-Log "Uninstallation completed successfully" $LogFile
} else {
    Write-Host "Uninstallation completed with $UninstallErrors errors." -ForegroundColor Yellow
    Write-Host "Some tools may need to be uninstalled manually." -ForegroundColor Yellow
    Write-Log "Uninstallation completed with $UninstallErrors errors" $LogFile
}

Write-Host ""
Write-Host "Note: You may need to restart your command prompt to see PATH changes."
Write-Host "============================================================================"

if ($UninstallErrors -gt 0) {
    exit 1
} else {
    exit 0
}
