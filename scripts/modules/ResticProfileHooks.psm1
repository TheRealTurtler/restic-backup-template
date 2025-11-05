# === Convert string to trimmed form ===
# Returns empty string if null/whitespace, otherwise trimmed
function Convert-StringTrimmed {
	param([string]$Value)
	if ([string]::IsNullOrWhiteSpace($Value)) {
		return ""
	}
	return $Value.Trim()
}

# === Get system information ===
# Returns a hashtable with hostname, OS name, architecture, and Windows update version
function Get-SystemInfo {
	$hostname = $env:COMPUTERNAME
	$os = (Get-CimInstance Win32_OperatingSystem).Caption
	$architecture = $env:PROCESSOR_ARCHITECTURE
	$updateVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion -ErrorAction SilentlyContinue).DisplayVersion

	if ([string]::IsNullOrWhiteSpace($updateVersion)) {
		$updateVersion = "UNKNOWN"
	}

	return @{
		Hostname      = (Convert-StringTrimmed $hostname)
		OS            = (Convert-StringTrimmed $os)
		Architecture  = (Convert-StringTrimmed $architecture)
		UpdateVersion = (Convert-StringTrimmed $updateVersion)
	}
}

# === Get ResticProfile context ===
# Returns a hashtable with timestamp and Restic-related environment variables
function Get-ResticProfileContext {
	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

	return @{
		Timestamp    = (Convert-StringTrimmed $timestamp)
		ProfileName  = (Convert-StringTrimmed $env:PROFILE_NAME)
		Command      = (Convert-StringTrimmed $env:PROFILE_COMMAND)
		ExitCode     = (Convert-StringTrimmed $env:ERROR_EXIT_CODE)
		ErrorMessage = (Convert-StringTrimmed $env:ERROR)
		CommandLine  = (Convert-StringTrimmed $env:ERROR_COMMANDLINE)
		StderrOutput = (Convert-StringTrimmed $env:ERROR_STDERR)
	}
}

# === Format info report ===
# Builds a simple info report with ResticProfile context (Profile + Command)
function Format-ResticInfoReport {
	param ([hashtable]$Context)

	return @(
		"============================================================"
		" Resticprofile INFO [$($Context.Timestamp)]"
		"============================================================"
		"  Profile         : $($Context.ProfileName)"
		"  Command         : $($Context.Command)"
		"============================================================"
	) -join "`n"
}

# === Format failure report ===
# Combines system info and ResticProfile context into a structured failure report
function Format-ResticFailureReport {
	param (
		[hashtable]$SystemInfo,
		[hashtable]$Context
	)

	return @(
		"============================================================"
		" Resticprofile FAILURE [$($Context.Timestamp)]"
		"============================================================"
		"  System Information"
		"------------------------------------------------------------"
		"  Hostname        : $($SystemInfo.Hostname)"
		"  OS              : $($SystemInfo.OS)"
		"  Architecture    : $($SystemInfo.Architecture)"
		"  Update Version  : $($SystemInfo.UpdateVersion)"
		""
		"  ResticProfile Context"
		"------------------------------------------------------------"
		"  Profile         : $($Context.ProfileName)"
		"  Command         : $($Context.Command)"
		"  Exit Code       : $($Context.ExitCode)"
		""
		"  Error Message"
		"    $($Context.ErrorMessage)"
		""
		"  Command Line"
		"    $($Context.CommandLine)"
		""
		"  STDERR Output"
		"    $($Context.StderrOutput)"
		"============================================================"
	) -join "`n"
}

# === Write report to log file ===
# Appends a given report string to the log file for the current profile/command
function Write-ResticLog {
	param (
		[string]$Report,
		[hashtable]$Context
	)

	# Sanitize profile/command for filename
	$SafeProfile = ($Context.ProfileName -replace '[^\w\-]', '_')
	$SafeCommand = ($Context.Command -replace '[^\w\-]', '_')
	$LogFileName = "$SafeProfile" + "_" + "$SafeCommand" + ".log"
	$LogFilePath = Join-Path $LOG_DIR $LogFileName

	# Append report to log file using UTF8 without BOM
	[System.IO.File]::AppendAllText(
		$LogFilePath,
		$Report + "`r`n",
		[System.Text.UTF8Encoding]::new($false)
	)
}
