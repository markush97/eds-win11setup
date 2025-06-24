
param(
    [string] $EDSFolderName
);

$targetPath = Join-Path "C:\Windows\Setup" $EDSFolderName
New-Item -Path $targetPath -ItemType Directory -Force | Out-Null;
$drives = Get-PSDrive -PSProvider FileSystem;
foreach ($drive in $drives) {
    $path = Join-Path $drive.Root "$EDSFolderName\eds.cfg";
    if (Test-Path $path) {
        Copy-Item -Path (Join-Path $drive.Root "$EDSFolderName\Setup\*") -Destination $targetPath -Recurse -Force;
    }
}
