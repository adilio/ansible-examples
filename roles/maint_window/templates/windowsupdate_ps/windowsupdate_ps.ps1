# {{ ansible_managed }}
# Source: {{ template_fullpath }}
# Host: {{ template_host }}
# Tested on: Windows Server 2012R2

Import-Module C:\DRS\Scripts\windowsupdate_ps\PSWindowsUpdate

$date = date -f yyyyMMdd-HHmmss
$pc = $env:COMPUTERNAME

$smtp_server = "smtp.interchange.ubc.ca"
$smtp = New-Object Net.Mail.SmtpClient($smtp_server)
$smtp_from = "no-reply@ubc.ca"
$smtp_to = "bis.systems@ubc.ca"
	
# Checks if there is a pending restart required.
# If there is a pending restart, customizes team email,
# performs Auto-Reboot, and triggers re-run of task.
if (Get-WURebootStatus -Silent) {
    $subject = "[$pc] Restarting Now for Pending Updates"
    $body = @()

    $style = "<style>"
    $style = $style + "TH{padding-left: 10px;text-align: left;}"
    $style = $style + "TD{padding-left: 10px;}"
    $style = $style + "</style>"

    $message = New-Object System.Net.Mail.MailMessage $smtp_from, $smtp_to
    $message.Subject = $subject
    $message.IsBodyHTML = $true

    $body += "<html><head>$style</head><body>"
    $body += "Server will be rebooted now, as a restart is pending for update installation."
    $body += "<br><br>"
    $body += "Task 'maintenance_windows_update' will be triggered after reboot."
    $body += "</body></html>"
	
    $message.Body = $body
	
	# Create a one-time task to trigger update script at next startup, after reboot, and delete task once complete
	schtasks.exe /create /f /tn MaintUpdate /ru SYSTEM /sc ONSTART /tr "powershell.exe -executionpolicy bypass -command 'C:\DRS\Scripts\windowsupdate_ps\windowsupdate_ps.ps1 ; schtasks.exe /delete /f /tn MaintUpdate'"
	Start-Sleep 5

	# Run with -AutoReboot flag to trigger reboot
    Get-WURebootStatus -AutoReboot
}

# If there is no pending restart, proceed with searching for/installing updates
# and customizes email to be sent to team.
else {
    Restart-Service -Name wuauserv -Force

    $result = Get-WUInstall -IgnoreReboot -AcceptAll
    #$result = Get-WUInstall -ListOnly

    # Creates maintenance subfolder under C:\DRS if it doesn't already exist for logs storage
    if ($(Test-Path "C:\drs\logs\maintenance") -eq $false) {
        New-Item -Path "C:\drs\logs\maintenance" -ItemType Directory -Force
    }

    $result | Set-Content -Path "C:\drs\logs\maintenance\maintenance_log_$date.log"

    $changelog_date = get-date -f "h:mm tt yyy-MM-dd"
    $changelog_entry = "`r`n$changelog_date`r`nInstalled updates as per maintenance schedule and restarted."
    $changelog_path = "C:\DRS\Logs\changelog.txt"

	if ($result.count -gt 0)
	{
		# If applying of any updates fails, update email subject
		if ($result -like "*Failed*") {
			$subject = "[$pc] Update Failure"
			$changelog_entry | Add-Content -Path $changelog_path
		}
		else {
			$subject = "[$pc] Updates Completed"
			$changelog_entry | Add-Content -Path $changelog_path
		}		
	}
	else
	{
		$subject = "[$pc] No Updates to Install"
	}
	$body = @()

    $style = "<style>"
    $style = $style + "TH{padding-left: 10px;text-align: left;}"
    $style = $style + "TD{padding-left: 10px;}"
    $style = $style + "</style>"

    $message = New-Object System.Net.Mail.MailMessage $smtp_from, $smtp_to
    $message.Subject = $subject
    $message.IsBodyHTML = $true

    $body += "<html><head>$style</head><body>"

    if ($result.count -gt 0) {
        $body += $result | Select-Object Status, KB, Size, Title | convertto-html -fragment
    }
    else {
        $body += "0 Updates to Install"
    }

    $body += "</body></html>"
	
    $message.Body = $body
}

# Sends email to team based on updates status.
$smtp.Send($message)
