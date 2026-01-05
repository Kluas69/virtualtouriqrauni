@echo off
echo 🚀 Professional Firebase Deployment Process
echo ============================================
echo.

REM Check prerequisites
echo 📋 Checking prerequisites...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter not found. Please install Flutter first.
    exit /b 1
)

firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI not found. Please install: npm install -g firebase-tools
    exit /b 1
)

echo ✅ Prerequisites check passed
echo.

echo 📦 Step 1: Cleaning previous builds...
flutter clean
if %errorlevel% neq 0 (
    echo ❌ Flutter clean failed
    exit /b 1
)
echo ✅ Clean completed
echo.

echo 🔨 Step 2: Building Flutter web app with production optimizations...
flutter build web --release --web-renderer canvaskit --dart-define=FLUTTER_WEB_USE_SKIA=true --source-maps --dart-define=FLUTTER_WEB_AUTO_DETECT=false
if %errorlevel% neq 0 (
    echo ❌ Flutter build failed
    exit /b 1
)
echo ✅ Flutter build completed
echo.

echo 📁 Step 3: Setting up Three.js assets in build directory...
if not exist "build\web\threejs" mkdir "build\web\threejs"

REM Copy Three.js files
echo Copying Three.js source files...
xcopy "web\threejs\*.html" "build\web\threejs\" /Y
xcopy "web\threejs\*.js" "build\web\threejs\" /Y
if exist "web\threejs\src" xcopy "web\threejs\src" "build\web\threejs\src" /E /I /Y
if exist "web\threejs\assets" xcopy "web\threejs\assets" "build\web\threejs\assets" /E /I /Y
echo ✅ Three.js assets copied
echo.

echo 📁 Step 4: Ensuring 3D models are in all required locations...
REM Create all necessary asset directories
if not exist "build\web\assets" mkdir "build\web\assets"
if not exist "build\web\assets\models" mkdir "build\web\assets\models"
if not exist "build\web\threejs\assets" mkdir "build\web\threejs\assets"
if not exist "build\web\threejs\assets\models" mkdir "build\web\threejs\assets\models"
if not exist "build\web\threejs\public" mkdir "build\web\threejs\public"
if not exist "build\web\threejs\public\assets" mkdir "build\web\threejs\public\assets"
if not exist "build\web\threejs\public\assets\models" mkdir "build\web\threejs\public\assets\models"

REM Copy 3D models to all strategic locations for maximum compatibility
if exist "assets\models\classroom.glb" (
    echo 📦 Copying classroom.glb to multiple locations for maximum compatibility...
    copy "assets\models\classroom.glb" "build\web\assets\models\" >nul
    copy "assets\models\classroom.glb" "build\web\threejs\assets\models\" >nul
    copy "assets\models\classroom.glb" "build\web\threejs\public\assets\models\" >nul
    copy "assets\models\classroom.glb" "build\web\threejs\classroom.glb" >nul
    copy "assets\models\classroom.glb" "build\web\classroom.glb" >nul
    echo ✅ 3D models copied to all locations
) else (
    echo ❌ classroom.glb not found in assets\models\
    exit /b 1
)

REM Also copy from web directory if it exists there
if exist "web\classroom.glb" (
    copy "web\classroom.glb" "build\web\classroom.glb" >nul
)
if exist "web\assets\models\classroom.glb" (
    copy "web\assets\models\classroom.glb" "build\web\assets\models\classroom.glb" >nul
)
echo.

echo 🔍 Step 5: Verifying build contents...
echo Checking for 3D models:
if exist "build\web\assets\models\classroom.glb" (
    echo ✅ Found: build\web\assets\models\classroom.glb
) else (
    echo ❌ Missing: build\web\assets\models\classroom.glb
)

if exist "build\web\threejs\classroom.glb" (
    echo ✅ Found: build\web\threejs\classroom.glb
) else (
    echo ❌ Missing: build\web\threejs\classroom.glb
)

if exist "build\web\classroom.glb" (
    echo ✅ Found: build\web\classroom.glb
) else (
    echo ❌ Missing: build\web\classroom.glb
)

if exist "build\web\threejs\assets\models\classroom.glb" (
    echo ✅ Found: build\web\threejs\assets\models\classroom.glb
) else (
    echo ❌ Missing: build\web\threejs\assets\models\classroom.glb
)

echo.
echo Checking for Three.js files:
if exist "build\web\threejs\classroom-viewer-working.html" (
    echo ✅ Found: build\web\threejs\classroom-viewer-working.html
) else (
    echo ❌ Missing: build\web\threejs\classroom-viewer-working.html
)
echo.

echo 🌐 Step 6: Deploying to Firebase with production settings...
firebase deploy --only hosting
if %errorlevel% neq 0 (
    echo ❌ Firebase deployment failed
    exit /b 1
)
echo.

echo ✅ Deployment completed successfully!
echo 🎉 Your app is now live on Firebase!
echo.
echo 📊 Build Summary:
echo ================
echo ✅ Flutter web app built with production optimizations
echo ✅ Three.js application prepared and included
echo ✅ 3D models copied to multiple locations for compatibility
echo ✅ CORS headers configured for 3D model loading
echo ✅ Deployed to Firebase Hosting with caching optimizations
echo.
echo 🔗 To access your app:
echo 1. Check your Firebase console for the hosting URL
echo 2. Or run: firebase hosting:channel:list
echo.
echo 🧪 To test 3D model loading:
echo 1. Open your deployed app
echo 2. Navigate to any location and click "Start Tour"
echo 3. Check browser console for any errors
echo.
pause