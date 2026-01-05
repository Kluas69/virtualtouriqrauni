/**
 * ModuleLoadingDiagnostics - Professional module loading diagnostics and recovery
 * Provides comprehensive error detection and fallback mechanisms
 */

export class ModuleLoadingDiagnostics {
    constructor(options = {}) {
        this.options = {
            enableLogging: true,
            enableRetry: true,
            maxRetries: 3,
            retryDelay: 1000,
            enableFallbacks: true,
            ...options
        };
        
        this.loadingAttempts = new Map();
        this.failedModules = new Set();
        this.loadedModules = new Set();
        this.fallbacksUsed = new Set();
        
        console.log('✅ ModuleLoadingDiagnostics initialized');
    }

    /**
     * Safely import a module with retry and fallback mechanisms
     * @param {string} modulePath - Path to the module
     * @param {Object} options - Loading options
     * @returns {Promise} Module import promise
     */
    async safeImport(modulePath, options = {}) {
        const moduleOptions = {
            enableRetry: this.options.enableRetry,
            maxRetries: this.options.maxRetries,
            retryDelay: this.options.retryDelay,
            fallbackModule: null,
            required: true,
            ...options
        };

        const attemptKey = `${modulePath}_${Date.now()}`;
        this.loadingAttempts.set(attemptKey, {
            path: modulePath,
            attempts: 0,
            startTime: Date.now(),
            options: moduleOptions
        });

        try {
            const module = await this._attemptModuleLoad(modulePath, moduleOptions, attemptKey);
            this.loadedModules.add(modulePath);
            
            if (this.options.enableLogging) {
                console.log(`✅ Module loaded successfully: ${modulePath}`);
            }
            
            return module;
        } catch (error) {
            this.failedModules.add(modulePath);
            
            if (this.options.enableLogging) {
                console.error(`❌ Module loading failed: ${modulePath}`, error);
            }
            
            // Try fallback if available
            if (moduleOptions.fallbackModule && this.options.enableFallbacks) {
                try {
                    const fallbackModule = await this._loadFallbackModule(moduleOptions.fallbackModule, modulePath);
                    this.fallbacksUsed.add(modulePath);
                    
                    if (this.options.enableLogging) {
                        console.warn(`⚠️ Using fallback for ${modulePath}: ${moduleOptions.fallbackModule}`);
                    }
                    
                    return fallbackModule;
                } catch (fallbackError) {
                    if (this.options.enableLogging) {
                        console.error(`❌ Fallback also failed for ${modulePath}:`, fallbackError);
                    }
                }
            }
            
            // If module is required, throw error
            if (moduleOptions.required) {
                throw new Error(`Required module failed to load: ${modulePath} - ${error.message}`);
            }
            
            // Return null for optional modules
            return null;
        } finally {
            this.loadingAttempts.delete(attemptKey);
        }
    }

    /**
     * Attempt to load a module with retry logic
     * @param {string} modulePath - Module path
     * @param {Object} options - Loading options
     * @param {string} attemptKey - Attempt tracking key
     * @returns {Promise} Module
     */
    async _attemptModuleLoad(modulePath, options, attemptKey) {
        const attempt = this.loadingAttempts.get(attemptKey);
        
        for (let i = 0; i < options.maxRetries; i++) {
            attempt.attempts = i + 1;
            
            try {
                if (this.options.enableLogging && i > 0) {
                    console.log(`🔄 Retry attempt ${i + 1} for module: ${modulePath}`);
                }
                
                const module = await import(modulePath);
                return module;
            } catch (error) {
                if (i < options.maxRetries - 1) {
                    // Wait before retry
                    await new Promise(resolve => setTimeout(resolve, options.retryDelay));
                } else {
                    // Last attempt failed
                    throw error;
                }
            }
        }
    }

    /**
     * Load fallback module
     * @param {string|Function} fallback - Fallback module path or factory function
     * @param {string} originalPath - Original module path
     * @returns {Promise} Fallback module
     */
    async _loadFallbackModule(fallback, originalPath) {
        if (typeof fallback === 'function') {
            // Fallback is a factory function
            return { default: fallback, [originalPath]: fallback };
        } else if (typeof fallback === 'string') {
            // Fallback is a module path
            return await import(fallback);
        } else if (typeof fallback === 'object') {
            // Fallback is a pre-built object
            return fallback;
        } else {
            throw new Error(`Invalid fallback type for ${originalPath}`);
        }
    }

    /**
     * Load Three.js addons with fallback mechanisms
     * @param {string} addonPath - Addon path (e.g., 'postprocessing/EffectComposer.js')
     * @param {Object} options - Loading options
     * @returns {Promise} Addon module
     */
    async loadThreeJSAddon(addonPath, options = {}) {
        const fullPath = `three/addons/${addonPath}`;
        
        const addonOptions = {
            enableRetry: true,
            maxRetries: 2,
            retryDelay: 500,
            fallbackModule: this._createThreeJSFallback(addonPath),
            required: false,
            ...options
        };

        return await this.safeImport(fullPath, addonOptions);
    }

    /**
     * Create fallback implementations for Three.js addons
     * @param {string} addonPath - Addon path
     * @returns {Object|null} Fallback implementation
     */
    _createThreeJSFallback(addonPath) {
        // Create basic fallback implementations for common addons
        switch (addonPath) {
            case 'postprocessing/EffectComposer.js':
                return {
                    EffectComposer: class FallbackEffectComposer {
                        constructor(renderer) {
                            this.renderer = renderer;
                            this.passes = [];
                        }
                        addPass(pass) { this.passes.push(pass); }
                        render() { 
                            // Basic render without post-processing
                            if (this.passes.length > 0 && this.passes[0].scene && this.passes[0].camera) {
                                this.renderer.render(this.passes[0].scene, this.passes[0].camera);
                            }
                        }
                        setSize(width, height) { this.renderer.setSize(width, height); }
                    }
                };
            
            case 'postprocessing/RenderPass.js':
                return {
                    RenderPass: class FallbackRenderPass {
                        constructor(scene, camera) {
                            this.scene = scene;
                            this.camera = camera;
                        }
                    }
                };
            
            case 'postprocessing/UnrealBloomPass.js':
                return {
                    UnrealBloomPass: class FallbackBloomPass {
                        constructor() {
                            // No-op fallback
                        }
                    }
                };
            
            case 'postprocessing/SSAOPass.js':
                return {
                    SSAOPass: class FallbackSSAOPass {
                        constructor() {
                            // No-op fallback
                            this.enabled = true;
                        }
                        setSize() {}
                        static get OUTPUT() {
                            return { Default: 0, Beauty: 1, SSAO: 2 };
                        }
                    }
                };
            
            case 'postprocessing/OutputPass.js':
                return {
                    OutputPass: class FallbackOutputPass {
                        constructor() {
                            // No-op fallback
                        }
                    }
                };
            
            case 'loaders/GLTFLoader.js':
                return {
                    GLTFLoader: class FallbackGLTFLoader {
                        load(url, onLoad, onProgress, onError) {
                            // Create a basic fallback scene
                            const scene = new THREE.Scene();
                            const geometry = new THREE.BoxGeometry(2, 2, 2);
                            const material = new THREE.MeshLambertMaterial({ color: 0x8B4513 });
                            const mesh = new THREE.Mesh(geometry, material);
                            scene.add(mesh);
                            
                            setTimeout(() => {
                                onLoad({ scene, animations: [], cameras: [] });
                            }, 100);
                        }
                    }
                };
            
            default:
                return null;
        }
    }

    /**
     * Get loading statistics
     * @returns {Object} Loading statistics
     */
    getStatistics() {
        return {
            loadedModules: Array.from(this.loadedModules),
            failedModules: Array.from(this.failedModules),
            fallbacksUsed: Array.from(this.fallbacksUsed),
            activeAttempts: this.loadingAttempts.size,
            totalLoaded: this.loadedModules.size,
            totalFailed: this.failedModules.size,
            fallbackRate: this.fallbacksUsed.size / Math.max(1, this.loadedModules.size + this.failedModules.size)
        };
    }

    /**
     * Generate loading report
     * @returns {string} Formatted loading report
     */
    generateReport() {
        const stats = this.getStatistics();
        
        return `
Module Loading Report:
=====================
✅ Loaded: ${stats.totalLoaded} modules
❌ Failed: ${stats.totalFailed} modules
⚠️ Fallbacks: ${stats.fallbacksUsed.length} modules
📊 Success Rate: ${((stats.totalLoaded / Math.max(1, stats.totalLoaded + stats.totalFailed)) * 100).toFixed(1)}%

Loaded Modules:
${stats.loadedModules.map(m => `  ✅ ${m}`).join('\n')}

Failed Modules:
${stats.failedModules.map(m => `  ❌ ${m}`).join('\n')}

Fallbacks Used:
${stats.fallbacksUsed.map(m => `  ⚠️ ${m}`).join('\n')}
        `.trim();
    }

    /**
     * Clear all tracking data
     */
    reset() {
        this.loadingAttempts.clear();
        this.failedModules.clear();
        this.loadedModules.clear();
        this.fallbacksUsed.clear();
        
        console.log('🔄 ModuleLoadingDiagnostics reset');
    }
}