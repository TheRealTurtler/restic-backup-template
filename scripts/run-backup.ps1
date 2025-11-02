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

# Executable
$ResticProfileExe = Join-Path $BIN_DIR "resticprofile.exe"

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
