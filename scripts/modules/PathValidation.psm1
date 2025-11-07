# === Normalize directory path ===
# Converts backslashes to forward slashes, collapses duplicates, and ensures trailing slash
function Convert-Directory {
	param([string]$Path)

	if ([string]::IsNullOrWhiteSpace($Path)) { return $null }

	$normalized = $Path.Trim()
	$normalized = $normalized -replace '[\\]', '/'

	while ($normalized.Contains('//')) {
		$normalized = $normalized.Replace('//', '/')
	}

	if (-not $normalized.EndsWith('/')) {
		$normalized += '/'
	}

	return $normalized
}

# === Normalize filename ===
# Extracts the filename from a full path and returns it if valid
function Convert-FileName {
	param([string]$FileName)

	if ([string]::IsNullOrWhiteSpace($FileName)) { return $null }

	$name = [System.IO.Path]::GetFileName($FileName)

	if ([string]::IsNullOrWhiteSpace($name)) { return $null }

	return $name
}

# === Normalize full path ===
# Combines normalized directory and filename if both are present
function Convert-Path {
	param([string]$Path)

	if ([string]::IsNullOrWhiteSpace($Path)) { return $null }

	$dir = [System.IO.Path]::GetDirectoryName($Path)
	$file = [System.IO.Path]::GetFileName($Path)

	if ([string]::IsNullOrWhiteSpace($file)) {
		return Convert-Directory $dir
	}
	elseif ([string]::IsNullOrWhiteSpace($dir)) {
		return Convert-FileName $file
	}
	else {
		$normalizedDir = Convert-Directory $dir
		$normalizedFile = Convert-FileName $file
		return ($normalizedDir + $normalizedFile)
	}
}
