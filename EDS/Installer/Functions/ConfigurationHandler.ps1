$script:configCache = @{}

function Initialize-Configuration {
    param (
        [Parameter(Mandatory=$true)]
        [string]$EDSFolderName
    )
    
    Write-EDSLog "Initializing configuration handler..." -Level "Info"
    
    try {
        # Find the configuration file
        $drives = Get-PSDrive -PSProvider FileSystem
        $configPath = $null
        
        foreach ($drive in $drives) {
            $testPath = Join-Path $drive.Root "$EDSFolderName\eds.cfg"
            if (Test-Path $testPath) {
                $configPath = $testPath
                Write-EDSLog "Found configuration file at: $configPath" -Level "Debug"
                break
            }
        }
        
        if (-not $configPath) {
            throw "Configuration file not found in any drive"
        }
        
        # Read and parse the configuration file
        $content = Get-Content -Path $configPath -Raw
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-EDSLog "Configuration file is empty, using defaults" -Level "Warning"
            return
        }
        
        # Parse the configuration file
        $lines = $content -split "`n" | ForEach-Object { $_.Trim() }
        
        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
                continue
            }
            
            if ($line -match "^([^=]+)=(.*)$") {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                
                # Remove quotes if present
                if ($value -match '^"(.*)"$') {
                    $value = $matches[1]
                }
                
                $script:configCache[$key] = $value
                Write-EDSLog "Loaded config: $key = $value" -Level "Debug"
            }
        }
        
        Write-EDSLog "Configuration initialized successfully" -Level "Info"
    }
    catch {
        Write-EDSLog "Failed to initialize configuration" -Level "Error" -ErrorRecord $_
        throw
    }
}

function Get-EDSConfig {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Key,
        
        [Parameter()]
        $DefaultValue
    )
    
    if ($script:configCache.ContainsKey($Key)) {
        return $script:configCache[$Key]
    }
    
    Write-EDSLog "Configuration key '$Key' not found, using default: $DefaultValue" -Level "Debug"
    return $DefaultValue
}

function Set-EDSConfig {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Key,
        
        [Parameter(Mandatory=$true)]
        $Value
    )
    
    $script:configCache[$Key] = $Value
    Write-EDSLog "Updated configuration: $Key = $Value" -Level "Debug"
}