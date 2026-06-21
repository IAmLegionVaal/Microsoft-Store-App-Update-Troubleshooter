#requires -Version 5.1
<# Created by Dewald Pretorius. #>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [ValidateSet('Diagnose','ResetStoreCache','StartRequiredServices','FlushDns')][string]$Action='Diagnose',
  [string]$OutputPath=(Join-Path ([Environment]::GetFolderPath('Desktop')) 'Microsoft_Store_Update_Repair')
)
$ErrorActionPreference='Stop'
$serviceNames=@('InstallService','ClipSVC','BITS','wuauserv')
New-Item -ItemType Directory -Path $OutputPath -Force|Out-Null
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$logPath=Join-Path $OutputPath "Repair_$stamp.log"
function Write-RepairLog([string]$Message){$line='{0:u} {1}' -f (Get-Date),$Message;Write-Host $line;Add-Content -LiteralPath $logPath -Value $line}
$state=[ordered]@{Action=$Action;StorePackage=@(Get-AppxPackage Microsoft.WindowsStore|Select-Object Name,Version,InstallLocation);Services=@($serviceNames|ForEach-Object{Get-Service -Name $_ -ErrorAction SilentlyContinue|Select-Object Name,Status,StartType});StoreEndpoint=(Test-NetConnection 'storeedgefd.dsx.mp.microsoft.com' -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue)}
$state|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $OutputPath "PreRepair_$stamp.json") -Encoding UTF8
if($Action -eq 'Diagnose'){Write-RepairLog '[COMPLETE] Read-only snapshot saved.';exit 0}
try{
  if($Action -eq 'ResetStoreCache' -and $PSCmdlet.ShouldProcess('Microsoft Store cache','Run WSReset')){
    $process=Start-Process -FilePath 'wsreset.exe' -Wait -PassThru
    if($process.ExitCode -ne 0){throw "WSReset exited with code $($process.ExitCode)."}
  }
  elseif($Action -eq 'StartRequiredServices' -and $PSCmdlet.ShouldProcess(($serviceNames -join ', '),'Start stopped services')){
    foreach($name in $serviceNames){$service=Get-Service -Name $name -ErrorAction SilentlyContinue;if($service -and $service.Status -eq 'Stopped'){Start-Service -Name $name}}
    Start-Sleep -Seconds 2
    $stopped=@($serviceNames|Where-Object{(Get-Service -Name $_ -ErrorAction SilentlyContinue).Status -eq 'Stopped'})
    if($stopped.Count -gt 0){throw "Services remain stopped: $($stopped -join ', ')"}
  }
  elseif($Action -eq 'FlushDns' -and $PSCmdlet.ShouldProcess('Windows DNS client cache','Clear')){Clear-DnsClientCache}
}catch{Write-RepairLog "[FAILED] $($_.Exception.Message)";exit 5}
Write-RepairLog '[COMPLETE] Repair completed.'
exit 0
