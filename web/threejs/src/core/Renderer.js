/**
 * Renderer - Three.js renderer setup and management
 */

import * as THREE from 'three';

export class Renderer {
    constructor(container, options = {}) {
        this.container = container;
        this.options = {
            antialias: true,
            powerPreference: 'high-performance',
            enableShadows: true,
            shadowMapType: THREE.PCFSoftShadowMap,
            pixelRatio: Math.min(window.devicePixelRatio, 2),
            outputColorSpace: THREE.SRGBColorSpace,
            ...options
        };
        
        this.renderer = null;
        this.stats = null;
        
        this.setupRenderer();
        this.setupEventListeners();
        
        console.log('✅ Renderer initialized');
    }

    /**
     * Setup Three.js renderer
     */
    setupRenderer() {
        // Create WebGL renderer
        this.renderer = new THREE.WebGLRenderer({
            antialias: this.options.antialias,
            powerPreference: this.options.powerPreference
        });
        
        // Set size
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        this.renderer.setPixelRatio(this.options.pixelRatio);
        
        // Configure shadows
        if (this.options.enableShadows) {
            this.renderer.shadowMap.enabled = true;
            this.renderer.shadowMap.type = this.options.shadowMapType;
        }
        
        // Set color space
        this.renderer.outputColorSpace = this.options.outputColorSpace;
        
        // Add to container
        this.container.appendChild(this.renderer.domElement);
        
        console.log('🖥️ WebGL renderer created and added to DOM');
    }

    /**
     * Setup event listeners
     */
    setupEventListeners() {
        // Handle window resize
        window.addEventListener('resize', () => this.onWindowResize());
        
        // Handle visibility change for performance
        document.addEventListener('visibilitychange', () => this.onVisibilityChange());
    }

    /**
     * Handle window resize
     */
    onWindowResize() {
        const width = window.innerWidth;
        const height = window.innerHeight;
        
        this.renderer.setSize(width, height);
        
        // Emit resize event for camera and other systems
        if (window.classroomViewer && window.classroomViewer.onResize) {
            window.classroomViewer.onResize(width, height);
        }
        
        console.log(`📐 Renderer resized to ${width}×${height}`);
    }

    /**
     * Handle visibility change
     */
    onVisibilityChange() {
        if (document.hidden) {
            console.log('📱 Page hidden - renderer can be paused');
        } else {
            console.log('📱 Page visible - renderer resumed');
        }
        
        // Emit visibility change event
        if (window.classroomViewer && window.classroomViewer.onVisibilityChange) {
            window.classroomViewer.onVisibilityChange(!document.hidden);
        }
    }

    /**
     * Render scene with camera
     * @param {THREE.Scene} scene - Scene to render
     * @param {THREE.Camera} camera - Camera to render with
     */
    render(scene, camera) {
        this.renderer.render(scene, camera);
    }

    /**
     * Get renderer instance
     * @returns {THREE.WebGLRenderer} Renderer instance
     */
    getRenderer() {
        return this.renderer;
    }

    /**
     * Get renderer DOM element
     * @returns {HTMLCanvasElement} Canvas element
     */
    getDomElement() {
        return this.renderer.domElement;
    }

    /**
     * Set pixel ratio
     * @param {number} ratio - Pixel ratio
     */
    setPixelRatio(ratio) {
        this.options.pixelRatio = ratio;
        this.renderer.setPixelRatio(ratio);
    }

    /**
     * Enable/disable shadows
     * @param {boolean} enabled - Whether shadows should be enabled
     */
    setShadowsEnabled(enabled) {
        this.options.enableShadows = enabled;
        this.renderer.shadowMap.enabled = enabled;
    }

    /**
     * Set shadow map type
     * @param {number} type - Shadow map type (THREE.BasicShadowMap, THREE.PCFShadowMap, etc.)
     */
    setShadowMapType(type) {
        this.options.shadowMapType = type;
        this.renderer.shadowMap.type = type;
    }

    /**
     * Get renderer info for debugging
     * @returns {Object} Renderer information
     */
    getInfo() {
        return {
            memory: this.renderer.info.memory,
            render: this.renderer.info.render,
            capabilities: {
                maxTextures: this.renderer.capabilities.maxTextures,
                maxVertexTextures: this.renderer.capabilities.maxVertexTextures,
                maxTextureSize: this.renderer.capabilities.maxTextureSize,
                maxCubemapSize: this.renderer.capabilities.maxCubemapSize,
                maxAttributes: this.renderer.capabilities.maxAttributes,
                maxVertexUniforms: this.renderer.capabilities.maxVertexUniforms,
                maxFragmentUniforms: this.renderer.capabilities.maxFragmentUniforms
            },
            extensions: this.renderer.extensions,
            pixelRatio: this.renderer.getPixelRatio(),
            size: this.renderer.getSize(new THREE.Vector2())
        };
    }

    /**
     * Take screenshot of current render
     * @param {string} format - Image format ('image/png', 'image/jpeg')
     * @param {number} quality - Image quality (0-1, for JPEG)
     * @returns {string} Data URL of screenshot
     */
    takeScreenshot(format = 'image/png', quality = 0.9) {
        return this.renderer.domElement.toDataURL(format, quality);
    }

    /**
     * Clear renderer
     * @param {boolean} color - Clear color buffer
     * @param {boolean} depth - Clear depth buffer
     * @param {boolean} stencil - Clear stencil buffer
     */
    clear(color = true, depth = true, stencil = true) {
        this.renderer.clear(color, depth, stencil);
    }

    /**
     * Set clear color
     * @param {number} color - Hex color value
     * @param {number} alpha - Alpha value (0-1)
     */
    setClearColor(color, alpha = 1) {
        this.renderer.setClearColor(color, alpha);
    }

    /**
     * Dispose of resources
     */
    dispose() {
        // Remove event listeners
        window.removeEventListener('resize', this.onWindowResize);
        document.removeEventListener('visibilitychange', this.onVisibilityChange);
        
        // Remove from DOM
        if (this.renderer.domElement.parentNode) {
            this.renderer.domElement.parentNode.removeChild(this.renderer.domElement);
        }
        
        // Dispose renderer
        this.renderer.dispose();
        this.renderer = null;
        
        console.log('🗑️ Renderer disposed');
    }
}