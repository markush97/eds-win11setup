. $PSScriptRoot\WindowControls.ps1

function Add-TitleBar {
    $titleBar = New-Object System.Windows.Forms.Panel
    $titleBar.Size = New-Object System.Drawing.Size($form.Width, 40)
    $titleBar.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
    $titleBar.Dock = "Top"

    # Logo Image
    $logo = New-Object System.Windows.Forms.PictureBox
    $logo.Size = New-Object System.Drawing.Size(24,24)
    $logo.Location = New-Object System.Drawing.Point(10, 8)
    $logo.SizeMode = "StretchImage"

    # Try to load the logo, skip if not found
    $logoPath = Join-Path $PSScriptRoot "logo.png"
    if (Test-Path $logoPath) {
        try {
            $logo.Image = [System.Drawing.Image]::FromFile($logoPath)
            $titleBar.Controls.Add($logo)
        } catch {
            Write-Warning "Could not load logo image: $_"
        }
    }

    # PowerShell Logo text
    $logoText = New-Object System.Windows.Forms.Label
    $logoText.Text = "CWI Imaging-Toolbox"
    $logoText.ForeColor = [System.Drawing.Color]::LightBlue
    $logoText.Font = New-Object System.Drawing.Font("Consolas", 12)
    $logoText.Location = New-Object System.Drawing.Point(44,10)
    $logoText.AutoSize = $true
    $titleBar.Controls.Add($logoText)
    # Window Control Buttons
    Add-WindowControls $titleBar

    $script:form.Controls.Add($titleBar)
    $script:titleBar = $titleBar

    Add-DragFunctionality
}

function Add-DragFunctionality {
    $script:dragging = $false
    $script:dragStartX = 0
    $script:dragStartY = 0
    $script:formStartX = 0
    $script:formStartY = 0

    $titleBar.Add_MouseDown({
        if ($form.WindowState -eq "Maximized") {
            return
        }
        $script:dragging = $true
        $script:dragStartX = [System.Windows.Forms.Cursor]::Position.X
        $script:dragStartY = [System.Windows.Forms.Cursor]::Position.Y
        $script:formStartX = $form.Left
        $script:formStartY = $form.Top
    })

    $titleBar.Add_MouseMove({
        if ($script:dragging) {
            $deltaX = [System.Windows.Forms.Cursor]::Position.X - $script:dragStartX
            $deltaY = [System.Windows.Forms.Cursor]::Position.Y - $script:dragStartY

            if ($form.WindowState -eq "Maximized") {
                # Calculate the relative position for restoration
                $ratio = [System.Windows.Forms.Cursor]::Position.X / $form.Width
                $form.WindowState = "Normal"
                $form.Left = [System.Windows.Forms.Cursor]::Position.X - ($form.Width * $ratio)
                $form.Top = [System.Windows.Forms.Cursor]::Position.Y - 20

                # Update drag start positions
                $script:dragStartX = [System.Windows.Forms.Cursor]::Position.X
                $script:dragStartY = [System.Windows.Forms.Cursor]::Position.Y
                $script:formStartX = $form.Left
                $script:formStartY = $form.Top
            } else {
                $form.Left = $script:formStartX + $deltaX
                $form.Top = $script:formStartY + $deltaY
            }
        }
    })

    $titleBar.Add_MouseUp({
        $script:dragging = $false
    })

    # Double-click to maximize/restore
    $titleBar.Add_MouseDoubleClick({
        if ($form.WindowState -eq "Maximized") {
            $form.WindowState = "Normal"
            $script:maximizeButton.Text = [char]0x25A1
        } else {
            $form.WindowState = "Maximized"
            $script:maximizeButton.Text = [char]0x25A3
        }
    })
}
