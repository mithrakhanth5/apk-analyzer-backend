@echo off
echo ===================================================
echo    APK Risk Analyzer - Mobile Deployer
echo ===================================================
echo.
echo [1/3] Checking for Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not in PATH.
    pause
    exit /b
)

echo [2/3] Cleaning and Building APK...
call flutter clean
call flutter build apk --debug

echo.
echo [3/3] Installing to device...
echo NOTE: Ensure your mobile is connected via USB and Debugging is ON.
call flutter install

echo.
echo ===================================================
echo    DEPLOYMENT COMPLETE!
echo    Ensure the BACKEND is running: release\run_backend.bat
echo ===================================================
pause
