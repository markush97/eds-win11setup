function Set-DefaultUnattendedXML {
    param(
        [string]$EDSFolderName = "EDS",
        [string]$WinPeDrive = "X:"
    )
    [OutputType([xml])]
    
    [xml]$xmlDoc;

    try {
        $installDrive = Get-InstallationDrive -EDSFolderName $EDSFolderName
        if (-not $installDrive) {
            throw "Installation media not found. Please ensure the USB drive is properly connected."
        }

        # Create TEMP directory if it doesn't exist
        $tempDir = Join-Path $WinPeDrive "Temp" 
        $tempXmlPath = Join-Path $tempDir "unattended.xml"
        $script:unattendPath = $tempXmlPath
        $unattendPath = $tempXmlPath
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        $sourceXmlPath = Join-Path $installDrive "$EDSFolderName\Installer\unattended.xml"
        Write-Host "Looking for unattended.xml in $sourceXmlPath"

        if (Test-Path $sourceXmlPath) {
            Write-Host "Existing unattended.xml found, modifying it..."
            $xmlDoc = [xml](Get-Content -Path $sourceXmlPath)
        } else {
            Write-Host "No existing unattended.xml found, creating default one..."
            $xmlDoc = [xml](New-Object System.Xml.XmlDocument)
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error updating unattended.xml: $($_.Exception.Message)",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        throw "Could not load unattended XML."
    }

    # Create basic unattend structure if it doesn't exist
    if (-not $xmlDoc.DocumentElement) {
        $root = $xmlDoc.CreateElement("unattend", "urn:schemas-microsoft-com:unattend")
        # Add wcm namespace
        $wcmAttr = $xmlDoc.CreateAttribute("xmlns:wcm")
        $wcmAttr.Value = "http://schemas.microsoft.com/WMIConfig/2002/State"
        $root.Attributes.Append($wcmAttr) | Out-Null
        $xmlDoc.AppendChild($root) | Out-Null
    }

    $nsMgr = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
    $nsMgr.AddNamespace("u", "urn:schemas-microsoft-com:unattend")

    # Use correct XPath with namespace
    $settings = $xmlDoc.SelectSingleNode("//u:settings[@pass='specialize']", $nsMgr)
    if (-not $settings) {
        $settings = $xmlDoc.CreateElement("settings", "urn:schemas-microsoft-com:unattend")
        $settings.SetAttribute("pass", "specialize")
        $xmlDoc.DocumentElement.AppendChild($settings) | Out-Null  # FIX: use DocumentElement
    }

    # Create component if it doesn't exist
    $component = $settings.SelectSingleNode("u:component[@name='Microsoft-Windows-Shell-Setup']", $nsMgr)
    if (-not $component) {
        $component = $xmlDoc.CreateElement("component", "urn:schemas-microsoft-com:unattend")
        $component.SetAttribute("name", "Microsoft-Windows-Shell-Setup")
        $component.SetAttribute("processorArchitecture", "amd64")
        $component.SetAttribute("publicKeyToken", "31bf3856ad364e35")
        $component.SetAttribute("language", "neutral")
        $component.SetAttribute("versionScope", "nonSxS")
        $settings.AppendChild($component) | Out-Null
    }


    # Add RunSynchronous commands component if it doesn't exist
    $runComponent = $settings.SelectSingleNode("u:component[@name='Microsoft-Windows-Deployment']", $nsMgr)
    if (-not $runComponent) {
        $runComponent = $xmlDoc.CreateElement("component", "urn:schemas-microsoft-com:unattend")
        $runComponent.SetAttribute("name", "Microsoft-Windows-Deployment")
        $runComponent.SetAttribute("processorArchitecture", "amd64")
        $runComponent.SetAttribute("publicKeyToken", "31bf3856ad364e35")
        $runComponent.SetAttribute("language", "neutral")
        $runComponent.SetAttribute("versionScope", "nonSxS")
        $settings.AppendChild($runComponent) | Out-Null
    }

    # Create RunSynchronous element if it doesn't exist
    $runSync = $runComponent.SelectSingleNode("u:RunSynchronous", $nsMgr)
    if (-not $runSync) {
        $runSync = $xmlDoc.CreateElement("RunSynchronous", "urn:schemas-microsoft-com:unattend")
        $runComponent.AppendChild($runSync) | Out-Null
    }



    $wcmNamespaceUri = "http://schemas.microsoft.com/WMIConfig/2002/State"
    $wcmAttr = $xmlDoc.CreateAttribute("wcm", "action", $wcmNamespaceUri)
    $wcmAttr.Value = "add"

    # Add command to extract Specialize.ps1
    $extractCommand = $xmlDoc.CreateElement("RunSynchronousCommand", "urn:schemas-microsoft-com:unattend")
    $extractCommand.SetAttributeNode($wcmAttr)

    $path = $xmlDoc.CreateElement("Path", "urn:schemas-microsoft-com:unattend")
    $path.InnerText = "powershell.exe -WindowStyle Normal -NoProfile -Command `"`$xml = [xml]::new(); `$xml.Load('C:\Windows\Panther\unattend.xml'); `$sb = [scriptblock]::Create( `$xml.unattend.EDS.CopyScript ); Invoke-Command -ScriptBlock `$sb -ArgumentList $EDSFolderName;`""

    $description = $xmlDoc.CreateElement("Description", "urn:schemas-microsoft-com:unattend")
    $description.InnerText = "Execute CopySpecialize Script embedded inside unattend.xml"

    $order = $xmlDoc.CreateElement("Order", "urn:schemas-microsoft-com:unattend")
    $order.InnerText = "1"

    $extractCommand.AppendChild($path) | Out-Null
    $extractCommand.AppendChild($description) | Out-Null
    $extractCommand.AppendChild($order) | Out-Null

    $runSync.AppendChild($extractCommand) | Out-Null

    # Add command to run Specialize.ps1
    $runCommand = $xmlDoc.CreateElement("RunSynchronousCommand", "urn:schemas-microsoft-com:unattend")
    $wcmAttr2 = $xmlDoc.CreateAttribute("wcm", "action", $wcmNamespaceUri)
    $wcmAttr2.Value = "add"
    $runCommand.SetAttributeNode($wcmAttr2)

    $path = $xmlDoc.CreateElement("Path", "urn:schemas-microsoft-com:unattend")
    $path.InnerText = "powershell.exe -ExecutionPolicy Bypass -File C:\$EDSFolderName\Setup\Specialize.ps1"

    $description = $xmlDoc.CreateElement("Description", "urn:schemas-microsoft-com:unattend")
    $description.InnerText = "Execute Specialize-Script"

    $order = $xmlDoc.CreateElement("Order", "urn:schemas-microsoft-com:unattend")
    $order.InnerText = "2"

    $runCommand.AppendChild($path) | Out-Null
    $runCommand.AppendChild($description) | Out-Null
    $runCommand.AppendChild($order) | Out-Null

    $runSync.AppendChild($runCommand) | Out-Null

    # Create EDS element if it doesn't exist
    $eds = $xmlDoc.DocumentElement.SelectSingleNode("EDS")  # FIX: use DocumentElement
    if (-not $eds) {
        $eds = $xmlDoc.CreateElement("EDS", "https://eds.cwi.at")
        $xmlDoc.DocumentElement.AppendChild($eds) | Out-Null
    }

    # Add CopyScript section inside EDS
    $copyScript = $xmlDoc.CreateElement("CopyScript",$eds.NamespaceURI)
    $copyScript.InnerText = Get-Content -Path "$installDrive\$EDSFolderName\Installer\Functions\CopySpecialize.ps1" -Raw
    $eds.AppendChild($copyScript) | Out-Null

    # When saving, ensure XML declaration is present
    $xmlWriterSettings = New-Object System.Xml.XmlWriterSettings
    $xmlWriterSettings.Indent = $true
    $xmlWriterSettings.Encoding = [System.Text.Encoding]::UTF8
    $xmlWriterSettings.OmitXmlDeclaration = $false
    $xmlWriter = [System.Xml.XmlWriter]::Create($tempXmlPath, $xmlWriterSettings)
    $xmlDoc.save($xmlWriter)
    $xmlWriter.Close()
    [xml]$script:unattendXml = Get-Content -Path $tempXmlPath -Raw
}

function Set-UnattendedDeviceName {
    param (
        [Parameter(Mandatory=$true)]
        [xml]$xmlDoc,
        [Parameter(Mandatory=$true)]
        [string]$deviceName
    )

    $nsMgr = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
    $nsMgr.AddNamespace("u", "urn:schemas-microsoft-com:unattend") | Out-Null

    # Get the component from the XML document
    $component = $xmlDoc.SelectSingleNode("//u:settings[@pass='specialize']/u:component[@name='Microsoft-Windows-Shell-Setup']", $nsMgr)
    if (-not $component) {
        Write-Warning "Required component not found in XML"
        return $false
    }

    # Create or update ComputerName element
    $computerName = $component.SelectSingleNode("u:ComputerName", $nsMgr)
    if (-not $computerName) {
        $computerName = $xmlDoc.CreateElement("ComputerName", "urn:schemas-microsoft-com:unattend")
        $component.AppendChild($computerName) | Out-Null
    }
    $computerName.InnerText = $deviceName

    $xmlDoc.save($script:unattendPath)
    return $true
}


function Set-UnattendedUserInput {
    param (
        [Parameter(Mandatory=$true)]
        [xml]$xmlDoc,
        [Parameter(Mandatory=$true)]
        [Hashtable]$UserInput
    )

    Write-Host "Saving userInput..."

    $nsMgr = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
    $nsMgr.AddNamespace("u", "urn:schemas-microsoft-com:unattend")
    $nsMgr.AddNamespace("e", "https://eds.cwi.at")

    # Query the <EDS> node using XPath with the correct namespace
    $eds = $xmlDoc.SelectSingleNode("//e:EDS", $nsMgr)

    # Add or update settings under EDS
    $userInputBlock = $eds.SelectSingleNode("UserInput")
    if (-not $userInputBlock) {
        $userInputBlock = $xmlDoc.CreateElement("UserInput", $eds.NamespaceURI)
        $eds.AppendChild($userInputBlock)  | Out-Null
    }

    # Iterate through the UserInput hashtable and create elements
    foreach ($key in $UserInput.Keys) {
        $value = $UserInput[$key]

        # Check if the element already exists
        $element = $userInputBlock.SelectSingleNode($key)
        if (-not $element) {
            $element = $xmlDoc.CreateElement($key, $eds.NamespaceURI)
            $userInputBlock.AppendChild($element)  | Out-Null
        }
        $element.InnerText = $value
    }

    try {
        $xmlDoc.save($script:unattendPath)
    } catch {
        Write-Warning "Failed to save XML: $_"
        return $false
    }
}

Export-ModuleMember -Function *