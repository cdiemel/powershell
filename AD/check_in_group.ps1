## Dont die when AD throws up
$ErrorActionPreference = "SilentlyContinue"

## Get list of hostnames from file
$workstationlist = Get-Content ".\hostnames.txt"

$ad_group = "CN=my-ad-group,OU=Lower OU,OU=Middle OU,OU=subdomain,DC=example,DC=com"
$group_name = (($OUpath -split(",")[0]) -split("="))[0]


foreach($workstation in $workstationlist){

    ## Write header information
    Write-Host("`n" + $workstation + "`n-------------") -ForegroundColor White
    
    ## Get AD properties
    $props = Get-ADComputer -Identity $workstation -Properties DistinguishedName,MemberOf

    if(!$?) {
        Write-Host( $workstation + " DOES NOT EXIST IN AD") -ForegroundColor White -BackgroundColor Red
        continue
    }

    ## Does it have the correct baseline group?
    $baseline = $memberof | findstr $group_name
    if($?){
        Write-Host(" - is member of $group_name") -Foreground Green
    } else {
        Write-Host(" - is NOT a member of $group_name") -Foreground Red
    }

} ## end foreach

pause