. "$PSScriptRoot\constants.ps1"

# Key constants for config variables
$CONFIG_KEY_USER_NAME = "USER_NAME"
$CONFIG_KEY_REPO_TYPE = "REPO_TYPE"
$CONFIG_KEY_REPO_BASEDIR = "REPO_BASE_DIR"
$CONFIG_KEY_PASSWORD_FILE = "PASSWORD_FILE"

function Get-ConfigVariables {
	param(
		[Parameter(Mandatory = $true)]
		[string]$ConfigFile
	)

	if (-not (Test-Path $ConfigFile)) {
		# Return empty hashtable if file does not exist
		return @{}
	}

	$vars = @{}

	foreach ($line in Get-Content $ConfigFile) {
		# Match lines like: {{ $USER_NAME := "value" }}
		if ($line -match '^\s*\{\{\s*\$(\w+)\s*:?=\s*"([^"]+)"\s*\}\}') {
			$vars[$matches[1]] = $matches[2]
		}
	}

	return $vars
}

function Test-ConfigValid {
	param(
		[Parameter(Mandatory = $true)]
		[hashtable]$ConfigVars
	)

	$requiredKeys = @(
		$CONFIG_KEY_USER_NAME,
		$CONFIG_KEY_REPO_TYPE,
		$CONFIG_KEY_REPO_BASEDIR,
		$CONFIG_KEY_PASSWORD_FILE
	)

	foreach ($key in $requiredKeys) {
		if (-not $ConfigVars.ContainsKey($key)) {
			Write-Host "Missing config key: $key"
			return $false
		}
		if ([string]::IsNullOrWhiteSpace($ConfigVars[$key])) {
			Write-Host "Empty value for config key: $key"
			return $false
		}
	}

	return $true
}

function New-ConfigFromTemplate {
	param(
		[Parameter(Mandatory = $true)]
		[string]$TemplateFile,

		[Parameter(Mandatory = $true)]
		[string]$OutputFile,

		[Parameter(Mandatory = $true)]
		[hashtable]$ConfigVars
	)

	if (-not (Test-Path $TemplateFile)) {
		throw "Template file not found: $TemplateFile"
	}

	$content = Get-Content $TemplateFile -Raw

	foreach ($key in $ConfigVars.Keys) {
		$placeholder = "<<$key>>"
		$value = $ConfigVars[$key]
		$content = $content -replace [regex]::Escape($placeholder), [System.Text.RegularExpressions.Regex]::Escape($value)
	}

	Set-Content -Path $OutputFile -Value $content -Encoding UTF8
}
