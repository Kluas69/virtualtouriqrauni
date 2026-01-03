@echo off
echo 🚀 Starting Firebase Deployment Process...
echo.

echo 📦 Step 1: Cleaning previous builds...
flutter clean
if %errorlevel% neq 0 (
    echo ❌ Flutter clean failed
    exit /b 1
)

echo 🔨 Step 2: Building Flutter web app with optimizations...
flutter build web --release --web-renderer canvaskit --dart-define=FLUTTER_WEB_USE_SKIA=true --source-maps
if %errorlevel% neq 0 (
    echo ❌ Flutter build failed
    exit /b 1
)

echo 📁 Step 3: Copying Three.js assets to build directory...
if not exist "build\web\threejs" mkdir "build\web\threejs"
xcopy "web\threejs" "build\web\threejs" /E /I /Y
if %errorlevel% neq 0 (
    echo ❌ Failed to copy Three.js assets
    exit /b 1
)

echo 📁 Step 4: Ensuring assets are in correct locations...
if not exist "build\web\assets" mkdir "build\web\assets"
if not exist "build\web\assets\models" mkdir "build\web\assets\models"
if exist "web\assets\models\classroom.glb" (
    copy "web\assets\models\classroom.glb" "build\web\assets\models\"
)
if exist "web\threejs\public\assets\models\classroom.glb" (
    copy "web\threejs\public\assets\models\classroom.glb" "build\web\threejs\public\assets\models\"
)

echo 🔍 Step 5: Verifying build contents...
dir "build\web" /s | findstr /i "\.glb"
dir "build\web" /s | findstr /i "classroom-viewer-working.html"

echo 🌐 Step 6: Deploying to Firebase...
firebase deploy --only hosting
if %errorlevel% neq 0 (
    echo ❌ Firebase deployment failed
    exit /b 1
)

echo ✅ Deployment completed successfully!
echo 🎉 Your app is now live on Firebase!
echo.
echo 📊 Build Summary:
echo - Flutter web app built with optimizations
echo - Three.js assets included
echo - 3D models copied to multiple locations for compatibility
echo - Deployed to Firebase Hosting
echo.
pause