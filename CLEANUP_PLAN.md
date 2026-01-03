# Project Cleanup Plan

## Files to Delete

### 1. Redundant Documentation Files (Outdated/Duplicate)
- `CALLBACK_FIX_COMPLETE.md` - Superseded by working implementation
- `CALLBACK_FIX_SUMMARY.md` - Duplicate of above
- `FINAL_FIX_VERIFICATION.md` - Outdated fix documentation
- `FINAL_INTEGRATION_TEST.md` - Superseded by working classroom viewer
- `DEPLOYMENT_FIX_VERIFICATION.md` - Deployment is working, doc not needed
- `INTEGRATION_TEST_REPORT.md` - Outdated test report
- `DIRECT_CLASSROOM_TEST.md` - Superseded by working implementation

### 2. Redundant Test Files (Outdated/Duplicate)
- `test_callback_fix.html` - Callback system is fixed, test not needed
- `test_threejs.html` - Generic test, superseded by specific classroom test
- `test_threejs_direct.html` - Superseded by working classroom viewer
- `test_classroom_loading.html` - Basic loading test, not needed
- `test_flutter_integration.html` - Integration is working, test not needed
- `test_flutter_navigation.html` - Navigation is working, test not needed
- `test_fix_verification.html` - Fix is verified, test not needed
- `debug_webgl_initialization.html` - Debug file, not needed in production
- `flutter_debug_test.html` - Debug file, not needed

### 3. Redundant Three.js Files
- `web/threejs/classroom-viewer.html` - ES6 module version that doesn't work with basic HTTP server
- `web/threejs/classroom-viewer-simple.html` - CDN version, but we have working version
- `web/threejs/test-classroom-direct.html` - Test file, functionality moved to working version
- `web/threejs/test-engine.html` - Engine test, not needed
- `web/threejs/test-engine-simple.html` - Engine test, not needed  
- `web/threejs/test-glb.html` - GLB test, not needed
- `web/threejs/test-main-simple.html` - Main test, not needed
- `web/threejs/debug.html` - Debug file, not needed

### 4. Redundant Build Files
- `web/dist/` - Build output directory, can be regenerated
- `web/threejs/node_modules/` - Dependencies, can be reinstalled

### 5. Keep These Files (Working/Essential)
- `web/threejs/classroom-viewer-working.html` - The working classroom viewer
- `web/threejs/src/` - Source code directory
- `web/threejs/public/` - Assets directory
- `web/threejs/package.json` - Dependencies
- `web/threejs/vite.config.js` - Build configuration
- `test_classroom_integration.html` - Comprehensive integration test
- `CLASSROOM_INTEGRATION_COMPLETE.md` - Final integration documentation
- `FIREBASE_DEPLOYMENT_SUCCESS.md` - Deployment documentation

## Cleanup Actions
1. Delete redundant documentation files
2. Delete redundant test files  
3. Delete redundant Three.js files
4. Clean build directories
5. Update remaining documentation to reference working files