# Define parameters
$smtpServer = "smtp.office365.com"
$smtpPort = 587
$from = "rubicon@transcableusa.com"
$to = "paulo@transcableusa.com"
$subject = "SMTP AUTH Test"
$body = "This is a test message from [rubicon@transcableusa.com] using PowerShell SMTP AUTH and STARTTLS."

# Prompt for password securely
$securePassword = Read-Host "Enter password for $from" -AsSecureString
$credential = New-Object System.Management.Automation.PSCredential($from, $securePassword)

# Convert to plain text for SmtpClient (this is safe for test use only)
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
)

# Create SMTP client
$smtp = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
$smtp.EnableSsl = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($from, $plainPassword)

# Create message
$message = New-Object System.Net.Mail.MailMessage $from, $to, $subject, $body

try {
    $smtp.Send($message)
    Write-Host "✅ Email sent successfully." -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to send email." -ForegroundColor Red
    Write-Host $_.Exception.Message
}
