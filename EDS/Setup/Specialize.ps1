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
$edsFolderName = $params.edsFolder[0]

$headers = @{
    "Content-Type"    = "application/json"
    "X-Device-Token"  = $deviceToken
}

$zipPath = Join-Path $edsFolderName "content.zip"
$extractPath = Join-Path $edsFolderName "content"

New-Item -Path $edsFolderName -ItemType Directory -Force | Out-Null

Invoke-RestMethod -Uri "$apiUrl/jobs/$jobId/content" -Method Get -Headers $headers -TimeoutSec 5 -OutFile $zipPath

# Extract the zip file
if (Test-Path $zipPath) {
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractPath)
    Write-Host "Content extracted to $extractPath"
} else {
    Write-Host "Zip file not found: $zipPath"
}

$entryPoint = Join-Path $extractPath "main.ps1"
if (Test-Path $entryPoint) {
    Write-Host "Executing entry point script: $entryPoint"
    . $entryPoint
} else {
    Write-Host "Entry point script not found: $entryPoint"
}