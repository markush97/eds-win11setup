$xml = [xml]::new();
$xml.Load('C:\Windows\Panther\unattend.xml');
$sb = [scriptblock]::Create( $xml.unattend.Extensions.ExtractScript );
Invoke-Command -ScriptBlock $sb -ArgumentList $xml;
Get-Content -LiteralPath 'C:\Windows\Setup\Scripts\Specialize.ps1' -Raw | Invoke-Expression;
Get-Content -LiteralPath 'C:\Windows\Setup\Scripts\FirstLogon.ps1' -Raw | Invoke-Expression;