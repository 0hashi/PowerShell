# Define the target OU
$targetOU = "OU=TestDev,OU=Texas,DC=verticalcable,DC=local"

# Load users from CSV
$usersRaw = Import-Csv -Path "C:\Users\paulo\Desktop\ActiveDirectory\TestDev\EmployeeActiveDirectoryAccounts(Employee List).csv"

# Debug: Show headers once
Write-Host "Detected Columns:" -ForegroundColor Cyan
$usersRaw[0].PSObject.Properties.Name | ForEach-Object { Write-Host " - $_" }

# Main loop
foreach ($user in $usersRaw) {
    $sam = $user.'sAMAccountName'.Trim()

    # Validate sAMAccountName
    if (-not $sam -or $sam -match '[^a-zA-Z0-9.-]') {
        Write-Host "Skipping: Invalid or missing sAMAccountName for '$($user.'Employee Name')'" -ForegroundColor Yellow
        continue
    }

    $existingUser = Get-ADUser -Filter { SamAccountName -eq $sam } -ErrorAction SilentlyContinue

    if ($existingUser) {
        Write-Host "User '$sam' already exists. Updating attributes..." -ForegroundColor Cyan

        try {
            Set-ADUser -Identity $sam `
                -Title $user.'Job Title'.Trim() `
                -Department $user.'Department'.Trim() `
                -EmployeeID $user.'Employee ID'.Trim() `
                -UserPrincipalName ($sam + "@transcableusa.com") `
                -Description "Start Date: $($user.'Start Date')"

            # Update extensionAttributes only if values are provided
            $otherAttributes = @{}
            if ($user.'Employment Status')             { $otherAttributes['extensionAttribute1'] = $user.'Employment Status'.Trim() }
            if ($user.'System Access')                 { $otherAttributes['extensionAttribute2'] = $user.'System Access'.Trim() }
            if ($user.'Role-Based Access Level')       { $otherAttributes['extensionAttribute3'] = $user.'Role-Based Access Level'.Trim() }
            if ($user.'MFA Enabled')                   { $otherAttributes['extensionAttribute4'] = $user.'MFA Enabled'.Trim() }
            if ($user.'Background Check Complete')     { $otherAttributes['extensionAttribute5'] = $user.'Background Check Complete'.Trim() }

            if ($otherAttributes.Count -gt 0) {
                Set-ADUser -Identity $sam -Replace $otherAttributes
            }

            Write-Host "Updated user: $($user.'Employee Name')" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to update user: $($user.'Employee Name') - $_" -ForegroundColor Red
        }

        continue
    }

    # For new users, set secure password
    $securePassword = ConvertTo-SecureString "Xy!9z@T2#kL7&mQp" -AsPlainText -Force

    try {
        New-ADUser `
            -Name $user.'Employee Name'.Trim() `
            -SamAccountName $sam `
            -UserPrincipalName ($sam + "@transcableusa.com") `
            -AccountPassword $securePassword `
            -Enabled $true `
            -GivenName ($user.'Employee Name' -split ' ')[0] `
            -Surname ($user.'Employee Name' -split ' ')[1] `
            -Title $user.'Job Title'.Trim() `
            -Department $user.'Department'.Trim() `
            -EmployeeID $user.'Employee ID'.Trim() `
            -Description "Start Date: $($user.'Start Date')" `
            -Path $targetOU

        # Now apply optional attributes after creation
        $otherAttributes = @{}
        if ($user.'Employment Status')             { $otherAttributes['extensionAttribute1'] = $user.'Employment Status'.Trim() }
        if ($user.'System Access')                 { $otherAttributes['extensionAttribute2'] = $user.'System Access'.Trim() }
        if ($user.'Role-Based Access Level')       { $otherAttributes['extensionAttribute3'] = $user.'Role-Based Access Level'.Trim() }
        if ($user.'MFA Enabled')                   { $otherAttributes['extensionAttribute4'] = $user.'MFA Enabled'.Trim() }
        if ($user.'Background Check Complete')     { $otherAttributes['extensionAttribute5'] = $user.'Background Check Complete'.Trim() }

        if ($otherAttributes.Count -gt 0) {
            Set-ADUser -Identity $sam -Replace $otherAttributes
        }

        Write-Host "Created user: $($user.'Employee Name')" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create user: $($user.'Employee Name') - $_" -ForegroundColor Red
    }
}
