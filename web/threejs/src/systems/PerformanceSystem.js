/**
 * PerformanceSystem - Professional performance monitoring and quality scaling
 * Handles FPS monitoring, memory tracking, and automatic quality adjustment
 */

export class PerformanceSystem {
    constructor(options = {}) {
        this.options = {
            targetFPS: 60,
            minFPS: 30,
            maxFPS: 120,
            enableAutoScaling: true,
            enableProfiling: true,
            enableMemoryMonitoring: true,
            scalingInterval: 2000, // 2 seconds
            memoryWarningThreshold: 0.8, // 80% of available memory
            memoryErrorThreshold: 0.95, // 95% of available memory
            ...options
        };
        
        // Performance metrics
        this.fps = 0;
        this.frameTime = 0;
        this.averageFPS = 0;
        this.minFPS = Infinity;
        this.maxFPS = 0;
        
        // Frame timing
        this.frameCount = 0;
        this.lastTime = 0;
        this.fpsHistory = [];
        this.frameTimeHistory = [];
        
        // Memory monitoring
        this.memoryUsage = {
            used: 0,
            total: 0,
            percentage: 0
        };
        
        // Quality scaling
        this.currentQuality = 'high';
        this.qualityLevels = new Map([
            ['ultra', { renderScale: 1.2, shadowQuality: 'high', textureQuality: 'high', effectsEnabled: true }],
            ['high', { renderScale: 1.0, shadowQuality: 'high', textureQuality: 'high', effectsEnabled: true }],
            ['medium', { renderScale: 0.8, shadowQuality: 'medium', textureQuality: 'medium', effectsEnabled: true }],
            ['low', { renderScale: 0.6, shadowQuality: 'low', textureQuality: 'low', effectsEnabled: false }],
            ['potato', { renderScale: 0.4, shadowQuality: 'off', textureQuality: 'low', effectsEnabled: false }]
        ]);
        
        // Profiling
        this.profiler = {
            enabled: this.options.enableProfiling,
            markers: new Map(),
            timings: new Map(),
            currentFrame: new Map()
        };
        
        // Auto-scaling
        this.autoScaling = {
            enabled: this.options.enableAutoScaling,
            lastCheck: 0,
            consecutiveLowFPS: 0,
            consecutiveHighFPS: 0,
            scalingCooldown: 0
        };
        
        // Performance warnings
        this.warnings = {
            lowFPS: false,
            highMemory: false,
            longFrameTime: false
        };
        
        // Callbacks
        this.callbacks = new Map();
        
        console.log('✅ PerformanceSystem initialized with quality scaling');
    }

    /**
     * Initialize performance system
     */
    async initialize() {
        // Detect device capabilities
        await this.detectDeviceCapabilities();
        
        // Set initial quality based on device
        this.setInitialQuality();
        
        // Start monitoring
        this.startMonitoring();
        
        console.log('📊 PerformanceSystem initialized');
    }

    /**
     * Detect device capabilities
     */
    async detectDeviceCapabilities() {
        this.deviceInfo = {
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
                this.deviceInfo.webglVersion = gl.getParameter(gl.VERSION);
                this.deviceInfo.maxTextureSize = gl.getParameter(gl.MAX_TEXTURE_SIZE);
                
                // Estimate if device is low-end based on WebGL info
                const renderer = gl.getParameter(gl.RENDERER).toLowerCase();
                this.deviceInfo.isLowEnd = renderer.includes('mali') || 
                                          renderer.includes('adreno 3') || 
                                          renderer.includes('powervr');
            }
        } catch (error) {
            console.warn('⚠️ Could not detect WebGL capabilities:', error);
        }
        
        // Estimate memory if available
        if (navigator.deviceMemory) {
            this.deviceInfo.memoryGB = navigator.deviceMemory;
        }
        
        console.log('🔍 Device capabilities detected:', this.deviceInfo);
    }

    /**
     * Set initial quality based on device capabilities
     */
    setInitialQuality() {
        let initialQuality = 'high';
        
        if (this.deviceInfo.isMobile) {
            if (this.deviceInfo.isLowEnd || this.deviceInfo.memoryGB < 3) {
                initialQuality = 'low';
            } else if (this.deviceInfo.memoryGB < 6) {
                initialQuality = 'medium';
            }
        } else {
            // Desktop - can handle higher quality
            if (this.deviceInfo.memoryGB >= 16 && this.deviceInfo.cores >= 8) {
                initialQuality = 'ultra';
            }
        }
        
        this.setQuality(initialQuality);
        console.log(`🎯 Initial quality set to: ${initialQuality}`);
    }

    /**
     * Start performance monitoring
     */
    startMonitoring() {
        this.lastTime = performance.now();
        
        // Start FPS monitoring
        this.monitoringInterval = setInterval(() => {
            this.updateMetrics();
            this.checkAutoScaling();
            this.checkMemoryUsage();
            this.checkWarnings();
        }, 100); // Check every 100ms
        
        console.log('📊 Performance monitoring started');
    }

    /**
     * Update performance metrics (call every frame)
     * @param {number} timestamp - Current timestamp
     */
    update(timestamp) {
        // Calculate frame time
        const deltaTime = timestamp - this.lastTime;
        this.frameTime = deltaTime;
        this.lastTime = timestamp;
        
        // Calculate FPS
        this.fps = 1000 / deltaTime;
        this.frameCount++;
        
        // Update history
        this.fpsHistory.push(this.fps);
        this.frameTimeHistory.push(deltaTime);
        
        // Keep history size manageable
        if (this.fpsHistory.length > 300) { // 5 seconds at 60fps
            this.fpsHistory.shift();
            this.frameTimeHistory.shift();
        }
        
        // Update profiler
        if (this.profiler.enabled) {
            this.updateProfiler(timestamp);
        }
    }

    /**
     * Update performance metrics
     */
    updateMetrics() {
        if (this.fpsHistory.length === 0) return;
        
        // Calculate average FPS
        this.averageFPS = this.fpsHistory.reduce((a, b) => a + b, 0) / this.fpsHistory.length;
        
        // Calculate min/max FPS
        this.minFPS = Math.min(...this.fpsHistory);
        this.maxFPS = Math.max(...this.fpsHistory);
        
        // Update memory usage
        this.updateMemoryUsage();
    }

    /**
     * Update memory usage
     */
    updateMemoryUsage() {
        if (performance.memory) {
            this.memoryUsage.used = performance.memory.usedJSHeapSize;
            this.memoryUsage.total = performance.memory.jsHeapSizeLimit;
            this.memoryUsage.percentage = this.memoryUsage.used / this.memoryUsage.total;
        }
    }

    /**
     * Check auto-scaling conditions
     */
    checkAutoScaling() {
        if (!this.autoScaling.enabled) return;
        
        const now = performance.now();
        
        // Check cooldown
        if (now - this.autoScaling.lastCheck < this.options.scalingInterval) return;
        
        // Check if scaling is on cooldown
        if (this.autoScaling.scalingCooldown > 0) {
            this.autoScaling.scalingCooldown -= (now - this.autoScaling.lastCheck);
            this.autoScaling.lastCheck = now;
            return;
        }
        
        const avgFPS = this.averageFPS;
        
        // Check for consistent low FPS
        if (avgFPS < this.options.minFPS) {
            this.autoScaling.consecutiveLowFPS++;
            this.autoScaling.consecutiveHighFPS = 0;
            
            if (this.autoScaling.consecutiveLowFPS >= 3) {
                this.scaleQualityDown();
                this.autoScaling.consecutiveLowFPS = 0;
                this.autoScaling.scalingCooldown = 5000; // 5 second cooldown
            }
        }
        // Check for consistent high FPS (can scale up)
        else if (avgFPS > this.options.targetFPS + 10) {
            this.autoScaling.consecutiveHighFPS++;
            this.autoScaling.consecutiveLowFPS = 0;
            
            if (this.autoScaling.consecutiveHighFPS >= 5) {
                this.scaleQualityUp();
                this.autoScaling.consecutiveHighFPS = 0;
                this.autoScaling.scalingCooldown = 10000; // 10 second cooldown
            }
        }
        // Reset counters if FPS is stable
        else {
            this.autoScaling.consecutiveLowFPS = 0;
            this.autoScaling.consecutiveHighFPS = 0;
        }
        
        this.autoScaling.lastCheck = now;
    }

    /**
     * Check memory usage
     */
    checkMemoryUsage() {
        if (!this.options.enableMemoryMonitoring) return;
        
        const memoryPercentage = this.memoryUsage.percentage;
        
        if (memoryPercentage > this.options.memoryErrorThreshold) {
            this.triggerCallback('memoryError', {
                usage: memoryPercentage,
                used: this.memoryUsage.used,
                total: this.memoryUsage.total
            });
        } else if (memoryPercentage > this.options.memoryWarningThreshold) {
            this.triggerCallback('memoryWarning', {
                usage: memoryPercentage,
                used: this.memoryUsage.used,
                total: this.memoryUsage.total
            });
        }
    }

    /**
     * Check performance warnings
     */
    checkWarnings() {
        const avgFPS = this.averageFPS;
        const memoryPercentage = this.memoryUsage.percentage;
        const avgFrameTime = this.frameTimeHistory.length > 0 ? 
            this.frameTimeHistory.reduce((a, b) => a + b, 0) / this.frameTimeHistory.length : 0;
        
        // Low FPS warning
        if (avgFPS < this.options.minFPS && !this.warnings.lowFPS) {
            this.warnings.lowFPS = true;
            this.triggerCallback('lowFPS', { fps: avgFPS });
        } else if (avgFPS >= this.options.minFPS && this.warnings.lowFPS) {
            this.warnings.lowFPS = false;
            this.triggerCallback('fpsRecovered', { fps: avgFPS });
        }
        
        // High memory warning
        if (memoryPercentage > this.options.memoryWarningThreshold && !this.warnings.highMemory) {
            this.warnings.highMemory = true;
            this.triggerCallback('highMemory', { percentage: memoryPercentage });
        } else if (memoryPercentage <= this.options.memoryWarningThreshold && this.warnings.highMemory) {
            this.warnings.highMemory = false;
            this.triggerCallback('memoryRecovered', { percentage: memoryPercentage });
        }
        
        // Long frame time warning
        if (avgFrameTime > 33.33 && !this.warnings.longFrameTime) { // > 30 FPS
            this.warnings.longFrameTime = true;
            this.triggerCallback('longFrameTime', { frameTime: avgFrameTime });
        } else if (avgFrameTime <= 33.33 && this.warnings.longFrameTime) {
            this.warnings.longFrameTime = false;
            this.triggerCallback('frameTimeRecovered', { frameTime: avgFrameTime });
        }
    }

    /**
     * Scale quality down
     */
    scaleQualityDown() {
        const qualityLevels = Array.from(this.qualityLevels.keys());
        const currentIndex = qualityLevels.indexOf(this.currentQuality);
        
        if (currentIndex < qualityLevels.length - 1) {
            const newQuality = qualityLevels[currentIndex + 1];
            this.setQuality(newQuality);
            
            console.log(`📉 Quality scaled down to: ${newQuality} (FPS: ${this.averageFPS.toFixed(1)})`);
            this.triggerCallback('qualityScaled', { 
                quality: newQuality, 
                direction: 'down', 
                reason: 'low_fps',
                fps: this.averageFPS 
            });
        }
    }

    /**
     * Scale quality up
     */
    scaleQualityUp() {
        const qualityLevels = Array.from(this.qualityLevels.keys());
        const currentIndex = qualityLevels.indexOf(this.currentQuality);
        
        if (currentIndex > 0) {
            const newQuality = qualityLevels[currentIndex - 1];
            this.setQuality(newQuality);
            
            console.log(`📈 Quality scaled up to: ${newQuality} (FPS: ${this.averageFPS.toFixed(1)})`);
            this.triggerCallback('qualityScaled', { 
                quality: newQuality, 
                direction: 'up', 
                reason: 'high_fps',
                fps: this.averageFPS 
            });
        }
    }

    /**
     * Set quality level
     * @param {string} quality - Quality level
     */
    setQuality(quality) {
        if (!this.qualityLevels.has(quality)) {
            console.warn(`⚠️ Unknown quality level: ${quality}`);
            return;
        }
        
        this.currentQuality = quality;
        const qualitySettings = this.qualityLevels.get(quality);
        
        this.triggerCallback('qualityChanged', {
            quality: quality,
            settings: qualitySettings
        });
        
        console.log(`🎯 Quality set to: ${quality}`, qualitySettings);
    }

    /**
     * Start profiling marker
     * @param {string} name - Marker name
     */
    startProfiler(name) {
        if (!this.profiler.enabled) return;
        
        this.profiler.currentFrame.set(name, performance.now());
    }

    /**
     * End profiling marker
     * @param {string} name - Marker name
     */
    endProfiler(name) {
        if (!this.profiler.enabled) return;
        
        const startTime = this.profiler.currentFrame.get(name);
        if (startTime !== undefined) {
            const duration = performance.now() - startTime;
            
            if (!this.profiler.timings.has(name)) {
                this.profiler.timings.set(name, []);
            }
            
            const timings = this.profiler.timings.get(name);
            timings.push(duration);
            
            // Keep only recent timings
            if (timings.length > 100) {
                timings.shift();
            }
            
            this.profiler.currentFrame.delete(name);
        }
    }

    /**
     * Update profiler
     * @param {number} timestamp - Current timestamp
     */
    updateProfiler(timestamp) {
        // Clear old markers that weren't ended
        for (const [name, startTime] of this.profiler.currentFrame) {
            if (timestamp - startTime > 100) { // 100ms timeout
                console.warn(`⚠️ Profiler marker '${name}' was not ended properly`);
                this.profiler.currentFrame.delete(name);
            }
        }
    }

    /**
     * Get profiler statistics
     * @param {string} name - Marker name
     * @returns {Object} Profiler statistics
     */
    getProfilerStats(name) {
        const timings = this.profiler.timings.get(name);
        if (!timings || timings.length === 0) {
            return null;
        }
        
        const sorted = [...timings].sort((a, b) => a - b);
        const average = timings.reduce((a, b) => a + b, 0) / timings.length;
        
        return {
            name: name,
            count: timings.length,
            average: average,
            min: sorted[0],
            max: sorted[sorted.length - 1],
            median: sorted[Math.floor(sorted.length / 2)],
            p95: sorted[Math.floor(sorted.length * 0.95)],
            p99: sorted[Math.floor(sorted.length * 0.99)]
        };
    }

    /**
     * Enable/disable auto-scaling
     * @param {boolean} enabled - Whether to enable auto-scaling
     */
    setAutoScalingEnabled(enabled) {
        this.autoScaling.enabled = enabled;
        console.log(`🎯 Auto-scaling ${enabled ? 'enabled' : 'disabled'}`);
    }

    /**
     * Enable/disable profiling
     * @param {boolean} enabled - Whether to enable profiling
     */
    setProfilingEnabled(enabled) {
        this.profiler.enabled = enabled;
        console.log(`📊 Profiling ${enabled ? 'enabled' : 'disabled'}`);
    }

    /**
     * Get current performance metrics
     * @returns {Object} Performance metrics
     */
    getMetrics() {
        return {
            fps: {
                current: this.fps,
                average: this.averageFPS,
                min: this.minFPS,
                max: this.maxFPS,
                target: this.options.targetFPS
            },
            frameTime: {
                current: this.frameTime,
                average: this.frameTimeHistory.length > 0 ? 
                    this.frameTimeHistory.reduce((a, b) => a + b, 0) / this.frameTimeHistory.length : 0
            },
            memory: {
                ...this.memoryUsage,
                warningThreshold: this.options.memoryWarningThreshold,
                errorThreshold: this.options.memoryErrorThreshold
            },
            quality: {
                current: this.currentQuality,
                settings: this.qualityLevels.get(this.currentQuality)
            },
            device: this.deviceInfo,
            warnings: this.warnings
        };
    }

    /**
     * Get performance report
     * @returns {Object} Detailed performance report
     */
    getReport() {
        const metrics = this.getMetrics();
        
        return {
            ...metrics,
            profiler: {
                enabled: this.profiler.enabled,
                markers: Array.from(this.profiler.timings.keys()).map(name => 
                    this.getProfilerStats(name)
                ).filter(stats => stats !== null)
            },
            autoScaling: {
                enabled: this.autoScaling.enabled,
                consecutiveLowFPS: this.autoScaling.consecutiveLowFPS,
                consecutiveHighFPS: this.autoScaling.consecutiveHighFPS,
                cooldown: this.autoScaling.scalingCooldown
            },
            frameCount: this.frameCount,
            uptime: performance.now()
        };
    }

    /**
     * Register performance callback
     * @param {string} event - Event type
     * @param {Function} callback - Callback function
     */
    on(event, callback) {
        if (!this.callbacks.has(event)) {
            this.callbacks.set(event, []);
        }
        this.callbacks.get(event).push(callback);
    }

    /**
     * Trigger callback
     * @param {string} event - Event type
     * @param {*} data - Event data
     */
    triggerCallback(event, data) {
        const callbacks = this.callbacks.get(event);
        if (callbacks) {
            callbacks.forEach(callback => {
                try {
                    callback(data);
                } catch (error) {
                    console.error(`❌ Performance callback error for ${event}:`, error);
                }
            });
        }
    }

    /**
     * Reset performance metrics
     */
    reset() {
        this.fps = 0;
        this.frameTime = 0;
        this.averageFPS = 0;
        this.minFPS = Infinity;
        this.maxFPS = 0;
        this.frameCount = 0;
        this.fpsHistory = [];
        this.frameTimeHistory = [];
        
        // Reset auto-scaling
        this.autoScaling.consecutiveLowFPS = 0;
        this.autoScaling.consecutiveHighFPS = 0;
        this.autoScaling.scalingCooldown = 0;
        
        // Reset warnings
        this.warnings.lowFPS = false;
        this.warnings.highMemory = false;
        this.warnings.longFrameTime = false;
        
        console.log('🔄 Performance metrics reset');
    }

    /**
     * Dispose of performance system
     */
    dispose() {
        // Stop monitoring
        if (this.monitoringInterval) {
            clearInterval(this.monitoringInterval);
        }
        
        // Clear callbacks
        this.callbacks.clear();
        
        // Clear profiler data
        this.profiler.timings.clear();
        this.profiler.currentFrame.clear();
        
        console.log('🗑️ PerformanceSystem disposed');
    }
}