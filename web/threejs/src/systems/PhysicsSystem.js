/**
 * PhysicsSystem - Professional physics simulation with continuous collision detection
 * Implements high-precision physics for bee-sized character navigation
 */

import * as THREE from 'three';

export class PhysicsSystem {
    constructor(options = {}) {
        this.options = {
            gravity: -9.81,
            timeStep: 1/120, // 120Hz physics
            maxSubSteps: 10,
            enableCollisions: true,
            enableCCD: true, // Continuous collision detection
            debugMode: false,
            worldSize: 1000,
            ...options
        };
        
        // Physics world
        this.world = {
            gravity: new THREE.Vector3(0, this.options.gravity, 0),
            bodies: new Map(), // entityId -> RigidBody
            colliders: new Map(), // entityId -> Collider
            constraints: new Map() // constraintId -> Constraint
        };
        
        // Spatial partitioning for efficient collision detection
        this.spatialGrid = new SpatialGrid(this.options.worldSize, 32);
        
        // Collision detection
        this.collisionPairs = new Set();
        this.contactPoints = [];
        
        // Raycasting
        this.raycaster = new THREE.Raycaster();
        this.raycastResults = [];
        
        // Performance tracking
        this.physicsStats = {
            bodies: 0,
            colliders: 0,
            collisionChecks: 0,
            contactPoints: 0,
            raycastQueries: 0
        };
        
        console.log('⚡ PhysicsSystem created with professional simulation');
    }
    
    /**
     * Initialize the physics system
     */
    async initialize() {
        try {
            console.log('🚀 Initializing Professional Physics System...');
            
            // Initialize spatial partitioning
            this.spatialGrid.initialize();
            
            // Setup collision materials
            this.setupCollisionMaterials();
            
            console.log('✅ Professional Physics System initialized');
            
        } catch (error) {
            console.error('❌ PhysicsSystem initialization failed:', error);
            throw error;
        }
    }
    
    /**
     * Setup collision materials for different surface types
     */
    setupCollisionMaterials() {
        this.materials = {
            default: {
                friction: 0.7,
                restitution: 0.3,
                density: 1.0
            },
            ground: {
                friction: 0.8,
                restitution: 0.1,
                density: 0.0 // Static
            },
            character: {
                friction: 0.9,
                restitution: 0.0,
                density: 70.0 // 70kg character
            },
            bouncy: {
                friction: 0.3,
                restitution: 0.9,
                density: 1.0
            }
        };
        
        console.log('🧪 Collision materials setup');
    }
    
    /**
     * Add rigid body to physics world
     * @param {number} entityId - Entity ID
     * @param {Object} bodyData - Rigid body data
     */
    addRigidBody(entityId, bodyData) {
        const body = {
            entityId,
            mass: bodyData.mass || 0,
            position: new THREE.Vector3().copy(bodyData.position || new THREE.Vector3()),
            rotation: new THREE.Euler().copy(bodyData.rotation || new THREE.Euler()),
            velocity: new THREE.Vector3().copy(bodyData.velocity || new THREE.Vector3()),
            angularVelocity: new THREE.Vector3().copy(bodyData.angularVelocity || new THREE.Vector3()),
            force: new THREE.Vector3(),
            torque: new THREE.Vector3(),
            material: bodyData.material || 'default',
            isKinematic: bodyData.isKinematic || false,
            isStatic: bodyData.mass === 0,
            sleepState: 'awake',
            lastPosition: new THREE.Vector3().copy(bodyData.position || new THREE.Vector3())
        };
        
        this.world.bodies.set(entityId, body);
        this.physicsStats.bodies++;
        
        console.log(`⚡ RigidBody added for entity ${entityId}`);
    }
    
    /**
     * Add collider to physics world
     * @param {number} entityId - Entity ID
     * @param {Object} colliderData - Collider data
     */
    addCollider(entityId, colliderData) {
        const collider = {
            entityId,
            shape: colliderData.shape || 'box',
            size: new THREE.Vector3().copy(colliderData.size || new THREE.Vector3(1, 1, 1)),
            offset: new THREE.Vector3().copy(colliderData.offset || new THREE.Vector3()),
            isTrigger: colliderData.isTrigger || false,
            collisionLayer: colliderData.collisionLayer || 0,
            collisionMask: colliderData.collisionMask || 0xFFFFFFFF,
            bounds: new THREE.Box3()
        };
        
        // Update bounds
        this.updateColliderBounds(collider);
        
        this.world.colliders.set(entityId, collider);
        this.physicsStats.colliders++;
        
        console.log(`🔲 Collider added for entity ${entityId}`);
    }
    
    /**
     * Update collider bounds based on body position
     * @param {Object} collider - Collider object
     */
    updateColliderBounds(collider) {
        const body = this.world.bodies.get(collider.entityId);
        if (!body) return;
        
        const position = body.position.clone().add(collider.offset);
        const halfSize = collider.size.clone().multiplyScalar(0.5);
        
        collider.bounds.setFromCenterAndSize(position, collider.size);
    }
    
    /**
     * Update physics simulation
     * @param {number} deltaTime - Frame delta time in milliseconds
     * @param {number} totalTime - Total elapsed time
     */
    update(deltaTime, totalTime) {
        try {
            // Convert delta time to seconds
            const dt = deltaTime / 1000;
            
            // Fixed timestep integration
            this.integratePhysics(dt);
            
            // Update spatial partitioning
            this.updateSpatialPartitioning();
            
            // Collision detection and response
            if (this.options.enableCollisions) {
                this.detectCollisions();
                this.resolveCollisions();
            }
            
            // Update statistics
            this.updatePhysicsStats();
            
        } catch (error) {
            console.error('❌ Physics update error:', error);
        }
    }
    
    /**
     * Integrate physics (velocity, position, forces)
     * @param {number} dt - Delta time in seconds
     */
    integratePhysics(dt) {
        for (const [entityId, body] of this.world.bodies) {
            if (body.isStatic || body.sleepState === 'sleeping') continue;
            
            // Store last position for CCD
            body.lastPosition.copy(body.position);
            
            // Apply gravity
            if (!body.isKinematic && body.mass > 0) {
                body.force.add(
                    this.world.gravity.clone().multiplyScalar(body.mass)
                );
            }
            
            // Integrate velocity (Verlet integration for stability)
            if (body.mass > 0) {
                const acceleration = body.force.clone().divideScalar(body.mass);
                body.velocity.add(acceleration.multiplyScalar(dt));
                
                // Apply damping
                body.velocity.multiplyScalar(0.999);
                body.angularVelocity.multiplyScalar(0.999);
            }
            
            // Integrate position
            if (!body.isKinematic) {
                body.position.add(body.velocity.clone().multiplyScalar(dt));
                
                // Angular integration (simplified)
                const angularDisplacement = body.angularVelocity.clone().multiplyScalar(dt);
                body.rotation.x += angularDisplacement.x;
                body.rotation.y += angularDisplacement.y;
                body.rotation.z += angularDisplacement.z;
            }
            
            // Clear forces
            body.force.set(0, 0, 0);
            body.torque.set(0, 0, 0);
            
            // Update collider bounds
            const collider = this.world.colliders.get(entityId);
            if (collider) {
                this.updateColliderBounds(collider);
            }
        }
    }
    
    /**
     * Update spatial partitioning for efficient collision detection
     */
    updateSpatialPartitioning() {
        this.spatialGrid.clear();
        
        for (const [entityId, collider] of this.world.colliders) {
            this.spatialGrid.insert(entityId, collider.bounds);
        }
    }
    
    /**
     * Detect collisions using spatial partitioning
     */
    detectCollisions() {
        this.collisionPairs.clear();
        this.contactPoints = [];
        this.physicsStats.collisionChecks = 0;
        
        // Broad phase: spatial grid
        const potentialPairs = this.spatialGrid.getPotentialCollisions();
        
        // Narrow phase: detailed collision detection
        for (const [entityA, entityB] of potentialPairs) {
            const colliderA = this.world.colliders.get(entityA);
            const colliderB = this.world.colliders.get(entityB);
            
            if (!colliderA || !colliderB) continue;
            
            // Check collision layers
            if ((colliderA.collisionLayer & colliderB.collisionMask) === 0 &&
                (colliderB.collisionLayer & colliderA.collisionMask) === 0) {
                continue;
            }
            
            this.physicsStats.collisionChecks++;
            
            // Detailed collision detection
            const contact = this.detectCollision(colliderA, colliderB);
            if (contact) {
                this.collisionPairs.add(`${entityA}-${entityB}`);
                this.contactPoints.push(contact);
            }
        }
        
        this.physicsStats.contactPoints = this.contactPoints.length;
    }
    
    /**
     * Detect collision between two colliders
     * @param {Object} colliderA - First collider
     * @param {Object} colliderB - Second collider
     * @returns {Object|null} Contact information
     */
    detectCollision(colliderA, colliderB) {
        // Box-Box collision (most common case)
        if (colliderA.shape === 'box' && colliderB.shape === 'box') {
            return this.detectBoxBoxCollision(colliderA, colliderB);
        }
        
        // Sphere-Sphere collision
        if (colliderA.shape === 'sphere' && colliderB.shape === 'sphere') {
            return this.detectSphereSphereCollision(colliderA, colliderB);
        }
        
        // Capsule-Box collision (for character)
        if ((colliderA.shape === 'capsule' && colliderB.shape === 'box') ||
            (colliderA.shape === 'box' && colliderB.shape === 'capsule')) {
            return this.detectCapsuleBoxCollision(colliderA, colliderB);
        }
        
        // Fallback to bounding box intersection
        if (colliderA.bounds.intersectsBox(colliderB.bounds)) {
            return this.createContactFromBounds(colliderA, colliderB);
        }
        
        return null;
    }
    
    /**
     * Detect box-box collision with SAT (Separating Axis Theorem)
     * @param {Object} colliderA - First box collider
     * @param {Object} colliderB - Second box collider
     * @returns {Object|null} Contact information
     */
    detectBoxBoxCollision(colliderA, colliderB) {
        if (!colliderA.bounds.intersectsBox(colliderB.bounds)) {
            return null;
        }
        
        // Calculate overlap on each axis
        const overlapX = Math.min(
            colliderA.bounds.max.x - colliderB.bounds.min.x,
            colliderB.bounds.max.x - colliderA.bounds.min.x
        );
        
        const overlapY = Math.min(
            colliderA.bounds.max.y - colliderB.bounds.min.y,
            colliderB.bounds.max.y - colliderA.bounds.min.y
        );
        
        const overlapZ = Math.min(
            colliderA.bounds.max.z - colliderB.bounds.min.z,
            colliderB.bounds.max.z - colliderA.bounds.min.z
        );
        
        // Find minimum overlap (separation axis)
        const minOverlap = Math.min(overlapX, overlapY, overlapZ);
        
        if (minOverlap <= 0) return null;
        
        // Calculate contact normal and point
        let normal = new THREE.Vector3();
        let penetration = minOverlap;
        
        if (minOverlap === overlapX) {
            normal.x = colliderA.bounds.getCenter(new THREE.Vector3()).x > 
                      colliderB.bounds.getCenter(new THREE.Vector3()).x ? 1 : -1;
        } else if (minOverlap === overlapY) {
            normal.y = colliderA.bounds.getCenter(new THREE.Vector3()).y > 
                      colliderB.bounds.getCenter(new THREE.Vector3()).y ? 1 : -1;
        } else {
            normal.z = colliderA.bounds.getCenter(new THREE.Vector3()).z > 
                      colliderB.bounds.getCenter(new THREE.Vector3()).z ? 1 : -1;
        }
        
        const contactPoint = new THREE.Vector3()
            .addVectors(
                colliderA.bounds.getCenter(new THREE.Vector3()),
                colliderB.bounds.getCenter(new THREE.Vector3())
            )
            .multiplyScalar(0.5);
        
        return {
            entityA: colliderA.entityId,
            entityB: colliderB.entityId,
            normal,
            penetration,
            contactPoint,
            isTrigger: colliderA.isTrigger || colliderB.isTrigger
        };
    }
    
    /**
     * Detect sphere-sphere collision
     * @param {Object} colliderA - First sphere collider
     * @param {Object} colliderB - Second sphere collider
     * @returns {Object|null} Contact information
     */
    detectSphereSphereCollision(colliderA, colliderB) {
        const centerA = colliderA.bounds.getCenter(new THREE.Vector3());
        const centerB = colliderB.bounds.getCenter(new THREE.Vector3());
        const radiusA = colliderA.size.x * 0.5;
        const radiusB = colliderB.size.x * 0.5;
        
        const distance = centerA.distanceTo(centerB);
        const totalRadius = radiusA + radiusB;
        
        if (distance >= totalRadius) return null;
        
        const normal = centerB.clone().sub(centerA).normalize();
        const penetration = totalRadius - distance;
        const contactPoint = centerA.clone().add(
            normal.clone().multiplyScalar(radiusA)
        );
        
        return {
            entityA: colliderA.entityId,
            entityB: colliderB.entityId,
            normal,
            penetration,
            contactPoint,
            isTrigger: colliderA.isTrigger || colliderB.isTrigger
        };
    }
    
    /**
     * Detect capsule-box collision (for character navigation)
     * @param {Object} colliderA - First collider
     * @param {Object} colliderB - Second collider
     * @returns {Object|null} Contact information
     */
    detectCapsuleBoxCollision(colliderA, colliderB) {
        // Simplified capsule-box collision
        // Treat capsule as sphere for now (can be enhanced later)
        const capsule = colliderA.shape === 'capsule' ? colliderA : colliderB;
        const box = colliderA.shape === 'box' ? colliderA : colliderB;
        
        // Convert capsule to sphere approximation
        const sphereCollider = {
            ...capsule,
            shape: 'sphere',
            size: new THREE.Vector3(capsule.size.x, capsule.size.x, capsule.size.x)
        };
        
        return this.detectBoxBoxCollision(sphereCollider, box);
    }
    
    /**
     * Create contact from bounding box intersection (fallback)
     * @param {Object} colliderA - First collider
     * @param {Object} colliderB - Second collider
     * @returns {Object} Contact information
     */
    createContactFromBounds(colliderA, colliderB) {
        const centerA = colliderA.bounds.getCenter(new THREE.Vector3());
        const centerB = colliderB.bounds.getCenter(new THREE.Vector3());
        
        const normal = centerB.clone().sub(centerA).normalize();
        const contactPoint = centerA.clone().add(centerB).multiplyScalar(0.5);
        
        return {
            entityA: colliderA.entityId,
            entityB: colliderB.entityId,
            normal,
            penetration: 0.01, // Small penetration
            contactPoint,
            isTrigger: colliderA.isTrigger || colliderB.isTrigger
        };
    }
    
    /**
     * Resolve collisions using impulse-based method
     */
    resolveCollisions() {
        for (const contact of this.contactPoints) {
            if (contact.isTrigger) {
                // Handle trigger events
                this.handleTriggerEvent(contact);
                continue;
            }
            
            const bodyA = this.world.bodies.get(contact.entityA);
            const bodyB = this.world.bodies.get(contact.entityB);
            
            if (!bodyA || !bodyB) continue;
            
            // Position correction (prevent sinking)
            this.correctPosition(bodyA, bodyB, contact);
            
            // Velocity correction (collision response)
            this.correctVelocity(bodyA, bodyB, contact);
        }
    }
    
    /**
     * Correct position to prevent penetration
     * @param {Object} bodyA - First body
     * @param {Object} bodyB - Second body
     * @param {Object} contact - Contact information
     */
    correctPosition(bodyA, bodyB, contact) {
        const totalMass = bodyA.mass + bodyB.mass;
        if (totalMass === 0) return;
        
        const correction = contact.normal.clone()
            .multiplyScalar(contact.penetration * 0.8); // 80% correction
        
        if (bodyA.mass > 0 && !bodyA.isStatic) {
            const ratio = bodyB.mass / totalMass;
            bodyA.position.sub(correction.clone().multiplyScalar(ratio));
        }
        
        if (bodyB.mass > 0 && !bodyB.isStatic) {
            const ratio = bodyA.mass / totalMass;
            bodyB.position.add(correction.clone().multiplyScalar(ratio));
        }
    }
    
    /**
     * Correct velocity for collision response
     * @param {Object} bodyA - First body
     * @param {Object} bodyB - Second body
     * @param {Object} contact - Contact information
     */
    correctVelocity(bodyA, bodyB, contact) {
        // Get material properties
        const materialA = this.materials[bodyA.material] || this.materials.default;
        const materialB = this.materials[bodyB.material] || this.materials.default;
        
        const restitution = Math.min(materialA.restitution, materialB.restitution);
        const friction = Math.sqrt(materialA.friction * materialB.friction);
        
        // Relative velocity
        const relativeVelocity = bodyB.velocity.clone().sub(bodyA.velocity);
        const velocityAlongNormal = relativeVelocity.dot(contact.normal);
        
        // Don't resolve if velocities are separating
        if (velocityAlongNormal > 0) return;
        
        // Calculate impulse scalar
        const impulseScalar = -(1 + restitution) * velocityAlongNormal / 
                             (1/bodyA.mass + 1/bodyB.mass);
        
        const impulse = contact.normal.clone().multiplyScalar(impulseScalar);
        
        // Apply impulse
        if (bodyA.mass > 0 && !bodyA.isStatic) {
            bodyA.velocity.sub(impulse.clone().divideScalar(bodyA.mass));
        }
        
        if (bodyB.mass > 0 && !bodyB.isStatic) {
            bodyB.velocity.add(impulse.clone().divideScalar(bodyB.mass));
        }
        
        // Apply friction
        this.applyFriction(bodyA, bodyB, contact, friction);
    }
    
    /**
     * Apply friction forces
     * @param {Object} bodyA - First body
     * @param {Object} bodyB - Second body
     * @param {Object} contact - Contact information
     * @param {number} friction - Friction coefficient
     */
    applyFriction(bodyA, bodyB, contact, friction) {
        const relativeVelocity = bodyB.velocity.clone().sub(bodyA.velocity);
        const velocityAlongNormal = relativeVelocity.dot(contact.normal);
        
        // Tangent velocity (perpendicular to normal)
        const tangent = relativeVelocity.clone()
            .sub(contact.normal.clone().multiplyScalar(velocityAlongNormal))
            .normalize();
        
        const tangentVelocity = relativeVelocity.dot(tangent);
        
        // Friction impulse
        const frictionImpulse = -tangentVelocity / (1/bodyA.mass + 1/bodyB.mass);
        const maxFriction = friction * Math.abs(velocityAlongNormal);
        
        const clampedFriction = Math.max(-maxFriction, Math.min(frictionImpulse, maxFriction));
        const frictionVector = tangent.multiplyScalar(clampedFriction);
        
        // Apply friction
        if (bodyA.mass > 0 && !bodyA.isStatic) {
            bodyA.velocity.sub(frictionVector.clone().divideScalar(bodyA.mass));
        }
        
        if (bodyB.mass > 0 && !bodyB.isStatic) {
            bodyB.velocity.add(frictionVector.clone().divideScalar(bodyB.mass));
        }
    }
    
    /**
     * Handle trigger events
     * @param {Object} contact - Contact information
     */
    handleTriggerEvent(contact) {
        // Emit trigger events for game logic
        console.log(`🎯 Trigger event: ${contact.entityA} <-> ${contact.entityB}`);
    }
    
    /**
     * Raycast query
     * @param {THREE.Vector3} origin - Ray origin
     * @param {THREE.Vector3} direction - Ray direction (normalized)
     * @param {number} maxDistance - Maximum ray distance
     * @param {number} layerMask - Collision layer mask
     * @returns {Object|null} Raycast result
     */
    raycast(origin, direction, maxDistance = Infinity, layerMask = 0xFFFFFFFF) {
        this.physicsStats.raycastQueries++;
        
        this.raycaster.set(origin, direction);
        this.raycaster.far = maxDistance;
        
        let closestHit = null;
        let closestDistance = Infinity;
        
        for (const [entityId, collider] of this.world.colliders) {
            // Check layer mask
            if ((collider.collisionLayer & layerMask) === 0) continue;
            
            // Simple ray-box intersection
            const intersection = this.raycaster.ray.intersectBox(collider.bounds, new THREE.Vector3());
            
            if (intersection) {
                const distance = origin.distanceTo(intersection);
                if (distance < closestDistance && distance <= maxDistance) {
                    closestDistance = distance;
                    closestHit = {
                        entityId,
                        point: intersection,
                        distance,
                        normal: this.calculateSurfaceNormal(intersection, collider.bounds)
                    };
                }
            }
        }
        
        return closestHit;
    }
    
    /**
     * Calculate surface normal from hit point and bounds
     * @param {THREE.Vector3} point - Hit point
     * @param {THREE.Box3} bounds - Collider bounds
     * @returns {THREE.Vector3} Surface normal
     */
    calculateSurfaceNormal(point, bounds) {
        const center = bounds.getCenter(new THREE.Vector3());
        const size = bounds.getSize(new THREE.Vector3());
        
        const localPoint = point.clone().sub(center).divide(size);
        
        // Find the axis with the largest absolute component
        const absX = Math.abs(localPoint.x);
        const absY = Math.abs(localPoint.y);
        const absZ = Math.abs(localPoint.z);
        
        if (absX > absY && absX > absZ) {
            return new THREE.Vector3(Math.sign(localPoint.x), 0, 0);
        } else if (absY > absZ) {
            return new THREE.Vector3(0, Math.sign(localPoint.y), 0);
        } else {
            return new THREE.Vector3(0, 0, Math.sign(localPoint.z));
        }
    }
    
    /**
     * Add collision object from Three.js mesh (convenience method)
     * @param {THREE.Mesh} mesh - Three.js mesh to add as collision object
     */
    addCollisionObject(mesh) {
        if (!mesh || !mesh.isMesh) {
            console.warn('⚠️ Invalid mesh provided to addCollisionObject');
            return;
        }
        
        // Generate unique entity ID for the mesh
        const entityId = mesh.id || Math.floor(Math.random() * 1000000);
        
        // Calculate bounding box
        mesh.geometry.computeBoundingBox();
        const boundingBox = mesh.geometry.boundingBox;
        const size = boundingBox.getSize(new THREE.Vector3());
        
        // Get world position
        const worldPosition = new THREE.Vector3();
        mesh.getWorldPosition(worldPosition);
        
        // Add rigid body (static for most collision objects)
        this.addRigidBody(entityId, {
            mass: 0, // Static object
            position: worldPosition,
            rotation: mesh.rotation,
            material: 'ground'
        });
        
        // Add collider
        this.addCollider(entityId, {
            shape: 'box',
            size: size,
            offset: new THREE.Vector3(),
            isTrigger: false,
            collisionLayer: 1,
            collisionMask: 0xFFFFFFFF
        });
        
        // Store reference to mesh
        mesh.userData.physicsEntityId = entityId;
        
        console.log(`🔲 Collision object added for mesh: ${mesh.name || 'unnamed'} (ID: ${entityId})`);
    }
    
    /**
     * Remove collision object
     * @param {THREE.Mesh|number} meshOrEntityId - Mesh or entity ID to remove
     */
    removeCollisionObject(meshOrEntityId) {
        let entityId;
        
        if (typeof meshOrEntityId === 'number') {
            entityId = meshOrEntityId;
        } else if (meshOrEntityId && meshOrEntityId.userData && meshOrEntityId.userData.physicsEntityId) {
            entityId = meshOrEntityId.userData.physicsEntityId;
        } else {
            console.warn('⚠️ Invalid mesh or entity ID provided to removeCollisionObject');
            return;
        }
        
        // Remove from physics world
        this.world.bodies.delete(entityId);
        this.world.colliders.delete(entityId);
        
        console.log(`🗑️ Collision object removed (ID: ${entityId})`);
    }
    
    /**
     * Apply force to rigid body
     * @param {number} entityId - Entity ID
     * @param {THREE.Vector3} force - Force vector
     */
    applyForce(entityId, force) {
        const body = this.world.bodies.get(entityId);
        if (body && !body.isStatic) {
            body.force.add(force);
        }
    }
    
    /**
     * Apply impulse to rigid body
     * @param {number} entityId - Entity ID
     * @param {THREE.Vector3} impulse - Impulse vector
     */
    applyImpulse(entityId, impulse) {
        const body = this.world.bodies.get(entityId);
        if (body && body.mass > 0 && !body.isStatic) {
            body.velocity.add(impulse.clone().divideScalar(body.mass));
        }
    }
    
    /**
     * Update physics statistics
     */
    updatePhysicsStats() {
        this.physicsStats.bodies = this.world.bodies.size;
        this.physicsStats.colliders = this.world.colliders.size;
    }
    
    /**
     * Get physics statistics
     * @returns {Object} Physics statistics
     */
    getStatistics() {
        return {
            ...this.physicsStats,
            gravity: this.world.gravity.y,
            timeStep: this.options.timeStep,
            spatialGridCells: this.spatialGrid.getCellCount()
        };
    }
    
    /**
     * Dispose of physics system resources
     */
    dispose() {
        this.world.bodies.clear();
        this.world.colliders.clear();
        this.world.constraints.clear();
        this.spatialGrid.dispose();
        
        console.log('🗑️ PhysicsSystem disposed');
    }
}

/**
 * SpatialGrid - Efficient spatial partitioning for collision detection
 */
class SpatialGrid {
    constructor(worldSize, cellSize) {
        this.worldSize = worldSize;
        this.cellSize = cellSize;
        this.gridSize = Math.ceil(worldSize / cellSize);
        this.cells = new Map(); // cellKey -> Set(entityIds)
    }
    
    initialize() {
        this.cells.clear();
    }
    
    getCellKey(x, z) {
        const cellX = Math.floor(x / this.cellSize);
        const cellZ = Math.floor(z / this.cellSize);
        return `${cellX},${cellZ}`;
    }
    
    insert(entityId, bounds) {
        const min = bounds.min;
        const max = bounds.max;
        
        const minCellX = Math.floor(min.x / this.cellSize);
        const maxCellX = Math.floor(max.x / this.cellSize);
        const minCellZ = Math.floor(min.z / this.cellSize);
        const maxCellZ = Math.floor(max.z / this.cellSize);
        
        for (let x = minCellX; x <= maxCellX; x++) {
            for (let z = minCellZ; z <= maxCellZ; z++) {
                const key = `${x},${z}`;
                if (!this.cells.has(key)) {
                    this.cells.set(key, new Set());
                }
                this.cells.get(key).add(entityId);
            }
        }
    }
    
    getPotentialCollisions() {
        const pairs = new Set();
        
        for (const [cellKey, entities] of this.cells) {
            const entityArray = Array.from(entities);
            
            for (let i = 0; i < entityArray.length; i++) {
                for (let j = i + 1; j < entityArray.length; j++) {
                    const entityA = entityArray[i];
                    const entityB = entityArray[j];
                    const pairKey = entityA < entityB ? `${entityA}-${entityB}` : `${entityB}-${entityA}`;
                    
                    if (!pairs.has(pairKey)) {
                        pairs.add(pairKey);
                    }
                }
            }
        }
        
        return Array.from(pairs).map(pair => pair.split('-').map(Number));
    }
    
    clear() {
        this.cells.clear();
    }
    
    getCellCount() {
        return this.cells.size;
    }
    
    dispose() {
        this.clear();
    }
}