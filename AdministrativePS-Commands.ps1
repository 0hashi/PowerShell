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

#PO - Get a list of AzureAD subscriptions
Get-AzureADSubscribedSku 

#PO - List total and used Azure licenses
Get-AzureADSubscribedSku | Select-Object SkuPartNumber, SkuId, @{Name="TotalLicenses";Expression={$_.ConsumedUnits + $_.PrepaidUnits.Enabled}}, @{Name="UsedLicenses";Expression={$_.ConsumedUnits}}

#PO -List users with licenses assigned
Get-AzureADUser -All $true | Where-Object {$_.AssignedLicenses -ne $null} | Select-Object DisplayName, UserPrincipalName, @{Name="Licenses";Expression={($_.AssignedLicenses).SkuId}}

#PO - Get a list of users and their assigned licenses (I do not have permissions)
Get-MgUser -All -Property AssignedLicenses,DisplayName,UserPrincipalName | ForEach-Object {
    $user = $_
    foreach ($license in $user.AssignedLicenses) {
        [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            DisplayName       = $user.DisplayName
            LicenseSku        = $license.SkuId
        }
    }
} | Format-Table -AutoSize
