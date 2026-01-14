# Implementation Plan: Dynamic 3D Location Spawn System

## Overview

This implementation plan transforms the virtual tour application to support location-specific 3D spawn coordinates across all 10 campus locations. The approach follows a layered architecture: first establishing the data foundation with JSON configuration, then building the Dart models and services, followed by JavaScript engine integration, and finally comprehensive testing and validation.

The implementation prioritizes backward compatibility, performance, and maintainability while enabling rich, contextually-aware 3D experiences for each campus location.

## Tasks

- [ ] 1. Extend app_data.json with spawn configurations
  - Add "locationSpawnConfigs" section to assets/app_data.json
  - Define spawn coordinates for all 10 locations (Library, Play Area, Auditorium, Class Rooms, Amphitheater, Cafeteria, Common Room, Playground, Swimming Pool, Webinar Room)
  - Include position (x, y, z), rotation (pitch, yaw, roll), and metadata for each location
  - Add default fallback spawn configuration
  - Document coordinate system conventions in JSON comments
  - _Requirements: 1.1, 1.2, 2.1, 2.2, 2.3_

- [ ] 2. Create SpawnConfig data model in Dart
  - [ ] 2.1 Implement Vector3 class for 3D coordinates
    - Create lib/core/models/vector3.dart with x, y, z fields
    - Implement equality operator and hashCode
    - Add toString() for debugging
    - _Requirements: 1.1, 1.2_

  - [ ] 2.2 Implement SpawnConfig class
    - Create lib/core/models/spawn_config.dart
    - Add fields: position (Vector3), rotation (Vector3), locationName, description, scaleFactor, environmentType
    - Implement fromJson() factory constructor with null-safe parsing
    - Implement toJson() method for serialization
    - Implement toUrlParams() method for URL encoding
    - Add validation logic for coordinate bounds
    - _Requirements: 1.1, 1.2, 1.5, 2.2, 3.4_

  - [ ]* 2.3 Write property test for SpawnConfig serialization
    - **Property 3: Configuration Parsing Round-Trip**
    - **Validates: Requirements 2.4, 3.4**
    - Generate random SpawnConfig instances
    - Serialize to JSON and deserialize back
    - Verify all fields match original values within floating-point precision
    - Test with edge cases (zero values, negative coordinates, large angles)

  - [ ]* 2.4 Write unit tests for SpawnConfig
    - Test fromJson() with valid data
    - Test fromJson() with missing optional fields
    - Test toUrlParams() encoding format
    - Test coordinate validation and clamping
    - _Requirements: 1.4, 1.5, 2.4_

- [ ] 3. Extend AppConstants with spawn configuration management
  - [ ] 3.1 Add spawn configuration fields to AppConstants
    - Add static Map<String, SpawnConfig> locationSpawnConfigs field
    - Add static SpawnConfig defaultSpawnConfig field
    - Import spawn_config.dart model
    - _Requirements: 1.1, 1.3, 2.1_

  - [ ] 3.2 Implement spawn configuration loading in initialize()
    - Parse "locationSpawnConfigs" from app_data.json
    - Convert JSON entries to SpawnConfig objects
    - Store in locationSpawnConfigs map
    - Initialize defaultSpawnConfig with safe coordinates (0, 1.6, 5)
    - Add error handling for malformed configurations
    - Log loading success/failure with AppLogger
    - _Requirements: 1.3, 2.1, 2.4, 3.3, 9.1, 9.3, 10.1_

  - [ ] 3.3 Implement getSpawnConfigFor() method
    - Accept locationName parameter
    - Look up configuration in locationSpawnConfigs map
    - Return default configuration if location not found
    - Log warning when using fallback
    - _Requirements: 1.3, 3.1, 10.2_

  - [ ] 3.4 Implement hasSpawnConfig() helper method
    - Check if location exists in locationSpawnConfigs
    - Return boolean result
    - _Requirements: 3.1_

  - [ ]* 3.5 Write property test for spawn configuration loading
    - **Property 1: Spawn Configuration Completeness**
    - **Validates: Requirements 1.3, 10.2**
    - For all 10 location names, verify getSpawnConfigFor() returns valid config
    - Verify fallback to default for non-existent locations
    - Verify no null returns

  - [ ]* 3.6 Write unit tests for AppConstants spawn methods
    - Test getSpawnConfigFor() with existing locations
    - Test getSpawnConfigFor() with non-existent location
    - Test hasSpawnConfig() for all locations
    - Test default configuration validity
    - _Requirements: 1.3, 3.1, 10.2_

- [ ] 4. Update LocationDetailScreen to use spawn configurations
  - [ ] 4.1 Modify _openTour() method to retrieve spawn config
    - Call AppConstants.getSpawnConfigFor(widget.locationData.name)
    - Store result in local variable
    - Log spawn configuration details with AppLogger
    - _Requirements: 3.1, 3.2_

  - [ ] 4.2 Pass spawn configuration to WebGLRoomScreen
    - Add spawnConfig parameter to WebGLRoomScreen constructor call
    - Include spawn config in RouteSettings arguments
    - Update all WebGL navigation calls (desktop and mobile)
    - _Requirements: 3.2, 3.4_

  - [ ] 4.3 Update viewTypeFor() logic for all locations
    - Modify AppConstants.viewTypeFor() to return 'webgl' for all 10 locations
    - Remove hardcoded location name checks
    - Ensure backward compatibility with panorama fallback
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.10_

  - [ ]* 4.4 Write integration test for location detail screen navigation
    - Test tapping tour button for each location
    - Verify correct spawn config is retrieved
    - Verify navigation to WebGLRoomScreen with spawn data
    - _Requirements: 3.1, 3.2, 7.1-7.10_

- [ ] 5. Enhance WebGLRoomScreen to transmit spawn data
  - [ ] 5.1 Add spawnConfig parameter to WebGLRoomScreen
    - Update constructor to accept optional SpawnConfig parameter
    - Store in widget state
    - Update all constructor calls in codebase
    - _Requirements: 3.2_

  - [ ] 5.2 Implement spawn config transmission via postMessage
    - Create _sendSpawnConfigToWebGL() method
    - Serialize spawn config to JSON
    - Send via JavaScript interop or platform channel
    - Add error handling for transmission failures
    - Log transmission success/failure
    - _Requirements: 3.2, 3.4, 4.1_

  - [ ] 5.3 Implement spawn config transmission via URL parameters
    - Add URL parameter encoding as fallback method
    - Append spawn coordinates to iframe src URL
    - Use SpawnConfig.toUrlParams() method
    - _Requirements: 3.2, 3.4_

  - [ ] 5.4 Add spawn config transmission timing
    - Call _sendSpawnConfigToWebGL() after iframe loads
    - Add retry logic for failed transmissions
    - Ensure transmission before engine initialization
    - _Requirements: 4.5_

  - [ ]* 5.5 Write unit tests for WebGLRoomScreen spawn transmission
    - Test postMessage encoding
    - Test URL parameter encoding
    - Test handling of null spawn config
    - Test error handling for transmission failures
    - _Requirements: 3.2, 3.4, 10.4_

- [ ] 6. Create SpawnManager JavaScript module
  - [ ] 6.1 Implement SpawnManager class
    - Create web/threejs/src/core/SpawnManager.js
    - Add defaultSpawnConfig constant
    - Add currentSpawnConfig state variable
    - Implement constructor with initialization
    - _Requirements: 4.1, 10.2_

  - [ ] 6.2 Implement postMessage listener
    - Add window message event listener
    - Parse incoming SPAWN_CONFIG messages
    - Store received configuration in currentSpawnConfig
    - Log received configurations
    - _Requirements: 3.2, 4.1_

  - [ ] 6.3 Implement URL parameter parsing
    - Create parseUrlParams() method
    - Extract spawnX, spawnY, spawnZ, pitch, yaw, roll parameters
    - Parse numeric values with fallbacks
    - Return structured configuration object
    - _Requirements: 3.2, 4.1_

  - [ ] 6.4 Implement getSpawnConfig() method
    - Check currentSpawnConfig (postMessage) first
    - Fall back to parseUrlParams() if not set
    - Fall back to defaultSpawnConfig if neither available
    - Log which source was used
    - _Requirements: 1.3, 4.1, 10.2_

  - [ ] 6.5 Implement coordinate validation and clamping
    - Create validateAndClamp() method
    - Clamp Y coordinate to [0.5, 10.0] range
    - Clamp X and Z coordinates to [-50, 50] range
    - Normalize rotation angles to [-π, π]
    - Log clamping operations
    - _Requirements: 1.4, 4.4, 5.4_

  - [ ] 6.6 Implement angle normalization
    - Create normalizeAngle() helper method
    - Wrap angles to [-π, π] range
    - Handle edge cases (exactly π, -π)
    - _Requirements: 5.3, 5.4_

  - [ ]* 6.7 Write property test for coordinate clamping
    - **Property 2: Coordinate Bounds Safety**
    - **Validates: Requirements 1.4, 4.4**
    - Generate random coordinates (including out-of-bounds)
    - Apply validateAndClamp()
    - Verify Y is in [0.5, 10.0], X and Z in [-50, 50]

  - [ ]* 6.8 Write property test for angle normalization
    - **Property 5: Angle Normalization Idempotence**
    - **Validates: Requirements 4.4, 5.3**
    - Generate random angle values
    - Apply normalizeAngle() twice
    - Verify f(x) = f(f(x)) (idempotence)

  - [ ]* 6.9 Write unit tests for SpawnManager
    - Test postMessage reception
    - Test URL parameter parsing
    - Test fallback priority (postMessage > URL > default)
    - Test coordinate validation edge cases
    - _Requirements: 1.3, 3.2, 4.1, 4.4, 10.2_

- [ ] 7. Integrate SpawnManager with CharacterSystem
  - [ ] 7.1 Import SpawnManager in CharacterSystem
    - Add import statement for SpawnManager
    - Create SpawnManager instance in constructor
    - _Requirements: 4.1_

  - [ ] 7.2 Retrieve spawn configuration during initialization
    - Call spawnManager.getSpawnConfig() in initialize()
    - Store configuration in local variable
    - Log retrieved spawn configuration
    - _Requirements: 4.1, 4.5_

  - [ ] 7.3 Implement applySpawnPosition() method
    - Accept spawn configuration parameter
    - Set player entity position to config.position
    - Update camera position to follow player
    - Add eye height offset to camera Y position
    - Log applied position
    - _Requirements: 4.2, 4.5_

  - [ ] 7.4 Implement applySpawnRotation() method
    - Accept spawn configuration parameter
    - Set camera rotation to config.rotation (pitch, yaw, roll)
    - Use 'YXZ' Euler order for correct rotation application
    - Log applied rotation
    - _Requirements: 4.3, 6.1, 6.2, 6.3_

  - [ ] 7.5 Call spawn application methods during initialization
    - Call applySpawnPosition() after player creation
    - Call applySpawnRotation() after position application
    - Ensure spawn completes before first frame render
    - _Requirements: 4.2, 4.3, 4.5_

  - [ ]* 7.6 Write property test for spawn position application
    - **Property 6: WebGL Engine Spawn Application**
    - **Validates: Requirements 4.2, 4.5**
    - Generate random spawn configurations
    - Apply to CharacterSystem
    - Verify player position matches config within 0.01 units

  - [ ]* 7.7 Write property test for camera orientation application
    - **Property 7: Camera Orientation Application**
    - **Validates: Requirements 4.3, 6.1, 6.2**
    - Generate random rotation configurations
    - Apply to camera
    - Verify camera Euler angles match config within 0.01 radians

  - [ ]* 7.8 Write integration tests for CharacterSystem spawn
    - Test spawn with valid configuration
    - Test spawn with default configuration
    - Test spawn with out-of-bounds coordinates (should clamp)
    - Test spawn timing (before first render)
    - _Requirements: 4.2, 4.3, 4.4, 4.5_

- [ ] 8. Update CameraController for spawn orientation
  - [ ] 8.1 Add setInitialOrientation() method
    - Accept pitch, yaw, roll parameters
    - Apply rotation to camera
    - Disable user input during initial orientation
    - Re-enable user input after orientation set
    - _Requirements: 6.1, 6.2, 6.3, 6.6_

  - [ ] 8.2 Integrate with CharacterSystem spawn flow
    - Call setInitialOrientation() from CharacterSystem
    - Pass spawn rotation values
    - Ensure smooth transition to user control
    - _Requirements: 6.6_

  - [ ]* 8.3 Write unit tests for camera orientation
    - Test setInitialOrientation() with various angles
    - Test transition to user control
    - Test edge cases (extreme angles, zero rotation)
    - _Requirements: 6.1, 6.2, 6.3_

- [ ] 9. Add coordinate system documentation
  - [ ] 9.1 Document coordinate system in code comments
    - Add detailed comments to SpawnConfig class
    - Add comments to SpawnManager class
    - Add comments to CharacterSystem spawn methods
    - Include axis directions and rotation conventions
    - _Requirements: 5.2, 11.1_

  - [ ] 9.2 Create coordinate system README
    - Create docs/coordinate-system.md
    - Document Three.js right-handed coordinate system
    - Provide visual diagrams of axes
    - Document rotation angle conventions
    - Include example spawn configurations
    - _Requirements: 5.2, 11.2, 11.4_

  - [ ] 9.3 Add JSON schema documentation
    - Create docs/spawn-config-schema.md
    - Document all fields in locationSpawnConfigs
    - Provide field descriptions and valid ranges
    - Include complete example configurations
    - _Requirements: 8.1, 11.2_

- [ ] 10. Implement performance monitoring
  - [ ] 10.1 Add spawn loading performance metrics
    - Measure time to load spawn configurations in AppConstants
    - Log loading duration with AppLogger
    - Add performance warning if loading exceeds 100ms
    - _Requirements: 9.1, 9.4_

  - [ ] 10.2 Add spawn application performance metrics
    - Measure time to apply spawn position and rotation
    - Log application duration in CharacterSystem
    - Add performance warning if application exceeds 16ms
    - _Requirements: 9.4, 9.5_

  - [ ]* 10.3 Write property test for loading performance
    - **Property 10: Configuration Loading Performance**
    - **Validates: Requirements 9.1, 9.3**
    - Load all spawn configurations
    - Measure loading time
    - Verify completion within 100ms

  - [ ]* 10.4 Write performance benchmark tests
    - Benchmark spawn config parsing
    - Benchmark coordinate validation
    - Benchmark spawn application in engine
    - Compare against performance targets
    - _Requirements: 9.1, 9.2, 9.4, 9.5_

- [ ] 11. Add error handling and logging
  - [ ] 11.1 Implement comprehensive error logging in Dart
    - Add try-catch blocks in AppConstants.initialize()
    - Add try-catch blocks in getSpawnConfigFor()
    - Log errors with context and metadata
    - Use AppLogger.error() with component tags
    - _Requirements: 10.1, 10.3, 10.4_

  - [ ] 11.2 Implement comprehensive error logging in JavaScript
    - Add error logging in SpawnManager
    - Add error logging in CharacterSystem spawn methods
    - Use console.error() with structured data
    - Include error context and recovery actions
    - _Requirements: 10.1, 10.3, 10.4_

  - [ ] 11.3 Implement graceful fallbacks
    - Ensure default spawn config is always valid
    - Add coordinate clamping for out-of-bounds values
    - Add null checks for missing configurations
    - Test all fallback paths
    - _Requirements: 10.1, 10.2, 10.3_

  - [ ]* 11.4 Write unit tests for error handling
    - Test handling of malformed JSON
    - Test handling of missing spawn configs
    - Test handling of out-of-bounds coordinates
    - Test handling of WebGL communication failures
    - Verify graceful fallbacks in all cases
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

- [ ] 12. Create spawn position visualization tool
  - [ ] 12.1 Add debug mode for spawn visualization
    - Add URL parameter ?debugSpawn=true
    - Render spawn position markers in 3D scene
    - Display coordinate values as text overlays
    - Show camera orientation vectors
    - _Requirements: 5.4, 12.1_

  - [ ] 12.2 Add spawn position adjustment UI
    - Create on-screen controls for adjusting spawn position
    - Add buttons to increment/decrement X, Y, Z coordinates
    - Add buttons to adjust pitch, yaw, roll
    - Display current coordinates in real-time
    - Add "Copy to Clipboard" button for JSON export
    - _Requirements: 8.4, 12.1_

  - [ ]* 12.3 Write integration tests for debug tools
    - Test spawn marker rendering
    - Test coordinate adjustment controls
    - Test JSON export functionality
    - _Requirements: 12.1_

- [ ] 13. End-to-end testing and validation
  - [ ]* 13.1 Write E2E tests for all 10 locations
    - For each location (Library, Play Area, Auditorium, Class Rooms, Amphitheater, Cafeteria, Common Room, Playground, Swimming Pool, Webinar Room):
      - Navigate to location detail screen
      - Tap "Start Tour" button
      - Verify WebGL loads successfully
      - Verify player spawns at correct position
      - Verify camera orientation is correct
      - Verify player can move from spawn position
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.10_

  - [ ]* 13.2 Write E2E tests for error scenarios
    - Test tour with missing spawn configuration
    - Test tour with malformed spawn data
    - Test tour with out-of-bounds coordinates
    - Verify graceful fallbacks and error messages
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

  - [ ]* 13.3 Write validation tests for spawn configurations
    - Validate all 10 spawn configs in app_data.json
    - Verify Y coordinates are above ground
    - Verify coordinates are within model bounds
    - Verify rotation angles are reasonable
    - _Requirements: 1.4, 5.4, 12.2, 12.4_

- [ ] 14. Final integration and polish
  - [ ] 14.1 Update all location cards to use 3D tours
    - Verify all 10 locations show "Start Professional 3D Tour" button
    - Verify button text is contextually appropriate
    - Test mobile warning dialog for all locations
    - _Requirements: 7.1-7.10_

  - [ ] 14.2 Optimize spawn configuration data size
    - Review JSON file size
    - Remove unnecessary metadata fields
    - Compress coordinate precision if appropriate
    - Ensure loading performance remains under 100ms
    - _Requirements: 9.1, 9.3_

  - [ ] 14.3 Add user documentation
    - Update app documentation with spawn system overview
    - Add troubleshooting guide for spawn issues
    - Document how to customize spawn positions
    - _Requirements: 11.3, 11.4, 11.5_

  - [ ] 14.4 Final checkpoint - Comprehensive testing
    - Run all unit tests and verify passing
    - Run all property tests and verify passing
    - Run all integration tests and verify passing
    - Run all E2E tests and verify passing
    - Test on multiple devices (mobile, tablet, desktop)
    - Verify performance metrics meet targets
    - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- The implementation follows a bottom-up approach: data → models → services → integration → testing
- Spawn coordinates should be fine-tuned based on actual 3D model layout
- Debug visualization tools are essential for coordinate refinement
- Performance monitoring ensures the system meets responsiveness targets
