#requires -version 5.1
param(
	[Parameter(Mandatory = $true)]
	[string]$Filename,   # Full filename incl. extension

	[int]$ByteSize = 1024
)

$ErrorActionPreference = 'Stop'

# === Load constants and modules ===
. "$PSScriptRoot\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "Logging.psm1")

# === FUNCTIONS ===

function Test-PasswordFileExists {
	param([string]$OutFile)

	if (Test-Path $OutFile) { return $true }
	return $false
}

function New-PasswordFile {
	param(
		[string]$OutFile,
		[int]$ByteSize
	)

	if (-not (Test-Path $SECRETS_DIR)) {
		New-Item -ItemType Directory -Path $SECRETS_DIR | Out-Null
	}

	Write-LogLine "Generating password..."
	Add-Type -AssemblyName System.Security
	$bytes = New-Object byte[] $ByteSize
	[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
	$securePassword = [Convert]::ToBase64String($bytes)

	Set-Content -Path $OutFile -Value $securePassword -Encoding utf8
	Write-LogLine "Password saved to: $OutFile."
	Write-LogLine ""
	Write-LogLine "WARNING: This password file is CRITICAL for repository access!"
	Write-LogLine "         Store it in a safe place outside the backup."
	Write-LogLine "         Without this password, the backup repository CANNOT be accessed anymore."
}

# === MAIN ===
Start-LogBlock "Password Generation"

if ($ByteSize -lt 1) {
	Write-LogLine "Error: Byte size must be at least 1."
	Stop-LogBlock "Password Generation"
	exit 1
}

$OutFile = Join-Path $SECRETS_DIR $Filename

if (-not (Test-PasswordFileExists -OutFile $OutFile)) {
	New-PasswordFile -OutFile $OutFile -ByteSize $ByteSize
	Stop-LogBlock "Password Generation"
	exit 0
}
else {
	Stop-LogBlock "Password Generation"
	exit 1
}
