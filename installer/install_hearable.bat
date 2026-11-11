@echo off
title Hearable Music - 1-Click Android Installer
color 0A
cls
echo =======================================================
echo          Hearable Music - 1-Click Android Installer
echo =======================================================
echo.

where adb >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] ADB is not detected in your system PATH.
    echo Please enable USB debugging and connect your phone with Android Platform Tools.
    pause
    exit /b
)

echo [1/3] Checking connected Android devices...
adb devices
echo.

echo [2/3] Locating Hearable APK...
set APK_FILE=app-release.apk
if not exist "%APK_FILE%" (
    set APK_FILE=..\build\app\outputs\flutter-apk\app-release.apk
)

if not exist "%APK_FILE%" (
    echo [ERROR] %APK_FILE% not found.
    echo Please compile the release APK with 'flutter build apk --release'.
    pause
    exit /b
)

echo [3/3] Installing Hearable onto your device...
adb install -r -d "%APK_FILE%"
if %ERRORLEVEL% EQU 0 (
    echo.
    echo =======================================================
    echo   SUCCESS: Hearable installed successfully!
    echo   Launching Hearable on your device now...
    echo =======================================================
    adb shell monkey -p com.hearable.music -c android.intent.category.LAUNCHER 1 >nul 2>&1
) else (
    echo.
    echo [ERROR] Installation failed. Ensure your screen is unlocked and USB Debugging is authorized.
)
echo.
pause
