
## Get list of hostnames from file of IPs using nslookup

$workstationlist = Get-Content ".\hostnames.txt"


foreach($wsid in $workstationlist){
    $ip = (((nslookup $wsid | findstr 'Name') -split(":"))[1]).trim()
    Write-Host($ip)
    ("{0},{1}" -f $wsid,$ip) | Out-File -Append -FilePath ("IP_hostnames.csv")
}
   