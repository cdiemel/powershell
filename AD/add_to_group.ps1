## Dont die when AD throws up
$ErrorActionPreference = "SilentlyContinue"

## Get list of hostnames from file
$workstationlist = Get-Content ".\hostnames.txt"

$ad_group = "CN=my-ad-group,OU=Lower OU,OU=Middle OU,DC=sub-domain,DC=example,DC=com"
$group_name = (($OUpath -split(",")[0]) -split("="))[0]


## Run GPUpdate
Write-Host 'Restart? [Y/N] ' -NoNewline -ForegroundColor Green
$cont_restart = if((Read-Host) -eq "Y"){$true}else{$false}
foreach($workstation in $workstationlist){

    ## Write header information
    Write-Host("`n" + $workstation + "`n-------------") -ForegroundColor White
    
    $mem = Get-ADComputer -Identity $workstation
    
    Add-ADGroupMember -Identity $ad_group -Members $mem
    Write-Host(" - $group_name added") -Foreground Green


    ## Run restart
    if ($cont_restart) {
       ## Invoke-GPUpdate -Computer $workstation -Target "Computer"
       ## Write-Host(" - GPUpdate complete") -Foreground Green
        Restart-Computer -ComputerName $workstation
    } ## end if do gpupdate

} ## end foreach

pause