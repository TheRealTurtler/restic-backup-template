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

# === Format HTML failure report ===
# Generates a styled HTML report for ResticProfile failures.
# Combines system info and context into tables and <pre> blocks for email delivery.
function Format-ResticFailureReportHtml {
	param (
		[hashtable]$SystemInfo,
		[hashtable]$Context
	)

	return @"
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      font-family: Consolas, monospace;
      background-color: #ffffff;
      color: #000000;
    }
    h2 {
      background-color: #c0392b;
      color: white;
      padding: 10px;
    }
    table {
      border-collapse: collapse;
      width: 100%;
      table-layout: fixed;
      margin-bottom: 20px;
    }
    th, td {
      width: 50%;
      padding: 6px;
      border-bottom: 1px solid #ccc;
      text-align: left;
    }
    th {
      background-color: #f2f2f2;
      font-weight: bold;
    }
    pre {
      background-color: #f9f9f9;
      padding: 10px;
      border: 1px solid #ddd;
      overflow-x: auto;
    }
  </style>
</head>
<body>

<h2>ResticProfile FAILURE [$($Context.Timestamp)]</h2>

<table>
  <thead><tr><th colspan="2">System Information</th></tr></thead>
  <tbody>
    <tr><td>Hostname</td><td>$($SystemInfo.Hostname)</td></tr>
    <tr><td>OS</td><td>$($SystemInfo.OS)</td></tr>
    <tr><td>Architecture</td><td>$($SystemInfo.Architecture)</td></tr>
    <tr><td>Update Version</td><td>$($SystemInfo.UpdateVersion)</td></tr>
  </tbody>
</table>

<table>
  <thead><tr><th colspan="2">ResticProfile Context</th></tr></thead>
  <tbody>
    <tr><td>Profile</td><td>$($Context.ProfileName)</td></tr>
    <tr><td>Command</td><td>$($Context.Command)</td></tr>
    <tr><td>Exit Code</td><td>$($Context.ExitCode)</td></tr>
  </tbody>
</table>

<h3>Error Message</h3>
<pre>$($Context.ErrorMessage)</pre>

<h3>Command Line</h3>
<pre>$($Context.CommandLine)</pre>

<h3>STDERR Output</h3>
<pre>$($Context.StderrOutput)</pre>

</body>
</html>
"@
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
