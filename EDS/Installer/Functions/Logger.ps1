function Initialize-Logger {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogPath,
        [string]$LogName = "EDS",
        [switch]$IncludeDebug = $false
    )

    # Create log directory if it doesn't exist
    if (-not (Test-Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }

    # Set script-level variables
    $script:logFile = Join-Path $LogPath "$LogName-$(Get-Date -Format 'yyyy-MM-dd').log"
    $script:includeDebug = $IncludeDebug
    $script:logName = $LogName

    Write-EDSLog "Logging initialized. Log file: $script:logFile" -Level "Info"
}

function Write-EDSLog {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]$Level = "Info",

        [Parameter()]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter()]
        [switch]$NoConsole
    )

    # Skip debug messages if debug logging is disabled
    if ($Level -eq "Debug" -and -not $script:includeDebug) {
        return
    }

    # Build timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"

    # Build log entry
    $logEntry = "[$timestamp] [$Level] $Message"

    # Add error details if provided
    if ($ErrorRecord) {
        $errorDetails = @(
            "Exception: $($ErrorRecord.Exception.Message)"
            "Script: $($ErrorRecord.InvocationInfo.ScriptName)"
            "Line: $($ErrorRecord.InvocationInfo.ScriptLineNumber)"
            "Position: $($ErrorRecord.InvocationInfo.OffsetInLine)"
            "Stack Trace: $($ErrorRecord.ScriptStackTrace)"
        ) -join "`n    "

        $logEntry += "`n    $errorDetails"
    }

    # Write to file
    try {
        Add-Content -Path $script:logFile -Value $logEntry -ErrorAction Stop
    }
    catch {
        # If writing to file fails, write error to console
        Write-Host "Failed to write to log file: $_" -ForegroundColor Red
    }

    # Write to console if not suppressed
    if (-not $NoConsole) {
        $color = switch ($Level) {
            "Info"    { "White" }
            "Warning" { "Yellow" }
            "Error"   { "Red" }
            "Debug"   { "Gray" }
            default   { "White" }
        }

        Write-Host $logEntry -ForegroundColor $color
    }
}

function Get-EDSLogPath {
    return $script:logFile
}
