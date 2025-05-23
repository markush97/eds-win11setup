function Get-InstallationDrive {
    # Get all drives and find the actual iso by checking for eds.cfg
    $drives = Get-PSDrive -PSProvider FileSystem
    Write-Host "Looking for '$script:EDSFolderName\eds.cfg' in all drives"
    foreach ($drive in $drives) {
        $path = Join-Path $drive.Root "$script:EDSFolderName\eds.cfg"
        if (Test-Path $path) {
            return $drive.Root
        }
    }
    return $null
}

function Copy-CustomData {
     param (
        [Parameter(Mandatory=$true)]
        [string]$targetPath
    )
    $installDrive = Get-InstallationDrive

    if (-not $installDrive) {
        throw "Installation media not found"
    }

        # Create target directory on system drive
    New-Item -Path (Join-Path $targetPath $script:EDSFolderName) -ItemType Directory -Force | Out-Null
    # Copy CWI folder to system drive
    Copy-Item -Path (Join-Path $installDrive "$script:EDSFolderName\*") -Destination (Join-Path $targetPath $script:EDSFolderName) -Recurse -Force

}
