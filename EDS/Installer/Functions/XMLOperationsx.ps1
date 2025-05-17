# Functions/XMLOperations.ps1
function Set-DefaultUnattendedXML {
    [OutputType([xml])]

    [xml]$xmlDoc;
    [string]$tempXmlPath

    try {
        $installDrive = Get-InstallationDrive
        if (-not $installDrive) {
            throw "Installation media not found. Please ensure the USB drive is properly connected."
        }

        # Create TEMP directory if it doesn't exist
        $tempDir = Join-Path $PSScriptRoot "..\TEMP"
        $tempXmlPath = Join-Path $tempDir "unattended.xml"
        $script:unattendPath = $tempXmlPath
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        $sourceXmlPath = Join-Path $installDrive "$script:EDSFolderName\Installer\unattended.xml"

        if (Test-Path $sourceXmlPath) {
            Write-Host "Existing unattended.xml found, modifying it..."
            $xmlDoc = [xml](Get-Content -Path $sourceXmlPath)
        } else {
            Write-Host "No existing unattended.xml found, creating new one..."
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
        $xmlDoc.AppendChild($root) | Out-Null
    }

    $nsMgr = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
    $nsMgr.AddNamespace("u", "urn:schemas-microsoft-com:unattend")

    # Use correct XPath with namespace
    $settings = $xmlDoc.SelectSingleNode("//u:settings[@pass='specialize']", $nsMgr)
    if (-not $settings) {
        $settings = $xmlDoc.CreateElement("settings", "urn:schemas-microsoft-com:unattend")
        $settings.SetAttribute("pass", "specialize")
        $xmlDoc.unattend.AppendChild($settings) | Out-Null
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
    #$extractCommand = $xmlDoc.CreateElement("RunSynchronousCommand", "urn:schemas-microsoft-com:unattend")
    #$extractCommand.SetAttributeNode($wcmAttr)

    #$path = $xmlDoc.CreateElement("Path", "urn:schemas-microsoft-com:unattend")
    #$path.InnerText = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Normal -NoProfile -Command `"`$xml = [xml]::new(); `$xml.Load('C:\Windows\Panther\unattend.xml'); `$sb = [scriptblock]::Create( `$xml.unattend.EDS.CopyScript ); Invoke-Command -ScriptBlock `$sb -ArgumentList $script:EDSFolderName;`""

    #$description = $xmlDoc.CreateElement("Description", "urn:schemas-microsoft-com:unattend")
    #$description.InnerText = "Execute CopySpecialize Script embedded inside unattend.xml"

    #$order = $xmlDoc.CreateElement("Order", "urn:schemas-microsoft-com:unattend")
    #$order.InnerText = "1"

    #[void]$extractCommand.AppendChild($path)
    #[void]$extractCommand.AppendChild($description)
    #[void]$extractCommand.AppendChild($order)

    #[void]$runSync.AppendChild($extractCommand)

    # Add command to run Specialize.ps1
    #$runCommand = $xmlDoc.CreateElement("RunSynchronousCommand", "urn:schemas-microsoft-com:unattend")
    #$runCommand.SetAttributeNode($wcmAttr)

    #$path = $xmlDoc.CreateElement("Path", "urn:schemas-microsoft-com:unattend")
    #$path.InnerText = "powershell.exe -ExecutionPolicy Bypass -File C:\$script:EDSFolderName\Setup\Specialize.ps1"

    #$description = $xmlDoc.CreateElement("Description", "urn:schemas-microsoft-com:unattend")
    #$description.InnerText = "Execute Specialize-Script"

    #$order = $xmlDoc.CreateElement("Order", "urn:schemas-microsoft-com:unattend")
    #$order.InnerText = "2"

    #$runCommand.AppendChild($path)
    #$runCommand.AppendChild($description)
    #$runCommand.AppendChild($order)

    #$runSync.AppendChild($runCommand)



    # Create EDS element if it doesn't exist
    $eds = $xmlDoc.unattend.SelectSingleNode("EDS")
    if (-not $eds) {
        $eds = $xmlDoc.CreateElement("EDS", "https://eds.cwi.at")
        [void]$xmlDoc.unattend.AppendChild($eds)
    }

    # Add CopyScript section inside EDS
    $copyScript = $xmlDoc.CreateElement("CopyScript",$eds.NamespaceURI)
    $copyScript.InnerText = Get-Content -Path "$script:WinPeDrive\$script:EDSFolderName\Installer\Functions\CopySpecialize.ps1" -Raw
    [void]$eds.AppendChild($copyScript)

    $xmlDoc.Save($tempXmlPath)
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
    $nsMgr.AddNamespace("u", "urn:schemas-microsoft-com:unattend")

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
        [void]$component.AppendChild($computerName)
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
        [void]$eds.AppendChild($userInputBlock)
    }

    # Iterate through the UserInput hashtable and create elements
    foreach ($key in $UserInput.Keys) {
        $value = $UserInput[$key]

        # Check if the element already exists
        $element = $userInputBlock.SelectSingleNode($key)
        if (-not $element) {
            $element = $xmlDoc.CreateElement($key, $eds.NamespaceURI)
            [void]$userInputBlock.AppendChild($element)
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
