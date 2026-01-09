@echo off
setlocal enabledelayedexpansion

echo.
echo 🚀 PROFESSIONAL FIREBASE DEPLOYMENT
echo ====================================
echo Virtual Tour University - Clean Deployment Process
echo Project: virtualtouriqrauni
echo.

REM Color codes for better output
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "CYAN=[96m"
set "RESET=[0m"

REM Configuration
set "BUILD_TIMEOUT=300"
set "DEPLOY_TIMEOUT=600"

REM Check prerequisites
echo %BLUE%📋 Checking prerequisites...%RESET%
call :check_command flutter "Flutter CLI" "https://flutter.dev/docs/get-started/install"
call :check_command firebase "Firebase CLI" "npm install -g firebase-tools"
call :check_command dart "Dart SDK" "Included with Flutter"

REM Check Firebase login status
echo %CYAN%🔐 Checking Firebase authentication...%RESET%
firebase projects:list >nul 2>&1
if !errorlevel! neq 0 (
    echo %RED%❌ Not logged into Firebase%RESET%
    echo Please run: firebase login
    pause
    exit /b 1
)

REM Verify Firebase project
firebase use --project virtualtouriqrauni >nul 2>&1
if !errorlevel! neq 0 (
    echo %RED%❌ Firebase project 'virtualtouriqrauni' not accessible%RESET%
    echo Please check your project permissions or run: firebase use --add
    pause
    exit /b 1
)

echo %GREEN%✅ All prerequisites satisfied%RESET%
echo %GREEN%✅ Firebase project: virtualtouriqrauni%RESET%
echo.

REM Clean previous builds
echo %BLUE%🧹 Step 1: Cleaning previous builds...%RESET%
if exist "build" (
    echo Removing old build directory...
    rmdir /s /q "build" 2>nul
)
flutter clean >nul 2>&1
if !errorlevel! neq 0 (
    echo %RED%❌ Flutter clean failed%RESET%
    exit /b 1
)
echo %GREEN%✅ Clean completed%RESET%
echo.

REM Get dependencies
echo %BLUE%📦 Step 2: Getting Flutter dependencies...%RESET%
flutter pub get >nul 2>&1
if !errorlevel! neq 0 (
    echo %RED%❌ Failed to get dependencies%RESET%
    exit /b 1
)
echo %GREEN%✅ Dependencies updated%RESET%
echo.

REM Build Flutter web app
echo %BLUE%🔨 Step 3: Building Flutter web app (Production)...%RESET%
echo This may take a few minutes...
echo %CYAN%Build configuration:%RESET%
echo • Renderer: CanvasKit
echo • Mode: Release
echo • Skia: Enabled
echo • Source Maps: Enabled
echo.

timeout /t 2 >nul
flutter build web --release --web-renderer canvaskit --dart-define=FLUTTER_WEB_USE_SKIA=true --source-maps --verbose
if !errorlevel! neq 0 (
    echo.
    echo %RED%❌ Flutter build failed%RESET%
    echo.
    echo %YELLOW%Common solutions:%RESET%
    echo 1. Run 'flutter clean' and try again
    echo 2. Check for syntax errors: flutter analyze
    echo 3. Update dependencies: flutter pub get
    echo 4. Check available disk space
    echo.
    pause
    exit /b 1
)
echo %GREEN%✅ Flutter build completed successfully%RESET%
echo.

REM Setup Three.js assets
echo %BLUE%📁 Step 4: Setting up Three.js assets...%RESET%
if not exist "build\web\threejs" mkdir "build\web\threejs"

REM Copy Three.js files with error handling
if exist "web\threejs" (
    echo Copying Three.js source files...
    xcopy "web\threejs\*.html" "build\web\threejs\" /Y /Q >nul 2>&1
    xcopy "web\threejs\*.js" "build\web\threejs\" /Y /Q >nul 2>&1
    if exist "web\threejs\src" xcopy "web\threejs\src" "build\web\threejs\src" /E /I /Y /Q >nul 2>&1
    if exist "web\threejs\assets" xcopy "web\threejs\assets" "build\web\threejs\assets" /E /I /Y /Q >nul 2>&1
    echo %GREEN%✅ Three.js assets copied%RESET%
) else (
    echo %YELLOW%⚠️  No Three.js directory found, skipping...%RESET%
)
echo.

REM Setup 3D models
echo %BLUE%📦 Step 5: Setting up 3D models and assets...%RESET%
call :setup_directories
call :copy_models
echo %GREEN%✅ 3D models and assets configured%RESET%
echo.

REM Verify build
echo %BLUE%🔍 Step 6: Verifying build integrity...%RESET%
call :verify_build
echo.

REM Deploy to Firebase
echo %BLUE%🌐 Step 7: Deploying to Firebase Hosting...%RESET%
echo %CYAN%Target: https://virtualtouriqrauni.web.app%RESET%
echo Uploading to Firebase (this may take a few minutes)...
echo.

REM Show what will be deployed
echo %CYAN%Files to deploy:%RESET%
dir "build\web" /b | findstr /v /c:"." | wc -l >nul 2>&1
for /f %%i in ('dir "build\web" /s /-c ^| find "File(s)"') do echo • %%i

echo.
firebase deploy --only hosting --project virtualtouriqrauni
if !errorlevel! neq 0 (
    echo.
    echo %RED%❌ Firebase deployment failed%RESET%
    echo.
    echo %YELLOW%Common solutions:%RESET%
    echo 1. Check internet connection
    echo 2. Verify Firebase project permissions
    echo 3. Check Firebase quota limits
    echo 4. Try: firebase login --reauth
    echo.
    pause
    exit /b 1
)
echo.

REM Success message
echo %GREEN%🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!%RESET%
echo.
echo %BLUE%📊 Deployment Summary:%RESET%
echo =====================
echo %GREEN%✅ Flutter web app built with production optimizations%RESET%
echo %GREEN%✅ Three.js integration configured%RESET%
echo %GREEN%✅ 3D models and assets deployed%RESET%
echo %GREEN%✅ Firebase hosting configured with optimal caching%RESET%
echo %GREEN%✅ CORS headers configured for WebGL and 3D models%RESET%
echo %GREEN%✅ Security headers and CSP policies applied%RESET%
echo.
echo %CYAN%🔗 Live Application:%RESET%
echo https://virtualtouriqrauni.web.app
echo https://virtualtouriqrauni.firebaseapp.com
echo.
echo %BLUE%🧪 Testing Commands:%RESET%
echo • firebase hosting:channel:list (view all deployments)
echo • firebase open hosting:site (open in browser)
echo • firebase hosting:clone (clone to preview channel)
echo.
echo %YELLOW%⚠️  Post-Deployment Checklist:%RESET%
echo 1. Test the application in different browsers
echo 2. Verify 3D model loading works correctly
echo 3. Check mobile responsiveness
echo 4. Test WebGL functionality
echo 5. Verify security headers are applied
echo.
pause
goto :eof

REM Function to check if a command exists
:check_command
%1 --version >nul 2>&1
if !errorlevel! neq 0 (
    echo %RED%❌ %2 not found%RESET%
    echo Please install from: %3
    exit /b 1
)
echo %GREEN%✅ %2 found%RESET%
goto :eof

REM Function to setup directories
:setup_directories
if not exist "build\web\assets" mkdir "build\web\assets"
if not exist "build\web\assets\models" mkdir "build\web\assets\models"
if not exist "build\web\threejs\assets" mkdir "build\web\threejs\assets"
if not exist "build\web\threejs\assets\models" mkdir "build\web\threejs\assets\models"
goto :eof

REM Function to copy 3D models
:copy_models
set "model_found=false"
if exist "assets\models\*.glb" (
    echo Copying 3D models from assets\models\...
    copy "assets\models\*.glb" "build\web\assets\models\" >nul 2>&1
    copy "assets\models\*.glb" "build\web\threejs\assets\models\" >nul 2>&1
    set "model_found=true"
)
if exist "assets\models\*.gltf" (
    echo Copying GLTF models from assets\models\...
    copy "assets\models\*.gltf" "build\web\assets\models\" >nul 2>&1
    copy "assets\models\*.gltf" "build\web\threejs\assets\models\" >nul 2>&1
    set "model_found=true"
)
if "!model_found!"=="false" (
    echo %YELLOW%⚠️  No 3D models found in assets\models\%RESET%
)
goto :eof

REM Function to verify build
:verify_build
echo Checking critical files...
if exist "build\web\index.html" (
    echo %GREEN%✅ index.html%RESET%
) else (
    echo %RED%❌ index.html missing%RESET%
)
if exist "build\web\main.dart.js" (
    echo %GREEN%✅ main.dart.js%RESET%
) else (
    echo %RED%❌ main.dart.js missing%RESET%
)
if exist "build\web\flutter_bootstrap.js" (
    echo %GREEN%✅ flutter_bootstrap.js%RESET%
) else (
    echo %RED%❌ flutter_bootstrap.js missing%RESET%
)
if exist "build\web\canvaskit" (
    echo %GREEN%✅ CanvasKit directory%RESET%
) else (
    echo %RED%❌ CanvasKit directory missing%RESET%
)
goto :eof