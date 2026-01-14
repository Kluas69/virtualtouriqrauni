/**
 * CharacterSystem - Professional character representation and management
 * Handles player character mesh, animations, and visual representation
 * SPAWN SYSTEM: Integrated with SpawnManager for location-specific spawning
 */

import * as THREE from 'three';
import { SpawnManager } from './SpawnManager.js';

export class CharacterSystem {
    constructor(scene, options = {}, camera = null) {
        this.scene = scene;
        this.camera = camera; // SPAWN SYSTEM: Store camera reference for rotation application
        this.options = {
            characterType: 'capsule',
            visible: false, // Hidden by default for first-person
            debugMode: false,
            enableAnimations: false,
            autoSpawn: true, // AUTOMATIC SPAWNING ENABLED
            spawnDelay: 2000, // 2 second delay to ensure spawn config arrives via postMessage
            ...options
        };
        
        // SPAWN SYSTEM: Initialize spawn manager
        this.spawnManager = new SpawnManager();
        
        // Character properties
        this.characterMesh = null;
        this.boundingBox = new THREE.Box3();
        // SPAWN SYSTEM: Use default spawn config position instead of hardcoded value
        const defaultConfig = this.spawnManager.defaultSpawnConfig;
        this.position = new THREE.Vector3(
            defaultConfig.position.x,
            defaultConfig.position.y,
            defaultConfig.position.z
        );
        this.rotation = new THREE.Euler(0, 0, 0);
        this.spawned = false;
        
        // Animation system
        this.mixer = null;
        this.animations = {};
        this.currentAnimation = null;
        
        // Debug helpers
        this.debugHelpers = [];
        
        this.createCharacter();
        
        // AUTO-SPAWN: Automatically spawn character after delay
        if (this.options.autoSpawn) {
            this.scheduleAutoSpawn();
        }
        
        console.log('✅ CharacterSystem initialized with auto-spawn and SpawnManager enabled');
    }

    /**
     * Create character mesh based on type
     * @param {string} type - Character type ('capsule', 'box', 'sphere', 'custom')
     */
    createCharacter(type = this.options.characterType) {
        this.options.characterType = type;
        
        switch (type) {
            case 'capsule':
                this.createCapsuleCharacter();
                break;
            case 'box':
                this.createBoxCharacter();
                break;
            case 'sphere':
                this.createSphereCharacter();
                break;
            case 'custom':
                this.createCustomCharacter();
                break;
            default:
                this.createCapsuleCharacter();
        }
        
        this.setupCharacterMesh();
        
        if (this.options.debugMode) {
            this.createDebugHelpers();
        }
        
        console.log(`👤 Character created: ${type}`);
    }
    
    /**
     * Schedule automatic character spawning
     */
    scheduleAutoSpawn() {
        console.log(`⏰ Auto-spawn scheduled in ${this.options.spawnDelay}ms`);
        
        setTimeout(() => {
            this.spawnCharacter();
        }, this.options.spawnDelay);
    }
    
    /**
     * Spawn character automatically (no click required)
     * SPAWN SYSTEM: Uses SpawnManager to get location-specific spawn coordinates
     */
    spawnCharacter() {
        if (this.spawned) {
            console.log('👤 Character already spawned');
            return;
        }
        
        // SPAWN SYSTEM: Get spawn configuration from SpawnManager
        const spawnConfig = this.spawnManager.getSpawnConfig();
        console.log('[CharacterSystem] ===== SPAWN DEBUG =====');
        console.log('[CharacterSystem] Current position BEFORE spawn:', this.position.toArray());
        console.log('[CharacterSystem] Spawn config received:', this.spawnManager.describeConfig(spawnConfig));
        console.log('[CharacterSystem] Spawn config position:', spawnConfig.position);
        
        // Apply spawn position
        this.applySpawnPosition(spawnConfig);
        
        console.log('[CharacterSystem] Position AFTER applySpawnPosition:', this.position.toArray());
        
        // Apply spawn rotation (camera orientation)
        this.applySpawnRotation(spawnConfig);
        
        // Set character to spawn position
        this.updatePosition(this.position);
        this.updateRotation(this.rotation);
        
        // Mark as spawned
        this.spawned = true;
        
        // Enable debug helpers if needed
        if (this.options.debugMode && this.debugHelpers.length === 0) {
            this.createDebugHelpers();
        }
        
        console.log('[CharacterSystem] ===== SPAWN COMPLETE =====');
        console.log('[CharacterSystem] Final character position:', this.position.toArray());
        console.log('[CharacterSystem] Final character rotation:', {
            x: this.rotation.x,
            y: this.rotation.y,
            z: this.rotation.z
        });
        
        // Trigger spawn callback if available
        if (window.classroomViewer && window.classroomViewer.onCharacterSpawned) {
            window.classroomViewer.onCharacterSpawned(this.position, this.rotation);
        }
    }

    /**
     * SPAWN SYSTEM: Apply spawn position from configuration
     * @param {Object} spawnConfig - Spawn configuration with position data
     */
    applySpawnPosition(spawnConfig) {
        if (!spawnConfig || !spawnConfig.position) {
            console.warn('[CharacterSystem] Invalid spawn config, using default position');
            return;
        }
        
        // Set character position from spawn config
        this.position.set(
            spawnConfig.position.x,
            spawnConfig.position.y,
            spawnConfig.position.z
        );
        
        console.log('[CharacterSystem] Applied spawn position:', this.position.toArray());
    }

    /**
     * SPAWN SYSTEM: Apply spawn rotation (camera orientation) from configuration
     * @param {Object} spawnConfig - Spawn configuration with rotation data
     */
    applySpawnRotation(spawnConfig) {
        if (!spawnConfig || !spawnConfig.rotation) {
            console.warn('[CharacterSystem] Invalid spawn config, using default rotation');
            return;
        }
        
        // Set character rotation from spawn config
        this.rotation.set(
            spawnConfig.rotation.pitch,
            spawnConfig.rotation.yaw,
            spawnConfig.rotation.roll,
            'YXZ' // Yaw-Pitch-Roll order for correct rotation
        );
        
        // Apply rotation to camera if available
        if (this.camera) {
            this.camera.rotation.set(
                spawnConfig.rotation.pitch,
                spawnConfig.rotation.yaw,
                spawnConfig.rotation.roll,
                'YXZ'
            );
            console.log('[CharacterSystem] Applied spawn rotation to camera');
        }
        
        console.log('[CharacterSystem] Applied spawn rotation:', {
            pitch: spawnConfig.rotation.pitch,
            yaw: spawnConfig.rotation.yaw,
            roll: spawnConfig.rotation.roll
        });
    }

    /**
     * Create capsule character (default for FPS games)
     */
    createCapsuleCharacter() {
        // BEE-SIZED collision - microscopic for fitting through ANY gap imaginable
        const geometry = new THREE.CapsuleGeometry(0.001, 1.4, 4, 8); // 1mm radius (2mm diameter) - BEE-SIZED!
        const material = new THREE.MeshLambertMaterial({
            color: 0xFFD700, // Gold color like a bee
            transparent: true,
            opacity: this.options.debugMode ? 0.8 : 0.5
        });
        
        this.characterMesh = new THREE.Mesh(geometry, material);
        this.characterMesh.name = 'PlayerCharacter';
    }

    /**
     * Create box character (simple collision representation)
     */
    createBoxCharacter() {
        // BEE-SIZED box - microscopic for fitting through ANY gap
        const geometry = new THREE.BoxGeometry(0.002, 1.8, 0.002); // 2mm x 2mm - BEE-SIZED!
        const material = new THREE.MeshLambertMaterial({
            color: 0xFFD700, // Gold color like a bee
            transparent: true,
            opacity: this.options.debugMode ? 0.8 : 0.5
        });
        
        this.characterMesh = new THREE.Mesh(geometry, material);
        this.characterMesh.name = 'PlayerCharacter';
    }

    /**
     * Create sphere character (rolling ball games)
     */
    createSphereCharacter() {
        const geometry = new THREE.SphereGeometry(0.4, 16, 12);
        const material = new THREE.MeshLambertMaterial({
            color: 0xFF9800,
            transparent: true,
            opacity: this.options.debugMode ? 0.5 : 0.3
        });
        
        this.characterMesh = new THREE.Mesh(geometry, material);
        this.characterMesh.name = 'PlayerCharacter';
    }

    /**
     * Create custom character (for loading external models)
     */
    createCustomCharacter() {
        // Placeholder for custom character loading
        // This would typically load a GLTF model
        this.createCapsuleCharacter(); // Fallback to capsule
        console.log('🔧 Custom character not implemented, using capsule fallback');
    }

    /**
     * Setup character mesh properties
     */
    setupCharacterMesh() {
        if (!this.characterMesh) return;
        
        // Set initial position and rotation
        this.characterMesh.position.copy(this.position);
        this.characterMesh.rotation.copy(this.rotation);
        
        // Enable shadows
        this.characterMesh.castShadow = true;
        this.characterMesh.receiveShadow = true;
        
        // Set visibility
        this.characterMesh.visible = this.options.visible;
        
        // Update bounding box
        this.boundingBox.setFromObject(this.characterMesh);
        
        // Add to scene
        this.scene.add(this.characterMesh);
    }

    /**
     * Create debug helpers for visualization
     */
    createDebugHelpers() {
        // Bounding box helper
        const boxHelper = new THREE.Box3Helper(this.boundingBox, 0xFF0000);
        boxHelper.name = 'CharacterBoundingBox';
        this.scene.add(boxHelper);
        this.debugHelpers.push(boxHelper);
        
        // Position indicator
        const positionGeometry = new THREE.SphereGeometry(0.05, 8, 6);
        const positionMaterial = new THREE.MeshBasicMaterial({ color: 0xFF0000 });
        const positionIndicator = new THREE.Mesh(positionGeometry, positionMaterial);
        positionIndicator.name = 'CharacterPosition';
        this.scene.add(positionIndicator);
        this.debugHelpers.push(positionIndicator);
        
        // Direction indicator
        const directionGeometry = new THREE.ConeGeometry(0.1, 0.3, 8);
        const directionMaterial = new THREE.MeshBasicMaterial({ color: 0x00FF00 });
        const directionIndicator = new THREE.Mesh(directionGeometry, directionMaterial);
        directionIndicator.name = 'CharacterDirection';
        directionIndicator.rotation.x = -Math.PI / 2; // Point forward
        this.scene.add(directionIndicator);
        this.debugHelpers.push(directionIndicator);
        
        console.log('🔧 Debug helpers created');
    }

    /**
     * Update character position
     * @param {THREE.Vector3} newPosition - New position
     */
    updatePosition(newPosition) {
        this.position.copy(newPosition);
        
        if (this.characterMesh) {
            this.characterMesh.position.copy(newPosition);
            this.boundingBox.setFromObject(this.characterMesh);
        }
        
        // Update debug helpers
        if (this.options.debugMode && this.debugHelpers.length > 0) {
            // Update bounding box helper
            const boxHelper = this.debugHelpers.find(h => h.name === 'CharacterBoundingBox');
            if (boxHelper) {
                boxHelper.box.copy(this.boundingBox);
            }
            
            // Update position indicator
            const positionIndicator = this.debugHelpers.find(h => h.name === 'CharacterPosition');
            if (positionIndicator) {
                positionIndicator.position.copy(newPosition);
            }
            
            // Update direction indicator
            const directionIndicator = this.debugHelpers.find(h => h.name === 'CharacterDirection');
            if (directionIndicator) {
                directionIndicator.position.copy(newPosition);
                directionIndicator.position.y += 1.0; // Above character
            }
        }
    }

    /**
     * Update character rotation
     * @param {THREE.Euler} newRotation - New rotation
     */
    updateRotation(newRotation) {
        this.rotation.copy(newRotation);
        
        if (this.characterMesh) {
            this.characterMesh.rotation.copy(newRotation);
        }
        
        // Update direction indicator
        if (this.options.debugMode) {
            const directionIndicator = this.debugHelpers.find(h => h.name === 'CharacterDirection');
            if (directionIndicator) {
                directionIndicator.rotation.y = newRotation.y;
            }
        }
    }

    /**
     * Get character bounding box
     * @returns {THREE.Box3} Character bounding box
     */
    getBoundingBox() {
        if (this.characterMesh) {
            this.boundingBox.setFromObject(this.characterMesh);
        }
        return this.boundingBox;
    }

    /**
     * Set character visibility
     * @param {boolean} visible - Whether character should be visible
     */
    setVisible(visible) {
        this.options.visible = visible;
        
        if (this.characterMesh) {
            this.characterMesh.visible = visible;
        }
        
        console.log(`👤 Character visibility: ${visible ? 'visible' : 'hidden'}`);
    }

    /**
     * Set character size (for fitting through doors)
     * @param {number} width - Character width/radius
     * @param {number} height - Character height (optional)
     */
    setCharacterSize(width, height = null) {
        if (!this.characterMesh) return;
        
        const currentType = this.options.characterType;
        
        // Remove current character
        this.scene.remove(this.characterMesh);
        if (this.characterMesh.geometry) this.characterMesh.geometry.dispose();
        if (this.characterMesh.material) this.characterMesh.material.dispose();
        
        // Create new character with custom size
        if (currentType === 'capsule') {
            const geometry = new THREE.CapsuleGeometry(width / 2, height || 1.4, 4, 8);
            const material = new THREE.MeshLambertMaterial({
                color: 0x4CAF50,
                transparent: true,
                opacity: this.options.debugMode ? 0.5 : 0.3
            });
            this.characterMesh = new THREE.Mesh(geometry, material);
        } else if (currentType === 'box') {
            const geometry = new THREE.BoxGeometry(width, height || 1.8, width);
            const material = new THREE.MeshLambertMaterial({
                color: 0x2196F3,
                transparent: true,
                opacity: this.options.debugMode ? 0.5 : 0.3
            });
            this.characterMesh = new THREE.Mesh(geometry, material);
        }
        
        this.characterMesh.name = 'PlayerCharacter';
        this.setupCharacterMesh();
        
        console.log(`👤 Character resized to width: ${width}, height: ${height || 'default'}`);
    }

    /**
     * Set debug mode
     * @param {boolean} enabled - Whether debug mode should be enabled
     */
    setDebugMode(enabled) {
        this.options.debugMode = enabled;
        
        if (enabled && this.debugHelpers.length === 0) {
            this.createDebugHelpers();
        } else if (!enabled && this.debugHelpers.length > 0) {
            this.removeDebugHelpers();
        }
        
        // Update character opacity for debug visibility
        if (this.characterMesh && this.characterMesh.material) {
            this.characterMesh.material.opacity = enabled ? 0.5 : 0.3;
        }
    }

    /**
     * Remove debug helpers
     */
    removeDebugHelpers() {
        this.debugHelpers.forEach(helper => {
            this.scene.remove(helper);
            if (helper.geometry) helper.geometry.dispose();
            if (helper.material) helper.material.dispose();
        });
        this.debugHelpers = [];
        
        console.log('🔧 Debug helpers removed');
    }

    /**
     * Load custom character model
     * @param {string} modelPath - Path to character model
     * @returns {Promise} Promise that resolves when model is loaded
     */
    async loadCustomModel(modelPath) {
        // This would use ModelLoader to load a custom character
        console.log('🔧 Custom model loading not implemented yet:', modelPath);
        return Promise.resolve();
    }

    /**
     * Setup animation system
     * @param {THREE.AnimationClip[]} clips - Animation clips
     */
    setupAnimations(clips = []) {
        if (!this.options.enableAnimations || !this.characterMesh) return;
        
        this.mixer = new THREE.AnimationMixer(this.characterMesh);
        
        clips.forEach(clip => {
            const action = this.mixer.clipAction(clip);
            this.animations[clip.name] = action;
        });
        
        console.log(`🎬 Animation system setup with ${clips.length} clips`);
    }

    /**
     * Play animation
     * @param {string} animationName - Name of animation to play
     * @param {boolean} loop - Whether animation should loop
     */
    playAnimation(animationName, loop = true) {
        if (!this.mixer || !this.animations[animationName]) {
            console.warn(`Animation not found: ${animationName}`);
            return;
        }
        
        // Stop current animation
        if (this.currentAnimation) {
            this.currentAnimation.stop();
        }
        
        // Play new animation
        const action = this.animations[animationName];
        action.setLoop(loop ? THREE.LoopRepeat : THREE.LoopOnce);
        action.play();
        
        this.currentAnimation = action;
        
        console.log(`🎬 Playing animation: ${animationName}`);
    }

    /**
     * Update animation system
     * @param {number} delta - Time delta
     */
    updateAnimations(delta) {
        if (this.mixer) {
            this.mixer.update(delta);
        }
    }

    /**
     * Get character statistics
     * @returns {Object} Character statistics
     */
    getStatistics() {
        return {
            type: this.options.characterType,
            visible: this.options.visible,
            position: this.position.clone(),
            rotation: this.rotation.clone(),
            boundingBox: {
                min: this.boundingBox.min.clone(),
                max: this.boundingBox.max.clone(),
                size: this.boundingBox.getSize(new THREE.Vector3())
            },
            animations: Object.keys(this.animations),
            currentAnimation: this.currentAnimation?.getClip()?.name || null
        };
    }

    /**
     * Dispose of character system resources
     */
    dispose() {
        // Remove from scene
        if (this.characterMesh) {
            this.scene.remove(this.characterMesh);
            
            // Dispose geometry and material
            if (this.characterMesh.geometry) {
                this.characterMesh.geometry.dispose();
            }
            if (this.characterMesh.material) {
                if (Array.isArray(this.characterMesh.material)) {
                    this.characterMesh.material.forEach(mat => mat.dispose());
                } else {
                    this.characterMesh.material.dispose();
                }
            }
            
            this.characterMesh = null;
        }
        
        // Remove debug helpers
        this.removeDebugHelpers();
        
        // Dispose animation system
        if (this.mixer) {
            this.mixer.stopAllAction();
            this.mixer = null;
        }
        
        this.animations = {};
        this.currentAnimation = null;
        
        console.log('🗑️ CharacterSystem disposed');
    }
}