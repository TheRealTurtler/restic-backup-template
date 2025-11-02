function Get-RepoConfig {
	param([string]$ConfigFile)

	if (-not (Test-Path $ConfigFile)) { return @{} }

	$vars = @{}
	foreach ($line in Get-Content $ConfigFile) {
		if ($line -match '^\s*\{\{\s*\$(\w+)\s*:?=\s*"([^"]+)"\s*\}\}') {
			$vars[$matches[1]] = $matches[2]
		}
	}
	return $vars
}

function Test-RepoConfigValidity {
	param(
		[hashtable]$ConfigVars,
		[string[]]$RequiredKeys
	)

	foreach ($key in $RequiredKeys) {
		if (-not $ConfigVars.ContainsKey($key)) { return $false }
		if ([string]::IsNullOrWhiteSpace($ConfigVars[$key])) { return $false }
	}
	return $true
}

function New-RepoConfigFromTemplate {
	param(
		[string]$TemplateFile,
		[string]$OutputFile,
		[hashtable]$ConfigVars
	)

	$content = Get-Content $TemplateFile -Raw
	foreach ($key in $ConfigVars.Keys) {
		$placeholder = "<<$key>>"
		$value = $ConfigVars[$key]
		$content = $content.Replace($placeholder, $value)
	}

	Set-Content -Path $OutputFile -Value $content -Encoding UTF8
}
