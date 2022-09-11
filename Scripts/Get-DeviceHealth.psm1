$date_stamp = Get-Date -Format "MM-dd-yy-hhmmss"

## Dont die when AD throws up
$ErrorActionPreference = "SilentlyContinue"

## List of files to check
$host_files = ('c$\Users\Public\Desktop\desktop_link.lnk',
               'c$\Program Files\Program\program.exe')


## List of ad groups
$ad_groups = ("CN=my-ad-group,OU=Lower OU,OU=Middle OU,DC=sub-domain,DC=example,DC=com",
              "CN=my-ad-group2,OU=Lower OU,OU=Middle OU,DC=sub-domain,DC=example,DC=com")

## Create list of AD Group Names
$AD_Group_Names_Array = @()
foreach($group in $ad_groups) {
    $AD_Group_Names_Array += (($group -split(","))[0] -split("="))[1]
}

## Create FQDN
$ad_groups0_dc = [System.Collections.ArrayList]((($ad_groups[0] -split(",")) | findstr "DC") -split("="))
while($ad_groups0_dc -contains "DC") { $ad_groups0_dc.remove("DC") }
$fqdn = $ad_groups0_dc -join('.')

function Get-DeviceHealth {
    param ( 
        [string[]]$ComputerName,
        [Switch]$ToFile,
        [Switch]$Clipboard,
        [string[]]$Tests  #boot,files,ad,all
    )

    if($Clipboard) {
        $tempWS = Get-Clipboard
        if(($tempWS.Length -ge 7) -and ($tempWS.Length -le 15)) {
            $ComputerName = $tempWS
        }
    }
            


    if(!$ComputerName) {
        Write-Host "Nothing on clipboard, please provide -ComputerName" -ForegroundColor Red
        return
    }

    ## Array of workstation objects
    if($ToFile) {
        $ws_obj_array = @()
    }

    #Write-Host ($ComputerName,$ToFile,$Tests)

    ## Determine tests to complete
    if($Tests) {
        $Tests = ($Tests.Split(",")).ToUpper()
        $_AD_ = If ($Tests.contains("AD")) {1} Else {0}
        $_FILES_ = If ($Tests.contains("FILES")) {1} Else {0}
        $_BOOT_ = If ($Tests.contains("BOOT")) {1} Else {0}
        ($_BOOT_,$_FILES_,$_AD_) = If ($Tests.contains("ALL")) {1,1,1} else {$_BOOT_,$_FILES_,$_AD_}
    } else {
        ($_BOOT_,$_FILES_,$_AD_) = 1,1,1
    }

    foreach($workstation in $ComputerName){
        $workstation = $workstation.ToUpper()

        ## Create object
        ## We have to build the obj even if we dont 
        ## use it, this prevents Fx calls from failing
        ## where we [ref] but it is non-existant
        $ws_obj = [PSCustomObject]@{}

        ## Write header information
        Write-Host("`n" + $workstation + "`n-------------") -ForegroundColor White

        if($ToFile) {
            $ws_obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $workstation
        }
        
        $ping = PingInfo -ws $workstation -domain $fqdn
        $color = if($ping[0]) {"Green"}else{"Red"}
        Write-Host(" - " + $ping[1]) -ForegroundColor $color

        ###########################
        ## GET BOOT INFORMATION ###
        ###########################
        if($_BOOT_ -and $ping) {
            GetBoot -ws $workstation -file $ToFile -obj ([ref]$ws_obj)
        }

        #######################################
        ## GET ACTIVE DIRECTORY INFORMATION ###
        #######################################
        if($_AD_) {
            GetAD -ws $workstation -file $ToFile -obj ([ref]$ws_obj) -AD_Groups $AD_Group_Names_Array
        }

        #############################################################
        ## GET CURRENT NETWORK STATUS AND DESKTOP LINK DEPLOYMENT ###
        #############################################################
        if($_FILES_) {
            GetFiles -ws $workstation -outfile $ToFile -obj ([ref]$ws_obj) -files $host_files -domain $fqdn
        }
    
        $ws_obj_array += $ws_obj
    } ## end foreach

    #####################################
    ## WRITE INFORMATION TO LOCAL CSV ###
    #####################################
    if($ToFile) { WriteToFile($ws_obj_array) }
}

function PingInfo {
    param ( $ws, $domain )

    $test = ping -n 1 (("{0}."+$domain) -f $ws)
    if($?) {
        $ttl = [Int](($test | findstr TTL) -split("TTL="))[1]
        $os = if($ttl -lt 65){"Linux"}else{if($ttl-lt129){"Windows"}else{"Network"}}
        Write-Host (" - Likely {0} device" -f $os) -ForegroundColor Cyan
        return 1,($test | findstr "Reply")
        #Write-Host ("`n{0}`n" -f $test | findstr "Reply") -NoNewline -ForegroundColor Green
    } else {
        return 0,($test | findstr "equest")
        #Write-Host ("`n{0}`n" -f $test | findstr "equest") -NoNewline -ForegroundColor Red
    }
}


function GetAD {
    param ($ws,$file,[ref]$obj,[String[]]$AD_Groups)

    ## Get AD properties
    $props = Get-ADComputer -Identity $ws -Properties DistinguishedName,MemberOf

    if(!$?) {
        Write-Host( $ws + " DOES NOT EXIST IN AD") -ForegroundColor White -BackgroundColor Red
        if($file) {
            $obj.value | Add-Member -MemberType NoteProperty -Name "In AD" -Value "False"
            foreach($group in $AD_Groups) {
                $obj.value | Add-Member -MemberType NoteProperty -Name $group -Value "False"
            }
        } ## end if_write_to_file

    } else {
        if($file) {
            $obj.value | Add-Member -MemberType NoteProperty -Name "In AD" -Value "True"
        } ## end if_write_to_file

        ## Get MembeOf line  - not working correctly
        ##$memberof = $props | findstr "MemberOf"
        $memberof = $props

        ## Does it have the correct groups?
        foreach($group in $AD_Groups) {
            #$groupTF = $memberof | findstr $group
            if($memberof | findstr $group){
                Write-Host(" - is member of $group") -Foreground Green
                if($file) {
                    $obj.value | Add-Member -MemberType NoteProperty -Name "$group" -Value "True"
                } ## end if_write_to_file
            } else{
                Write-Host(" - is NOT a member of $group") -Foreground Red
                if($file) {
                    $obj.value | Add-Member -MemberType NoteProperty -Name "$group" -Value "False"
                } ## end if_write_to_file
            }
        }

    }

}

#############################################################
## GET CURRENT NETWORK STATUS AND DESKTOP LINK DEPLOYMENT ###
#############################################################
## The idea here is to get the information needed with as little nework overhead as possible. 
## 1) Lets full send and see if we can reach out and find the link.
## 2) If we cannot find the link either it does not exist or we do not have permissions
##   a) If we have permission then the file does not exist and we fail.   
##   b) If we do not have permissions, then we exit knowing that we can reach the host but
##      cannot access the file we are looking for
## 3) If we cannot reach the host, we try ping to see if they are even online. 

function GetFiles {
    param ($ws,$outfile,[ref]$obj,[String[]]$files,$domain)

    $failed = 0
    ## 1) Test if path exists (Full send)
    foreach($filepath in $files) {
        $filename = ($filepath -split("\\"))[-1]
        if(Test-Path ('\\' + $ws + '.' + $domain + '\' + $filepath)) {
            Write-Host(" - $filename") -Foreground Green
            if($outfile) {
                $obj.value | Add-Member -MemberType NoteProperty -Name $filename -Value "True"
            } ## end if_write_to_file
        } else {
            Write-Host(" - $filename NOT present") -Foreground Red
            if($outfile) {
                $obj.value | Add-Member -MemberType NoteProperty -Name $filename -Value "False"
            } ## end if_write_to_file
            $failed += 1
        }
    }

    if($failed -eq 0){
        if($outfile) {
            $obj.value | Add-Member -MemberType NoteProperty -Name "c$ Accessible" -Value "True"
            $obj.value | Add-Member -MemberType NoteProperty -Name "Pingable" -Value "True"
        } ## end if_write_to_file

    }

<#
    if(($failed -lt $files.Count) -and ($failed -gt 0)){
        $processed = (Get-ChildItem ('\\' + $ws + '.' + $domain + '\' + $folder)).count
        Write-Host(" - {0} Files in {1}" -f $processed,$folder) -Foreground Green
        if($file) {
            $obj.value | Add-Member -MemberType NoteProperty -Name "c$ Accessible" -Value "True"
            $obj.value | Add-Member -MemberType NoteProperty -Name "Pingable" -Value "True"
            $obj.value | Add-Member -MemberType NoteProperty -Name "Files" -Value $processed
        } ## end if_write_to_file

    }
#>

    if($failed -eq $files.Count){

        ## Test if accessible
        if(Test-Path ('\\' + $ws + '.' + $domain + 'c$\Users\Public\Desktop\')){

            if($file) {
                $obj.value | Add-Member -MemberType NoteProperty -Name "c$ Accessible" -Value "True"
                $obj.value | Add-Member -MemberType NoteProperty -Name "Pingable" -Value "True"
            } ## end if_write_to_file

        } else {

            ## Test if pingable
            $pingtest = Test-Connection -ComputerName $ws -Quiet -Count 1 -ErrorAction SilentlyContinue
            if($pingtest){

                Write-Host(" - c$ NOT accessible") -Foreground Red
                Write-Host(" - pingable") -Foreground Green
                if($file) {
                    $obj.value | Add-Member -MemberType NoteProperty -Name "c$ Accessible" -Value "False"
                    $obj.value | Add-Member -MemberType NoteProperty -Name "Pingable" -Value "True"
                } ## end if_write_to_file

            } else {

                Write-Host(" - NOT pingable") -Foreground Red
                if($file) {
                    $obj.value | Add-Member -MemberType NoteProperty -Name "c$ Accessible" -Value "False"
                    $obj.value | Add-Member -MemberType NoteProperty -Name "Pingable" -Value "False"
                } ## end if_write_to_file
            } ## End if pingable
        } ## end if accessible
    } ## end if neither path exists
} ## end GetFiles Fx
        
###########################
## GET BOOT INFORMATION ###
###########################

function GetBoot {
    param ($ws,$file,[ref]$obj)
    $bootTime = (systeminfo /s $ws | find "Boot Time").split(":",2)[1].trim()
    Write-Host(" - Boot: "+$bootTime) -Foreground Blue
    if($file) {
        $obj.value | Add-Member -MemberType NoteProperty -Name "Boot" -Value $ws
    }
}


function WriteToFile {
    param ( $WSObjArray )

    $date_stamp = Get-Date -Format "MM-dd-yy-hhmmss"
    $WSObjArray | Export-Csv -Path ("./DeviceHealthTest_{0}.csv" -f $date_stamp) -NoTypeInformation

}


Export-ModuleMember -Function Get-DeviceHealth

## Specify Hostname to query
## Get-DeviceHealth -ComputerName $hostname

## Send to outfile in current directory
## Get-DeviceHealth -ComputerName $hostname -ToFile

## Specify tests to run
## Get-DeviceHealth -ComputerName $hostname -Tests AD,Files,Boot,ALL

## Force getting hostname from clipboard
## Get-DeviceHealth -Clipboard


