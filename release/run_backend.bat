@echo off
echo ===================================================
echo    APK Risk Analyzer - Backend Launcher
echo ===================================================
echo.
echo [1/3] Checking for Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH.
    echo Please install Python 3.9+ from python.org
    pause
    exit /b
)

echo [2/3] Installing dependencies...
pip install -r backend\requirements.txt

echo.
echo [3/3] Starting Server...
echo.
echo  --- IMPORTANT ------------------------------------
echo  DO NOT CLOSE THIS WINDOW while using the mobile app
echo  Your Local IP: 10.184.190.245
echo  --------------------------------------------------
echo.

cd ..\backend_new
python main.py
pause
