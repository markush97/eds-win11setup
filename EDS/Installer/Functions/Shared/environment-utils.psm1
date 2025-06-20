function Get-InstallationDrive {
    param(
        [string]$EDSFolderName = "EDS"
    )
    # Get all drives and find the actual iso by checking for eds.cfg
    $drives = Get-PSDrive -PSProvider FileSystem
    Write-Host "Looking for '$EDSFolderName\eds.cfg' in all drives"
    foreach ($drive in $drives) {
        $path = Join-Path $drive.Root "$EDSFolderName\eds.cfg"
        if (Test-Path $path) {
            Write-Host "Found installation media on drive: $($drive.Name)"
            return $drive.Root
        }
    }
    return $null
}

function Copy-CustomData {
     param (
        [Parameter(Mandatory=$true)]
        [string]$targetPath,
        [string]$EDSFolderName = "EDS"
    )
    $installDrive = Get-InstallationDrive -EDSFolderName $EDSFolderName

    if (-not $installDrive) {
        throw "Installation media not found"
    }

    # Create target directory on system drive
    New-Item -Path (Join-Path $targetPath $EDSFolderName) -ItemType Directory -Force | Out-Null
    # Copy EDS folder to system drive
    Copy-Item -Path (Join-Path $installDrive "$EDSFolderName\*") -Destination (Join-Path $targetPath $EDSFolderName) -Recurse -Force
}
