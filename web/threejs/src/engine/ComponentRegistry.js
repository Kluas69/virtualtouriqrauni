/**
 * ComponentRegistry - Professional component type registry
 * Manages component definitions and factory methods
 */

export class ComponentRegistry {
    constructor() {
        this.components = new Map(); // componentType -> ComponentClass
        this.componentFactories = new Map(); // componentType -> factory function
        
        // Register built-in components
        this.registerBuiltInComponents();
        
        console.log('📋 ComponentRegistry initialized');
    }
    
    /**
     * Register built-in component types
     */
    registerBuiltInComponents() {
        // Transform component (position, rotation, scale)
        this.registerComponent('Transform', class Transform {
            constructor(data = {}) {
                this.position = data.position || { x: 0, y: 0, z: 0 };
                this.rotation = data.rotation || { x: 0, y: 0, z: 0 };
                this.scale = data.scale || { x: 1, y: 1, z: 1 };
                this.dirty = true;
            }
            
            setPosition(x, y, z) {
                this.position.x = x;
                this.position.y = y;
                this.position.z = z;
                this.dirty = true;
            }
            
            setRotation(x, y, z) {
                this.rotation.x = x;
                this.rotation.y = y;
                this.rotation.z = z;
                this.dirty = true;
            }
            
            setScale(x, y, z) {
                this.scale.x = x;
                this.scale.y = y;
                this.scale.z = z;
                this.dirty = true;
            }
        });
        
        // Mesh component (3D visual representation)
        this.registerComponent('Mesh', class Mesh {
            constructor(data = {}) {
                this.geometry = data.geometry || null;
                this.material = data.material || null;
                this.mesh = data.mesh || null;
                this.visible = data.visible !== false;
                this.castShadow = data.castShadow || false;
                this.receiveShadow = data.receiveShadow || false;
            }
            
            setVisible(visible) {
                this.visible = visible;
                if (this.mesh) {
                    this.mesh.visible = visible;
                }
            }
            
            dispose() {
                if (this.geometry) this.geometry.dispose();
                if (this.material) {
                    if (Array.isArray(this.material)) {
                        this.material.forEach(mat => mat.dispose());
                    } else {
                        this.material.dispose();
                    }
                }
            }
        });
        
        // RigidBody component (physics body)
        this.registerComponent('RigidBody', class RigidBody {
            constructor(data = {}) {
                this.mass = data.mass || 0; // 0 = static body
                this.velocity = data.velocity || { x: 0, y: 0, z: 0 };
                this.angularVelocity = data.angularVelocity || { x: 0, y: 0, z: 0 };
                this.friction = data.friction || 0.5;
                this.restitution = data.restitution || 0.3;
                this.isKinematic = data.isKinematic || false;
                this.body = null; // Physics engine body
            }
            
            applyForce(force) {
                if (this.body && this.body.applyForce) {
                    this.body.applyForce(force);
                }
            }
            
            applyImpulse(impulse) {
                if (this.body && this.body.applyImpulse) {
                    this.body.applyImpulse(impulse);
                }
            }
        });
        
        // Collider component (collision detection)
        this.registerComponent('Collider', class Collider {
            constructor(data = {}) {
                this.shape = data.shape || 'box'; // box, sphere, capsule, mesh
                this.size = data.size || { x: 1, y: 1, z: 1 };
                this.offset = data.offset || { x: 0, y: 0, z: 0 };
                this.isTrigger = data.isTrigger || false;
                this.collisionLayer = data.collisionLayer || 0;
                this.collisionMask = data.collisionMask || 0xFFFFFFFF;
                this.collider = null; // Physics engine collider
            }
        });
        
        // PlayerController component (player-specific logic)
        this.registerComponent('PlayerController', class PlayerController {
            constructor(data = {}) {
                this.moveSpeed = data.moveSpeed || 5.0;
                this.runSpeed = data.runSpeed || 8.0;
                this.jumpHeight = data.jumpHeight || 8.0;
                this.isGrounded = false;
                this.isRunning = false;
                this.inputVector = { x: 0, y: 0 };
                this.cameraMode = data.cameraMode || 'first-person';
            }
            
            setInput(x, y) {
                this.inputVector.x = x;
                this.inputVector.y = y;
            }
            
            jump() {
                return this.isGrounded;
            }
        });
        
        // Camera component (camera properties)
        this.registerComponent('Camera', class Camera {
            constructor(data = {}) {
                this.fov = data.fov || 75;
                this.near = data.near || 0.1;
                this.far = data.far || 1000;
                this.camera = null; // Three.js camera
                this.isActive = data.isActive !== false;
            }
            
            setFOV(fov) {
                this.fov = fov;
                if (this.camera) {
                    this.camera.fov = fov;
                    this.camera.updateProjectionMatrix();
                }
            }
        });
        
        // Light component (lighting)
        this.registerComponent('Light', class Light {
            constructor(data = {}) {
                this.type = data.type || 'directional'; // directional, point, spot, ambient
                this.color = data.color || 0xffffff;
                this.intensity = data.intensity || 1.0;
                this.castShadow = data.castShadow || false;
                this.light = null; // Three.js light
            }
            
            setIntensity(intensity) {
                this.intensity = intensity;
                if (this.light) {
                    this.light.intensity = intensity;
                }
            }
        });
        
        // Animation component (animation state)
        this.registerComponent('Animation', class Animation {
            constructor(data = {}) {
                this.clips = data.clips || [];
                this.currentClip = data.currentClip || null;
                this.mixer = null; // Three.js AnimationMixer
                this.actions = new Map();
                this.isPlaying = false;
                this.loop = data.loop !== false;
            }
            
            play(clipName) {
                const action = this.actions.get(clipName);
                if (action) {
                    action.play();
                    this.currentClip = clipName;
                    this.isPlaying = true;
                }
            }
            
            stop() {
                if (this.mixer) {
                    this.mixer.stopAllAction();
                    this.isPlaying = false;
                }
            }
            
            update(deltaTime) {
                if (this.mixer && this.isPlaying) {
                    this.mixer.update(deltaTime / 1000); // Convert to seconds
                }
            }
        });
        
        console.log('✅ Built-in components registered');
    }
    
    /**
     * Register a component type
     * @param {string} name - Component type name
     * @param {Function} ComponentClass - Component class constructor
     */
    registerComponent(name, ComponentClass) {
        if (this.components.has(name)) {
            console.warn(`⚠️ Component type '${name}' already registered, overwriting`);
        }
        
        this.components.set(name, ComponentClass);
        console.log(`📋 Component registered: ${name}`);
    }
    
    /**
     * Register a component factory function
     * @param {string} name - Component type name
     * @param {Function} factory - Factory function
     */
    registerComponentFactory(name, factory) {
        this.componentFactories.set(name, factory);
        console.log(`🏭 Component factory registered: ${name}`);
    }
    
    /**
     * Get component class by name
     * @param {string} name - Component type name
     * @returns {Function|null} Component class
     */
    getComponent(name) {
        return this.components.get(name) || null;
    }
    
    /**
     * Get component factory by name
     * @param {string} name - Component type name
     * @returns {Function|null} Factory function
     */
    getComponentFactory(name) {
        return this.componentFactories.get(name) || null;
    }
    
    /**
     * Create component instance
     * @param {string} name - Component type name
     * @param {Object} data - Component data
     * @returns {Object|null} Component instance
     */
    createComponent(name, data = {}) {
        const ComponentClass = this.getComponent(name);
        if (ComponentClass) {
            return new ComponentClass(data);
        }
        
        const factory = this.getComponentFactory(name);
        if (factory) {
            return factory(data);
        }
        
        console.warn(`⚠️ Unknown component type: ${name}`);
        return null;
    }
    
    /**
     * Check if component type is registered
     * @param {string} name - Component type name
     * @returns {boolean} Whether component is registered
     */
    hasComponent(name) {
        return this.components.has(name) || this.componentFactories.has(name);
    }
    
    /**
     * Get all registered component names
     * @returns {string[]} Array of component names
     */
    getComponentNames() {
        const names = new Set();
        
        for (const name of this.components.keys()) {
            names.add(name);
        }
        
        for (const name of this.componentFactories.keys()) {
            names.add(name);
        }
        
        return Array.from(names);
    }
    
    /**
     * Unregister a component type
     * @param {string} name - Component type name
     */
    unregisterComponent(name) {
        this.components.delete(name);
        this.componentFactories.delete(name);
        console.log(`🗑️ Component unregistered: ${name}`);
    }
    
    /**
     * Get registry statistics
     * @returns {Object} Registry statistics
     */
    getStatistics() {
        return {
            componentTypes: this.components.size,
            factoryTypes: this.componentFactories.size,
            totalTypes: this.components.size + this.componentFactories.size,
            registeredComponents: this.getComponentNames()
        };
    }
    
    /**
     * Clear all registered components
     */
    clear() {
        this.components.clear();
        this.componentFactories.clear();
        console.log('🧹 ComponentRegistry cleared');
    }
    
    /**
     * Dispose of registry resources
     */
    dispose() {
        this.clear();
        console.log('🗑️ ComponentRegistry disposed');
    }
}