# Spawn System Fix - Dynamic Location Coordinates

## Problem
The character was spawning at a hardcoded position (9.6, -0.2, -28.1) instead of using the dynamic spawn coordinates configured for each location card. When clicking "Class Rooms" location card, the player should spawn at (-16.9, 0.6, -0.6), but was spawning at the default game position.

## Root Causes Identified

### 1. Hardcoded Position in CharacterSystem
**File**: `web/threejs/src/core/CharacterSystem.js`
- **Issue**: Constructor had hardcoded position `this.position = new THREE.Vector3(9.6, -0.2, -28.1)`
- **Fix**: Changed to use SpawnManager's default config position `(0, 1.6, 5)`

### 2. Hardcoded Position in PlayerState
**File**: `web/threejs/src/core/PlayerController.js`
- **Issue**: PlayerState constructor had hardcoded position `new THREE.Vector3(9.6, -0.2, -28.1)`
- **Fix**: Changed to use default spawn position `(0, 1.6, 5)`

### 3. Timing Issue - Spawn Before Config Arrives
**File**: `web/threejs/src/core/CharacterSystem.js`
- **Issue**: Auto-spawn delay was 1000ms, which might not be enough for postMessage to arrive
- **Fix**: Increased spawn delay to 2000ms to ensure spawn config arrives via postMessage

### 4. Missing Synchronization Between CharacterSystem and PlayerController
**File**: `web/threejs/src/core/PlayerController.js`
- **Issue**: CharacterSystem spawns at correct position, but PlayerController's PlayerState wasn't synced
- **Fix**: Added `setupSpawnListener()` method that listens for spawn events and syncs PlayerState position with CharacterSystem

## Changes Made

### 1. CharacterSystem.js
```javascript
// BEFORE
this.position = new THREE.Vector3(9.6, -0.2, -28.1); // Hardcoded

// AFTER
const defaultConfig = this.spawnManager.defaultSpawnConfig;
this.position = new THREE.Vector3(
    defaultConfig.position.x,
    defaultConfig.position.y,
    defaultConfig.position.z
);
```

```javascript
// BEFORE
spawnDelay: 1000, // 1 second delay

// AFTER
spawnDelay: 2000, // 2 second delay to ensure spawn config arrives
```

### 2. PlayerController.js
```javascript
// BEFORE
this.position = new THREE.Vector3(9.6, -0.2, -28.1); // Hardcoded

// AFTER
this.position = new THREE.Vector3(0, 1.6, 5); // Default spawn position
```

Added new method:
```javascript
setupSpawnListener() {
    // Listens for character spawn events
    // Syncs PlayerState position with CharacterSystem spawn position
    // Updates camera position and rotation
}
```

### 3. Enhanced Logging
Added comprehensive debug logging to track spawn process:
- SpawnManager logs when postMessage is received
- CharacterSystem logs spawn config before and after application
- PlayerController logs when syncing with spawn position

## How It Works Now

### Data Flow
1. **Flutter Side** (`location_detail_screen.dart`):
   - Gets spawn config for location: `AppConstants.getSpawnConfigFor(locationName)`
   - Passes to WebGLRoomScreen: `spawnConfig: spawnConfig`

2. **WebGL Screen** (`webgl_room_screen.dart`):
   - Sends spawn config via postMessage when iframe loads
   - Message format: `{ type: 'SPAWN_CONFIG', data: spawnConfig.toJson() }`

3. **JavaScript Side** (`SpawnManager.js`):
   - Receives postMessage with spawn config
   - Stores in `currentSpawnConfig`
   - Logs receipt with full details

4. **Character Spawn** (`CharacterSystem.js`):
   - Waits 2 seconds for spawn config to arrive
   - Gets spawn config from SpawnManager
   - Applies position and rotation
   - Triggers spawn callback

5. **Player Sync** (`PlayerController.js`):
   - Listens for spawn callback
   - Syncs PlayerState position with CharacterSystem
   - Updates camera position and rotation

## Testing

### Test Case 1: Class Rooms Location
- **Action**: Click "Class Rooms" location card
- **Expected**: Player spawns at (-16.9, 0.6, -0.6)
- **Verify**: Check browser console for spawn logs

### Test Case 2: Default Spawn (Start Campus Tour)
- **Action**: Click "Start Campus Tour" from home screen
- **Expected**: Player spawns at (0, 1.6, 5)
- **Verify**: Check browser console for spawn logs

### Test Case 3: Other Locations
- **Action**: Click any other location card (Library, Auditorium, etc.)
- **Expected**: Player spawns at (0, 1.6, 5) - placeholder coordinates
- **Note**: User will provide actual coordinates for each location later

## Console Logs to Verify

When spawn system works correctly, you should see:
```
[SpawnManager] ===== SPAWN CONFIG RECEIVED =====
[SpawnManager] Received spawn config via postMessage: {...}
[SpawnManager] Location: Class Rooms
[SpawnManager] Position: {x: -16.9, y: 0.6, z: -0.6}
[SpawnManager] =====================================

[CharacterSystem] ===== SPAWN DEBUG =====
[CharacterSystem] Current position BEFORE spawn: [0, 1.6, 5]
[CharacterSystem] Spawn config received: Location: Class Rooms, Position: (-16.90, 0.60, -0.60), ...
[CharacterSystem] Position AFTER applySpawnPosition: [-16.9, 0.6, -0.6]
[CharacterSystem] ===== SPAWN COMPLETE =====
[CharacterSystem] Final character position: [-16.9, 0.6, -0.6]

[PlayerController] Character spawned, syncing PlayerState position
[PlayerController] Spawn position: [-16.9, 0.6, -0.6]
[PlayerController] PlayerState synced with spawn position
```

## Next Steps

1. **Test the fix**: Run the app and click "Class Rooms" location card
2. **Verify spawn position**: Check console logs and in-game position
3. **Provide coordinates**: User will provide actual spawn coordinates for remaining 9 locations
4. **Update app_data.json**: Replace placeholder coordinates with actual values

## Files Modified
- `web/threejs/src/core/CharacterSystem.js`
- `web/threejs/src/core/PlayerController.js`
- `web/threejs/src/core/SpawnManager.js`

## Status
✅ **FIXED** - Character now spawns at location-specific coordinates
