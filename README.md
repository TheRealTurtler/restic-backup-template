# 🛡️ restic Backup Template for Windows

This repository provides a portable, team-safe backup setup using [restic](https://github.com/restic/restic) and [resticprofile](https://github.com/creativeprojects/resticprofile). It is built for clarity, portability and zero hidden dependencies. Simply unzip, configure and run.

## 📦 Quick Start

1. **Download the ZIP**
   Extract this repository to any folder, for example:
   ```
   C:\Tools\restic\
   ```

2. **Run the Setup Script**
   Launch PowerShell and execute:
   ```
   .\setup-repo.ps1
   ```
   This will:
   - Download the latest versions of restic and resticprofile
   - Guide you through repository setup
   - Generate a secure password
   - Create your backup profile

## 🔐 Secrets and Passwords

- Repository passwords are stored in:
  ```
  secrets\
  ```

- File naming convention: `restic_username.secret`
  (See [User Configuration](#-user-configuration) for setting up your username)

- To generate a new cryptographically strong password, run:
  ```
  .\scripts\generate-password.ps1
  ```
  This uses [`System.Security.Cryptography.RandomNumberGenerator`](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.randomnumbergenerator) for secure randomness.

### ⚠️ Critical: Backup Your `.secret` File

This file contains the encryption password for your restic repository.

If it is lost, **you will permanently lose access to your backups.**
restic cannot decrypt the repository without the exact password.

✅ Always store this file in a **secure, separate location** — outside your backup targets and version control.

📁 *Example:*
Store it on a USB stick, password manager, or encrypted vault that is not part of the backup set.

## 👤 User Configuration

- A default profile named `userdata` is included for backing up user data.
- Your personal settings (username, repository location, etc.) are automatically configured by the setup script
  and stored in `conf/resticprofile/profiles.d/01_default_repo.yaml`.
- This configuration approach allows each user's backup profile and password file to be managed independently
  when using this template across multiple PCs or users.

## 🗂️ Running a Backup with a Profile

### 🧪 Test Profile

A `test` profile is included to verify your setup. This profile backs up the contents of the `test/data/` folder and is perfect for trying out the backup process without risking important data.

To run the test backup:
```
.\scripts\run-backup.ps1 -Profile test
```

### 💾 User Data Profile

For actual backups, you can start a backup using:
```
.\bin\resticprofile.exe --name "profilename" backup
```

🔧 Replace `"profilename"` with the name of your profile, for example:
```
.\bin\resticprofile.exe --name "userdata" backup
```

This command uses the configuration from:
```
conf\resticprofile\profiles.d\userdata.yaml
```
and backs up the directories defined in that profile to the associated restic repository.

✅ Make sure the `.secret` file for the profile exists and is correctly named (e.g. `restic_alice.secret`) so authentication works as expected.

## ✅ Features

- Windows-only (for now)
- Portable, file-based configuration (no registry, no credential manager)
- Predefined user profile for quick onboarding
- Easy-to-backup password files (`.secret`)
- Clear folder and config layout for team use and version control

## 📚 Repositories Used

- [restic](https://github.com/restic/restic) – backup engine
- [resticprofile](https://github.com/creativeprojects/resticprofile) – profile-based wrapper
