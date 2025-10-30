#requires -Module Logging

function Get-GitHubLatestReleaseTag {
	param(
		[string]$Repository                # GitHub repository "owner/project"
	)
	try {
		$apiUrl = "https://api.github.com/repos/$Repository/releases/latest"
		$release = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
		return $release.tag_name
	}
	catch { return $null }
}

function Get-GitHubExecutable {
	param (
		[string]$Repository,               # GitHub repository "owner/project"
		[string[]]$AssetMustContain,       # Filters for the release asset name
		[string[]]$ExecutableMustContain,  # Filters for the .exe inside the archive
		[string]$TargetPath,               # Destination path (dir or full path incl. filename)
		[string]$ReleaseTag                # Optional: specific release tag (e.g. "v1.2.3")
	)

	Start-LogBlock "GitHub Download: $Repository"

	try {
		# Select release
		$apiUrl = if ($ReleaseTag) {
			"https://api.github.com/repos/$Repository/releases/tags/$ReleaseTag"
		}
		else {
			"https://api.github.com/repos/$Repository/releases/latest"
		}

		$release = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing

		foreach ($asset in $release.assets) {
			$name = $asset.name
			$url = $asset.browser_download_url

			$matchesAsset = $true
			foreach ($filter in $AssetMustContain) {
				if ($name -notlike "*$filter*") { $matchesAsset = $false; break }
			}

			if ($matchesAsset) {
				$tempRoot = [System.IO.Path]::GetTempPath()
				$assetPath = Join-Path $tempRoot $name
				$extractPath = Join-Path $tempRoot ([System.IO.Path]::GetFileNameWithoutExtension($name))

				Write-LogLine "Downloading $name..."
				Invoke-WebRequest -Uri $url -OutFile $assetPath

				Write-LogLine "Extracting $name..."
				Expand-Archive -Path $assetPath -DestinationPath $extractPath -Force

				$exe = Get-ChildItem -Path $extractPath -Recurse -Filter "*.exe" |
				Where-Object {
					foreach ($filter in $ExecutableMustContain) {
						if ($_.Name -notlike "*$filter*") { return $false }
					}
					return $true
				} |
				Select-Object -First 1

				if ($exe) {
					# If TargetPath is a directory or a path without extension, keep original filename
					$destPath = if ((Test-Path $TargetPath -PathType Container) -or
						(-not [System.IO.Path]::HasExtension($TargetPath))) {
						Join-Path $TargetPath $exe.Name
					}
					else {
						$TargetPath
					}

					Write-LogLine "Copying $($exe.Name) to $destPath..."
					Copy-Item -Path $exe.FullName -Destination $destPath -Force

					Write-LogLine "Cleaning up temporary files..."
					if (Test-Path $assetPath) { Remove-Item $assetPath -Force }
					if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }

					Write-LogLine "Download successful."
					Stop-LogBlock "GitHub Download: $Repository"
					return $true
				}
				else {
					$filters = $ExecutableMustContain | ForEach-Object { "`"$_`"" } -join ", "
					throw "No .exe matching filters ($filters) found in archive"
				}
			}
		}

		throw "No matching asset found for repository $Repository"
	}
	catch {
		Write-LogLine "Download failed: $($_.Exception.Message)."
		Stop-LogBlock "GitHub Download: $Repository"
		return $false
	}
}
