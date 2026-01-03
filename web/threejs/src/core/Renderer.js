/**
 * Professional WebGL Renderer
 * Handles WebGL context creation with fallback strategies
 */

import * as THREE from 'three';

export class Renderer {
    constructor(container, options = {}) {
        this.container = container;
        this.options = {
            antialias: false,
            alpha: true,
            powerPreference: 'high-performance',
            stencil: false,
            depth: true,
            logarithmicDepthBuffer: false,
            ...options
        };
        
        this.renderer = null;
        this.isWebGL2 = false;
        this.capabilities = null;
        
        this.init();
    }
    
    init() {
        console.log('🎨 Initializing WebGL Renderer...');
        
        // Detect device capabilities
        this.detectCapabilities();
        
        // Create renderer with fallback strategy
        this.renderer = this.createRendererWithFallback();
        
        if (!this.renderer) {
            throw new Error('Failed to create WebGL renderer');
        }
        
        // Configure renderer
        this.configureRenderer();
        
        // Add to container
        this.container.appendChild(this.renderer.domElement);
        
        console.log('✅ WebGL Renderer initialized:', {
            webgl2: this.isWebGL2,
            pixelRatio: this.renderer.getPixelRatio(),
            capabilities: this.capabilities
        });
    }
    
    detectCapabilities() {
        const canvas = document.createElement('canvas');
        
        // Test WebGL 2.0
        let context = canvas.getContext('webgl2');
        if (context) {
            this.isWebGL2 = true;
            this.capabilities = this.analyzeContext(context, 'webgl2');
            return;
        }
        
        // Test WebGL 1.0
        context = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        if (context) {
            this.isWebGL2 = false;
            this.capabilities = this.analyzeContext(context, 'webgl');
            return;
        }
        
        throw new Error('WebGL not supported');
    }
    
    analyzeContext(gl, version) {
        const capabilities = {
            version,
            vendor: gl.getParameter(gl.VENDOR),
            renderer: gl.getParameter(gl.RENDERER),
            maxTextureSize: gl.getParameter(gl.MAX_TEXTURE_SIZE),
            maxVertexAttributes: gl.getParameter(gl.MAX_VERTEX_ATTRIBS),
            maxFragmentUniforms: gl.getParameter(gl.MAX_FRAGMENT_UNIFORM_VECTORS),
            maxVertexUniforms: gl.getParameter(gl.MAX_VERTEX_UNIFORM_VECTORS),
            extensions: gl.getSupportedExtensions() || []
        };
        
        // WebGL 2.0 specific
        if (version === 'webgl2') {
            capabilities.maxDrawBuffers = gl.getParameter(gl.MAX_DRAW_BUFFERS);
            capabilities.maxColorAttachments = gl.getParameter(gl.MAX_COLOR_ATTACHMENTS);
        }
        
        return capabilities;
    }
    
    createRendererWithFallback() {
        const strategies = [
            // Strategy 1: WebGL 2.0 with full options
            () => this.createRenderer({ 
                ...this.options,
                context: this.isWebGL2 ? 'webgl2' : null 
            }),
            
            // Strategy 2: WebGL 1.0 with full options
            () => this.createRenderer({ 
                ...this.options,
                context: 'webgl' 
            }),
            
            // Strategy 3: Reduced options for compatibility
            () => this.createRenderer({
                antialias: false,
                alpha: false,
                powerPreference: 'low-power',
                stencil: false,
                depth: true
            }),
            
            // Strategy 4: Minimal options (last resort)
            () => this.createRenderer({
                antialias: false,
                alpha: false,
                powerPreference: 'low-power'
            })
        ];
        
        for (let i = 0; i < strategies.length; i++) {
            try {
                const renderer = strategies[i]();
                if (renderer) {
                    console.log(`✅ Renderer created with strategy ${i + 1}`);
                    return renderer;
                }
            } catch (error) {
                console.warn(`⚠️ Renderer strategy ${i + 1} failed:`, error.message);
            }
        }
        
        return null;
    }
    
    createRenderer(options) {
        const canvas = document.createElement('canvas');
        const context = canvas.getContext(options.context || 'webgl', options);
        
        if (!context) {
            throw new Error(`Failed to create ${options.context || 'webgl'} context`);
        }
        
        return new THREE.WebGLRenderer({
            canvas,
            context,
            ...options
        });
    }
    
    configureRenderer() {
        const { renderer } = this;
        
        // Basic setup
        renderer.setSize(window.innerWidth, window.innerHeight);
        renderer.setPixelRatio(this.getOptimalPixelRatio());
        
        // Color management
        renderer.outputColorSpace = THREE.SRGBColorSpace;
        renderer.toneMapping = THREE.ACESFilmicToneMapping;
        renderer.toneMappingExposure = 1.0;
        
        // Shadows (conditional)
        if (this.shouldEnableShadows()) {
            renderer.shadowMap.enabled = true;
            renderer.shadowMap.type = THREE.PCFSoftShadowMap;
        }
        
        // Performance optimizations
        renderer.info.autoReset = true;
        renderer.sortObjects = true;
        renderer.autoClear = true;
        
        // Mobile optimizations
        if (this.isMobileDevice()) {
            renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5));
            renderer.shadowMap.enabled = false;
        }
    }
    
    getOptimalPixelRatio() {
        const devicePixelRatio = window.devicePixelRatio || 1;
        
        // Limit pixel ratio based on device capabilities
        if (this.isMobileDevice()) {
            return Math.min(devicePixelRatio, 1.5);
        }
        
        if (this.isLowEndDevice()) {
            return Math.min(devicePixelRatio, 1.0);
        }
        
        return Math.min(devicePixelRatio, 2.0);
    }
    
    shouldEnableShadows() {
        // Disable shadows on low-end devices
        if (this.isLowEndDevice() || this.isMobileDevice()) {
            return false;
        }
        
        // Check if device supports shadow mapping
        const extensions = this.capabilities?.extensions || [];
        return extensions.includes('WEBGL_depth_texture');
    }
    
    isMobileDevice() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    }
    
    isLowEndDevice() {
        // Heuristics for low-end device detection
        const memory = navigator.deviceMemory || 4;
        const cores = navigator.hardwareConcurrency || 4;
        
        return memory <= 2 || cores <= 2;
    }
    
    // Public API
    render(scene, camera) {
        if (this.renderer) {
            this.renderer.render(scene, camera);
        }
    }
    
    setSize(width, height) {
        if (this.renderer) {
            this.renderer.setSize(width, height);
        }
    }
    
    setPixelRatio(ratio) {
        if (this.renderer) {
            this.renderer.setPixelRatio(ratio);
        }
    }
    
    getPixelRatio() {
        return this.renderer ? this.renderer.getPixelRatio() : 1;
    }
    
    getInfo() {
        if (!this.renderer) return null;
        
        const info = this.renderer.info;
        return {
            geometries: info.memory.geometries,
            textures: info.memory.textures,
            triangles: info.render.triangles,
            points: info.render.points,
            lines: info.render.lines,
            calls: info.render.calls,
            frame: info.render.frame
        };
    }
    
    getCapabilities() {
        return this.capabilities;
    }
    
    dispose() {
        if (this.renderer) {
            this.renderer.dispose();
            
            // Remove canvas from container
            if (this.renderer.domElement && this.renderer.domElement.parentNode) {
                this.renderer.domElement.parentNode.removeChild(this.renderer.domElement);
            }
            
            this.renderer = null;
        }
    }
}