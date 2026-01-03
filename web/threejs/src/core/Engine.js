/**
 * Core Three.js Engine
 * Professional WebGL rendering engine with performance optimization
 */

import * as THREE from 'three';
import { Renderer } from './Renderer.js';
import { Camera } from './Camera.js';
import { Scene } from './Scene.js';
import { PerformanceMonitor } from './PerformanceMonitor.js';
import { EventEmitter } from '../utils/EventEmitter.js';

export class Engine extends EventEmitter {
    constructor(container, options = {}) {
        super();
        
        this.container = container;
        this.options = {
            enablePerformanceMonitoring: true,
            targetFPS: 30,
            maxMemoryMB: 100,
            enableStats: typeof __DEV__ !== 'undefined' ? __DEV__ : false,
            ...options
        };
        
        // Core components
        this.renderer = null;
        this.camera = null;
        this.scene = null;
        this.performanceMonitor = null;
        
        // Animation
        this.clock = new THREE.Clock();
        this.animationId = null;
        this.isRunning = false;
        this.isInitialized = false;
        
        // Performance tracking
        this.frameCount = 0;
        this.lastFPSCheck = performance.now();
        this.currentFPS = 60;
        
        // Initialize asynchronously
        this.init().catch(error => {
            console.error('❌ Engine initialization failed in constructor:', error);
            this.emit('error', error);
        });
    }
    
    async init() {
        try {
            console.log('🚀 Initializing Three.js Engine...');
            
            // Initialize core components
            console.log('📦 Creating Renderer...');
            this.renderer = new Renderer(this.container, this.options);
            
            console.log('📷 Creating Camera...');
            this.camera = new Camera(this.options);
            
            console.log('🎬 Creating Scene...');
            this.scene = new Scene(this.options);
            
            // Setup performance monitoring
            if (this.options.enablePerformanceMonitoring) {
                console.log('📊 Setting up Performance Monitor...');
                this.performanceMonitor = new PerformanceMonitor(this.renderer, this.options);
                this.performanceMonitor.on('performanceWarning', this.handlePerformanceWarning.bind(this));
            }
            
            // Setup event listeners
            console.log('🎧 Setting up Event Listeners...');
            this.setupEventListeners();
            
            // Start render loop
            console.log('▶️ Starting Render Loop...');
            this.start();
            
            console.log('✅ Three.js Engine initialized successfully');
            this.emit('initialized');
            
            // Set initialized flag after a short delay to ensure all setup is complete
            setTimeout(() => {
                this.isInitialized = true;
                console.log('🔓 Engine initialization complete - visibility changes now active');
            }, 1000);
            
        } catch (error) {
            console.error('❌ Engine initialization failed:', error);
            this.emit('error', error);
            throw error;
        }
    }
    
    setupEventListeners() {
        // Window resize
        window.addEventListener('resize', this.handleResize.bind(this));
        
        // Visibility change (pause when tab is hidden)
        document.addEventListener('visibilitychange', this.handleVisibilityChange.bind(this));
        
        // Memory pressure (if available)
        if ('memory' in performance) {
            setInterval(() => {
                const memoryInfo = performance.memory;
                const usedMB = memoryInfo.usedJSHeapSize / 1048576;
                
                if (usedMB > this.options.maxMemoryMB) {
                    this.emit('memoryPressure', { usedMB, maxMB: this.options.maxMemoryMB });
                }
            }, 5000);
        }
    }
    
    handleResize() {
        if (!this.renderer || !this.camera) return;
        
        const width = window.innerWidth;
        const height = window.innerHeight;
        
        this.camera.updateAspect(width / height);
        this.renderer.setSize(width, height);
        
        this.emit('resize', { width, height });
    }
    
    handleVisibilityChange() {
        // CRITICAL FIX: Don't pause in iframe contexts (Flutter WebView)
        const isInIframe = window.self !== window.top;
        const isFlutterContext = window.location.search.includes('room=') || 
                                navigator.userAgent.toLowerCase().includes('flutter') ||
                                window.flutter !== undefined;
        
        if (isInIframe || isFlutterContext) {
            console.log('🌐 Running in iframe/Flutter context - ignoring visibility changes');
            return;
        }
        
        // Don't pause during initial loading
        if (!this.isInitialized) {
            console.log('⚠️ Ignoring visibility change during initialization');
            return;
        }
        
        if (document.hidden) {
            console.log('⏸️ Tab hidden - pausing engine');
            this.pause();
        } else {
            console.log('▶️ Tab visible - resuming engine');
            this.resume();
        }
    }
    
    handlePerformanceWarning(data) {
        console.warn('⚠️ Performance warning:', data);
        
        // Auto-adjust quality if FPS is too low
        if (data.fps < this.options.targetFPS * 0.7) {
            this.adjustQuality('lower');
        }
        
        this.emit('performanceWarning', data);
    }
    
    adjustQuality(direction) {
        if (!this.renderer) return;
        
        const currentPixelRatio = this.renderer.getPixelRatio();
        
        if (direction === 'lower' && currentPixelRatio > 0.5) {
            const newRatio = Math.max(0.5, currentPixelRatio * 0.8);
            this.renderer.setPixelRatio(newRatio);
            console.log(`📉 Quality reduced: pixel ratio ${newRatio.toFixed(2)}`);
        } else if (direction === 'higher' && currentPixelRatio < window.devicePixelRatio) {
            const newRatio = Math.min(window.devicePixelRatio, currentPixelRatio * 1.2);
            this.renderer.setPixelRatio(newRatio);
            console.log(`📈 Quality increased: pixel ratio ${newRatio.toFixed(2)}`);
        }
        
        this.emit('qualityChanged', { pixelRatio: this.renderer.getPixelRatio() });
    }
    
    start() {
        if (this.isRunning) return;
        
        this.isRunning = true;
        this.animate();
        
        console.log('▶️ Engine started');
        this.emit('started');
    }
    
    pause() {
        if (!this.isRunning) return;
        
        this.isRunning = false;
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
            this.animationId = null;
        }
        
        console.log('⏸️ Engine paused');
        this.emit('paused');
    }
    
    resume() {
        if (this.isRunning) return;
        
        this.start();
        console.log('▶️ Engine resumed');
        this.emit('resumed');
    }
    
    get isPaused() {
        return !this.isRunning;
    }
    
    animate() {
        if (!this.isRunning) return;
        
        this.animationId = requestAnimationFrame(this.animate.bind(this));
        
        const time = performance.now();
        const delta = this.clock.getDelta();
        
        // FPS monitoring
        this.frameCount++;
        if (time - this.lastFPSCheck >= 1000) {
            this.currentFPS = this.frameCount;
            this.frameCount = 0;
            this.lastFPSCheck = time;
            
            // Update performance monitor
            if (this.performanceMonitor) {
                this.performanceMonitor.update(this.currentFPS, delta);
            }
        }
        
        // Update scene
        if (this.scene) {
            this.scene.update(delta, time);
        }
        
        // Update camera
        if (this.camera) {
            this.camera.update(delta, time);
        }
        
        // Render
        if (this.renderer && this.scene && this.camera) {
            this.renderer.render(this.scene.getScene(), this.camera.getCamera());
        }
        
        this.emit('frame', { delta, time, fps: this.currentFPS });
    }
    
    setQuality(level) {
        const qualitySettings = {
            low: { pixelRatio: 0.5, shadows: false, antialias: false },
            medium: { pixelRatio: 0.75, shadows: true, antialias: false },
            high: { pixelRatio: 1.0, shadows: true, antialias: true },
            auto: null // Will be determined by performance
        };
        
        const settings = qualitySettings[level];
        if (!settings) return;
        
        if (this.renderer) {
            this.renderer.setPixelRatio(settings.pixelRatio);
            this.renderer.shadowMap.enabled = settings.shadows;
        }
        
        console.log(`🎛️ Quality set to: ${level}`);
        this.emit('qualitySet', { level, settings });
    }
    
    getStats() {
        const stats = {
            fps: this.currentFPS,
            isRunning: this.isRunning,
            renderer: this.renderer ? this.renderer.getInfo() : null,
            memory: performance.memory ? {
                used: Math.round(performance.memory.usedJSHeapSize / 1048576),
                total: Math.round(performance.memory.totalJSHeapSize / 1048576),
                limit: Math.round(performance.memory.jsHeapSizeLimit / 1048576)
            } : null
        };
        
        return stats;
    }
    
    dispose() {
        console.log('🧹 Disposing Engine...');
        
        this.pause();
        
        if (this.performanceMonitor) {
            this.performanceMonitor.dispose();
        }
        
        if (this.scene) {
            this.scene.dispose();
        }
        
        if (this.renderer) {
            this.renderer.dispose();
        }
        
        // Remove event listeners
        window.removeEventListener('resize', this.handleResize.bind(this));
        document.removeEventListener('visibilitychange', this.handleVisibilityChange.bind(this));
        
        this.emit('disposed');
        console.log('✅ Engine disposed');
    }
}