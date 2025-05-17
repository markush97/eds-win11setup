# Start.ps1
# This script launches the main installer GUI

$installerPath = Join-Path $PSScriptRoot 'Installer\Install.ps1'
if (-not (Test-Path $installerPath)) {
    Write-Host "Installer script not found: $installerPath"
    exit 1
}

# Forward any arguments to Install.ps1
& $installerPath @args
