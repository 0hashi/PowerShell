# Active Directory user creation script
#
# Filename: ActiveDirectoryUserCreation(CSV)_v1.1.ps1
# Version 1.0
# Date: 5-1-2025
# Paul Ohashi, Trans Cable International
#
# This script serves two purposes: 
# 1. To create new AD User accounts for new employees.
# 2. To verify the EmployeeActiveDirectoryAccounts.xlsx file has parity with
#    the Trans Cable Users in Active Directory User Accounts
#
# NOTE: The employee spreadsheet exists on TCI IT SharePoint site in the following location:
#       (Documents > a > b > c)
#
# Usage:    1. Download EmployeeActiveDirectoryAccounts.xlsx as a .csv file.
#              (this may work as .xlsx, but I had issues while testing, so I converted it to .csv). 
#           2. Update the $usersRaw variable with the path and filename of the downloaded .csv spreadsheet.
#           3. Verify the $targetOU is where you want new users created/updated.
#           4. Run this script.
#
# NOTE: Version 2.0 will read the spreadsheet from SharePoint directly (no need to download and convert to .csv).
#


# User creation source CSV file should be in the following format:
# Employee Name,Employee ID,Job Title,Department,Employment Status,Start Date,Termination Date,sAMAccountName,System Access,Role-Based Access Level,MFA Enabled,Background Check Complete,Company,Manager,Telephone
# Jesus Frias,248,Machine Operator,Production,Active,6/9/2025,,Jesus.Frias,AD - ERP (Rubicon) - SharePoint,Standard User,No,Yes,Trans Cable International,billyb,903-449-4622
# Jessiah Kinnamon,249,Maintenance Tech,Maintenance,Active,6/16/2025,,Jessiah.Kinnamon,AD - Email (M365) - ERP (Rubicon) - SharePoint,Standard User,Yes,Yes,Trans Cable International,chadm,903-449-4622





Import-Module ActiveDirectory

# Path to your CSV file
$csvPath = "C:\Users\paulo\Desktop\ActiveDirectory\TestDev\EmployeeActiveDirectoryAccounts(Employee List).csv"

# Target OU DN (change this to match your AD structure)
$targetOU = "OU=TestDev,OU=Texas,DC=verticalcable,DC=local"

# Import the CSV
$users = Import-Csv $csvPath

foreach ($user in $users) {
    $username = $user.sAMAccountName
    $existingUser = Get-ADUser -Filter {SamAccountName -eq $username} -Properties *

    # Split names
    $nameParts = $user.'Employee Name' -split ' ', 2
    $givenName = $nameParts[0]
    $surname = if ($nameParts.Length -gt 1) { $nameParts[1] } else { "" }

    # Lookup manager DN
    $manager = Get-ADUser -Filter "SamAccountName -eq '$($user.Manager)'" -ErrorAction SilentlyContinue
    $managerDN = if ($manager) { $manager.DistinguishedName } else { $null }

    if ($existingUser) {
        # Update existing user
        Set-ADUser -Identity $username `
    -GivenName $givenName `
    -Surname $surname `
    -DisplayName "$givenName $surname" `
    -Title $user.'Job Title' `
    -Department $user.Department `
    -Company $user.Company `
    -Manager $managerDN `
    -OfficePhone $user.Telephone `
    -Office "Bonham TX" `
    -Description "Start: $($user.'Start Date')" `
    -Replace @{wWWHomePage = "https://transcableusa.com/"}
        Write-Host "Updated user: $username"
    }
    else {
    # Create new user in the specified OU
    New-ADUser `
        -SamAccountName $username `
        -UserPrincipalName "$username@verticalcable.local" `
        -Name $user.'Employee Name' `
        -GivenName $givenName `
        -Surname $surname `
        -DisplayName "$givenName $surname" `
        -Title $user.'Job Title' `
        -Department $user.Department `
        -Company $user.Company `
        -Manager $managerDN `
        -OfficePhone $user.Telephone `
        -Office "Bonham TX" `
        -Description "Start: $($user.'Start Date')" `
        -Path $targetOU `
        -AccountPassword (ConvertTo-SecureString "TempP@ssw0rd!" -AsPlainText -Force) `
        -Enabled:$true

    # Set additional attribute after creation
    Set-ADUser -Identity $username -Replace @{wWWHomePage = "https://transcableusa.com/"}

    Write-Host "Created new user: $username in OU $targetOU"
    }
}
