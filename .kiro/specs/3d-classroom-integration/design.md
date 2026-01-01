# Design Document: 3D Classroom Model Integration

## Overview

This design document outlines the implementation of a seamless 3D classroom viewing experience that works optimally on both mobile and desktop platforms. The solution addresses WebGL availability issues and ensures proper Three.js integration with the classroom.glb model, providing robust performance optimization and error handling.

**Key Issue Addressed**: WebGL detection failures preventing 3D model loading despite browser support for Three.js and .glb files.

## Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Location      │    │   WebGL Room     │    │   Three.js      │
│   Card (UI)     │───▶│   Screen         │───▶│   Viewer        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   WebGL Service  │    │   Classroom     │
                       │   Abstraction    │    │   Model (.glb)  │
                       └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   Memory         │
                       │   Manager        │
                       └──────────────────┘
```

### Component Interaction Flow

1. **User Interaction**: User clicks "Start Tour" on Class Rooms location card
2. **Navigation**: App navigates to WebGLRoomScreen with classroom model URL
3. **Initialization**: WebGL service initializes and checks platform capabilities
4. **Model Loading**: Three.js viewer loads classroom.glb with progress tracking
5. **Optimization**: System applies mobile/desktop-specific optimizations
6. **Rendering**: 3D scene renders with first-person controls enabled
7. **Memory Management**: System monitors and manages WebGL resources

## Components and Interfaces

### 1. Enhanced Location Card Integration

**File**: `lib/core/constants.dart`

The existing location card system already has the infrastructure for WebGL integration. The classroom location is configured to use the WebGL viewer:

```dart
// Current configuration (already working)
static String viewTypeFor(String locationName) {
  if (locationName == 'Class Rooms') {
    return 'webgl';
  }
  // ... other locations
}

static String? webglUrlFor(String locationName) {
  if (locationName == 'Class Rooms') {
    return 'assets/models/classroom.glb';
  }
  return null;
}
```

**Enhancement Needed**: Add classroom-specific metadata for better user experience.

### 2. WebGL Room Screen Enhancements

**File**: `lib/Screens/webgl_room_screen.dart`

The existing WebGLRoomScreen provides the foundation. Enhancements needed:

```dart
class WebGLRoomScreen extends StatefulWidget {
  final String url;           // Model URL (classroom.glb)
  final String title;         // "Class Rooms"
  final String? description;  // Optional description
  final Map<String, dynamic>? metadata; // Classroom-specific settings
}
```

**Key Enhancements**:
- Classroom-specific loading messages
- Enhanced mobile optimization detection
- Better error recovery for classroom model
- Improved progress tracking for large models

### 3. Three.js Viewer Optimization - GLB SPECIFIC FIXES

**File**: `web/three_viewer.html`

**ISSUE**: WebGL detection may fail but Three.js can still render .glb files successfully.

**SOLUTION**: Enhanced initialization with fallback detection:

```javascript
// Enhanced WebGL Detection for GLB Support
function detectWebGLSupport() {
    try {
        const canvas = document.createElement('canvas');
        
        // Try WebGL 2.0 first
        let gl = canvas.getContext('webgl2');
        if (gl) {
            console.log('WebGL 2.0 supported');
            return { supported: true, version: 2 };
        }
        
        // Fallback to WebGL 1.0
        gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        if (gl) {
            console.log('WebGL 1.0 supported');
            return { supported: true, version: 1 };
        }
        
        return { supported: false, version: 0 };
    } catch (e) {
        console.warn('WebGL detection failed:', e);
        // Return true anyway - let Three.js attempt to initialize
        return { supported: true, version: 1, fallback: true };
    }
}

// Enhanced Three.js Initialization
function initializeThreeJS() {
    const webglInfo = detectWebGLSupport();
    
    if (!webglInfo.supported && !webglInfo.fallback) {
        showError('WebGL is not supported in this browser. Please use a modern browser like Chrome, Firefox, or Safari.');
        return false;
    }
    
    try {
        // Create renderer with enhanced error handling
        renderer = new THREE.WebGLRenderer({ 
            antialias: !shouldOptimizeForMobile,
            alpha: true,
            powerPreference: shouldOptimizeForMobile ? "low-power" : "high-performance",
            failIfMajorPerformanceCaveat: false // Allow fallback rendering
        });
        
        // Test renderer creation
        if (!renderer.getContext()) {
            throw new Error('Failed to get WebGL context from renderer');
        }
        
        console.log('Three.js renderer initialized successfully');
        return true;
        
    } catch (e) {
        console.error('Three.js initialization failed:', e);
        showError(`3D rendering initialization failed: ${e.message}`);
        return false;
    }
}

// Enhanced GLB Loading with Better Error Handling
function loadGLBModel(modelUrl) {
    const loader = new THREE.GLTFLoader();
    
    // Add detailed progress tracking
    loader.load(
        modelUrl,
        // Success callback
        function(gltf) {
            console.log('GLB model loaded successfully:', gltf);
            
            // Validate model structure
            if (!gltf.scene) {
                throw new Error('Invalid GLB file: No scene found');
            }
            
            processLoadedModel(gltf);
        },
        // Progress callback
        function(progress) {
            const percent = (progress.loaded / progress.total) * 100;
            updateLoadingProgress(percent);
            console.log(`Loading progress: ${percent.toFixed(1)}%`);
        },
        // Error callback
        function(error) {
            console.error('GLB loading error:', error);
            
            let errorMessage = 'Failed to load 3D classroom model.';
            
            if (error.message.includes('404')) {
                errorMessage = 'Classroom model file not found. Please check that classroom.glb exists in web/assets/models/';
            } else if (error.message.includes('CORS')) {
                errorMessage = 'Cross-origin error loading model. Please serve the app from a web server.';
            } else if (error.message.includes('WebGL')) {
                errorMessage = 'WebGL error while loading model. Your device may not support 3D graphics.';
            }
            
            showError(errorMessage);
        }
    );
}
```

**Key GLB-Specific Optimizations**:
- Enhanced WebGL detection with multiple fallback methods
- Specific GLB file validation
- Better error messages for common GLB loading issues
- Fallback rendering options for limited WebGL support

### 4. WebGL Service Abstraction - CRITICAL FIX NEEDED

**Files**: 
- `lib/core/webgl/webgl_service.dart`
- `lib/core/webgl/webgl_service_web.dart`
- `lib/core/webgl/webgl_service_stub.dart`

**ISSUE**: The current WebGL detection is too restrictive and fails even when Three.js can successfully render .glb models.

**Current Problem**:
```dart
// Current detection may be failing
Future<bool> isSupported() async {
  // This check might be too strict
  return webGLSupported;
}
```

**SOLUTION**: Enhanced WebGL detection with Three.js compatibility check:

```dart
abstract class WebGLService {
  Future<void> initialize();
  Future<bool> isSupported();
  Future<bool> canRenderGLB(); // NEW: Specific GLB support check
  Widget createViewer({
    required String url,
    required String title,
    VoidCallback? onLoaded,
    Function(String)? onError,
  });
  void dispose();
}
```

**Enhanced Web Implementation**:
```dart
class WebPlatformService implements PlatformService {
  @override
  Future<bool> initializeWebGL() async {
    try {
      // Try multiple WebGL detection methods
      final canvas = html.CanvasElement();
      
      // Method 1: Standard WebGL context
      var context = canvas.getContext('webgl2');
      if (context != null) return true;
      
      // Method 2: WebGL 1.0 fallback
      context = canvas.getContext('webgl');
      if (context != null) return true;
      
      // Method 3: Experimental WebGL
      context = canvas.getContext('experimental-webgl');
      if (context != null) return true;
      
      return false;
    } catch (e) {
      // Even if detection fails, Three.js might still work
      console.warn('WebGL detection failed, but Three.js may still work: $e');
      return true; // Allow Three.js to attempt rendering
    }
  }
}
```

## Data Models

### Classroom Model Configuration

```dart
class ClassroomConfig {
  final String modelUrl;
  final Vector3 initialCameraPosition;
  final Vector3 initialCameraTarget;
  final double walkSpeed;
  final double runSpeed;
  final bool enableShadows;
  final int maxTextureSize;
  final double fogDistance;
  
  const ClassroomConfig({
    required this.modelUrl,
    this.initialCameraPosition = const Vector3(0, 1.6, 5),
    this.initialCameraTarget = const Vector3(0, 1.6, 0),
    this.walkSpeed = 100.0,
    this.runSpeed = 200.0,
    this.enableShadows = true,
    this.maxTextureSize = 2048,
    this.fogDistance = 750.0,
  });
  
  // Factory for mobile optimization
  factory ClassroomConfig.forMobile() {
    return const ClassroomConfig(
      modelUrl: 'assets/models/classroom.glb',
      enableShadows: false,
      maxTextureSize: 512,
      fogDistance: 500.0,
    );
  }
  
  // Factory for desktop
  factory ClassroomConfig.forDesktop() {
    return const ClassroomConfig(
      modelUrl: 'assets/models/classroom.glb',
      enableShadows: true,
      maxTextureSize: 2048,
      fogDistance: 750.0,
    );
  }
}
```

### Performance Metrics

```dart
class WebGLPerformanceMetrics {
  final int triangleCount;
  final int drawCalls;
  final int textureCount;
  final double memoryUsageMB;
  final double currentFPS;
  final bool isOptimized;
  
  const WebGLPerformanceMetrics({
    required this.triangleCount,
    required this.drawCalls,
    required this.textureCount,
    required this.memoryUsageMB,
    required this.currentFPS,
    required this.isOptimized,
  });
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Model Loading Reliability
*For any* valid classroom.glb file, the system should successfully load and display the 3D model or provide a clear error message if loading fails.
**Validates: Requirements 1.1, 1.4**

### Property 2: Cross-Platform Consistency
*For any* supported device (mobile or desktop), the classroom 3D viewer should provide functional navigation controls and visual rendering appropriate to the device capabilities.
**Validates: Requirements 2.1, 2.2, 2.3**

### Property 3: Performance Optimization
*For any* mobile device, when frame rate drops below 20 FPS, the system should automatically reduce rendering quality to maintain smooth performance.
**Validates: Requirements 4.3, 4.5**

### Property 4: Memory Management
*For any* WebGL context creation, the system should properly register the context with the memory manager and dispose of all resources when the viewer is closed.
**Validates: Requirements 10.1, 10.3**

### Property 5: Navigation Controls
*For any* user input (WASD keys on desktop or touch on mobile), the system should translate the input into smooth camera movement within the 3D environment.
**Validates: Requirements 3.1, 3.2, 3.3**

### Property 6: Error Recovery
*For any* WebGL context loss event, the system should detect the loss and attempt automatic recovery or display appropriate error messaging.
**Validates: Requirements 6.4, 4.4**

### Property 7: Responsive Design
*For any* screen size change or device orientation change, the 3D viewport should adjust its dimensions and aspect ratio to match the new screen configuration.
**Validates: Requirements 9.1, 9.5**

### Property 8: Asset Validation
*For any* model file loaded from web/assets/models/, the system should validate the file format and structure before attempting to render.
**Validates: Requirements 8.2, 1.4**

## Error Handling - WEBGL DETECTION FIXES

### Error Categories and Responses

1. **WebGL Detection Issues - CRITICAL FIX**
   - **Problem**: WebGL detection fails even when Three.js can render GLB files
   - **Detection**: Use multiple WebGL detection methods with fallbacks
   - **Response**: Allow Three.js to attempt rendering even if initial detection fails
   - **Implementation**:
   ```dart
   // Enhanced WebGL detection in Flutter
   Future<bool> _checkWebGLSupport() async {
     try {
       // Method 1: Direct WebGL check
       final isSupported = await _webglService.isSupported();
       if (isSupported) return true;
       
       // Method 2: Three.js capability check
       final canRenderGLB = await _webglService.canRenderGLB();
       if (canRenderGLB) {
         AppLogger.info('WebGL detection failed but Three.js GLB support available');
         return true;
       }
       
       return false;
     } catch (e) {
       // Fallback: Let Three.js attempt to initialize
       AppLogger.warning('WebGL detection error, allowing Three.js fallback: $e');
       return true;
     }
   }
   ```

2. **GLB Model Loading Failures**
   - **File not found**: Check `web/assets/models/classroom.glb` exists
   - **CORS issues**: Ensure proper web server configuration
   - **Format errors**: Validate GLB file structure
   - **Memory errors**: Implement progressive loading for large models

3. **Three.js Initialization Failures**
   - **Context creation**: Try multiple WebGL context types
   - **Renderer setup**: Use fallback options for limited hardware
   - **Shader compilation**: Provide simplified shader fallbacks

4. **Mobile-Specific WebGL Issues**
   - **Context loss**: Implement automatic recovery
   - **Memory limitations**: Aggressive model optimization
   - **Performance**: Dynamic quality adjustment

### Enhanced Error Recovery Strategies

```dart
class WebGLErrorRecovery {
  static Future<bool> handleWebGLDetectionFailure() async {
    AppLogger.info('Attempting WebGL recovery strategies');
    
    // Strategy 1: Force Three.js initialization
    try {
      final viewer = await _createThreeJSViewer();
      if (viewer != null) {
        AppLogger.info('Three.js viewer created despite WebGL detection failure');
        return true;
      }
    } catch (e) {
      AppLogger.warning('Three.js fallback failed: $e');
    }
    
    // Strategy 2: Try with reduced capabilities
    try {
      final viewer = await _createReducedCapabilityViewer();
      if (viewer != null) {
        AppLogger.info('Reduced capability viewer created');
        return true;
      }
    } catch (e) {
      AppLogger.warning('Reduced capability fallback failed: $e');
    }
    
    return false;
  }
  
  static Future<Widget?> _createThreeJSViewer() async {
    // Direct Three.js viewer creation bypassing WebGL detection
    return HtmlElementView(
      viewType: 'three-js-viewer-fallback',
      creationParams: {
        'modelUrl': 'assets/models/classroom.glb',
        'fallbackMode': true,
        'ignoreWebGLDetection': true,
      },
    );
  }
}
```

## Testing Strategy

### Unit Testing
- WebGL service initialization and platform detection
- Model loading and validation logic
- Error handling and recovery mechanisms
- Memory management resource tracking

### Property-Based Testing
- Performance optimization under various device conditions
- Cross-platform rendering consistency
- Memory cleanup after viewer disposal
- Navigation control responsiveness

### Integration Testing
- End-to-end classroom tour flow
- Mobile vs desktop experience validation
- Error recovery scenarios
- Performance under load

### Manual Testing
- Real device testing on various mobile devices
- Browser compatibility testing
- Network condition simulation
- User experience validation

## Implementation Plan

### Phase 1: WebGL Detection Fix (IMMEDIATE - HIGH PRIORITY)
1. **Fix WebGL Detection Logic**
   - Update `lib/core/platform/platform_service_web.dart` with enhanced detection
   - Implement fallback WebGL context creation methods
   - Add Three.js specific capability checking
   - Test GLB loading capability independently of WebGL detection

2. **Update WebGL Service**
   - Modify `lib/core/webgl/webgl_service_web.dart` to be less restrictive
   - Add `canRenderGLB()` method for specific GLB support checking
   - Implement fallback viewer creation that bypasses strict WebGL checks
   - Add detailed logging for WebGL detection process

3. **Enhance Three.js Viewer**
   - Update `web/three_viewer.html` with better WebGL detection
   - Add multiple WebGL context creation attempts
   - Implement GLB-specific error handling
   - Add fallback rendering options for limited WebGL support

4. **Test Classroom.glb Integration**
   - Verify classroom.glb file exists at `web/assets/models/classroom.glb`
   - Test direct Three.js loading of the GLB file
   - Validate model structure and optimize if needed
   - Test on multiple browsers and devices

### Phase 2: Enhanced Mobile Experience
1. Implement classroom-specific mobile optimizations
2. Add progressive loading for large models
3. Enhance touch controls for mobile navigation
4. Implement battery-conscious rendering

### Phase 3: Desktop Enhancements
1. Add advanced lighting for classroom environment
2. Implement high-quality shadow mapping
3. Add ambient occlusion for better depth perception
4. Optimize for high-resolution displays

### Phase 4: Performance Monitoring
1. Add real-time performance metrics
2. Implement automatic quality adjustment
3. Add memory usage monitoring
4. Create performance analytics dashboard

### CRITICAL DEBUGGING STEPS

1. **Verify GLB File**
   ```bash
   # Check if classroom.glb exists
   ls -la web/assets/models/classroom.glb
   
   # Check file size (should be reasonable for web)
   du -h web/assets/models/classroom.glb
   ```

2. **Test Three.js Directly**
   - Open `web/three_viewer.html` directly in browser
   - Check browser console for WebGL errors
   - Test with URL parameter: `three_viewer.html?model=assets/models/classroom.glb`

3. **Browser Compatibility Check**
   - Test in Chrome, Firefox, Safari, Edge
   - Check mobile browsers (Chrome Mobile, Safari Mobile)
   - Verify WebGL support: Visit `https://get.webgl.org/`

4. **Flutter WebGL Integration**
   - Add debug logging to WebGL service initialization
   - Test WebGL detection in Flutter web build
   - Verify HtmlElementView registration for Three.js viewer

## Security Considerations

1. **Asset Security**: Ensure classroom.glb is served over HTTPS
2. **Memory Safety**: Prevent memory leaks in WebGL contexts
3. **Input Validation**: Sanitize all model loading parameters
4. **Error Information**: Avoid exposing sensitive system information in error messages

## Deployment Considerations

1. **Asset Optimization**: Compress classroom.glb for faster loading
2. **CDN Integration**: Consider CDN for model assets
3. **Browser Support**: Test on all target browsers
4. **Performance Monitoring**: Set up real-world performance tracking

This design provides a comprehensive foundation for implementing a robust, cross-platform 3D classroom viewing experience that leverages existing infrastructure while adding necessary enhancements for optimal performance and user experience.