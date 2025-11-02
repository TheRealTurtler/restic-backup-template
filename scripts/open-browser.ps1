#requires -version 5.1
param(
	[Parameter(Mandatory = $true)]
	[string]$RepoPath,

	[Parameter(Mandatory = $true)]
	[string]$PasswordFile
)

. "$PSScriptRoot\constants.ps1"

$ResticExe = Join-Path $BIN_DIR "restic.exe"
$BrowserExe = Join-Path $BIN_DIR "restic-browser.exe"

# Validate executables
if (!(Test-Path $ResticExe)) { Write-Host "restic.exe not found: $ResticExe"; exit 1 }
if (!(Test-Path $BrowserExe)) { Write-Host "restic-browser.exe not found: $BrowserExe"; exit 1 }

# Launch restic-browser
Write-Host "Launching restic-browser..."

$BrowserArgs = "--restic `"$ResticExe`" --repo `"$RepoPath`" --password-file `"$PasswordFile`""
$proc = Start-Process -FilePath $BrowserExe -ArgumentList $BrowserArgs -PassThru
$proc.WaitForExit()
