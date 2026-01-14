# Spawn Coordinates Setup - Complete

## Configuration Summary

### Default Spawn (Home Screen "Start Campus Tour")
**Coordinates**: `(10.6, -0.2, -27.8)`
- Used when clicking "Start Campus Tour" button on home screen
- No spawn config is sent from Flutter
- HTML uses default coordinates from `spawnSystem.defaultConfig`

### Location-Specific Spawns (Location Cards)
**Source**: `assets/app_data.json` → `locationSpawnConfigs`
- Used when clicking any location card (Library, Class Rooms, etc.)
- Spawn config is sent from Flutter via postMessage
- HTML receives and applies custom coordinates

## Current Coordinates

### Default (Campus Tour)
```json
{
  "position": { "x": 10.6, "y": -0.2, "z": -27.8 },
  "rotation": { "pitch": 0, "yaw": 0, "roll": 0 },
  "locationName": "default",
  "description": "Default campus tour spawn position"
}
```

### Class Rooms (Custom)
```json
{
  "position": { "x": -16.9, "y": 0.6, "z": -0.6 },
  "rotation": { "pitch": 0, "yaw": 0, "roll": 0 },
  "locationName": "Class Rooms",
  "description": "Classroom spawn at specified coordinates"
}
```

### Other Locations (Placeholder)
All other locations currently use placeholder coordinates:
```json
{
  "position": { "x": 0.0, "y": 1.6, "z": 5.0 },
  "rotation": { "pitch": 0, "yaw": 0, "roll": 0 }
}
```

## How It Works

### 1. Home Screen Flow
```
User clicks "Start Campus Tour"
  ↓
navigateTo3DGame() called
  ↓
WebGLRoomScreen(title: 'Campus Tour', url: 'classroom')
  ↓ (no spawnConfig parameter)
_sendSpawnConfigToWebGL() returns early (null check)
  ↓
HTML spawnSystem.getSpawnConfig() returns defaultConfig
  ↓
Player spawns at (10.6, -0.2, -27.8) ✅
```

### 2. Location Card Flow
```
User clicks "Class Rooms" card
  ↓
_openTour() called
  ↓
spawnConfig = AppConstants.getSpawnConfigFor('Class Rooms')
  ↓ Returns: {position: {x: -16.9, y: 0.6, z: -0.6}, ...}
WebGLRoomScreen(title: 'Class Rooms', url: 'classroom', spawnConfig: config)
  ↓
_sendSpawnConfigToWebGL() sends postMessage
  ↓
HTML spawnSystem receives config
  ↓
Player spawns at (-16.9, 0.6, -0.6) ✅
```

## Files Modified

### 1. web/threejs/professional_classroom_enhanced.html
```javascript
// Default spawn coordinates updated
const spawnSystem = {
    defaultConfig: {
        position: { x: 10.6, y: -0.2, z: -27.8 }, // ← Updated
        rotation: { pitch: 0, yaw: 0, roll: 0 },
        locationName: 'default',
        description: 'Default campus tour spawn position'
    },
    // ... rest of spawn system
};

// Player initial position updated
const player = {
    position: { x: 10.6, y: -0.2, z: -27.8 }, // ← Updated
    // ... rest of player properties
};
```

### 2. assets/app_data.json
```json
{
  "locationSpawnConfigs": {
    "Class Rooms": {
      "position": { "x": -16.9, "y": 0.6, "z": -0.6 },
      // ... rest of config
    },
    // Other locations with placeholder coordinates
  }
}
```

## Testing

### Test 1: Home Screen Campus Tour
1. Open app
2. Click "Start Campus Tour" button on home screen
3. Press **P** key in-game to log position
4. **Expected**: `X: 10.600, Y: -0.200, Z: -27.800`

**Console Output:**
```
[SpawnSystem] Using default spawn config
[resetPlayer] Using spawn config: {position: {x: 10.6, y: -0.2, z: -27.8}, ...}
🎯 Player spawned at: {x: 10.6, y: -0.2, z: -27.8}
📍 Location: default
```

### Test 2: Class Rooms Location Card
1. Navigate to location cards
2. Click "Class Rooms" card
3. Click "Start Professional 3D Tour"
4. Press **P** key in-game to log position
5. **Expected**: `X: -16.900, Y: 0.600, Z: -0.600`

**Console Output:**
```
[SpawnSystem] ===== SPAWN CONFIG RECEIVED =====
[SpawnSystem] Location: Class Rooms
[SpawnSystem] Position: {x: -16.9, y: 0.6, z: -0.6}
[resetPlayer] Using spawn config: {position: {x: -16.9, y: 0.6, z: -0.6}, ...}
🎯 Player spawned at: {x: -16.9, y: 0.6, z: -0.6}
📍 Location: Class Rooms
```

### Test 3: Other Location Cards
1. Click any other location card (Library, Auditorium, etc.)
2. Press **P** key in-game
3. **Expected**: `X: 0.000, Y: 1.600, Z: 5.000` (placeholder)

## Next Steps

### 1. Gather Coordinates for Remaining Locations

For each location, navigate in-game and press **P** to log coordinates:

- [ ] Library
- [ ] Play Area
- [ ] Auditorium
- [x] Class Rooms (Done: -16.9, 0.6, -0.6)
- [ ] Amphitheater
- [ ] Cafeteria
- [ ] Common Room
- [ ] Playground
- [ ] Swimming Pool
- [ ] Webinar Room

### 2. Update app_data.json

Replace placeholder coordinates with actual coordinates:

```json
{
  "locationSpawnConfigs": {
    "Library": {
      "position": { "x": YOUR_X, "y": YOUR_Y, "z": YOUR_Z },
      "rotation": { "pitch": 0, "yaw": 0, "roll": 0 },
      "locationName": "Library",
      "description": "Library entrance spawn",
      "scaleFactor": 1.0,
      "environmentType": "classroom"
    },
    // ... repeat for all locations
  }
}
```

### 3. Test Each Location

After updating coordinates, test each location card to verify correct spawning.

## Coordinate System Reference

**Three.js Right-Handed Coordinate System:**
- **X-axis**: Positive = Right, Negative = Left
- **Y-axis**: Positive = Up, Negative = Down
- **Z-axis**: Positive = Forward (toward camera), Negative = Backward

**Rotation (Euler angles in radians):**
- **Pitch**: Rotation around X-axis (looking up/down)
  - Positive = Looking up
  - Negative = Looking down
- **Yaw**: Rotation around Y-axis (looking left/right)
  - 0 = Facing forward
  - π (3.14159) = Facing backward
  - π/2 = Facing right
  - -π/2 = Facing left
- **Roll**: Rotation around Z-axis (tilting head)
  - Usually 0 for normal gameplay

## Tips for Finding Good Spawn Points

1. **Height (Y coordinate)**:
   - Keep between 0.5 and 3.0 for ground level
   - Use -0.2 to 0.6 for most indoor locations
   - Avoid negative values below -1.0 (underground)

2. **Position (X, Z coordinates)**:
   - Stand at entrance or main viewing point
   - Press **P** to log coordinates
   - Adjust if needed for better view

3. **Rotation**:
   - Usually keep at 0 (default forward)
   - Adjust yaw if you want player facing specific direction
   - Example: `yaw: Math.PI` (3.14159) to face opposite direction

## Status

✅ **Default spawn configured**: (10.6, -0.2, -27.8)
✅ **Class Rooms configured**: (-16.9, 0.6, -0.6)
✅ **Spawn system working**: Dynamic coordinates applied correctly
📝 **Pending**: Coordinates for 9 remaining locations

## Troubleshooting

### Issue: Home screen spawns at wrong location

**Check:**
1. HTML file has correct default coordinates
2. No spawn config is being sent (check console for "No spawn config to send")
3. Browser cache cleared

### Issue: Location card spawns at default instead of custom

**Check:**
1. Spawn config exists in app_data.json for that location
2. Console shows "SPAWN CONFIG RECEIVED" message
3. Coordinates match what's in app_data.json

### Issue: Player spawns underground or in wall

**Solution:**
1. Navigate to correct position in-game
2. Press **P** to log coordinates
3. Update app_data.json with correct coordinates
4. Test again
