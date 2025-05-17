function Show-WarningPopup {
    param(
        [string]$message,
        [int]$timeout = 30
    )

    $warningForm = New-Object System.Windows.Forms.Form
    $warningForm.Text = "Warning"
    $warningForm.Size = New-Object System.Drawing.Size(500, 250)
    $warningForm.StartPosition = "CenterScreen"
    $warningForm.FormBorderStyle = "None"
    $warningForm.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
    $warningForm.TopMost = $true

    # Warning Header
    $warningHeader = New-Object System.Windows.Forms.Label
    $warningHeader.Text = "WARNING"
    $warningHeader.ForeColor = [System.Drawing.Color]::Red
    $warningHeader.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $warningHeader.TextAlign = "MiddleCenter"
    $warningHeader.Dock = "Top"
    $warningHeader.Height = 40
    $warningHeader.BackColor = [System.Drawing.Color]::FromArgb(60, 30, 30)

    # Message Panel with shadow effect
    $messagePanel = New-Object System.Windows.Forms.Panel
    $messagePanel.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $messagePanel.Dock = "Fill"
    $messagePanel.Padding = New-Object System.Windows.Forms.Padding(2)

    $warningLabel = New-Object System.Windows.Forms.Label
    $warningLabel.Text = $message
    $warningLabel.ForeColor = [System.Drawing.Color]::White
    $warningLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12)
    $warningLabel.TextAlign = "MiddleCenter"
    $warningLabel.Dock = "Fill"
    $warningLabel.Padding = New-Object System.Windows.Forms.Padding(20)

    $countdownLabel = New-Object System.Windows.Forms.Label
    $countdownLabel.Text = "Installation will start in $timeout seconds..."
    $countdownLabel.ForeColor = [System.Drawing.Color]::Yellow
    $countdownLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $countdownLabel.TextAlign = "MiddleCenter"
    $countdownLabel.Dock = "Bottom"
    $countdownLabel.Height = 40
    $countdownLabel.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)

    $messagePanel.Controls.Add($warningLabel)
    $warningForm.Controls.Add($messagePanel)
    $warningForm.Controls.Add($warningHeader)
    $warningForm.Controls.Add($countdownLabel)

    $script:remainingTime = $timeout

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000

    $timer.Add_Tick({
        $script:remainingTime--
        $countdownLabel.Text = "Installation will start in $script:remainingTime seconds..."
        if ($script:remainingTime -le 0) {
            $timer.Stop()
            $warningForm.Close()
        }
    })

    $warningForm.Add_Shown({ $timer.Start() })
    $warningForm.Add_KeyDown({
        $timer.Stop()
        $warningForm.Close()
    })
    $warningForm.Add_Click({
        $timer.Stop()
        $warningForm.Close()
    })

    $warningForm.ShowDialog()
}
