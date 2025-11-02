function Convert-Directory {
	param([string]$Path)

	if ([string]::IsNullOrWhiteSpace($Path)) { return $null }

	$normalized = $Path.Trim()

	# Convert all backslashes to forward slashes
	$normalized = $normalized -replace '[\\]', '/'

	# Collapse duplicate forward slashes
	while ($normalized.Contains('//')) {
		$normalized = $normalized.Replace('//', '/')
	}

	# Ensure trailing slash
	if (-not $normalized.EndsWith('/')) {
		$normalized += '/'
	}

	return $normalized
}

function Convert-FileName {
	param([string]$FileName)

	if ([string]::IsNullOrWhiteSpace($FileName)) { return $null }

	$name = [System.IO.Path]::GetFileName($FileName)

	if ([string]::IsNullOrWhiteSpace($name)) { return $null }

	return $name
}

function Convert-Path {
	param([string]$Path)

	if ([string]::IsNullOrWhiteSpace($Path)) { return $null }

	# Zerlegen in Directory + FileName
	$dir = [System.IO.Path]::GetDirectoryName($Path)
	$file = [System.IO.Path]::GetFileName($Path)

	if ([string]::IsNullOrWhiteSpace($file)) {
		# Nur ein Verzeichnis → Directory normalisieren
		return Convert-Directory $dir
	}
	elseif ([string]::IsNullOrWhiteSpace($dir)) {
		# Nur ein Dateiname → FileName normalisieren
		return Convert-FileName $file
	}
	else {
		# Beides vorhanden → Directory + FileName kombinieren
		$normalizedDir = Convert-Directory $dir
		$normalizedFile = Convert-FileName $file
		return ($normalizedDir + $normalizedFile)
	}
}
