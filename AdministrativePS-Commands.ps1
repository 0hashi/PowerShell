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

#PO - Display the number of disabled user accounts.
Search-ADAccount -AccountDisabled -UsersOnly -SearchBase "OU=Texas,DC=verticalcable,DC=local" | FT Name, DistinguishedName | Measure-Object -Line
#PO - Display the disabled user accounts.
Search-ADAccount -AccountDisabled -UsersOnly -SearchBase "OU=Texas,DC=verticalcable,DC=local" | FT Name, DistinguishedName

#--------------------------------------------------------------------

#PO - Execute remote PowerShell cmd
Invoke-Command -ComputerName design1 -ScriptBlock { Get-LocalGroupMember -Group $GroupName }

#--------------------------------------------------------------------

#PO - Get a list of AzureAD subscriptions
Get-AzureADSubscribedSku 

#--------------------------------------------------------------------

#PO - Get a list of users and their assigned license SKUs
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