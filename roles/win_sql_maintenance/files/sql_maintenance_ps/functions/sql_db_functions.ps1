#####################################################################################
#
# v1.07 2012-12-06 created by Michael Pal
# v1.08 2018-01-25 EL
# v1.09 2019-04-26 DL
# - INC1090943 rebuild larger index >5GB and ensure enough space available
# - INC1320975 fix function check_table_integ to properly catch exceptions in $db.CheckTables()
# 
#####################################################################################


function load_assemblies {
	param([string]$name, $UseVersion)

	try
	{
		add-type -path $(ls (ls "C:\Windows\assembly\GAC_MSIL\$name\$UseVersion*" | select -exp fullname -First 1) | select -exp fullname -First 1) -ErrorAction Stop
	}
	catch
	{
		$logger.error("Fail to load assembly : $name")
		$logger.error("Check SQL version specified in server config file")
	}
}

function backup_db {
	param ($server, $database, [string]$backupDir, $days, [bool]$compression)
	
	$errorBackup = $false
	$timestamp = Get-Date -Format yyyyMMddHHmmss
	$recoverymod = $database.DatabaseOptions.RecoveryModel
	$dbName = $database.Name
	
	if (!(test-path "$backupDir\$dbname")) {
		$logger.warn($(New-Item -Path "$backupDir\$dbname" -Type Directory | out-string))
	}
	$backupFile = $backupDir + "\" + $dbname + "\" + $dbName + "_db_" + $timestamp + ".bak"
		
	$logger.info("Creating Sql Server Backup Object.")
	try 
	{
		$smoBackup = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Backup -ErrorAction Stop
		$logger.info("Successfully created Sql Server Backup Object.")
	}
	catch
	{
		$logger.error("Failed to create Sql Server Backup Object.")
		$errorBackup = $true
	}
	
	
	$smoBackup.Action = [Microsoft.SqlServer.Management.SMO.BackupActionType]::Database
	
	$smoBackup.BackupSetDescription = "Full Backup of " + $dbName
	$smoBackup.BackupSetName = "$dbName-$timestamp-Backup"
	$smoBackup.Database = $dbName
	$smoBackup.MediaDescription = "Disk"
	
	if ($compression) {
		$smoBackup.CompressionOption = [Microsoft.SqlServer.Management.Smo.BackupCompressionOptions]::On
	}
	
	$deviceType = [Microsoft.SqlServer.Management.SMO.DeviceType]::File
	$backupDeviceItem = New-Object -TypeName Microsoft.SqlServer.Management.SMO.BackupDeviceItem -argumentlist $backupFile, $deviceType
	$smoBackup.Devices.Add($backupDeviceItem)
	
	$smoBackup.Incremental = $false
	$smoBackup.ExpirationDate = (get-date).AddDays($days)
	$smoBackup.LogTruncation = [Microsoft.SqlServer.Management.SMO.BackupTruncateLogType]::Truncate
	
	$logger.info("Backing up Database $database to $backupFile.")
	try
	{
		$smoBackup.SqlBackup($server)
		$logger.info("Successfully completed backup.")
		if ((test-Path $backupFile) -eq $true) {
			$logger.info("$backupFile Exists.")
		} else {
			$logger.error("$backupFile does not Exists.")
			$errorBackup = $true
		}
	}
	catch
	{
		$logger.error("Backup failed.")
	}
	
	
	$smoBackup.Devices.Remove($backupDeviceItem) | out-null

}

function update_stats {
	param ($table)
		
	$logger.info("Updating table statistics for $table.")
	$table.UpdateStatistics("all","percent", 50)
	$logger.info("Completed updating table statistics for $table.")
}

function maint_index_frag {
	param ($table,$sqlVer, $db)
	
	$reorganized = 0
	$reorgFragThreshold = 10.00
	$rebuildFragThreshold = 30.00
	# threshold index size, in bytes, of the index at which to rebuild instead of reorg
	$indexSizeThreshold = 5*1024*1024*1024
	# space available, in bytes, on the disk volume where the primary db data file resides
	$drv1 = Split-Path $db.PrimaryFilePath -Qualifier
	$dsk1 = Get-WMIObject Win32_Logicaldisk -filter "deviceid='$drv1'"
	$dbVolSpaceAvail = $dsk1.FreeSpace
	# this doesn't quite seem to work consistently
	#$dbVolSpaceAvail = (Get-Volume ((Split-Path $db.PrimaryFilePath -Qualifier) -replace ":","")).SizeRemaining
	# total space available, in bytes, including db data file space available
	$totVolSpaceAvail = $dbVolSpaceAvail + $db.SpaceAvailable*1024
	
	foreach ($index in $table.Indexes.Where{$_.Name -notin @("syscolumns","syscomments")} ) {
		$tableIndexes = $index.EnumFragmentation()
		$tableIndexes | %{
			$Index_Name = $_.Index_Name;
			if ([float]$sqlVer -lt 9.0) {
				$avgFrag = $_.LogicalFragmentation
			} else {
				$avgFrag = $_.AverageFragmentation
			}
			$avgFragNum = "{0:N2}%" -f $avgFrag
			$o1 = $_.Index_Name
			$o2 = $table.Name
			$o3 = $db.Name
			$o4 = $_.Index_Type
			$o5 = $_.Pages*8
			$logger.info("----------")
			$logger.info("Index:$o1.$o2.$o3, Type:$o4, Size:${o5}kB, Avg Frag:$avgFragNum")
			
			# rebuild/reorg? Rebuild will use diskspace equal to the index size during the process, reorg will not.
			# Determine which to do based on conditions. In case of rebuild, update $totVolSpaceAvail after the operation
			if ($avgFrag -gt $reorgFragThreshold) {
				# calculate size of index, in bytes
				$indexSize = $_.Pages*8*1024
				$t1 = [math]::round($indexSize/1Gb, 2)
				$t2 = [math]::round($totVolSpaceAvail/1Gb, 2)
				$t3 = [math]::round($indexSizeThreshold/1Gb, 2)
				# acronyms for determining whether to rebuild or reorg
				# DISKOK | DISKNO - sufficient | not sufficient diskspace for rebuild
				# IDXLRG | IDXSML - index larger | not larger than $indexSizeThreshold
				# THRSRB | THRSRO - > $rebuildFragThreshold | <= $rebuildFragThreshold
				if ($indexSize -lt $totVolSpaceAvail -and ($indexSize -gt $indexSizeThreshold -or $avgFrag -gt $rebuildFragThreshold)) {
					$logger.warn("$Index_Name is $avgFragNum fragmented and will be rebuilt.")
					if ($indexSize -lt $totVolSpaceAvail) {
						$logger.warn("  DISKOK:${t2}Gb diskspace available, sufficient for rebuild")
					}
					if ($indexSize -gt $indexSizeThreshold) {
						$logger.warn("  IDXLRG:Index size ${t1}Gb>${t3}Gb threshold for rebuild")
					}
					if ($avgFrag -gt $rebuildFragThreshold) {
						$logger.warn("  THRSRB:>${rebuildFragThreshold}% threshold needed for rebuild")
					}
					try
					{
						$timeResult = measure-command { $index.Rebuild() }
						$logger.info("$Index_Name has been rebuilt in $timeResult.")
					}
					catch
					{
						$logger.error("Failed to rebuild index $Index_Name")
					}
					# update $totVolSpaceAvail
					$totVolSpaceAvail = $totVolSpaceAvail - $indexSize
				}
				else {
					$logger.warn("$Index_Name is $avgFragNum fragmented and will be reorganized.")
					if ($indexSize -ge $totVolSpaceAvail) {
						$logger.warn("  DISKNO:${t2}Gb diskspace available insufficient for rebuild")
					}
					if ($indexSize -le $indexSizeThreshold) {
						$logger.warn("  IDXSML:Index size ${t1}Gb<=${t3}Gb threshold needed for rebuild")
					}
					if ($avgFrag -le $rebuildFragThreshold) {
						$logger.warn("  THRSRO:<=${rebuildFragThreshold}% threshold needed for rebuild")
					}
					try
					{
						$timeResult = measure-command { $index.Reorganize() }
						$reorganized = 1
						$logger.info("$Index_Name has been reorganized in $timeResult.")
					}
					catch
					{
						$logger.error("Failed to reorganize index $Index_Name")
					}
				}
			}
			# do nothing
			else {
				$logger.info("$Index_Name is $avgFragNum fragmented. No action is required.")
			}
		} # end foreach $tableIndexes
	} # end foreach $index
	if ($reorganized -eq 1) {
		update_stats $table
	}
}

function check_table_integ {
	param($db)
	
	$errorIntegrity = $false
	try {
		$timeResult = measure-command { $sc = $db.CheckTables([Microsoft.SqlServer.Management.SMO.RepairType]::None,[Microsoft.SqlServer.Management.Smo.RepairOptions]::AllErrorMessages) }
		$dbName = $db.Name
		try {
			$scResult = $sc.item($sc.count -2)
			[int]$checkAllocation = (($sc.item($sc.count -2)).split(" "))[2]
			[int]$checkConsistency = (($sc.item($sc.count -2)).split(" "))[6]
			if ($checkAllocation -eq 0 -AND $checkConsistency -eq 0) {
				$logger.info("$dbName Passed Integrity Checks. $timeResult")
				$logger.info($scResult)
			}
			if ($checkAllocation -ne 0) {
				$logger.info("$dbName FAILED Integrity Checks. $timeResult")
				$logger.info($scResult)
				$errorIntegrity = $true
			}
			if ($checkConsistency -ne 0) {
				$logger.info("$dbName FAILED Integrity Checks. $timeResult")
				$logger.info($scResult)
				$errorIntegrity = $true
			}
		}
		catch {
			$logger.error("Exception occurred, db.CheckTables() of $dbname did not return expected scResult.")
		}
	}
	catch {
		$logger.error("Exception occurred during db.CheckTables() of $dbname. Possible DBCC corruption, check SQL ERRORLOG.")
	}
}