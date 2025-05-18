function Set-UnattendedDeviceName {
    param (
        [Parameter(Mandatory=$true)]
        [xml]$xmlDoc,
        [Parameter(Mandatory=$true)]
        [string]$deviceName
    )

    # Create basic unattend structure if it doesn't exist
    if (-not $xmlDoc.DocumentElement) {
        $xmlDoc.AppendChild($xmlDoc.CreateElement("unattend"))
    }

    if (-not $xmlDoc.unattend.xmlns) {
        $xmlDoc.DocumentElement.SetAttribute("xmlns", "urn:schemas-microsoft-com:unattend")
    }

    # Create settings pass if it doesn't exist
    $settings = $xmlDoc.SelectSingleNode("settings[@pass='specialize']")
    if (-not $settings) {
        $settings = $xmlDoc.CreateElement("settings")
        $settings.SetAttribute("pass", "specialize")
        $xmlDoc.unattend.AppendChild($settings)
    }

    # Create component if it doesn't exist
    $component = $settings.SelectSingleNode("component[@name='Microsoft-Windows-Shell-Setup']")
    if (-not $component) {
        $component = $xmlDoc.CreateElement("component")
        $component.SetAttribute("name", "Microsoft-Windows-Shell-Setup")
        $component.SetAttribute("processorArchitecture", "amd64")
        $component.SetAttribute("publicKeyToken", "31bf3856ad364e35")
        $component.SetAttribute("language", "neutral")
        $component.SetAttribute("versionScope", "nonSxS")
        $settings.AppendChild($component)
    }

    # Create or update ComputerName element
    $computerName = $component.SelectSingleNode("ComputerName")
    if (-not $computerName) {
        $computerName = $xmlDoc.CreateElement("ComputerName")
        $component.AppendChild($computerName)
    }
    $computerName.InnerText = $deviceName

    # Add RunSynchronous commands component if it doesn't exist
    $runComponent = $settings.SelectSingleNode("component[@name='Microsoft-Windows-Deployment']")
    if (-not $runComponent) {
        $runComponent = $xmlDoc.CreateElement("component")
        $runComponent.SetAttribute("name", "Microsoft-Windows-Deployment")
        $runComponent.SetAttribute("processorArchitecture", "amd64")
        $runComponent.SetAttribute("publicKeyToken", "31bf3856ad364e35")
        $runComponent.SetAttribute("language", "neutral")
        $runComponent.SetAttribute("versionScope", "nonSxS")
        $settings.AppendChild($runComponent)
    }

    # Create RunSynchronous element if it doesn't exist
    $runSync = $runComponent.SelectSingleNode("RunSynchronous")
    if (-not $runSync) {
        $runSync = $xmlDoc.CreateElement("RunSynchronous")
        $runComponent.AppendChild($runSync)
    }

    # Add command to exctract Specialize.ps1
    $extractCommand = $xmlDoc.CreateElement("RunSynchronousCommand")
    $extractCommand.SetAttribute("wcm:action", "add")

    $path = $xmlDoc.CreateElement("Path")
    $path.InnerText = "powershell.exe -WindowStyle Normal -NoProfile -Command `"`$xml = [xml]::new(); `$xml.Load('C:\Windows\Panther\unattend.xml'); `$sb = [scriptblock]::Create( `$xml.unattend.CopyScript ); Invoke-Command -ScriptBlock `$sb -ArgumentList $script:EDSFolderName;`""

    $description = $xmlDoc.CreateElement("Description")
    $description.InnerText = "Execute CopySpecialize Script embedded inside unattend.xml"

    $order = $xmlDoc.CreateElement("Order")
    $order.InnerText = "1"

    $extractCommand.AppendChild($path)
    $extractCommand.AppendChild($description)
    $extractCommand.AppendChild($order)

    $runSync.AppendChild($extractCommand)

    # Add command to run Specialize.ps1
    $runCommand = $xmlDoc.CreateElement("RunSynchronousCommand")
    $runCommand.SetAttribute("wcm:action", "add")

    $path = $xmlDoc.CreateElement("Path")
    $path.InnerText = "powershell.exe -ExecutionPolicy Bypass -File C:\$script:EDSFolderName\Setup\Specialize.ps1"

    $description = $xmlDoc.CreateElement("Description")
    $description.InnerText = "Execute Specialize-Script"

    $order = $xmlDoc.CreateElement("Order")
    $order.InnerText = "2"

    $runCommand.AppendChild($path)
    $runCommand.AppendChild($description)
    $runCommand.AppendChild($order)

    $runSync.AppendChild($runCommand)

    # Add CopyScript section
    $copyScript = $xmlDoc.CreateElement("CopyScript","https://eds.cwi.at")
    $copyScript.InnerText = Get-Content -Path "$script:WinPeDrive\$script:EDSFolderName\Functions\CopySpecialize.ps1" -Raw
    $xmlDoc.unattend.AppendChild($copyScript)
}

function Update-UnattendedXML {
    param(
        [Parameter(Mandatory=$true)]
        [string]$deviceName
    )

    try {
        $installDrive = Get-InstallationDrive
        if (-not $installDrive) {
            throw "Installation media not found. Please ensure the USB drive is properly connected."
        }

        # Create TEMP directory if it doesn't exist
        $tempDir = Join-Path $PSScriptRoot "..\TEMP"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }

        $sourceXmlPath = Join-Path $installDrive "$script:EDSFolderName\unattended.xml"
        $tempXmlPath = Join-Path $tempDir "unattended.xml"

        if (Test-Path $sourceXmlPath) {
            $xmlContent = [xml](Get-Content -Path $sourceXmlPath)
        } else {
            $xmlContent = [xml](New-Object System.Xml.XmlDocument)
        }

        # Create or update the XML structure
        Set-UnattendedDeviceName -xmlDoc $xmlContent -deviceName $deviceName

        # Save the updated XML
        $xmlContent.Save($tempXmlPath)

        Write-Host "Successfully updated computer name in temporary unattended.xml"
        return $true
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error updating unattended.xml: $($_.Exception.Message)",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }
}
