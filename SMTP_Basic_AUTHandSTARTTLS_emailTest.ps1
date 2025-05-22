# Raw test using basic SMTP AUTH
$smtpServer = "smtp.office365.com"
$smtpPort = 587
$from = "rubicon@transcableusa.com"
$to = "paulo@transcableusa.com"
$subject = "Rubicon ERP Basic SMTP AUTH Test"
$body = "Testing SMTP Basic Auth from ERP"

$securePassword = Read-Host "Enter password for $from" -AsSecureString
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
)

$smtp = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
$smtp.EnableSsl = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($from, $plainPassword)
$message = New-Object System.Net.Mail.MailMessage $from, $to, $subject, $body

try {
    $smtp.Send($message)
    Write-Host "✅ Basic SMTP AUTH test succeeded." -ForegroundColor Green
} catch {
    Write-Host "❌ SMTP AUTH failed: $($_.Exception.Message)" -ForegroundColor Red
}
