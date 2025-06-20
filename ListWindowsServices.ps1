# WMI script
# Remote computer name
$remoteComputer = "srl-overhead"

# Query and sort services by Name
Get-WmiObject -Class Win32_Service -ComputerName $remoteComputer |
    Sort-Object Name |
    Select-Object Name, DisplayName, State, StartMode
