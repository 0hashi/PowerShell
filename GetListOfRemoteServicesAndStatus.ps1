# Status definitions:
# 1 = Stopped
# 2 = StartPending
# 3 = StopPending
# 4 = Running
# 5 = ContinuePending
# 6 = PausePending
# 7 = Paused


# Define the remote computer
$RemoteComputer = "IT01"  # Replace with your target system

function Show-ServiceMenu {
    param (
        [array]$services
    )

    Write-Host "`n--- Services on $RemoteComputer ---`n"
    for ($i = 0; $i -lt $services.Count; $i++) {
        $svc = $services[$i]
        Write-Host "$i. [$($svc.Status)] $($svc.Name) - $($svc.DisplayName)"
    }
    Write-Host "`nX. Exit"
}

do {
    # Get and sort services from remote machine
    $services = Invoke-Command -ComputerName $RemoteComputer -ScriptBlock {
        Get-Service | Select-Object Name, DisplayName, Status
    } | Sort-Object Status, Name

    $servicesArray = @($services)

    # Show menu
    Show-ServiceMenu -services $servicesArray

    # Prompt for input
    $selection = Read-Host "`nEnter the number of the service to manage (or 'X' to exit)"

    if ($selection -match '^[xX]$') {
        Write-Host "Exiting..."
        break
    }

    if ($selection -match '^\d+$' -and $selection -ge 0 -and $selection -lt $servicesArray.Count) {
        $selectedService = $servicesArray[$selection]

        # Ask for action: start or stop
        $action = Read-Host "Do you want to Start or Stop '$($selectedService.DisplayName)'? (S=start, T=stop, X=cancel)"

        switch ($action.ToUpper()) {
            'S' {
                Invoke-Command -ComputerName $RemoteComputer -ScriptBlock {
                    param($name)
                    $svc = Get-Service -Name $name
                    if ($svc.Status -ne 'Running') {
                        Start-Service -Name $name
                        Start-Sleep -Seconds 2
                        $svc = Get-Service -Name $name
                        Write-Host "`n[$name] started. Current status: $($svc.Status)" -ForegroundColor Green
                    } else {
                        Write-Host "`n[$name] is already running." -ForegroundColor Yellow
                    }
                } -ArgumentList $selectedService.Name
            }
            'T' {
                Invoke-Command -ComputerName $RemoteComputer -ScriptBlock {
                    param($name)
                    $svc = Get-Service -Name $name
                    if ($svc.Status -eq 'Running') {
                        Stop-Service -Name $name -Force
                        Start-Sleep -Seconds 2
                        $svc = Get-Service -Name $name
                        Write-Host "`n[$name] stopped. Current status: $($svc.Status)" -ForegroundColor Cyan
                    } else {
                        Write-Host "`n[$name] is not running." -ForegroundColor Yellow
                    }
                } -ArgumentList $selectedService.Name
            }
            default {
                Write-Host "Action cancelled." -ForegroundColor DarkGray
            }
        }
    } else {
        Write-Host "Invalid selection. Please enter a valid number or 'X' to exit." -ForegroundColor Red
    }

} while ($true)
