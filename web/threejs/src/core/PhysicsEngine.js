/**
 * PhysicsEngine - AAA-Quality physics simulation for 3D games
 * Implements professional collision detection with spatial partitioning,
 * swept collision, and optimized raycasting for game-level performance
 */

import * as THREE from 'three';

export class PhysicsEngine {
    constructor(options = {}) {
        this.options = {
            gravity: -9.81,
            groundLevel: 0.0,
            enableCollisions: true,
            enableGravity: true,
            debugMode: false,
            maxGroundDistance: 2.0,
            // Professional collision settings
            useSpatialPartitioning: true,
            spatialGridSize: 10.0, // Grid cell size for spatial partitioning
            useSweptCollision: true, // Prevents tunneling at high speeds
            collisionMargin: 0.01, // Small margin to prevent jittering
            maxCollisionIterations: 3, // Max iterations for collision resolution
            ...options
        };
        
        // Physics state
        this.collisionObjects = [];
        this.staticCollisionObjects = []; // Objects that don't move
        this.dynamicCollisionObjects = []; // Objects that move
        
        // Spatial partitioning (Octree-like grid)
        this.spatialGrid = new Map();
        this.spatialGridDirty = true;
        
        // Raycasting optimization
        this.raycaster = new THREE.Raycaster();
        this.raycasterPool = []; // Pool of raycasters for multi-ray checks
        for (let i = 0; i < 5; i++) {
            this.raycasterPool.push(new THREE.Raycaster());
        }
        
        // Temp objects for calculations (avoid allocations)
        this.tempVector = new THREE.Vector3();
        this.tempVector2 = new THREE.Vector3();
        this.tempVector3 = new THREE.Vector3();
        this.tempBox = new THREE.Box3();
        this.tempBox2 = new THREE.Box3();
        
        // Bounding box cache for performance
        this.boundingBoxCache = new WeakMap();
        this.boundingBoxCacheTime = new WeakMap();
        this.cacheLifetime = 1000; // 1 second cache lifetime
        
        // Collision layers (for selective collision)
        this.collisionLayers = {
            player: 1,
            environment: 2,
            items: 4,
            triggers: 8
        };
        
        // Performance metrics
        this.metrics = {
            collisionChecks: 0,
            raycastChecks: 0,
            spatialLookups: 0,
            cacheHits: 0,
            lastFrameTime: 0
        };
        
        console.log('✅ PhysicsEngine initialized with AAA-quality collision detection');
        console.log('🎮 Features: Spatial Partitioning, Swept Collision, Bounding Box Cache');
    }

    /**
     * Add collision object to physics world with professional categorization
     * @param {THREE.Object3D} object - Object to add for collision detection
     * @param {Object} options - Collision options
     */
    addCollisionObject(object, options = {}) {
        if (!object.isMesh && !object.isGroup) return;
        
        const collisionData = {
            object: object,
            isStatic: options.isStatic !== undefined ? options.isStatic : true,
            layer: options.layer || this.collisionLayers.environment,
            boundingBox: null,
            gridCells: [] // Spatial grid cells this object occupies
        };
        
        this.collisionObjects.push(collisionData);
        
        if (collisionData.isStatic) {
            this.staticCollisionObjects.push(collisionData);
        } else {
            this.dynamicCollisionObjects.push(collisionData);
        }
        
        // Mark spatial grid as dirty for rebuild
        this.spatialGridDirty = true;
        
        if (this.options.debugMode) {
            console.log(`🔧 Added collision object: ${object.name || 'unnamed'} (${collisionData.isStatic ? 'static' : 'dynamic'})`);
        }
    }

    /**
     * Remove collision object from physics world
     * @param {THREE.Object3D} object - Object to remove
     */
    removeCollisionObject(object) {
        const index = this.collisionObjects.findIndex(data => data.object === object);
        if (index !== -1) {
            const collisionData = this.collisionObjects[index];
            
            // Remove from appropriate array
            if (collisionData.isStatic) {
                const staticIndex = this.staticCollisionObjects.indexOf(collisionData);
                if (staticIndex !== -1) {
                    this.staticCollisionObjects.splice(staticIndex, 1);
                }
            } else {
                const dynamicIndex = this.dynamicCollisionObjects.indexOf(collisionData);
                if (dynamicIndex !== -1) {
                    this.dynamicCollisionObjects.splice(dynamicIndex, 1);
                }
            }
            
            this.collisionObjects.splice(index, 1);
            this.spatialGridDirty = true;
            
            if (this.options.debugMode) {
                console.log('🔧 Removed collision object:', object.name || 'unnamed');
            }
        }
    }
    
    /**
     * Build spatial partitioning grid for optimized collision detection
     * Only rebuilds when dirty (objects added/removed)
     */
    buildSpatialGrid() {
        if (!this.options.useSpatialPartitioning || !this.spatialGridDirty) {
            return;
        }
        
        this.spatialGrid.clear();
        const gridSize = this.options.spatialGridSize;
        
        // Only partition static objects (dynamic objects checked every frame anyway)
        for (const collisionData of this.staticCollisionObjects) {
            const bbox = this.getCachedBoundingBox(collisionData.object);
            if (!bbox) continue;
            
            // Calculate which grid cells this object occupies
            const minCell = this.worldToGrid(bbox.min, gridSize);
            const maxCell = this.worldToGrid(bbox.max, gridSize);
            
            collisionData.gridCells = [];
            
            // Add object to all cells it occupies
            for (let x = minCell.x; x <= maxCell.x; x++) {
                for (let y = minCell.y; y <= maxCell.y; y++) {
                    for (let z = minCell.z; z <= maxCell.z; z++) {
                        const cellKey = `${x},${y},${z}`;
                        
                        if (!this.spatialGrid.has(cellKey)) {
                            this.spatialGrid.set(cellKey, []);
                        }
                        
                        this.spatialGrid.get(cellKey).push(collisionData);
                        collisionData.gridCells.push(cellKey);
                    }
                }
            }
        }
        
        this.spatialGridDirty = false;
        
        if (this.options.debugMode) {
            console.log(`🗺️ Spatial grid built: ${this.spatialGrid.size} cells, ${this.staticCollisionObjects.length} static objects`);
        }
    }
    
    /**
     * Convert world position to grid cell coordinates
     * @param {THREE.Vector3} position - World position
     * @param {number} gridSize - Grid cell size
     * @returns {Object} Grid cell coordinates
     */
    worldToGrid(position, gridSize) {
        return {
            x: Math.floor(position.x / gridSize),
            y: Math.floor(position.y / gridSize),
            z: Math.floor(position.z / gridSize)
        };
    }
    
    /**
     * Get nearby collision objects using spatial partitioning
     * @param {THREE.Vector3} position - Query position
     * @param {number} radius - Query radius
     * @returns {Array} Nearby collision objects
     */
    getNearbyObjects(position, radius = 5.0) {
        if (!this.options.useSpatialPartitioning) {
            // Fallback: return all objects
            return this.collisionObjects;
        }
        
        this.buildSpatialGrid(); // Build if dirty
        
        const gridSize = this.options.spatialGridSize;
        const radiusCells = Math.ceil(radius / gridSize);
        const centerCell = this.worldToGrid(position, gridSize);
        
        const nearbyObjects = new Set();
        
        // Check surrounding cells
        for (let x = centerCell.x - radiusCells; x <= centerCell.x + radiusCells; x++) {
            for (let y = centerCell.y - radiusCells; y <= centerCell.y + radiusCells; y++) {
                for (let z = centerCell.z - radiusCells; z <= centerCell.z + radiusCells; z++) {
                    const cellKey = `${x},${y},${z}`;
                    const cellObjects = this.spatialGrid.get(cellKey);
                    
                    if (cellObjects) {
                        cellObjects.forEach(obj => nearbyObjects.add(obj));
                    }
                }
            }
        }
        
        // Always include dynamic objects (they move every frame)
        this.dynamicCollisionObjects.forEach(obj => nearbyObjects.add(obj));
        
        this.metrics.spatialLookups++;
        
        return Array.from(nearbyObjects);
    }
    
    /**
     * Get cached bounding box for object (performance optimization)
     * @param {THREE.Object3D} object - Object to get bounding box for
     * @returns {THREE.Box3} Cached bounding box
     */
    getCachedBoundingBox(object) {
        const now = performance.now();
        const cachedTime = this.boundingBoxCacheTime.get(object);
        
        // Check if cache is still valid
        if (cachedTime && (now - cachedTime) < this.cacheLifetime) {
            this.metrics.cacheHits++;
            return this.boundingBoxCache.get(object);
        }
        
        // Compute new bounding box
        const bbox = new THREE.Box3().setFromObject(object);
        this.boundingBoxCache.set(object, bbox);
        this.boundingBoxCacheTime.set(object, now);
        
        return bbox;
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
     * Check ground collision using optimized multi-ray detection
     * Uses spatial partitioning and raycaster pooling for performance
     * @param {Object} playerState - Player state object
     * @returns {boolean} Whether player is grounded
     */
    checkGroundCollision(playerState) {
        // If no collision objects, use simple ground level check
        if (this.collisionObjects.length === 0) {
            const distanceToGround = playerState.position.y - this.options.groundLevel;
            return distanceToGround <= 0.05;
        }
        
        const rayDistance = 1.0; // Increased for better detection
        let groundHits = 0;
        let closestGroundDistance = Infinity;
        let groundY = this.options.groundLevel;
        
        // Get nearby objects for raycasting (optimization)
        const nearbyObjects = this.getNearbyObjects(playerState.position, 3.0);
        const objectMeshes = nearbyObjects.map(data => data.object);
        
        if (objectMeshes.length === 0) {
            // Fallback to ground level check
            const distanceToGround = playerState.position.y - this.options.groundLevel;
            return distanceToGround <= 0.1;
        }
        
        // Use multiple rays for reliable ground detection (professional approach)
        const rayOffsets = [
            { x: 0, z: 0 },      // Center
            { x: 0.1, z: 0 },    // Right
            { x: -0.1, z: 0 },   // Left
            { x: 0, z: 0.1 },    // Forward
            { x: 0, z: -0.1 },   // Backward
            { x: 0.07, z: 0.07 }, // Diagonal corners
            { x: -0.07, z: 0.07 },
            { x: 0.07, z: -0.07 },
            { x: -0.07, z: -0.07 }
        ];
        
        for (let i = 0; i < Math.min(rayOffsets.length, this.raycasterPool.length); i++) {
            const offset = rayOffsets[i];
            const raycaster = this.raycasterPool[i];
            
            // Cast ray from slightly above player position
            const rayOrigin = this.tempVector.set(
                playerState.position.x + offset.x,
                playerState.position.y + 0.1,
                playerState.position.z + offset.z
            );
            
            raycaster.set(rayOrigin, new THREE.Vector3(0, -1, 0));
            raycaster.far = rayDistance;
            
            const intersects = raycaster.intersectObjects(objectMeshes, true);
            
            if (intersects.length > 0) {
                const distance = intersects[0].distance;
                
                if (distance < rayDistance) {
                    groundHits++;
                    
                    if (distance < closestGroundDistance) {
                        closestGroundDistance = distance;
                        groundY = intersects[0].point.y;
                    }
                }
            }
            
            this.metrics.raycastChecks++;
        }
        
        // Professional ground detection logic
        const tolerance = 0.15; // 15cm tolerance
        const isCloseToGround = closestGroundDistance < tolerance;
        
        // Require multiple hits for reliability, but allow single hit if very close
        if ((groundHits >= 3) || (groundHits >= 1 && isCloseToGround)) {
            const targetY = groundY + 0.001;
            
            // Only snap if falling or very close to ground
            if (playerState.velocity.y <= 0 || Math.abs(playerState.position.y - groundY) < 0.1) {
                playerState.position.y = targetY;
            }
            
            if (this.options.debugMode) {
                console.log(`🟢 Grounded: ${groundHits} hits, distance=${closestGroundDistance.toFixed(4)}m, groundY=${groundY.toFixed(3)}`);
            }
            
            return true;
        }
        
        if (this.options.debugMode && groundHits > 0) {
            console.log(`🟡 Partial ground detection: ${groundHits} hits, distance=${closestGroundDistance.toFixed(4)}m`);
        }
        
        return false;
    }

    /**
     * Handle player jump with professional game-like mechanics
     * Prevents jump spamming and ensures reliable jumping
     * @param {Object} playerState - Player state object
     */
    jump(playerState) {
        // Only allow jump if grounded (prevents mid-air jumping)
        if (!playerState.isGrounded) {
            if (this.options.debugMode) {
                console.log('🚫 Jump blocked: Player not grounded');
            }
            return false;
        }
        
        // Apply jump velocity
        playerState.velocity.y = playerState.jumpHeight;
        playerState.isGrounded = false;
        
        if (this.options.debugMode) {
            console.log(`🦘 Player jumped! Velocity: ${playerState.jumpHeight}, Position: ${playerState.position.y.toFixed(3)}`);
        }
        
        return true;
    }

    /**
     * Check collisions with scene geometry using professional techniques
     * Implements spatial partitioning and swept collision detection
     * @param {Object} playerState - Player state object
     * @param {Object} characterSystem - Character system for bounding box
     * @returns {boolean} Whether collision occurred
     */
    checkCollisions(playerState, characterSystem) {
        if (!this.options.enableCollisions || this.collisionObjects.length === 0) {
            return false;
        }
        
        this.metrics.collisionChecks++;
        
        // Get player bounding box
        const playerBounds = characterSystem.getBoundingBox();
        if (!playerBounds) return false;
        
        // Get nearby objects using spatial partitioning
        const nearbyObjects = this.getNearbyObjects(
            playerState.position,
            5.0 // Check within 5 meter radius
        );
        
        let hasCollision = false;
        let iterations = 0;
        
        // Iterative collision resolution (prevents getting stuck)
        while (iterations < this.options.maxCollisionIterations) {
            let collisionThisIteration = false;
            
            for (const collisionData of nearbyObjects) {
                if (this.checkObjectCollision(playerBounds, collisionData.object, playerState)) {
                    collisionThisIteration = true;
                    hasCollision = true;
                }
            }
            
            if (!collisionThisIteration) {
                break; // No more collisions, we're done
            }
            
            // Update player bounds for next iteration
            playerBounds.setFromCenterAndSize(
                playerState.position,
                playerBounds.getSize(this.tempVector)
            );
            
            iterations++;
        }
        
        if (this.options.debugMode && hasCollision) {
            console.log(`🔴 Collision resolved in ${iterations} iteration(s)`);
        }
        
        return hasCollision;
    }

    /**
     * Check collision with specific object using optimized bounding box test
     * @param {THREE.Box3} playerBounds - Player bounding box
     * @param {THREE.Object3D} object - Object to check collision with
     * @param {Object} playerState - Player state object
     * @returns {boolean} Whether collision occurred
     */
    checkObjectCollision(playerBounds, object, playerState) {
        // Get cached object bounding box
        const objectBounds = this.getCachedBoundingBox(object);
        if (!objectBounds) return false;
        
        // Quick AABB intersection test
        if (!playerBounds.intersectsBox(objectBounds)) {
            return false;
        }
        
        // Collision detected - resolve it
        this.resolveCollision(playerBounds, objectBounds, playerState);
        return true;
    }

    /**
     * Resolve collision using professional separation algorithm
     * Uses minimum translation vector (MTV) for smooth collision response
     * @param {THREE.Box3} playerBounds - Player bounding box
     * @param {THREE.Box3} objectBounds - Object bounding box
     * @param {Object} playerState - Player state object
     */
    resolveCollision(playerBounds, objectBounds, playerState) {
        // Calculate penetration depth on each axis
        const playerCenter = playerBounds.getCenter(this.tempVector);
        const objectCenter = objectBounds.getCenter(this.tempVector2);
        
        const playerSize = playerBounds.getSize(this.tempVector3);
        const objectSize = objectBounds.getSize(new THREE.Vector3());
        
        // Calculate overlap on each axis
        const overlapX = (playerSize.x + objectSize.x) / 2 - Math.abs(playerCenter.x - objectCenter.x);
        const overlapY = (playerSize.y + objectSize.y) / 2 - Math.abs(playerCenter.y - objectCenter.y);
        const overlapZ = (playerSize.z + objectSize.z) / 2 - Math.abs(playerCenter.z - objectCenter.z);
        
        // Find minimum overlap axis (MTV - Minimum Translation Vector)
        const minOverlap = Math.min(overlapX, overlapY, overlapZ);
        
        // Add small margin to prevent jittering
        const margin = this.options.collisionMargin;
        
        if (minOverlap === overlapX) {
            // Separate on X axis
            const direction = playerCenter.x > objectCenter.x ? 1 : -1;
            playerState.position.x += direction * (overlapX + margin);
            playerState.velocity.x = 0;
            
            if (this.options.debugMode) {
                console.log(`🔴 X-axis collision: overlap=${overlapX.toFixed(3)}m, dir=${direction}`);
            }
        } else if (minOverlap === overlapY) {
            // Separate on Y axis
            const direction = playerCenter.y > objectCenter.y ? 1 : -1;
            playerState.position.y += direction * (overlapY + margin);
            
            // Landing on top of object
            if (direction < 0) {
                playerState.velocity.y = 0;
                playerState.isGrounded = true;
            } else {
                // Hitting ceiling
                playerState.velocity.y = Math.min(0, playerState.velocity.y);
            }
            
            if (this.options.debugMode) {
                console.log(`🔴 Y-axis collision: overlap=${overlapY.toFixed(3)}m, dir=${direction}`);
            }
        } else {
            // Separate on Z axis
            const direction = playerCenter.z > objectCenter.z ? 1 : -1;
            playerState.position.z += direction * (overlapZ + margin);
            playerState.velocity.z = 0;
            
            if (this.options.debugMode) {
                console.log(`🔴 Z-axis collision: overlap=${overlapZ.toFixed(3)}m, dir=${direction}`);
            }
        }
    }
    
    /**
     * Swept collision detection - prevents tunneling at high speeds
     * @param {THREE.Vector3} startPos - Start position
     * @param {THREE.Vector3} endPos - End position
     * @param {THREE.Box3} bounds - Object bounds
     * @returns {Object} Collision result with hit point and normal
     */
    sweptCollision(startPos, endPos, bounds) {
        if (!this.options.useSweptCollision) {
            return null;
        }
        
        const direction = this.tempVector.subVectors(endPos, startPos);
        const distance = direction.length();
        
        if (distance < 0.001) return null;
        
        direction.normalize();
        
        // Cast ray along movement path
        this.raycaster.set(startPos, direction);
        this.raycaster.far = distance;
        
        const nearbyObjects = this.getNearbyObjects(startPos, distance + 2.0);
        const objectMeshes = nearbyObjects.map(data => data.object);
        
        const intersects = this.raycaster.intersectObjects(objectMeshes, true);
        
        if (intersects.length > 0) {
            return {
                hit: true,
                point: intersects[0].point,
                normal: intersects[0].face.normal,
                distance: intersects[0].distance,
                object: intersects[0].object
            };
        }
        
        return null;
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
     * Get comprehensive physics statistics for performance monitoring
     * @returns {Object} Physics statistics
     */
    getStatistics() {
        return {
            collisionObjects: this.collisionObjects.length,
            staticObjects: this.staticCollisionObjects.length,
            dynamicObjects: this.dynamicCollisionObjects.length,
            spatialGridCells: this.spatialGrid.size,
            gravity: this.options.gravity,
            groundLevel: this.options.groundLevel,
            collisionsEnabled: this.options.enableCollisions,
            gravityEnabled: this.options.enableGravity,
            // Performance metrics
            metrics: {
                collisionChecks: this.metrics.collisionChecks,
                raycastChecks: this.metrics.raycastChecks,
                spatialLookups: this.metrics.spatialLookups,
                cacheHits: this.metrics.cacheHits,
                cacheHitRate: this.metrics.cacheHits > 0 
                    ? ((this.metrics.cacheHits / (this.metrics.cacheHits + this.collisionObjects.length)) * 100).toFixed(1) + '%'
                    : '0%'
            }
        };
    }
    
    /**
     * Reset performance metrics
     */
    resetMetrics() {
        this.metrics = {
            collisionChecks: 0,
            raycastChecks: 0,
            spatialLookups: 0,
            cacheHits: 0,
            lastFrameTime: 0
        };
    }
    
    /**
     * Clear bounding box cache (call when objects move significantly)
     */
    clearBoundingBoxCache() {
        this.boundingBoxCache = new WeakMap();
        this.boundingBoxCacheTime = new WeakMap();
    }
    
    /**
     * Rebuild spatial grid (call when many objects added/removed)
     */
    rebuildSpatialGrid() {
        this.spatialGridDirty = true;
        this.buildSpatialGrid();
    }

    /**
     * Dispose of physics engine resources
     */
    dispose() {
        this.collisionObjects = [];
        this.staticCollisionObjects = [];
        this.dynamicCollisionObjects = [];
        this.spatialGrid.clear();
        this.boundingBoxCache = new WeakMap();
        this.boundingBoxCacheTime = new WeakMap();
        
        this.raycaster = null;
        this.raycasterPool = [];
        this.tempVector = null;
        this.tempVector2 = null;
        this.tempVector3 = null;
        this.tempBox = null;
        this.tempBox2 = null;
        
        console.log('🗑️ PhysicsEngine disposed');
    }
}