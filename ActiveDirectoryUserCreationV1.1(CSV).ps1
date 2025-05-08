# Define the target OU
$targetOU = "OU=TestDev,OU=Texas,DC=verticalcable,DC=local"

# Import CSV
$usersRaw = Import-Csv -Path "C:\Users\paulo\Desktop\ActiveDirectory\TestDev\EmployeeActiveDirectoryAccounts(Employee List).csv"

# Debug output: Show all headers once
Write-Host "Detected Columns:" -ForegroundColor Cyan
$usersRaw[0].PSObject.Properties.Name | ForEach-Object { Write-Host " - $_" }

# Main loop
foreach ($user in $usersRaw) {
    $sam = $user.'sAMAccountName'.Trim()
    if (-not $sam) {
        Write-Host "Skipping: No sAMAccountName found in row." -ForegroundColor Yellow
        continue
    }

    $existingUser = Get-ADUser -Filter { SamAccountName -eq $sam } -ErrorAction SilentlyContinue

    # Secure default password
    $securePassword = ConvertTo-SecureString "Xy!9z@T2#kL7&mQp" -AsPlainText -Force

    # Prep attributes
    $displayName = $user.'Employee Name'.Trim()
    $company     = $user.'Company'.Trim()
    $office      = $user.'Office Location'.Trim()
    $phone       = $user.'Phone Number'.Trim()
    $email       = $user.'Email Address'.Trim()
    $web         = $user.'Web Page'.Trim()

    $replaceAttributes = @{}
    if ($phone)   { $replaceAttributes['telephoneNumber']            = $phone }
    if ($email)   { $replaceAttributes['mail']                       = $email }
    if ($web)     { $replaceAttributes['wWWHomePage']                = $web }
    if ($company) { $replaceAttributes['company']                    = $company }
    if ($office)  { $replaceAttributes['physicalDeliveryOfficeName'] = $office }

    # Optional: Extension attributes
    # if ($user.'Employment Status') {
    #     $replaceAttributes['extensionAttribute1'] = $user.'Employment Status'.Trim()
    # }

    if ($existingUser) {
        Write-Host "User '$sam' already exists. Updating attributes..." -ForegroundColor Yellow
        try {
            Set-ADUser -Identity $sam `
                -DisplayName $displayName `
                -Replace $replaceAttributes

            Write-Host "Updated user: $displayName" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to update user: $displayName - $_" -ForegroundColor Red
        }
    }
    else {
        try {
            New-ADUser `
                -Name $displayName `
                -SamAccountName $sam `
                -UserPrincipalName ($sam + "@yourdomain.com") `
                -AccountPassword $securePassword `
                -Enabled $true `
                -GivenName ($displayName -split ' ')[0] `
                -Surname ($displayName -split ' ')[1] `
                -Title $user.'Job Title'.Trim() `
                -Department $user.'Department'.Trim() `
                -EmployeeID $user.'Employee ID'.Trim() `
                -Description "Start Date: $($user.'Start Date')" `
                -DisplayName $displayName `
                -Path $targetOU `
                -Replace $replaceAttributes

            Write-Host "Created user: $displayName" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to create user: $displayName - $_" -ForegroundColor Red
        }
    }
}
