/**
 * Professional Model Loader
 * Handles GLB/GLTF loading with optimization and caching
 */

import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { DRACOLoader } from 'three/examples/jsm/loaders/DRACOLoader.js';
import { EventEmitter } from '../utils/EventEmitter.js';

export class ModelLoader extends EventEmitter {
    constructor(options = {}) {
        super();
        
        this.options = {
            enableDraco: true,
            dracoPath: 'https://www.gstatic.com/draco/versioned/decoders/1.5.6/',
            maxCacheSize: 150, // MB
            enableOptimization: true,
            timeout: 30000, // 30 seconds
            ...options
        };
        
        // Loaders
        this.gltfLoader = null;
        this.dracoLoader = null;
        
        // Cache management
        this.cache = new Map();
        this.cacheSize = 0; // MB
        this.loadingPromises = new Map();
        
        this.init();
    }
    
    init() {
        console.log('📦 Initializing Model Loader...');
        
        // Setup GLTF loader
        this.gltfLoader = new GLTFLoader();
        
        // Setup Draco loader for compression
        if (this.options.enableDraco) {
            this.dracoLoader = new DRACOLoader();
            this.dracoLoader.setDecoderPath(this.options.dracoPath);
            this.gltfLoader.setDRACOLoader(this.dracoLoader);
        }
        
        console.log('✅ Model Loader initialized');
    }
    
    async loadModel(url, options = {}) {
        const loadOptions = {
            enableCache: true,
            optimize: this.options.enableOptimization,
            timeout: this.options.timeout,
            ...options
        };
        
        console.log(`📥 Loading model: ${url}`);
        
        // Check cache first
        if (loadOptions.enableCache && this.cache.has(url)) {
            console.log(`💾 Model loaded from cache: ${url}`);
            const cached = this.cache.get(url);
            this.emit('loaded', { url, model: cached.model, fromCache: true });
            return cached.model.clone();
        }
        
        // Check if already loading
        if (this.loadingPromises.has(url)) {
            console.log(`⏳ Model already loading, waiting: ${url}`);
            return this.loadingPromises.get(url);
        }
        
        // Start loading
        const loadPromise = this._loadModelInternal(url, loadOptions);
        this.loadingPromises.set(url, loadPromise);
        
        try {
            const result = await loadPromise;
            this.loadingPromises.delete(url);
            return result;
        } catch (error) {
            this.loadingPromises.delete(url);
            throw error;
        }
    }
    
    async _loadModelInternal(url, options) {
        return new Promise((resolve, reject) => {
            const startTime = performance.now();
            let timeoutId;
            
            // Setup timeout
            if (options.timeout > 0) {
                timeoutId = setTimeout(() => {
                    reject(new Error(`Model loading timeout: ${url}`));
                }, options.timeout);
            }
            
            // Progress tracking
            const onProgress = (progress) => {
                if (progress.lengthComputable) {
                    const percentComplete = (progress.loaded / progress.total) * 100;
                    this.emit('progress', {
                        url,
                        loaded: progress.loaded,
                        total: progress.total,
                        percent: percentComplete
                    });
                }
            };
            
            // Error handling
            const onError = (error) => {
                if (timeoutId) clearTimeout(timeoutId);
                
                const errorMessage = this._categorizeError(error, url);
                console.error(`❌ Model loading failed: ${url}`, error);
                
                this.emit('error', { url, error: errorMessage, originalError: error });
                reject(new Error(errorMessage));
            };
            
            // Success handling
            const onLoad = (gltf) => {
                if (timeoutId) clearTimeout(timeoutId);
                
                const loadTime = performance.now() - startTime;
                console.log(`✅ Model loaded: ${url} (${loadTime.toFixed(0)}ms)`);
                
                try {
                    // Process the model
                    const processedModel = this._processModel(gltf, options);
                    
                    // Cache the model
                    if (options.enableCache) {
                        this._cacheModel(url, processedModel, gltf);
                    }
                    
                    this.emit('loaded', {
                        url,
                        model: processedModel,
                        loadTime,
                        fromCache: false,
                        gltf
                    });
                    
                    resolve(processedModel);
                } catch (processError) {
                    console.error(`❌ Model processing failed: ${url}`, processError);
                    reject(processError);
                }
            };
            
            // Start loading
            this.gltfLoader.load(url, onLoad, onProgress, onError);
        });
    }
    
    _processModel(gltf, options) {
        const model = gltf.scene;
        
        // Calculate bounding box
        const box = new THREE.Box3().setFromObject(model);
        const center = box.getCenter(new THREE.Vector3());
        const size = box.getSize(new THREE.Vector3());
        
        // Center the model
        model.position.sub(center);
        
        // Auto-scale if needed
        const maxDimension = Math.max(size.x, size.y, size.z);
        if (maxDimension > 20) {
            const scale = 20 / maxDimension;
            model.scale.setScalar(scale);
            console.log(`📏 Model auto-scaled by factor: ${scale.toFixed(2)}`);
        }
        
        // Optimize if enabled
        if (options.optimize) {
            this._optimizeModel(model);
        }
        
        // Setup animations
        if (gltf.animations && gltf.animations.length > 0) {
            const mixer = new THREE.AnimationMixer(model);
            model.userData.mixer = mixer;
            model.userData.animations = gltf.animations;
            
            console.log(`🎬 Model has ${gltf.animations.length} animations`);
        }
        
        // Store metadata
        model.userData.boundingBox = box;
        model.userData.originalSize = size;
        model.userData.center = center;
        
        return model;
    }
    
    _optimizeModel(model) {
        let optimizations = 0;
        
        model.traverse((child) => {
            if (child.isMesh) {
                // Optimize materials
                if (child.material) {
                    if (Array.isArray(child.material)) {
                        child.material.forEach(mat => {
                            if (this._optimizeMaterial(mat)) optimizations++;
                        });
                    } else {
                        if (this._optimizeMaterial(child.material)) optimizations++;
                    }
                }
                
                // Setup shadows conditionally
                if (!this._isMobileDevice()) {
                    child.castShadow = true;
                    child.receiveShadow = true;
                } else {
                    child.castShadow = false;
                    child.receiveShadow = false;
                }
                
                // Optimize geometry
                if (child.geometry) {
                    if (!child.geometry.attributes.normal) {
                        child.geometry.computeVertexNormals();
                    }
                }
            }
        });
        
        if (optimizations > 0) {
            console.log(`⚡ Applied ${optimizations} material optimizations`);
        }
    }
    
    _optimizeMaterial(material) {
        let optimized = false;
        
        // Mobile optimizations
        if (this._isMobileDevice()) {
            // Disable expensive features
            if (material.envMap) {
                material.envMap = null;
                optimized = true;
            }
            if (material.lightMap) {
                material.lightMap = null;
                optimized = true;
            }
            if (material.aoMap) {
                material.aoMap = null;
                optimized = true;
            }
            
            // Optimize texture filtering
            if (material.map) {
                material.map.minFilter = THREE.LinearFilter;
                material.map.magFilter = THREE.LinearFilter;
                material.map.generateMipmaps = false;
                optimized = true;
            }
            
            // Simplify material properties
            if (material.roughness !== undefined) {
                material.roughness = Math.max(material.roughness, 0.5);
                optimized = true;
            }
            if (material.metalness !== undefined) {
                material.metalness = Math.min(material.metalness, 0.5);
                optimized = true;
            }
        }
        
        return optimized;
    }
    
    _cacheModel(url, model, gltf) {
        // Estimate model size
        const estimatedSize = this._estimateModelSize(model);
        
        // Check cache size limit
        if (this.cacheSize + estimatedSize > this.options.maxCacheSize) {
            this._cleanupCache(estimatedSize);
        }
        
        // Cache the model
        this.cache.set(url, {
            model: model.clone(),
            gltf,
            size: estimatedSize,
            timestamp: Date.now()
        });
        
        this.cacheSize += estimatedSize;
        
        console.log(`💾 Model cached: ${url} (${estimatedSize.toFixed(1)}MB, total: ${this.cacheSize.toFixed(1)}MB)`);
    }
    
    _estimateModelSize(model) {
        let size = 0;
        
        model.traverse((child) => {
            if (child.geometry) {
                // Estimate geometry size
                const attributes = child.geometry.attributes;
                Object.keys(attributes).forEach(key => {
                    const attribute = attributes[key];
                    size += attribute.array.byteLength;
                });
            }
            
            if (child.material) {
                const materials = Array.isArray(child.material) ? child.material : [child.material];
                materials.forEach(material => {
                    // Estimate texture sizes
                    Object.keys(material).forEach(key => {
                        const value = material[key];
                        if (value && value.isTexture && value.image) {
                            // Rough estimate: width * height * 4 bytes (RGBA)
                            size += (value.image.width || 512) * (value.image.height || 512) * 4;
                        }
                    });
                });
            }
        });
        
        return size / 1048576; // Convert to MB
    }
    
    _cleanupCache(requiredSize) {
        console.log('🧹 Cleaning up model cache...');
        
        // Sort by timestamp (oldest first)
        const entries = Array.from(this.cache.entries()).sort((a, b) => 
            a[1].timestamp - b[1].timestamp
        );
        
        let freedSize = 0;
        const toRemove = [];
        
        for (const [url, cached] of entries) {
            toRemove.push(url);
            freedSize += cached.size;
            
            // Stop when we have enough space
            if (freedSize >= requiredSize) {
                break;
            }
        }
        
        // Remove old entries
        toRemove.forEach(url => {
            const cached = this.cache.get(url);
            this._disposeModel(cached.model);
            this.cache.delete(url);
            this.cacheSize -= cached.size;
        });
        
        console.log(`🗑️ Freed ${freedSize.toFixed(1)}MB from cache (removed ${toRemove.length} models)`);
    }
    
    _disposeModel(model) {
        model.traverse((child) => {
            if (child.geometry) {
                child.geometry.dispose();
            }
            
            if (child.material) {
                const materials = Array.isArray(child.material) ? child.material : [child.material];
                materials.forEach(material => {
                    // Dispose textures
                    Object.keys(material).forEach(key => {
                        const value = material[key];
                        if (value && value.isTexture) {
                            value.dispose();
                        }
                    });
                    material.dispose();
                });
            }
        });
    }
    
    _categorizeError(error, url) {
        const message = error.message || error.toString();
        
        if (message.includes('404') || message.includes('Not Found')) {
            return `Model file not found: ${url}`;
        }
        
        if (message.includes('CORS') || message.includes('cross-origin')) {
            return `Cross-origin request blocked. Check server CORS configuration.`;
        }
        
        if (message.includes('timeout') || message.includes('Timeout')) {
            return `Model loading timed out. Check your internet connection.`;
        }
        
        if (message.includes('network') || message.includes('Network')) {
            return `Network error while loading model. Check your connection.`;
        }
        
        if (message.includes('JSON') || message.includes('Unexpected token')) {
            return `Model file appears to be corrupted or served as HTML instead of binary GLB format. Check server configuration.`;
        }
        
        if (message.includes('Invalid file format') || message.includes('GLTFLoader')) {
            return `Invalid GLB/GLTF file format. Please check the model file.`;
        }
        
        return `Failed to load model: ${message}`;
    }
    
    _isMobileDevice() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    }
    
    // Public API
    clearCache() {
        console.log('🧹 Clearing model cache...');
        
        this.cache.forEach((cached, url) => {
            this._disposeModel(cached.model);
        });
        
        this.cache.clear();
        this.cacheSize = 0;
        
        console.log('✅ Model cache cleared');
    }
    
    getCacheInfo() {
        return {
            size: this.cacheSize,
            maxSize: this.options.maxCacheSize,
            count: this.cache.size,
            urls: Array.from(this.cache.keys())
        };
    }
    
    preloadModel(url) {
        return this.loadModel(url, { enableCache: true });
    }
    
    dispose() {
        console.log('🧹 Disposing Model Loader...');
        
        // Clear cache
        this.clearCache();
        
        // Dispose loaders
        if (this.dracoLoader) {
            this.dracoLoader.dispose();
        }
        
        // Clear loading promises
        this.loadingPromises.clear();
        
        this.removeAllListeners();
        console.log('✅ Model Loader disposed');
    }
}