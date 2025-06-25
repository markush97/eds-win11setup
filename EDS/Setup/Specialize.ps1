function Get-InstallerParams {
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

$params = Get-InstallerParams
$apiUrl = $params.apiUrl[0]
$jobId = $params.jobId[0]
$deviceToken = $params.deviceToken[0]
$edsFolderName = $params.edsFolderName[0]

$headers = @{
    "Content-Type"    = "application/json"
    "X-Device-Token"  = $deviceToken
}

$basePath = Join-Path "C:\Windows\Setup" $edsFolderName
$zipPath = Join-Path $basePath "content.zip"
$extractPath = Join-Path $basePath "content"

New-Item -Path $basePath -ItemType Directory -Force | Out-Null

$downloadSuccess = $false
try {
    Invoke-RestMethod -Uri "$apiUrl/jobs/$jobId/content" -Method Get -Headers $headers -TimeoutSec 5 -OutFile $zipPath
    $downloadSuccess = $true
} catch {
    Write-Host "Failed to download job content: $($_.Exception.Message)"
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
        Write-Host "HTTP Status: $($_.Exception.Response.StatusCode)"
    }
}

if (-not $downloadSuccess -or -not (Test-Path $zipPath)) {
    Write-Host "Zip file not found or download failed: $zipPath"
    exit 1
}

# Extract the zip file
if (Test-Path $extractPath) {
    try {
        Remove-Item $extractPath -Recurse -Force
    } catch {
        Write-Host "Failed to remove existing extract path: $extractPath. $_"
        exit 1
    }
}
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractPath)
    Write-Host "Content extracted to $extractPath"
} catch {
    Write-Host "Failed to extract zip file: $($_.Exception.Message)"
    exit 1
}

$entryPoint = Join-Path $extractPath "main.ps1"
if (Test-Path $entryPoint) {
    Write-Host "Executing entry point script: $entryPoint"
    . $entryPoint
} else {
    Write-Host "Entry point script not found: $entryPoint"
}