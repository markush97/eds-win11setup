# Hacky workaround till a real config-system is in place
param (
    [switch]$DryRun = $false,
    [string]$WinPeDrive = "X:",
    [string]$EDSFolderName = "EDS"
)

$script:EDSFolderName = $EDSFolderName
$script:EDSTitle = $EDSFolderName
$script:DryRun = $DryRun
$script:WinPeDrive

if ($DryRun -eq $true) {
    Write-Host "Starting installer in DryRun Mode"
}
Write-Host EDS-Folder is $script:EDSFolderName

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Import Forms
. $PSScriptRoot\GUI\LoadingScreen.ps1
. $PSScriptRoot\GUI\WarningPopup.ps1
. $PSScriptRoot\GUI\MainForm.ps1

# Show loading screen
Write-Host "Starting WinPe Initialization Process..."
$loadingForm = Initialize-LoadingForm
Show-LoadingScreen -message "Initializing Windows PE..." -parentForm $loadingForm | out-null
$loadingForm.Show()
$loadingForm.Update()

if ($DryRun -ne $true) {
    # Initialize WinPE
    Start-Process "wpeinit.exe" -Wait
    Start-Sleep -Seconds 2
} else {
    Write-Host "Skipping WPEInit because of Dry-Run"
}

# Close loading form
$loadingForm.Close()
$loadingForm.Dispose()

Write-Host "Init done, starting actual installer..."

# Initialize and show the form
$mainForm = Initialize-MainForm -DryRun $DryRun
$mainForm.ShowDialog()
