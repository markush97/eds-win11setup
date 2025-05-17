function Add-Footer {
    $footer = New-Object System.Windows.Forms.Label
    $footer.Text = "M. Hinkel @ CWI"
    $footer.ForeColor = [System.Drawing.Color]::Gray
    $footer.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $footer.AutoSize = $true
    $footer.Location = New-Object System.Drawing.Point(($form.Width - 150), ($form.Height - 30))
    $footer.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $script:form.Controls.Add($footer)
}