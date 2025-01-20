#PO - Get/Set Execution Policy (RemoteSigned or Unrestricted)
Get-ExecutionPolicy
Set-ExecutionPolicy Unrestricted

#--------------------------------------------------------------------
#PO - AzureAD/Entra ID & Microsoft Graph PowerShell Modules. The AzureAD Module is being replaced by the MS Graph Powershell Module
#
# Depending on which module you want to use (AzureAD or Microsoft Graph API) make sure the module is installed.
#
# Import the AzureAD, or Microsoft Graph module and connect before running queries.

#PO - If needed, install and import the AzureAD PowerShell Module
Install-Module AzureAD
Import-Module AzureAD

#PO - Connect to AzureAD
Connect-AzureAD
#------------------------------
#PO - If needed, install and import Microsoft Graph API
Install-Module -Name Microsoft.Graph -Force
Import-Module Microsoft.Graph

#PO - Connect/Authenticate Microsoft Graph
Connect-MgGraph
#--------------------------------------------------------------------

Invoke-Command -ComputerName tci-tw-cbl -ScriptBlock { systeminfo | find "System Boot Time" }

#--------------------------------------------------------------------

#PO - Get AD User info
Get-ADUser announcement1

#--------------------------------------------------------------------

#PO - Get the domain role of a system
# - 0x0: Standalone workstation
# - 0x1: Member workstation
# - 0x2: Standalone server
# - 0x3: Member server
# - 0x4: Backup domain controller
# - 0x5: Primary domain controller

wmic computersystem get DomainRole

#--------------------------------------------------------------------

#PO - Who's logged on, where?
qwinsta /server:172.18.1.4 | Where-Object {$_ -notmatch "SYSTEM"}

#--------------------------------------------------------------------

#PO - Search Security Event log for logons in the last (x) days.
Get-EventLog -LogName Security | Where-Object {$_.EventID -eq 4624} | Select-Object -Property @{Name='TimeGenerated';Expression={$_.TimeGenerated}}, @{Name='User';Expression={$_.ReplacementStrings[5]}} | Sort-Object TimeGenerated -Descending | Where-Object {$_.TimeGenerated -ge (Get-Date).AddDays(-5)} | Where-Object {$_ -notmatch "SYSTEM"}

#--------------------------------------------------------------------
# Get a list of AD users in the Texas OU
Get-ADUser -Filter * -SearchBase "OU=Texas,DC=verticalcable,DC=local" | Select-Object Name, DistinguishedName | Sort-Object Name

#--------------------------------------------------------------------

#PO - Display the number of disabled user accounts.
Search-ADAccount -AccountDisabled -UsersOnly -SearchBase "OU=Texas,DC=verticalcable,DC=local" | FT Name, DistinguishedName | Measure-Object -Line
#PO - Display the disabled user accounts.
Search-ADAccount -AccountDisabled -UsersOnly -SearchBase "OU=Texas,DC=verticalcable,DC=local" | Sort-Object -Property Name | FT Name, DistinguishedName 

#--------------------------------------------------------------------

#PO - Get a list of AzureAD subscriptions
Get-AzureADSubscribedSku 

#--------------------------------------------------------------------

#PO - Get a list of users and their assigned license SKUs
Connect-AzureAD
Get-AzureADUser -All $true | ForEach-Object {
    $user = $_

    $licenses = Get-AzureADUserLicenseDetail -ObjectId $user.ObjectId
    $licenses | ForEach-Object {
        [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            DisplayName       = $user.DisplayName
            LicenseSku        = $_.SkuPartNumber
        }
    }
} | Format-Table -AutoSize 

#--------------------------------------------------------------------

# Shutdown Windows systems remotely.
# Comma delimited list of computers to shut down
$ComputerNames = @("e6workstation")

# Credentials for remote access
$Credential = Get-Credential

# Iterate through each computer and attempt to shut it down
foreach ($Computer in $ComputerNames) {
    try {
        Write-Host "Attempting to shut down $Computer..." -ForegroundColor Yellow
        Stop-Computer -ComputerName $Computer -Credential $Credential -Force -Confirm:$false
        Write-Host "$Computer has been shut down successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to shut down $Computer. Error: $_" -ForegroundColor Red
    }
}

#--------------------------------------------------------------------

#PO - Execute remote PowerShell cmd
Invoke-Command -ComputerName design1 -ScriptBlock { Get-LocalGroupMember -Group $GroupName }

#--------------------------------------------------------------------
# Shutdown Windows with WMIC
Invoke-Command -ComputerName computername -ScriptBlock { shutdown /s /t 0 }

#--------------------------------------------------------------------

#PO - Backup DNS
# Specify the DNS server and zone
Import-Module DnsServer
$DnsServer = "verttxdc001"
$ZoneName = "verticalcable.local"

# Export the zone
Export-DnsServerZone -Name $ZoneName -FileName "$ZoneName.dns" -ComputerName $DnsServer
Write-Output "Exported zone $ZoneName to $ZoneName.dns"

# Specify the DNS server
$DnsServer = "verttxdc001"

# List all zones to verify the zone name
Get-DnsServerZone -ComputerName $DnsServer

#--------------------------------------------------------------------

$ZoneName = "verticalcable.local"
$DnsServer = "VERTTXDC001.verticalcable.local"

# Get all A records in the specified zone
$ARecords = Get-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $DnsServer | Where-Object RecordType -eq "A"

# Group A records by IP address
$Duplicates = $ARecords | Group-Object -Property RecordData -NoElement | Where-Object Count -gt 1

# Display duplicates
$Duplicates | ForEach-Object {
    Write-Output "Duplicate IP Address: $($_.Name) - Count: $($_.Count)"
}

#--------------------------------------------------------------------

Get-DhcpServerv4Reservation -ComputerName "10.100.104.7" -ScopeId 10.100.104.0

#--------------------------------------------------------------------

# Find users in specific privileged groups and print the results to STDOOUT and if selected
# to the default printer
$privilegedGroups = "Domain Admins", "Enterprise Admins", "Schema Admins", "Administrators"
$privilegedAccts = foreach ($group in $privilegedGroups) {
    Get-ADGroupMember -Identity $group | Select-Object Name, SamAccountName, DistinguishedName,@{Name='Group';Expression={$group}}
}
$privilegedAccts = $privilegedAccts | Sort-Object -Property Name 

# Output and print the results
Write-Output $privilegedAccts | Format-Table -AutoSize

###$privilegedAccts | Export-Csv -Path "TCI_PrivilegedAccounts.csv" -NoTypeInformation
###Out-Printer -InputObject $privilegedAccts

#--------------------------------------------------------------------

# Find users with adminCount attribute set to 1
Get-ADUser -Filter "adminCount -eq 1" | Select-Object Name, SamAccountName, Enabled | Sort-Object -Property Name

#--------------------------------------------------------------------

# Find users with specific rights (e.g., reset password)
Get-ADObject -Filter 'objectClass -eq "user"' -Properties userAccountControl | 
    Where-Object {$_.userAccountControl -band 0x10000} | 
    Select-Object Name, SamAccountName, Enabled |Sort-Object -Property Name

#--------------------------------------------------------------------

# Find disabled users in OU and move to another OU
# Specify the source and destination OUs
$sourceOU = "OU=Texas,DC=verticalcable,DC=local"
$destinationOU = "OU=Disabled Users,OU=Texas,DC=verticalcable,DC=local"

# Get all disabled users in the source OU
$disabledUsers = Get-ADUser -SearchBase $sourceOU -Filter {Enabled -eq $false}

# Move each disabled user to the destination OU
foreach ($user in $disabledUsers) {
    #Move-ADObject -Identity $user.DistinguishedName -TargetPath $destinationOU
    Write-Output $user "moved to " $destinationOU
    Write-Output "---------------------------------"
}

# Get the Group Membership of a user object
Get-ADPrincipalGroupMembership lead.operator | Select-Object name
Get-ADPrincipalGroupMembership -Identity lead.operator | Get-ADGroupMember



$username = "lead.operator"  # Replace with the actual username
$userGroups = Get-ADPrincipalGroupMembership -Identity $username  

foreach ($group in $userGroups) {
    Write-Host "Group: $($group.Name)"
        $nestedGroups = Get-ADGroupMember -Identity $group.Name | Where-Object { $_.ObjectClass -eq "group" }
            foreach ($nestedGroup in $nestedGroups) {
                    Write-Host "  - $($nestedGroup.Name)"
    }
}

#--------------------------------------------------------------------
$user = "lead.operator"
$groups = Get-ADPrincipalGroupMembership -Identity $user 


# Get the members of each group
foreach ($group in $groups) {
    Write-Host "Members of group $($group.Name):"
    Get-ADGroupMember -Identity $group.Name
}

#--------------------------------------------------------------------
#PO - Get group membership of user
Get-ADPrincipalGroupMembership -Identity "lead.operator" | Select-Object name

#--------------------------------------------------------------------

$User = "lead.operator"


$Groups = Get-ADUser -Identity $User | Get-ADPrincipalGroupMembership
$Groups | ForEach-Object {
    Get-ADGroup -Identity $_.DistinguishedName -Properties MemberOf
} | Select Name

Get-ADUser -Identity $User | Get-ADPrincipalGroupMembership | Select-Object Name


Get-ADUser -Filter { extensionAttribute1 -notlike "*" } -Properties extensionAttribute1
