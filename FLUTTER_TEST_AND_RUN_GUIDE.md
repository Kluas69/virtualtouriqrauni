# 🚀 Flutter App Test & Run Guide

## 🔧 **Screen Refresh Issue - FIXED**

### Problem Identified:
- Screen was refreshing due to unnecessary widget rebuilds
- State management was triggering frequent updates
- Hot reload was causing continuous refreshes

### Solution Applied:
1. **Created `RefreshFix` utility** - Prevents unnecessary rebuilds
2. **Added `StableWidget`** - Caches widgets to prevent refreshes
3. **Enhanced state management** - Debounced updates
4. **Optimized main app** - Wrapped with stable widgets

## 🧪 **Step-by-Step Testing Process**

### 1. **Test the Working Classroom Viewer**
```bash
# Open the working classroom viewer directly
http://localhost:8000/web/threejs/classroom-viewer-working.html
```
**Expected Result:** 3D classroom loads with WASD controls

### 2. **Test Integration**
```bash
# Open the comprehensive integration test
http://localhost:8000/test_classroom_integration.html
```
**Expected Result:** All tests pass, classroom loads in iframe

### 3. **Run Flutter App**
```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Run on Chrome (recommended for 3D)
flutter run -d chrome --web-port 8080

# Alternative: Run on Edge
flutter run -d edge --web-port 8080
```

### 4. **Test Navigation Flow**
1. **Home Screen** → Should load without refreshing
2. **Categories** → Click to browse locations
3. **Classroom** → Select classroom location
4. **Start Tour** → Should load 3D classroom

## 🎯 **Expected Behavior**

### ✅ **Fixed Issues:**
- ❌ **Screen refreshing** → ✅ **Stable display**
- ❌ **Continuous rebuilds** → ✅ **Optimized updates**
- ❌ **Hot reload loops** → ✅ **Controlled refreshes**

### ✅ **Working Features:**
- **3D Classroom Loading** - Loads classroom.glb model
- **WASD Controls** - First-person navigation
- **Flutter Integration** - Iframe communication
- **Responsive Design** - Works on mobile and desktop
- **Error Handling** - Graceful error recovery

## 🐛 **Troubleshooting**

### If Screen Still Refreshes:
```bash
# 1. Stop all running processes
flutter clean

# 2. Clear browser cache
# Chrome: Ctrl+Shift+Delete → Clear all

# 3. Restart with fresh build
flutter pub get
flutter run -d chrome --web-port 8080 --release
```

### If 3D Classroom Doesn't Load:
```bash
# 1. Check if Three.js server is running
cd web/threejs
npm run dev

# 2. Verify model file exists
ls -la web/threejs/public/assets/models/classroom.glb

# 3. Test direct access
http://localhost:3000/public/assets/models/classroom.glb
```

### If Flutter Build Fails:
```bash
# 1. Check Flutter doctor
flutter doctor

# 2. Update dependencies
flutter pub upgrade

# 3. Clean and rebuild
flutter clean
flutter pub get
flutter build web
```

## 📊 **Performance Monitoring**

### Memory Usage:
- **Target:** < 100MB for mobile
- **Monitor:** Chrome DevTools → Memory tab
- **Optimize:** Automatic cleanup every 5 minutes

### Frame Rate:
- **Target:** 30+ FPS for 3D scenes
- **Monitor:** Chrome DevTools → Performance tab
- **Optimize:** Reduced shadow quality on mobile

### Network:
- **Model Size:** classroom.glb should be < 50MB
- **Loading Time:** < 10 seconds on average connection
- **Caching:** Models cached after first load

## 🎮 **User Experience Test**

### Desktop (Chrome/Edge):
1. **Home Screen** - Loads in < 3 seconds
2. **Navigation** - Smooth transitions
3. **3D Classroom** - WASD controls responsive
4. **Performance** - 30+ FPS consistently

### Mobile (Chrome Mobile):
1. **Touch Controls** - Tap to enter first-person
2. **Movement** - Touch and drag to look around
3. **Performance** - Optimized for mobile devices
4. **Memory** - Automatic cleanup prevents crashes

## 🚀 **Deployment Test**

### Local Testing:
```bash
# Build for production
flutter build web --release

# Test production build
cd build/web
python -m http.server 8080
# Open: http://localhost:8080
```

### Firebase Deployment:
```bash
# Deploy to Firebase
firebase deploy

# Test live version
# Open: https://virtualtouriqrauni.web.app
```

## 📝 **Success Checklist**

- [ ] Flutter app runs without screen refreshing
- [ ] Home screen loads smoothly
- [ ] Categories navigation works
- [ ] Classroom selection works
- [ ] 3D classroom loads with WASD controls
- [ ] No console errors
- [ ] Performance is acceptable (30+ FPS)
- [ ] Memory usage is reasonable (< 100MB)
- [ ] Mobile experience is optimized
- [ ] Production build works
- [ ] Firebase deployment successful

## 🎉 **Ready for Production**

Once all tests pass:
1. **Performance is optimized** ✅
2. **Screen refresh issue fixed** ✅
3. **3D integration working** ✅
4. **Mobile experience polished** ✅
5. **Error handling robust** ✅

Your Flutter app with 3D classroom integration is ready! 🚀