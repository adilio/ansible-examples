function log_config()
{
	param ([string]$pathToLogFile, [string]$scriptPath)
	$assembly = "$scriptPath\etc\log4net.dll"
	$config = "$scriptPath\etc\log.config"
	Add-Type -Path $assembly
	$fileInfo = New-Object System.IO.FileInfo($config)
	[log4net.GlobalContext]::Properties["LogFileName"] = $pathToLogFile
	[log4net.Config.XmlConfigurator]::Configure($fileInfo)
	$script:Logger = [log4net.LogManager]::GetLogger("root")
	return $Logger
}