/**
 * Performance Adapter
 * Monitors device performance and automatically adjusts quality settings
 */

export class PerformanceAdapter {
    constructor(options = {}) {
        this.options = {
            targetFPS: 30,
            maxMemoryMB: 100,
            adaptiveQuality: true,
            monitoringInterval: 1000,
            ...options
        };
        
        // Performance metrics
        this.metrics = {
            fps: 0,
            frameTime: 0,
            memory: 0,
            cpuUsage: 0,
            gpuUsage: 0,
            batteryLevel: 1.0,
            thermalState: 'normal',
            networkSpeed: 'fast'
        };
        
        // Performance history for trend analysis
        this.history = {
            fps: [],
            memory: [],
            frameTime: []
        };
        this.historySize = 10;
        
        // Quality levels
        this.qualityLevels = ['low', 'medium', 'high'];
        this.currentQualityIndex = 1; // Start with medium
        
        // Adaptation state
        this.isAdapting = false;
        this.lastAdaptation = 0;
        this.adaptationCooldown = 5000; // 5 seconds between adaptations
        
        // Device capabilities
        this.deviceCapabilities = this.detectDeviceCapabilities();
        
        this.init();
    }
    
    init() {
        console.log('📊 Initializing Performance Adapter...');
        
        // Setup performance monitoring
        this.setupPerformanceMonitoring();
        
        // Setup battery monitoring
        this.setupBatteryMonitoring();
        
        // Setup thermal monitoring
        this.setupThermalMonitoring();
        
        // Setup network monitoring
        this.setupNetworkMonitoring();
        
        console.log('✅ Performance Adapter initialized');
        console.log('📱 Device capabilities:', this.deviceCapabilities);
    }
    
    detectDeviceCapabilities() {
        const capabilities = {
            isMobile: this.isMobile(),
            hasWebGL2: this.hasWebGL2(),
            maxTextureSize: this.getMaxTextureSize(),
            maxRenderBufferSize: this.getMaxRenderBufferSize(),
            supportedExtensions: this.getSupportedExtensions(),
            memoryInfo: this.getMemoryInfo(),
            cpuCores: navigator.hardwareConcurrency || 1,
            devicePixelRatio: window.devicePixelRatio || 1
        };
        
        // Calculate device score
        capabilities.score = this.calculateDeviceScore(capabilities);
        capabilities.tier = this.getDeviceTier(capabilities.score);
        
        return capabilities;
    }
    
    isMobile() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    }
    
    hasWebGL2() {
        const canvas = document.createElement('canvas');
        return !!canvas.getContext('webgl2');
    }
    
    getMaxTextureSize() {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl') || canvas.getContext('webgl2');
        return gl ? gl.getParameter(gl.MAX_TEXTURE_SIZE) : 0;
    }
    
    getMaxRenderBufferSize() {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl') || canvas.getContext('webgl2');
        return gl ? gl.getParameter(gl.MAX_RENDERBUFFER_SIZE) : 0;
    }
    
    getSupportedExtensions() {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl') || canvas.getContext('webgl2');
        return gl ? gl.getSupportedExtensions() : [];
    }
    
    getMemoryInfo() {
        if (performance.memory) {
            return {
                totalJSHeapSize: performance.memory.totalJSHeapSize,
                usedJSHeapSize: performance.memory.usedJSHeapSize,
                jsHeapSizeLimit: performance.memory.jsHeapSizeLimit
            };
        }
        return null;
    }
    
    calculateDeviceScore(capabilities) {
        let score = 0;
        
        // WebGL2 support
        if (capabilities.hasWebGL2) score += 2;
        
        // Texture size
        if (capabilities.maxTextureSize >= 4096) score += 2;
        else if (capabilities.maxTextureSize >= 2048) score += 1;
        
        // CPU cores
        if (capabilities.cpuCores >= 8) score += 3;
        else if (capabilities.cpuCores >= 4) score += 2;
        else if (capabilities.cpuCores >= 2) score += 1;
        
        // Memory
        if (capabilities.memoryInfo) {
            const totalMemoryMB = capabilities.memoryInfo.totalJSHeapSize / 1024 / 1024;
            if (totalMemoryMB >= 4000) score += 3;
            else if (totalMemoryMB >= 2000) score += 2;
            else if (totalMemoryMB >= 1000) score += 1;
        }
        
        // Mobile penalty
        if (capabilities.isMobile) score -= 2;
        
        // High DPI penalty for mobile
        if (capabilities.isMobile && capabilities.devicePixelRatio > 2) score -= 1;
        
        return Math.max(0, score);
    }
    
    getDeviceTier(score) {
        if (score >= 8) return 'high';
        if (score >= 4) return 'medium';
        return 'low';
    }
    
    setupPerformanceMonitoring() {
        let frameCount = 0;
        let lastTime = performance.now();
        
        const monitor = () => {
            const now = performance.now();
            const delta = now - lastTime;
            
            if (delta >= this.options.monitoringInterval) {
                // Calculate FPS
                this.metrics.fps = Math.round((frameCount * 1000) / delta);
                this.metrics.frameTime = delta / frameCount;
                
                // Update memory usage
                if (performance.memory) {
                    this.metrics.memory = Math.round(performance.memory.usedJSHeapSize / 1024 / 1024);
                }
                
                // Add to history
                this.addToHistory('fps', this.metrics.fps);
                this.addToHistory('memory', this.metrics.memory);
                this.addToHistory('frameTime', this.metrics.frameTime);
                
                // Check if adaptation is needed
                this.checkAdaptationNeeded();
                
                frameCount = 0;
                lastTime = now;
            }
            
            frameCount++;
            requestAnimationFrame(monitor);
        };
        
        monitor();
    }
    
    setupBatteryMonitoring() {
        if ('getBattery' in navigator) {
            navigator.getBattery().then((battery) => {
                this.metrics.batteryLevel = battery.level;
                
                const updateBatteryMetrics = () => {
                    this.metrics.batteryLevel = battery.level;
                };
                
                battery.addEventListener('levelchange', updateBatteryMetrics);
                battery.addEventListener('chargingchange', updateBatteryMetrics);
            }).catch(() => {
                console.log('📱 Battery API not available');
            });
        }
    }
    
    setupThermalMonitoring() {
        // Thermal monitoring is limited on web, but we can infer from performance
        setInterval(() => {
            const avgFPS = this.getAverageFPS();
            const avgFrameTime = this.getAverageFrameTime();
            
            // Infer thermal state from performance degradation
            if (avgFPS < this.options.targetFPS * 0.5 && avgFrameTime > 50) {
                this.metrics.thermalState = 'critical';
            } else if (avgFPS < this.options.targetFPS * 0.7 && avgFrameTime > 35) {
                this.metrics.thermalState = 'warning';
            } else {
                this.metrics.thermalState = 'normal';
            }
        }, 5000);
    }
    
    setupNetworkMonitoring() {
        if ('connection' in navigator) {
            const connection = navigator.connection;
            
            const updateNetworkMetrics = () => {
                const effectiveType = connection.effectiveType;
                
                switch (effectiveType) {
                    case '4g':
                        this.metrics.networkSpeed = 'fast';
                        break;
                    case '3g':
                        this.metrics.networkSpeed = 'medium';
                        break;
                    case '2g':
                    case 'slow-2g':
                        this.metrics.networkSpeed = 'slow';
                        break;
                    default:
                        this.metrics.networkSpeed = 'unknown';
                }
            };
            
            updateNetworkMetrics();
            connection.addEventListener('change', updateNetworkMetrics);
        }
    }
    
    addToHistory(metric, value) {
        if (!this.history[metric]) {
            this.history[metric] = [];
        }
        
        this.history[metric].push(value);
        
        if (this.history[metric].length > this.historySize) {
            this.history[metric].shift();
        }
    }
    
    getAverageFPS() {
        const fpsHistory = this.history.fps;
        if (fpsHistory.length === 0) return this.options.targetFPS;
        
        return fpsHistory.reduce((sum, fps) => sum + fps, 0) / fpsHistory.length;
    }
    
    getAverageFrameTime() {
        const frameTimeHistory = this.history.frameTime;
        if (frameTimeHistory.length === 0) return 16.67; // 60fps baseline
        
        return frameTimeHistory.reduce((sum, time) => sum + time, 0) / frameTimeHistory.length;
    }
    
    getAverageMemory() {
        const memoryHistory = this.history.memory;
        if (memoryHistory.length === 0) return 0;
        
        return memoryHistory.reduce((sum, memory) => sum + memory, 0) / memoryHistory.length;
    }
    
    checkAdaptationNeeded() {
        if (!this.options.adaptiveQuality || this.isAdapting) return;
        
        const now = Date.now();
        if (now - this.lastAdaptation < this.adaptationCooldown) return;
        
        const avgFPS = this.getAverageFPS();
        const avgMemory = this.getAverageMemory();
        const { batteryLevel, thermalState } = this.metrics;
        
        let shouldAdaptDown = false;
        let shouldAdaptUp = false;
        
        // Check for performance issues
        if (avgFPS < this.options.targetFPS * 0.7) {
            shouldAdaptDown = true;
            console.log(`📉 Low FPS detected: ${avgFPS.toFixed(1)}`);
        }
        
        if (avgMemory > this.options.maxMemoryMB) {
            shouldAdaptDown = true;
            console.log(`📉 High memory usage: ${avgMemory.toFixed(1)}MB`);
        }
        
        if (batteryLevel < 0.2) {
            shouldAdaptDown = true;
            console.log(`📉 Low battery: ${(batteryLevel * 100).toFixed(0)}%`);
        }
        
        if (thermalState === 'critical') {
            shouldAdaptDown = true;
            console.log(`📉 Thermal throttling detected`);
        }
        
        // Check for performance headroom
        if (avgFPS > this.options.targetFPS * 1.3 && avgMemory < this.options.maxMemoryMB * 0.7) {
            shouldAdaptUp = true;
        }
        
        // Perform adaptation
        if (shouldAdaptDown) {
            this.adaptQualityDown();
        } else if (shouldAdaptUp) {
            this.adaptQualityUp();
        }
    }
    
    adaptQualityDown() {
        if (this.currentQualityIndex > 0) {
            this.currentQualityIndex--;
            this.performAdaptation('down');
        }
    }
    
    adaptQualityUp() {
        if (this.currentQualityIndex < this.qualityLevels.length - 1) {
            this.currentQualityIndex++;
            this.performAdaptation('up');
        }
    }
    
    performAdaptation(direction) {
        this.isAdapting = true;
        this.lastAdaptation = Date.now();
        
        const newQuality = this.qualityLevels[this.currentQualityIndex];
        
        console.log(`🎨 Adapting quality ${direction} to: ${newQuality}`);
        
        // Emit adaptation event
        this.emit('qualityAdaptation', {
            direction: direction,
            quality: newQuality,
            reason: this.getAdaptationReason()
        });
        
        // Reset adaptation flag after cooldown
        setTimeout(() => {
            this.isAdapting = false;
        }, this.adaptationCooldown);
    }
    
    getAdaptationReason() {
        const reasons = [];
        
        if (this.getAverageFPS() < this.options.targetFPS * 0.7) {
            reasons.push('low_fps');
        }
        
        if (this.getAverageMemory() > this.options.maxMemoryMB) {
            reasons.push('high_memory');
        }
        
        if (this.metrics.batteryLevel < 0.2) {
            reasons.push('low_battery');
        }
        
        if (this.metrics.thermalState === 'critical') {
            reasons.push('thermal_throttling');
        }
        
        return reasons;
    }
    
    // Public API
    getCurrentQuality() {
        return this.qualityLevels[this.currentQualityIndex];
    }
    
    setQuality(quality) {
        const index = this.qualityLevels.indexOf(quality);
        if (index !== -1) {
            this.currentQualityIndex = index;
            console.log(`🎨 Quality manually set to: ${quality}`);
        }
    }
    
    getMetrics() {
        return { ...this.metrics };
    }
    
    getDeviceCapabilities() {
        return { ...this.deviceCapabilities };
    }
    
    getRecommendedQuality() {
        const { tier } = this.deviceCapabilities;
        const { batteryLevel, thermalState } = this.metrics;
        
        // Start with device tier
        let recommendedQuality = tier;
        
        // Adjust for battery level
        if (batteryLevel < 0.3 && recommendedQuality === 'high') {
            recommendedQuality = 'medium';
        }
        
        if (batteryLevel < 0.2) {
            recommendedQuality = 'low';
        }
        
        // Adjust for thermal state
        if (thermalState === 'critical') {
            recommendedQuality = 'low';
        } else if (thermalState === 'warning' && recommendedQuality === 'high') {
            recommendedQuality = 'medium';
        }
        
        return recommendedQuality;
    }
    
    // Event emitter functionality
    emit(event, data) {
        if (this.listeners && this.listeners[event]) {
            this.listeners[event].forEach(callback => callback(data));
        }
    }
    
    on(event, callback) {
        if (!this.listeners) this.listeners = {};
        if (!this.listeners[event]) this.listeners[event] = [];
        this.listeners[event].push(callback);
    }
    
    off(event, callback) {
        if (this.listeners && this.listeners[event]) {
            const index = this.listeners[event].indexOf(callback);
            if (index !== -1) {
                this.listeners[event].splice(index, 1);
            }
        }
    }
    
    dispose() {
        console.log('🧹 Disposing Performance Adapter...');
        
        if (this.listeners) {
            this.listeners = {};
        }
        
        console.log('✅ Performance Adapter disposed');
    }
}