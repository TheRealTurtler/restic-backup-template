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
   .\update-binaries.ps1
   ```
   This downloads the latest versions of restic and resticprofile into:
   ```
   bin\
   ```

## 🔐 Secrets and Passwords

- Repository passwords are stored in:
  ```
  secrets\
  ```

- File naming convention:
  ```
  alice_userdata.secret
  ```

- To generate a new cryptographically strong password, run:
  ```
  .\generate-password.ps1
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

- A default profile named `userdata` is included.
- Username configuration is only needed if this template is used across multiple PCs or users.
  This allows each user's password file to be stored and backed up independently.

- To set your username, edit:
  ```
  conf\resticprofile\profiles.d\00_default.yaml
  ```

  Modify the following line:
  ```yaml
  #{{ $user_name := "user" }}
  ```

  Replace `"user"` with your actual username.

## 🗂️ Running a Backup with a Profile

Once your profile is configured, you can start a backup using:

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

✅ Make sure the `.secret` file for the profile exists and is correctly named (e.g. `alice_userdata.secret`) so authentication works as expected.

## ✅ Features

- Windows-only (for now)
- Portable, file-based configuration (no registry, no credential manager)
- Predefined user profile for quick onboarding
- Easy-to-backup password files (`.secret`)
- Clear folder and config layout for team use and version control

## 📚 Repositories Used

- [restic](https://github.com/restic/restic) – backup engine
- [resticprofile](https://github.com/creativeprojects/resticprofile) – profile-based wrapper
