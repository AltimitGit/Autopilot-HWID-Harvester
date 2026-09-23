# Windows Autopilot Hardware Hash Harvester

A lightweight, automated PowerShell and Batch script suite for harvesting Windows Autopilot hardware hashes (`HWID`) directly to a portable USB drive. Built specifically for IT administrators, deployment engineers, and Managed Service Providers (MSPs) provisioning devices via Microsoft Intune.

---

## Key Features

* **Zero-Configuration Execution:** Runs seamlessly in standard Windows Desktop environments and during Out-of-Box Experience (**OOBE** via `Shift + F10`).
* **Auto-Elevation:** Automatically prompts for UAC Administrator privileges when executed inside an active Windows session.
* **Smart File Management:**
  * Detects existing CSV files on startup and displays the current count of saved hashes.
  * Prompts the operator with an option to wipe the CSV for a fresh batch or append new entries.
  * Automatically fetches `Get-WindowsAutopilotInfo.ps1` from the PowerShell Gallery if missing and connected to the internet.
* **Duplicate Prevention:** Scans existing records by Serial Number and Hardware Hash to prevent duplicate entries that cause Intune import failures.
* **Visual & Audio Cues:** Features clean console summary banners, serial number previews, and custom audio chimes upon completion or error.
* **Persistent Console Display:** Holds the screen open after execution so completion data remains visible even if you step away.

---

## Folder Structure

To ensure correct relative path handling, structure your USB drive as follows:

```
USB_ROOT (e.g., D:\)
├── run_gethash.bat
├── gethash.ps1
├── README.md
├── LICENSE
└── HWID\
    └── Get-WindowsAutopilotInfo.ps1 (Optional: auto-downloads if connected online)
```
## Installation & Setup
Clone or download this repository.

Copy run_gethash.bat and gethash.ps1 directly to the root directory of your USB drive.

(Optional for Offline Environments) Create a folder named HWID on your USB root and place Get-WindowsAutopilotInfo.ps1 inside it.

Note: If internet access is available on first run, gethash.ps1 will download this dependency automatically.

## Usage Instructions
Option A: Running from OOBE (New / Factory Reset Devices)
Boot the target device to the Windows initial setup screen (Region/Keyboard selection).

Insert your USB drive.

Press Shift + F10 (or Fn + Shift + F10) to launch the Command Prompt.

Navigate to your USB drive letter (e.g., type d: and press Enter).

Run the loader batch file:
```
run_gethash.bat
```
Respond to the prompt (clear CSV or append), wait for the success chime, and press Enter to exit.

Option B: Running from an Active Windows Session
Insert the USB drive into an active Windows desktop.

Open the drive in File Explorer and double-click run_gethash.bat.

Click Yes on the User Account Control (UAC) prompt to grant Administrator rights.

Follow the on-screen prompts and review the output banner.

## Output & Intune Import
All harvested hashes are written to:
\HWID\AutopilotHWID.csv

This CSV adheres strictly to Microsoft's schema and can be uploaded directly into the Microsoft Intune Admin Center:

Devices > Enrollment > Windows > Devices > Import
