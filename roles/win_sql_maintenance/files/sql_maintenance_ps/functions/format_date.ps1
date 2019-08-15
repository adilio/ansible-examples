function format_date {
	# Format Date Strings

	return Get-Date -Format yyyyMMdd
}

function format_time {
	#Format Time Strings
	
	return Get-Date -Format HHmmss
}

function log_time {
	#return (get-date).ToLongTimeString()
	return Get-Date -Format HH:mm:ss
}