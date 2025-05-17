function Get-DeviceType {
    [CmdletBinding()]
    param()

    try {
        $chassisType = Get-CimInstance -ClassName Win32_SystemEnclosure | Select-Object -ExpandProperty ChassisTypes

        # Reference: https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-systemenclosure
        switch ($chassisType[0]) {
            # Laptops/Notebooks
            {$_ -in 8..14 -or $_ -eq 30 -or $_ -eq 31 -or $_ -eq 32} { return "NB" }

            # Servers
            {$_ -in 17..24 -or $_ -eq 4} { return "SRV" }

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

Export-ModuleMember -Function *