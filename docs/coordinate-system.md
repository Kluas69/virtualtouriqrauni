# Coordinate System Documentation

## Overview

The Dynamic 3D Location Spawn System uses the Three.js right-handed coordinate system for positioning players and orienting cameras in the 3D classroom environment.

## Coordinate System

### Three.js Right-Handed Coordinate System

```
        Y (Up)
        |
        |
        |_______ X (Right)
       /
      /
     Z (Forward)
```

### Axis Directions

- **X-axis**: 
  - Positive (+X) = Right
  - Negative (-X) = Left
  
- **Y-axis**: 
  - Positive (+Y) = Up
  - Negative (-Y) = Down
  
- **Z-axis**: 
  - Positive (+Z) = Forward (toward camera)
  - Negative (-Z) = Backward (away from camera)

## Rotation System

### Euler Angles (in radians)

The system uses Euler angles to define camera orientation:

- **Pitch**: Rotation around X-axis (looking up/down)
  - Positive = Looking up
  - Negative = Looking down
  - Range: [-π/2, π/2] for natural head movement

- **Yaw**: Rotation around Y-axis (looking left/right)
  - Positive = Turning right
  - Negative = Turning left
  - Range: [-π, π] (wraps around)

- **Roll**: Rotation around Z-axis (tilting head)
  - Positive = Tilting right
  - Negative = Tilting left
  - Range: [-π, π] (typically kept near 0 for natural feel)

### Rotation Order

The system uses **YXZ** (Yaw-Pitch-Roll) Euler order for correct rotation application:
1. First apply Yaw (Y-axis rotation)
2. Then apply Pitch (X-axis rotation)
3. Finally apply Roll (Z-axis rotation)

## Angle Conversion

### Radians to Degrees

```
degrees = radians × (180 / π)
```

### Degrees to Radians

```
radians = degrees × (π / 180)
```

### Common Angles

| Degrees | Radians | Description |
|---------|---------|-------------|
| 0° | 0 | Forward |
| 45° | π/4 ≈ 0.785 | 45° turn |
| 90° | π/2 ≈ 1.571 | Right angle |
| 180° | π ≈ 3.142 | Opposite direction |
| 270° | 3π/2 ≈ 4.712 | Three-quarter turn |
| 360° | 2π ≈ 6.283 | Full rotation |

## Spawn Configuration Format

### JSON Structure

```json
{
  "position": {
    "x": 0.0,
    "y": 1.6,
    "z": 5.0
  },
  "rotation": {
    "pitch": 0.0,
    "yaw": 0.0,
    "roll": 0.0
  },
  "locationName": "Library",
  "description": "Spawn near library entrance",
  "scaleFactor": 1.0,
  "environmentType": "classroom"
}
```

### Field Descriptions

- **position.x**: Horizontal position (left/right)
- **position.y**: Vertical position (up/down) - typically 1.6 for eye height
- **position.z**: Depth position (forward/backward)
- **rotation.pitch**: Vertical look angle (up/down)
- **rotation.yaw**: Horizontal look angle (left/right)
- **rotation.roll**: Head tilt angle (rarely used)
- **scaleFactor**: Player model scale (1.0 = normal size)
- **environmentType**: Environment identifier (e.g., "classroom")

## Coordinate Bounds

### Safe Ranges

To ensure players spawn within the 3D model boundaries:

- **X coordinate**: [-50, 50] units
- **Y coordinate**: [0.5, 10.0] units (above ground, below ceiling)
- **Z coordinate**: [-50, 50] units
- **Scale factor**: [0.1, 10.0] (reasonable size range)

### Automatic Clamping

The SpawnManager automatically clamps coordinates to safe ranges:
- Out-of-bounds values are adjusted to the nearest valid value
- Warnings are logged when clamping occurs
- This prevents players from spawning outside the model or underground

## Example Spawn Configurations

### Default Classroom Entrance

```json
{
  "position": { "x": 0.0, "y": 1.6, "z": 5.0 },
  "rotation": { "pitch": 0.0, "yaw": 0.0, "roll": 0.0 }
}
```

Spawns player at center, eye height, 5 units forward, facing straight ahead.

### Library Corner View

```json
{
  "position": { "x": -8.5, "y": 1.6, "z": 12.0 },
  "rotation": { "pitch": 0.0, "yaw": -0.785, "roll": 0.0 }
}
```

Spawns player in left corner, facing 45° to the right.

### Auditorium Back Row

```json
{
  "position": { "x": 0.0, "y": 1.6, "z": -15.0 },
  "rotation": { "pitch": 0.0, "yaw": 0.0, "roll": 0.0 }
}
```

Spawns player at back of auditorium, facing forward toward stage.

### Elevated Amphitheater View

```json
{
  "position": { "x": -12.0, "y": 3.0, "z": -8.0 },
  "rotation": { "pitch": -0.262, "yaw": 0.524, "roll": 0.0 }
}
```

Spawns player on elevated tier, looking down and slightly to the right.

## Debugging Spawn Positions

### Debug Mode

Enable debug mode by adding `?debugSpawn=true` to the URL:

```
https://your-app.com/webgl/Library?debugSpawn=true
```

This will:
- Display spawn position markers in the 3D scene
- Show coordinate values as text overlays
- Render camera orientation vectors
- Enable on-screen coordinate adjustment controls

### Console Logging

The system logs spawn information to the browser console:

```javascript
[SpawnManager] Using spawn config from postMessage
[CharacterSystem] Spawning with config: Location: Library, Position: (-8.50, 1.60, 12.00), Rotation: (pitch: 0.00, yaw: -0.79, roll: 0.00)
[CharacterSystem] Applied spawn position: [-8.5, 1.6, 12]
[CharacterSystem] Applied spawn rotation to camera
```

## Best Practices

1. **Y Coordinate**: Always set Y to at least 1.6 for eye-level viewing
2. **Rotation**: Keep pitch between -π/4 and π/4 for natural viewing angles
3. **Testing**: Use debug mode to visualize and fine-tune spawn positions
4. **Documentation**: Add descriptive comments to spawn configurations
5. **Validation**: Let the system clamp coordinates rather than manually validating

## Troubleshooting

### Player Spawns Underground

- Check that Y coordinate is >= 0.5
- Verify the 3D model's ground level matches your Y values

### Player Spawns Outside Model

- Ensure X and Z coordinates are within model bounds
- Use debug mode to visualize the spawn position

### Camera Facing Wrong Direction

- Check yaw angle (0 = forward, π/2 = right, -π/2 = left, π = backward)
- Verify rotation order is YXZ
- Ensure angles are in radians, not degrees

### Spawn Config Not Applied

- Check browser console for SpawnManager logs
- Verify postMessage is being sent from Flutter
- Confirm SpawnManager is initialized before character spawns
