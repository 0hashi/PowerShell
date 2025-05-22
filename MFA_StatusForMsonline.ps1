# Import MSOnline module
Import-Module MSOnline

# Connect to Azure AD
Connect-MsolService

# Get all users and determine their MFA status
$users = Get-MsolUser -All | Select-Object DisplayName, UserPrincipalName, StrongAuthenticationRequirements

# Build report with MFA status
$mfaReport = $users | ForEach-Object {
    $status = if ($_.StrongAuthenticationRequirements.Count -eq 0) {
        "Disabled"
    } else {
        "Enabled"
    }

    [PSCustomObject]@{
        DisplayName       = $_.DisplayName
        UserPrincipalName = $_.UserPrincipalName
        MFAStatus         = $status
    }
}

# Group and display sorted results
$mfaReport | Sort-Object MFAStatus, DisplayName | Group-Object MFAStatus | ForEach-Object {
    Write-Host "`nMFA Status: $($_.Name) ($($_.Count) users)" -ForegroundColor Cyan
    $_.Group | Format-Table DisplayName, UserPrincipalName -AutoSize
}

# Show summary counts
$enabledCount = ($mfaReport | Where-Object { $_.MFAStatus -eq "Enabled" }).Count
$disabledCount = ($mfaReport | Where-Object { $_.MFAStatus -eq "Disabled" }).Count

Write-Host "`nSummary:" -ForegroundColor Yellow
Write-Host "-----------"
Write-Host "Enabled MFA Users : $enabledCount"
Write-Host "Disabled MFA Users: $disabledCount"
