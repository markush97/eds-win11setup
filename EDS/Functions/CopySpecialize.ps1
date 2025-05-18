
# !IMPORTANT: This file has to work as a standalone script without any imports since only itself is copied at first!

param(
    [string] $EDSFolderName
)

try {
    $drives = Get-PSDrive -PSProvider FileSystem
    Write-Host "Looking for '$EDSFolderName\eds.cfg' in all drives"
    foreach ($drive in $drives) {
        $path = Join-Path $drive.Root "$EDSFolderName\eds.cfg"
        if (Test-Path $path) {
            Write-Host "Found installation-drive on drive $($drive.Root)"
            New-Item -Path (Join-Path "C:" $EDSFolderName) -ItemType Directory -Force | Out-Null
             # Copy Custom folder to system drive
            Copy-Item -Path (Join-Path $drive "$EDSFolderName\*") -Destination (Join-Path "C:" $EDSFolderName) -Recurse -Force

            Write-Host "Successfully copied Custom data to installed OS"
            Exit 0
        }
    }

} catch {
    Write-Error "Failed to copy Custom data: $_"
    Exit 1
}
