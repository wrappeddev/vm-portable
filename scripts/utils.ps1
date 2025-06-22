# ============================================================================
# Utility Functions for Portable Dev Setup
# ============================================================================
# This file contains common utility functions used across all installation
# scripts for logging, error handling, and other shared functionality.
# ============================================================================

# Function to write timestamped log entries
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [string]$LogFile
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] $Message"

    # Write to console
    Write-Host $LogEntry

    # Write to log file
    try {
        # Skip logging if path is invalid
        if ([string]::IsNullOrWhiteSpace($LogFile) -or $LogFile -match '[<>:"|?*]') {
            return
        }

        # Ensure the log directory exists
        $LogDir = Split-Path $LogFile -Parent
        if ($LogDir -and -not (Test-Path $LogDir)) {
            New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
        }

        # Use simple path resolution
        if (-not [System.IO.Path]::IsPathRooted($LogFile)) {
            $LogFile = Join-Path (Get-Location) $LogFile
        }

        $LogEntry | Out-File -FilePath $LogFile -Append -Encoding UTF8
    } catch {
        # Silently fail for logging issues to avoid disrupting the main process
        # Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
}

# Function to check if running as administrator
function Test-Administrator {
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to refresh environment variables
function Update-EnvironmentPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Function to test if a command exists
function Test-Command {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CommandName
    )
    
    return (Get-Command $CommandName -ErrorAction SilentlyContinue) -ne $null
}

# Function to wait for a file to exist (useful after installations)
function Wait-ForFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [int]$TimeoutSeconds = 30,
        [int]$CheckIntervalSeconds = 1
    )
    
    $ElapsedTime = 0
    
    while (-not (Test-Path $FilePath) -and $ElapsedTime -lt $TimeoutSeconds) {
        Start-Sleep -Seconds $CheckIntervalSeconds
        $ElapsedTime += $CheckIntervalSeconds
    }
    
    return Test-Path $FilePath
}

# Function to safely create directory
function New-DirectorySafe {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        try {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            return $true
        } catch {
            Write-Warning "Failed to create directory ${Path}: $($_.Exception.Message)"
            return $false
        }
    }
    return $true
}

# Function to backup a file with timestamp
function Backup-File {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [string]$BackupDir = $null
    )
    
    if (-not (Test-Path $FilePath)) {
        return $null
    }
    
    $FileInfo = Get-Item $FilePath
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    if ($BackupDir) {
        $BackupPath = Join-Path $BackupDir "$($FileInfo.BaseName)_$Timestamp$($FileInfo.Extension)"
    } else {
        $BackupPath = "$FilePath.backup_$Timestamp"
    }
    
    try {
        Copy-Item $FilePath $BackupPath -Force
        return $BackupPath
    } catch {
        Write-Warning "Failed to backup file ${FilePath}: $($_.Exception.Message)"
        return $null
    }
}

# Function to download file with progress
function Download-File {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [string]$UserAgent = "PowerShell/Portable-Dev-Setup"
    )
    
    try {
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.Add("User-Agent", $UserAgent)
        
        # Register progress event
        Register-ObjectEvent -InputObject $WebClient -EventName DownloadProgressChanged -Action {
            $Global:DownloadProgress = $Event.SourceEventArgs.ProgressPercentage
            Write-Progress -Activity "Downloading" -Status "$($Global:DownloadProgress)% Complete" -PercentComplete $Global:DownloadProgress
        } | Out-Null
        
        $WebClient.DownloadFile($Url, $OutputPath)
        $WebClient.Dispose()
        
        Write-Progress -Activity "Downloading" -Completed
        return $true
        
    } catch {
        Write-Warning "Failed to download ${Url}: $($_.Exception.Message)"
        return $false
    }
}

# Function to verify file hash
function Test-FileHash {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [string]$ExpectedHash,
        
        [string]$Algorithm = "SHA256"
    )
    
    if (-not (Test-Path $FilePath)) {
        return $false
    }
    
    try {
        $FileHash = Get-FileHash -Path $FilePath -Algorithm $Algorithm
        return $FileHash.Hash -eq $ExpectedHash.ToUpper()
    } catch {
        Write-Warning "Failed to calculate hash for ${FilePath}: $($_.Exception.Message)"
        return $false
    }
}

# Function to get system information
function Get-SystemInfo {
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem
    $CPU = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $Memory = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    
    return @{
        OSName = $OS.Caption
        OSVersion = $OS.Version
        OSArchitecture = $OS.OSArchitecture
        CPUName = $CPU.Name
        CPUCores = $CPU.NumberOfCores
        TotalMemoryGB = [Math]::Round($Memory.Sum / 1GB, 2)
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    }
}

# Function to check internet connectivity
function Test-InternetConnection {
    param(
        [string]$TestUrl = "https://www.google.com",
        [int]$TimeoutSeconds = 10
    )

    try {
        # Try multiple methods for better reliability
        $Request = [System.Net.WebRequest]::Create($TestUrl)
        $Request.Timeout = $TimeoutSeconds * 1000
        $Response = $Request.GetResponse()
        $Response.Close()
        return $true
    } catch {
        # Fallback: try ping to a reliable DNS server
        try {
            $PingResult = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
            return $PingResult
        } catch {
            return $false
        }
    }
}

# Function to format file size
function Format-FileSize {
    param(
        [Parameter(Mandatory=$true)]
        [long]$SizeInBytes
    )
    
    $Sizes = @("B", "KB", "MB", "GB", "TB")
    $Index = 0
    $Size = $SizeInBytes
    
    while ($Size -ge 1024 -and $Index -lt $Sizes.Length - 1) {
        $Size = $Size / 1024
        $Index++
    }
    
    return "{0:N2} {1}" -f $Size, $Sizes[$Index]
}

# Function to clean up temporary files
function Clear-TempFiles {
    param(
        [string]$Pattern = "*portable-dev-setup*"
    )
    
    try {
        $TempFiles = Get-ChildItem -Path $env:TEMP -Filter $Pattern -ErrorAction SilentlyContinue
        foreach ($File in $TempFiles) {
            Remove-Item $File.FullName -Force -Recurse -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Warning "Failed to clean up temporary files: $($_.Exception.Message)"
    }
}

# Function to validate installer file
function Test-InstallerFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [string]$ExpectedExtension
    )
    
    if (-not (Test-Path $FilePath)) {
        return @{
            Valid = $false
            Message = "File not found: $FilePath"
        }
    }
    
    $FileInfo = Get-Item $FilePath
    
    if ($FileInfo.Extension.ToLower() -ne $ExpectedExtension.ToLower()) {
        return @{
            Valid = $false
            Message = "Invalid file extension. Expected: $ExpectedExtension, Got: $($FileInfo.Extension)"
        }
    }
    
    if ($FileInfo.Length -eq 0) {
        return @{
            Valid = $false
            Message = "File is empty: $FilePath"
        }
    }
    
    return @{
        Valid = $true
        Message = "File is valid"
        Size = Format-FileSize $FileInfo.Length
    }
}
