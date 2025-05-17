# Define Endpoint for Server
$uri = "https://eds.cwi.at/api"
# Path to configuration file
$configPath = "C:\CWI\Windows\deviceconfig.json"
# Token Path
$tokenPath = "C:\ProgramData\CWI\device.token"

Write-Host "Starting Automated enrollment..."

New-Item -ItemType Directory C:\CWI\Logs\Setup -Force
& $PSScriptRoot\manual.ps1

function Get-UserInput {
 # Load the XML file

    $xmlPath = "C:\Windows\Panther\unattend.xml"
    [xml]$xmlDoc = Get-Content $xmlPath

    # Set up namespaces
    $nsMgr = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
    $nsMgr.AddNamespace("u", "urn:schemas-microsoft-com:unattend")
    $nsMgr.AddNamespace("e", "https://eds.cwi.at")

    # Navigate to the <UserInput> block
    $userInputBlock = $xmlDoc.SelectSingleNode("//e:EDS/e:UserInput", $nsMgr)

    # Create a hashtable to store the key-value pairs
    $userInputData = @{}

    # Only proceed if the block exists
    if ($userInputBlock) {
        foreach ($child in $userInputBlock.ChildNodes) {
            $userInputData[$child.Name] = $child.InnerText
        }
    }

    # Output the result
    $userInputData
    [xml]$xmlDoc = Get-Content $xmlPath

    # Set up namespaces
    $nsMgr = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
    $nsMgr.AddNamespace("u", "urn:schemas-microsoft-com:unattend")
    $nsMgr.AddNamespace("e", "https://eds.cwi.at")

    # Navigate to the <UserInput> block
    $userInputBlock = $xmlDoc.SelectSingleNode("//e:EDS/e:UserInput", $nsMgr)

    # Create a hashtable to store the key-value pairs
    $userInputData = @{}

    # Only proceed if the block exists
    if ($userInputBlock) {
        foreach ($child in $userInputBlock.ChildNodes) {
            $userInputData[$child.Name] = $child.InnerText
        }
    }

    return $userInputData
}

function Get-AssetTag {
    $userInput = Get-UserInput
    return $userInput.AssetTag | Select-Object -First 1
}

function Get-InstalledBy {
    $userInput = Get-UserInput
    return $userInput.InstalledBy | Select-Object -First 1
}

function Get-OperatingSystemNotes {
    $os = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $version = $os.DisplayVersion
    $build = "$($os.CurrentBuild).$($os.UBR)"
    return "$version Build: $build"
}

function Get-SystemInformation {
    [CmdletBinding()]
    param()

    $bitlockerInfo = Get-Bitlockerinfo

    try {
        # Create system info object
        $systemInfo = [PSCustomObject]@{
            name = Get-HostName
            model = Get-DeviceModel
            manufacturer = Get-Manufacturer
            networkInterfaces = Get-NetworkInterfaces
            operatingSystem = Get-OperatingSystem
            operatingSystemNotes = Get-OperatingSystemNotes
            assetTag = Get-AssetTag
            installedBy = Get-InstalledBy;
            bitlockerId = $bitlockerInfo.KeyProtectorId | Select-Object -First 1
            bitlockerKey = $bitlockerInfo.RecoveryPassword | Select-Object -First 1
	    deviceType = "PC"
        }

        return $systemInfo
    }
    catch {
        Write-Error "Error collecting system information: $_"
        throw
    }
}

function Get-Bitlockerinfo {
	[CmdletBinding()]
	param()

	try {
	  $bitlockerVolume = Get-BitLockerVolume -MountPoint "C:"
	  $bitlockerInfo = $bitlockerVolume.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" } | Select-Object @{Name='KeyProtectorId';Expression={ $_.KeyProtectorId -replace '[{}]' }},RecoveryPassword

          return $bitlockerInfo
    } catch {
       	Write-Warning "Error retrieving BitlockerInfo: $_"
       	return "Unknown"
    }
}

function Get-HostName {
    [CmdletBinding()]
    param()

    try {
        return [System.Net.Dns]::GetHostName()
    }
    catch {
        Write-Warning "Error retrieving hostname: $_"
        return "Unknown"
    }
}

function Get-DeviceType {
    [CmdletBinding()]
    param()

    try {
        $chassisType = Get-CimInstance -ClassName Win32_SystemEnclosure | Select-Object -ExpandProperty ChassisTypes

        # Reference: https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-systemenclosure
        switch ($chassisType[0]) {
            # Laptops/Notebooks
            {$_ -in 8..14 -or $_ -eq 30 -or $_ -eq 31 -or $_ -eq 32} { return "Laptop" }

            # Servers
            {$_ -in 17..24 -or $_ -eq 4} { return "Server" }

            # Desktops
            {$_ -in 3, 5, 6, 7, 15, 16} { return "PC" }

            # Default
            default {
                # Additional check for server OS
                if ((Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -ne 1) {
                    return "Server"
                }
                return "PC"
            }
        }
    }
    catch {
        Write-Warning "Error determining device type: $_"
        return "Unknown"
    }
}

function Get-SerialNumber {
    [CmdletBinding()]
    param()

    try {
        $serial = Get-CimInstance -ClassName Win32_BIOS | Select-Object -ExpandProperty SerialNumber
        return $serial.Trim()
    }
    catch {
        Write-Warning "Error retrieving serial number: $_"
        return "Unknown"
    }
}

function Get-DeviceModel {
    [CmdletBinding()]
    param()

    try {
        $model = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Model
        return $model.Trim()
    }
    catch {
        Write-Warning "Error retrieving device model: $_"
        return "Unknown"
    }
}

function Get-Manufacturer {
    [CmdletBinding()]
    param()

    try {
        $manufacturer = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Manufacturer
	$manufacturer = $manufacturer.Substring(0,1).ToUpper() + $manufacturer.Substring(1).ToLower()
        return $manufacturer.Trim()
    }
    catch {
        Write-Warning "Error retrieving manufacturer: $_"
        return "Unknown"
    }
}

function Get-NetworkInterfaces {
    [CmdletBinding()]
    param()

    try {
        $interfaces = @()

        $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter |
                           Where-Object { $_.PhysicalAdapter -eq $true -and $_.MACAddress -ne $null }

        foreach ($adapter in $networkAdapters) {
            $interfaceInfo = [PSCustomObject]@{
                Name = $adapter.Name
                MacAddress = $adapter.MACAddress
                AdapterType = $adapter.AdapterType
                Status = $adapter.NetConnectionStatus
            }

            $interfaces += $interfaceInfo
        }

        return $interfaces
    }
    catch {
        Write-Warning "Error retrieving network interfaces: $_"
        return @()
    }
}

function Get-OperatingSystem {
    [CmdletBinding()]
    param()

    try {
        $caption = (Get-CimInstance Win32_OperatingSystem).Caption
        $cleanCaption = $caption -replace '^Microsoft ', ''
	return $cleanCaption
    }
    catch {
        Write-Warning "Error retrieving operating system: $_"
        return "Unknown"
    }
}

function Get-PlatformArchitecture {
    [CmdletBinding()]
    param()

    try {
        $arch = (Get-CimInstance -ClassName Win32_Processor)[0].Architecture

        switch ($arch) {
            0 { $archName = "x86" }
            5 { $archName = "ARM" }
            9 { $archName = "x64" }
            12 { $archName = "ARM64" }
            default { $archName = "Unknown" }
        }

        # Additional check for AMD vs Intel
        $processorManufacturer = (Get-CimInstance -ClassName Win32_Processor)[0].Manufacturer

        if ($processorManufacturer -like "*AMD*") {
            return "AMD $archName"
        }
        elseif ($processorManufacturer -like "*Intel*") {
            return "Intel $archName"
        }
        else {
            return $archName
        }
    }
    catch {
        Write-Warning "Error retrieving platform architecture: $_"
        return "Unknown"
    }
}

function Run-SubFunctions {
    [CmdletBinding()]
    param()

        Get-ChildItem -Path . -Recurse -Filter 'install.ps1' | ForEach-Object {
        if ($_.FullName -eq "C:\CWI\Windows\install.ps1") {
            return
        }

        Write-Host "Executing: $($_.FullName)"
        try {
            cd $_.Directory
            & $_.FullName
            cd "C:\CWI\Windows"
        } catch {
            Write-Host "Error executing $($_.FullName): $_"
        }
    }
}

function Register-Device {
    [CmdletBinding()]
    param(
	[Parameter(Mandatory=$true)]
	[pscustomobject]$registerInfo,
	[Parameter(Mandatory=$true)]
	[string]$uri
)


    try {
	    Write-Host "Registering device with $uri/jobs/register"
        $response = Invoke-RestMethod -Uri "$uri/jobs/register" -Method POST -Headers $headers -Body $registerInfo
	New-Item "C:\ProgramData\CWI" -Force -ItemType Directory | Out-Null

        $deviceToken = $response.deviceToken

        # Check if token matches the expected format
        if ($deviceToken -match '^[a-zA-Z0-9_\-=+/]{20,}$') {
            # Save the token
            $deviceToken | Set-Content -Path $tokenPath -Encoding UTF8

	# Secure the token file (Administrators only)
	$acl = Get-ACL $tokenPath

	# Break inheritence and delete inherited rules
	$acl.SetAccessRuleProtection($true, $false)

	$identity = "VORDEFINIERT\Administratoren"

	# Create the access rule
	$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, "Read", "Allow")
	## Original
	$acl.SetAccessRule($rule)

	Set-Acl -Path $tokenPath -AclObject $acl
            return $response.jobId
        }
        else {
            Write-Error "Invalid token format received: $response"
            exit 1
        }
    }
    catch {
        Write-Error "Request failed: $_"
        exit 1
    }
}


#### SCRIPT BEGIN

# Ensure script is run as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator."
    Exit 1
}

# Check for config file
if (-Not (Test-Path $configPath)) {
    Write-Error "Configuration file not found at $configPath"
    Exit 1
}

# Load and parse JSON
try {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Failed to parse JSON: $_"
    Exit 1
}

# Extract values
$desiredName = $config.DeviceName
$domainName = $config.DomainName
$domainUser = $config.DomainUser
$domainPassword = $config.DomainPassword
$ouPath = $config.OU
$organisationId = $config.OrganisationId

# Validate required values
if (-not $desiredName -or -not $domainName -or -not $domainUser -or -not $domainPassword) {
    Write-Error "Missing required fields in config file."
    Exit 1
}

$registerInfo = @{
 "organizationId" = $organisationId;
 "deviceSerial" = (Get-WmiObject -Class Win32_BIOS).SerialNumber;
 "deviceName" = (Get-WmiObject -Class Win32_ComputerSystem).Name
 "deviceType" = "PC"
}

# Register device-setup process
$jobId = Register-Device -registerInfo $registerInfo -Uri "$uri"

# Check domain join status
$alreadyJoined = (Get-WmiObject Win32_ComputerSystem).PartOfDomain
if (-not $alreadyJoined) {

    # Prepare secure credentials
    $securePassword = ConvertTo-SecureString $domainPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($domainUser, $securePassword)

    # Rename-Computer -NewName $desiredName -Force

    # Join domain with or without OU
    if ($ouPath -and $ouPath -ne "") {
        Add-Computer -DomainName $domainName -Credential $credential -OUPath $ouPath -Force
    } else {
        Add-Computer -DomainName $domainName -Credential $credential -Force
    }

} else {
    Write-Host "Device is already domain-joined. Skipping rename and join."
}

Run-SubFunctions

Write-Host "Uploading System information..."
# Collect system info
$sysInfo = Get-SystemInformation | ConvertTo-Json -Depth 5
$deviceToken = Get-Content $tokenPath
$headers = @{
    "Content-Type"    = "application/json"
    "X-Device-Token"  = $deviceToken
}
# Upload JSON data to API
try {
    $sysInfo
    Invoke-RestMethod -Uri "$uri/devices/info" -Method PUT -Headers $headers -Body $sysInfo
    Write-Host "System info successfully uploaded."
    Invoke-RestMethod -Uri "$uri/jobs/notify/$jobId`?jobStatus=done" -Method POST -Headers $headers

    Remove-Item -Path "C:\Windows\Panther" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Setup" -Recurse -Force -ErrorAction SilentlyContinue	

    # Final reboot to apply changes
    Restart-Computer -Force
}
catch {
    Write-Error "Failed to upload system information: $_"
}
