/**
 * MobilePerformanceOptimizer - Enhanced mobile performance optimization for Three.js
 * Implements touch event throttling, adaptive quality scaling, and device-specific optimizations
 */

export class MobilePerformanceOptimizer {
    constructor(options = {}) {
        this.options = {
            touchThrottleInterval: 16, // 60fps instead of 4ms (240fps)
            useRequestAnimationFrame: true,
            enableAdaptiveQuality: true,
            enableGestures: true,
            sensitivity: 1.0,
            targetFPS: 60,
            memoryThresholdMB: 512,
            ...options
        };
        
        // Device capabilities
        this.deviceCapabilities = this.detectDeviceCapabilities();
        
        // Performance monitoring
        this.performanceMetrics = {
            fps: {
                current: 60,
                average: 60,
                min: 60,
                max: 60,
                history: [],
                target: this.options.targetFPS
            },
            memory: {
                used: 0,
                total: 0,
                percentage: 0,
                textures: 0,
                geometries: 0,
                contexts: 0,
                history: []
            },
            quality: {
                current: 'high',
                renderScale: 1.0,
                textureQuality: 'high',
                effectsEnabled: true
            }
        };
        
        // Touch throttling state
        this.touchThrottleState = {
            lastEventTime: {},
            throttledHandlers: new Map(),
            activeTimers: new Map()
        };
        
        // Adaptive quality state
        this.adaptiveQuality = {
            enabled: this.options.enableAdaptiveQuality,
            performanceDropCount: 0,
            dropThreshold: 3,
            lastAdjustment: 0,
            adjustmentCooldown: 2000 // 2 seconds
        };
        
        // Quality presets
        this.qualityPresets = {
            low: {
                renderScale: 0.5,
                textureQuality: 'low',
                enableShadows: false,
                enablePostProcessing: false,
                enableAntialiasing: false,
                maxTextureSize: 1024,
                cullingDistance: 50
            },
            medium: {
                renderScale: 0.75,
                textureQuality: 'medium',
                enableShadows: false,
                enablePostProcessing: true,
                enableAntialiasing: false,
                maxTextureSize: 2048,
                cullingDistance: 100
            },
            high: {
                renderScale: 1.0,
                textureQuality: 'high',
                enableShadows: true,
                enablePostProcessing: true,
                enableAntialiasing: true,
                maxTextureSize: 4096,
                cullingDistance: 200
            }
        };
        
        // Set initial quality based on device
        this.setQualityForDevice();
        
        console.log('📱 MobilePerformanceOptimizer initialized:', {
            device: this.deviceCapabilities,
            quality: this.performanceMetrics.quality.current,
            touchInterval: this.options.touchThrottleInterval
        });
    }
    
    /**
     * Detect device capabilities for optimization
     */
    detectDeviceCapabilities() {
        const userAgent = navigator.userAgent;
        const isMobile = /Mobile|Android|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(userAgent);
        const isTablet = /iPad|Android.*Tablet|Kindle|Silk/i.test(userAgent);
        const isLowEnd = this.detectLowEndDevice();
        
        // Memory estimation
        let memoryGB = 4; // Default assumption
        if (navigator.deviceMemory) {
            memoryGB = navigator.deviceMemory;
        } else if (isMobile) {
            memoryGB = isTablet ? 3 : 2; // Rough mobile estimation
        }
        
        // CPU cores
        const cores = navigator.hardwareConcurrency || 4;
        
        // WebGL support
        const canvas = document.createElement('canvas');
        const webgl2Support = !!canvas.getContext('webgl2');
        const webgl1Support = !!canvas.getContext('webgl') || !!canvas.getContext('experimental-webgl');
        
        // Touch support
        const supportsTouch = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
        
        // Pixel ratio
        const pixelRatio = window.devicePixelRatio || 1;
        
        return {
            isMobile,
            isTablet,
            isLowEnd,
            memoryGB,
            cores,
            webgl2Support,
            webgl1Support,
            supportsTouch,
            pixelRatio,
            platform: this.detectPlatform(),
            browser: this.detectBrowser()
        };
    }
    
    /**
     * Detect if device is low-end
     */
    detectLowEndDevice() {
        // Check for known low-end indicators
        const userAgent = navigator.userAgent;
        const memoryGB = navigator.deviceMemory || 2;
        const cores = navigator.hardwareConcurrency || 2;
        
        // Low memory or few cores
        if (memoryGB < 3 || cores < 4) return true;
        
        // Known low-end devices
        const lowEndPatterns = [
            /Android.*Go/i,
            /Android.*Lite/i,
            /iPhone.*5/i,
            /iPhone.*6/i
        ];
        
        return lowEndPatterns.some(pattern => pattern.test(userAgent));
    }
    
    /**
     * Detect platform
     */
    detectPlatform() {
        const userAgent = navigator.userAgent;
        if (/Windows/i.test(userAgent)) return 'Windows';
        if (/Mac/i.test(userAgent)) return 'macOS';
        if (/Linux/i.test(userAgent)) return 'Linux';
        if (/Android/i.test(userAgent)) return 'Android';
        if (/iOS|iPhone|iPad/i.test(userAgent)) return 'iOS';
        return 'Unknown';
    }
    
    /**
     * Detect browser
     */
    detectBrowser() {
        const userAgent = navigator.userAgent;
        if (/Chrome/i.test(userAgent)) return 'Chrome';
        if (/Firefox/i.test(userAgent)) return 'Firefox';
        if (/Safari/i.test(userAgent) && !/Chrome/i.test(userAgent)) return 'Safari';
        if (/Edge/i.test(userAgent)) return 'Edge';
        return 'Unknown';
    }
    
    /**
     * Set quality preset based on device capabilities
     */
    setQualityForDevice() {
        let quality = 'high';
        
        if (this.deviceCapabilities.isLowEnd) {
            quality = 'low';
        } else if (this.deviceCapabilities.isMobile) {
            quality = this.deviceCapabilities.memoryGB >= 4 ? 'medium' : 'low';
        } else {
            quality = this.deviceCapabilities.memoryGB >= 8 ? 'high' : 'medium';
        }
        
        this.setQualityLevel(quality);
    }
    
    /**
     * Create throttled touch event handler
     * Reduces touch event frequency from 240fps to 60fps
     */
    throttleTouchEvents(eventHandler, customInterval = null) {
        const interval = customInterval || this.options.touchThrottleInterval;
        const handlerId = Math.random().toString(36).substring(2, 9);
        
        const throttledHandler = (event) => {
            const eventType = event.type;
            const now = performance.now();
            const lastTime = this.touchThrottleState.lastEventTime[eventType] || 0;
            
            if (now - lastTime >= interval) {
                this.touchThrottleState.lastEventTime[eventType] = now;
                
                if (this.options.useRequestAnimationFrame) {
                    // Use requestAnimationFrame for smooth visual updates
                    requestAnimationFrame(() => {
                        try {
                            eventHandler(event);
                        } catch (error) {
                            console.error('❌ Error in throttled touch handler:', error);
                        }
                    });
                } else {
                    // Direct execution
                    try {
                        eventHandler(event);
                    } catch (error) {
                        console.error('❌ Error in throttled touch handler:', error);
                    }
                }
            }
        };
        
        // Store handler for cleanup
        this.touchThrottleState.throttledHandlers.set(handlerId, throttledHandler);
        
        return {
            handler: throttledHandler,
            id: handlerId,
            dispose: () => this.disposeTouchHandler(handlerId)
        };
    }
    
    /**
     * Dispose of touch handler
     */
    disposeTouchHandler(handlerId) {
        this.touchThrottleState.throttledHandlers.delete(handlerId);
        
        const timer = this.touchThrottleState.activeTimers.get(handlerId);
        if (timer) {
            clearTimeout(timer);
            this.touchThrottleState.activeTimers.delete(handlerId);
        }
    }
    
    /**
     * Update performance metrics
     */
    updatePerformanceMetrics(fps, memoryUsage = {}) {
        // Update FPS metrics
        this.performanceMetrics.fps.current = fps;
        this.performanceMetrics.fps.history.push(fps);
        
        // Keep history limited
        if (this.performanceMetrics.fps.history.length > 60) {
            this.performanceMetrics.fps.history.shift();
        }
        
        // Calculate statistics
        const fpsHistory = this.performanceMetrics.fps.history;
        if (fpsHistory.length > 0) {
            this.performanceMetrics.fps.average = fpsHistory.reduce((a, b) => a + b) / fpsHistory.length;
            this.performanceMetrics.fps.min = Math.min(...fpsHistory);
            this.performanceMetrics.fps.max = Math.max(...fpsHistory);
        }
        
        // Update memory metrics
        if (memoryUsage.used !== undefined) {
            this.performanceMetrics.memory.used = memoryUsage.used;
            this.performanceMetrics.memory.total = memoryUsage.total || 0;
            this.performanceMetrics.memory.percentage = memoryUsage.total > 0 ? 
                (memoryUsage.used / memoryUsage.total) * 100 : 0;
            this.performanceMetrics.memory.textures = memoryUsage.textures || 0;
            this.performanceMetrics.memory.geometries = memoryUsage.geometries || 0;
            this.performanceMetrics.memory.contexts = memoryUsage.contexts || 0;
            
            this.performanceMetrics.memory.history.push(memoryUsage.used);
            if (this.performanceMetrics.memory.history.length > 60) {
                this.performanceMetrics.memory.history.shift();
            }
        }
        
        // Check for adaptive quality adjustment
        if (this.adaptiveQuality.enabled) {
            this.checkPerformanceAndAdjust();
        }
        
        // Send metrics to Flutter if available
        this.sendMetricsToFlutter();
    }
    
    /**
     * Check performance and automatically adjust quality
     */
    checkPerformanceAndAdjust() {
        const now = performance.now();
        if (now - this.adaptiveQuality.lastAdjustment < this.adaptiveQuality.adjustmentCooldown) {
            return; // Too soon since last adjustment
        }
        
        const fps = this.performanceMetrics.fps;
        const targetFPS = fps.target;
        
        // Check if performance is consistently below target
        if (fps.average < targetFPS * 0.8) { // 80% of target FPS
            this.adaptiveQuality.performanceDropCount++;
            
            if (this.adaptiveQuality.performanceDropCount >= this.adaptiveQuality.dropThreshold) {
                this.reduceQuality();
                this.adaptiveQuality.performanceDropCount = 0;
                this.adaptiveQuality.lastAdjustment = now;
            }
        } else if (fps.average > targetFPS * 0.95) { // 95% of target FPS
            this.adaptiveQuality.performanceDropCount = 0;
            
            // Consider increasing quality if performance is good
            if (fps.average > targetFPS && this.performanceMetrics.memory.used < 400) {
                this.increaseQuality();
                this.adaptiveQuality.lastAdjustment = now;
            }
        }
    }
    
    /**
     * Reduce quality for better performance
     */
    reduceQuality() {
        const currentQuality = this.performanceMetrics.quality.current;
        let newQuality = currentQuality;
        
        if (currentQuality === 'high') {
            newQuality = 'medium';
        } else if (currentQuality === 'medium') {
            newQuality = 'low';
        }
        
        if (newQuality !== currentQuality) {
            this.setQualityLevel(newQuality);
            console.log(`📉 Quality reduced to: ${newQuality}`, {
                averageFPS: this.performanceMetrics.fps.average,
                targetFPS: this.performanceMetrics.fps.target,
                memoryMB: this.performanceMetrics.memory.used
            });
        }
    }
    
    /**
     * Increase quality if performance allows
     */
    increaseQuality() {
        const currentQuality = this.performanceMetrics.quality.current;
        let newQuality = currentQuality;
        
        if (currentQuality === 'low') {
            newQuality = 'medium';
        } else if (currentQuality === 'medium') {
            newQuality = 'high';
        }
        
        if (newQuality !== currentQuality) {
            this.setQualityLevel(newQuality);
            console.log(`📈 Quality increased to: ${newQuality}`, {
                averageFPS: this.performanceMetrics.fps.average,
                targetFPS: this.performanceMetrics.fps.target,
                memoryMB: this.performanceMetrics.memory.used
            });
        }
    }
    
    /**
     * Set quality level
     */
    setQualityLevel(quality) {
        if (!this.qualityPresets[quality]) {
            console.warn(`⚠️ Unknown quality level: ${quality}`);
            return;
        }
        
        const preset = this.qualityPresets[quality];
        this.performanceMetrics.quality = {
            current: quality,
            renderScale: preset.renderScale,
            textureQuality: preset.textureQuality,
            effectsEnabled: preset.enablePostProcessing
        };
        
        console.log(`🎯 Quality set to: ${quality}`, preset);
    }
    
    /**
     * Get device-specific performance settings
     */
    getPerformanceSettings() {
        const settings = {
            ...this.qualityPresets[this.performanceMetrics.quality.current],
            touchThrottleInterval: this.options.touchThrottleInterval,
            useRequestAnimationFrame: this.options.useRequestAnimationFrame,
            sensitivity: this.getTouchSensitivity(),
            enableGestures: this.options.enableGestures
        };
        
        // Mobile-specific optimizations
        if (this.deviceCapabilities.isMobile) {
            settings.enableShadows = false; // Always disable shadows on mobile
            settings.enableLOD = true;
            settings.pixelRatio = this.deviceCapabilities.isLowEnd ? 1.0 : Math.min(this.deviceCapabilities.pixelRatio, 2.0);
        }
        
        // Browser-specific optimizations
        if (this.deviceCapabilities.browser === 'Safari') {
            settings.enableWebGL2 = false; // Safari WebGL2 issues
            settings.precision = 'mediump';
            settings.enableFloatTextures = false;
        }
        
        return settings;
    }
    
    /**
     * Get device-specific touch sensitivity
     */
    getTouchSensitivity() {
        let sensitivity = this.options.sensitivity;
        
        // Adjust for device type
        if (this.deviceCapabilities.isMobile) {
            if (this.deviceCapabilities.isTablet) {
                sensitivity *= 0.8; // Tablets need less sensitivity
            } else {
                sensitivity *= 1.2; // Phones need more sensitivity
            }
        }
        
        // Adjust for pixel ratio
        if (this.deviceCapabilities.pixelRatio > 2.0) {
            sensitivity *= 0.9; // High DPI screens
        }
        
        return sensitivity;
    }
    
    /**
     * Send performance metrics to Flutter
     */
    sendMetricsToFlutter() {
        if (window.parent && window.parent !== window) {
            try {
                window.parent.postMessage({
                    type: 'mobile_performance_update',
                    source: 'threejs',
                    payload: {
                        fps: this.performanceMetrics.fps,
                        memory: this.performanceMetrics.memory,
                        quality: this.performanceMetrics.quality,
                        device: this.deviceCapabilities
                    },
                    timestamp: Date.now()
                }, '*');
            } catch (error) {
                console.warn('⚠️ Failed to send metrics to Flutter:', error);
            }
        }
    }
    
    /**
     * Enable/disable adaptive quality scaling
     */
    setAdaptiveQualityEnabled(enabled) {
        this.adaptiveQuality.enabled = enabled;
        console.log(`🔄 Adaptive quality scaling ${enabled ? 'enabled' : 'disabled'}`);
    }
    
    /**
     * Get performance statistics
     */
    getPerformanceStats() {
        return {
            fps: this.performanceMetrics.fps,
            memory: this.performanceMetrics.memory,
            quality: this.performanceMetrics.quality,
            device: this.deviceCapabilities,
            adaptiveQuality: {
                enabled: this.adaptiveQuality.enabled,
                performanceDropCount: this.adaptiveQuality.performanceDropCount
            }
        };
    }
    
    /**
     * Dispose of optimizer
     */
    dispose() {
        // Clear all throttled handlers
        for (const [handlerId] of this.touchThrottleState.throttledHandlers) {
            this.disposeTouchHandler(handlerId);
        }
        
        // Clear timers
        for (const timer of this.touchThrottleState.activeTimers.values()) {
            clearTimeout(timer);
        }
        
        // Clear state
        this.touchThrottleState.throttledHandlers.clear();
        this.touchThrottleState.activeTimers.clear();
        this.performanceMetrics.fps.history = [];
        this.performanceMetrics.memory.history = [];
        
        console.log('🗑️ MobilePerformanceOptimizer disposed');
    }
}

// Export for global use
window.MobilePerformanceOptimizer = MobilePerformanceOptimizer;