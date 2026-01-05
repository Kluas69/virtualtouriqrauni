/**
 * Scene - Main Three.js scene setup and management
 */

import * as THREE from 'three';

export class Scene {
    constructor(options = {}) {
        this.options = {
            backgroundColor: 0x87CEEB, // Sky blue
            enableShadows: true,
            shadowMapType: THREE.PCFSoftShadowMap,
            enableFog: false,
            fogColor: 0x87CEEB,
            fogNear: 10,
            fogFar: 100,
            ...options
        };
        
        this.scene = new THREE.Scene();
        this.lights = [];
        
        this.setupScene();
        this.setupLighting();
        
        console.log('✅ Scene initialized');
    }

    /**
     * Setup basic scene properties
     */
    setupScene() {
        // Set background color
        this.scene.background = new THREE.Color(this.options.backgroundColor);
        
        // Add fog if enabled
        if (this.options.enableFog) {
            this.scene.fog = new THREE.Fog(
                this.options.fogColor,
                this.options.fogNear,
                this.options.fogFar
            );
        }
    }

    /**
     * Setup scene lighting
     */
    setupLighting() {
        // Ambient light for overall illumination
        const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
        ambientLight.name = 'AmbientLight';
        this.scene.add(ambientLight);
        this.lights.push(ambientLight);

        // Directional light (main light source - sun)
        const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
        directionalLight.name = 'DirectionalLight';
        directionalLight.position.set(10, 10, 5);
        
        if (this.options.enableShadows) {
            directionalLight.castShadow = true;
            
            // Optimize shadow map for performance
            directionalLight.shadow.mapSize.width = 1024;
            directionalLight.shadow.mapSize.height = 1024;
            directionalLight.shadow.camera.near = 0.5;
            directionalLight.shadow.camera.far = 50;
            directionalLight.shadow.camera.left = -20;
            directionalLight.shadow.camera.right = 20;
            directionalLight.shadow.camera.top = 20;
            directionalLight.shadow.camera.bottom = -20;
        }
        
        this.scene.add(directionalLight);
        this.lights.push(directionalLight);

        // Hemisphere light for better ambient lighting
        const hemisphereLight = new THREE.HemisphereLight(0x87CEEB, 0x444444, 0.4);
        hemisphereLight.name = 'HemisphereLight';
        this.scene.add(hemisphereLight);
        this.lights.push(hemisphereLight);

        console.log(`✅ Lighting setup complete (${this.lights.length} lights)`);
    }

    /**
     * Add object to scene
     * @param {THREE.Object3D} object - Object to add
     */
    add(object) {
        this.scene.add(object);
    }

    /**
     * Remove object from scene
     * @param {THREE.Object3D} object - Object to remove
     */
    remove(object) {
        this.scene.remove(object);
    }

    /**
     * Get the Three.js scene object
     * @returns {THREE.Scene} The scene object
     */
    getScene() {
        return this.scene;
    }

    /**
     * Set background color
     * @param {number} color - Hex color value
     */
    setBackgroundColor(color) {
        this.options.backgroundColor = color;
        this.scene.background = new THREE.Color(color);
    }

    /**
     * Enable/disable fog
     * @param {boolean} enabled - Whether fog should be enabled
     */
    setFogEnabled(enabled) {
        this.options.enableFog = enabled;
        
        if (enabled) {
            this.scene.fog = new THREE.Fog(
                this.options.fogColor,
                this.options.fogNear,
                this.options.fogFar
            );
        } else {
            this.scene.fog = null;
        }
    }

    /**
     * Set fog parameters
     * @param {number} color - Fog color
     * @param {number} near - Fog near distance
     * @param {number} far - Fog far distance
     */
    setFogParameters(color, near, far) {
        this.options.fogColor = color;
        this.options.fogNear = near;
        this.options.fogFar = far;
        
        if (this.scene.fog) {
            this.scene.fog.color.setHex(color);
            this.scene.fog.near = near;
            this.scene.fog.far = far;
        }
    }

    /**
     * Update lighting intensity
     * @param {string} lightName - Name of light to update
     * @param {number} intensity - New intensity value
     */
    updateLightIntensity(lightName, intensity) {
        const light = this.lights.find(l => l.name === lightName);
        if (light) {
            light.intensity = intensity;
            console.log(`💡 ${lightName} intensity set to ${intensity}`);
        } else {
            console.warn(`Light not found: ${lightName}`);
        }
    }

    /**
     * Get all lights in scene
     * @returns {THREE.Light[]} Array of lights
     */
    getLights() {
        return [...this.lights];
    }

    /**
     * Get scene statistics
     * @returns {Object} Scene statistics
     */
    getStatistics() {
        let meshCount = 0;
        let triangleCount = 0;
        let materialCount = 0;
        
        this.scene.traverse((object) => {
            if (object.isMesh) {
                meshCount++;
                if (object.geometry) {
                    const geometry = object.geometry;
                    if (geometry.index) {
                        triangleCount += geometry.index.count / 3;
                    } else {
                        triangleCount += geometry.attributes.position.count / 3;
                    }
                }
                if (object.material) {
                    materialCount++;
                }
            }
        });
        
        return {
            meshCount,
            triangleCount: Math.floor(triangleCount),
            materialCount,
            lightCount: this.lights.length,
            objectCount: this.scene.children.length
        };
    }

    /**
     * Dispose of resources
     */
    dispose() {
        // Dispose of all objects in scene
        this.scene.traverse((object) => {
            if (object.geometry) {
                object.geometry.dispose();
            }
            if (object.material) {
                if (Array.isArray(object.material)) {
                    object.material.forEach(material => material.dispose());
                } else {
                    object.material.dispose();
                }
            }
        });
        
        // Clear scene
        this.scene.clear();
        this.lights = [];
        
        console.log('🗑️ Scene disposed');
    }
}