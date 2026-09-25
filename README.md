# Windows Autopilot Hardware Hash Harvester

A lightweight, automated PowerShell and Batch script suite for harvesting Windows Autopilot hardware hashes (`HWID`) directly to a portable USB drive or uploading them directly to Microsoft Intune. Built specifically for IT administrators, deployment engineers, and Managed Service Providers (MSPs) provisioning devices via Microsoft Intune.

---

## Key Features

* **Dual Deployment Modes:**
  * **[1] ONLINE MODE:** Uploads the hardware hash directly to Microsoft Intune via Graph API (supports optional Group Tag assignment and requires tenant authentication).
  * **[2] OFFLINE MODE:** Harvests hardware hashes to a consolidated CSV file on the USB drive.
* **Zero-Configuration Execution:** Runs seamlessly in standard Windows Desktop environments and during Out-of-Box Experience (**OOBE** via `Shift + F10`).
* **Auto-Elevation:** Automatically prompts for UAC Administrator privileges when executed inside an active Windows session.
* **Smart File Management:**
  * Detects existing CSV files on startup in Offline Mode, displays the current count of saved hashes, and prompts the operator with an option to wipe the CSV for a fresh batch or append new entries.
  * Automatically fetches `Get-WindowsAutopilotInfo.ps1` and required Intune Graph modules from the PowerShell Gallery if missing and connected to the internet.
* **Duplicate Prevention:** 
  * **Offline:** Scans existing records by Serial Number and Hardware Hash to prevent duplicate entries that cause Intune import failures.
  * **Online:** Detects Intune Graph conflict errors (such as `409 Conflict` or existing device warnings) and alerts the operator if the device is already registered in the tenant.
* **Visual & Audio Cues:** Features clean console summary banners, serial number previews, and custom audio chimes upon completion or error.
* **Persistent Console Display:** Holds the screen open after execution so completion data remains visible even if you step away.

---

## Folder Structure

To ensure correct relative path handling, structure your USB drive as follows:
```
USB_ROOT (e.g., D:)
├── run_gethash.bat
├── gethash.ps1
├── README.md
├── LICENSE
└── HWID

└── Get-WindowsAutopilotInfo.ps1 (Optional: auto-downloads if connected online)
```
---

## Installation & Setup

1. Clone or download this repository.
2. Copy `run_gethash.bat` and `gethash.ps1` directly to the root directory of your USB drive.
3. *(Optional for Offline Environments)* Create a folder named `HWID` on your USB root and place `Get-WindowsAutopilotInfo.ps1` inside it.

> **Note:** If internet access is available on first run, `gethash.ps1` will download this dependency and any missing Intune Graph modules automatically.

---

## Usage Instructions

### Launching the Harvester

**Option A: Running from OOBE (New / Factory Reset Devices)**
1. Boot the target device to the Windows initial setup screen (Region/Keyboard selection).
2. Insert your USB drive.
3. Press `Shift + F10` (or `Fn + Shift + F10`) to launch the Command Prompt.
4. Navigate to your USB drive letter (e.g., type `d:` and press Enter).
5. Run the loader batch file:
```
run_gethash.bat
```
**Option B: Running from an Active Windows Session**
1. Insert the USB drive into an active Windows desktop.
2. Open the drive in File Explorer and double-click `run_gethash.bat`.
3. Click **Yes** on the User Account Control (UAC) prompt to grant Administrator rights.

---

### Selecting Deployment Mode

Upon launch, you will be presented with the mode selection menu:
```
============================================================
WINDOWS AUTOPILOT HARVESTER - VERSION 2.0
[1] ONLINE  - Direct Upload to Intune (Requires Tenant Login)
[2] OFFLINE - Harvest Hash to USB CSV File
```
#### Option 1: Online Direct Upload
1. Select mode `1`.
2. Enter an optional **Group Tag** when prompted (or press `ENTER` to skip).
3. Authenticate with your Microsoft Intune credentials in the popup authentication window.
4. The script uploads the hardware hash directly to your tenant and notifies you upon completion or duplicate detection.

#### Option 2: Offline CSV Harvesting
1. Select mode `2`.
2. Respond to the prompt (clear CSV or append existing records).
3. Wait for the success chime, review the on-screen summary banner, and press Enter to exit.

---

## Output & Intune Import

For **Offline Mode**, all harvested hashes are written to:
`\HWID\AutopilotHWID.csv`

This CSV adheres strictly to Microsoft's schema (`Device Serial Number`, `Windows Product ID`, `Hardware Hash`) and can be uploaded directly into the Microsoft Intune Admin Center:

> **Devices** > **Enrollment** > **Windows** > **Devices** > **Import**
