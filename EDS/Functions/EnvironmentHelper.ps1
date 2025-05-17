function Get-InstallationDrive {
    # Get all drives and find the actual iso by checking for eds.cfg
    $drives = Get-PSDrive -PSProvider FileSystem
    foreach ($drive in $drives) {
        $path = Join-Path $drive.Root "EDS\eds.cfg"
        if (Test-Path $path) {
            return $drive.Root
        }
    }
    return $null
}

function Copy-CustomData {
    $installDrive = Get-InstallationDrive
    Copy-Item -Path (Join-Path "$installDrive" "EDS") -Destination "X:" -Recurse

}
