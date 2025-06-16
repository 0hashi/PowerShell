# Import the Active Directory module (only needed once per session)
Import-Module ActiveDirectory

# Set the target OU (adjust as needed)
$targetOU = "OU=Texas,DC=verticalcable,DC=local"

# Get all users in the specified OU and include the whenCreated property
Get-ADUser -Filter * -SearchBase $targetOU -Properties whenCreated |
    Select-Object Name, SamAccountName, whenCreated |
    Sort-Object whenCreated |
    Format-Table Name, SamAccountName, whenCreated