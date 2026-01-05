/**
 * PhysicsEngine - Professional physics simulation for 3D games
 * Handles gravity, collision detection, and realistic movement physics
 */

import * as THREE from 'three';

export class PhysicsEngine {
    constructor(options = {}) {
        this.options = {
            gravity: -9.81,
            groundLevel: 0.0, // Changed to 0.0 for better floor detection
            enableCollisions: true,
            enableGravity: true,
            debugMode: false,
            maxGroundDistance: 2.0, // Maximum distance to check for ground
            ...options
        };
        
        // Physics state
        this.collisionObjects = [];
        this.raycaster = new THREE.Raycaster();
        this.tempVector = new THREE.Vector3();
        this.tempBox = new THREE.Box3();
        
        // Ground detection
        this.groundRays = [
            new THREE.Vector3(0, -1, 0),   // Center
            new THREE.Vector3(0.3, -1, 0), // Right
            new THREE.Vector3(-0.3, -1, 0), // Left
            new THREE.Vector3(0, -1, 0.3), // Forward
            new THREE.Vector3(0, -1, -0.3) // Backward
        ];
        
        console.log('✅ PhysicsEngine initialized with realistic game physics');
    }

    /**
     * Add collision object to physics world
     * @param {THREE.Object3D} object - Object to add for collision detection
     */
    addCollisionObject(object) {
        if (object.isMesh) {
            this.collisionObjects.push(object);
            
            if (this.options.debugMode) {
                console.log('🔧 Added collision object:', object.name || 'unnamed');
            }
        }
    }

    /**
     * Remove collision object from physics world
     * @param {THREE.Object3D} object - Object to remove
     */
    removeCollisionObject(object) {
        const index = this.collisionObjects.indexOf(object);
        if (index !== -1) {
            this.collisionObjects.splice(index, 1);
            
            if (this.options.debugMode) {
                console.log('🔧 Removed collision object:', object.name || 'unnamed');
            }
        }
    }

    /**
     * Apply gravity to player state
     * @param {Object} playerState - Player state object
     * @param {number} delta - Time delta
     */
    applyGravity(playerState, delta) {
        if (!this.options.enableGravity) return;
        
        // Check ground collision first with improved detection
        const isGrounded = this.checkGroundCollision(playerState);
        
        if (isGrounded) {
            // Player is on ground - stop falling
            if (playerState.velocity.y < 0) {
                playerState.velocity.y = 0;
            }
            playerState.isGrounded = true;
            
            if (this.options.debugMode) {
                console.log(`🐝 Bee grounded at Y: ${playerState.position.y.toFixed(4)}m`);
            }
        } else {
            // Player is in air - apply gravity
            playerState.velocity.y += this.options.gravity * delta;
            playerState.isGrounded = false;
            
            if (this.options.debugMode) {
                console.log(`🐝 Bee falling: Y=${playerState.position.y.toFixed(4)}m, Vy=${playerState.velocity.y.toFixed(3)}`);
            }
        }
        
        // Prevent falling through world (safety net)
        if (playerState.position.y < this.options.groundLevel) {
            playerState.position.y = this.options.groundLevel + 0.001; // 1mm above ground level
            playerState.velocity.y = 0;
            playerState.isGrounded = true;
            
            if (this.options.debugMode) {
                console.log(`🐝 Bee safety net activated at Y: ${playerState.position.y.toFixed(4)}m`);
            }
        }
    }

    /**
     * Check ground collision using multiple raycasts
     * @param {Object} playerState - Player state object
     * @returns {boolean} Whether player is grounded
     */
    checkGroundCollision(playerState) {
        const rayDistance = 10.0; // Increased distance for better detection
        let groundHits = 0;
        let closestGroundDistance = Infinity;
        let groundY = this.options.groundLevel;
        
        // Use more rays for better ground detection
        const rayDirections = [
            new THREE.Vector3(0, -1, 0),     // Center
            new THREE.Vector3(0.1, -1, 0),   // Right (smaller offset for bee)
            new THREE.Vector3(-0.1, -1, 0),  // Left
            new THREE.Vector3(0, -1, 0.1),   // Forward
            new THREE.Vector3(0, -1, -0.1),  // Backward
        ];
        
        for (const rayDirection of rayDirections) {
            // Cast ray from player position with tiny offset
            const rayOrigin = playerState.position.clone().add(
                new THREE.Vector3(rayDirection.x * 0.01, 0.1, rayDirection.z * 0.01) // Very small offset for bee
            );
            
            this.raycaster.set(rayOrigin, rayDirection);
            
            const intersects = this.raycaster.intersectObjects(this.collisionObjects, true);
            
            if (intersects.length > 0) {
                const distance = intersects[0].distance;
                
                if (distance < rayDistance) {
                    groundHits++;
                    
                    // Track the closest ground point
                    if (distance < closestGroundDistance) {
                        closestGroundDistance = distance;
                        groundY = intersects[0].point.y;
                    }
                }
            }
        }
        
        // If we found ground, snap player directly to it (bee-sized)
        if (groundHits >= 1 && closestGroundDistance < 1.0) {
            // Snap player directly to ground level with microscopic offset
            const targetY = groundY + 0.001; // 1mm offset above ground for bee
            playerState.position.y = targetY;
            
            if (this.options.debugMode) {
                console.log(`🐝 Bee snapped to ground: ${targetY.toFixed(4)}m`);
            }
            
            return true;
        }
        
        return false;
    }

    /**
     * Handle player jump
     * @param {Object} playerState - Player state object
     */
    jump(playerState) {
        if (playerState.isGrounded) {
            playerState.velocity.y = playerState.jumpHeight;
            playerState.isGrounded = false;
            
            if (this.options.debugMode) {
                console.log('🦘 Player jumped with velocity:', playerState.jumpHeight);
            }
        }
    }

    /**
     * Check collisions with scene geometry
     * @param {Object} playerState - Player state object
     * @param {Object} characterSystem - Character system for bounding box
     * @returns {boolean} Whether collision occurred
     */
    checkCollisions(playerState, characterSystem) {
        if (!this.options.enableCollisions || this.collisionObjects.length === 0) {
            return false;
        }
        
        // Get player bounding box
        const playerBounds = characterSystem.getBoundingBox();
        let hasCollision = false;
        
        // Check collision with each object
        for (const obj of this.collisionObjects) {
            if (this.checkObjectCollision(playerBounds, obj, playerState)) {
                hasCollision = true;
            }
        }
        
        return hasCollision;
    }

    /**
     * Check collision with specific object
     * @param {THREE.Box3} playerBounds - Player bounding box
     * @param {THREE.Object3D} object - Object to check collision with
     * @param {Object} playerState - Player state object
     * @returns {boolean} Whether collision occurred
     */
    checkObjectCollision(playerBounds, object, playerState) {
        // Get object bounding box
        this.tempBox.setFromObject(object);
        
        if (playerBounds.intersectsBox(this.tempBox)) {
            // Calculate collision response
            this.resolveCollision(playerBounds, this.tempBox, playerState);
            return true;
        }
        
        return false;
    }

    /**
     * Resolve collision by pushing player out of collision
     * @param {THREE.Box3} playerBounds - Player bounding box
     * @param {THREE.Box3} objectBounds - Object bounding box
     * @param {Object} playerState - Player state object
     */
    resolveCollision(playerBounds, objectBounds, playerState) {
        // Calculate overlap on each axis
        const overlapX = Math.min(playerBounds.max.x - objectBounds.min.x, objectBounds.max.x - playerBounds.min.x);
        const overlapY = Math.min(playerBounds.max.y - objectBounds.min.y, objectBounds.max.y - playerBounds.min.y);
        const overlapZ = Math.min(playerBounds.max.z - objectBounds.min.z, objectBounds.max.z - playerBounds.min.z);
        
        // Find minimum overlap axis for separation
        const minOverlap = Math.min(overlapX, overlapY, overlapZ);
        
        if (minOverlap === overlapX) {
            // Separate on X axis
            const direction = playerBounds.getCenter(this.tempVector).x > objectBounds.getCenter(new THREE.Vector3()).x ? 1 : -1;
            playerState.position.x += direction * overlapX;
            playerState.velocity.x = 0;
        } else if (minOverlap === overlapY) {
            // Separate on Y axis
            const direction = playerBounds.getCenter(this.tempVector).y > objectBounds.getCenter(new THREE.Vector3()).y ? 1 : -1;
            playerState.position.y += direction * overlapY;
            if (direction < 0) {
                playerState.velocity.y = 0;
                playerState.isGrounded = true;
            }
        } else {
            // Separate on Z axis
            const direction = playerBounds.getCenter(this.tempVector).z > objectBounds.getCenter(new THREE.Vector3()).z ? 1 : -1;
            playerState.position.z += direction * overlapZ;
            playerState.velocity.z = 0;
        }
        
        if (this.options.debugMode) {
            console.log('🔴 Collision resolved on axis:', minOverlap === overlapX ? 'X' : minOverlap === overlapY ? 'Y' : 'Z');
        }
    }

    /**
     * Advanced collision detection using raycasting
     * @param {Object} playerState - Player state object
     * @param {THREE.Vector3} direction - Movement direction
     * @param {number} distance - Movement distance
     * @returns {boolean} Whether movement is blocked
     */
    raycastCollision(playerState, direction, distance) {
        this.raycaster.set(playerState.position, direction.normalize());
        
        const intersects = this.raycaster.intersectObjects(this.collisionObjects, true);
        
        if (intersects.length > 0 && intersects[0].distance < distance) {
            if (this.options.debugMode) {
                console.log('🔴 Raycast collision detected at distance:', intersects[0].distance);
            }
            return true;
        }
        
        return false;
    }

    /**
     * Apply friction to velocity
     * @param {Object} playerState - Player state object
     * @param {number} friction - Friction coefficient (0-1)
     */
    applyFriction(playerState, friction = 0.9) {
        if (playerState.isGrounded) {
            playerState.velocity.x *= friction;
            playerState.velocity.z *= friction;
        } else {
            // Air resistance (less friction in air)
            playerState.velocity.x *= friction * 0.99;
            playerState.velocity.z *= friction * 0.99;
        }
    }

    /**
     * Apply air resistance
     * @param {Object} playerState - Player state object
     * @param {number} resistance - Air resistance coefficient
     */
    applyAirResistance(playerState, resistance = 0.98) {
        if (!playerState.isGrounded) {
            playerState.velocity.multiplyScalar(resistance);
        }
    }

    /**
     * Check if player can move in direction
     * @param {Object} playerState - Player state object
     * @param {THREE.Vector3} direction - Movement direction
     * @param {number} distance - Movement distance
     * @returns {boolean} Whether movement is possible
     */
    canMove(playerState, direction, distance) {
        return !this.raycastCollision(playerState, direction, distance);
    }

    /**
     * Get ground normal at player position
     * @param {Object} playerState - Player state object
     * @returns {THREE.Vector3} Ground normal vector
     */
    getGroundNormal(playerState) {
        this.raycaster.set(playerState.position, new THREE.Vector3(0, -1, 0));
        
        const intersects = this.raycaster.intersectObjects(this.collisionObjects, true);
        
        if (intersects.length > 0) {
            return intersects[0].face.normal.clone();
        }
        
        return new THREE.Vector3(0, 1, 0); // Default up vector
    }

    /**
     * Apply slope movement (walking up/down slopes)
     * @param {Object} playerState - Player state object
     * @param {THREE.Vector3} movement - Movement vector
     * @returns {THREE.Vector3} Adjusted movement vector
     */
    applySlopeMovement(playerState, movement) {
        if (!playerState.isGrounded) return movement;
        
        const groundNormal = this.getGroundNormal(playerState);
        
        // Project movement onto ground plane
        const projectedMovement = movement.clone().projectOnPlane(groundNormal);
        
        return projectedMovement;
    }

    /**
     * Set gravity strength
     * @param {number} gravity - Gravity value (negative for downward)
     */
    setGravity(gravity) {
        this.options.gravity = gravity;
    }

    /**
     * Set ground level
     * @param {number} level - Ground level Y coordinate
     */
    setGroundLevel(level) {
        this.options.groundLevel = level;
    }

    /**
     * Enable/disable collision detection
     * @param {boolean} enabled - Whether collisions should be enabled
     */
    setCollisionsEnabled(enabled) {
        this.options.enableCollisions = enabled;
    }

    /**
     * Enable/disable gravity
     * @param {boolean} enabled - Whether gravity should be enabled
     */
    setGravityEnabled(enabled) {
        this.options.enableGravity = enabled;
    }

    /**
     * Get physics statistics
     * @returns {Object} Physics statistics
     */
    getStatistics() {
        return {
            collisionObjects: this.collisionObjects.length,
            gravity: this.options.gravity,
            groundLevel: this.options.groundLevel,
            collisionsEnabled: this.options.enableCollisions,
            gravityEnabled: this.options.enableGravity
        };
    }

    /**
     * Dispose of physics engine resources
     */
    dispose() {
        this.collisionObjects = [];
        this.raycaster = null;
        this.tempVector = null;
        this.tempBox = null;
        this.groundRays = [];
        
        console.log('🗑️ PhysicsEngine disposed');
    }
}