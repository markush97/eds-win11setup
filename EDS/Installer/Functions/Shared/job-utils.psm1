function Register-Device {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$registerInfo,
        [Parameter(Mandatory = $true)]
        [string]$uri
    )

    Write-Host "Registering device with $uri/api/jobs/register"
    try {
        $response = Invoke-RestMethod -Uri "$uri/api/jobs/register" -Method POST -Body $registerInfo
    } catch {
        $errorMessage = $_.Exception.Message
        $rawError = $_.Exception | Out-String

        $response = $_ | ConvertFrom-Json

        if ($response.mtiErrorCode -eq 2005) {
            Add-Type -AssemblyName System.Windows.Forms
            $fullMsg = "Error: A device with this serial number is already registered"
            [System.Windows.Forms.MessageBox]::Show(
                $fullMsg,
                "Registration Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            Write-Host $fullMsg
            
        } else {
            Add-Type -AssemblyName System.Windows.Forms
            $fullMsg = "Error during device registration. $($errorMessage)"
            [System.Windows.Forms.MessageBox]::Show(
                $fullMsg,
                "Registration Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            Write-Host $fullMsg
            
        }
        throw
    }

    $deviceToken = $response.deviceToken
    $jobId = $response.jobId
    $jobName = $response.jobName

    if ($deviceToken -and $jobId) {
        Write-Host "Device registered successfully. Job ID: $jobId and Name: $jobName"
        return @{
            deviceToken = $deviceToken
            jobId = $jobId
            jobName = $jobName
        }
    }
}

function Set-JobStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$jobId,
        [Parameter(Mandatory = $true)]
        [string]$status,
        [Parameter(Mandatory = $true)]
        [string]$deviceToken,
        [Parameter(Mandatory = $true)]
        [string]$uri
    )

    $headers = @{
        "Content-Type"    = "application/json"
        "X-Device-Token"  = $deviceToken
    }

     try {
        Write-Host "Updateing job status for Job ID: $jobId to '$status'"
        $response = Invoke-RestMethod -Uri "$uri/api/jobs/notify/$jobId`?jobStatus=$status" -Method POST -Headers $headers
	
    } catch {
        Write-Error "Failed to register device: $_"
        exit 1
    }
}

function Set-DeviceInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$deviceInfo,
        [Parameter()]
        [string]$configPath = "C:\ProgramData\CWI"
    )

    $deviceToken = $deviceInfo.deviceToken
    $jobId = $deviceInfo.jobId

    $tokenPath = Join-Path $configPath "device.token"
    $jobPath = Join-Path $configPath "jobinfo.ini"

    $jobId | Set-Content -Path $jobPath -Encoding UTF8

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

Export-ModuleMember -Function *