# Find all GPOs linked to an OU
#
# Define the OU distinguished name
$ou = "OU=Florida,DC=verticalcable,DC=local"

# Get GPO inheritance for that OU
$inheritance = Get-GPInheritance -Target $ou

# Safely loop through GPO links using correct property name: GpoId
$inheritance.GpoLinks | Where-Object { $_.GpoId } | ForEach-Object {
    $gpo = Get-GPO -Guid $_.GpoId
    [PSCustomObject]@{
        GPOName         = $gpo.DisplayName
        LinkEnabled     = $_.Enabled
        Enforced        = $_.Enforced
        UserEnabled     = $gpo.UserEnabled
        ComputerEnabled = $gpo.ComputerEnabled
        LinkLocation    = $ou
    }
} | Format-Table -AutoSize
