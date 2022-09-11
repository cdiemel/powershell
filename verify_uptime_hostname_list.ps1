## Checks uptime of a list of hostnames every 5 minutes



## Get list of hostnames from file
$workstationlist = Get-Content ".\hostnames.txt"

function checkList {
    clear
    foreach($wsid in $workstationlist){
        #$ip = ((nslookup $wsid | findstr 'Address')[1] -split(" "))[2]
        (nslookup $wsid | findstr 'Name')
        $ping = (ping -n 1 $wsid)
        Write-Host("{0} - " -f (($ping[1] -split(" "))[0..2] -join(" "))) -NoNewline  -ForegroundColor Cyan
        if(($ping[2] | findstr 'Reply')) {
            Write-Host("{0}`n" -f $ping[2])  -ForegroundColor Green
        } else {
            Write-Host("{0}`n" -f $ping[2])  -ForegroundColor Red
        }
    }

}

While(1) {
    checklist
    Start-Sleep -Seconds 30
    Write-Host("30 sec down")
    Start-Sleep -Seconds 90
    Write-Host("2 min down")
    Start-Sleep -Seconds 120
    Write-Host("1 min to go")
    Start-Sleep -Seconds 60
}

