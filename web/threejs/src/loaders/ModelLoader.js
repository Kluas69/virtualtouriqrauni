/**
 * ModelLoader - Professional model loading with smart path resolution
 */

import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

export class ModelLoader {
    constructor(options = {}) {
        this.options = {
            enableProgress: true,
            enableRetry: true,
            maxRetries: 3,
            retryDelay: 1000,
            debugMode: false,
            ...options
        };
        
        this.loader = new GLTFLoader();
        this.loadingManager = new THREE.LoadingManager();
        this.deploymentContext = this.detectDeploymentContext();
        
        this.setupLoadingManager();
        
        console.log(`✅ ModelLoader initialized (context: ${this.deploymentContext})`);
    }

    /**
     * Setup loading manager with progress tracking
     */
    setupLoadingManager() {
        this.loadingManager.onStart = (url, itemsLoaded, itemsTotal) => {
            if (this.options.debugMode) {
                console.log('📦 Loading started:', { url, itemsLoaded, itemsTotal });
            }
        };

        this.loadingManager.onProgress = (url, itemsLoaded, itemsTotal) => {
            const progress = (itemsLoaded / itemsTotal) * 100;
            if (this.options.enableProgress) {
                this.updateProgress(progress);
            }
            
            if (this.options.debugMode) {
                console.log(`📊 Loading progress: ${progress.toFixed(1)}%`);
            }
        };

        this.loadingManager.onLoad = () => {
            console.log('✅ All models loaded successfully');
        };

        this.loadingManager.onError = (url) => {
            console.error('❌ Loading error for:', url);
        };
    }

    /**
     * Detect deployment context for smart path resolution
     * @returns {string} Deployment context
     */
    detectDeploymentContext() {
        const url = window.location.href;
        const hostname = window.location.hostname;
        const port = window.location.port;
        
        // Check for local development
        if (hostname === 'localhost' || hostname === '127.0.0.1') {
            if (port === '3000') {
                return 'local-python-server';
            } else if (port && port !== '80' && port !== '443') {
                return 'local-flutter-dev';
            }
            return 'local-development';
        }
        
        // Check for Firebase hosting
        if (hostname.includes('firebase') || hostname.includes('web.app') || hostname.includes('firebaseapp.com')) {
            return 'firebase-hosting';
        }
        
        // Check for GitHub Pages or other static hosting
        if (hostname.includes('github.io') || hostname.includes('netlify') || hostname.includes('vercel')) {
            return 'static-hosting';
        }
        
        // Default to production
        return 'production';
    }

    /**
     * Get model paths based on deployment context
     * @param {string} modelName - Name of the model file
     * @returns {string[]} Array of paths to try
     */
    getModelPaths(modelName) {
        const basePaths = {
            'local-python-server': [
                `./assets/models/${modelName}`,
                `/assets/models/${modelName}`,
                `../assets/models/${modelName}`
            ],
            'local-flutter-dev': [
                `../assets/models/${modelName}`,
                `./assets/models/${modelName}`,
                `../../assets/models/${modelName}`,
                `/assets/models/${modelName}`
            ],
            'firebase-hosting': [
                `/assets/models/${modelName}`,
                `./assets/models/${modelName}`,
                `../assets/models/${modelName}`
            ],
            'static-hosting': [
                `./assets/models/${modelName}`,
                `../assets/models/${modelName}`,
                `/assets/models/${modelName}`
            ],
            'production': [
                `/assets/models/${modelName}`,
                `./assets/models/${modelName}`,
                `../assets/models/${modelName}`
            ]
        };
        
        // Get context-specific paths with universal fallbacks
        const contextPaths = basePaths[this.deploymentContext] || basePaths['production'];
        const fallbackPaths = [
            `../../assets/models/${modelName}`,
            `../../../assets/models/${modelName}`,
            `./${modelName}`,
            `../${modelName}`
        ];
        
        // Combine context-specific paths with fallbacks, removing duplicates
        const allPaths = [...contextPaths, ...fallbackPaths];
        return [...new Set(allPaths)]; // Remove duplicates
    }

    /**
     * Load model with smart path resolution and retry logic
     * @param {string} modelName - Name of the model file (e.g., 'classroom.glb')
     * @param {Object} options - Loading options
     * @returns {Promise} Promise that resolves with loaded model
     */
    async loadModel(modelName, options = {}) {
        const paths = this.getModelPaths(modelName);
        
        console.log(`🔍 Loading ${modelName} with ${paths.length} path options`);
        
        if (this.options.debugMode) {
            console.log('📍 Paths to try:', paths);
        }
        
        return this.tryLoadFromPaths(paths, options);
    }

    /**
     * Try loading from multiple paths with retry logic
     * @param {string[]} paths - Array of paths to try
     * @param {Object} options - Loading options
     * @returns {Promise} Promise that resolves with loaded model
     */
    async tryLoadFromPaths(paths, options = {}) {
        let lastError = null;
        
        for (let i = 0; i < paths.length; i++) {
            const path = paths[i];
            
            try {
                console.log(`🔍 Trying path ${i + 1}/${paths.length}: ${path}`);
                
                const model = await this.loadFromPath(path, options);
                
                console.log(`✅ Successfully loaded from: ${path}`);
                return {
                    model,
                    loadedFrom: path,
                    deploymentContext: this.deploymentContext,
                    pathIndex: i
                };
                
            } catch (error) {
                lastError = error;
                console.warn(`❌ Failed to load from ${path}:`, error.message);
                
                // Small delay before trying next path
                if (i < paths.length - 1) {
                    await this.delay(100);
                }
            }
        }
        
        // All paths failed
        throw new Error(`Failed to load model from any path. Last error: ${lastError?.message}`);
    }

    /**
     * Load model from specific path
     * @param {string} path - Path to model
     * @param {Object} options - Loading options
     * @returns {Promise} Promise that resolves with loaded model
     */
    loadFromPath(path, options = {}) {
        return new Promise((resolve, reject) => {
            const onProgress = (progressEvent) => {
                if (progressEvent.lengthComputable && this.options.enableProgress) {
                    const percentComplete = (progressEvent.loaded / progressEvent.total) * 100;
                    this.updateProgress(percentComplete);
                    
                    if (this.options.debugMode) {
                        console.log(`📊 Progress: ${percentComplete.toFixed(1)}%`);
                    }
                }
            };

            this.loader.load(
                path,
                (gltf) => {
                    // Process loaded model
                    const processedModel = this.processModel(gltf, options);
                    resolve(processedModel);
                },
                onProgress,
                (error) => {
                    reject(error);
                }
            );
        });
    }

    /**
     * Process loaded model (scaling, materials, shadows, etc.)
     * @param {Object} gltf - Loaded GLTF object
     * @param {Object} options - Processing options
     * @returns {Object} Processed model data
     */
    processModel(gltf, options = {}) {
        const model = gltf.scene;
        
        // Center and scale the model
        const box = new THREE.Box3().setFromObject(model);
        const center = box.getCenter(new THREE.Vector3());
        const size = box.getSize(new THREE.Vector3());
        
        // Center the model
        model.position.sub(center);
        
        // Scale if necessary
        const maxDimension = Math.max(size.x, size.y, size.z);
        const targetSize = options.targetSize || 20;
        
        if (maxDimension > targetSize) {
            const scale = targetSize / maxDimension;
            model.scale.setScalar(scale);
            console.log(`📏 Model scaled by factor: ${scale.toFixed(2)}`);
        }
        
        // Process materials and enable shadows
        let meshCount = 0;
        model.traverse((child) => {
            if (child.isMesh) {
                meshCount++;
                
                // Enable shadows
                child.castShadow = options.castShadow !== false;
                child.receiveShadow = options.receiveShadow !== false;
                
                // Optimize materials for performance
                if (child.material) {
                    this.optimizeMaterial(child.material, options);
                }
            }
        });
        
        console.log(`✅ Model processed: ${meshCount} meshes, size: ${size.x.toFixed(1)}×${size.y.toFixed(1)}×${size.z.toFixed(1)}`);
        
        return {
            scene: model,
            animations: gltf.animations || [],
            meshCount,
            boundingBox: box,
            size,
            center
        };
    }

    /**
     * Optimize material for performance
     * @param {THREE.Material} material - Material to optimize
     * @param {Object} options - Optimization options
     */
    optimizeMaterial(material, options = {}) {
        if (Array.isArray(material)) {
            material.forEach(mat => this.optimizeMaterial(mat, options));
            return;
        }
        
        // Disable mipmap generation for better performance
        if (material.map && options.disableMipmaps !== false) {
            material.map.generateMipmaps = false;
        }
        
        // Additional material optimizations can be added here
        if (options.debugMode) {
            console.log('🔧 Material optimized:', material.name || 'unnamed');
        }
    }

    /**
     * Update loading progress
     * @param {number} progress - Progress percentage (0-100)
     */
    updateProgress(progress) {
        // Update progress UI element if it exists
        const progressElement = document.getElementById('progress');
        if (progressElement) {
            progressElement.textContent = `${Math.round(progress)}%`;
        }
        
        // Emit progress event
        if (window.classroomViewer && window.classroomViewer.onLoadingProgress) {
            window.classroomViewer.onLoadingProgress(progress);
        }
    }

    /**
     * Utility delay function
     * @param {number} ms - Milliseconds to delay
     * @returns {Promise} Promise that resolves after delay
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    /**
     * Get deployment context
     * @returns {string} Current deployment context
     */
    getDeploymentContext() {
        return this.deploymentContext;
    }

    /**
     * Dispose of resources
     */
    dispose() {
        this.loader = null;
        this.loadingManager = null;
        
        console.log('🗑️ ModelLoader disposed');
    }
}