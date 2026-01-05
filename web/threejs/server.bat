@echo off
echo 🚀 Starting Three.js Classroom Viewer Development Server...
echo.

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python not found! Please install Python 3.x
    echo    Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Start the server
echo 📍 Starting server with Python...
python server.py

pause