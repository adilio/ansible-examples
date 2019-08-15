#####################################################################################
#
# Version 1.05
#
# Written on 12/06/2012
# By Michael Pal
# 
#####################################################################################



function create_log {
	param ([string]$logPath)
	
	if (!(Test-Path $logPath)) {
		Write-Host "Creating new log at $logPath"
		$log = New-Item -Path $logPath -type File -Force
	} else {
		Write-Host "Retrieving log file " -nonewline
		Write-Host "$logPath" -nonewline -foregroundcolor "CYAN"
		Write-Host "..." -nonewline
		
		$log = (gi $logPath)
	}
	
	return $log
}

function clean_files {
	param($folder, $ageDays)
	
	$cleanError = $false
	If (Test-Path $folder) {
		
		$fileAgeLimit = (get-date).AddDays(-$ageDays)
		
		$filesCleaned = 0
		if (($files = ls $folder) -ne $null) {
			$files | %{ 
				if ($_.CreationTime -lt $fileAgeLimit) {
					if (test-path $_.FullName) {
						try
						{
							$timeResult = measure-command { Remove-Item -Path $_.FullName -ErrorAction Stop }
							if (!(test-path $_.FullName)) {
								$logger.info("Removing old file $($_.FullName) Completed. $timeResult")
								$filesCleaned++
							} else {
								$logger.error("Removing old file $($_.FullName) Failed. $timeResult")
								$cleanError = $true
							}
						}
						catch
						{
							$logger.error("Exception occured while removing $($_.FullName).")
						}
					}
				}
			}
		}
		if ($filesCleaned -lt 1) {
			$logger.info("$folder Has no files old enough to clean up.")
		}
	} 
	else
	{
		$logger.warn("$folder Does not exist.  This may be the first run of the backup.")
	}
}

function move_files {
	param ([string]$source, [string]$target)
	
	$logger.info("Begining Robocopy.")
	$logger.info($(robocopy $source $target /MIR /NP /NDL /NFL /R:0 /W:0 | out-string))
}