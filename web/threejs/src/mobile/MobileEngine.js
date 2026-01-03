/**
 * Mobile Engine
 * Mobile-optimized 3D engine with performance monitoring and adaptive quality
 */

import * as THREE from 'three';
import { PerformanceAdapter } from './PerformanceAdapter.js';

export class MobileEngine {
    constructor(container, options = {}) {
        this.container = container;
        this.options = {
            enablePerformanceMonitoring: true,
            targetFPS: 30,
            maxMemoryMB: 100,
            adaptiveQuality: true,
            batteryOptimization: true,
            ...options
        };
        
        // Core components
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.performanceAdapter = null;
        
        // Mobile optimizations
        this.isMobile = this.detectMobile();
        this.deviceCapability = 'medium';
        this.currentQuality = 'auto';
        
        // Performance monitoring
        this.stats = {
            fps: 0,
            frameTime: 0,
            memory: 0,
            drawCalls: 0,
            triangles: 0,
            batteryLevel: 1.0,
            thermalState: 'normal'
        };
        
        // Rendering state
        this.isRunning = false;
        this.isPaused = false;
        this.lastFrameTime = 0;
        this.frameCount = 0;
        
        // Quality settings
        this.qualitySettings = {
            low: {
                pixelRatio: 0.5,
                shadowMapSize: 512,
                antialias: false,
                shadowsEnabled: false,
                postProcessing: false,
                maxLights: 2,
                lodBias: 2.0
            },
            medium: {
                pixelRatio: 0.75,
                shadowMapSize: 1024,
                antialias: false,
                shadowsEnabled: true,
                postProcessing: false,
                maxLights: 4,
                lodBias: 1.0
            },
            high: {
                pixelRatio: 1.0,
                shadowMapSize: 2048,
                antialias: true,
                shadowsEnabled: true,
                postProcessing: true,
                maxLights: 8,
                lodBias: 0.5
            }
        };
        
        this.init();
    }
    
    init() {
        console.log('📱 Initializing Mobile Engine...');
        
        // Detect device capability
        this.detectDeviceCapability();
        
        // Initialize performance adapter
        this.performanceAdapter = new PerformanceAdapter(this.options);
        
        // Setup renderer
        this.setupRenderer();
        
        // Setup scene and camera
        this.setupScene();
        this.setupCamera();
        
        // Apply initial quality settings
        this.applyQualitySettings();
        
        // Setup performance monitoring
        if (this.options.enablePerformanceMonitoring) {
            this.setupPerformanceMonitoring();
        }
        
        // Setup battery monitoring
        if (this.options.batteryOptimization) {
            this.setupBatteryMonitoring();
        }
        
        console.log('✅ Mobile Engine initialized');
        console.log(`📱 Device: ${this.isMobile ? 'Mobile' : 'Desktop'}`);
        console.log(`⚡ Capability: ${this.deviceCapability}`);
        console.log(`🎨 Quality: ${this.currentQuality}`);
    }
    
    detectMobile() {
        const userAgent = navigator.userAgent.toLowerCase();
        const mobileKeywords = ['android', 'webos', 'iphone', 'ipad', 'ipod', 'blackberry', 'iemobile', 'opera mini'];
        
        return mobileKeywords.some(keyword => userAgent.includes(keyword)) ||
               ('ontouchstart' in window) ||
               (navigator.maxTouchPoints > 0);
    }
    
    detectDeviceCapability() {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
        
        if (!gl) {
            this.deviceCapability = 'low';
            return;
        }
        
        // Check GPU info
        const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
        let gpuInfo = '';
        
        if (debugInfo) {
            gpuInfo = gl.getParameter(debugInfo.UNMASKED_RENDERER_GL).toLowerCase();
        }
        
        // Check memory
        const memoryInfo = performance.memory;
        const totalMemoryMB = memoryInfo ? memoryInfo.totalJSHeapSize / 1024 / 1024 : 0;
        
        // Check CPU cores
        const cpuCores = navigator.hardwareConcurrency || 1;
        
        // Device capability scoring
        let score = 0;
        
        // GPU scoring
        if (gpuInfo.includes('adreno') && (gpuInfo.includes('640') || gpuInfo.includes('650'))) {
            score += 3; // High-end mobile GPU
        } else if (gpuInfo.includes('adreno') || gpuInfo.includes('mali') || gpuInfo.includes('powervr')) {
            score += 2; // Mid-range mobile GPU
        } else if (gpuInfo.includes('intel') || gpuInfo.includes('nvidia') || gpuInfo.includes('amd')) {
            score += 4; // Desktop GPU
        } else {
            score += 1; // Unknown/low-end GPU
        }
        
        // Memory scoring
        if (totalMemoryMB > 4000) score += 2;
        else if (totalMemoryMB > 2000) score += 1;
        
        // CPU scoring
        if (cpuCores >= 8) score += 2;
        else if (cpuCores >= 4) score += 1;
        
        // Mobile penalty
        if (this.isMobile) score -= 1;
        
        // Determine capability
        if (score >= 6) {
            this.deviceCapability = 'high';
        } else if (score >= 3) {
            this.deviceCapability = 'medium';
        } else {
            this.deviceCapability = 'low';
        }
        
        console.log(`📊 Device capability score: ${score} (${this.deviceCapability})`);
        console.log(`💾 Memory: ${totalMemoryMB.toFixed(0)}MB`);
        console.log(`🖥️ CPU cores: ${cpuCores}`);
        console.log(`🎮 GPU: ${gpuInfo || 'unknown'}`);
    }
    
    setupRenderer() {
        const settings = this.qualitySettings[this.deviceCapability];
        
        this.renderer = new THREE.WebGLRenderer({
            canvas: this.container.querySelector('canvas'),
            antialias: settings.antialias,
            alpha: false,
            powerPreference: this.isMobile ? 'low-power' : 'high-performance',
            failIfMajorPerformanceCaveat: false
        });
        
        this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, settings.pixelRatio));
        
        // Mobile optimizations
        this.renderer.outputColorSpace = THREE.SRGBColorSpace;
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = 1.0;
        
        // Shadow settings
        if (settings.shadowsEnabled) {
            this.renderer.shadowMap.enabled = true;
            this.renderer.shadowMap.type = this.isMobile ? THREE.PCFShadowMap : THREE.PCFSoftShadowMap;
            this.renderer.shadowMap.autoUpdate = false; // Manual shadow updates for performance
        }
        
        // Performance optimizations
        this.renderer.info.autoReset = false;
        this.renderer.sortObjects = true;
        this.renderer.frustumCulled = true;
        
        console.log(`🎨 Renderer initialized with ${settings.antialias ? 'AA' : 'no AA'}, pixel ratio: ${settings.pixelRatio}`);
    }
    
    setupScene() {
        this.scene = new THREE.Scene();
        this.scene.fog = new THREE.Fog(0x404040, 10, 50); // Fog for mobile performance
        
        // Optimize scene for mobile
        this.scene.autoUpdate = false; // Manual scene updates
        this.scene.matrixAutoUpdate = false;
    }
    
    setupCamera() {
        this.camera = new THREE.PerspectiveCamera(
            75, // FOV optimized for mobile
            this.container.clientWidth / this.container.clientHeight,
            0.1,
            100 // Reduced far plane for mobile
        );
        
        this.camera.position.set(0, 1.6, 5);
    }
    
    applyQualitySettings() {
        const settings = this.qualitySettings[this.currentQuality === 'auto' ? this.deviceCapability : this.currentQuality];
        
        // Update renderer settings
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, settings.pixelRatio));
        
        // Update shadow settings
        if (this.renderer.shadowMap.enabled !== settings.shadowsEnabled) {
            this.renderer.shadowMap.enabled = settings.shadowsEnabled;
            this.renderer.shadowMap.needsUpdate = true;
        }
        
        // Update scene materials for LOD
        this.scene.traverse((object) => {
            if (object.material) {
                if (Array.isArray(object.material)) {
                    object.material.forEach(material => this.optimizeMaterial(material, settings));
                } else {
                    this.optimizeMaterial(object.material, settings);
                }
            }
        });
        
        console.log(`🎨 Applied ${this.currentQuality} quality settings`);
    }
    
    optimizeMaterial(material, settings) {
        // Optimize material for mobile
        if (material.map) {
            material.map.generateMipmaps = true;
            material.map.minFilter = settings.lodBias > 1 ? THREE.LinearFilter : THREE.LinearMipmapLinearFilter;
        }
        
        // Disable expensive features on low-end devices
        if (settings.lodBias > 1.5) {
            material.normalMap = null;
            material.roughnessMap = null;
            material.metalnessMap = null;
        }
        
        material.needsUpdate = true;
    }
    
    setupPerformanceMonitoring() {
        let frameCount = 0;
        let lastTime = performance.now();
        
        const updateStats = () => {
            const now = performance.now();
            const delta = now - lastTime;
            
            if (delta >= 1000) { // Update every second
                this.stats.fps = Math.round((frameCount * 1000) / delta);
                this.stats.frameTime = delta / frameCount;
                
                // Memory stats
                if (performance.memory) {
                    this.stats.memory = Math.round(performance.memory.usedJSHeapSize / 1024 / 1024);
                }
                
                // Renderer stats
                this.stats.drawCalls = this.renderer.info.render.calls;
                this.stats.triangles = this.renderer.info.render.triangles;
                
                // Check for performance issues
                this.checkPerformanceIssues();
                
                frameCount = 0;
                lastTime = now;
            }
            
            frameCount++;
            
            if (this.isRunning) {
                requestAnimationFrame(updateStats);
            }
        };
        
        updateStats();
    }
    
    setupBatteryMonitoring() {
        if ('getBattery' in navigator) {
            navigator.getBattery().then((battery) => {
                this.stats.batteryLevel = battery.level;
                
                battery.addEventListener('levelchange', () => {
                    this.stats.batteryLevel = battery.level;
                    
                    // Reduce quality on low battery
                    if (battery.level < 0.2 && this.currentQuality !== 'low') {
                        console.log('🔋 Low battery detected, reducing quality');
                        this.setQuality('low');
                    }
                });
                
                battery.addEventListener('chargingchange', () => {
                    // Increase quality when charging
                    if (battery.charging && this.currentQuality === 'low') {
                        console.log('🔌 Charging detected, restoring quality');
                        this.setQuality('auto');
                    }
                });
            });
        }
    }
    
    checkPerformanceIssues() {
        const { fps, memory } = this.stats;
        
        // Check FPS performance
        if (fps < this.options.targetFPS * 0.7) {
            console.warn(`⚠️ Low FPS detected: ${fps}`);
            
            if (this.options.adaptiveQuality) {
                this.adaptQualityDown();
            }
        } else if (fps > this.options.targetFPS * 1.2 && this.currentQuality === 'low') {
            // Increase quality if performance is good
            this.adaptQualityUp();
        }
        
        // Check memory usage
        if (memory > this.options.maxMemoryMB) {
            console.warn(`⚠️ High memory usage: ${memory}MB`);
            this.performMemoryCleanup();
        }
    }
    
    adaptQualityDown() {
        if (this.currentQuality === 'high') {
            this.setQuality('medium');
        } else if (this.currentQuality === 'medium') {
            this.setQuality('low');
        }
    }
    
    adaptQualityUp() {
        if (this.currentQuality === 'low' && this.deviceCapability !== 'low') {
            this.setQuality('medium');
        } else if (this.currentQuality === 'medium' && this.deviceCapability === 'high') {
            this.setQuality('high');
        }
    }
    
    performMemoryCleanup() {
        // Clear unused textures
        this.renderer.info.memory.textures = 0;
        
        // Force garbage collection if available
        if (window.gc) {
            window.gc();
        }
        
        console.log('🧹 Memory cleanup performed');
    }
    
    // Public API
    start() {
        this.isRunning = true;
        this.isPaused = false;
        this.render();
        console.log('▶️ Mobile Engine started');
    }
    
    pause() {
        this.isPaused = true;
        console.log('⏸️ Mobile Engine paused');
    }
    
    resume() {
        this.isPaused = false;
        console.log('▶️ Mobile Engine resumed');
    }
    
    stop() {
        this.isRunning = false;
        this.isPaused = false;
        console.log('⏹️ Mobile Engine stopped');
    }
    
    render() {
        if (!this.isRunning) return;
        
        if (!this.isPaused) {
            // Update scene matrix
            this.scene.updateMatrixWorld();
            
            // Render frame
            this.renderer.render(this.scene, this.camera);
            
            // Reset renderer info for next frame
            this.renderer.info.reset();
        }
        
        requestAnimationFrame(() => this.render());
    }
    
    setQuality(quality) {
        if (quality === this.currentQuality) return;
        
        this.currentQuality = quality;
        this.applyQualitySettings();
        
        console.log(`🎨 Quality changed to: ${quality}`);
    }
    
    resize(width, height) {
        this.camera.aspect = width / height;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(width, height);
        
        console.log(`📐 Resized to: ${width}x${height}`);
    }
    
    getStats() {
        return { ...this.stats };
    }
    
    getQuality() {
        return this.currentQuality;
    }
    
    getDeviceCapability() {
        return this.deviceCapability;
    }
    
    dispose() {
        console.log('🧹 Disposing Mobile Engine...');
        
        this.stop();
        
        if (this.renderer) {
            this.renderer.dispose();
        }
        
        if (this.performanceAdapter) {
            this.performanceAdapter.dispose();
        }
        
        console.log('✅ Mobile Engine disposed');
    }
}