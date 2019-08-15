#####################################################################################
#
# v1.06 2012-03-08 created by Michael Pal
# v1.07 2018-01-25 EL
# v1.08 2019-06-07 DL
# - renamed global config to sqlbkpconfig.xml for Ansible automation
# - change email sender address, remove from emailconfig.xml
# 
#####################################################################################
$scriptpath = $MyInvocation.MyCommand.Path
$scriptpath = Split-Path $scriptpath

. $scriptpath\functions\logging_functions.ps1


. $scriptpath\functions\format_date.ps1
. $scriptpath\functions\db_functions.ps1
. $scriptpath\functions\sql_db_functions.ps1


$localhost = (gci env:COMPUTERNAME).value
$sqlbkpconfig = "$scriptpath\etc\sqlbkpconfig.xml"
$errorResult = @{}
$errorCatastrophic = $false

$logFilePath = "C:\DRS\Logs\sql_maintenance"
if (!(test-path $logFilePath)) {
	new-item -path $logFilePath -type Directory
}
$log = "$logFilePath\$localhost-$(date -f yyyyMMdd-hhmmss).log"
$logger = log_config $log $scriptpath

$sender = "sql_maintenance@$($localhost.ToLower()).ead.ubc.ca"
if (test-path "$scriptpath\etc\emailconfig.xml") {
	$email = [xml](gc "$scriptpath\etc\emailconfig.xml")
	$recipients = $email.email.recipients
} else {
	$errorResult.Add("Email Configuration","Email Configuration file not found at $scriptpath\etc\emailconfig.xml!")
	$recipients = "ubcit.bislog@ubc.ca"
}

if (test-path $sqlbkpconfig) {
	$settings = [xml](gc $sqlbkpconfig)
	$server = $settings.config.sqlserver.instance.name
	[array]$databases = $settings.config.sqlserver.databases.name
	$sqlver = $settings.config.sqlserver.version.number
	$options = $settings.config.sqlserver.options
	$checkIntegrity = $options.checkIntegrity.enabled
	$indexDefrag = $options.indexDefrag.enabled
	$updateStatistics = $options.updateStatistics.enabled
	$backupDatabase = $options.backupDatabase.enabled
	$backupLocation = $options.backupDatabase.location
	$moveFiles = $options.movefiles.enabled
	$moveFileSource = $options.movefiles.sourcefolder
	$moveFileTarget = $options.movefiles.targetfolder
	$cleanupFiles = $options.cleanupFiles.enabled
	$cleanupFileSource = $options.cleanupFiles.sourcefolder
	$cleanupFileAgeDays = $options.cleanupFiles.fileagedays
	#$compression = $options.compression.enabled
	$compression = $false
	$backupResult = $false
	$cleanupFilesResult = $false
	$checkIntegrityResult = $false


} else {
	$errorResult.Add("Global Configuration File","Global Configuration File not found at $sqlbkpconfig")  # CHEcK THIS!
	$errorCatastrophic = $true
}

if ($errorCatastrophic -eq $false) {

	#Start-Transcript -Path $log

	Trap {
		$err = $_.Exception
		while ( $err.InnerException )
			{
			$err = $err.InnerException
			write-output $err.Message
		};
		continue
	}

	$logger.info("Start of Maintenance Sequence.")

	#Version of assembly to use
	if ($sqlver -eq 2005) {
		$version = 9
	} elseif ($sqlvers -eq 2008) {
		$version = 10
	} elseif ($sqlver -eq 2012) {
		$version = 11
	} elseif ($sqlver -eq 2014) {
		$version = 12
	} elseif ($sqlver -eq 2016) {
		$version = 13
	} elseif ($sqlver -eq 2017) {
		$version = 14
	} else {
		$version = 10
	}
	
	$logger.info("Begin Loading SQL Assemblies.")
	load_assemblies "Microsoft.SqlServer.SMO" $version
	load_assemblies "Microsoft.SqlServer.SmoExtended" $version
	load_assemblies "Microsoft.SqlServer.ConnectionInfo" $version
	load_assemblies "Microsoft.SqlServer.SqlEnum" $version
	

	$logger.info("Creating Sql Server Object $server.")
	try 
	{
		$svr = new-object "Microsoft.SqlServer.Management.SMO.Server" $server
		$logger.info("Successfully Created Sql Server Object $server.")
	}
	catch
	{
		$logger.error("Failed to create Sql Server Object $server.  Exiting...")
		exit
	}

	
	$svr.ConnectionContext.StatementTimeout = 3600

	$sqlVer = $svr.VersionString.SubString(0,4)

	$logger.info("Processing $server SQL Version $($svr.VersionString)")

	if ($cleanupFiles -eq 0) { $logger.warn("Skipping Cleaning up of Database files.") }
	if ($checkIntegrity -eq 0) { $logger.warn("Skipping Table Integrity checks.") }
	if ($indexDefrag -eq 0) { $logger.warn("Skipping Index Defragmentation.") }
	if ($updateStatistics -eq 0) { $logger.warn("Skipping Updating Statistics.") }
	if ($backupDatabase -eq 0) { $logger.warn("Skipping Backing up of Database.") }
	if ($moveFiles -eq 0) { $logger.warn("Skipping Move of Database Files.") }

	[array]$dbs = @()

	$databases | %{ 
		try
		{
			$tempDB = new-object "Microsoft.SqlServer.Management.SMO.Database" -ErrorAction Stop
			$tempDB = $svr.Databases[$_]
			$dbs += $tempDB
		}
		catch
		{
			$logger.error("Failed to create Database object $_")
		}
		
	}

	if ($cleanupFiles -eq 1) {
		$logger.info("Performing Cleaning up of Database files")
		foreach ($db in $dbs) {
			$dbName = $db.Name
			$folder = "$cleanupFileSource\$dbName\"
			clean_files $folder $cleanupFileAgeDays
		}
	}

	if ($checkIntegrity -eq 1) {
		$logger.info("Performing Integrity Checks...")
		foreach ($db in $dbs) {
			$dbName = $db.Name
			check_table_integ $db
		}
	}



	if ($indexDefrag -eq 1) {
		$logger.info("Performing Index Defragmentation...")
		foreach ($db in $dbs) {
			foreach ($table in $db.tables) {
				# pass in $db object also for calculating space available
				maint_index_frag $table $sqlVer $db
			}
		}
	}

	if ($updateStatistics -eq 1) {
		$logger.info("Performing Update of Statistics...")
		foreach ($db in $dbs) {
			foreach ($table in $db.tables) {
				update_stats $table
			}
		}
	}

	if ($backupDatabase -eq 1) {
		$logger.info("Performing Database Backups...")
		foreach ($db in $dbs) {
			$dbName = $db.Name
			backup_db $svr $db $backupLocation $cleanupFileAgeDays $compression
		}
	}

	if ($moveFiles -eq 1) {
		$logger.info("Performing Move of Files to Remote Location...")
		move_files $moveFileSource $moveFileTarget
	}

	if ((gc $log | Select-String -CaseSensitive "ERROR" ).count -gt 0) {
		$errorSubjectLine = $true
	}	


	$svr.ConnectionContext.StatementTimeout = 1200

	#Stop-Transcript

}

$logger.info("End of Maintenance Sequence.")
$logger.Logger.Repository.Shutdown()
[string]$from = $sender

[string[]]$to = $recipients

if ($errorSubjectLine -eq $true) {
	[string]$subject = "[$Server] FAILED! Database Maintenance Tasks"
} else {
	[string]$subject = "[$Server] PASSED! Database Maintenance Tasks"
}


[string]$body = (gc $log) | out-string

send-mailmessage -from $from -to $to -subject $subject -body $body -smtpServer $email.email.smtpServer

