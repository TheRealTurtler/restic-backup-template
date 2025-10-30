#requires -version 5.1
$ErrorActionPreference = 'Stop'

# === Load constants and modules ===
. "$PSScriptRoot\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "Logging.psm1")

# === Constants ===
$SECRET_DIR = "secrets"                      # Directory to store generated password files
$SECRET_EXTENSION = ".secret"                # File extension for password output
$DEFAULT_BYTE_SIZE = 1024                    # Default password size in bytes

# === INPUT HANDLING ===
[string]$Filename = $null
[int]$ByteSize = $null

if ($args.Count -ge 1) {
	$Filename = $args[0]
}
if ($args.Count -ge 2) {
	$ByteSize = [int]$args[1]
}

if (-not $Filename) {
	Write-LogLine "Please enter the following information:"
	$Filename = Read-Host "Enter filename for password (without extension)"
}

if (-not $ByteSize) {
	$ByteSize = Read-Host "Enter password size in bytes (default: $DEFAULT_BYTE_SIZE)"
	if (-not $ByteSize) {
		$ByteSize = $DEFAULT_BYTE_SIZE
	}
	else {
		$ByteSize = [int]$ByteSize
	}
}

# === VALIDATION ===
Start-LogBlock "Password Generation"

if (-not $Filename) {
	Write-LogLine "Error: No filename provided."
	Stop-LogBlock "Password Generation"
	exit 1
}
if ($ByteSize -lt 1) {
	Write-LogLine "Error: Byte size must be at least 1."
	Stop-LogBlock "Password Generation"
	exit 1
}

# === PATH SETUP ===
$OutFile = Join-Path $SECRET_DIR ($Filename + $SECRET_EXTENSION)

if (Test-Path $OutFile) {
	Write-LogLine "Error: Password file already exists: $OutFile."
	Write-LogLine "Aborting to prevent overwrite."
	Stop-LogBlock "Password Generation"
	exit 1
}

if (-not (Test-Path $SECRET_DIR)) {
	New-Item -ItemType Directory -Path $SECRET_DIR | Out-Null
}

# === PASSWORD GENERATION ===
Write-LogLine "Generating password..."
Add-Type -AssemblyName System.Security
$bytes = New-Object byte[] $ByteSize
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$securePassword = [Convert]::ToBase64String($bytes)

# === WRITE TO FILE ===
Set-Content -Path $OutFile -Value $securePassword -Encoding utf8
Write-LogLine "Password saved to: $OutFile."
Write-LogLine ""
Write-LogLine "WARNING: This password file is CRITICAL for repository access!"
Write-LogLine "         Store it in a safe place outside the backup."
Write-LogLine "         Without this password, the backup repository CANNOT be accessed anymore."
Stop-LogBlock "Password Generation"
exit 0
