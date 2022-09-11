## Dont die when AD throws up
$ErrorActionPreference = "SilentlyContinue"

$timeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

## Get list of hostnames from file
$workstationlist = Get-Content ".\hostnames.txt"

$ou = "OU=my_ad_OU,OU=Lower OU,OU=Middle OU,OU=subdomain,DC=example,DC=com"
$ou_name = (($ou -split(",")[0]) -split("="))[0]

$logFile = ".\results\" + $ou_name + "_" + $timeStamp +"_log.txt"

foreach($workstation in $workstationlist){

    Write-Host("`n" + $workstation + "`n-------------") -ForegroundColor White
    $ws = (Get-ADComputer -Identity $workstation -Properties DistinguishedName).DistinguishedName
    
    Move-ADObject -Identity $ws -TargetPath $ou

    if($?) {
        Write-Host(" - added to $ou_name") -Foreground Green
         Out-File -Append -FilePath $logFile -InputObject ("{0} passed" -f $ws)
    } else {
         Write-Host(" - failed to add to $ou_name") -Foreground Red
         Out-File -Append -FilePath $logFile -InputObject ("{0} failed" -f $ws)
    }

} ## end foreach



pause