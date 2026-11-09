# Hearable One-Click APK Installer & Launcher for Windows PowerShell
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host " ==============================================================" -ForegroundColor Cyan
Write-Host "    HEARABLE - HIGH-FIDELITY MUSIC STREAMING FOR ANDROID" -ForegroundColor White
Write-Host "    Windows One-Click APK Installer & Launcher (PowerShell)" -ForegroundColor Cyan
Write-Host " ==============================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Locate ADB
$adb = "adb"
$adbFound = $null

if (Get-Command "adb" -ErrorAction SilentlyContinue) {
    $adbFound = "adb"
} else {
    $standardPaths = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\platform-tools\adb.exe",
        "C:\Android\Sdk\platform-tools\adb.exe"
    )
    foreach ($p in $standardPaths) {
        if (Test-Path $p) {
            $adbFound = $p
            break
        }
    }
}

if (-not $adbFound) {
    Write-Host " [ERROR] Android Debug Bridge (adb.exe) was not found!" -ForegroundColor Red
    Write-Host " Please ensure Android SDK Platform-Tools is installed." -ForegroundColor Yellow
    Read-Host " Press Enter to exit..."
    exit 1
}

Write-Host " [*] ADB Path: $adbFound" -ForegroundColor Green

# 2. Check connected devices
& $adbFound start-server | Out-Null
$devicesOutput = & $adbFound devices
$lines = $devicesOutput -split "`n" | Where-Object { $_ -match "\s+device$" }

if ($lines.Count -eq 0) {
    Write-Host " [!] No active device/emulator detected via ADB." -ForegroundColor Yellow
    Write-Host " [*] Checking for local Android emulator..." -ForegroundColor Cyan

    $emuPath = "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe"
    if (Test-Path $emuPath) {
        Write-Host " [*] Starting Pixel 9 emulator..." -ForegroundColor Cyan
        Start-Process -FilePath $emuPath -ArgumentList "-avd Pixel_9_API_36 -netdelay none -netspeed full"
        Write-Host " [*] Waiting for device to connect..." -ForegroundColor Cyan
        & $adbFound wait-for-device
        Write-Host " [+] Connected to emulator!" -ForegroundColor Green
    } else {
        Write-Host " [WARNING] Please connect an Android device with USB Debugging enabled." -ForegroundColor Yellow
        Read-Host " Press Enter to exit..."
        exit 1
    }
} else {
    Write-Host " [+] Found device(s):" -ForegroundColor Green
    $lines | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
}

# 3. Check for APK
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path $apkPath)) {
    Write-Host " [*] APK not found. Building Debug APK now..." -ForegroundColor Cyan
    flutter build apk --debug
    if (-not (Test-Path $apkPath)) {
        Write-Host " [ERROR] Flutter build failed." -ForegroundColor Red
        Read-Host " Press Enter to exit..."
        exit 1
    }
}

# 4. Install APK
Write-Host " [*] Installing Hearable APK..." -ForegroundColor Cyan
& $adbFound install -r -d $apkPath

# 5. Launch
Write-Host " [*] Launching Hearable (com.hearable.music)..." -ForegroundColor Cyan
& $adbFound shell am start -n com.hearable.music/.MainActivity

Write-Host ""
Write-Host " ==============================================================" -ForegroundColor Green
Write-Host "    SUCCESS! Hearable is now running on your device!" -ForegroundColor White
Write-Host " ==============================================================" -ForegroundColor Green
Write-Host ""
Read-Host " Press Enter to continue..."

