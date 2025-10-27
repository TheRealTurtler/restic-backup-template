# 🛡️ Restic Backup Template for Windows

This repository provides a portable, team-safe backup setup using [Restic](https://github.com/restic/restic) and [resticprofile](https://github.com/creativeprojects/resticprofile). It’s designed for clarity, maintainability, and zero hidden dependencies — just unzip and go!

## 📦 Quick Start

1. **Download the ZIP**  
   Grab this repository as a ZIP file and extract it to:  
   ```
   C:\Restic
   ```

2. **Run the Setup Script**  
   Launch PowerShell and execute:  
   ```
   .\update-binaries.ps1
   ```  
   This downloads the latest versions of Restic and resticprofile into `bin/`.

## 🔐 Secrets & Passwords

- Repository passwords are stored in the:
   ```
   secrets\
   ```
- File naming convention:  
   ```
   user_profilename.secret
   ```  
  Example:  
   ```
   michael_userdata.secret
   ```

- To generate a new cryptographically strong password, run:  
   ```
   .\generate-password.ps1
   ```  
   This uses [`System.Security.Cryptography.RandomNumberGenerator`](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.randomnumbergenerator) for secure randomness.

## 👤 User Configuration

- A default profile named `userdata` is already included.
- To activate it, set your username in:  
   ```
   conf\resticprofile\profiles.d\00_default.yaml
   ```  
  Modify the following line:
   ```yaml
   #{{ $user_name := "user" }}
   ```  
  Replace `"user"` with your actual username.

## ✅ Features

- 🪟 Windows-only setup (for now)  
- 🔧 Portable, file-based configuration — no registry or credential manager required  
- 📁 Predefined user profile for quick onboarding  
- 🔐 Secure password handling via `.secret` files  
- 🧠 Explicit, maintainable structure for teams  

## 📚 Repositories Used

- [Restic](https://github.com/restic/restic) – Fast, secure, efficient backup program  
- [resticprofile](https://github.com/creativeprojects/resticprofile) – Profile-based wrapper for Restic

## 💬 Notes

- All paths and config files are designed for portability and clarity.  
- No secrets are ever stored in code or version control.  
- YAML quoting and path handling are cross-platform safe (forward slashes, explicit quoting).
