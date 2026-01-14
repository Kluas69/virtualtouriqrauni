# Spawn System Test Guide

## Quick Test Instructions

### 1. Build and Run the App
```bash
flutter run -d chrome
```

### 2. Test Class Rooms Spawn

1. **Navigate to Class Rooms**:
   - From home screen, scroll to location cards
   - Click on "Class Rooms" card

2. **Start the 3D Tour**:
   - Click "Start Professional 3D Tour" button
   - Wait for 3D environment to load (2-3 seconds)

3. **Verify Spawn Position**:
   - Open browser console (F12)
   - Look for spawn logs (see expected logs below)
   - Check if player is at the correct position in the 3D world

### Expected Console Output

When everything works correctly, you should see:

```
✅ CharacterSystem initialized with auto-spawn and SpawnManager enabled
[SpawnManager] Initialized with default config: {...}

[SpawnManager] ===== SPAWN CONFIG RECEIVED =====
[SpawnManager] Received spawn config via postMessage: {...}
[SpawnManager] Location: Class Rooms
[SpawnManager] Position: {x: -16.9, y: 0.6, z: -0.6}
[SpawnManager] Rotation: {pitch: 0, yaw: 0, roll: 0}
[SpawnManager] =====================================

⏰ Auto-spawn scheduled in 2000ms

[CharacterSystem] ===== SPAWN DEBUG =====
[CharacterSystem] Current position BEFORE spawn: [0, 1.6, 5]
[CharacterSystem] Spawn config received: Location: Class Rooms, Position: (-16.90, 0.60, -0.60), Rotation: (pitch: 0.00, yaw: 0.00, roll: 0.00), Scale: 1
[CharacterSystem] Spawn config position: {x: -16.9, y: 0.6, z: -0.6}
[CharacterSystem] Applied spawn position: [-16.9, 0.6, -0.6]
[CharacterSystem] Position AFTER applySpawnPosition: [-16.9, 0.6, -0.6]
[CharacterSystem] ===== SPAWN COMPLETE =====
[CharacterSystem] Final character position: [-16.9, 0.6, -0.6]
[CharacterSystem] Final character rotation: {x: 0, y: 0, z: 0}

[PlayerController] Character spawned, syncing PlayerState position
[PlayerController] Spawn position: [-16.9, 0.6, -0.6]
[PlayerController] PlayerState synced with spawn position
```

### 3. Test Other Locations (Placeholder Coordinates)

Test any other location card (Library, Auditorium, etc.):
- Should spawn at default position: (0, 1.6, 5)
- Console should show: `Location: [Location Name], Position: (0.00, 1.60, 5.00)`

### 4. Visual Verification

In the 3D environment:
- **Class Rooms**: You should be at position (-16.9, 0.6, -0.6)
- **Other Locations**: You should be at position (0, 1.6, 5)

Use the in-game debug info (if available) to verify coordinates.

## Troubleshooting

### Issue: Still spawning at old position (9.6, -0.2, -28.1)

**Solution**: Clear browser cache and rebuild
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Issue: No spawn logs in console

**Possible Causes**:
1. Console is filtered - make sure "All" or "Verbose" is selected
2. 3D environment didn't load - check for errors in console
3. postMessage not sent - check Flutter logs

### Issue: Spawn config not received

**Check**:
1. Flutter logs for: `Spawn config sent to WebGL`
2. JavaScript logs for: `SPAWN CONFIG RECEIVED`
3. Network tab for iframe loading

### Issue: Player spawns at (0, 1.6, 5) for Class Rooms

**Possible Causes**:
1. postMessage arrived after spawn (increase delay in CharacterSystem.js)
2. Spawn config not in app_data.json
3. Location name mismatch

**Verify**:
```bash
# Check app_data.json has Class Rooms config
cat assets/app_data.json | grep "Class Rooms" -A 10
```

## Debug Mode

To enable more detailed logging, you can modify the CharacterSystem options:

In `web/threejs/src/core/PlayerController.js`:
```javascript
this.characterSystem = new CharacterSystem(scene, {
    ...this.options,
    debugMode: true  // Enable debug mode
}, camera);
```

This will show:
- Character bounding box
- Position indicator (red sphere)
- Direction indicator (green cone)
- Additional debug logs

## Next Steps After Successful Test

1. ✅ Verify Class Rooms spawns at (-16.9, 0.6, -0.6)
2. ✅ Verify other locations spawn at default (0, 1.6, 5)
3. 📝 Provide coordinates for remaining 9 locations
4. 🔄 Update `assets/app_data.json` with actual coordinates
5. 🧪 Test each location individually

## Coordinate Format

When providing coordinates for other locations, use this format:

```json
"Location Name": {
  "position": { "x": 0.0, "y": 1.6, "z": 5.0 },
  "rotation": { "pitch": 0.0, "yaw": 0.0, "roll": 0.0 },
  "locationName": "Location Name",
  "description": "Description of spawn point",
  "scaleFactor": 1.0,
  "environmentType": "classroom"
}
```

**Coordinate System**:
- **X-axis**: Positive = Right, Negative = Left
- **Y-axis**: Positive = Up, Negative = Down (keep between 0.5 and 3.0)
- **Z-axis**: Positive = Forward, Negative = Backward

**Rotation** (in radians):
- **Pitch**: Looking up/down (0 = straight ahead)
- **Yaw**: Looking left/right (0 = facing forward)
- **Roll**: Head tilt (usually 0)

## Support

If you encounter any issues:
1. Check console logs for errors
2. Verify spawn config in `assets/app_data.json`
3. Clear browser cache and rebuild
4. Check that all modified files are saved and deployed
