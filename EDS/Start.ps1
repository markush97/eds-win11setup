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

# Initialize WinPE
Start-Process "wpeinit.exe" -Wait
Start-Sleep -Seconds 2

# Close loading form
$loadingForm.Close()
$loadingForm.Dispose()

Write-Host "Init done, starting actual installer..."


# Initialize and show main form
# Initialize and show the form
$mainForm = Initialize-MainForm
$mainForm.ShowDialog()
