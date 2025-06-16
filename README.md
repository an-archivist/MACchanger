# MACchanger

This repository contains scripts to rotate (spoof) the MAC address of your wireless network interface, for **Linux**, **Windows PowerShell**, and **Windows Batch** environments.

---

## File Overview

### 1. `rotate_mac.sh`

- **Platform:** Linux / Unix (Bash shell)
- **Purpose:** Automatically detect or use specified Wi-Fi interface and profile, then change the MAC address either from a known pool or randomly.
- **Features:**
  - Auto-detect wireless interface and active Wi-Fi profile.
  - Supports user-specified interface/profile.
  - Use a pool of known MAC addresses or generate a random locally administered MAC.
  - Logs all MAC address changes to `~/.mac_history.log` with log rotation.
  - Verbose and dry-run modes.
- **Usage example:**

```bash
chmod +x rotate_mac.sh
sudo ./rotate_mac.sh --interface wlan0 --profile HomeWiFi --use-random --verbose
```

---

### 2. `RotateMac.ps1`

- **Platform:** Windows (PowerShell)
- **Purpose:** Rotate MAC address of a specified network interface using either a known list of MACs or generate a random MAC.
- **Features:**
  - Specify the network interface by name (e.g., "Wi-Fi").
  - Choose between a known pool of MAC addresses or a random locally administered MAC.
  - Dry-run and verbose modes.
  - Writes change logs to `%USERPROFILE%\.mac_history.log`.
  - Disables and re-enables the network adapter to apply the new MAC.
- **Usage example:**

```powershell
# Run PowerShell as Administrator
.\RotateMac.ps1 -InterfaceName "Wi-Fi" -UseRandom -Verbose
```

Add `-DryRun` to simulate without applying changes.

---

### 3. `rotate_mac.bat` *(Simplified Example)*

- **Platform:** Windows (Batch file)
- **Purpose:** Provide a simple MAC address change using built-in Windows tools (limited compared to PowerShell or Linux versions).
- **Features:**
  - Requires manual MAC address input.
  - No auto-detection or random generation.
  - Mainly included for legacy support or minimal environments.
- **Example batch content:**

```batch
@echo off
setlocal

set INTERFACE_NAME="Wi-Fi"
set NEW_MAC="001122334455"

echo Changing MAC Address on %INTERFACE_NAME% to %NEW_MAC%

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001" /v NetworkAddress /d %NEW_MAC% /f

netsh interface set interface %INTERFACE_NAME% disable
timeout /t 3
netsh interface set interface %INTERFACE_NAME% enable

echo Done!
pause
```

- **Important Notes:**
  - You must modify `INTERFACE_NAME` and `NEW_MAC` before running.
  - Run the batch file as Administrator.
  - The exact registry path may differ depending on the system and interface. Use `RotateMac.ps1` for fully automated handling.

---

## Common Configuration

All scripts allow you to configure:

- **Network interface** name.
- Use of **random MAC** or known pool (except batch).
- Verbose output.
- Dry-run mode for testing (in shell & PowerShell versions).

---

## Requirements

### Linux Script (`rotate_mac.sh`)

- Bash shell (`#!/usr/bin/env bash`)
- Commands: `nmcli`, `ip`, `sudo`, `awk`
- User must have permission to change network interface MAC (usually requires `sudo`).

### Windows PowerShell Script (`RotateMac.ps1`)

- PowerShell 5.1 or later
- Run PowerShell as Administrator
- Uses: `Get-NetAdapter`, `Disable-NetAdapter`, `Enable-NetAdapter`, `Set-ItemProperty`

### Windows Batch Script (`rotate_mac.bat`)

- Administrator rights
- Works via registry editing and interface restart
- Limited compared to PowerShell

---

## Notes

- Changing MAC address may disconnect your Wi-Fi temporarily.
- Some Wi-Fi adapters/drivers may not support MAC address changes or may reset on reboot.
- Always backup current configurations before running.
- Logs are rotated when they exceed approximately 1000 lines (Linux and PowerShell versions).

---

## License

(Include your license or leave as needed)

---

## Support

If you encounter issues or want enhancements, feel free to open an issue or request help.

---

Happy spoofing! 
