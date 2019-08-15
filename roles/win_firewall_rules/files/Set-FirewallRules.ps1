<#
Set-FirewallRules.ps1
Sets the initial firewall rules on a Windows VM.
To be used as a part of win_firewall_rules Ansible role.
Note: $null used to suppress command output
20181204 - adil.leghari@ubc.ca
#>

# We would normally use Get-NetFirewallRule to check for existing rules
# However, this command is not available in Windows Server 2008 R2
# Hence, this is how we check for rule existence and not duplicate
$RuleName = 'All ICMP V4'
$RuleMatch = netsh advfirewall firewall show rule name="$RuleName" | Out-String
If ($RuleMatch -match "No rules match") {
  $null = netsh advfirewall firewall add rule name=$RuleName protocol=icmpv4 dir=in action=allow
}
$RuleName = 'Windows Remote Management (HTTPS-In)'
$RuleMatch = netsh advfirewall firewall show rule name="$RuleName" | Out-String
If ($RuleMatch -match "No rules match") {
  $null = netsh advfirewall firewall add rule name=$RuleName description='Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]' dir=in action=allow enable=yes localport=5986 protocol=TCP remoteip=137.82.171.224/27,10.20.3.67/32,142.103.146.209/32 profile=domain
}
$RuleName = 'Sophos RMS Service (TCP/8192-In)'
$RuleMatch = netsh advfirewall firewall show rule name="$RuleName" | Out-String
If ($RuleMatch -match "No rules match") {
  $null = netsh advfirewall firewall add rule name=$RuleName description='Inbound rule for Sophos RMS. [TCP 8192]' dir=in action=allow enable=yes localport=8192 protocol=TCP remoteip=137.82.196.81 profile=domain
}
$RuleName = 'Sophos RMS Service (TCP/8194-In)'
$RuleMatch = netsh advfirewall firewall show rule name="$RuleName" | Out-String
If ($RuleMatch -match "No rules match") {
  $null = netsh advfirewall firewall add rule name='Sophos RMS Service (TCP/8194-In)' description='Inbound rule for Sophos RMS. [TCP 8194]' dir=in action=allow enable=yes localport=8194 protocol=TCP remoteip=137.82.196.81 profile=domain
}

# These are existing rules that we are modifying
$null = netsh advfirewall firewall set rule name='Windows Remote Management (HTTP-In)' new enable=no
$null = netsh advfirewall firewall set rule name='Windows Remote Management (HTTP-In)' new enable=no
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (NB-Session-In)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (NB-Session-Out)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (SMB-In)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (SMB-Out)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (NB-Name-In)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (NB-Name-Out)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (NB-Datagram-In)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (NB-Datagram-Out)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (Spooler Service - RPC)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (Spooler Service - RPC-EPMAP)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (Echo Request - ICMPv4-In)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (Echo Request - ICMPv4-Out)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (Echo Request - ICMPv6-In)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (Echo Request - ICMPv6-Out)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (LLMNR-UDP-In)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='File and Printer Sharing (LLMNR-UDP-Out)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='Windows Management Instrumentation (WMI-In)' new enable=yes remoteip=137.82.171.224/27 profile=domain
$null = netsh advfirewall firewall set rule name='Remote Desktop - Shadow (TCP-In)' new enable=yes remoteip=137.82.171.224/27
$null = netsh advfirewall firewall set rule name='Remote Desktop - User Mode (TCP-In)' new enable=yes remoteip=137.82.171.224/27
$null = netsh advfirewall firewall set rule name='Remote Desktop - User Mode (UDP-In)' new enable=yes remoteip=137.82.171.224/27

# These are logging settings to limit filesize and make auditing easier
$null = netsh advfirewall set Domainprofile logging filename C:\DRS\Logs\Firewall\pfirewall_domain.log
$null = netsh advfirewall set Domainprofile logging maxfilesize 4096
$null = netsh advfirewall set Domainprofile logging droppedconnections enable
$null = netsh advfirewall set Domainprofile logging allowedconnections disable
$null = netsh advfirewall set Privateprofile logging filename C:\DRS\Logs\Firewall\pfirewall_private.log
$null = netsh advfirewall set Privateprofile logging maxfilesize 4096
$null = netsh advfirewall set Privateprofile logging droppedconnections enable
$null = netsh advfirewall set Privateprofile logging allowedconnections disable
$null = netsh advfirewall set Publicprofile logging filename C:\DRS\Logs\Firewall\pfirewall_public.log
$null = netsh advfirewall set Publicprofile logging maxfilesize 4096
$null = netsh advfirewall set Publicprofile logging droppedconnections enable
$null = netsh advfirewall set Publicprofile logging allowedconnections disable

# This logfile indicates that the script has been run (helps skip subsequent runs)
Add-Content -Value "[$(Get-Date -Format 'dd-MMM-yyyy HH:mm')]
Initial firewall settings have been applied via Ansible
Existence of this logfile will skip subsequent runs of ths role.
If you'd like to re-apply the role, delete this file." -Path "C:\DRS\Logs\Set-FirewallRules.txt"
