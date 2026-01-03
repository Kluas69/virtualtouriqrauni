#!/bin/bash

echo "🚀 Starting Firebase Deployment Process..."
echo

echo "📦 Step 1: Cleaning previous builds..."
flutter clean
if [ $? -ne 0 ]; then
    echo "❌ Flutter clean failed"
    exit 1
fi

echo "🔨 Step 2: Building Flutter web app with optimizations..."
flutter build web --release --web-renderer canvaskit --dart-define=FLUTTER_WEB_USE_SKIA=true --source-maps
if [ $? -ne 0 ]; then
    echo "❌ Flutter build failed"
    exit 1
fi

echo "📁 Step 3: Copying Three.js assets to build directory..."
mkdir -p "build/web/threejs"
cp -r "web/threejs/"* "build/web/threejs/"
if [ $? -ne 0 ]; then
    echo "❌ Failed to copy Three.js assets"
    exit 1
fi

echo "📁 Step 4: Ensuring assets are in correct locations..."
mkdir -p "build/web/assets/models"
if [ -f "web/assets/models/classroom.glb" ]; then
    cp "web/assets/models/classroom.glb" "build/web/assets/models/"
fi
if [ -f "web/threejs/public/assets/models/classroom.glb" ]; then
    mkdir -p "build/web/threejs/public/assets/models"
    cp "web/threejs/public/assets/models/classroom.glb" "build/web/threejs/public/assets/models/"
fi

echo "🔍 Step 5: Verifying build contents..."
find "build/web" -name "*.glb" -type f
find "build/web" -name "classroom-viewer-working.html" -type f

echo "🌐 Step 6: Deploying to Firebase..."
firebase deploy --only hosting
if [ $? -ne 0 ]; then
    echo "❌ Firebase deployment failed"
    exit 1
fi

echo "✅ Deployment completed successfully!"
echo "🎉 Your app is now live on Firebase!"
echo
echo "📊 Build Summary:"
echo "- Flutter web app built with optimizations"
echo "- Three.js assets included"
echo "- 3D models copied to multiple locations for compatibility"
echo "- Deployed to Firebase Hosting"
echo