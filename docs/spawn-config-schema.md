# Spawn Configuration JSON Schema

## Overview

This document defines the JSON schema for location spawn configurations in the Dynamic 3D Location Spawn System.

## Schema Definition

### Root Object: `locationSpawnConfigs`

The root object contains spawn configurations for all campus locations, keyed by location name.

```json
{
  "locationSpawnConfigs": {
    "Location Name": { /* SpawnConfig object */ },
    ...
  }
}
```

### SpawnConfig Object

Each location has a spawn configuration object with the following structure:

```typescript
interface SpawnConfig {
  position: Vector3;           // Required: 3D spawn position
  rotation: Vector3;           // Required: Camera orientation
  locationName: string;        // Required: Location identifier
  description?: string;        // Optional: Human-readable description
  scaleFactor?: number;        // Optional: Player scale (default: 1.0)
  environmentType?: string;    // Optional: Environment type (default: "classroom")
}

interface Vector3 {
  x: number;  // X-axis coordinate
  y: number;  // Y-axis coordinate
  z: number;  // Z-axis coordinate
}
```

## Field Specifications

### position (Required)

3D coordinates where the player spawns.

**Type**: `Object { x: number, y: number, z: number }`

**Coordinate System**: Three.js right-handed
- X: Horizontal (left/right)
- Y: Vertical (up/down)
- Z: Depth (forward/backward)

**Valid Ranges**:
- `x`: -50.0 to 50.0 (automatically clamped)
- `y`: 0.5 to 10.0 (automatically clamped)
- `z`: -50.0 to 50.0 (automatically clamped)

**Example**:
```json
"position": {
  "x": -8.5,
  "y": 1.6,
  "z": 12.0
}
```

**Notes**:
- Y value of 1.6 represents typical eye height
- Values outside valid ranges are automatically clamped
- Use debug mode to visualize spawn positions

---

### rotation (Required)

Camera orientation in Euler angles (radians).

**Type**: `Object { pitch: number, yaw: number, roll: number }`

**Rotation System**: Euler angles in radians
- pitch: Vertical look angle (up/down)
- yaw: Horizontal look angle (left/right)
- roll: Head tilt angle (left/right)

**Valid Ranges**:
- `pitch`: -π to π (automatically normalized)
- `yaw`: -π to π (automatically normalized)
- `roll`: -π to π (automatically normalized)

**Example**:
```json
"rotation": {
  "pitch": 0.0,
  "yaw": -0.785,
  "roll": 0.0
}
```

**Common Values**:
- `0.0`: Facing forward/level
- `0.785` (π/4): 45° turn
- `1.571` (π/2): 90° turn
- `3.142` (π): 180° turn

**Notes**:
- Angles are in radians, not degrees
- Angles are automatically normalized to [-π, π]
- Roll is typically 0.0 for natural viewing

---

### locationName (Required)

Unique identifier for the location.

**Type**: `string`

**Valid Values**: Must match a location card title exactly
- "Library"
- "Play Area"
- "Auditorium"
- "Class Rooms"
- "Amphitheater"
- "Cafeteria"
- "Common Room"
- "Playground"
- "Swimming Pool"
- "Webinar Room"

**Example**:
```json
"locationName": "Library"
```

**Notes**:
- Must match location card title exactly (case-sensitive)
- Used for logging and debugging
- Displayed in spawn configuration logs

---

### description (Optional)

Human-readable description of the spawn point.

**Type**: `string`

**Default**: Empty string

**Example**:
```json
"description": "Spawn near library entrance with view of bookshelves"
```

**Notes**:
- Used for documentation and debugging
- Not displayed to end users
- Helpful for coordinate refinement

---

### scaleFactor (Optional)

Scale multiplier for the player model.

**Type**: `number`

**Default**: `1.0`

**Valid Range**: 0.1 to 10.0 (automatically clamped)

**Example**:
```json
"scaleFactor": 1.0
```

**Common Values**:
- `1.0`: Normal size
- `0.5`: Half size
- `2.0`: Double size

**Notes**:
- Affects player collision size
- Typically left at 1.0 for consistency
- Can be used for special viewing modes

---

### environmentType (Optional)

Environment type identifier.

**Type**: `string`

**Default**: `"classroom"`

**Valid Values**: Any string (typically "classroom")

**Example**:
```json
"environmentType": "classroom"
```

**Notes**:
- Currently all locations use "classroom"
- Reserved for future multi-environment support
- Can be used for environment-specific logic

## Complete Example

### Single Location Configuration

```json
{
  "locationSpawnConfigs": {
    "Library": {
      "position": {
        "x": -8.5,
        "y": 1.6,
        "z": 12.0
      },
      "rotation": {
        "pitch": 0.0,
        "yaw": -0.785,
        "roll": 0.0
      },
      "locationName": "Library",
      "description": "Spawn near library entrance with view of bookshelves",
      "scaleFactor": 1.0,
      "environmentType": "classroom"
    }
  }
}
```

### Multiple Locations Configuration

```json
{
  "locationSpawnConfigs": {
    "Library": {
      "position": { "x": -8.5, "y": 1.6, "z": 12.0 },
      "rotation": { "pitch": 0.0, "yaw": -0.785, "roll": 0.0 },
      "locationName": "Library",
      "description": "Library entrance view",
      "scaleFactor": 1.0,
      "environmentType": "classroom"
    },
    "Auditorium": {
      "position": { "x": 0.0, "y": 1.6, "z": -15.0 },
      "rotation": { "pitch": 0.0, "yaw": 0.0, "roll": 0.0 },
      "locationName": "Auditorium",
      "description": "Back row facing stage",
      "scaleFactor": 1.0,
      "environmentType": "classroom"
    },
    "Cafeteria": {
      "position": { "x": 10.0, "y": 1.6, "z": 8.0 },
      "rotation": { "pitch": 0.0, "yaw": -1.571, "roll": 0.0 },
      "locationName": "Cafeteria",
      "description": "Dining area side view",
      "scaleFactor": 1.0,
      "environmentType": "classroom"
    }
  }
}
```

## Validation Rules

### Automatic Validation

The system automatically validates and corrects spawn configurations:

1. **Coordinate Clamping**: Out-of-bounds coordinates are clamped to valid ranges
2. **Angle Normalization**: Rotation angles are normalized to [-π, π]
3. **Scale Clamping**: Scale factors are clamped to [0.1, 10.0]
4. **Default Fallback**: Missing configurations use default values

### Validation Warnings

The system logs warnings when validation occurs:

```javascript
[SpawnManager] Spawn config had out-of-bounds values, clamped to safe ranges
[SpawnManager] Original: { position: { x: 100, y: -5, z: 0 }, ... }
[SpawnManager] Clamped: { position: { x: 50, y: 0.5, z: 0 }, ... }
```

## Error Handling

### Missing Configuration

If a location has no spawn configuration:
- System uses default configuration
- Warning logged to console
- Player spawns at default position (0, 1.6, 5)

### Malformed JSON

If JSON is malformed:
- Error logged to console
- System uses default configuration
- Application continues without crashing

### Invalid Values

If values are invalid (NaN, null, undefined):
- System substitutes default values
- Warning logged to console
- Validation ensures safe spawning

## Best Practices

### Configuration Design

1. **Start with Default**: Begin with default values and adjust incrementally
2. **Use Debug Mode**: Enable debug visualization to see spawn positions
3. **Test Thoroughly**: Test each spawn position in the 3D environment
4. **Document Clearly**: Add descriptive comments for each configuration
5. **Consistent Naming**: Use exact location card titles

### Coordinate Selection

1. **Eye Height**: Set Y to 1.6 for natural viewing
2. **Clear View**: Ensure spawn position has unobstructed view
3. **Safe Distance**: Keep away from walls and obstacles
4. **Logical Orientation**: Face toward points of interest

### Maintenance

1. **Version Control**: Track changes to spawn configurations
2. **Backup Configs**: Keep backup of working configurations
3. **Test After Changes**: Verify all locations after updates
4. **Document Changes**: Note reasons for coordinate adjustments

## Tools and Utilities

### Debug Mode

Enable spawn visualization:
```
?debugSpawn=true
```

Features:
- Visual spawn position markers
- Coordinate value overlays
- Camera orientation vectors
- Real-time coordinate adjustment

### Console Logging

Monitor spawn system:
```javascript
// Enable verbose logging
localStorage.setItem('spawnDebug', 'true');

// View spawn configuration
console.log(spawnManager.getSpawnConfig());

// Describe configuration
console.log(spawnManager.describeConfig(config));
```

### Coordinate Calculator

Convert degrees to radians:
```javascript
function degreesToRadians(degrees) {
  return degrees * (Math.PI / 180);
}

// Example: 45° = 0.785 radians
const yaw = degreesToRadians(45); // 0.785
```

## Schema Validation

### JSON Schema (Draft-07)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "locationSpawnConfigs": {
      "type": "object",
      "patternProperties": {
        "^.*$": {
          "type": "object",
          "required": ["position", "rotation", "locationName"],
          "properties": {
            "position": {
              "type": "object",
              "required": ["x", "y", "z"],
              "properties": {
                "x": { "type": "number", "minimum": -50, "maximum": 50 },
                "y": { "type": "number", "minimum": 0.5, "maximum": 10 },
                "z": { "type": "number", "minimum": -50, "maximum": 50 }
              }
            },
            "rotation": {
              "type": "object",
              "required": ["pitch", "yaw", "roll"],
              "properties": {
                "pitch": { "type": "number" },
                "yaw": { "type": "number" },
                "roll": { "type": "number" }
              }
            },
            "locationName": { "type": "string", "minLength": 1 },
            "description": { "type": "string" },
            "scaleFactor": { "type": "number", "minimum": 0.1, "maximum": 10 },
            "environmentType": { "type": "string" }
          }
        }
      }
    }
  }
}
```

## Support

For issues or questions about spawn configurations:
1. Check console logs for validation warnings
2. Enable debug mode to visualize spawn positions
3. Verify JSON syntax is valid
4. Ensure coordinate values are within valid ranges
5. Test with default configuration first
