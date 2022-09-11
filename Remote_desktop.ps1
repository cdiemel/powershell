

$hostname = Read-Host "Device IP/Hostname? "


Start-Process "C:\Program Files (x86)\Microsoft Endpoint Manager\bin\i386\CmRcViewer.exe" $hostname
