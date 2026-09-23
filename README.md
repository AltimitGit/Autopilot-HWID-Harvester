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

```text
USB_ROOT (e.g., D:\)
├── run_gethash.bat
├── gethash.ps1
├── README.md
├── LICENSE
└── HWID\
    └── Get-WindowsAutopilotInfo.ps1 (Optional: auto-downloads if connected online)
