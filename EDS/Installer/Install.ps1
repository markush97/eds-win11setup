# Hacky workaround till a real config-system is in place
param (
    [switch]$DryRun = $false,
    [string]$WinPeDrive = "X:",
    [string]$EDSFolderName = "CWI"
)

$script:EDSFolderName = $EDSFolderName
$script:EDSTitle = $EDSFolderName
$script:DryRun = $DryRun
$script:WinPeDrive

Import-Module "$PSScriptRoot\Functions\Shared\job-utils.psm1" -Force
Import-Module "$PSScriptRoot\Functions\Shared\device-utils.psm1" -Force
Import-Module "$PSScriptRoot\Functions\Shared\unattended-utils.psm1" -Force
Import-Module "$PSScriptRoot\Functions\Shared\environment-utils.psm1" -Force
Import-Module "$PSScriptRoot\Functions\Automated\install-automated.psm1" -Force

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if ($DryRun -eq $true) {
    Write-Host "Starting installer in DryRun Mode"
}
Write-Host EDS-Folder is $script:EDSFolderName

# Read EDS configuration file before any UI or WinPE logic
$configPath = Join-Path $PSScriptRoot '..\eds.cfg'
$EDSConfig = @{}
if (Test-Path $configPath) {
    foreach ($line in Get-Content $configPath) {
        if ($line -match '^(\s*#|//)') { continue } # skip comments
        if ($line -match '^(.*?)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Split('#')[0].Trim() # remove inline comment
            $EDSConfig[$key] = $value
        }
    }
}

$EDS_Server = $EDSConfig['EDS-Server']
$NetworkInstallMode = $EDSConfig['NetworkInstallMode']

# Import GUI and Function scripts early so all functions are available
. $PSScriptRoot\GUI\WarningPopup.ps1
. $PSScriptRoot\GUI\MainForm.ps1
. $PSScriptRoot\Functions\ConfigurationHandler.ps1
. $PSScriptRoot\Functions\Logger.ps1

# Import Loading Forms
. $PSScriptRoot\GUI\LoadingScreen.ps1


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

# Some sleep to ensure WPE is ready
Start-Sleep -Milliseconds 500
# Close loading form
$loadingForm.Close()
$loadingForm.Dispose()

Write-Host "Updating unattend.xml Template with default values..."
Set-DefaultUnattendedXML -EDSFolderName $script:EDSFolderName -WinPeDrive $WinPeDrive

if ($NetworkInstallMode -eq 'auto') {
    Write-Host "Automated network install from server $EDS_Server selected."
    Write-Host "Starting automated installation..."
    
    try {
        Install-Automated -EDS_Server $EDS_Server -DryRun:($DryRun) -WinPeDrive $WinPeDrive -EDSFolderName $EDSFolderName
    } catch {
        Write-Host "ERROR: Exception during Install-Automated: $($_.Exception.Message)"
    }
    
    return
}

Write-Host "Init done, starting actual installer..."
# Initialize and show the form
$mainForm = Initialize-MainForm -DryRun $DryRun
Write-Host "Showing form..."
$mainForm.ShowDialog()

# Use config values
$EDS_Server = $EDSConfig['EDS-Server']
$NetworkInstallMode = $EDSConfig['NetworkInstallMode']
