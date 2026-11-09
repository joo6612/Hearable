@echo off
setlocal enabledelayedexpansion

title Hearable - One-Click APK Installer
color 0B

echo.
echo  ==============================================================
echo     HEARABLE - HIGH-FIDELITY MUSIC STREAMING FOR ANDROID
echo     Windows One-Click APK Installer & Launcher
echo  ==============================================================
echo.

:: 1. Locate ADB
set "ADB_BIN=adb"
where adb >nul 2>nul
if %ERRORLEVEL% equ 0 (
    goto :ADB_FOUND
)

if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
    set "ADB_BIN=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
    goto :ADB_FOUND
)

if exist "C:\Users\%USERNAME%\AppData\Local\Android\Sdk\platform-tools\adb.exe" (
    set "ADB_BIN=C:\Users\%USERNAME%\AppData\Local\Android\Sdk\platform-tools\adb.exe"
    goto :ADB_FOUND
)

if exist "C:\Android\Sdk\platform-tools\adb.exe" (
    set "ADB_BIN=C:\Android\Sdk\platform-tools\adb.exe"
    goto :ADB_FOUND
)

color 0C
echo  [ERROR] Android Debug Bridge (adb.exe) was not found!
echo  Please ensure Android SDK Platform-Tools is installed.
echo.
pause
exit /b 1

:ADB_FOUND
echo  [*] ADB Path: %ADB_BIN%

:: 2. Check connected devices
echo  [*] Checking for connected Android devices / emulators...
"%ADB_BIN%" start-server >nul 2>&1

set "DEVICE_FOUND=0"
for /f "skip=1 tokens=1,2" %%A in ('"%ADB_BIN%" devices') do (
    if "%%B"=="device" (
        set "DEVICE_FOUND=1"
        set "TARGET_DEVICE=%%A"
        echo  [+] Target device detected: %%A
    )
)

if "%DEVICE_FOUND%"=="0" (
    echo.
    echo  [!] No active device/emulator detected via ADB.
    echo  [*] Attempting to launch Pixel 9 emulator...
    
    set "EMU_BIN="
    if exist "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" (
        set "EMU_BIN=%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe"
    ) else if exist "C:\Users\%USERNAME%\AppData\Local\Android\Sdk\emulator\emulator.exe" (
        set "EMU_BIN=C:\Users\%USERNAME%\AppData\Local\Android\Sdk\emulator\emulator.exe"
    )

    if defined EMU_BIN (
        start "" "%EMU_BIN%" -avd Pixel_9_API_36 -netdelay none -netspeed full
        echo  [*] Waiting for emulator to boot up (this may take ~20-30 seconds)...
        "%ADB_BIN%" wait-for-device
        echo  [+] Emulator booted and connected!
    ) else (
        color 0E
        echo  [WARNING] Could not start emulator automatically.
        echo  Please plug in your Android phone via USB (with USB Debugging ON)
        echo  or start an Android emulator from Android Studio.
        echo.
        pause
        exit /b 1
    )
)

:: 3. Check for APK
set "APK_PATH=build\app\outputs\flutter-apk\app-debug.apk"
if not exist "%APK_PATH%" (
    echo  [*] Pre-built APK not found. Building Debug APK now...
    call flutter build apk --debug
    if %ERRORLEVEL% neq 0 (
        color 0C
        echo  [ERROR] Flutter build failed!
        pause
        exit /b 1
    )
)

:: 4. Install APK
echo.
echo  [*] Installing Hearable APK to target device...
"%ADB_BIN%" install -r -d "%APK_PATH%"
if %ERRORLEVEL% neq 0 (
    color 0C
    echo  [ERROR] APK installation failed!
    pause
    exit /b 1
)

:: 5. Launch App
echo.
echo  [*] Launching Hearable (com.hearable.music)...
"%ADB_BIN%" shell am start -n com.hearable.music/.MainActivity
if %ERRORLEVEL% equ 0 (
    color 0A
    echo.
    echo  ==============================================================
    echo     SUCCESS! Hearable is now running on your device!
    echo  ==============================================================
) else (
    color 0E
    echo  [!] Installed successfully, please open Hearable manually.
)

echo.
pause

