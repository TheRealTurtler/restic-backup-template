# 📦 bin/

This folder contains downloaded binaries used by the backup workflow.

✅ After running `update-binaries.ps1`, the following executables will appear here:

- `restic.exe` – the backup engine
- `resticprofile.exe` – profile-based wrapper for restic

These files are downloaded automatically and should not be edited.

📌 Also located here:
`profiles.yaml` – the main configuration file that includes all relevant profile definitions from `conf/`

⚠️ `profiles.yaml` should not be changed.
All settings and profile logic should be defined in `conf/profiles.d/` and `conf/conf.d/`.

☑️ You may add this folder to `.gitignore`, **but make sure `profiles.yaml` remains versioned**.
