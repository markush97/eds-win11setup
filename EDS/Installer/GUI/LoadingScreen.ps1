function Show-LoadingScreen {
    param(
        [string]$message = "Initializing...",
        [System.Windows.Forms.Form]$parentForm
    )

    Write-Host "Showing loading screen with message: $message"

    $loadingPanel = New-Object System.Windows.Forms.Panel
    $loadingPanel.Dock = "Fill"
    $loadingPanel.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)

    # Create a container for centered content
    $centerContainer = New-Object System.Windows.Forms.Panel
    $centerContainer.Size = New-Object System.Drawing.Size(400, 200)
    $centerContainer.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
    $centerContainer.Padding = New-Object System.Windows.Forms.Padding(20)

    # Center the container
    $centerX = [Math]::Floor(($parentForm.ClientSize.Width - $centerContainer.Width) / 2)
    $centerY = [Math]::Floor(($parentForm.ClientSize.Height - $centerContainer.Height) / 2)
    $centerContainer.Location = New-Object System.Drawing.Point($centerX, $centerY)
    $centerContainer.Anchor = [System.Windows.Forms.AnchorStyles]::None

    # Loading icon (spinning animation)
    $spinnerLabel = New-Object System.Windows.Forms.Label
    $spinnerLabel.Text = "Please wait..."
    $spinnerLabel.ForeColor = [System.Drawing.Color]::LightBlue
    $spinnerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 24)
    $spinnerLabel.TextAlign = "MiddleCenter"
    $spinnerLabel.Dock = "Top"
    $spinnerLabel.Height = 60

    # Loading message
    $loadingLabel = New-Object System.Windows.Forms.Label
    $loadingLabel.Text = $message
    $loadingLabel.ForeColor = [System.Drawing.Color]::White
    $loadingLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14)
    $loadingLabel.TextAlign = "MiddleCenter"
    $loadingLabel.Dock = "Fill"

    # Add controls to container
    $centerContainer.Controls.Add($loadingLabel)
    $centerContainer.Controls.Add($spinnerLabel)
    $loadingPanel.Controls.Add($centerContainer)

    # Add resize handler to keep container centered
    $loadingPanel.Add_Resize({
        if ($centerContainer -and $loadingPanel) {
            $centerX = [Math]::Floor(($parentForm.ClientSize.Width - $centerContainer.Width) / 2)
            $centerY = [Math]::Floor(($parentForm.ClientSize.Height - $centerContainer.Height) / 2)
            $centerContainer.Location = New-Object System.Drawing.Point($centerX, $centerY)
        }
    })

    $parentForm.Controls.Add($loadingPanel)
    return $loadingPanel
}

function Remove-LoadingScreen {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Panel]$loadingPanel
    )

    if ($loadingPanel) {
        $loadingPanel.Parent.Controls.Remove($loadingPanel)
        $loadingPanel.Dispose()
    }
}

function Initialize-LoadingForm {
    $loadingForm = New-Object System.Windows.Forms.Form
    $loadingForm.Size = New-Object System.Drawing.Size(500, 300)
    $loadingForm.StartPosition = "CenterScreen"
    $loadingForm.FormBorderStyle = "None"
    $loadingForm.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
    $loadingForm.TopMost = $true

    return $loadingForm

}
