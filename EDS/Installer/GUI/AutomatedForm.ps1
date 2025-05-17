. $PSScriptRoot\TitleBar.ps1
. $PSScriptRoot\Footer.ps1
. $PSScriptRoot\WindowControls.ps1

function Set-JobIdText {
    param (
        [string]$jobId
    )
    if ($script:jobIdLabel) {
        $script:jobIdLabel.Text = "Job ID: $jobId"
        [System.Windows.Forms.Application]::DoEvents()
    }
}

function Set-JobNameText {
    param (
        [string]$JobName
    )
    if ($script:jobNameLabel) {
        $script:jobNameLabel.Text = "Job Name: $JobName"
        [System.Windows.Forms.Application]::DoEvents()
    }
}

function Set-Infotext {
    param (
        [string]$text
    )
    if ($script:infoLabel) {
        $script:infoLabel.Text = $text
        [System.Windows.Forms.Application]::DoEvents()
    }
}

function Set-ProgressBar {
    param (
        [int]$value
    )
    if ($script:progressBar) {
        $script:progressBar.Value = $value
        [System.Windows.Forms.Application]::DoEvents()
    }
}

function Initialize-AutomatedForm {

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
    Add-DragFunctionality

    $contentPanel = New-Object System.Windows.Forms.Panel
    $contentPanel.Dock = "Fill"
    $contentPanel.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
    $contentPanel.Padding = New-Object System.Windows.Forms.Padding(20)
    $form.Controls.Add($contentPanel)

    $formContainer = New-Object System.Windows.Forms.Panel
    $formContainer.Size = New-Object System.Drawing.Size(500, 220)
    $formContainer.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
    $formContainer.Padding = New-Object System.Windows.Forms.Padding(20)
    $contentPanel.Controls.Add($formContainer)
    $centerX = [Math]::Floor(($contentPanel.ClientSize.Width - $formContainer.Width) / 2)
    $centerY = [Math]::Floor(($contentPanel.ClientSize.Height - $formContainer.Height) / 2)
    $formContainer.Location = New-Object System.Drawing.Point($centerX, $centerY)
    $formContainer.Anchor = [System.Windows.Forms.AnchorStyles]::None

    $headerLabel = New-Object System.Windows.Forms.Label
    $headerLabel.Text = "Automated Enrollment"
    $headerLabel.ForeColor = [System.Drawing.Color]::LightBlue
    $headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $headerLabel.Location = New-Object System.Drawing.Point(20, 10)
    $headerLabel.AutoSize = $true
    $formContainer.Controls.Add($headerLabel)

    # Add jobId label (initially empty)
    $jobIdLabel = New-Object System.Windows.Forms.Label
    $jobIdLabel.Text = "Job ID: "
    $jobIdLabel.ForeColor = [System.Drawing.Color]::LightGray
    $jobIdLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
    $jobIdLabel.Location = New-Object System.Drawing.Point(20, 40)
    $jobIdLabel.Size = New-Object System.Drawing.Size(440, 20)
    $formContainer.Controls.Add($jobIdLabel)
    $script:jobIdLabel = $jobIdLabel

    # Add jobName label (initially empty)
    $jobNameLabel = New-Object System.Windows.Forms.Label
    $jobNameLabel.Text = "Job Name: "
    $jobNameLabel.ForeColor = [System.Drawing.Color]::LightGray
    $jobNameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
    $jobNameLabel.Location = New-Object System.Drawing.Point(20, 60)
    $jobNameLabel.Size = New-Object System.Drawing.Size(440, 20)
    $formContainer.Controls.Add($jobNameLabel)
    $script:jobNameLabel = $jobNameLabel

    $infoLabel = New-Object System.Windows.Forms.Label
    $infoLabel.Text = "Starting setup..."
    $infoLabel.ForeColor = [System.Drawing.Color]::White
    $infoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $infoLabel.Location = New-Object System.Drawing.Point(20, 85)
    $infoLabel.Size = New-Object System.Drawing.Size(440, 40)
    $infoLabel.TextAlign = 'MiddleLeft'
    $formContainer.Controls.Add($infoLabel)
    $script:infoLabel = $infoLabel  # <-- Make infoLabel accessible to Set-Infotext

    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Style = 'Marquee'
    $progressBar.MarqueeAnimationSpeed = 30
    $progressBar.Size = New-Object System.Drawing.Size(440, 20)
    $progressBar.Location = New-Object System.Drawing.Point(20, 110)
    $formContainer.Controls.Add($progressBar)
    $script:progressBar = $progressBar  # <-- Make progressBar accessible to Set-ProgressBar

    $progressBar.Style = 'Continuous'   
    $progressBar.Value = 0
    $progressBar.Maximum = 15

    $skipButton = New-Object System.Windows.Forms.Button
    $skipButton.Text = "Start Manual Configuration"
    $skipButton.Size = New-Object System.Drawing.Size(250, 35)
    $skipButton.Location = New-Object System.Drawing.Point(120, 150)
    $skipButton.BackColor = [System.Drawing.Color]::FromArgb(76,175,80)
    $skipButton.ForeColor = [System.Drawing.Color]::White
    $skipButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $skipButton.FlatStyle = "Flat"
    $skipButton.Cursor = "Hand"
    $skipButton.Add_Click({
        $form.Tag = 'skip'
        $form.Close()
    })
    $formContainer.Controls.Add($skipButton)

    $form.Show()
    [System.Windows.Forms.Application]::DoEvents()

    return $form
}
