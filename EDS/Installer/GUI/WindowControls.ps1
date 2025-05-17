function Add-WindowControls($titleBar) {
    # Close Button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = [char]0x2715
    $closeButton.Size = New-Object System.Drawing.Size(40,25)
    $closeButton.Location = New-Object System.Drawing.Point(($form.Width - 45), 7)
    $closeButton.FlatStyle = "Flat"
    $closeButton.ForeColor = [System.Drawing.Color]::White
    $closeButton.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
    $closeButton.Add_Click({ $form.Close(); exit })
    $closeButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    $titleBar.Controls.Add($closeButton)

    # Maximize Button
    $script:maximizeButton = New-Object System.Windows.Forms.Button
    $maximizeButton.Text = [char]0x25A1
    $maximizeButton.Size = New-Object System.Drawing.Size(40,25)
    $maximizeButton.Location = New-Object System.Drawing.Point(($form.Width - 85), 7)
    $maximizeButton.FlatStyle = "Flat"
    $maximizeButton.ForeColor = [System.Drawing.Color]::White
    $maximizeButton.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
    $maximizeButton.Add_Click({
        if ($form.WindowState -eq "Maximized") {
            $form.WindowState = "Normal"
            $script:maximizeButton.Text = [char]0x25A1
        } else {
            $form.WindowState = "Maximized"
            $script:maximizeButton.Text = [char]0x25A3
        }
    })
    $maximizeButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    $titleBar.Controls.Add($maximizeButton)
}
