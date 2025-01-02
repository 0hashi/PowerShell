#PO - Get AD User info
Get-ADUser announcement1

#PO - Get the domain role of a system
# - 0x0: Standalone workstation
# - 0x1: Member workstation
# - 0x2: Standalone server
# - 0x3: Member server
# - 0x4: Backup domain controller
# - 0x5: Primary domain controller
wmic computersystem get DomainRole

#PO - Who's logged on, where?
qwinsta /server:172.18.1.4 | Where-Object {$_ -notmatch "SYSTEM"}


#PO - Search Security Event log for logons in the last (x) days.
Get-EventLog -LogName Security | Where-Object {$_.EventID -eq 4624} | Select-Object -Property @{Name='TimeGenerated';Expression={$_.TimeGenerated}}, @{Name='User';Expression={$_.ReplacementStrings[5]}} | Sort-Object TimeGenerated -Descending | Where-Object {$_.TimeGenerated -ge (Get-Date).AddDays(-5)} | Where-Object {$_ -notmatch "SYSTEM"}

#PO - Find disabled user accounts
Search-ADAccount -AccountDisabled -UsersOnly -SearchBase "OU=Texas,DC=verticalcable,DC=local" | FT Name, DistinguishedName | Measure-Object -Line

#PO - Execute remote PowerShell cmd
Invoke-Command -ComputerName ENG-TECH2.verticalcable.local -ScriptBlock { Get-Process }

#PO - AzureAD/Entra ID & Microsoft Graph PowerShell Modules. The AzureAD Module is being replaced by the MS Graph Powershell Module
#
# Make sure the AzureAD Module is installed (Install-Module -Name AzureAD)
#
# Import the AzureAD module and connect to AzureAD before running queries.
# Also install Microsoft Graph with: Install-Module Microsoft.Graph

Install-Module Microsoft.Graph

Import-Module AzureAD #PO - Import the AzureAD module into this session
Connect-AzureAD       #PO - Connect to AzureAD

Get-AzureADSubscribedSku #PO - List AzureAD subscriptions

#PO - List total and used Azure licenses (AzureAD Module)
Get-AzureADSubscribedSku | Select-Object SkuPartNumber, SkuId, @{Name="TotalLicenses";Expression={$_.ConsumedUnits + $_.PrepaidUnits.Enabled}}, @{Name="UsedLicenses";Expression={$_.ConsumedUnits}}

#PO -List users with licenses assigned
Get-AzureADUser -All $true | Where-Object {$_.AssignedLicenses -ne $null} | Select-Object DisplayName, UserPrincipalName, @{Name="Licenses";Expression={($_.AssignedLicenses).SkuId}}

