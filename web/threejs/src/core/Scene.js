/**
 * Professional Scene Manager
 * Handles Three.js scene with lighting and environment
 */

import * as THREE from 'three';

export class Scene {
    constructor(options = {}) {
        this.options = {
            enableFog: true,
            fogColor: 0x87CEEB,
            fogNear: 0,
            fogFar: 750,
            enableShadows: true,
            backgroundColor: 0x87CEEB,
            ...options
        };
        
        this.scene = null;
        this.lights = [];
        this.objects = new Map();
        this.mixers = [];
        
        this.init();
    }
    
    init() {
        console.log('🌍 Initializing Scene...');
        
        // Create scene
        this.scene = new THREE.Scene();
        
        // Setup environment
        this.setupEnvironment();
        this.setupDefaultLighting();
        
        console.log('✅ Scene initialized');
    }
    
    setupEnvironment() {
        // Background
        this.scene.background = new THREE.Color(this.options.backgroundColor);
        
        // Fog
        if (this.options.enableFog) {
            this.scene.fog = new THREE.Fog(
                this.options.fogColor,
                this.options.fogNear,
                this.options.fogFar
            );
        }
        
        // Ground plane (optional)
        if (!this.isMobileDevice()) {
            this.createGroundPlane();
        }
    }
    
    setupDefaultLighting() {
        // Ambient light
        const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
        ambientLight.name = 'ambient';
        this.scene.add(ambientLight);
        this.lights.push(ambientLight);
        
        // Directional light (sun)
        const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
        directionalLight.position.set(5, 10, 7.5);
        directionalLight.name = 'sun';
        
        // Shadows
        if (this.options.enableShadows && !this.isMobileDevice()) {
            directionalLight.castShadow = true;
            directionalLight.shadow.camera.right = 20;
            directionalLight.shadow.camera.left = -20;
            directionalLight.shadow.camera.top = 20;
            directionalLight.shadow.camera.bottom = -20;
            directionalLight.shadow.mapSize.width = 2048;
            directionalLight.shadow.mapSize.height = 2048;
            directionalLight.shadow.camera.near = 0.1;
            directionalLight.shadow.camera.far = 50;
        }
        
        this.scene.add(directionalLight);
        this.lights.push(directionalLight);
        
        // Hemisphere light for better ambient lighting
        const hemisphereLight = new THREE.HemisphereLight(0x87CEEB, 0x444444, 0.4);
        hemisphereLight.name = 'hemisphere';
        this.scene.add(hemisphereLight);
        this.lights.push(hemisphereLight);
        
        // Additional lights for mobile (simpler setup)
        if (this.isMobileDevice()) {
            // Single point light for mobile
            const pointLight = new THREE.PointLight(0xffffff, 0.5, 100);
            pointLight.position.set(0, 10, 0);
            pointLight.name = 'mobile-point';
            this.scene.add(pointLight);
            this.lights.push(pointLight);
        }
    }
    
    createGroundPlane() {
        const groundGeometry = new THREE.PlaneGeometry(100, 100);
        const groundMaterial = new THREE.MeshStandardMaterial({
            color: 0x808080,
            roughness: 0.8,
            metalness: 0.2
        });
        
        const ground = new THREE.Mesh(groundGeometry, groundMaterial);
        ground.rotation.x = -Math.PI / 2;
        ground.receiveShadow = true;
        ground.name = 'ground';
        
        this.scene.add(ground);
        this.objects.set('ground', ground);
    }
    
    // Object management
    addObject(name, object) {
        if (this.objects.has(name)) {
            console.warn(`Object '${name}' already exists, replacing...`);
            this.removeObject(name);
        }
        
        this.scene.add(object);
        this.objects.set(name, object);
        
        console.log(`➕ Added object: ${name}`);
    }
    
    removeObject(name) {
        const object = this.objects.get(name);
        if (object) {
            this.scene.remove(object);
            this.objects.delete(name);
            
            // Dispose geometry and materials
            this.disposeObject(object);
            
            console.log(`➖ Removed object: ${name}`);
        }
    }
    
    getObject(name) {
        return this.objects.get(name);
    }
    
    hasObject(name) {
        return this.objects.has(name);
    }
    
    // Animation management
    addMixer(mixer) {
        this.mixers.push(mixer);
    }
    
    removeMixer(mixer) {
        const index = this.mixers.indexOf(mixer);
        if (index > -1) {
            this.mixers.splice(index, 1);
        }
    }
    
    // Lighting control
    setAmbientIntensity(intensity) {
        const ambientLight = this.lights.find(light => light.name === 'ambient');
        if (ambientLight) {
            ambientLight.intensity = intensity;
        }
    }
    
    setSunIntensity(intensity) {
        const sunLight = this.lights.find(light => light.name === 'sun');
        if (sunLight) {
            sunLight.intensity = intensity;
        }
    }
    
    setSunPosition(x, y, z) {
        const sunLight = this.lights.find(light => light.name === 'sun');
        if (sunLight) {
            sunLight.position.set(x, y, z);
        }
    }
    
    // Environment control
    setFogDistance(near, far) {
        if (this.scene.fog) {
            this.scene.fog.near = near;
            this.scene.fog.far = far;
        }
    }
    
    setBackgroundColor(color) {
        this.scene.background = new THREE.Color(color);
    }
    
    // Performance optimization
    optimizeForMobile() {
        console.log('📱 Optimizing scene for mobile...');
        
        // Disable shadows
        this.lights.forEach(light => {
            if (light.castShadow) {
                light.castShadow = false;
            }
        });
        
        // Reduce fog distance
        if (this.scene.fog) {
            this.scene.fog.far = Math.min(this.scene.fog.far, 500);
        }
        
        // Optimize materials
        this.scene.traverse((child) => {
            if (child.isMesh && child.material) {
                this.optimizeMaterial(child.material);
            }
        });
    }
    
    optimizeMaterial(material) {
        if (Array.isArray(material)) {
            material.forEach(mat => this.optimizeMaterial(mat));
            return;
        }
        
        // Disable expensive features
        if (material.envMap) material.envMap = null;
        if (material.lightMap) material.lightMap = null;
        if (material.aoMap) material.aoMap = null;
        
        // Optimize texture filtering
        if (material.map) {
            material.map.minFilter = THREE.LinearFilter;
            material.map.magFilter = THREE.LinearFilter;
            material.map.generateMipmaps = false;
        }
        
        // Simplify material properties
        if (material.roughness !== undefined) {
            material.roughness = Math.max(material.roughness, 0.5);
        }
        if (material.metalness !== undefined) {
            material.metalness = Math.min(material.metalness, 0.5);
        }
    }
    
    // Update loop
    update(delta, time) {
        // Update animations
        this.mixers.forEach(mixer => {
            mixer.update(delta);
        });
        
        // Update dynamic objects
        this.objects.forEach((object, name) => {
            if (object.userData.update) {
                object.userData.update(delta, time);
            }
        });
    }
    
    // Utility methods
    isMobileDevice() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    }
    
    disposeObject(object) {
        object.traverse((child) => {
            if (child.geometry) {
                child.geometry.dispose();
            }
            
            if (child.material) {
                if (Array.isArray(child.material)) {
                    child.material.forEach(material => {
                        this.disposeMaterial(material);
                    });
                } else {
                    this.disposeMaterial(child.material);
                }
            }
        });
    }
    
    disposeMaterial(material) {
        // Dispose textures
        Object.keys(material).forEach(key => {
            const value = material[key];
            if (value && value.isTexture) {
                value.dispose();
            }
        });
        
        // Dispose material
        material.dispose();
    }
    
    // Model management (for RoomManager compatibility)
    addModel(model) {
        const modelId = `model_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        this.addObject(modelId, model);
        
        // Setup animations if present
        if (model.userData.mixer) {
            this.addMixer(model.userData.mixer);
        }
        
        return modelId;
    }
    
    removeModel(model) {
        // Find and remove the model
        for (const [name, obj] of this.objects.entries()) {
            if (obj === model) {
                this.removeObject(name);
                
                // Remove mixer if present
                if (model.userData.mixer) {
                    this.removeMixer(model.userData.mixer);
                }
                break;
            }
        }
    }
    
    // Hotspot management
    addHotspot(hotspot) {
        if (hotspot.mesh) {
            const hotspotId = `hotspot_${hotspot.id}`;
            this.addObject(hotspotId, hotspot.mesh);
            
            // Add animation if present
            if (hotspot.mesh.userData.animate) {
                hotspot.mesh.userData.update = (delta, time) => {
                    hotspot.mesh.userData.animate(time);
                };
            }
        }
    }
    
    removeHotspot(hotspot) {
        if (hotspot.mesh) {
            const hotspotId = `hotspot_${hotspot.id}`;
            this.removeObject(hotspotId);
        }
    }
    
    // Lighting setup for rooms
    setupLighting(lightingConfig) {
        // Handle undefined or null lightingConfig
        if (!lightingConfig) {
            console.log('💡 No lighting config provided, using default lighting');
            return [];
        }
        
        // Clear existing dynamic lights (keep default lights)
        const dynamicLights = this.lights.filter(light => 
            light.name && light.name.startsWith('room_')
        );
        
        dynamicLights.forEach(light => {
            this.scene.remove(light);
            const index = this.lights.indexOf(light);
            if (index > -1) {
                this.lights.splice(index, 1);
            }
        });
        
        const addedLights = [];
        
        // Add ambient light
        if (lightingConfig.ambient) {
            const ambientLight = new THREE.AmbientLight(
                lightingConfig.ambient.color,
                lightingConfig.ambient.intensity
            );
            ambientLight.name = 'room_ambient';
            this.scene.add(ambientLight);
            this.lights.push(ambientLight);
            addedLights.push(ambientLight);
        }
        
        // Add directional light
        if (lightingConfig.directional) {
            const directionalLight = new THREE.DirectionalLight(
                lightingConfig.directional.color,
                lightingConfig.directional.intensity
            );
            
            if (lightingConfig.directional.position) {
                directionalLight.position.set(
                    lightingConfig.directional.position.x,
                    lightingConfig.directional.position.y,
                    lightingConfig.directional.position.z
                );
            }
            
            // Setup shadows if enabled and not mobile
            if (this.options.enableShadows && !this.isMobileDevice()) {
                directionalLight.castShadow = true;
                directionalLight.shadow.camera.right = 20;
                directionalLight.shadow.camera.left = -20;
                directionalLight.shadow.camera.top = 20;
                directionalLight.shadow.camera.bottom = -20;
                directionalLight.shadow.mapSize.width = 1024;
                directionalLight.shadow.mapSize.height = 1024;
            }
            
            directionalLight.name = 'room_directional';
            this.scene.add(directionalLight);
            this.lights.push(directionalLight);
            addedLights.push(directionalLight);
        }
        
        // Add point lights
        if (lightingConfig.point && Array.isArray(lightingConfig.point)) {
            lightingConfig.point.forEach((pointConfig, index) => {
                const pointLight = new THREE.PointLight(
                    pointConfig.color,
                    pointConfig.intensity,
                    pointConfig.distance || 100
                );
                
                if (pointConfig.position) {
                    pointLight.position.set(
                        pointConfig.position.x,
                        pointConfig.position.y,
                        pointConfig.position.z
                    );
                }
                
                pointLight.name = `room_point_${index}`;
                this.scene.add(pointLight);
                this.lights.push(pointLight);
                addedLights.push(pointLight);
            });
        }
        
        console.log(`💡 Setup ${addedLights.length} room lights`);
        return addedLights;
    }

    // Public API
    getScene() {
        return this.scene;
    }
    
    getLights() {
        return [...this.lights];
    }
    
    getObjects() {
        return new Map(this.objects);
    }
    
    clear() {
        // Remove all objects
        this.objects.forEach((object, name) => {
            this.removeObject(name);
        });
        
        // Clear mixers
        this.mixers.length = 0;
    }
    
    dispose() {
        console.log('🧹 Disposing Scene...');
        
        // Clear all objects
        this.clear();
        
        // Dispose lights
        this.lights.forEach(light => {
            this.scene.remove(light);
        });
        this.lights.length = 0;
        
        // Clear scene
        if (this.scene) {
            this.scene.clear();
            this.scene = null;
        }
        
        console.log('✅ Scene disposed');
    }
}