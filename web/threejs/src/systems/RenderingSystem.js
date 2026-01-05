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
            enableShadows: true,
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
     * Create WebGL renderer with professional settings
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
        
        // Enable shadows
        if (this.options.enableShadows) {
            this.renderer.shadowMap.enabled = true;
            this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
            this.renderer.shadowMap.autoUpdate = true;
        }
        
        // Set tone mapping for HDR
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = 1.0;
        
        // Enable physically correct lights
        this.renderer.useLegacyLights = false;
        
        // Output encoding for proper color space
        this.renderer.outputColorSpace = THREE.SRGBColorSpace;
        
        // Append to container
        this.container.appendChild(this.renderer.domElement);
        
        console.log('🖥️ Professional WebGL renderer created');
    }
    
    /**
     * Setup professional lighting system
     */
    setupLighting() {
        // Ambient light for base illumination
        const ambientLight = new THREE.AmbientLight(0x404040, 0.3);
        this.scene.add(ambientLight);
        this.lights.set('ambient', ambientLight);
        
        // Directional light (sun) with shadows
        const directionalLight = new THREE.DirectionalLight(0xffffff, 1.0);
        directionalLight.position.set(10, 10, 5);
        directionalLight.castShadow = true;
        
        // Configure shadow camera
        directionalLight.shadow.mapSize.width = this.qualitySettings.shadowMapSize;
        directionalLight.shadow.mapSize.height = this.qualitySettings.shadowMapSize;
        directionalLight.shadow.camera.near = 0.5;
        directionalLight.shadow.camera.far = 50;
        directionalLight.shadow.camera.left = -20;
        directionalLight.shadow.camera.right = 20;
        directionalLight.shadow.camera.top = 20;
        directionalLight.shadow.camera.bottom = -20;
        
        // Shadow bias for quality
        directionalLight.shadow.bias = -0.0001;
        directionalLight.shadow.normalBias = 0.02;
        
        this.scene.add(directionalLight);
        this.lights.set('directional', directionalLight);
        
        // Hemisphere light for natural outdoor lighting
        const hemisphereLight = new THREE.HemisphereLight(0x87CEEB, 0x8B4513, 0.4);
        this.scene.add(hemisphereLight);
        this.lights.set('hemisphere', hemisphereLight);
        
        console.log('💡 Professional lighting system setup');
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
     * Get quality settings for different levels
     * @param {string} level - Quality level
     * @returns {Object} Quality settings
     */
    getQualitySettings(level) {
        const settings = {
            low: {
                shadowMapSize: 512,
                antialias: false,
                postProcessing: false,
                ssao: false,
                bloom: false,
                maxPixelRatio: 1.0,
                renderScale: 0.75
            },
            medium: {
                shadowMapSize: 1024,
                antialias: true,
                postProcessing: true,
                ssao: false,
                bloom: true,
                maxPixelRatio: 1.5,
                renderScale: 0.85
            },
            high: {
                shadowMapSize: 2048,
                antialias: true,
                postProcessing: true,
                ssao: true,
                bloom: true,
                maxPixelRatio: 2.0,
                renderScale: 1.0
            },
            ultra: {
                shadowMapSize: 4096,
                antialias: true,
                postProcessing: true,
                ssao: true,
                bloom: true,
                maxPixelRatio: 3.0,
                renderScale: 1.0
            }
        };
        
        return settings[level] || settings.medium;
    }
    
    /**
     * Apply quality settings to renderer
     */
    applyQualitySettings() {
        // Update pixel ratio
        this.renderer.setPixelRatio(
            Math.min(window.devicePixelRatio, this.qualitySettings.maxPixelRatio)
        );
        
        // Update shadow map size
        if (this.lights.has('directional')) {
            const light = this.lights.get('directional');
            light.shadow.mapSize.width = this.qualitySettings.shadowMapSize;
            light.shadow.mapSize.height = this.qualitySettings.shadowMapSize;
        }
        
        // Update post-processing effects
        if (this.composer) {
            if (this.ssaoPass) {
                this.ssaoPass.enabled = this.qualitySettings.ssao;
            }
            if (this.bloomPass) {
                this.bloomPass.enabled = this.qualitySettings.bloom;
            }
        }
        
        console.log(`🎯 Quality settings applied: ${this.options.qualityLevel}`);
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