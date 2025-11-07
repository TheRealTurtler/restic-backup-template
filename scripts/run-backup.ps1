#requires -version 5.1
param(
	[Parameter(Mandatory = $true)]
	[string]$ProfileName,

	[Parameter(Mandatory = $false)]
	[string]$Operation = "show",

	[Parameter(Mandatory = $false)]
	[string[]]$ExtraArgs
)

. "$PSScriptRoot\constants.ps1"

# Add BIN_DIR to PATH so resticprofile can find restic.exe
$env:PATH = "$BIN_DIR;" + $env:PATH

# Executable
$ResticProfileExe = (Join-Path $BIN_DIR "resticprofile.exe")

# === Unschedule profile ===
# ResticProfile cannot remove scheduled tasks itself on windows for whatever reason
function Invoke-Unschedule {
	param(
		[string]$ProfileName
	)

	$taskPath = '\resticprofile backup\'

	# Alle passenden Tasks suchen
	$tasks = Get-ScheduledTask | Where-Object {
		$_.TaskPath -eq $taskPath -and $_.TaskName -like "$ProfileName*"
	}

	if ($tasks) {
		foreach ($task in $tasks) {
			Write-Host ("Removing scheduled task: {0}{1}" -f $task.TaskPath, $task.TaskName)
			Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Confirm:$false
		}
		Write-Host "All matching schedules removed."
	}
	else {
		Write-Host ("No schedules found for profile '{0}'." -f $ProfileName)
	}
}

if ($Operation -eq "unschedule") {
	# Unschedule operation
	Invoke-Unschedule -ProfileName $ProfileName
	exit 0
}

# Validate executable
if (!(Test-Path $ResticProfileExe)) {
	Write-Host "resticprofile.exe not found: $ResticProfileExe"
	exit 1
}

# Build argument list
$ResticProfileArgs = @("--name", $ProfileName, $Operation)
if ($ExtraArgs) {
	$ResticProfileArgs += $ExtraArgs
}

# Run resticprofile
Write-Host "Running: $ResticProfileExe $($ResticProfileArgs -join ' ')"
& $ResticProfileExe @ResticProfileArgs
$exitCode = $LASTEXITCODE

exit $exitCode
