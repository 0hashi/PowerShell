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
Invoke-Command -ComputerName e6workstation -ScriptBlock { Enable-NetFirewallRule -Name "WMI-In-TCP" }

#PO - Get a list of AzureAD subscriptions
Get-AzureADSubscribedSku 

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