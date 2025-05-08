# Import the Active Directory module
Import-Module ActiveDirectory

# Get current date/time for filename
$timestamp = Get-Date -Format "MM-dd-yyyy_HH-mm-ss"

# Define output file path with timestamp
$outputDir = "C:\Users\paulo\Desktop\ActiveDirectory"
$outputFile = "$outputDir\LockedAccounts_$timestamp.txt"

# Ensure the output directory exists
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory
}

# Get all locked user accounts
$lockedAccounts = Search-ADAccount -LockedOut -UsersOnly

# Format and write results to the file
if ($lockedAccounts) {
    $formatted = $lockedAccounts | Select-Object Name, SamAccountName, DistinguishedName | Format-Table -AutoSize | Out-String
    #$formatted | Set-Content -Path $outputFile

    # Send output to default printer
    #$formatted | Out-Printer
    #Write-Host "Locked accounts written to $outputFile and sent to printer." -ForegroundColor Green

    # Write to STDOUT
    Write-Host $formatted
} else {
    $message = "No locked accounts found."
    #$message | Set-Content -Path $outputFile
    #$message | Out-Printer
    Write-Host $message -ForegroundColor Green
}

