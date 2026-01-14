/**
 * CameraController - Professional camera system for 3D games
 * Handles first-person, third-person, and free-cam modes with smooth transitions
 */

import * as THREE from 'three';

export class CameraController {
    constructor(camera, options = {}) {
        this.camera = camera;
        this.options = {
            mode: 'first-person', // 'first-person', 'third-person', 'free-cam'
            followSmoothing: 0.1,
            rotationSmoothing: 0.05,
            thirdPersonDistance: 3,
            thirdPersonHeight: 2,
            enableCollisionAvoidance: true,
            debugMode: false,
            ...options
        };
        
        // Camera state
        this.targetPosition = new THREE.Vector3();
        this.targetRotation = new THREE.Euler();
        this.currentOffset = new THREE.Vector3();
        
        // Third-person camera properties
        this.thirdPersonOffset = new THREE.Vector3(0, this.options.thirdPersonHeight, -this.options.thirdPersonDistance);
        this.idealCameraPosition = new THREE.Vector3();
        
        // Collision detection for camera
        this.raycaster = new THREE.Raycaster();
        this.collisionObjects = [];
        
        // Smooth interpolation
        this.velocity = new THREE.Vector3();
        this.angularVelocity = new THREE.Euler();
        
        console.log(`✅ CameraController initialized in ${this.options.mode} mode`);
    }

    /**
     * SPAWN SYSTEM: Set initial camera orientation from spawn configuration
     * @param {number} pitch - Pitch angle in radians (looking up/down)
     * @param {number} yaw - Yaw angle in radians (looking left/right)
     * @param {number} roll - Roll angle in radians (tilting head)
     */
    setInitialOrientation(pitch, yaw, roll) {
        // Apply rotation to camera
        this.camera.rotation.set(pitch, yaw, roll, 'YXZ');
        
        // Store as target rotation for smooth transitions
        this.targetRotation.set(pitch, yaw, roll, 'YXZ');
        
        console.log('[CameraController] Initial orientation set:', {
            pitch: pitch,
            yaw: yaw,
            roll: roll
        });
    }

    /**
     * Follow player character based on current camera mode
     * @param {Object} playerState - Player state object
     * @param {number} delta - Time delta
     */
    followPlayer(playerState, delta) {
        switch (this.options.mode) {
            case 'first-person':
                this.followFirstPerson(playerState, delta);
                break;
            case 'third-person':
                this.followThirdPerson(playerState, delta);
                break;
            case 'free-cam':
                // Free camera mode - no following
                break;
            default:
                this.followFirstPerson(playerState, delta);
        }
    }

    /**
     * First-person camera following
     * @param {Object} playerState - Player state object
     * @param {number} delta - Time delta
     */
    followFirstPerson(playerState, delta) {
        // Camera position matches player position with eye-level offset
        this.targetPosition.copy(playerState.position);
        this.targetPosition.y += 0.1; // Eye level adjustment
        
        // Smooth camera movement for natural feel
        if (this.options.followSmoothing > 0) {
            this.camera.position.lerp(this.targetPosition, this.options.followSmoothing);
        } else {
            this.camera.position.copy(this.targetPosition);
        }
        
        if (this.options.debugMode) {
            console.log('📷 First-person camera updated');
        }
    }

    /**
     * Third-person camera following with collision avoidance
     * @param {Object} playerState - Player state object
     * @param {number} delta - Time delta
     */
    followThirdPerson(playerState, delta) {
        // Calculate ideal camera position behind player
        this.calculateIdealCameraPosition(playerState);
        
        // Check for collisions and adjust position if needed
        if (this.options.enableCollisionAvoidance) {
            this.avoidCollisions(playerState);
        }
        
        // Smooth camera movement
        if (this.options.followSmoothing > 0) {
            this.camera.position.lerp(this.idealCameraPosition, this.options.followSmoothing);
        } else {
            this.camera.position.copy(this.idealCameraPosition);
        }
        
        // Always look at player
        this.camera.lookAt(playerState.position);
        
        if (this.options.debugMode) {
            console.log('📷 Third-person camera updated');
        }
    }

    /**
     * Calculate ideal camera position for third-person mode
     * @param {Object} playerState - Player state object
     */
    calculateIdealCameraPosition(playerState) {
        // Apply player rotation to camera offset
        const rotatedOffset = this.thirdPersonOffset.clone();
        rotatedOffset.applyEuler(playerState.rotation);
        
        // Set ideal position
        this.idealCameraPosition.copy(playerState.position).add(rotatedOffset);
    }

    /**
     * Avoid collisions by adjusting camera position
     * @param {Object} playerState - Player state object
     */
    avoidCollisions(playerState) {
        // Cast ray from player to ideal camera position
        const direction = this.idealCameraPosition.clone().sub(playerState.position).normalize();
        const distance = playerState.position.distanceTo(this.idealCameraPosition);
        
        this.raycaster.set(playerState.position, direction);
        const intersects = this.raycaster.intersectObjects(this.collisionObjects, true);
        
        if (intersects.length > 0 && intersects[0].distance < distance) {
            // Collision detected, move camera closer to player
            const safeDistance = Math.max(intersects[0].distance - 0.5, 0.5); // Minimum distance
            this.idealCameraPosition.copy(playerState.position).add(direction.multiplyScalar(safeDistance));
            
            if (this.options.debugMode) {
                console.log('📷 Camera collision avoided, distance:', safeDistance);
            }
        }
    }

    /**
     * Set camera mode
     * @param {string} mode - Camera mode ('first-person', 'third-person', 'free-cam')
     */
    setMode(mode) {
        const previousMode = this.options.mode;
        this.options.mode = mode;
        
        // Handle mode transition
        this.handleModeTransition(previousMode, mode);
        
        console.log(`📷 Camera mode changed from ${previousMode} to ${mode}`);
    }

    /**
     * Handle smooth transition between camera modes
     * @param {string} fromMode - Previous camera mode
     * @param {string} toMode - New camera mode
     */
    handleModeTransition(fromMode, toMode) {
        // Store current camera state for smooth transition
        const currentPosition = this.camera.position.clone();
        const currentRotation = this.camera.rotation.clone();
        
        // Mode-specific transition logic can be added here
        if (fromMode === 'first-person' && toMode === 'third-person') {
            // Smooth transition from first to third person
            console.log('📷 Transitioning from first-person to third-person');
        } else if (fromMode === 'third-person' && toMode === 'first-person') {
            // Smooth transition from third to first person
            console.log('📷 Transitioning from third-person to first-person');
        }
    }

    /**
     * Set follow smoothing factor
     * @param {number} smoothing - Smoothing factor (0-1, 0 = instant, 1 = very smooth)
     */
    setFollowSmoothing(smoothing) {
        this.options.followSmoothing = Math.max(0, Math.min(1, smoothing));
    }

    /**
     * Set third-person camera distance
     * @param {number} distance - Distance from player
     */
    setThirdPersonDistance(distance) {
        this.options.thirdPersonDistance = Math.max(0.5, distance);
        this.thirdPersonOffset.z = -this.options.thirdPersonDistance;
    }

    /**
     * Set third-person camera height
     * @param {number} height - Height above player
     */
    setThirdPersonHeight(height) {
        this.options.thirdPersonHeight = Math.max(0, height);
        this.thirdPersonOffset.y = this.options.thirdPersonHeight;
    }

    /**
     * Add collision object for camera collision avoidance
     * @param {THREE.Object3D} object - Object to avoid
     */
    addCollisionObject(object) {
        this.collisionObjects.push(object);
        
        if (this.options.debugMode) {
            console.log('📷 Added camera collision object:', object.name || 'unnamed');
        }
    }

    /**
     * Remove collision object
     * @param {THREE.Object3D} object - Object to remove
     */
    removeCollisionObject(object) {
        const index = this.collisionObjects.indexOf(object);
        if (index !== -1) {
            this.collisionObjects.splice(index, 1);
            
            if (this.options.debugMode) {
                console.log('📷 Removed camera collision object:', object.name || 'unnamed');
            }
        }
    }

    /**
     * Enable/disable collision avoidance
     * @param {boolean} enabled - Whether collision avoidance should be enabled
     */
    setCollisionAvoidanceEnabled(enabled) {
        this.options.enableCollisionAvoidance = enabled;
    }

    /**
     * Shake camera for impact effects
     * @param {number} intensity - Shake intensity
     * @param {number} duration - Shake duration in seconds
     */
    shake(intensity = 0.1, duration = 0.5) {
        // Simple camera shake implementation
        const originalPosition = this.camera.position.clone();
        const shakeStart = Date.now();
        
        const shakeUpdate = () => {
            const elapsed = (Date.now() - shakeStart) / 1000;
            
            if (elapsed < duration) {
                const progress = elapsed / duration;
                const currentIntensity = intensity * (1 - progress); // Fade out
                
                this.camera.position.x = originalPosition.x + (Math.random() - 0.5) * currentIntensity;
                this.camera.position.y = originalPosition.y + (Math.random() - 0.5) * currentIntensity;
                this.camera.position.z = originalPosition.z + (Math.random() - 0.5) * currentIntensity;
                
                requestAnimationFrame(shakeUpdate);
            } else {
                this.camera.position.copy(originalPosition);
            }
        };
        
        shakeUpdate();
        
        if (this.options.debugMode) {
            console.log(`📷 Camera shake: intensity=${intensity}, duration=${duration}s`);
        }
    }

    /**
     * Get current camera mode
     * @returns {string} Current camera mode
     */
    getMode() {
        return this.options.mode;
    }

    /**
     * Get camera statistics
     * @returns {Object} Camera statistics
     */
    getStatistics() {
        return {
            mode: this.options.mode,
            position: this.camera.position.clone(),
            rotation: this.camera.rotation.clone(),
            followSmoothing: this.options.followSmoothing,
            thirdPersonDistance: this.options.thirdPersonDistance,
            thirdPersonHeight: this.options.thirdPersonHeight,
            collisionObjects: this.collisionObjects.length,
            collisionAvoidanceEnabled: this.options.enableCollisionAvoidance
        };
    }

    /**
     * Reset camera to default state
     */
    reset() {
        this.camera.position.set(0, 1.6, 5);
        this.camera.rotation.set(0, 0, 0);
        this.targetPosition.set(0, 1.6, 5);
        this.targetRotation.set(0, 0, 0);
        
        console.log('📷 Camera reset to default state');
    }

    /**
     * Dispose of camera controller resources
     */
    dispose() {
        this.collisionObjects = [];
        this.raycaster = null;
        this.targetPosition = null;
        this.targetRotation = null;
        this.currentOffset = null;
        this.thirdPersonOffset = null;
        this.idealCameraPosition = null;
        this.velocity = null;
        this.angularVelocity = null;
        
        console.log('🗑️ CameraController disposed');
    }
}