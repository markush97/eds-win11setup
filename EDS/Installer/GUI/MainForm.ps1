. $PSScriptRoot\TitleBar.ps1
. $PSScriptRoot\Footer.ps1
. $PSScriptRoot\ContentPanel.ps1
. $PSScriptRoot\WindowControls.ps1

function Initialize-MainForm {

    $script:form = New-Object System.Windows.Forms.Form
    $form.Text = "ImagingToolbox"
    $form.Size = New-Object System.Drawing.Size(800,600)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
    $form.TopMost = $true
    $form.FormBorderStyle = "None"
    $form.WindowState = "Maximized"  # Set initial state to maximized

    Add-TitleBar
    Add-Footer
    Add-ContentPanel
    Add-DragFunctionality

    return $form
}
