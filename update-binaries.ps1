#requires -version 5.1
$ErrorActionPreference = 'Stop'

# === CONFIGURATION ===
$BinDir            = "bin"                            # Target directory for final .exe files
$TempDir           = $env:TEMP                        # Temporary working directory (can be overridden if needed)
$ResticRepo        = "restic/restic"                  # GitHub repo for restic
$ResticProfileRepo = "creativeprojects/resticprofile" # GitHub repo for resticprofile

# Create bin directory if it doesn't exist
if (-not (Test-Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir | Out-Null
}

# Downloads a .zip asset from GitHub, extracts the matching .exe, renames it, and places it in bin\
function Download-And-ExtractRenamedExe {
    param (
        [string]$Repo,                  # GitHub repo in the format "owner/project"
        [string[]]$ZipNameMustContain, # Filters for identifying the correct .zip asset
        [string[]]$ExeNameMustContain, # Filters for identifying the correct .exe inside the archive
        [string]$TargetExeName         # Final name for the extracted .exe in bin\
    )

    try {
        # Fetch all releases from GitHub API
        $apiUrl = "https://api.github.com/repos/$Repo/releases"
        $releases = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing

        foreach ($release in $releases) {
            foreach ($asset in $release.assets) {
                $name = $asset.name
                $url = $asset.browser_download_url

                # Check if asset name matches all required substrings
                $matchesZip = $true
                foreach ($filter in $ZipNameMustContain) {
                    if ($name -notlike "*$filter*") {
                        $matchesZip = $false
                        break
                    }
                }

                # If it's a matching .zip file, proceed with download and extraction
                if ($matchesZip -and $name -like "*.zip") {
                    $zipPath     = Join-Path $TempDir $name
                    $extractPath = Join-Path $TempDir ([System.IO.Path]::GetFileNameWithoutExtension($name))

                    Write-Host "Downloading $name..."
                    Invoke-WebRequest -Uri $url -OutFile $zipPath

                    # Extract contents of the .zip archive
                    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

                    # Find the first .exe file that matches all required substrings
                    $exe = Get-ChildItem -Path $extractPath -Recurse -Filter "*.exe" |
                        Where-Object {
                            foreach ($filter in $ExeNameMustContain) {
                                if ($_.Name -notlike "*$filter*") { return $false }
                            }
                            return $true
                        } |
                        Select-Object -First 1

                    # Copy and rename the .exe to bin\
                    if ($exe) {
                        Copy-Item -Path $exe.FullName -Destination "$BinDir\$TargetExeName" -Force
                        Write-Host "Extracted and renamed $($exe.Name) to $TargetExeName"
                    } else {
                        Write-Host "ERROR: No .exe matching filters $($ExeNameMustContain -join ', ') found in archive"
                    }

                    # Clean up temporary files
                    if (Test-Path $zipPath)     { Remove-Item $zipPath -Force }
                    if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }

                    return
                }
            }
        }

        # If no matching .zip asset was found
        Write-Host ""
        Write-Host "ERROR: No matching .zip asset found for ${Repo} with filters: $($ZipNameMustContain -join ', ')"
    }
    catch {
        # Handle API or network errors
        Write-Host ""
        Write-Host "ERROR while downloading from ${Repo}:"
        Write-Host $_.Exception.Message
    }
}

# === Download restic ===
Download-And-ExtractRenamedExe `
    -Repo $ResticRepo `
    -ZipNameMustContain @("restic", "windows_amd64", "zip") `
    -ExeNameMustContain @("restic", "exe") `
    -TargetExeName "restic.exe"

# === Download resticprofile ===
Download-And-ExtractRenamedExe `
    -Repo $ResticProfileRepo `
    -ZipNameMustContain @("resticprofile", "windows_amd64", "zip") `
    -ExeNameMustContain @("resticprofile", "exe") `
    -TargetExeName "resticprofile.exe"

Write-Host ""
Write-Host "Done."
Pause
