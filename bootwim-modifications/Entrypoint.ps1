$EDSFolderName = "EDS"

function Get-InstallationDrive {
    Write-Host "Detecting installation media..."
    $drives = Get-PSDrive -PSProvider FileSystem
    foreach ($drive in $drives) {
        $path = Join-Path $drive.Root "$EDSFolderName\eds.cfg"
        if (Test-Path $path) {
            Write-Host "Installation media found at $($drive.Root)"
            return $drive.Root
        }
    }
    Write-Host "No installation media found"
    return $null
}

Write-Host "Starting Custom Windows-Installer"
$installDrive = Get-InstallationDrive

if ($null -ne $installDrive) {
    Write-Host "Copying custom-data into current system..."
    try {
        # Start the GUI
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$installDrive\$EDSFolderName\Start.ps1`"" -WorkingDirectory "$installDrive\$EDSFolderName" -NoNewWindow -Wait

    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForeColor Red
        exit 1
    }
}
else {
    Write-Host "Error: Installation media not found, starting default setup" -ForeColor Red
    # Start Windows Setup
    Start-Process -FilePath "X:\Setup.exe" -Wait

}
