<#
.Author
   Casey Diemel
.DESCRIPTION
   Get a list of all computers in a group
#>

$date_stamp = Get-Date -Format "MM-dd-yy"
$OUpath = "CN=my-ad-group,OU=Lower OU,OU=Middle OU,OU=subdomain,DC=example,DC=com"
$group_name = (($OUpath -split(",")[0]) -split("="))[0]


Get-ADGroupMember -Identity $OUpath | Get-ADComputer -Properties Name,OperatingSystemVersion,ObjectClass |  Export-Csv -NoTypeInformation -Path (".\ad_{0}_{1}.csv" -f ($group_name,$date_stamp))