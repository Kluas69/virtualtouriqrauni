# Enhanced Flutter-Three.js Classroom Tour Integration Design

## Overview

This design document outlines the architecture for enhancing the existing professional Three.js WebGL game engine integration with Flutter's classroom detail screen tour system. The system builds upon the already-implemented professional game engine to provide a seamless, immersive classroom tour experience with advanced mobile gaming features and intelligent tour guidance.

## Architecture

### Enhanced System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Flutter Application Layer                    │
├─────────────────────────────────────────────────────────────────┤
│  Location Detail  │  Tour Controls  │  Mobile UI  │  Settings   │
├─────────────────────────────────────────────────────────────────┤
│                Enhanced Communication Bridge                     │
├─────────────────────────────────────────────────────────────────┤
│  Tour State Sync  │  Performance Data  │  Interactive Events   │
├─────────────────────────────────────────────────────────────────┤
│              Professional Three.js Game Engine                  │
├─────────────────────────────────────────────────────────────────┤
│  Tour Manager  │  Interactive System  │  Mobile Controls       │
├─────────────────────────────────────────────────────────────────┤
│  Rendering  │  Physics  │  Assets  │  Input  │  Performance    │
├─────────────────────────────────────────────────────────────────┤
│                      WebGL/Three.js Layer                      │
└─────────────────────────────────────────────────────────────────┘
```

### Tour-Specific System Architecture

The enhanced system adds tour-specific components to the existing professional game engine:

```
ClassroomTourSystem
├── TourManager
│   ├── TourStateController
│   ├── ProgressTracker
│   ├── WaypointSystem
│   └── GuidanceSystem
├── InteractiveSystem
│   ├── ObjectHighlighter
│   ├── InfoPanelManager
│   ├── ClickHandler
│   └── ContextualHelp
├── MobileGamingSystem
│   ├── VirtualJoysticks
│   ├── GyroscopeController
│   ├── HapticFeedback
│   └── GestureRecognition
└── FlutterBridge
    ├── TourCommunication
    ├── StateSync
    ├── PerformanceReporting
    └── ErrorHandling
```

## Components and Interfaces

### 1. Professional Game Engine Core

#### GameEngine Class
```javascript
class GameEngine {
    constructor(options) {
        this.renderingSystem = new RenderingSystem(options.rendering);
        this.physicsSystem = new PhysicsSystem(options.physics);
        this.assetSystem = new AssetSystem(options.assets);
        this.inputSystem = new InputSystem(options.input);
        this.performanceSystem = new PerformanceSystem(options.performance);
        
        this.gameLoop = new GameLoop();
        this.entityManager = new EntityManager();
        this.componentRegistry = new ComponentRegistry();
    }
    
    async initialize() {
        await this.initializeSystems();
        this.startGameLoop();
    }
    
    update(deltaTime, totalTime) {
        this.inputSystem.update(deltaTime);
        this.physicsSystem.update(deltaTime);
        this.performanceSystem.update(deltaTime);
        this.entityManager.update(deltaTime);
    }
    
    render(interpolation) {
        this.renderingSystem.render(interpolation);
    }
}
```

#### GameLoop Class
```javascript
class GameLoop {
    constructor(targetFPS = 60) {
        this.targetFPS = targetFPS;
        this.fixedTimeStep = 1000 / 120; // 120Hz physics
        this.maxFrameTime = 250; // Prevent spiral of death
        
        this.accumulator = 0;
        this.currentTime = performance.now();
        this.running = false;
    }
    
    start(updateCallback, renderCallback) {
        this.running = true;
        this.loop(updateCallback, renderCallback);
    }
    
    loop(updateCallback, renderCallback) {
        if (!this.running) return;
        
        const newTime = performance.now();
        let frameTime = newTime - this.currentTime;
        
        // Prevent spiral of death
        frameTime = Math.min(frameTime, this.maxFrameTime);
        
        this.currentTime = newTime;
        this.accumulator += frameTime;
        
        // Fixed timestep updates
        while (this.accumulator >= this.fixedTimeStep) {
            updateCallback(this.fixedTimeStep, this.currentTime);
            this.accumulator -= this.fixedTimeStep;
        }
        
        // Interpolated rendering
        const interpolation = this.accumulator / this.fixedTimeStep;
        renderCallback(interpolation);
        
        requestAnimationFrame(() => this.loop(updateCallback, renderCallback));
    }
}
```

### 2. Advanced Rendering System

#### PBRRenderer Class
```javascript
class PBRRenderer {
    constructor(renderer, scene, camera) {
        this.renderer = renderer;
        this.scene = scene;
        this.camera = camera;
        
        this.setupPBRMaterials();
        this.setupLighting();
        this.setupPostProcessing();
    }
    
    setupPBRMaterials() {
        // Configure PBR material defaults
        this.pbrDefaults = {
            metalness: 0.0,
            roughness: 0.5,
            envMapIntensity: 1.0,
            clearcoat: 0.0,
            clearcoatRoughness: 0.0
        };
    }
    
    setupLighting() {
        // Environment mapping for IBL
        this.envMap = null;
        this.irradianceMap = null;
        
        // Dynamic lights
        this.directionalLights = [];
        this.pointLights = [];
        this.spotLights = [];
    }
    
    setupPostProcessing() {
        this.composer = new EffectComposer(this.renderer);
        
        // Render pass
        this.renderPass = new RenderPass(this.scene, this.camera);
        this.composer.addPass(this.renderPass);
        
        // SSAO pass
        this.ssaoPass = new SSAOPass(this.scene, this.camera, 1024, 1024);
        this.composer.addPass(this.ssaoPass);
        
        // Bloom pass
        this.bloomPass = new UnrealBloomPass(
            new THREE.Vector2(1024, 1024), 1.5, 0.4, 0.85
        );
        this.composer.addPass(this.bloomPass);
        
        // Tone mapping pass
        this.toneMappingPass = new ShaderPass(ToneMappingShader);
        this.composer.addPass(this.toneMappingPass);
        
        // TAA pass
        this.taaPass = new TAAPass(this.scene, this.camera);
        this.composer.addPass(this.taaPass);
    }
    
    render(interpolation) {
        this.updateLighting();
        this.updatePostProcessing();
        this.composer.render();
    }
}
```

#### ShadowSystem Class
```javascript
class ShadowSystem {
    constructor(renderer) {
        this.renderer = renderer;
        this.shadowMapSize = 2048;
        this.cascadeLevels = 4;
        
        this.setupShadowMapping();
        this.setupCSM();
    }
    
    setupShadowMapping() {
        this.renderer.shadowMap.enabled = true;
        this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
        this.renderer.shadowMap.autoUpdate = false;
    }
    
    setupCSM() {
        // Cascade Shadow Mapping implementation
        this.csm = new CSM({
            maxFar: 100,
            cascades: this.cascadeLevels,
            shadowMapSize: this.shadowMapSize,
            lightDirection: new THREE.Vector3(-1, -1, -1).normalize(),
            camera: this.camera,
            parent: this.scene
        });
    }
    
    update(camera, lights) {
        this.csm.update(camera.matrix);
        this.updateShadowCasters(lights);
    }
}
```

### 3. High-Performance Physics System

#### PhysicsEngine Class (Enhanced)
```javascript
class PhysicsEngine {
    constructor(options = {}) {
        this.options = {
            gravity: -9.81,
            timeStep: 1/120, // 120Hz physics
            maxSubSteps: 10,
            broadphaseType: 'SAP', // Sweep and Prune
            debugMode: false,
            ...options
        };
        
        this.world = new CANNON.World();
        this.setupPhysicsWorld();
        this.setupSpatialPartitioning();
        
        this.bodies = new Map();
        this.constraints = new Map();
        this.contactMaterials = new Map();
    }
    
    setupPhysicsWorld() {
        this.world.gravity.set(0, this.options.gravity, 0);
        this.world.broadphase = new CANNON.SAPBroadphase(this.world);
        this.world.solver.iterations = 10;
        this.world.solver.tolerance = 0.001;
        
        // Contact materials for realistic friction
        this.setupContactMaterials();
    }
    
    setupSpatialPartitioning() {
        // Octree for efficient collision detection
        this.octree = new Octree({
            undeferred: false,
            depthMax: 8,
            objectsThreshold: 10,
            overlapPct: 0.15
        });
    }
    
    setupContactMaterials() {
        // Ground material
        this.groundMaterial = new CANNON.Material('ground');
        
        // Character material
        this.characterMaterial = new CANNON.Material('character');
        
        // Character-ground contact
        const characterGroundContact = new CANNON.ContactMaterial(
            this.characterMaterial,
            this.groundMaterial,
            {
                friction: 0.8,
                restitution: 0.0,
                contactEquationStiffness: 1e8,
                contactEquationRelaxation: 3
            }
        );
        
        this.world.addContactMaterial(characterGroundContact);
    }
    
    update(deltaTime) {
        // Update spatial partitioning
        this.updateSpatialPartitioning();
        
        // Step physics simulation
        this.world.step(this.options.timeStep, deltaTime, this.options.maxSubSteps);
        
        // Update Three.js objects
        this.syncThreeJSObjects();
        
        // Update debug visualization
        if (this.options.debugMode) {
            this.updateDebugVisualization();
        }
    }
}
```

#### CharacterController Class (Enhanced)
```javascript
class CharacterController {
    constructor(scene, physicsEngine, options = {}) {
        this.scene = scene;
        this.physics = physicsEngine;
        
        this.options = {
            radius: 0.001, // 2mm diameter (bee-sized)
            height: 1.6,
            mass: 70,
            maxSpeed: 5.0,
            acceleration: 20.0,
            jumpForce: 8.0,
            airControl: 0.3,
            groundFriction: 0.8,
            airFriction: 0.1,
            ...options
        };
        
        this.createCharacterBody();
        this.setupMovementState();
        this.setupGroundDetection();
    }
    
    createCharacterBody() {
        // Capsule shape for smooth movement
        const shape = new CANNON.Capsule(
            this.options.radius,
            this.options.height - 2 * this.options.radius
        );
        
        this.body = new CANNON.Body({
            mass: this.options.mass,
            shape: shape,
            material: this.physics.characterMaterial,
            fixedRotation: true, // Prevent character from tipping over
            linearDamping: 0.1,
            angularDamping: 0.1
        });
        
        this.physics.world.add(this.body);
        
        // Visual representation
        this.createVisualMesh();
    }
    
    setupMovementState() {
        this.movementState = {
            velocity: new THREE.Vector3(),
            acceleration: new THREE.Vector3(),
            isGrounded: false,
            groundNormal: new THREE.Vector3(0, 1, 0),
            inputVector: new THREE.Vector2(),
            isRunning: false,
            isCrouching: false,
            canJump: true
        };
    }
    
    setupGroundDetection() {
        this.groundRaycast = {
            from: new CANNON.Vec3(),
            to: new CANNON.Vec3(),
            result: new CANNON.RaycastResult(),
            maxDistance: this.options.radius + 0.1,
            rayCount: 5 // Multiple rays for better detection
        };
    }
    
    update(deltaTime, inputState) {
        this.updateGroundDetection();
        this.updateMovement(deltaTime, inputState);
        this.updateVisualMesh();
        
        if (this.options.debugMode) {
            this.updateDebugVisualization();
        }
    }
    
    updateGroundDetection() {
        const position = this.body.position;
        const rays = this.generateGroundRays(position);
        
        let bestHit = null;
        let minDistance = Infinity;
        
        for (const ray of rays) {
            this.physics.world.raycastClosest(
                ray.from, ray.to, {}, this.groundRaycast.result
            );
            
            if (this.groundRaycast.result.hasHit) {
                const distance = ray.from.distanceTo(this.groundRaycast.result.hitPointWorld);
                if (distance < minDistance) {
                    minDistance = distance;
                    bestHit = this.groundRaycast.result;
                }
            }
        }
        
        this.movementState.isGrounded = bestHit !== null && 
            minDistance <= this.groundRaycast.maxDistance;
        
        if (bestHit) {
            this.movementState.groundNormal.copy(bestHit.hitNormalWorld);
        }
    }
    
    generateGroundRays(position) {
        const rays = [];
        const rayLength = this.groundRaycast.maxDistance;
        
        // Center ray
        rays.push({
            from: new CANNON.Vec3(position.x, position.y, position.z),
            to: new CANNON.Vec3(position.x, position.y - rayLength, position.z)
        });
        
        // Corner rays for better detection
        const offset = this.options.radius * 0.8;
        const corners = [
            [offset, 0, offset],
            [-offset, 0, offset],
            [offset, 0, -offset],
            [-offset, 0, -offset]
        ];
        
        for (const [x, y, z] of corners) {
            rays.push({
                from: new CANNON.Vec3(position.x + x, position.y + y, position.z + z),
                to: new CANNON.Vec3(position.x + x, position.y + y - rayLength, position.z + z)
            });
        }
        
        return rays;
    }
}
```

### 4. Professional Asset Management System

#### AssetManager Class
```javascript
class AssetManager {
    constructor(options = {}) {
        this.options = {
            baseURL: './assets/',
            maxConcurrentLoads: 4,
            cacheSize: 100 * 1024 * 1024, // 100MB
            compressionEnabled: true,
            streamingEnabled: true,
            ...options
        };
        
        this.cache = new Map();
        this.loadQueue = new PriorityQueue();
        this.activeLoads = new Set();
        this.loadingPromises = new Map();
        
        this.setupLoaders();
        this.setupCompression();
        this.setupStreaming();
    }
    
    setupLoaders() {
        this.loaders = {
            gltf: new GLTFLoader(),
            texture: new THREE.TextureLoader(),
            audio: new THREE.AudioLoader(),
            json: new THREE.FileLoader()
        };
        
        // Setup Draco compression
        const dracoLoader = new DRACOLoader();
        dracoLoader.setDecoderPath('./libs/draco/');
        this.loaders.gltf.setDRACOLoader(dracoLoader);
        
        // Setup KTX2 texture compression
        const ktx2Loader = new KTX2Loader();
        ktx2Loader.setTranscoderPath('./libs/basis/');
        ktx2Loader.detectSupport(this.renderer);
        this.loaders.gltf.setKTX2Loader(ktx2Loader);
    }
    
    async loadAsset(url, type, priority = 0, options = {}) {
        // Check cache first
        const cacheKey = this.getCacheKey(url, options);
        if (this.cache.has(cacheKey)) {
            return this.cache.get(cacheKey);
        }
        
        // Check if already loading
        if (this.loadingPromises.has(cacheKey)) {
            return this.loadingPromises.get(cacheKey);
        }
        
        // Create loading promise
        const loadPromise = this.createLoadPromise(url, type, options);
        this.loadingPromises.set(cacheKey, loadPromise);
        
        try {
            const asset = await loadPromise;
            this.cache.set(cacheKey, asset);
            this.loadingPromises.delete(cacheKey);
            return asset;
        } catch (error) {
            this.loadingPromises.delete(cacheKey);
            throw error;
        }
    }
    
    async loadModel(url, options = {}) {
        const gltf = await this.loadAsset(url, 'gltf', options.priority, options);
        
        // Process model for optimization
        this.optimizeModel(gltf.scene, options);
        
        return gltf;
    }
    
    optimizeModel(scene, options = {}) {
        scene.traverse((child) => {
            if (child.isMesh) {
                // Setup LOD if enabled
                if (options.enableLOD) {
                    this.setupMeshLOD(child, options.lodLevels);
                }
                
                // Optimize materials
                this.optimizeMaterial(child.material);
                
                // Setup frustum culling
                child.frustumCulled = true;
                
                // Enable shadow casting/receiving
                child.castShadow = options.castShadow !== false;
                child.receiveShadow = options.receiveShadow !== false;
            }
        });
    }
}
```

### 5. Performance Optimization System

#### PerformanceMonitor Class
```javascript
class PerformanceMonitor {
    constructor(options = {}) {
        this.options = {
            targetFPS: 60,
            minFPS: 30,
            qualityLevels: ['low', 'medium', 'high', 'ultra'],
            adaptiveQuality: true,
            memoryThreshold: 150 * 1024 * 1024, // 150MB
            ...options
        };
        
        this.metrics = {
            fps: 0,
            frameTime: 0,
            memoryUsage: 0,
            drawCalls: 0,
            triangles: 0,
            geometries: 0,
            textures: 0
        };
        
        this.qualityLevel = 'high';
        this.frameHistory = [];
        this.lastQualityAdjustment = 0;
        
        this.setupMonitoring();
    }
    
    setupMonitoring() {
        // FPS monitoring
        this.fpsCounter = 0;
        this.fpsTimer = 0;
        
        // Memory monitoring
        if (performance.memory) {
            this.memoryMonitoring = true;
        }
        
        // WebGL stats monitoring
        this.setupWebGLMonitoring();
    }
    
    update(deltaTime, renderer) {
        this.updateFPS(deltaTime);
        this.updateMemoryUsage();
        this.updateWebGLStats(renderer);
        
        if (this.options.adaptiveQuality) {
            this.updateQualityLevel();
        }
        
        this.broadcastMetrics();
    }
    
    updateFPS(deltaTime) {
        this.fpsCounter++;
        this.fpsTimer += deltaTime;
        
        if (this.fpsTimer >= 1000) {
            this.metrics.fps = this.fpsCounter;
            this.metrics.frameTime = this.fpsTimer / this.fpsCounter;
            
            this.frameHistory.push(this.metrics.fps);
            if (this.frameHistory.length > 60) {
                this.frameHistory.shift();
            }
            
            this.fpsCounter = 0;
            this.fpsTimer = 0;
        }
    }
    
    updateQualityLevel() {
        const now = performance.now();
        if (now - this.lastQualityAdjustment < 2000) return; // Adjust max every 2 seconds
        
        const avgFPS = this.getAverageFPS();
        const currentLevel = this.qualityLevel;
        
        if (avgFPS < this.options.minFPS && this.canReduceQuality()) {
            this.reduceQuality();
            this.lastQualityAdjustment = now;
        } else if (avgFPS > this.options.targetFPS && this.canIncreaseQuality()) {
            this.increaseQuality();
            this.lastQualityAdjustment = now;
        }
    }
    
    getQualitySettings(level) {
        const settings = {
            low: {
                shadowMapSize: 512,
                antialias: false,
                postProcessing: false,
                ssao: false,
                bloom: false,
                renderScale: 0.75,
                maxLights: 4
            },
            medium: {
                shadowMapSize: 1024,
                antialias: true,
                postProcessing: true,
                ssao: false,
                bloom: true,
                renderScale: 0.85,
                maxLights: 8
            },
            high: {
                shadowMapSize: 2048,
                antialias: true,
                postProcessing: true,
                ssao: true,
                bloom: true,
                renderScale: 1.0,
                maxLights: 16
            },
            ultra: {
                shadowMapSize: 4096,
                antialias: true,
                postProcessing: true,
                ssao: true,
                bloom: true,
                renderScale: 1.0,
                maxLights: 32
            }
        };
        
        return settings[level] || settings.medium;
    }
}
```

## Data Models

### GameState Model
```javascript
class GameState {
    constructor() {
        this.player = {
            position: new THREE.Vector3(0, 0, 5),
            rotation: new THREE.Euler(0, 0, 0),
            velocity: new THREE.Vector3(),
            isGrounded: false,
            health: 100,
            stamina: 100
        };
        
        this.world = {
            time: 0,
            weather: 'clear',
            lighting: 'day',
            gravity: -9.81
        };
        
        this.rendering = {
            quality: 'high',
            effects: {
                shadows: true,
                postProcessing: true,
                ssao: true,
                bloom: true
            }
        };
        
        this.performance = {
            fps: 60,
            frameTime: 16.67,
            memoryUsage: 0,
            qualityLevel: 'high'
        };
    }
    
    serialize() {
        return JSON.stringify({
            player: {
                position: this.player.position.toArray(),
                rotation: this.player.rotation.toArray(),
                velocity: this.player.velocity.toArray(),
                isGrounded: this.player.isGrounded
            },
            world: this.world,
            rendering: this.rendering,
            performance: this.performance
        });
    }
    
    deserialize(data) {
        const state = JSON.parse(data);
        
        this.player.position.fromArray(state.player.position);
        this.player.rotation.fromArray(state.player.rotation);
        this.player.velocity.fromArray(state.player.velocity);
        this.player.isGrounded = state.player.isGrounded;
        
        Object.assign(this.world, state.world);
        Object.assign(this.rendering, state.rendering);
        Object.assign(this.performance, state.performance);
    }
}
```

### AssetDescriptor Model
```javascript
class AssetDescriptor {
    constructor(options) {
        this.id = options.id;
        this.url = options.url;
        this.type = options.type; // 'model', 'texture', 'audio', 'shader'
        this.format = options.format; // 'glb', 'gltf', 'jpg', 'png', etc.
        this.size = options.size; // File size in bytes
        this.priority = options.priority || 0;
        this.dependencies = options.dependencies || [];
        this.metadata = options.metadata || {};
        
        // LOD information
        this.lodLevels = options.lodLevels || [];
        
        // Compression settings
        this.compression = {
            enabled: options.compression?.enabled || false,
            format: options.compression?.format || 'draco',
            quality: options.compression?.quality || 0.8
        };
        
        // Streaming settings
        this.streaming = {
            enabled: options.streaming?.enabled || false,
            chunkSize: options.streaming?.chunkSize || 1024 * 1024, // 1MB chunks
            preload: options.streaming?.preload || false
        };
    }
    
    getOptimalLOD(distance, quality) {
        if (!this.lodLevels.length) return null;
        
        const qualityMultiplier = {
            low: 0.5,
            medium: 0.75,
            high: 1.0,
            ultra: 1.25
        }[quality] || 1.0;
        
        const adjustedDistance = distance / qualityMultiplier;
        
        for (const lod of this.lodLevels) {
            if (adjustedDistance <= lod.maxDistance) {
                return lod;
            }
        }
        
        return this.lodLevels[this.lodLevels.length - 1];
    }
}
```

## Error Handling

### Professional Error Recovery System

```javascript
class ErrorHandler {
    constructor(gameEngine) {
        this.gameEngine = gameEngine;
        this.errorQueue = [];
        this.recoveryStrategies = new Map();
        this.setupErrorHandling();
        this.setupRecoveryStrategies();
    }
    
    setupErrorHandling() {
        // Global error handlers
        window.addEventListener('error', (event) => {
            this.handleError('javascript', event.error, event);
        });
        
        window.addEventListener('unhandledrejection', (event) => {
            this.handleError('promise', event.reason, event);
        });
        
        // WebGL context loss handling
        this.gameEngine.renderer.domElement.addEventListener('webglcontextlost', (event) => {
            event.preventDefault();
            this.handleError('webgl_context_lost', new Error('WebGL context lost'), event);
        });
        
        this.gameEngine.renderer.domElement.addEventListener('webglcontextrestored', (event) => {
            this.handleError('webgl_context_restored', null, event);
        });
    }
    
    setupRecoveryStrategies() {
        this.recoveryStrategies.set('webgl_context_lost', async () => {
            console.log('🔄 Recovering from WebGL context loss...');
            
            // Pause game loop
            this.gameEngine.pause();
            
            // Show recovery UI
            this.showRecoveryUI('Recovering graphics context...');
            
            // Wait for context restoration
            await this.waitForContextRestoration();
            
            // Reload all GPU resources
            await this.reloadGPUResources();
            
            // Resume game loop
            this.gameEngine.resume();
            
            // Hide recovery UI
            this.hideRecoveryUI();
            
            console.log('✅ WebGL context recovery complete');
        });
        
        this.recoveryStrategies.set('asset_load_failure', async (error, context) => {
            console.log('🔄 Recovering from asset load failure...');
            
            const asset = context.asset;
            const retryCount = context.retryCount || 0;
            
            if (retryCount < 3) {
                // Retry with exponential backoff
                const delay = Math.pow(2, retryCount) * 1000;
                await this.delay(delay);
                
                try {
                    await this.gameEngine.assetManager.loadAsset(
                        asset.url, 
                        asset.type, 
                        { ...asset.options, retryCount: retryCount + 1 }
                    );
                } catch (retryError) {
                    this.handleError('asset_load_failure', retryError, {
                        asset,
                        retryCount: retryCount + 1
                    });
                }
            } else {
                // Load fallback asset
                await this.loadFallbackAsset(asset);
            }
        });
        
        this.recoveryStrategies.set('performance_degradation', async () => {
            console.log('🔄 Recovering from performance degradation...');
            
            // Reduce quality level
            this.gameEngine.performanceMonitor.reduceQuality();
            
            // Clear unnecessary caches
            this.gameEngine.assetManager.clearCache(0.5);
            
            // Force garbage collection if available
            if (window.gc) {
                window.gc();
            }
            
            // Restart performance monitoring
            this.gameEngine.performanceMonitor.reset();
        });
    }
    
    async handleError(type, error, context = {}) {
        const errorInfo = {
            type,
            error,
            context,
            timestamp: Date.now(),
            stack: error?.stack,
            userAgent: navigator.userAgent,
            gameState: this.gameEngine.getState()
        };
        
        this.errorQueue.push(errorInfo);
        
        // Log error
        console.error(`🚨 Game Error [${type}]:`, error);
        
        // Attempt recovery
        const recoveryStrategy = this.recoveryStrategies.get(type);
        if (recoveryStrategy) {
            try {
                await recoveryStrategy(error, context);
            } catch (recoveryError) {
                console.error('❌ Recovery failed:', recoveryError);
                this.handleCriticalError(errorInfo, recoveryError);
            }
        } else {
            console.warn('⚠️ No recovery strategy for error type:', type);
        }
        
        // Report error to analytics
        this.reportError(errorInfo);
    }
}
```

## Testing Strategy

### Comprehensive Testing Framework

The testing strategy will implement both unit tests and property-based tests to ensure professional game quality:

#### Unit Testing Approach
- **Component Tests**: Test individual game systems (rendering, physics, input)
- **Integration Tests**: Test system interactions and data flow
- **Performance Tests**: Validate FPS targets and memory usage
- **Compatibility Tests**: Ensure cross-browser and cross-device functionality

#### Property-Based Testing Framework
- **Minimum 100 iterations per property test** for comprehensive coverage
- **Each test tagged with feature and property reference** for traceability
- **Randomized input generation** for robust validation

### Test Configuration
```javascript
// Property test configuration
const PBT_CONFIG = {
    iterations: 100,
    timeout: 30000,
    shrinkLimit: 1000,
    verbose: true
};

// Test tagging format
const TEST_TAG = "Feature: flutter-threejs-game-integration, Property {number}: {description}";
```

The testing framework will validate that the professional game implementation meets all performance targets, maintains visual quality, and provides robust error recovery across all supported platforms and devices.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Fixed Timestep Physics Consistency
*For any* game loop execution, the physics simulation should maintain consistent timestep regardless of frame rate variations, ensuring deterministic physics behavior across all devices.
**Validates: Requirements 1.1**

### Property 2: Component-Entity System Integrity
*For any* game object creation or modification, the entity-component system should maintain referential integrity and allow proper component composition without memory leaks.
**Validates: Requirements 1.2**

### Property 3: Asset Streaming and LOD Correctness
*For any* asset loading scenario, the system should load appropriate LOD levels based on distance and performance requirements, ensuring optimal memory usage and visual quality.
**Validates: Requirements 1.3**

### Property 4: Rendering Pipeline Order Consistency
*For any* frame rendering, the modular rendering pipeline should execute passes in the correct order and produce consistent visual output across all quality levels.
**Validates: Requirements 1.4**

### Property 5: Memory Management Pool Efficiency
*For any* object allocation and deallocation, the object pooling system should reuse objects correctly and maintain memory usage within specified bounds.
**Validates: Requirements 1.5**

### Property 6: PBR Material Consistency
*For any* material with PBR parameters, the rendering system should apply metallic-roughness workflow correctly and produce physically accurate lighting results.
**Validates: Requirements 2.1**

### Property 7: Global Illumination Accuracy
*For any* scene with light probes, the global illumination system should correctly interpolate lighting data and affect object appearance realistically.
**Validates: Requirements 2.2**

### Property 8: SSAO Effect Correctness
*For any* rendered frame with SSAO enabled, the screen-space ambient occlusion should darken appropriate areas and enhance depth perception without artifacts.
**Validates: Requirements 2.3**

### Property 9: Post-Processing Pipeline Integrity
*For any* post-processing configuration, effects should be applied in the correct order and produce expected visual enhancements without breaking the rendering pipeline.
**Validates: Requirements 2.4**

### Property 10: Continuous Collision Detection
*For any* character movement at high speed, the capsule-based collision system should prevent tunneling through objects and maintain accurate collision response.
**Validates: Requirements 3.1**

### Property 11: Physics Simulation Accuracy
*For any* physics interaction, the engine should simulate gravity, friction, and bounce effects according to realistic physics laws with consistent behavior.
**Validates: Requirements 3.2**

### Property 12: Movement Interpolation Smoothness
*For any* character movement input, the system should provide smooth visual motion through interpolation and prediction, eliminating visual stuttering.
**Validates: Requirements 3.3**

### Property 13: Ground Detection Precision
*For any* surface geometry, the ground detection system should accurately identify walkable surfaces and handle slopes correctly for the bee-sized character.
**Validates: Requirements 3.4**

### Property 14: Asset Loading Priority Correctness
*For any* asset loading queue, high-priority assets should load before low-priority ones, and loading should progress efficiently without blocking the main thread.
**Validates: Requirements 4.1**

### Property 15: Texture Optimization Effectiveness
*For any* texture asset, the system should automatically select the optimal compression format and quality based on device capabilities and performance requirements.
**Validates: Requirements 4.2**

### Property 16: LOD Mesh Simplification Accuracy
*For any* 3D model, the LOD system should generate appropriate mesh simplifications that maintain visual quality while reducing polygon count based on viewing distance.
**Validates: Requirements 4.3**

### Property 17: Input Buffering and Prediction Reliability
*For any* user input sequence, the input system should buffer commands correctly and apply prediction to reduce perceived latency without causing input loss.
**Validates: Requirements 5.1**

### Property 18: Key Binding Configuration Persistence
*For any* key binding modification, the system should save and apply custom control schemes correctly across game sessions without conflicts.
**Validates: Requirements 5.2**

### Property 19: Automatic Quality Scaling Responsiveness
*For any* performance degradation below target FPS, the system should automatically reduce quality settings and restore performance within acceptable bounds.
**Validates: Requirements 6.1**

### Property 20: Occlusion Culling Optimization
*For any* scene with occluded objects, the GPU-based culling system should correctly identify and skip rendering of hidden objects, improving performance.
**Validates: Requirements 6.2**

### Property 21: Dynamic Lighting Accuracy
*For any* combination of light types in a scene, the lighting system should correctly illuminate objects with proper shadows, attenuation, and color mixing.
**Validates: Requirements 7.1**

### Property 22: Reflection Probe Correctness
*For any* reflective surface, the real-time reflection probes should update correctly with parallax correction, providing accurate environmental reflections.
**Validates: Requirements 7.2**

### Property 23: Flutter-WebGL Communication Integrity
*For any* message passed between Flutter and WebGL layers, the communication system should deliver data without loss or corruption, maintaining synchronization.
**Validates: Requirements 8.1**

### Property 24: 3D UI Positioning Accuracy
*For any* UI overlay element, the 3D positioning system should correctly place elements in world space and maintain readability regardless of camera movement.
**Validates: Requirements 8.2**

### Property 25: Performance Profiler Accuracy
*For any* performance metric collection, the profiler should provide accurate real-time measurements of FPS, memory usage, and rendering statistics.
**Validates: Requirements 9.1**

### Property 26: Physics Debug Visualization Correctness
*For any* physics object with debug visualization enabled, the visual representation should accurately match the actual collision boundaries and physics state.
**Validates: Requirements 9.2**

## Testing Strategy

### Dual Testing Approach
The professional game implementation will use both unit tests and property-based tests for comprehensive validation:

- **Unit tests**: Verify specific examples, edge cases, and integration points between game systems
- **Property tests**: Verify universal properties across all inputs using randomized testing with 100+ iterations

### Property-Based Test Configuration
- **Framework**: Fast-check for JavaScript property-based testing
- **Iterations**: Minimum 100 iterations per property test for thorough coverage
- **Test Tags**: Each test tagged with `**Feature: flutter-threejs-game-integration, Property {number}: {property_text}**`
- **Timeout**: 30 seconds per property test to handle complex 3D operations
- **Shrinking**: Automatic test case reduction to find minimal failing examples

### Unit Test Coverage
- **Game Engine Core**: Test game loop timing, entity management, component systems
- **Rendering System**: Test WebGL state management, shader compilation, render pass execution
- **Physics System**: Test collision detection, character movement, ground detection accuracy
- **Asset System**: Test loading queues, compression, LOD generation, caching behavior
- **Performance System**: Test quality scaling, memory management, FPS monitoring
- **Integration**: Test Flutter-WebGL communication, error recovery, state synchronization

### Performance Testing
- **Frame Rate Validation**: Ensure 60+ FPS on desktop, 30+ FPS on mobile under various loads
- **Memory Usage Testing**: Validate memory stays within bounds (200MB mobile, 500MB desktop)
- **Loading Time Testing**: Verify asset loading meets performance targets (< 3 seconds initial load)
- **Quality Scaling Testing**: Test automatic quality adjustment maintains target performance
- **Stress Testing**: Validate system stability under extreme conditions (many objects, effects, etc.)

### Cross-Platform Testing
- **Browser Compatibility**: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- **Device Testing**: Desktop, tablet, mobile with various GPU capabilities
- **WebGL Version Testing**: WebGL 2.0 preferred path and WebGL 1.0 fallback path
- **Performance Scaling**: Validate quality levels work correctly on different hardware tiers

The comprehensive testing strategy ensures the professional Three.js WebGL game implementation meets all quality, performance, and reliability requirements across all supported platforms and devices.