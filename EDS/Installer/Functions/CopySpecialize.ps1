
param(
    [string] $EDSFolderName
);

New-Item -Path (Join-Path "C:" $EDSFolderName) -ItemType Directory -Force | Out-Null;
$drives = Get-PSDrive -PSProvider FileSystem;
foreach ($drive in $drives) {
    $path = Join-Path $drive.Root "$EDSFolderName\eds.cfg";
    if (Test-Path $path) {
        Copy-Item -Path (Join-Path $drive.Root "$EDSFolderName\*") -Destination (Join-Path "C:" $EDSFolderName) -Recurse -Force;
    }
}
