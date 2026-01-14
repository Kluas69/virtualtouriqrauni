/**
 * PlayerController - Professional Three.js Player Character System
 * Manages player character movement, physics, and camera integration
 */

import * as THREE from 'three';
import { CharacterSystem } from './CharacterSystem.js';
import { PhysicsEngine } from './PhysicsEngine.js';
import { CameraController } from './CameraController.js';
import { InputHandler } from './InputHandler.js';

export class PlayerState {
    constructor() {
        this.position = new THREE.Vector3(0, 1.6, 15);
        this.rotation = new THREE.Euler(0, 0, 0);
        this.velocity = new THREE.Vector3(0, 0, 0);
        this.isGrounded = false;
        this.isMoving = false;
        this.movementSpeed = 5.0;
        this.rotationSpeed = 2.0;
        this.jumpHeight = 5.0; // Increased for better jump feel
        this.health = 100;
        this.stamina = 100;
        
        // Jump control
        this.canJump = true;
        this.jumpCooldown = 0;
        this.jumpCooldownTime = 0.2; // 200ms cooldown between jumps
    }
}

export class PlayerController {
    constructor(scene, camera, options = {}) {
        this.scene = scene;
        this.camera = camera;
        this.options = {
            enablePhysics: true,
            enableCollisions: true,
            debugMode: false,
            ...options
        };
        
        // Initialize player state
        this.playerState = new PlayerState();
        
        // Initialize subsystems
        this.characterSystem = new CharacterSystem(scene, this.options);
        this.physicsEngine = new PhysicsEngine(this.options);
        this.cameraController = new CameraController(camera, this.options);
        this.inputHandler = new InputHandler(this.options);
        
        // Set character to BEE-SIZE by default for maximum navigation
        setTimeout(() => {
            this.setCharacterSize(0.001, 1.6); // 1mm radius (2mm diameter) - BEE-SIZED - fits through ANY gap!
        }, 100);
        
        // Bind methods
        this.update = this.update.bind(this);
        this.movePlayer = this.movePlayer.bind(this);
        this.updatePhysics = this.updatePhysics.bind(this);
        this.handleCollisions = this.handleCollisions.bind(this);
        
        console.log('✅ PlayerController initialized with BEE-SIZED character for maximum navigation');
        console.log('🐝 Character size: 2mm wide (bee-sized) - fits through ANY gap imaginable!');
    }

    /**
     * Main update loop - called every frame with professional jump handling
     * @param {number} delta - Time since last frame
     */
    update(delta) {
        // Get input from input handler
        const movement = this.inputHandler.getMovementVector();
        const isRunning = this.inputHandler.isRunning();
        const isJumping = this.inputHandler.isJumping();

        // Apply movement based on input
        this.movePlayer(movement, delta, isRunning);
        
        // Update jump cooldown
        if (this.playerState.jumpCooldown > 0) {
            this.playerState.jumpCooldown -= delta;
            if (this.playerState.jumpCooldown <= 0) {
                this.playerState.canJump = true;
            }
        }
        
        // Handle jumping with anti-spam protection
        if (isJumping && this.playerState.canJump && this.playerState.isGrounded) {
            const jumpSuccess = this.physicsEngine.jump(this.playerState);
            if (jumpSuccess) {
                // Set cooldown to prevent jump spamming
                this.playerState.canJump = false;
                this.playerState.jumpCooldown = this.playerState.jumpCooldownTime;
                
                if (this.options.debugMode) {
                    console.log('🦘 Jump executed successfully');
                }
            }
        }

        // Update physics simulation
        if (this.options.enablePhysics) {
            this.updatePhysics(delta);
        }

        // Handle collision detection
        if (this.options.enableCollisions) {
            this.handleCollisions();
        }

        // Update character visual representation
        this.characterSystem.updatePosition(this.playerState.position);
        this.characterSystem.updateRotation(this.playerState.rotation);

        // Update camera to follow player
        this.cameraController.followPlayer(this.playerState, delta);
        
        // Debug information
        if (this.options.debugMode) {
            this.updateDebugInfo();
        }
    }

    /**
     * Move player based on input
     * @param {THREE.Vector3} movement - Normalized movement vector
     * @param {number} delta - Time delta
     * @param {boolean} isRunning - Whether player is running
     */
    movePlayer(movement, delta, isRunning = false) {
        if (movement.length() === 0) {
            // Apply friction when not moving
            this.playerState.velocity.x *= 0.9;
            this.playerState.velocity.z *= 0.9;
            this.playerState.isMoving = false;
            return;
        }

        this.playerState.isMoving = true;
        const baseSpeed = this.playerState.movementSpeed;
        const speed = isRunning ? baseSpeed * 1.5 : baseSpeed;

        // Get camera direction for movement relative to view
        const cameraDirection = new THREE.Vector3();
        this.camera.getWorldDirection(cameraDirection);
        cameraDirection.y = 0; // Remove vertical component
        cameraDirection.normalize();

        // Calculate right vector for strafing
        const rightVector = new THREE.Vector3();
        rightVector.crossVectors(cameraDirection, new THREE.Vector3(0, 1, 0));

        // Apply movement relative to camera direction
        const moveVector = new THREE.Vector3();
        moveVector.addScaledVector(cameraDirection, -movement.z); // Forward/backward
        moveVector.addScaledVector(rightVector, movement.x); // Left/right

        // Apply to velocity with smooth acceleration
        const targetVelocityX = moveVector.x * speed;
        const targetVelocityZ = moveVector.z * speed;
        
        // Smooth velocity interpolation for better feel
        this.playerState.velocity.x = THREE.MathUtils.lerp(
            this.playerState.velocity.x, 
            targetVelocityX, 
            0.1
        );
        this.playerState.velocity.z = THREE.MathUtils.lerp(
            this.playerState.velocity.z, 
            targetVelocityZ, 
            0.1
        );
    }

    /**
     * Update physics simulation
     * @param {number} delta - Time delta
     */
    updatePhysics(delta) {
        // Apply gravity and ground detection
        this.physicsEngine.applyGravity(this.playerState, delta);

        // Update position based on velocity
        const deltaPosition = new THREE.Vector3()
            .copy(this.playerState.velocity)
            .multiplyScalar(delta);
        
        this.playerState.position.add(deltaPosition);
    }

    /**
     * Handle collision detection and response
     */
    handleCollisions() {
        const hadCollision = this.physicsEngine.checkCollisions(
            this.playerState, 
            this.characterSystem
        );
        
        if (hadCollision && this.options.debugMode) {
            console.log('🔴 Collision detected');
        }
    }

    /**
     * Add collision object to physics engine
     * @param {THREE.Object3D} object - Object to add for collision detection
     */
    addCollisionObject(object) {
        this.physicsEngine.addCollisionObject(object);
    }

    /**
     * Set player position
     * @param {THREE.Vector3} position - New position
     */
    setPosition(position) {
        this.playerState.position.copy(position);
        this.characterSystem.updatePosition(position);
        
        // Reset grounded state to allow physics to recalculate
        this.playerState.isGrounded = false;
        this.playerState.velocity.y = 0;
    }

    /**
     * Get player position
     * @returns {THREE.Vector3} Current player position
     */
    getPosition() {
        return this.playerState.position.clone();
    }

    /**
     * Set camera mode
     * @param {string} mode - Camera mode ('first-person', 'third-person', 'free-cam')
     */
    setCameraMode(mode) {
        this.cameraController.setMode(mode);
        
        // Show/hide character mesh based on camera mode
        this.characterSystem.setVisible(mode === 'third-person');
    }

    /**
     * Get current camera mode
     * @returns {string} Current camera mode
     */
    getCameraMode() {
        return this.cameraController.mode;
    }

    /**
     * Set ground level for physics
     * @param {number} level - Ground level Y coordinate
     */
    setGroundLevel(level) {
        this.physicsEngine.setGroundLevel(level);
    }

    /**
     * Get physics engine for advanced configuration
     * @returns {PhysicsEngine} Physics engine instance
     */
    getPhysicsEngine() {
        return this.physicsEngine;
    }

    /**
     * Set character size for fitting through doors
     * @param {number} width - Character width (0.2 for narrow doors, 0.3 for normal)
     * @param {number} height - Character height (optional)
     */
    setCharacterSize(width, height = null) {
        this.characterSystem.setCharacterSize(width, height);
        console.log(`🚪 Character resized for door navigation: ${width}m wide`);
    }

    /**
     * Get character system for advanced configuration
     * @returns {CharacterSystem} Character system instance
     */
    getCharacterSystem() {
        return this.characterSystem;
    }

    /**
     * Enable/disable debug mode
     * @param {boolean} enabled - Whether to enable debug mode
     */
    setDebugMode(enabled) {
        this.options.debugMode = enabled;
        this.characterSystem.setDebugMode(enabled);
    }

    /**
     * Update debug information with jump state
     * @private
     */
    updateDebugInfo() {
        // This could update debug UI elements
        const debugInfo = {
            position: this.playerState.position,
            velocity: this.playerState.velocity,
            isGrounded: this.playerState.isGrounded,
            isMoving: this.playerState.isMoving,
            canJump: this.playerState.canJump,
            jumpCooldown: this.playerState.jumpCooldown.toFixed(3),
            cameraMode: this.cameraController.mode
        };
        
        // Could emit debug event or update debug panel
        if (window.classroomViewer && window.classroomViewer.onDebugUpdate) {
            window.classroomViewer.onDebugUpdate(debugInfo);
        }
    }

    /**
     * Dispose of resources
     */
    dispose() {
        this.inputHandler.dispose();
        this.characterSystem.dispose();
        this.physicsEngine.dispose();
        this.cameraController.dispose();
        
        console.log('🗑️ PlayerController disposed');
    }
}