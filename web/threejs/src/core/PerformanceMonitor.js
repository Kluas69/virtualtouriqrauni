/**
 * Professional Performance Monitor
 * Real-time performance tracking and optimization
 */

import { EventEmitter } from '../utils/EventEmitter.js';

export class PerformanceMonitor extends EventEmitter {
    constructor(renderer, options = {}) {
        super();
        
        this.renderer = renderer;
        this.options = {
            targetFPS: 30,
            memoryWarningThreshold: 80, // MB
            memoryErrorThreshold: 100, // MB
            fpsWarningThreshold: 20,
            updateInterval: 1000, // ms
            enableUI: typeof __DEV__ !== 'undefined' ? __DEV__ : false,
            ...options
        };
        
        // Performance metrics
        this.metrics = {
            fps: 60,
            frameTime: 16.67,
            memory: {
                used: 0,
                total: 0,
                limit: 0
            },
            renderer: {
                triangles: 0,
                drawCalls: 0,
                geometries: 0,
                textures: 0
            },
            warnings: []
        };
        
        // Tracking
        this.frameCount = 0;
        this.lastUpdate = performance.now();
        this.frameTimes = [];
        this.maxFrameTimeHistory = 60;
        
        // UI elements
        this.uiElement = null;
        
        this.init();
    }
    
    init() {
        console.log('📊 Initializing Performance Monitor...');
        
        // Setup UI if enabled
        if (this.options.enableUI) {
            this.createUI();
        }
        
        // Start monitoring
        this.startMonitoring();
        
        console.log('✅ Performance Monitor initialized');
    }
    
    createUI() {
        this.uiElement = document.getElementById('performance-stats');
        if (!this.uiElement) {
            console.warn('Performance stats element not found');
            return;
        }
        
        this.updateUI();
    }
    
    updateUI() {
        if (!this.uiElement) return;
        
        const { metrics } = this;
        const memoryInfo = metrics.memory;
        const rendererInfo = metrics.renderer;
        
        this.uiElement.innerHTML = `
            <div style="margin-bottom: 8px; font-weight: bold;">Performance</div>
            <div>FPS: ${metrics.fps.toFixed(1)}</div>
            <div>Frame: ${metrics.frameTime.toFixed(1)}ms</div>
            <div style="margin-top: 8px; font-weight: bold;">Memory</div>
            <div>Used: ${memoryInfo.used.toFixed(1)}MB</div>
            <div>Total: ${memoryInfo.total.toFixed(1)}MB</div>
            <div style="margin-top: 8px; font-weight: bold;">Renderer</div>
            <div>Triangles: ${rendererInfo.triangles.toLocaleString()}</div>
            <div>Calls: ${rendererInfo.drawCalls}</div>
            <div>Textures: ${rendererInfo.textures}</div>
            <div>Geometries: ${rendererInfo.geometries}</div>
            ${metrics.warnings.length > 0 ? `
                <div style="margin-top: 8px; color: #ff6b6b; font-weight: bold;">Warnings</div>
                ${metrics.warnings.slice(-3).map(w => `<div style="font-size: 10px;">${w}</div>`).join('')}
            ` : ''}
        `;
    }
    
    startMonitoring() {
        setInterval(() => {
            this.updateMetrics();
            this.checkPerformance();
            
            if (this.options.enableUI) {
                this.updateUI();
            }
            
            this.emit('update', this.metrics);
        }, this.options.updateInterval);
    }
    
    update(fps, delta) {
        this.frameCount++;
        
        // Track frame time
        const frameTime = delta * 1000; // Convert to ms
        this.frameTimes.push(frameTime);
        
        if (this.frameTimes.length > this.maxFrameTimeHistory) {
            this.frameTimes.shift();
        }
        
        // Update FPS
        const now = performance.now();
        if (now - this.lastUpdate >= 1000) {
            this.metrics.fps = fps;
            this.metrics.frameTime = this.getAverageFrameTime();
            this.lastUpdate = now;
        }
    }
    
    updateMetrics() {
        // Memory metrics
        if (performance.memory) {
            this.metrics.memory = {
                used: performance.memory.usedJSHeapSize / 1048576, // MB
                total: performance.memory.totalJSHeapSize / 1048576, // MB
                limit: performance.memory.jsHeapSizeLimit / 1048576 // MB
            };
        }
        
        // Renderer metrics
        if (this.renderer) {
            const info = this.renderer.getInfo();
            if (info) {
                this.metrics.renderer = {
                    triangles: info.triangles || 0,
                    drawCalls: info.calls || 0,
                    geometries: info.geometries || 0,
                    textures: info.textures || 0
                };
            }
        }
    }
    
    checkPerformance() {
        const warnings = [];
        
        // FPS warnings
        if (this.metrics.fps < this.options.fpsWarningThreshold) {
            warnings.push(`Low FPS: ${this.metrics.fps.toFixed(1)}`);
            this.emit('performanceWarning', {
                type: 'fps',
                fps: this.metrics.fps,
                threshold: this.options.fpsWarningThreshold
            });
        }
        
        // Memory warnings
        const memoryUsed = this.metrics.memory.used;
        if (memoryUsed > this.options.memoryErrorThreshold) {
            warnings.push(`Critical memory: ${memoryUsed.toFixed(1)}MB`);
            this.emit('memoryError', {
                type: 'memory',
                used: memoryUsed,
                threshold: this.options.memoryErrorThreshold
            });
        } else if (memoryUsed > this.options.memoryWarningThreshold) {
            warnings.push(`High memory: ${memoryUsed.toFixed(1)}MB`);
            this.emit('memoryWarning', {
                type: 'memory',
                used: memoryUsed,
                threshold: this.options.memoryWarningThreshold
            });
        }
        
        // Triangle count warnings
        const triangles = this.metrics.renderer.triangles;
        if (triangles > 100000) {
            warnings.push(`High triangles: ${triangles.toLocaleString()}`);
            this.emit('performanceWarning', {
                type: 'triangles',
                count: triangles,
                threshold: 100000
            });
        }
        
        // Draw call warnings
        const drawCalls = this.metrics.renderer.drawCalls;
        if (drawCalls > 100) {
            warnings.push(`High draw calls: ${drawCalls}`);
            this.emit('performanceWarning', {
                type: 'drawCalls',
                count: drawCalls,
                threshold: 100
            });
        }
        
        // Update warnings
        if (warnings.length > 0) {
            this.metrics.warnings.push(...warnings.map(w => `${new Date().toLocaleTimeString()}: ${w}`));
            
            // Keep only recent warnings
            if (this.metrics.warnings.length > 10) {
                this.metrics.warnings = this.metrics.warnings.slice(-10);
            }
        }
    }
    
    getAverageFrameTime() {
        if (this.frameTimes.length === 0) return 16.67;
        
        const sum = this.frameTimes.reduce((a, b) => a + b, 0);
        return sum / this.frameTimes.length;
    }
    
    // Performance optimization suggestions
    getOptimizationSuggestions() {
        const suggestions = [];
        const { metrics } = this;
        
        if (metrics.fps < this.options.targetFPS) {
            suggestions.push({
                type: 'fps',
                message: 'Consider reducing quality settings or model complexity',
                severity: 'high'
            });
        }
        
        if (metrics.memory.used > this.options.memoryWarningThreshold) {
            suggestions.push({
                type: 'memory',
                message: 'Consider disposing unused resources or reducing texture sizes',
                severity: 'medium'
            });
        }
        
        if (metrics.renderer.triangles > 50000) {
            suggestions.push({
                type: 'geometry',
                message: 'Consider using LOD (Level of Detail) for complex models',
                severity: 'medium'
            });
        }
        
        if (metrics.renderer.drawCalls > 50) {
            suggestions.push({
                type: 'drawCalls',
                message: 'Consider merging geometries or using instancing',
                severity: 'low'
            });
        }
        
        return suggestions;
    }
    
    // Performance profiling
    startProfiling(name) {
        const start = performance.now();
        
        return {
            end: () => {
                const duration = performance.now() - start;
                console.log(`⏱️ ${name}: ${duration.toFixed(2)}ms`);
                return duration;
            }
        };
    }
    
    // Memory management helpers
    forceGarbageCollection() {
        if (window.gc) {
            window.gc();
            console.log('🗑️ Forced garbage collection');
        } else {
            console.warn('Garbage collection not available');
        }
    }
    
    // Export metrics
    exportMetrics() {
        return {
            timestamp: Date.now(),
            ...this.metrics,
            suggestions: this.getOptimizationSuggestions()
        };
    }
    
    // Reset metrics
    reset() {
        this.frameCount = 0;
        this.frameTimes.length = 0;
        this.metrics.warnings.length = 0;
        this.lastUpdate = performance.now();
        
        console.log('🔄 Performance metrics reset');
    }
    
    dispose() {
        if (this.uiElement) {
            this.uiElement.innerHTML = '';
            this.uiElement = null;
        }
        
        this.removeAllListeners();
        console.log('✅ Performance Monitor disposed');
    }
}