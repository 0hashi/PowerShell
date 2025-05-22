Send-MailMessage -From "rubicon@transcableusa.com" `
  -To "paulo@transcableusa.com" `
  -Subject "SMTP Test from PowerShell" `
  -Body "This is a test email." `
  -SmtpServer "smtp.office365.com" `
  -Port 587 `
  -UseSsl `
  -Credential (Get-Credential)

  # Check if SMTP AUTH is enabled:
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
Import-Module ExchangeOnlineManagement

Get-CASMailbox -Identity rubicon@transcableusa.com | Select SmtpClientAuthenticationDisabled

# Test connection
Connect-ExchangeOnline -UserPrincipalName pohashi@transcableusa.com -Device
