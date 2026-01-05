# Three.js Classroom Viewer - Complete Testing Setup

This directory contains a comprehensive Three.js implementation for viewing your classroom.glb model with advanced features and local testing capabilities.

## 🚀 Quick Start

### Option 1: Simple Testing (Recommended)
1. **Start the local server:**
   - **Windows:** Double-click `server.bat`
   - **Mac/Linux:** Run `./server.sh` or `python3 server.py`

2. **Open in browser:**
   - Go to `http://localhost:3000/simple.html`
   - Click to start exploring your classroom!

### Option 2: Advanced Testing
1. Start the server (same as above)
2. Go to `http://localhost:3000/index.html` for the full modular version

## 📦 Model Loading

The system automatically tries multiple paths for your `classroom.glb` model:
- `./assets/models/classroom.glb`
- `../assets/models/classroom.glb`
- `../../assets/models/classroom.glb`
- `/assets/models/classroom.glb`
- And more fallback paths...

**Make sure your `classroom.glb` file is in one of these locations:**
- `web/assets/models/classroom.glb`
- `assets/models/classroom.glb`
- `web/threejs/assets/models/classroom.glb`

## 🎮 Controls

### Movement
- **WASD** - Move around
- **Mouse** - Look around
- **Click** - Lock pointer for first-person view
- **ESC** - Unlock pointer
- **Space** - Jump
- **Shift** - Run (2x speed)

### Special Features
- **🐝 Bee Mode** - 2mm wide character (fits through ANY gap)
- **🐜 Ant Mode** - 1mm wide character (microscopic navigation)
- **Reset Position** - Return to starting point
- **Screenshot** - Capture current view
- **Debug Info** - View technical details

## 🔧 Features

### Smart Model Loading
- **Multiple Path Fallbacks** - Tries various common locations
- **Progress Tracking** - Shows loading percentage
- **Error Recovery** - Creates fallback scene if model fails to load
- **CORS Support** - Proper headers for local development

### Character System
- **Bee-Sized Character** - 2mm diameter for maximum navigation freedom
- **Ant-Sized Character** - 1mm diameter for microscopic exploration
- **Physics** - Gravity, jumping, collision detection
- **First-Person View** - Immersive camera controls

### Performance Optimizations
- **Quality Settings** - Ultra, High, Medium, Low, Potato modes
- **Shadow Mapping** - Realistic lighting and shadows
- **Material Optimization** - Efficient rendering
- **Memory Management** - Proper resource cleanup

### Error Handling
- **Comprehensive Logging** - Detailed console output
- **Fallback Scenes** - Basic room if model fails to load
- **Error Recovery** - Graceful handling of WebGL context loss
- **Debug Tools** - Built-in debugging capabilities

## 📁 File Structure

```
web/threejs/
├── simple.html              # Simple testing interface
├── index.html               # Full modular interface
├── server.py                # Python development server
├── server.bat               # Windows server launcher
├── server.sh                # Mac/Linux server launcher
├── README.md                # This documentation
├── src/
│   ├── main.js              # Main entry point
│   ├── ClassroomViewer.js   # Full modular viewer
│   ├── SimpleClassroomViewer.js # Simple direct implementation
│   ├── core/                # Core systems
│   ├── engine/              # Game engine components
│   ├── systems/             # ECS systems
│   └── loaders/             # Asset loading
└── assets/
    └── models/
        └── classroom.glb    # Your 3D model (place here)
```

## 🧪 Testing Scenarios

### 1. Model Loading Test
- Start server and open `simple.html`
- Check console for model loading attempts
- Verify model appears or fallback scene loads

### 2. Navigation Test
- Click to lock pointer
- Use WASD to move around
- Test jumping with Space
- Test running with Shift

### 3. Bee Mode Test
- Click "🐝 Bee Mode" button
- Navigate through small spaces
- Verify 2mm character width in console

### 4. Ant Mode Test
- Click "🐜 Ant Mode" button
- Test microscopic navigation
- Verify 1mm character width in console

### 5. Error Handling Test
- Rename/remove classroom.glb file
- Reload page
- Verify fallback scene appears

### 6. Performance Test
- Open browser dev tools (F12)
- Monitor FPS in console
- Test different quality settings

## 🐛 Troubleshooting

### Model Not Loading
1. **Check file location** - Ensure `classroom.glb` is in `assets/models/`
2. **Check console** - Look for loading error messages
3. **Try different paths** - Move model to different locations
4. **Check file permissions** - Ensure file is readable

### Server Won't Start
1. **Install Python** - Download from python.org
2. **Check port** - Server tries ports 3000-3009
3. **Run manually** - Use `python server.py` directly

### Performance Issues
1. **Lower quality** - Use "Low" or "Potato" quality settings
2. **Close other tabs** - Free up GPU memory
3. **Update browser** - Use latest Chrome/Firefox
4. **Check hardware** - Ensure WebGL support

### Controls Not Working
1. **Click to lock pointer** - Required for first-person controls
2. **Check browser permissions** - Allow pointer lock
3. **Try different browser** - Test in Chrome/Firefox
4. **Check console** - Look for JavaScript errors

## 🔍 Debug Information

### Console Commands
```javascript
// Get debug info
window.classroomViewer.getDebugInfo()

// Reset player
window.classroomViewer.resetPlayer()

// Activate bee mode
window.classroomViewer.activateBeeMode()

// Take screenshot
window.classroomViewer.takeScreenshot()

// Access Three.js objects directly
window.classroomViewer.scene
window.classroomViewer.camera
window.classroomViewer.renderer
```

### Performance Monitoring
- Open browser dev tools (F12)
- Go to Console tab
- Look for FPS and performance metrics
- Check for error messages

## 🚀 Integration with Flutter

Once testing is complete, the Three.js viewer can be integrated into your Flutter web app:

1. **Copy working files** to your Flutter web directory
2. **Update paths** in your Flutter HTML template
3. **Add message handling** for Flutter ↔ Three.js communication
4. **Test in Flutter dev server** to ensure compatibility

## 📝 Next Steps

1. **Test locally** - Use the development server to test everything
2. **Verify model loading** - Ensure your classroom.glb loads correctly
3. **Test navigation** - Try all movement controls and special modes
4. **Check performance** - Monitor FPS and adjust quality if needed
5. **Debug issues** - Use console tools to identify any problems
6. **Integrate with Flutter** - Once working, integrate into your main app

## 🎯 Expected Results

After successful testing, you should have:
- ✅ Classroom model loading correctly
- ✅ Smooth first-person navigation
- ✅ Bee/Ant mode working for tight spaces
- ✅ Error handling with fallback scenes
- ✅ Performance monitoring and optimization
- ✅ Ready for Flutter integration

## 📞 Support

If you encounter issues:
1. Check the console for error messages
2. Try the simple.html version first
3. Verify your classroom.glb file is accessible
4. Test with the fallback scene (rename model file temporarily)
5. Check browser compatibility (Chrome/Firefox recommended)

Happy exploring your 3D classroom! 🎓✨