/**
 * RenderingSystem - Professional WebGL rendering with PBR and post-processing
 * Implements advanced rendering pipeline with quality scaling
 */

import * as THREE from 'three';
import { ModuleLoadingDiagnostics } from '../core/ModuleLoadingDiagnostics.js';

export class RenderingSystem {
    constructor(container, options = {}) {
        this.container = container;
        this.options = {
            antialias: true,
            enableShadows: false, // Disabled - using baked lighting from .glb models
            enablePostProcessing: true,
            qualityLevel: 'high',
            powerPreference: 'high-performance',
            debugMode: false,
            ...options
        };
        
        // Module loading diagnostics
        this.moduleLoader = new ModuleLoadingDiagnostics({
            enableLogging: this.options.debugMode,
            enableFallbacks: true
        });
        
        // Core Three.js components
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.composer = null;
        
        // Quality management system
        this.qualityManager = {
            current: 'high',
            autoAdjust: true,
            deviceCapabilities: null
        };
        
        // Rendering passes
        this.renderPass = null;
        this.ssaoPass = null;
        this.bloomPass = null;
        this.outputPass = null;
        
        // Post-processing classes (loaded dynamically)
        this.EffectComposer = null;
        this.RenderPass = null;
        this.UnrealBloomPass = null;
        this.SSAOPass = null;
        this.OutputPass = null;
        
        // Lighting system
        this.lights = new Map();
        this.environmentMap = null;
        this.lightProbes = [];
        
        // Quality settings
        this.qualitySettings = this.getQualitySettings(this.options.qualityLevel);
        
        // Performance tracking
        this.renderStats = {
            triangles: 0,
            drawCalls: 0,
            geometries: 0,
            textures: 0,
            programs: 0
        };
        
        console.log('🎨 RenderingSystem created with professional pipeline');
    }
    
    /**
     * Initialize the rendering system
     */
    async initialize() {
        try {
            console.log('🚀 Initializing Professional Rendering System...');
            
            // Create Three.js scene
            this.createScene();
            
            // Create camera
            this.createCamera();
            
            // Create WebGL renderer
            this.createRenderer();
            
            // Setup lighting system
            this.setupLighting();
            
            // Setup post-processing pipeline
            if (this.options.enablePostProcessing) {
                await this.setupPostProcessing();
            }
            
            // Setup environment mapping
            await this.setupEnvironmentMapping();
            
            // Apply quality settings
            this.applyQualitySettings();
            
            console.log('✅ Professional Rendering System initialized');
            
        } catch (error) {
            console.error('❌ RenderingSystem initialization failed:', error);
            throw error;
        }
    }
    
    /**
     * Create Three.js scene with professional settings
     */
    createScene() {
        this.scene = new THREE.Scene();
        
        // Set background
        this.scene.background = new THREE.Color(0x87CEEB); // Sky blue
        
        // Enable fog for depth perception
        this.scene.fog = new THREE.Fog(0x87CEEB, 50, 200);
        
        // Setup tone mapping for HDR
        THREE.ColorManagement.enabled = true;
        
        console.log('🌍 Professional scene created');
    }
    
    /**
     * Create camera with professional settings
     */
    createCamera() {
        const aspect = this.container.clientWidth / this.container.clientHeight;
        
        this.camera = new THREE.PerspectiveCamera(75, aspect, 0.1, 1000);
        this.camera.position.set(0, 1.6, 5);
        
        // Enable automatic frustum culling
        this.camera.matrixAutoUpdate = true;
        
        console.log('📷 Professional camera created');
    }
    
    /**
     * Create WebGL renderer with optimized settings for baked lighting
     */
    createRenderer() {
        this.renderer = new THREE.WebGLRenderer({
            canvas: undefined,
            antialias: this.qualitySettings.antialias,
            alpha: false,
            premultipliedAlpha: false,
            stencil: false,
            preserveDrawingBuffer: false,
            powerPreference: this.options.powerPreference,
            failIfMajorPerformanceCaveat: false
        });
        
        // Set size and pixel ratio
        this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, this.qualitySettings.maxPixelRatio));
        
        // SHADOWS DISABLED - Using baked lighting from .glb models
        this.renderer.shadowMap.enabled = false;
        
        // Enhanced tone mapping for better visuals
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = 1.2; // Slightly brighter for better visibility
        
        // Enable physically correct lights
        this.renderer.useLegacyLights = false;
        
        // Output encoding for proper color space
        this.renderer.outputColorSpace = THREE.SRGBColorSpace;
        
        // Enhanced rendering settings for better graphics
        this.renderer.gammaFactor = 2.2;
        this.renderer.physicallyCorrectLights = true;
        
        // Append to container
        this.container.appendChild(this.renderer.domElement);
        
        console.log('🖥️ Optimized WebGL renderer created (shadows disabled, baked lighting)');
    }
    
    /**
     * Setup optimized lighting system (no shadows - using baked lighting)
     */
    setupLighting() {
        // Enhanced ambient light for better base illumination
        const ambientLight = new THREE.AmbientLight(0x404040, 0.6); // Increased intensity
        this.scene.add(ambientLight);
        this.lights.set('ambient', ambientLight);
        
        // Directional light (sun) WITHOUT shadows for performance
        const directionalLight = new THREE.DirectionalLight(0xffffff, 1.2); // Increased intensity
        directionalLight.position.set(10, 10, 5);
        directionalLight.castShadow = false; // DISABLED - using baked lighting
        
        this.scene.add(directionalLight);
        this.lights.set('directional', directionalLight);
        
        // Enhanced hemisphere light for natural outdoor lighting
        const hemisphereLight = new THREE.HemisphereLight(0x87CEEB, 0x8B4513, 0.6); // Increased intensity
        this.scene.add(hemisphereLight);
        this.lights.set('hemisphere', hemisphereLight);
        
        // Additional fill light for better visibility
        const fillLight = new THREE.DirectionalLight(0xffffff, 0.3);
        fillLight.position.set(-5, 5, -5);
        fillLight.castShadow = false;
        this.scene.add(fillLight);
        this.lights.set('fill', fillLight);
        
        console.log('💡 Optimized lighting system setup (shadows disabled, enhanced illumination)');
    }
    
    /**
     * Setup post-processing pipeline with safe module loading
     */
    async setupPostProcessing() {
        try {
            console.log('🎭 Setting up post-processing pipeline...');
            
            // Load post-processing modules safely
            await this.loadPostProcessingModules();
            
            if (!this.EffectComposer) {
                console.warn('⚠️ Post-processing modules not available, skipping');
                return;
            }
            
            // Create effect composer
            this.composer = new this.EffectComposer(this.renderer);
            
            // Render pass (base scene rendering)
            if (this.RenderPass) {
                this.renderPass = new this.RenderPass(this.scene, this.camera);
                this.composer.addPass(this.renderPass);
            }
            
            // SSAO pass (screen-space ambient occlusion)
            if (this.qualitySettings.ssao && this.SSAOPass) {
                try {
                    this.ssaoPass = new this.SSAOPass(
                        this.scene, 
                        this.camera, 
                        this.container.clientWidth, 
                        this.container.clientHeight
                    );
                    this.ssaoPass.kernelRadius = 8;
                    this.ssaoPass.minDistance = 0.005;
                    this.ssaoPass.maxDistance = 0.1;
                    
                    // Handle Three.js version compatibility for SSAO output
                    if (this.SSAOPass.OUTPUT && this.SSAOPass.OUTPUT.Beauty !== undefined) {
                        this.ssaoPass.output = this.SSAOPass.OUTPUT.Beauty;
                    } else if (this.ssaoPass.output !== undefined) {
                        // Fallback for newer Three.js versions
                        this.ssaoPass.output = 0; // Default output mode
                    }
                    
                    this.composer.addPass(this.ssaoPass);
                    console.log('✅ SSAO pass added successfully');
                } catch (error) {
                    console.warn('⚠️ SSAO pass failed to initialize, skipping:', error.message);
                    this.qualitySettings.ssao = false;
                }
            }
            
            // Bloom pass (HDR bloom effect)
            if (this.qualitySettings.bloom && this.UnrealBloomPass) {
                this.bloomPass = new this.UnrealBloomPass(
                    new THREE.Vector2(this.container.clientWidth, this.container.clientHeight),
                    1.5,  // strength
                    0.4,  // radius
                    0.85  // threshold
                );
                this.composer.addPass(this.bloomPass);
            }
            
            // Output pass (final tone mapping and gamma correction)
            if (this.OutputPass) {
                this.outputPass = new this.OutputPass();
                this.composer.addPass(this.outputPass);
            }
            
            console.log('✅ Post-processing pipeline setup complete');
            
        } catch (error) {
            console.error('❌ Post-processing setup failed:', error);
            // Continue without post-processing
            this.options.enablePostProcessing = false;
        }
    }
    
    /**
     * Load post-processing modules safely
     */
    async loadPostProcessingModules() {
        try {
            console.log('📦 Loading post-processing modules...');
            
            // Load EffectComposer
            const effectComposerModule = await this.moduleLoader.loadThreeJSAddon(
                'postprocessing/EffectComposer.js',
                { required: false }
            );
            if (effectComposerModule) {
                this.EffectComposer = effectComposerModule.EffectComposer;
            }
            
            // Load RenderPass
            const renderPassModule = await this.moduleLoader.loadThreeJSAddon(
                'postprocessing/RenderPass.js',
                { required: false }
            );
            if (renderPassModule) {
                this.RenderPass = renderPassModule.RenderPass;
            }
            
            // Load UnrealBloomPass
            const bloomPassModule = await this.moduleLoader.loadThreeJSAddon(
                'postprocessing/UnrealBloomPass.js',
                { required: false }
            );
            if (bloomPassModule) {
                this.UnrealBloomPass = bloomPassModule.UnrealBloomPass;
            }
            
            // Load SSAOPass
            const ssaoPassModule = await this.moduleLoader.loadThreeJSAddon(
                'postprocessing/SSAOPass.js',
                { required: false }
            );
            if (ssaoPassModule) {
                this.SSAOPass = ssaoPassModule.SSAOPass;
            }
            
            // Load OutputPass
            const outputPassModule = await this.moduleLoader.loadThreeJSAddon(
                'postprocessing/OutputPass.js',
                { required: false }
            );
            if (outputPassModule) {
                this.OutputPass = outputPassModule.OutputPass;
            }
            
            console.log('✅ Post-processing modules loaded successfully');
            
        } catch (error) {
            console.error('❌ Failed to load post-processing modules:', error);
            throw error;
        }
    }
    
    /**
     * Setup environment mapping for IBL
     */
    async setupEnvironmentMapping() {
        try {
            // Create HDR environment map
            const pmremGenerator = new THREE.PMREMGenerator(this.renderer);
            pmremGenerator.compileEquirectangularShader();
            
            // Create a simple gradient environment for now
            const envMapSize = 256;
            const envMapData = new Uint8Array(envMapSize * envMapSize * 4);
            
            for (let i = 0; i < envMapSize; i++) {
                for (let j = 0; j < envMapSize; j++) {
                    const index = (i * envMapSize + j) * 4;
                    const u = j / envMapSize;
                    const v = i / envMapSize;
                    
                    // Sky gradient
                    const skyColor = new THREE.Color(0x87CEEB);
                    const horizonColor = new THREE.Color(0xFFE4B5);
                    
                    const color = skyColor.clone().lerp(horizonColor, v);
                    
                    envMapData[index] = color.r * 255;
                    envMapData[index + 1] = color.g * 255;
                    envMapData[index + 2] = color.b * 255;
                    envMapData[index + 3] = 255;
                }
            }
            
            const envMapTexture = new THREE.DataTexture(
                envMapData, 
                envMapSize, 
                envMapSize, 
                THREE.RGBAFormat
            );
            envMapTexture.needsUpdate = true;
            
            this.environmentMap = pmremGenerator.fromEquirectangular(envMapTexture).texture;
            this.scene.environment = this.environmentMap;
            
            pmremGenerator.dispose();
            
            console.log('🌍 Environment mapping setup');
            
        } catch (error) {
            console.warn('⚠️ Environment mapping setup failed:', error);
        }
    }
    
    /**
     * Get quality settings for different levels with optimized performance
     * @param {string} level - Quality level
     * @returns {Object} Quality settings
     */
    getQualitySettings(level) {
        const settings = {
            low: {
                shadowMapSize: 0, // Shadows disabled
                antialias: false,
                postProcessing: false,
                ssao: false,
                bloom: false,
                maxPixelRatio: 1.0,
                renderScale: 0.75,
                textureQuality: 'low',
                geometryLOD: 'low',
                targetFPS: 30
            },
            medium: {
                shadowMapSize: 0, // Shadows disabled
                antialias: true,
                postProcessing: true,
                ssao: false,
                bloom: true,
                maxPixelRatio: 1.5,
                renderScale: 0.85,
                textureQuality: 'medium',
                geometryLOD: 'medium',
                targetFPS: 45
            },
            high: {
                shadowMapSize: 0, // Shadows disabled
                antialias: true,
                postProcessing: true,
                ssao: true,
                bloom: true,
                maxPixelRatio: 2.0,
                renderScale: 1.0,
                textureQuality: 'high',
                geometryLOD: 'high',
                targetFPS: 60
            }
        };
        
        return settings[level] || settings.medium;
    }
    
    /**
     * Detect device capabilities and set optimal quality
     */
    async detectAndSetOptimalQuality() {
        const deviceInfo = {
            isMobile: /Android|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent),
            isLowEnd: false,
            memoryGB: 4, // Default assumption
            cores: navigator.hardwareConcurrency || 4,
            webglVersion: 'unknown',
            maxTextureSize: 2048
        };
        
        // Detect WebGL capabilities
        try {
            const canvas = document.createElement('canvas');
            const gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
            
            if (gl) {
                deviceInfo.webglVersion = gl.getParameter(gl.VERSION);
                deviceInfo.maxTextureSize = gl.getParameter(gl.MAX_TEXTURE_SIZE);
                
                // Estimate if device is low-end based on WebGL info
                const renderer = gl.getParameter(gl.RENDERER).toLowerCase();
                deviceInfo.isLowEnd = renderer.includes('mali') || 
                                      renderer.includes('adreno 3') || 
                                      renderer.includes('powervr');
            }
        } catch (error) {
            console.warn('⚠️ Could not detect WebGL capabilities:', error);
        }
        
        // Estimate memory if available
        if (navigator.deviceMemory) {
            deviceInfo.memoryGB = navigator.deviceMemory;
        }
        
        // Set optimal quality based on device capabilities
        let optimalQuality = 'high';
        
        if (deviceInfo.isMobile) {
            if (deviceInfo.isLowEnd || deviceInfo.memoryGB < 3) {
                optimalQuality = 'low';
            } else if (deviceInfo.memoryGB < 6) {
                optimalQuality = 'medium';
            }
        } else {
            // Desktop - start with high quality since shadows are disabled
            if (deviceInfo.memoryGB >= 8 && deviceInfo.cores >= 4) {
                optimalQuality = 'high';
            } else if (deviceInfo.memoryGB < 4) {
                optimalQuality = 'low';
            } else {
                optimalQuality = 'medium';
            }
        }
        
        this.qualityManager.deviceCapabilities = deviceInfo;
        this.setQualityLevel(optimalQuality);
        
        console.log('🔍 Device capabilities detected:', deviceInfo);
        console.log(`🎯 Optimal quality set to: ${optimalQuality}`);
    }
    
    /**
     * Apply quality settings to renderer (optimized for baked lighting)
     */
    applyQualitySettings() {
        // Update pixel ratio
        this.renderer.setPixelRatio(
            Math.min(window.devicePixelRatio, this.qualitySettings.maxPixelRatio)
        );
        
        // Shadows are disabled - no shadow map updates needed
        
        // Update post-processing effects
        if (this.composer) {
            if (this.ssaoPass) {
                this.ssaoPass.enabled = this.qualitySettings.ssao;
            }
            if (this.bloomPass) {
                this.bloomPass.enabled = this.qualitySettings.bloom;
            }
        }
        
        // Apply texture quality settings
        this.applyTextureQuality(this.qualitySettings.textureQuality);
        
        console.log(`🎯 Quality settings applied: ${this.options.qualityLevel} (shadows disabled)`);
    }
    
    /**
     * Apply texture quality settings
     * @param {string} quality - Texture quality level
     */
    applyTextureQuality(quality) {
        const qualityMap = {
            low: { anisotropy: 1, maxTextureSize: 512 },
            medium: { anisotropy: 4, maxTextureSize: 1024 },
            high: { anisotropy: 8, maxTextureSize: 2048 },
            ultra: { anisotropy: 16, maxTextureSize: 4096 }
        };
        
        const settings = qualityMap[quality] || qualityMap.medium;
        
        // Apply to renderer capabilities
        if (this.renderer.capabilities) {
            this.renderer.capabilities.getMaxAnisotropy = () => settings.anisotropy;
        }
        
        console.log(`🖼️ Texture quality set to: ${quality}`);
    }
    
    /**
     * Set quality level
     * @param {string} level - Quality level (low, medium, high, ultra)
     */
    setQualityLevel(level) {
        this.options.qualityLevel = level;
        this.qualitySettings = this.getQualitySettings(level);
        this.applyQualitySettings();
        
        console.log(`🎯 Quality level changed to: ${level}`);
    }
    
    /**
     * Add object to scene
     * @param {THREE.Object3D} object - Object to add
     */
    addToScene(object) {
        this.scene.add(object);
    }
    
    /**
     * Remove object from scene
     * @param {THREE.Object3D} object - Object to remove
     */
    removeFromScene(object) {
        this.scene.remove(object);
    }
    
    /**
     * Get scene reference
     * @returns {THREE.Scene} Scene instance
     */
    getScene() {
        return this.scene;
    }
    
    /**
     * Get camera reference
     * @returns {THREE.Camera} Camera instance
     */
    getCamera() {
        return this.camera;
    }
    
    /**
     * Get renderer reference
     * @returns {THREE.WebGLRenderer} Renderer instance
     */
    getRenderer() {
        return this.renderer;
    }
    
    /**
     * Get canvas element
     * @returns {HTMLCanvasElement} Canvas element
     */
    getCanvas() {
        return this.renderer.domElement;
    }
    
    /**
     * Render frame
     * @param {number} interpolation - Interpolation factor for smooth rendering
     */
    render(interpolation = 1.0) {
        try {
            // Update render stats
            this.updateRenderStats();
            
            // Render with post-processing or direct
            if (this.composer && this.options.enablePostProcessing) {
                this.composer.render();
            } else {
                this.renderer.render(this.scene, this.camera);
            }
            
        } catch (error) {
            console.error('❌ Render error:', error);
            throw error;
        }
    }
    
    /**
     * Update render statistics
     */
    updateRenderStats() {
        const info = this.renderer.info;
        
        this.renderStats = {
            triangles: info.render.triangles,
            drawCalls: info.render.calls,
            geometries: info.memory.geometries,
            textures: info.memory.textures,
            programs: info.programs?.length || 0
        };
    }
    
    /**
     * Handle window resize
     * @param {number} width - New width
     * @param {number} height - New height
     */
    onResize(width, height) {
        // Update camera aspect ratio
        this.camera.aspect = width / height;
        this.camera.updateProjectionMatrix();
        
        // Update renderer size
        this.renderer.setSize(width, height);
        
        // Update post-processing composer
        if (this.composer) {
            this.composer.setSize(width, height);
            
            // Update SSAO pass
            if (this.ssaoPass) {
                this.ssaoPass.setSize(width, height);
            }
        }
        
        console.log(`📐 Rendering system resized to ${width}×${height}`);
    }
    
    /**
     * Handle WebGL context loss
     */
    onContextLost() {
        console.warn('🔄 Rendering system context lost');
        // Pause rendering
    }
    
    /**
     * Handle WebGL context restoration
     */
    async onContextRestored() {
        console.log('🔄 Restoring rendering system context');
        
        try {
            // Recreate post-processing pipeline
            if (this.options.enablePostProcessing) {
                this.setupPostProcessing();
            }
            
            // Reapply quality settings
            this.applyQualitySettings();
            
            console.log('✅ Rendering system context restored');
            
        } catch (error) {
            console.error('❌ Context restoration failed:', error);
            throw error;
        }
    }
    
    /**
     * Take screenshot
     * @returns {string} Data URL of screenshot
     */
    takeScreenshot() {
        return this.renderer.domElement.toDataURL('image/png');
    }
    
    /**
     * Get rendering statistics
     * @returns {Object} Render statistics
     */
    getStatistics() {
        return {
            ...this.renderStats,
            qualityLevel: this.options.qualityLevel,
            postProcessing: this.options.enablePostProcessing,
            shadows: this.options.enableShadows,
            pixelRatio: this.renderer.getPixelRatio(),
            size: this.renderer.getSize(new THREE.Vector2()),
            capabilities: this.renderer.capabilities
        };
    }
    
    /**
     * Dispose of rendering system resources
     */
    dispose() {
        try {
            // Dispose post-processing
            if (this.composer) {
                this.composer.dispose();
            }
            
            // Dispose environment map
            if (this.environmentMap) {
                this.environmentMap.dispose();
            }
            
            // Dispose lights
            for (const [name, light] of this.lights) {
                if (light.dispose) {
                    light.dispose();
                }
            }
            this.lights.clear();
            
            // Dispose renderer
            if (this.renderer) {
                this.renderer.dispose();
                if (this.renderer.domElement.parentNode) {
                    this.renderer.domElement.parentNode.removeChild(this.renderer.domElement);
                }
            }
            
            // Clear scene
            if (this.scene) {
                this.scene.clear();
            }
            
            console.log('🗑️ RenderingSystem disposed');
            
        } catch (error) {
            console.error('❌ Error during RenderingSystem disposal:', error);
        }
    }
}