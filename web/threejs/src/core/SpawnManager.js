// web/threejs/src/core/SpawnManager.js
// Manages spawn position and camera orientation for location-specific player spawning
// Receives spawn configurations from Flutter via postMessage or URL parameters

/**
 * SpawnManager handles loading and validating spawn configurations
 * for location-specific player positioning in the 3D environment.
 * 
 * Coordinate System (Three.js right-handed):
 * - X-axis: Positive = Right, Negative = Left
 * - Y-axis: Positive = Up, Negative = Down
 * - Z-axis: Positive = Forward (toward camera), Negative = Backward
 * 
 * Rotation (Euler angles in radians):
 * - Pitch: Rotation around X-axis (looking up/down)
 * - Yaw: Rotation around Y-axis (looking left/right)
 * - Roll: Rotation around Z-axis (tilting head)
 */
export class SpawnManager {
  constructor() {
    // Default spawn configuration (classroom entrance)
    this.defaultSpawnConfig = {
      position: { x: -23.5, y: 1.7, z: -14.7 },
      rotation: { pitch: 0, yaw: 0, roll: 0 },
      locationName: 'default',
      scaleFactor: 1.0,
      environmentType: 'classroom',
      description: 'Default classroom entrance'
    };
    
    // Current spawn configuration (set via postMessage or URL)
    this.currentSpawnConfig = null;
    
    // Setup message listener for spawn configs from Flutter
    this.setupMessageListener();
    
    console.log('[SpawnManager] Initialized with default config:', this.defaultSpawnConfig);
  }
  
  /**
   * Sets up window message listener to receive spawn configs from Flutter
   */
  setupMessageListener() {
    window.addEventListener('message', (event) => {
      try {
        // Parse message data
        let data = event.data;
        
        // Handle string messages (JSON encoded)
        if (typeof data === 'string') {
          try {
            data = JSON.parse(data);
          } catch (parseError) {
            // Not JSON, ignore
            return;
          }
        }
        
        // Check if this is a spawn config message
        if (data && data.type === 'SPAWN_CONFIG' && data.data) {
          this.currentSpawnConfig = data.data;
          console.log('[SpawnManager] ===== SPAWN CONFIG RECEIVED =====');
          console.log('[SpawnManager] Received spawn config via postMessage:', this.currentSpawnConfig);
          console.log('[SpawnManager] Location:', this.currentSpawnConfig.locationName);
          console.log('[SpawnManager] Position:', this.currentSpawnConfig.position);
          console.log('[SpawnManager] Rotation:', this.currentSpawnConfig.rotation);
          console.log('[SpawnManager] =====================================');
        }
      } catch (error) {
        console.error('[SpawnManager] Error processing message:', error);
      }
    });
  }
  
  /**
   * Parses spawn configuration from URL parameters
   * @returns {Object|null} Spawn config object or null if not found
   */
  parseUrlParams() {
    const params = new URLSearchParams(window.location.search);
    
    // Check if spawn parameters exist
    if (params.has('spawnX')) {
      const config = {
        position: {
          x: parseFloat(params.get('spawnX')) || 0,
          y: parseFloat(params.get('spawnY')) || 1.6,
          z: parseFloat(params.get('spawnZ')) || 5
        },
        rotation: {
          pitch: parseFloat(params.get('pitch')) || 0,
          yaw: parseFloat(params.get('yaw')) || 0,
          roll: parseFloat(params.get('roll')) || 0
        },
        locationName: params.get('location') || 'unknown',
        scaleFactor: parseFloat(params.get('scale')) || 1.0,
        environmentType: params.get('env') || 'classroom',
        description: params.get('desc') || ''
      };
      
      console.log('[SpawnManager] Parsed spawn config from URL:', config);
      return config;
    }
    
    return null;
  }
  
  /**
   * Gets the current spawn configuration with priority:
   * 1. postMessage config (from Flutter)
   * 2. URL parameters
   * 3. Default config
   * 
   * @returns {Object} Validated and clamped spawn configuration
   */
  getSpawnConfig() {
    let config;
    
    // Priority 1: postMessage from Flutter
    if (this.currentSpawnConfig) {
      console.log('[SpawnManager] Using spawn config from postMessage');
      config = this.currentSpawnConfig;
    }
    // Priority 2: URL parameters
    else {
      const urlConfig = this.parseUrlParams();
      if (urlConfig) {
        console.log('[SpawnManager] Using spawn config from URL parameters');
        config = urlConfig;
      }
      // Priority 3: Default
      else {
        console.warn('[SpawnManager] No spawn config found, using default');
        config = this.defaultSpawnConfig;
      }
    }
    
    // Validate and clamp coordinates to safe bounds
    return this.validateAndClamp(config);
  }
  
  /**
   * Validates and clamps spawn configuration to safe bounds
   * @param {Object} config - Spawn configuration to validate
   * @returns {Object} Validated and clamped configuration
   */
  validateAndClamp(config) {
    // Create a copy to avoid mutating original
    const validated = JSON.parse(JSON.stringify(config));
    
    // Clamp Y position to keep player above ground and below ceiling
    const minY = 0.5;
    const maxY = 10.0;
    validated.position.y = Math.max(minY, Math.min(maxY, validated.position.y));
    
    // Clamp X and Z to reasonable bounds
    const maxXZ = 50.0;
    validated.position.x = Math.max(-maxXZ, Math.min(maxXZ, validated.position.x));
    validated.position.z = Math.max(-maxXZ, Math.min(maxXZ, validated.position.z));
    
    // Normalize rotation angles to [-π, π]
    validated.rotation.pitch = this.normalizeAngle(validated.rotation.pitch);
    validated.rotation.yaw = this.normalizeAngle(validated.rotation.yaw);
    validated.rotation.roll = this.normalizeAngle(validated.rotation.roll);
    
    // Clamp scale factor
    validated.scaleFactor = Math.max(0.1, Math.min(10.0, validated.scaleFactor));
    
    // Log if clamping occurred
    if (JSON.stringify(config) !== JSON.stringify(validated)) {
      console.warn('[SpawnManager] Spawn config had out-of-bounds values, clamped to safe ranges');
      console.warn('[SpawnManager] Original:', config);
      console.warn('[SpawnManager] Clamped:', validated);
    }
    
    return validated;
  }
  
  /**
   * Normalizes angle to [-π, π] range
   * @param {number} angle - Angle in radians
   * @returns {number} Normalized angle
   */
  normalizeAngle(angle) {
    const PI = Math.PI;
    let normalized = angle;
    
    // Wrap angle to [-π, π]
    while (normalized > PI) {
      normalized -= 2 * PI;
    }
    while (normalized < -PI) {
      normalized += 2 * PI;
    }
    
    return normalized;
  }
  
  /**
   * Checks if a spawn configuration is valid
   * @param {Object} config - Configuration to check
   * @returns {boolean} True if valid
   */
  isValid(config) {
    if (!config || !config.position || !config.rotation) {
      return false;
    }
    
    // Check Y coordinate is above ground
    if (config.position.y < 0.5 || config.position.y > 10.0) {
      return false;
    }
    
    // Check X and Z are within bounds
    if (Math.abs(config.position.x) > 50.0 || Math.abs(config.position.z) > 50.0) {
      return false;
    }
    
    // Check scale factor is positive
    if (config.scaleFactor <= 0) {
      return false;
    }
    
    return true;
  }
  
  /**
   * Gets a human-readable description of the spawn configuration
   * @param {Object} config - Configuration to describe
   * @returns {string} Description string
   */
  describeConfig(config) {
    return `Location: ${config.locationName}, ` +
           `Position: (${config.position.x.toFixed(2)}, ${config.position.y.toFixed(2)}, ${config.position.z.toFixed(2)}), ` +
           `Rotation: (pitch: ${config.rotation.pitch.toFixed(2)}, yaw: ${config.rotation.yaw.toFixed(2)}, roll: ${config.rotation.roll.toFixed(2)}), ` +
           `Scale: ${config.scaleFactor}`;
  }
}
