function Add-ContentPanel {
    $contentPanel = New-Object System.Windows.Forms.Panel
    $contentPanel.Dock = "Fill"
    $contentPanel.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
    $contentPanel.Padding = New-Object System.Windows.Forms.Padding(20)

    # Create a container panel for the form elements
    $formContainer = New-Object System.Windows.Forms.Panel
    $formContainer.Size = New-Object System.Drawing.Size(400, 300)  # Increased height for new button
    $formContainer.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
    $formContainer.Padding = New-Object System.Windows.Forms.Padding(20)

    # Add the container to the content panel first
    $contentPanel.Controls.Add($formContainer)

    # Now center the form container after it's added to the panel
    $centerX = [Math]::Floor(($contentPanel.ClientSize.Width - $formContainer.Width) / 2)
    $centerY = [Math]::Floor(($contentPanel.ClientSize.Height - $formContainer.Height) / 2)
    $formContainer.Location = New-Object System.Drawing.Point($centerX, $centerY)

    # Update the container's anchor to keep it centered
    $formContainer.Anchor = [System.Windows.Forms.AnchorStyles]::None

    # Device Name Header
    $headerLabel = New-Object System.Windows.Forms.Label
    $headerLabel.Text = "Device Configuration"
    $headerLabel.ForeColor = [System.Drawing.Color]::LightBlue
    $headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $headerLabel.Location = New-Object System.Drawing.Point(20, 20)
    $headerLabel.AutoSize = $true
    $formContainer.Controls.Add($headerLabel)

    # Device Name Label
    $deviceLabel = New-Object System.Windows.Forms.Label
    $deviceLabel.Text = "Enter the device name below:"
    $deviceLabel.ForeColor = [System.Drawing.Color]::White
    $deviceLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $deviceLabel.Location = New-Object System.Drawing.Point(20, 60)
    $deviceLabel.AutoSize = $true
    $formContainer.Controls.Add($deviceLabel)

    # Device Name TextBox
    $script:deviceTextBox = New-Object System.Windows.Forms.TextBox
    $deviceTextBox.Location = New-Object System.Drawing.Point(20, 90)
    $deviceTextBox.Size = New-Object System.Drawing.Size(300, 25)
    $deviceTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $deviceTextBox.BackColor = [System.Drawing.Color]::FromArgb(60,60,60)
    $deviceTextBox.ForeColor = [System.Drawing.Color]::White
    $formContainer.Controls.Add($deviceTextBox)

    # Submit Button
    $submitButton = New-Object System.Windows.Forms.Button
    $submitButton.Text = "Apply Device Name"
    $submitButton.Location = New-Object System.Drawing.Point(20, 130)
    $submitButton.Size = New-Object System.Drawing.Size(150, 30)
    $submitButton.FlatStyle = "Flat"
    $submitButton.BackColor = [System.Drawing.Color]::FromArgb(0,122,204)
    $submitButton.ForeColor = [System.Drawing.Color]::White
    $submitButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $submitButton.Cursor = "Hand"
    $submitButton.Add_Click({
        Set-DeviceName $script:deviceTextBox.Text
    })
    $formContainer.Controls.Add($submitButton)

    # Installation Button
    $script:installButton = New-Object System.Windows.Forms.Button
    $installButton.Text = "Start Custom Installation"
    $installButton.Location = New-Object System.Drawing.Point(20, 180)
    $installButton.Size = New-Object System.Drawing.Size(300, 35)
    $installButton.FlatStyle = "Flat"
    $installButton.BackColor = [System.Drawing.Color]::FromArgb(76,175,80)
    $installButton.ForeColor = [System.Drawing.Color]::White
    $installButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $installButton.Cursor = "Hand"
    $installButton.Enabled = $false # Initially disabled
    $installButton.Add_Click({
        Start-Installation
    })
    $formContainer.Controls.Add($installButton)

    # Standard Windows Installation Button
    $standardInstallButton = New-Object System.Windows.Forms.Button
    $standardInstallButton.Text = "Standard Windows Installation"
    $standardInstallButton.Location = New-Object System.Drawing.Point(20, 230)
    $standardInstallButton.Size = New-Object System.Drawing.Size(300, 35)
    $standardInstallButton.FlatStyle = "Flat"
    $standardInstallButton.BackColor = [System.Drawing.Color]::FromArgb(100,100,100)
    $standardInstallButton.ForeColor = [System.Drawing.Color]::White
    $standardInstallButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $standardInstallButton.Cursor = "Hand"
    $standardInstallButton.Add_Click({
        Start-StandardInstallation
    })
    $formContainer.Controls.Add($standardInstallButton)

    $script:form.Controls.Add($contentPanel)

    # Add resize event handler to keep the container centered
    $contentPanel.Add_Resize({
        if ($formContainer -and $contentPanel) {
            $centerX = [Math]::Floor(($contentPanel.ClientSize.Width - $formContainer.Width) / 2)
            $centerY = [Math]::Floor(($contentPanel.ClientSize.Height - $formContainer.Height) / 2)
            $formContainer.Location = New-Object System.Drawing.Point($centerX, $centerY)
        }
    })
}

function Set-DeviceName {
    param($deviceName)
    if ([string]::IsNullOrWhiteSpace($deviceName)) {
        $script:installButton.Enabled = $false
        return
    }

    $success = Update-UnattendedXML -deviceName $deviceName
    $script:installButton.Enabled = $success
}

function Start-Installation {
    if ([string]::IsNullOrWhiteSpace($script:deviceTextBox.Text)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please set a device name before starting the installation.",
            "Validation Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }

    # Show warning after loading screen
    Show-WarningPopup -message "Warning: This will erase all data on the target device. The installation will begin automatically in 30 seconds. Press any key to cancel." -timeout 30

    # Close the GUI form since setup is now visible
    $script:form.Close()

    Write-Host "Starting installation process for device: $($script:deviceTextBox.Text)"
    Start-Process -FilePath "X:\setup.exe" -ArgumentList "/unattend:X:\${global:$EDSFolderName}\TEMP\unattended.xml" -NoNewWindow -WindowStyle Normal
}

function Start-StandardInstallation {
    # Close the GUI form
    $script:form.Close()
    Start-Process -FilePath "X:\Setup.exe"

}
