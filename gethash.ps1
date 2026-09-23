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

# 2. Prompt to clear existing CSV file before harvesting (showing existing hash count)
if (Test-Path ($outputFile)) {
    $existingRecords = Import-Csv -Path ($outputFile)
    $recordCount = @($existingRecords).Count

    Write-Host "`n============================================================" -ForegroundColor Yellow
    Write-Host " Existing CSV file detected at:" -ForegroundColor Yellow
    Write-Host " $outputFile" -ForegroundColor Cyan
    Write-Host " Current Hash Count: $recordCount device(s)" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Yellow
    
    $wipeChoice = Read-Host "Do you want to CLEAR these $recordCount hash(es) and start fresh? (Y/N)"
    
    if ($wipeChoice -eq 'Y' -or $wipeChoice -eq 'y') {
        Remove-Item -Path ($outputFile) -Force
        Write-Host "--> Existing CSV file deleted. Starting a fresh file." -ForegroundColor Green
    } else {
        Write-Host "--> Keeping existing CSV file. New devices will be appended." -ForegroundColor Gray
    }
}

# 3. Check if Get-WindowsAutopilotInfo.ps1 exists; if missing, attempt to download it
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

Write-Host "`nGenerating Windows Autopilot Hardware Hash..." -ForegroundColor Cyan

# 4. Harvest Hardware Hash
& $scriptDestination -OutputFile ($tempFile) -GroupTag ""

# 5. Save and handle duplicate checks
if (Test-Path ($tempFile)) {
    $tempData = Import-Csv -Path ($tempFile)
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
            $combinedData = @($existingData) + @($capturedRecord)
            Export-Csv -InputObject $combinedData -Path ($outputFile) -NoTypeInformation -Force
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

Write-Host "`nPress [ENTER] to exit..." -ForegroundColor Gray
Read-Host | Out-Null