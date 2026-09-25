$scriptDir =$PSScriptRoot
if ([string]::IsNullOrEmpty($scriptDir)) {
    $scriptDir = Split-Path -Parent$MyInvocation.MyCommand.Definition
}

# Construct paths directly
$hwidPath          = "$scriptDir\HWID"
$scriptDestination = "$hwidPath\Get-WindowsAutopilotInfo.ps1"
$outputFile        = "$hwidPath\AutopilotHWID.csv"
$tempFile          = "$hwidPath\temp_autopilot.csv"

# 1. Ensure HWID folder exists on USB
if (-not (Test-Path ($hwidPath))) {
    New-Item -Type Directory -Path ($hwidPath) -Force | Out-Null
}

# 2. Check if Get-WindowsAutopilotInfo.ps1 exists; if missing, attempt to download it
if (-not (Test-Path ($scriptDestination))) {
    Write-Host "`n[INFO] Get-WindowsAutopilotInfo.ps1 not found locally. Attempting online download..." -ForegroundColor Yellow
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
        }
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction SilentlyContinue
        Save-Script -Name Get-WindowsAutopilotInfo -Path ($hwidPath) -Force -ErrorAction Stop
        Write-Host "[SUCCESS] Downloaded Get-WindowsAutopilotInfo.ps1 to $scriptDestination" -ForegroundColor Green
    }
    catch {
        Write-Host "`n[ERROR] Failed to download Get-WindowsAutopilotInfo.ps1 automatically." -ForegroundColor Red
        Write-Host "Please place Get-WindowsAutopilotInfo.ps1 inside the 'HWID' folder." -ForegroundColor Yellow
        [console]::beep(500, 400)
        Write-Host "`nPress [ENTER] to exit..." -ForegroundColor Gray
        Read-Host | Out-Null
        return
    }
}

# 3. Mode Selection Menu
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "         WINDOWS AUTOPILOT HARVESTER - VERSION 2.0" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " [1] ONLINE  - Direct Upload to Intune (Requires Tenant Login)" -ForegroundColor Green
Write-Host " [2] OFFLINE - Harvest Hash to USB CSV File" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

$mode = Read-Host "Select Mode (1 or 2)"

# ==============================================================================
# MODE 1: ONLINE DIRECT UPLOAD TO INTUNE
# ==============================================================================
if ($mode -eq '1') {
    Write-Host "`n[ONLINE MODE] Preparing direct upload to Microsoft Intune..." -ForegroundColor Green
    
    # Pre-configure Environment and Ensure Required Modules
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
        }
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction SilentlyContinue
        
        Write-Host "[INFO] Checking for required Intune & Graph modules..." -ForegroundColor Yellow
        if (-not (Get-Module -ListAvailable -Name "WindowsAutopilotIntune")) {
            Write-Host "[INFO] Installing WindowsAutopilotIntune module from PSGallery..." -ForegroundColor Yellow
            Install-Module -Name "WindowsAutopilotIntune" -Force -AllowClobber -Scope CurrentUser
        }
        if (-not (Get-Module -ListAvailable -Name "Microsoft.Graph.Authentication")) {
            Write-Host "[INFO] Installing Microsoft.Graph.Authentication module..." -ForegroundColor Yellow
            Install-Module -Name "Microsoft.Graph.Authentication" -Force -AllowClobber -Scope CurrentUser
        }
    }
    catch {
        Write-Host "`n[WARNING] Module pre-installation step skipped or failed: $_" -ForegroundColor Yellow
    }

    $groupTag = Read-Host "`nEnter Group Tag (Optional - Press ENTER to skip)"
    Write-Host "`nConnecting to Microsoft Intune... Please authenticate in the popup window." -ForegroundColor Cyan

    # --- DIRECT UPLOAD VIA MICROSOFT SCRIPT ---
    if ([string]::IsNullOrWhiteSpace($groupTag)) {
        & ($scriptDestination) -Online -Assign
    } else {
        & ($scriptDestination) -Online -GroupTag ($groupTag) -Assign
    }

    if ($LASTEXITCODE -eq 0 -or$?) {
        Write-Host "`n============================================================" -ForegroundColor Green
        Write-Host " SUCCESS: Hardware hash uploaded directly to Intune!" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Green
        [console]::beep(523, 150)
        [console]::beep(784, 300)
    } else {
        Write-Host "`n[ERROR] Direct upload encountered an issue." -ForegroundColor Red
        [console]::beep(400, 500)
    }
}
# ==============================================================================
# MODE 2: OFFLINE CSV HARVESTING
# ==============================================================================
else {
    Write-Host "`n[OFFLINE MODE] Harvesting Hash to USB CSV file..." -ForegroundColor Yellow

    if (Test-Path ($outputFile)) {
        $existingRecords = Import-Csv -Path ($outputFile)
        $recordCount = @($existingRecords).Count

        Write-Host "`n============================================================" -ForegroundColor Yellow
        Write-Host " Existing CSV file detected at:" -ForegroundColor Yellow
        Write-Host " $outputFile" -ForegroundColor Cyan
        Write-Host " Current Hash Count: $recordCount device(s)" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Yellow
        
        $wipeChoice = Read-Host "Do you want to CLEAR these $recordCount hash(es) and start fresh? (Y/N)"
        
        if ($wipeChoice -eq 'Y' -or$wipeChoice -eq 'y') {
            Remove-Item -Path ($outputFile) -Force
            Write-Host "--> Existing CSV file deleted. Starting a fresh file." -ForegroundColor Green
        } else {
            Write-Host "--> Keeping existing CSV file. New devices will be appended." -ForegroundColor Gray
        }
    }

    Write-Host "`nGenerating Windows Autopilot Hardware Hash..." -ForegroundColor Cyan

    & ($scriptDestination) -OutputFile ($tempFile) -GroupTag ""

    if (Test-Path ($tempFile)) {
        $tempData       = Import-Csv -Path ($tempFile)
        $capturedRecord = $tempData[0]
        $serialNumber   = $capturedRecord.'Device Serial Number'

        if (Test-Path ($outputFile)) {
            $existingData = Import-Csv -Path ($outputFile)
            
            $isDuplicate = $false
            foreach ($row in $existingData) {
                if ($row.'Device Serial Number' -eq $serialNumber -or $row.'Hardware Hash' -eq $capturedRecord.'Hardware Hash') {
                    $isDuplicate = $true
                    break
                }
            }

            if ($isDuplicate) {
                Remove-Item -Path ($tempFile) -Force
                
                Write-Host "`n============================================================" -ForegroundColor Yellow
                Write-Host " WARNING: Duplicate detected! This device is already in CSV." -ForegroundColor Yellow
                Write-Host " Serial Number: $serialNumber" -ForegroundColor Cyan
                Write-Host " File Location: $outputFile" -ForegroundColor Yellow
                Write-Host "============================================================" -ForegroundColor Yellow
                
                [console]::beep(400, 300)
            } else {
                # Direct append without using a pipeline operator
                Export-Csv -InputObject $capturedRecord -Path ($outputFile) -NoTypeInformation -Append -Force
                Remove-Item -Path ($tempFile) -Force

                Write-Host "`n============================================================" -ForegroundColor Green
                Write-Host " SUCCESS: Autopilot hardware hash harvested!" -ForegroundColor Green
                Write-Host " Serial Number: $serialNumber" -ForegroundColor Cyan
                Write-Host " Saved to:      $outputFile" -ForegroundColor Yellow
                Write-Host "============================================================" -ForegroundColor Green

                [console]::beep(523, 150)
                [console]::beep(784, 300)
            }
        } else {
            Move-Item -Path ($tempFile) -Destination ($outputFile) -Force

            Write-Host "`n============================================================" -ForegroundColor Green
            Write-Host " SUCCESS: Autopilot hardware hash harvested!" -ForegroundColor Green
            Write-Host " Serial Number: $serialNumber" -ForegroundColor Cyan
            Write-Host " Saved to:      $outputFile" -ForegroundColor Yellow
            Write-Host "============================================================" -ForegroundColor Green

            [console]::beep(523, 150)
            [console]::beep(784, 300)
        }

    } else {
        Write-Host "`n[ERROR] Failed to generate temporary hash CSV file." -ForegroundColor Red
        [console]::beep(400, 500)
    }
}

Write-Host "`nPress [ENTER] to exit..." -ForegroundColor Gray
Read-Host | Out-Null