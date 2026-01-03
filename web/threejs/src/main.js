/**
 * Main Application Entry Point
 * Professional Three.js Virtual Tour Application
 */

import { Engine } from './core/Engine.js';
import { ModelLoader } from './loaders/ModelLoader.js';
import { RoomManager } from './rooms/RoomManager.js';
import { FlutterBridge } from './communication/FlutterBridge.js';
import { UIManager } from './ui/UIManager.js';
import { MobileBridge } from './mobile/MobileBridge.js';
import { TouchControls } from './mobile/TouchControls.js';
import { MobileEngine } from './mobile/MobileEngine.js';

class VirtualTourApp {
    constructor() {
        this.engine = null;
        this.modelLoader = null;
        this.roomManager = null;
        this.flutterBridge = null;
        this.uiManager = null;
        this.mobileBridge = null;
        this.touchControls = null;
        
        // App state
        this.isInitialized = false;
        this.currentRoom = null;
        this.isMobile = this.detectMobile();
        
        // Configuration
        this.config = {
            defaultRoom: 'classroom',
            enablePerformanceMonitoring: true,
            enableFlutterCommunication: true,
            enableMobileControls: this.isMobile,
            targetFPS: this.isMobile ? 30 : 60,
            maxMemoryMB: this.isMobile ? 100 : 200
        };
        
        // Initialize asynchronously
        this.init().catch(error => {
            console.error('❌ VirtualTourApp initialization failed:', error);
            this.showError('Failed to initialize 3D environment', error.message);
        });
    }
    
    detectMobile() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ||
               ('ontouchstart' in window) ||
               (navigator.maxTouchPoints > 0);
    }
    
    async init() {
        try {
            console.log('🚀 Initializing Virtual Tour Application...');
            
            // Parse URL parameters for room selection
            const urlParams = new URLSearchParams(window.location.search);
            const requestedRoom = urlParams.get('room');
            if (requestedRoom) {
                this.config.defaultRoom = requestedRoom;
                console.log(`📍 Room requested via URL: ${requestedRoom}`);
            }
            
            // Show loading screen
            this.showLoadingScreen('Initializing 3D Engine...');
            
            // Initialize core engine
            console.log('🎯 Step 1: Initializing engine...');
            await this.initializeEngine();
            console.log('✅ Step 1 complete: Engine initialized');
            
            // CRITICAL FIX: Ensure engine is not paused after initialization
            if (this.engine && this.engine.isPaused) {
                console.log('▶️ Resuming engine after initialization...');
                this.engine.resume();
            }
            
            // Additional check: Force resume if in iframe/Flutter context
            const isInIframe = window.self !== window.top;
            const isFlutterContext = window.location.search.includes('room=') || 
                                    navigator.userAgent.toLowerCase().includes('flutter');
            
            if ((isInIframe || isFlutterContext) && this.engine && this.engine.isPaused) {
                console.log('🌐 Force resuming engine for iframe/Flutter context...');
                this.engine.resume();
            }
            
            // Initialize subsystems
            console.log('🎯 Step 2: Initializing subsystems...');
            await this.initializeSubsystems();
            console.log('✅ Step 2 complete: Subsystems initialized');
            
            // Setup event handlers
            console.log('🎯 Step 3: Setting up event handlers...');
            this.setupEventHandlers();
            console.log('✅ Step 3 complete: Event handlers setup');
            
            // CRITICAL FIX: Ensure engine is running before loading room
            if (this.engine && this.engine.isPaused) {
                console.log('▶️ Resuming engine before room loading...');
                this.engine.resume();
            }
            
            // Load default room
            console.log('🎯 Step 4: Loading default room...');
            await this.loadDefaultRoom();
            console.log('✅ Step 4 complete: Default room loaded');
            
            // Hide loading screen
            this.hideLoadingScreen();
            
            this.isInitialized = true;
            console.log('🎉 Virtual Tour Application initialized successfully');
            
        } catch (error) {
            console.error('❌ Application initialization failed:', error);
            console.error('❌ Error details:', error.stack);
            this.showError('Failed to initialize 3D environment', error.message);
        }
    }
    
    async initializeEngine() {
        const container = document.getElementById('canvas-container');
        if (!container) {
            throw new Error('Canvas container not found');
        }
        
        // Use mobile-optimized engine for mobile devices
        if (this.isMobile) {
            console.log('📱 Using Mobile Engine for mobile device');
            this.engine = new MobileEngine(container, {
                enablePerformanceMonitoring: this.config.enablePerformanceMonitoring,
                targetFPS: this.config.targetFPS,
                maxMemoryMB: this.config.maxMemoryMB,
                adaptiveQuality: true,
                batteryOptimization: true
            });
        } else {
            this.engine = new Engine(container, {
                enablePerformanceMonitoring: this.config.enablePerformanceMonitoring,
                targetFPS: this.config.targetFPS,
                maxMemoryMB: this.config.maxMemoryMB,
                enableStats: __DEV__
            });
        }
        
        // Wait for engine initialization
        return new Promise((resolve, reject) => {
            this.engine.once('initialized', resolve);
            this.engine.once('error', reject);
        });
    }
    
    async initializeSubsystems() {
        try {
            console.log('🔧 Initializing subsystems...');
            
            // Model loader
            console.log('📦 Creating ModelLoader...');
            this.modelLoader = new ModelLoader({
                enableDraco: true,
                maxCacheSize: 150,
                enableOptimization: true
            });
            console.log('✅ ModelLoader created');
            
            // Room manager
            console.log('🏠 Creating RoomManager...');
            this.roomManager = new RoomManager(this.engine, this.modelLoader);
            console.log('✅ RoomManager created');
            
            // UI manager
            console.log('🎮 Creating UIManager...');
            this.uiManager = new UIManager(this.engine, this.roomManager);
            console.log('✅ UIManager created');
            
            // Flutter bridge
            if (this.config.enableFlutterCommunication) {
                console.log('🌉 Creating FlutterBridge...');
                this.flutterBridge = new FlutterBridge(this.engine, this.roomManager);
                console.log('✅ FlutterBridge created');
                
                // Mobile bridge for mobile devices
                if (this.config.enableMobileControls) {
                    console.log('📱 Creating MobileBridge...');
                    this.mobileBridge = new MobileBridge(this.engine, this.roomManager, this.flutterBridge);
                    console.log('✅ MobileBridge created');
                    
                    // Touch controls
                    console.log('🎮 Creating TouchControls...');
                    this.touchControls = new TouchControls(this.engine.camera, container, this.mobileBridge);
                    console.log('✅ TouchControls created');
                }
            }
            
            console.log('✅ All subsystems initialized successfully');
        } catch (error) {
            console.error('❌ Subsystem initialization failed:', error);
            throw error;
        }
    }
    
    setupEventHandlers() {
        // Engine events
        this.engine.on('performanceWarning', this.handlePerformanceWarning.bind(this));
        this.engine.on('memoryPressure', this.handleMemoryPressure.bind(this));
        this.engine.on('error', this.handleEngineError.bind(this));
        
        // Model loader events
        this.modelLoader.on('progress', this.handleLoadingProgress.bind(this));
        this.modelLoader.on('loaded', this.handleModelLoaded.bind(this));
        this.modelLoader.on('error', this.handleModelError.bind(this));
        
        // Room manager events
        this.roomManager.on('roomChanged', this.handleRoomChanged.bind(this));
        this.roomManager.on('roomLoadStart', this.handleRoomLoadStart.bind(this));
        this.roomManager.on('roomLoadComplete', this.handleRoomLoadComplete.bind(this));
        
        // Window events
        window.addEventListener('beforeunload', this.handleBeforeUnload.bind(this));
        
        // Error handling
        window.addEventListener('error', this.handleGlobalError.bind(this));
        window.addEventListener('unhandledrejection', this.handleUnhandledRejection.bind(this));
    }
    
    async loadDefaultRoom() {
        console.log(`🏠 Loading default room: ${this.config.defaultRoom}`);
        
        try {
            // CRITICAL FIX: Add timeout to prevent hanging
            console.log('🔍 Testing model file accessibility...');
            
            // Create timeout signal with fallback for older browsers
            let timeoutId;
            const controller = new AbortController();
            const timeoutPromise = new Promise((_, reject) => {
                timeoutId = setTimeout(() => {
                    controller.abort();
                    reject(new Error('Model accessibility check timeout'));
                }, 5000);
            });
            
            const fetchPromise = fetch('/assets/models/classroom.glb', { 
                method: 'HEAD',
                signal: controller.signal
            });
            
            const testResponse = await Promise.race([fetchPromise, timeoutPromise]);
            clearTimeout(timeoutId);
            
            if (!testResponse.ok) {
                throw new Error(`Model file not accessible: ${testResponse.status} ${testResponse.statusText}`);
            }
            
            const contentType = testResponse.headers.get('content-type');
            const contentLength = testResponse.headers.get('content-length');
            
            console.log(`📁 Model file info: ${contentType}, ${contentLength ? (contentLength / 1024 / 1024).toFixed(2) + 'MB' : 'unknown size'}`);
            
            // CRITICAL FIX: Add timeout to room loading
            console.log('🏠 Starting room loading...');
            
            // Add progress tracking
            let progressInterval = setInterval(() => {
                console.log('⏳ Room loading in progress...');
            }, 2000);
            
            await Promise.race([
                this.roomManager.loadRoom(this.config.defaultRoom),
                new Promise((_, reject) => 
                    setTimeout(() => reject(new Error('Room loading timeout after 30 seconds')), 30000)
                )
            ]);
            
            clearInterval(progressInterval);
            
            this.currentRoom = this.config.defaultRoom;
            console.log(`✅ Default room loaded successfully: ${this.config.defaultRoom}`);
            
            // CRITICAL FIX: Notify Flutter that loading is complete
            if (this.flutterBridge) {
                console.log('📤 Sending roomLoadComplete message to Flutter');
                this.flutterBridge.sendMessage('roomLoadComplete', {
                    roomId: this.config.defaultRoom,
                    success: true,
                    timestamp: Date.now()
                });
            } else {
                console.warn('⚠️ FlutterBridge not available - cannot notify Flutter');
            }
            
        } catch (error) {
            console.error('❌ Failed to load default room:', error);
            
            // Try to show a helpful error message
            let errorMessage = error.message;
            if (error.message.includes('404') || error.message.includes('Not Found')) {
                errorMessage = `Model file not found. Please ensure classroom.glb is available at /assets/models/classroom.glb`;
            } else if (error.message.includes('CORS')) {
                errorMessage = `CORS error loading model. Check server configuration.`;
            } else if (error.message.includes('JSON')) {
                errorMessage = `Model file appears to be corrupted or served as HTML instead of binary GLB format.`;
            } else if (error.message.includes('timeout')) {
                errorMessage = `Room loading timed out. The model may be too large or the server is slow.`;
            }
            
            // CRITICAL FIX: Notify Flutter about the error
            if (this.flutterBridge) {
                console.log('📤 Sending roomLoadError message to Flutter');
                this.flutterBridge.sendMessage('roomLoadError', {
                    roomId: this.config.defaultRoom,
                    error: errorMessage,
                    timestamp: Date.now()
                });
            } else {
                console.warn('⚠️ FlutterBridge not available - cannot notify Flutter about error');
            }
            
            this.showError('Failed to load virtual environment', errorMessage);
        }
    }
    
    // Event Handlers
    handlePerformanceWarning(data) {
        console.warn('⚠️ Performance warning:', data);
        
        if (this.flutterBridge) {
            this.flutterBridge.sendMessage('performanceWarning', data);
        }
        
        // Auto-adjust quality if needed
        if (data.fps < this.config.targetFPS * 0.7) {
            this.engine.adjustQuality('lower');
        }
    }
    
    handleMemoryPressure(data) {
        console.warn('🧠 Memory pressure detected:', data);
        
        // Clear model cache
        this.modelLoader.clearCache();
        
        // Force garbage collection
        if (window.gc) {
            window.gc();
        }
        
        if (this.flutterBridge) {
            this.flutterBridge.sendMessage('memoryPressure', data);
        }
    }
    
    handleEngineError(error) {
        console.error('🚨 Engine error:', error);
        this.showError('3D Engine Error', error.message);
    }
    
    handleLoadingProgress(data) {
        this.updateLoadingProgress(data.percent, `Loading ${data.url}...`);
        
        if (this.flutterBridge) {
            this.flutterBridge.sendMessage('loadingProgress', data);
        }
    }
    
    handleModelLoaded(data) {
        console.log('📦 Model loaded:', data.url);
        
        if (this.flutterBridge) {
            this.flutterBridge.sendMessage('modelLoaded', {
                url: data.url,
                loadTime: data.loadTime,
                fromCache: data.fromCache
            });
        }
    }
    
    handleModelError(data) {
        console.error('📦 Model error:', data);
        this.showError('Model Loading Error', data.error);
        
        if (this.flutterBridge) {
            this.flutterBridge.sendMessage('modelError', data);
        }
    }
    
    handleRoomChanged(data) {
        console.log('🏠 Room changed:', data);
        this.currentRoom = data.roomId;
        
        if (this.flutterBridge) {
            this.flutterBridge.sendMessage('roomChanged', data);
        }
    }
    
    handleRoomLoadStart(data) {
        this.showLoadingScreen(`Loading ${data.roomName}...`);
    }
    
    handleRoomLoadComplete(data) {
        this.hideLoadingScreen();
        console.log('🏠 Room load completed:', data);
    }
    
    handleBeforeUnload() {
        this.dispose();
    }
    
    handleGlobalError(event) {
        console.error('🚨 Global error:', event.error);
        this.showError('Application Error', event.error?.message || 'An unexpected error occurred');
    }
    
    handleUnhandledRejection(event) {
        console.error('🚨 Unhandled promise rejection:', event.reason);
        this.showError('Application Error', event.reason?.message || 'An unexpected error occurred');
    }
    
    // UI Methods
    showLoadingScreen(message = 'Loading...') {
        const loadingScreen = document.getElementById('loading-screen');
        const loadingText = document.querySelector('.loading-text');
        
        if (loadingScreen) {
            loadingScreen.classList.remove('hidden');
        }
        
        if (loadingText) {
            loadingText.textContent = message;
        }
    }
    
    hideLoadingScreen() {
        const loadingScreen = document.getElementById('loading-screen');
        if (loadingScreen) {
            loadingScreen.classList.add('hidden');
        }
    }
    
    updateLoadingProgress(percent, message) {
        const progressFill = document.querySelector('.loading-progress-fill');
        const loadingText = document.querySelector('.loading-text');
        
        if (progressFill) {
            progressFill.style.width = `${percent}%`;
        }
        
        if (loadingText && message) {
            loadingText.textContent = `${message} ${Math.round(percent)}%`;
        }
    }
    
    showError(title, message) {
        const errorScreen = document.getElementById('error-screen');
        const errorTitle = document.querySelector('.error-title');
        const errorMessage = document.getElementById('error-message');
        
        if (errorScreen) {
            errorScreen.classList.add('visible');
        }
        
        if (errorTitle) {
            errorTitle.textContent = title;
        }
        
        if (errorMessage) {
            errorMessage.textContent = message;
        }
        
        // Hide loading screen
        this.hideLoadingScreen();
    }
    
    // Public API
    async loadRoom(roomId) {
        if (!this.isInitialized) {
            throw new Error('Application not initialized');
        }
        
        return this.roomManager.loadRoom(roomId);
    }
    
    setQuality(level) {
        if (this.engine) {
            this.engine.setQuality(level);
        }
    }
    
    getStats() {
        if (!this.engine) return null;
        
        return {
            engine: this.engine.getStats(),
            modelCache: this.modelLoader.getCacheInfo(),
            currentRoom: this.currentRoom,
            isInitialized: this.isInitialized
        };
    }
    
    dispose() {
        console.log('🧹 Disposing Virtual Tour Application...');
        
        if (this.touchControls) {
            this.touchControls.dispose();
        }
        
        if (this.mobileBridge) {
            this.mobileBridge.dispose();
        }
        
        if (this.flutterBridge) {
            this.flutterBridge.dispose();
        }
        
        if (this.uiManager) {
            this.uiManager.dispose();
        }
        
        if (this.roomManager) {
            this.roomManager.dispose();
        }
        
        if (this.modelLoader) {
            this.modelLoader.dispose();
        }
        
        if (this.engine) {
            this.engine.dispose();
        }
        
        console.log('✅ Application disposed');
    }
}

// Initialize application when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.virtualTourApp = new VirtualTourApp();
    });
} else {
    window.virtualTourApp = new VirtualTourApp();
}

// Export for external access
export { VirtualTourApp };