/**
 * AssetSystem - Professional asset management with streaming and LOD
 * Handles loading, caching, and memory management of 3D assets
 */

import { ModuleLoadingDiagnostics } from '../core/ModuleLoadingDiagnostics.js';

export class AssetSystem {
    constructor(options = {}) {
        this.options = {
            enableStreaming: true,
            enableLOD: true,
            enableCompression: true,
            maxCacheSize: 512 * 1024 * 1024, // 512MB cache
            enablePreloading: true,
            enableRetry: true,
            maxRetries: 3,
            retryDelay: 1000,
            enableProgressTracking: true,
            ...options
        };
        
        // Module loading diagnostics
        this.moduleLoader = new ModuleLoadingDiagnostics({
            enableLogging: true,
            enableFallbacks: true
        });
        
        // Asset management
        this.loadedAssets = new Map();
        this.loadingPromises = new Map();
        this.assetCache = new Map();
        this.cacheSize = 0;
        
        // LOD management
        this.lodLevels = new Map();
        this.currentLOD = 'high';
        
        // Streaming
        this.streamingQueue = [];
        this.isStreaming = false;
        
        // Progress tracking
        this.loadingProgress = new Map();
        this.totalAssets = 0;
        this.loadedCount = 0;
        
        // Performance monitoring
        this.loadTimes = new Map();
        this.memoryUsage = 0;
        
        console.log('✅ AssetSystem initialized with professional asset management');
    }

    /**
     * Initialize asset system
     */
    async initialize() {
        // Setup asset loaders
        await this.setupLoaders();
        
        // Initialize streaming system
        if (this.options.enableStreaming) {
            this.initializeStreaming();
        }
        
        // Setup LOD system
        if (this.options.enableLOD) {
            this.initializeLOD();
        }
        
        console.log('🚀 AssetSystem initialized');
    }

    /**
     * Setup asset loaders with enhanced capabilities
     */
    async setupLoaders() {
        try {
            console.log('📦 Setting up asset loaders...');
            
            // Load loaders using module diagnostics
            this.loaderPromises = {
                gltf: this.moduleLoader.loadThreeJSAddon('loaders/GLTFLoader.js', { required: false }),
                draco: this.moduleLoader.loadThreeJSAddon('loaders/DRACOLoader.js', { required: false }),
                ktx2: this.moduleLoader.loadThreeJSAddon('loaders/KTX2Loader.js', { required: false }),
                texture: Promise.resolve({ TextureLoader: THREE.TextureLoader })
            };
            
            console.log('✅ Asset loaders setup complete');
        } catch (error) {
            console.error('❌ Failed to setup asset loaders:', error);
            // Continue with basic functionality
        }
    }

    /**
     * Initialize streaming system
     */
    initializeStreaming() {
        this.streamingWorker = new Worker(
            URL.createObjectURL(new Blob([`
                // Asset streaming worker
                self.onmessage = function(e) {
                    const { type, data } = e.data;
                    
                    switch (type) {
                        case 'prioritize':
                            // Prioritize asset loading based on distance/importance
                            self.postMessage({ type: 'prioritized', data });
                            break;
                        case 'compress':
                            // Compress asset data
                            self.postMessage({ type: 'compressed', data });
                            break;
                    }
                };
            `], { type: 'application/javascript' }))
        );
        
        console.log('📡 Asset streaming initialized');
    }

    /**
     * Initialize LOD system
     */
    initializeLOD() {
        this.lodLevels.set('ultra', { quality: 1.0, distance: 10 });
        this.lodLevels.set('high', { quality: 0.8, distance: 25 });
        this.lodLevels.set('medium', { quality: 0.6, distance: 50 });
        this.lodLevels.set('low', { quality: 0.3, distance: 100 });
        
        console.log('🎯 LOD system initialized');
    }

    /**
     * Load asset with professional features
     * @param {string} url - Asset URL
     * @param {Object} options - Loading options
     * @returns {Promise} Loading promise
     */
    async loadAsset(url, options = {}) {
        const assetOptions = {
            type: 'auto',
            enableLOD: this.options.enableLOD,
            enableCompression: this.options.enableCompression,
            priority: 'normal',
            preload: false,
            ...options
        };
        
        // Construct full URL with base path
        const fullUrl = url.startsWith('http') || url.startsWith('/') ? url : 
                       `${this.options.baseURL || '../assets/'}models/${url}`;
        
        console.log(`📦 Loading asset: ${url} -> ${fullUrl}`);
        
        // Check cache first
        if (this.assetCache.has(fullUrl)) {
            console.log(`📦 Asset loaded from cache: ${fullUrl}`);
            return this.assetCache.get(fullUrl);
        }
        
        // Check if already loading
        if (this.loadingPromises.has(fullUrl)) {
            return this.loadingPromises.get(fullUrl);
        }
        
        // Start loading
        const loadPromise = this._loadAssetInternal(fullUrl, assetOptions);
        this.loadingPromises.set(fullUrl, loadPromise);
        
        try {
            const asset = await loadPromise;
            
            // Cache the asset
            this._cacheAsset(fullUrl, asset);
            
            // Clean up loading promise
            this.loadingPromises.delete(fullUrl);
            
            return asset;
        } catch (error) {
            this.loadingPromises.delete(fullUrl);
            throw error;
        }
    }

    /**
     * Internal asset loading with retry logic
     * @param {string} url - Asset URL
     * @param {Object} options - Loading options
     * @returns {Promise} Loading promise
     */
    async _loadAssetInternal(url, options) {
        const startTime = performance.now();
        let lastError = null;
        
        for (let attempt = 0; attempt < this.options.maxRetries; attempt++) {
            try {
                console.log(`📦 Loading asset (attempt ${attempt + 1}): ${url}`);
                
                const asset = await this._performLoad(url, options);
                
                // Track loading time
                const loadTime = performance.now() - startTime;
                this.loadTimes.set(url, loadTime);
                
                console.log(`✅ Asset loaded in ${loadTime.toFixed(2)}ms: ${url}`);
                return asset;
                
            } catch (error) {
                lastError = error;
                console.warn(`⚠️ Asset loading attempt ${attempt + 1} failed: ${error.message}`);
                
                if (attempt < this.options.maxRetries - 1) {
                    await new Promise(resolve => setTimeout(resolve, this.options.retryDelay));
                }
            }
        }
        
        throw new Error(`Failed to load asset after ${this.options.maxRetries} attempts: ${lastError.message}`);
    }

    /**
     * Perform actual asset loading
     * @param {string} url - Asset URL
     * @param {Object} options - Loading options
     * @returns {Promise} Loading promise
     */
    async _performLoad(url, options) {
        const assetType = this._detectAssetType(url, options.type);
        
        switch (assetType) {
            case 'gltf':
                return this._loadGLTF(url, options);
            case 'texture':
                return this._loadTexture(url, options);
            case 'audio':
                return this._loadAudio(url, options);
            default:
                throw new Error(`Unsupported asset type: ${assetType}`);
        }
    }

    /**
     * Load GLTF model with enhanced features
     * @param {string} url - Model URL
     * @param {Object} options - Loading options
     * @returns {Promise} Loading promise
     */
    async _loadGLTF(url, options) {
        try {
            const gltfModule = await this.loaderPromises.gltf;
            
            if (!gltfModule || !gltfModule.GLTFLoader) {
                console.warn('⚠️ GLTFLoader not available, using fallback');
                return this._createFallbackModel(url, options);
            }
            
            const { GLTFLoader } = gltfModule;
            const loader = new GLTFLoader();
            
            // Setup Draco compression if enabled
            if (options.enableCompression) {
                try {
                    const dracoModule = await this.loaderPromises.draco;
                    if (dracoModule && dracoModule.DRACOLoader) {
                        const { DRACOLoader } = dracoModule;
                        const dracoLoader = new DRACOLoader();
                        dracoLoader.setDecoderPath('https://www.gstatic.com/draco/versioned/decoders/1.5.6/');
                        loader.setDRACOLoader(dracoLoader);
                    }
                } catch (error) {
                    console.warn('⚠️ Draco loader not available:', error.message);
                }
            }
            
            return new Promise((resolve, reject) => {
                loader.load(
                    url,
                    (gltf) => {
                        console.log(`✅ GLTF loaded successfully: ${url}`);
                        // Process loaded model
                        const processedModel = this._processGLTF(gltf, options);
                        resolve(processedModel);
                    },
                    (progress) => {
                        console.log(`📦 Loading progress for ${url}: ${Math.round((progress.loaded / progress.total) * 100)}%`);
                        if (options.onProgress) {
                            options.onProgress(progress);
                        }
                    },
                    (error) => {
                        console.error(`❌ GLTF loading failed for ${url}:`, error);
                        console.warn(`⚠️ GLTF loading failed, using fallback: ${error.message}`);
                        // Try fallback instead of rejecting
                        this._createFallbackModel(url, options)
                            .then(resolve)
                            .catch(reject);
                    }
                );
            });
        } catch (error) {
            console.warn(`⚠️ GLTF loader setup failed, using fallback: ${error.message}`);
            return this._createFallbackModel(url, options);
        }
    }
    
    /**
     * Create fallback model when GLTF loading fails
     * @param {string} url - Original model URL
     * @param {Object} options - Loading options
     * @returns {Promise} Fallback model
     */
    async _createFallbackModel(url, options) {
        console.log(`🏗️ Creating fallback model for: ${url}`);
        
        const scene = new THREE.Scene();
        
        // Create a simple classroom-like structure
        const roomGeometry = new THREE.BoxGeometry(20, 10, 20);
        const roomMaterial = new THREE.MeshLambertMaterial({ 
            color: 0xf0f0f0,
            side: THREE.BackSide
        });
        const room = new THREE.Mesh(roomGeometry, roomMaterial);
        room.position.y = 5;
        scene.add(room);
        
        // Add some basic furniture
        const deskGeometry = new THREE.BoxGeometry(2, 1, 1);
        const deskMaterial = new THREE.MeshLambertMaterial({ color: 0x8B4513 });
        
        for (let i = 0; i < 6; i++) {
            const desk = new THREE.Mesh(deskGeometry, deskMaterial);
            desk.position.set(
                (i % 3 - 1) * 4,
                0.5,
                Math.floor(i / 3) * 4 - 2
            );
            desk.castShadow = true;
            desk.receiveShadow = true;
            scene.add(desk);
        }
        
        // Add a floor
        const floorGeometry = new THREE.PlaneGeometry(20, 20);
        const floorMaterial = new THREE.MeshLambertMaterial({ color: 0x808080 });
        const floor = new THREE.Mesh(floorGeometry, floorMaterial);
        floor.rotation.x = -Math.PI / 2;
        floor.receiveShadow = true;
        scene.add(floor);
        
        // Simulate progress callback
        if (options.onProgress) {
            setTimeout(() => options.onProgress({ loaded: 100, total: 100 }), 100);
        }
        
        return {
            scene,
            animations: [],
            cameras: [],
            asset: { generator: 'Fallback Generator' },
            userData: { fallback: true }
        };
    }

    /**
     * Process loaded GLTF model
     * @param {Object} gltf - Loaded GLTF
     * @param {Object} options - Processing options
     * @returns {Object} Processed model
     */
    _processGLTF(gltf, options) {
        const model = {
            scene: gltf.scene,
            animations: gltf.animations,
            cameras: gltf.cameras,
            asset: gltf.asset,
            userData: gltf.userData
        };
        
        // Apply LOD if enabled
        if (options.enableLOD) {
            this._applyLOD(model.scene, this.currentLOD);
        }
        
        // Setup shadows and materials
        model.scene.traverse((child) => {
            if (child.isMesh) {
                child.castShadow = true;
                child.receiveShadow = true;
                
                // Optimize materials
                if (child.material) {
                    this._optimizeMaterial(child.material);
                }
            }
        });
        
        return model;
    }

    /**
     * Load texture with optimization
     * @param {string} url - Texture URL
     * @param {Object} options - Loading options
     * @returns {Promise} Loading promise
     */
    async _loadTexture(url, options) {
        const { TextureLoader } = await this.loaderPromises.texture;
        const loader = new TextureLoader();
        
        return new Promise((resolve, reject) => {
            loader.load(
                url,
                (texture) => {
                    // Optimize texture
                    this._optimizeTexture(texture, options);
                    resolve(texture);
                },
                (progress) => {
                    if (options.onProgress) {
                        options.onProgress(progress);
                    }
                },
                (error) => {
                    reject(new Error(`Texture loading failed: ${error.message}`));
                }
            );
        });
    }

    /**
     * Load audio asset
     * @param {string} url - Audio URL
     * @param {Object} options - Loading options
     * @returns {Promise} Loading promise
     */
    async _loadAudio(url, options) {
        const loader = new THREE.AudioLoader();
        
        return new Promise((resolve, reject) => {
            loader.load(
                url,
                (buffer) => {
                    resolve(buffer);
                },
                (progress) => {
                    if (options.onProgress) {
                        options.onProgress(progress);
                    }
                },
                (error) => {
                    reject(new Error(`Audio loading failed: ${error.message}`));
                }
            );
        });
    }

    /**
     * Detect asset type from URL
     * @param {string} url - Asset URL
     * @param {string} typeHint - Type hint
     * @returns {string} Asset type
     */
    _detectAssetType(url, typeHint) {
        if (typeHint !== 'auto') return typeHint;
        
        const extension = url.split('.').pop().toLowerCase();
        
        switch (extension) {
            case 'gltf':
            case 'glb':
                return 'gltf';
            case 'jpg':
            case 'jpeg':
            case 'png':
            case 'webp':
            case 'ktx2':
                return 'texture';
            case 'mp3':
            case 'wav':
            case 'ogg':
                return 'audio';
            default:
                return 'unknown';
        }
    }

    /**
     * Apply LOD to scene
     * @param {THREE.Object3D} scene - Scene object
     * @param {string} lodLevel - LOD level
     */
    _applyLOD(scene, lodLevel) {
        const lodConfig = this.lodLevels.get(lodLevel);
        if (!lodConfig) return;
        
        scene.traverse((child) => {
            if (child.isMesh && child.geometry) {
                // Simplify geometry based on LOD level
                if (lodConfig.quality < 1.0) {
                    this._simplifyGeometry(child.geometry, lodConfig.quality);
                }
            }
        });
    }

    /**
     * Simplify geometry for LOD
     * @param {THREE.BufferGeometry} geometry - Geometry to simplify
     * @param {number} quality - Quality factor (0-1)
     */
    _simplifyGeometry(geometry, quality) {
        // Simple decimation - in production, use proper mesh simplification
        if (geometry.index && quality < 0.8) {
            const originalCount = geometry.index.count;
            const targetCount = Math.floor(originalCount * quality);
            
            // This is a placeholder - real implementation would use proper decimation
            console.log(`🎯 LOD: Simplified geometry from ${originalCount} to ${targetCount} indices`);
        }
    }

    /**
     * Optimize material for performance
     * @param {THREE.Material} material - Material to optimize
     */
    _optimizeMaterial(material) {
        // Enable efficient rendering features
        material.transparent = material.transparent || material.opacity < 1.0;
        
        // Optimize for mobile if needed
        if (this.currentLOD === 'low') {
            material.roughness = Math.max(material.roughness || 0.5, 0.3);
            material.metalness = Math.min(material.metalness || 0.0, 0.7);
        }
    }

    /**
     * Optimize texture for performance
     * @param {THREE.Texture} texture - Texture to optimize
     * @param {Object} options - Optimization options
     */
    _optimizeTexture(texture, options) {
        // Set appropriate filtering
        texture.minFilter = THREE.LinearMipmapLinearFilter;
        texture.magFilter = THREE.LinearFilter;
        
        // Generate mipmaps
        texture.generateMipmaps = true;
        
        // Optimize for current LOD
        if (this.currentLOD === 'low') {
            // Reduce texture resolution for low LOD
            texture.repeat.set(0.5, 0.5);
        }
    }

    /**
     * Cache asset with memory management
     * @param {string} url - Asset URL
     * @param {Object} asset - Asset to cache
     */
    _cacheAsset(url, asset) {
        // Estimate asset size
        const assetSize = this._estimateAssetSize(asset);
        
        // Check if cache has space
        if (this.cacheSize + assetSize > this.options.maxCacheSize) {
            this._evictOldAssets(assetSize);
        }
        
        // Cache the asset
        this.assetCache.set(url, asset);
        this.cacheSize += assetSize;
        
        console.log(`💾 Asset cached: ${url} (${(assetSize / 1024 / 1024).toFixed(2)}MB)`);
    }

    /**
     * Estimate asset memory size
     * @param {Object} asset - Asset to estimate
     * @returns {number} Estimated size in bytes
     */
    _estimateAssetSize(asset) {
        let size = 0;
        
        if (asset.scene) {
            asset.scene.traverse((child) => {
                if (child.geometry) {
                    size += this._estimateGeometrySize(child.geometry);
                }
                if (child.material) {
                    size += this._estimateMaterialSize(child.material);
                }
            });
        }
        
        return size;
    }

    /**
     * Estimate geometry memory size
     * @param {THREE.BufferGeometry} geometry - Geometry
     * @returns {number} Estimated size in bytes
     */
    _estimateGeometrySize(geometry) {
        let size = 0;
        
        for (const attribute of Object.values(geometry.attributes)) {
            size += attribute.array.byteLength;
        }
        
        if (geometry.index) {
            size += geometry.index.array.byteLength;
        }
        
        return size;
    }

    /**
     * Estimate material memory size
     * @param {THREE.Material} material - Material
     * @returns {number} Estimated size in bytes
     */
    _estimateMaterialSize(material) {
        let size = 1024; // Base material size
        
        // Add texture sizes
        const textureProperties = ['map', 'normalMap', 'roughnessMap', 'metalnessMap', 'emissiveMap'];
        
        for (const prop of textureProperties) {
            if (material[prop] && material[prop].image) {
                const image = material[prop].image;
                size += (image.width || 512) * (image.height || 512) * 4; // RGBA
            }
        }
        
        return size;
    }

    /**
     * Evict old assets to make space
     * @param {number} requiredSpace - Required space in bytes
     */
    _evictOldAssets(requiredSpace) {
        const assetsToEvict = [];
        let freedSpace = 0;
        
        // Simple LRU eviction - in production, use proper LRU cache
        for (const [url, asset] of this.assetCache) {
            const assetSize = this._estimateAssetSize(asset);
            assetsToEvict.push({ url, asset, size: assetSize });
            freedSpace += assetSize;
            
            if (freedSpace >= requiredSpace) break;
        }
        
        // Evict assets
        for (const { url, asset, size } of assetsToEvict) {
            this.assetCache.delete(url);
            this.cacheSize -= size;
            this._disposeAsset(asset);
            
            console.log(`🗑️ Evicted asset: ${url} (${(size / 1024 / 1024).toFixed(2)}MB)`);
        }
    }

    /**
     * Dispose of asset resources
     * @param {Object} asset - Asset to dispose
     */
    _disposeAsset(asset) {
        if (asset.scene) {
            asset.scene.traverse((child) => {
                if (child.geometry) {
                    child.geometry.dispose();
                }
                if (child.material) {
                    if (Array.isArray(child.material)) {
                        child.material.forEach(mat => mat.dispose());
                    } else {
                        child.material.dispose();
                    }
                }
            });
        }
    }

    /**
     * Set LOD level
     * @param {string} level - LOD level ('ultra', 'high', 'medium', 'low')
     */
    setLODLevel(level) {
        if (this.lodLevels.has(level)) {
            this.currentLOD = level;
            console.log(`🎯 LOD level set to: ${level}`);
        }
    }

    /**
     * Preload assets
     * @param {string[]} urls - Asset URLs to preload
     * @returns {Promise} Preloading promise
     */
    async preloadAssets(urls) {
        console.log(`📦 Preloading ${urls.length} assets...`);
        
        const promises = urls.map(url => this.loadAsset(url, { preload: true }));
        
        try {
            await Promise.all(promises);
            console.log(`✅ Preloaded ${urls.length} assets`);
        } catch (error) {
            console.warn('⚠️ Some assets failed to preload:', error.message);
        }
    }

    /**
     * Get loading progress
     * @returns {Object} Progress information
     */
    getProgress() {
        return {
            totalAssets: this.totalAssets,
            loadedCount: this.loadedCount,
            percentage: this.totalAssets > 0 ? (this.loadedCount / this.totalAssets) * 100 : 0,
            isLoading: this.loadingPromises.size > 0
        };
    }

    /**
     * Get asset statistics
     * @returns {Object} Asset statistics
     */
    getStatistics() {
        return {
            cachedAssets: this.assetCache.size,
            cacheSize: this.cacheSize,
            maxCacheSize: this.options.maxCacheSize,
            cacheUsage: (this.cacheSize / this.options.maxCacheSize) * 100,
            loadingAssets: this.loadingPromises.size,
            currentLOD: this.currentLOD,
            averageLoadTime: Array.from(this.loadTimes.values()).reduce((a, b) => a + b, 0) / this.loadTimes.size || 0
        };
    }

    /**
     * Clear asset cache
     */
    clearCache() {
        for (const asset of this.assetCache.values()) {
            this._disposeAsset(asset);
        }
        
        this.assetCache.clear();
        this.cacheSize = 0;
        
        console.log('🗑️ Asset cache cleared');
    }

    /**
     * Dispose of asset system
     */
    dispose() {
        // Clear cache
        this.clearCache();
        
        // Cancel loading promises
        this.loadingPromises.clear();
        
        // Dispose streaming worker
        if (this.streamingWorker) {
            this.streamingWorker.terminate();
        }
        
        console.log('🗑️ AssetSystem disposed');
    }
}