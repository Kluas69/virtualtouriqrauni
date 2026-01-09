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
     * Create Three.js scene with Professional Studio Settings
     */
    createScene() {
        this.scene = new THREE.Scene();
        
        // Professional studio background - neutral but appealing
        this.scene.background = new THREE.Color(0x87ceeb); // Classic sky blue
        
        // Professional atmospheric fog for depth
        this.scene.fog = new THREE.Fog(0x87ceeb, 60, 250); // Balanced fog distance
        
        // Enable proper color management for professional results
        THREE.ColorManagement.enabled = true;
        
        console.log('🌍 Professional Studio Scene Created');
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
     * Create WebGL renderer with Professional Studio Settings
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
        
        // Professional Studio-Quality Tone Mapping
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping; // Cinematic tone mapping
        this.renderer.toneMappingExposure = 1.2; // Bright and vibrant like professional renders
        
        // Professional Color Settings
        this.renderer.gammaFactor = 2.2; // Standard gamma for accurate colors
        
        // Enable physically correct lights for professional results
        this.renderer.useLegacyLights = false;
        this.renderer.physicallyCorrectLights = true;
        
        // Professional color space
        this.renderer.outputColorSpace = THREE.SRGBColorSpace;
        
        // Enhanced rendering settings for professional quality
        this.renderer.sortObjects = true; // Better depth sorting
        this.renderer.logarithmicDepthBuffer = false; // Keep false for performance
        
        // Append to container
        this.container.appendChild(this.renderer.domElement);
        
        console.log('🖥️ Professional Studio-Quality WebGL Renderer Created');
    }
    
    /**
     * Setup Professional Studio-Quality Lighting System
     */
    setupLighting() {
        console.log('� Seetting up Professional Studio-Quality Lighting System...');
        
        // 1. PROFESSIONAL AMBIENT LIGHTING - Provides base illumination
        const ambientLight = new THREE.AmbientLight(0x404040, 0.6); // Balanced ambient
        this.scene.add(ambientLight);
        this.lights.set('ambient', ambientLight);
        
        // 2. KEY LIGHT (Main Sun) - Primary light source with warm professional color
        const keyLight = new THREE.DirectionalLight(0xfff8dc, 1.8); // Warm white, strong intensity
        keyLight.position.set(15, 20, 10);
        keyLight.castShadow = false; // Using baked lighting for performance
        this.scene.add(keyLight);
        this.lights.set('key', keyLight);
        
        // 3. FILL LIGHT - Softens shadows and provides secondary illumination
        const fillLight = new THREE.DirectionalLight(0x87ceeb, 0.8); // Cool blue fill
        fillLight.position.set(-10, 15, 5);
        fillLight.castShadow = false;
        this.scene.add(fillLight);
        this.lights.set('fill', fillLight);
        
        // 4. RIM LIGHT - Creates edge lighting for depth and separation
        const rimLight = new THREE.DirectionalLight(0xffffff, 0.6); // Pure white rim light
        rimLight.position.set(0, 10, -15);
        rimLight.castShadow = false;
        this.scene.add(rimLight);
        this.lights.set('rim', rimLight);
        
        // 5. PROFESSIONAL HEMISPHERE LIGHT - Natural sky-ground gradient
        const hemisphereLight = new THREE.HemisphereLight(0x87ceeb, 0x8b7355, 0.7); // Sky to earth
        this.scene.add(hemisphereLight);
        this.lights.set('hemisphere', hemisphereLight);
        
        // 6. ACCENT POINT LIGHTS - For local illumination and atmosphere
        const accentLight1 = new THREE.PointLight(0xfff8dc, 0.8, 30); // Warm accent
        accentLight1.position.set(8, 6, 8);
        this.scene.add(accentLight1);
        this.lights.set('accent1', accentLight1);
        
        const accentLight2 = new THREE.PointLight(0xe6f3ff, 0.6, 25); // Cool accent
        accentLight2.position.set(-8, 5, -8);
        this.scene.add(accentLight2);
        this.lights.set('accent2', accentLight2);
        
        // 7. BOUNCE LIGHT - Simulates light bouncing from surfaces
        const bounceLight = new THREE.DirectionalLight(0xffeaa7, 0.4); // Warm bounce
        bounceLight.position.set(5, -3, 12); // From below-forward
        bounceLight.castShadow = false;
        this.scene.add(bounceLight);
        this.lights.set('bounce', bounceLight);
        
        console.log('💡 Professional Studio-Quality Lighting System Complete');
    }
    
    /**
     * Setup GTA 5-style post-processing pipeline with realistic effects
     */
    async setupPostProcessing() {
        try {
            console.log('🎭 Setting up GTA 5-style post-processing pipeline...');
            
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
            
            // SSAO pass (screen-space ambient occlusion) - GTA 5 style subtle AO
            if (this.qualitySettings.ssao && this.SSAOPass) {
                try {
                    this.ssaoPass = new this.SSAOPass(
                        this.scene, 
                        this.camera, 
                        this.container.clientWidth, 
                        this.container.clientHeight
                    );
                    
                    // GTA 5-style SSAO settings - more subtle and realistic
                    this.ssaoPass.kernelRadius = 12; // Larger radius for softer AO
                    this.ssaoPass.minDistance = 0.002; // Finer detail
                    this.ssaoPass.maxDistance = 0.08; // Shorter range for realism
                    
                    // Handle Three.js version compatibility for SSAO output
                    if (this.SSAOPass.OUTPUT && this.SSAOPass.OUTPUT.Beauty !== undefined) {
                        this.ssaoPass.output = this.SSAOPass.OUTPUT.Beauty;
                    } else if (this.ssaoPass.output !== undefined) {
                        this.ssaoPass.output = 0; // Default output mode
                    }
                    
                    this.composer.addPass(this.ssaoPass);
                    console.log('✅ GTA 5-style SSAO pass added successfully');
                } catch (error) {
                    console.warn('⚠️ SSAO pass failed to initialize, skipping:', error.message);
                    this.qualitySettings.ssao = false;
                }
            }
            
            // Bloom pass (HDR bloom effect) - GTA 5 style subtle bloom
            if (this.qualitySettings.bloom && this.UnrealBloomPass) {
                this.bloomPass = new this.UnrealBloomPass(
                    new THREE.Vector2(this.container.clientWidth, this.container.clientHeight),
                    0.8,  // strength - more subtle like GTA 5
                    0.6,  // radius - wider spread
                    0.9   // threshold - higher threshold for realism
                );
                this.composer.addPass(this.bloomPass);
                console.log('✅ GTA 5-style bloom pass added');
            }
            
            // Output pass (final tone mapping and gamma correction)
            if (this.OutputPass) {
                this.outputPass = new this.OutputPass();
                this.composer.addPass(this.outputPass);
            }
            
            console.log('✅ GTA 5-style post-processing pipeline setup complete');
            
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
     * Get high-resolution quality settings for different levels
     * @param {string} level - Quality level
     * @returns {Object} Quality settings optimized for high-resolution graphics
     */
    getQualitySettings(level) {
        const settings = {
            low: {
                shadowMapSize: 0, // Shadows disabled for performance
                antialias: true, // Keep antialias even on low
                postProcessing: false,
                ssao: false,
                bloom: false,
                maxPixelRatio: 1.25, // High resolution even on low quality
                renderScale: 0.8,
                textureQuality: 'medium', // Upgraded from low
                geometryLOD: 'low',
                targetFPS: 30,
                toneMappingExposure: 1.0
            },
            medium: {
                shadowMapSize: 0, // Shadows disabled
                antialias: true,
                postProcessing: true,
                ssao: false, // Disabled for medium to maintain performance
                bloom: true,
                maxPixelRatio: 1.5, // Higher resolution
                renderScale: 0.9,
                textureQuality: 'high', // Upgraded from medium
                geometryLOD: 'medium',
                targetFPS: 45,
                toneMappingExposure: 1.1
            },
            high: {
                shadowMapSize: 0, // Shadows disabled but using baked lighting
                antialias: true,
                postProcessing: true,
                ssao: true, // Enable for high quality realism
                bloom: true,
                maxPixelRatio: 2.0, // Maximum resolution
                renderScale: 1.0,
                textureQuality: 'ultra', // Maximum quality
                geometryLOD: 'high',
                targetFPS: 60,
                toneMappingExposure: 1.2 // Bright and vibrant
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
     * Apply high-resolution quality settings to renderer
     */
    applyQualitySettings() {
        // Update pixel ratio for high resolution
        this.renderer.setPixelRatio(
            Math.min(window.devicePixelRatio, this.qualitySettings.maxPixelRatio)
        );
        
        // Update tone mapping exposure based on quality level
        this.renderer.toneMappingExposure = this.qualitySettings.toneMappingExposure || 1.2;
        
        // Shadows are disabled - no shadow map updates needed
        
        // Update post-processing effects with high-resolution settings
        if (this.composer) {
            if (this.ssaoPass) {
                this.ssaoPass.enabled = this.qualitySettings.ssao;
                if (this.qualitySettings.ssao) {
                    // Adjust SSAO intensity based on quality
                    const aoIntensity = this.options.qualityLevel === 'high' ? 0.6 : 0.4;
                    if (this.ssaoPass.kernelRadius !== undefined) {
                        this.ssaoPass.kernelRadius = this.options.qualityLevel === 'high' ? 16 : 12;
                    }
                }
            }
            if (this.bloomPass) {
                this.bloomPass.enabled = this.qualitySettings.bloom;
                if (this.qualitySettings.bloom) {
                    // Adjust bloom settings based on quality for high-resolution effect
                    this.bloomPass.strength = this.options.qualityLevel === 'high' ? 0.9 : 0.7;
                    this.bloomPass.threshold = this.options.qualityLevel === 'high' ? 0.85 : 0.8;
                }
            }
        }
        
        // Apply high-resolution texture quality settings
        this.applyTextureQuality(this.qualitySettings.textureQuality);
        
        console.log(`🎯 High-resolution quality settings applied: ${this.options.qualityLevel}`);
    }
    
    /**
     * Apply high-resolution texture quality settings
     * @param {string} quality - Texture quality level
     */
    applyTextureQuality(quality) {
        const qualityMap = {
            low: { anisotropy: 2, maxTextureSize: 1024 }, // Upgraded from 1/512
            medium: { anisotropy: 8, maxTextureSize: 2048 }, // Upgraded from 4/1024
            high: { anisotropy: 16, maxTextureSize: 4096 }, // Upgraded from 8/2048
            ultra: { anisotropy: 16, maxTextureSize: 8192 } // New ultra setting
        };
        
        const settings = qualityMap[quality] || qualityMap.medium;
        
        // Apply to renderer capabilities
        if (this.renderer.capabilities) {
            this.renderer.capabilities.getMaxAnisotropy = () => settings.anisotropy;
        }
        
        console.log(`🖼️ High-resolution texture quality set to: ${quality}`);
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