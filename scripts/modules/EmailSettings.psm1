# === Get email settings from file ===
function Get-EmailSettings {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]$Path
	)

	if (-not (Test-Path $Path)) {
		throw "File not found: $Path"
	}

	$lines = Get-Content $Path | Where-Object { $_ -match "=" }
	$map = @{}

	foreach ($line in $lines) {
		$parts = $line -split "=", 2
		$key = $parts[0].Trim()
		$value = $parts[1].Trim()
		$map[$key] = $value
	}

	$requiredKeys = @("From", "To", "SmtpServer", "Port", "PasswordEncrypted")
	foreach ($key in $requiredKeys) {
		if (-not $map.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($map[$key])) {
			throw "Missing or empty key '$key' in settings file: $Path"
		}
	}

	$securePassword = ConvertTo-SecureString $map["PasswordEncrypted"]
	$credential = New-Object System.Management.Automation.PSCredential ($map["From"], $securePassword)

	return @{
		From       = $map["From"]
		To         = $map["To"]
		SmtpServer = $map["SmtpServer"]
		Port       = [int]$map["Port"]
		Credential = $credential
	}
}

# === Export email settings to file ===
function Export-EmailSettings {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]$Path,

		[Parameter(Mandatory)]
		[string]$From,

		[Parameter(Mandatory)]
		[string]$To,

		[Parameter(Mandatory)]
		[string]$SmtpServer,

		[Parameter(Mandatory)]
		[int]$Port,

		[Parameter(Mandatory)]
		[SecureString]$SecurePassword
	)

	$encrypted = ConvertFrom-SecureString $SecurePassword

	$content = @(
		"From=$From"
		"To=$To"
		"SmtpServer=$SmtpServer"
		"Port=$Port"
		"PasswordEncrypted=$encrypted"
	)

	Set-Content -Path $Path -Value $content -Encoding UTF8
}
