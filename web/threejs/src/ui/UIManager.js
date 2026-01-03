/**
 * UI Manager
 * Handles user interface elements and interactions
 */

import { EventEmitter } from '../utils/EventEmitter.js';

export class UIManager extends EventEmitter {
    constructor(engine, roomManager) {
        super();
        
        this.engine = engine;
        this.roomManager = roomManager;
        
        // UI state
        this.isVisible = true;
        this.isFirstPersonMode = false;
        this.showHotspots = true;
        this.showPerformanceStats = false;
        
        // UI elements
        this.uiContainer = null;
        this.loadingScreen = null;
        this.errorScreen = null;
        this.controlsPanel = null;
        this.statsPanel = null;
        this.hotspotsContainer = null;
        
        // Controls state
        this.keys = {};
        this.mouse = { x: 0, y: 0, isLocked: false };
        this.touch = { isActive: false, startX: 0, startY: 0 };
        
        // Mobile detection
        this.isMobile = this.detectMobileDevice();
        
        this.init();
    }
    
    init() {
        console.log('🎨 Initializing UI Manager...');
        
        // Create UI elements
        this.createUIElements();
        
        // Setup event listeners
        this.setupEventListeners();
        
        // Setup controls
        this.setupControls();
        
        // Setup engine event handlers
        this.setupEngineEventHandlers();
        
        console.log('✅ UI Manager initialized');
    }
    
    detectMobileDevice() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    }
    
    createUIElements() {
        // Main UI container
        this.uiContainer = document.createElement('div');
        this.uiContainer.id = 'ui-container';
        this.uiContainer.style.cssText = `
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            z-index: 1000;
            font-family: 'Roboto', sans-serif;
        `;
        document.body.appendChild(this.uiContainer);
        
        // Create individual UI components
        this.createLoadingScreen();
        this.createErrorScreen();
        this.createControlsPanel();
        this.createStatsPanel();
        this.createHotspotsContainer();
        
        console.log('🎨 UI elements created');
    }
    
    createLoadingScreen() {
        this.loadingScreen = document.createElement('div');
        this.loadingScreen.id = 'loading-screen';
        this.loadingScreen.className = 'hidden';
        this.loadingScreen.style.cssText = `
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            color: white;
            pointer-events: all;
            transition: opacity 0.3s ease;
        `;
        
        this.loadingScreen.innerHTML = `
            <div class="loading-spinner" style="
                width: 60px;
                height: 60px;
                border: 4px solid rgba(255,255,255,0.3);
                border-top: 4px solid white;
                border-radius: 50%;
                animation: spin 1s linear infinite;
                margin-bottom: 20px;
            "></div>
            <div class="loading-text" style="
                font-size: 18px;
                font-weight: 500;
                margin-bottom: 10px;
            ">Loading...</div>
            <div class="loading-progress" style="
                width: 300px;
                height: 4px;
                background: rgba(255,255,255,0.3);
                border-radius: 2px;
                overflow: hidden;
            ">
                <div class="loading-progress-fill" style="
                    width: 0%;
                    height: 100%;
                    background: white;
                    transition: width 0.3s ease;
                "></div>
            </div>
        `;
        
        this.uiContainer.appendChild(this.loadingScreen);
        
        // Add CSS animation
        const style = document.createElement('style');
        style.textContent = `
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
            .hidden { opacity: 0; pointer-events: none; }
        `;
        document.head.appendChild(style);
    }
    
    createErrorScreen() {
        this.errorScreen = document.createElement('div');
        this.errorScreen.id = 'error-screen';
        this.errorScreen.style.cssText = `
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            color: white;
            pointer-events: all;
            opacity: 0;
            transition: opacity 0.3s ease;
            padding: 20px;
            box-sizing: border-box;
        `;
        
        this.errorScreen.innerHTML = `
            <div style="font-size: 48px; margin-bottom: 20px;">⚠️</div>
            <div class="error-title" style="
                font-size: 24px;
                font-weight: bold;
                margin-bottom: 10px;
                text-align: center;
            ">Error</div>
            <div id="error-message" style="
                font-size: 16px;
                text-align: center;
                max-width: 600px;
                line-height: 1.5;
                margin-bottom: 30px;
            "></div>
            <button id="retry-button" style="
                background: white;
                color: #ee5a24;
                border: none;
                padding: 12px 24px;
                border-radius: 6px;
                font-size: 16px;
                font-weight: 500;
                cursor: pointer;
                transition: transform 0.2s ease;
            " onmouseover="this.style.transform='scale(1.05)'" 
               onmouseout="this.style.transform='scale(1)'">
                Retry
            </button>
        `;
        
        this.uiContainer.appendChild(this.errorScreen);
        
        // Setup retry button
        const retryButton = this.errorScreen.querySelector('#retry-button');
        retryButton.addEventListener('click', () => {
            this.emit('retryRequested');
        });
    }
    
    createControlsPanel() {
        this.controlsPanel = document.createElement('div');
        this.controlsPanel.id = 'controls-panel';
        this.controlsPanel.style.cssText = `
            position: absolute;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: rgba(0,0,0,0.7);
            color: white;
            padding: 15px 20px;
            border-radius: 25px;
            display: flex;
            gap: 15px;
            align-items: center;
            pointer-events: all;
            transition: opacity 0.3s ease;
            backdrop-filter: blur(10px);
        `;
        
        const controls = [
            { id: 'first-person-btn', icon: '🎮', title: 'First Person Mode' },
            { id: 'hotspots-btn', icon: '📍', title: 'Toggle Hotspots' },
            { id: 'stats-btn', icon: '📊', title: 'Performance Stats' },
            { id: 'fullscreen-btn', icon: '⛶', title: 'Fullscreen' }
        ];
        
        controls.forEach(control => {
            const button = document.createElement('button');
            button.id = control.id;
            button.innerHTML = control.icon;
            button.title = control.title;
            button.style.cssText = `
                background: transparent;
                border: 2px solid rgba(255,255,255,0.3);
                color: white;
                width: 40px;
                height: 40px;
                border-radius: 50%;
                cursor: pointer;
                font-size: 16px;
                transition: all 0.2s ease;
                display: flex;
                align-items: center;
                justify-content: center;
            `;
            
            button.addEventListener('mouseenter', () => {
                button.style.background = 'rgba(255,255,255,0.2)';
                button.style.borderColor = 'white';
            });
            
            button.addEventListener('mouseleave', () => {
                button.style.background = 'transparent';
                button.style.borderColor = 'rgba(255,255,255,0.3)';
            });
            
            this.controlsPanel.appendChild(button);
        });
        
        this.uiContainer.appendChild(this.controlsPanel);
        
        // Setup control button handlers
        this.setupControlButtons();
    }
    
    createStatsPanel() {
        this.statsPanel = document.createElement('div');
        this.statsPanel.id = 'stats-panel';
        this.statsPanel.style.cssText = `
            position: absolute;
            top: 20px;
            right: 20px;
            background: rgba(0,0,0,0.8);
            color: white;
            padding: 15px;
            border-radius: 8px;
            font-family: monospace;
            font-size: 12px;
            line-height: 1.4;
            pointer-events: all;
            opacity: 0;
            transition: opacity 0.3s ease;
            backdrop-filter: blur(10px);
            min-width: 200px;
        `;
        
        this.statsPanel.innerHTML = `
            <div style="font-weight: bold; margin-bottom: 10px;">Performance Stats</div>
            <div id="fps-stat">FPS: --</div>
            <div id="memory-stat">Memory: -- MB</div>
            <div id="triangles-stat">Triangles: --</div>
            <div id="drawcalls-stat">Draw Calls: --</div>
            <div id="room-stat">Room: --</div>
        `;
        
        this.uiContainer.appendChild(this.statsPanel);
    }
    
    createHotspotsContainer() {
        this.hotspotsContainer = document.createElement('div');
        this.hotspotsContainer.id = 'hotspots-container';
        this.hotspotsContainer.style.cssText = `
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
        `;
        
        this.uiContainer.appendChild(this.hotspotsContainer);
    }
    
    setupControlButtons() {
        // First person mode toggle
        const firstPersonBtn = this.controlsPanel.querySelector('#first-person-btn');
        firstPersonBtn.addEventListener('click', () => {
            this.toggleFirstPersonMode();
        });
        
        // Hotspots toggle
        const hotspotsBtn = this.controlsPanel.querySelector('#hotspots-btn');
        hotspotsBtn.addEventListener('click', () => {
            this.toggleHotspots();
        });
        
        // Stats toggle
        const statsBtn = this.controlsPanel.querySelector('#stats-btn');
        statsBtn.addEventListener('click', () => {
            this.toggleStats();
        });
        
        // Fullscreen toggle
        const fullscreenBtn = this.controlsPanel.querySelector('#fullscreen-btn');
        fullscreenBtn.addEventListener('click', () => {
            this.toggleFullscreen();
        });
    }
    
    setupEventListeners() {
        // Window resize
        window.addEventListener('resize', this.handleResize.bind(this));
        
        // Visibility change
        document.addEventListener('visibilitychange', this.handleVisibilityChange.bind(this));
        
        // Room manager events
        this.roomManager.on('roomLoadStart', this.handleRoomLoadStart.bind(this));
        this.roomManager.on('roomLoadComplete', this.handleRoomLoadComplete.bind(this));
        this.roomManager.on('loadingProgress', this.handleLoadingProgress.bind(this));
        this.roomManager.on('roomChanged', this.handleRoomChanged.bind(this));
    }
    
    setupControls() {
        if (this.isMobile) {
            this.setupTouchControls();
        } else {
            this.setupKeyboardControls();
            this.setupMouseControls();
        }
    }
    
    setupKeyboardControls() {
        document.addEventListener('keydown', (event) => {
            this.keys[event.code] = true;
            
            // Handle special keys
            switch (event.code) {
                case 'Escape':
                    if (this.isFirstPersonMode) {
                        this.exitFirstPersonMode();
                    }
                    break;
                case 'KeyF':
                    this.toggleFullscreen();
                    break;
                case 'KeyH':
                    this.toggleHotspots();
                    break;
                case 'KeyP':
                    this.toggleStats();
                    break;
            }
        });
        
        document.addEventListener('keyup', (event) => {
            this.keys[event.code] = false;
        });
    }
    
    setupMouseControls() {
        const canvas = this.engine.renderer.domElement;
        
        // Click to enter first person mode
        canvas.addEventListener('click', () => {
            if (!this.isFirstPersonMode) {
                this.enterFirstPersonMode();
            }
        });
        
        // Mouse movement
        document.addEventListener('mousemove', (event) => {
            if (this.isFirstPersonMode && this.mouse.isLocked) {
                const movementX = event.movementX || 0;
                const movementY = event.movementY || 0;
                
                this.engine.camera.rotate(movementX * 0.002, movementY * 0.002);
            }
        });
        
        // Pointer lock events
        document.addEventListener('pointerlockchange', () => {
            this.mouse.isLocked = document.pointerLockElement === canvas;
            if (!this.mouse.isLocked && this.isFirstPersonMode) {
                this.exitFirstPersonMode();
            }
        });
    }
    
    setupTouchControls() {
        const canvas = this.engine.renderer.domElement;
        
        // Touch start
        canvas.addEventListener('touchstart', (event) => {
            event.preventDefault();
            
            if (event.touches.length === 1) {
                this.touch.isActive = true;
                this.touch.startX = event.touches[0].clientX;
                this.touch.startY = event.touches[0].clientY;
                
                if (!this.isFirstPersonMode) {
                    this.enterFirstPersonMode();
                }
            }
        });
        
        // Touch move
        canvas.addEventListener('touchmove', (event) => {
            event.preventDefault();
            
            if (this.touch.isActive && event.touches.length === 1) {
                const deltaX = event.touches[0].clientX - this.touch.startX;
                const deltaY = event.touches[0].clientY - this.touch.startY;
                
                this.engine.camera.rotate(deltaX * 0.01, deltaY * 0.01);
                
                this.touch.startX = event.touches[0].clientX;
                this.touch.startY = event.touches[0].clientY;
            }
        });
        
        // Touch end
        canvas.addEventListener('touchend', (event) => {
            event.preventDefault();
            this.touch.isActive = false;
        });
    }
    
    setupEngineEventHandlers() {
        this.engine.on('frame', this.updateControls.bind(this));
        this.engine.on('frame', this.updateStats.bind(this));
    }
    
    updateControls(data) {
        if (!this.isFirstPersonMode) return;
        
        const speed = this.keys['ShiftLeft'] ? 0.1 : 0.05;
        const camera = this.engine.camera;
        
        // WASD movement
        if (this.keys['KeyW']) camera.moveForward(speed);
        if (this.keys['KeyS']) camera.moveBackward(speed);
        if (this.keys['KeyA']) camera.moveLeft(speed);
        if (this.keys['KeyD']) camera.moveRight(speed);
        if (this.keys['Space']) camera.moveUp(speed);
        if (this.keys['KeyC']) camera.moveDown(speed);
    }
    
    updateStats(data) {
        if (!this.showPerformanceStats) return;
        
        const stats = this.engine.getStats();
        const currentRoom = this.roomManager.getCurrentRoom();
        
        this.statsPanel.querySelector('#fps-stat').textContent = `FPS: ${Math.round(data.fps)}`;
        this.statsPanel.querySelector('#memory-stat').textContent = `Memory: ${stats.memory?.used || '--'} MB`;
        this.statsPanel.querySelector('#triangles-stat').textContent = `Triangles: ${stats.renderer?.triangles || '--'}`;
        this.statsPanel.querySelector('#drawcalls-stat').textContent = `Draw Calls: ${stats.renderer?.calls || '--'}`;
        this.statsPanel.querySelector('#room-stat').textContent = `Room: ${currentRoom?.name || 'None'}`;
    }
    
    // Event handlers
    handleResize() {
        // Update UI layout if needed
        this.emit('resize');
    }
    
    handleVisibilityChange() {
        if (document.hidden && this.isFirstPersonMode) {
            this.exitFirstPersonMode();
        }
    }
    
    handleRoomLoadStart(data) {
        this.showLoadingScreen(`Loading ${data.roomName}...`);
    }
    
    handleRoomLoadComplete(data) {
        this.hideLoadingScreen();
    }
    
    handleLoadingProgress(data) {
        this.updateLoadingProgress(data.progress, `Loading ${data.roomId}...`);
    }
    
    handleRoomChanged(data) {
        // Update UI for new room
        this.updateHotspots();
    }
    
    // Public API
    toggleFirstPersonMode() {
        if (this.isFirstPersonMode) {
            this.exitFirstPersonMode();
        } else {
            this.enterFirstPersonMode();
        }
    }
    
    enterFirstPersonMode() {
        if (this.isMobile) {
            this.isFirstPersonMode = true;
            this.controlsPanel.style.opacity = '0.5';
            console.log('📱 Entered first person mode (mobile)');
        } else {
            const canvas = this.engine.renderer.domElement;
            canvas.requestPointerLock();
            this.isFirstPersonMode = true;
            this.controlsPanel.style.opacity = '0.5';
            console.log('🎮 Entered first person mode');
        }
        
        this.emit('firstPersonModeEntered');
    }
    
    exitFirstPersonMode() {
        if (!this.isMobile && document.pointerLockElement) {
            document.exitPointerLock();
        }
        
        this.isFirstPersonMode = false;
        this.controlsPanel.style.opacity = '1';
        console.log('🚪 Exited first person mode');
        
        this.emit('firstPersonModeExited');
    }
    
    toggleHotspots() {
        this.showHotspots = !this.showHotspots;
        this.hotspotsContainer.style.display = this.showHotspots ? 'block' : 'none';
        
        const btn = this.controlsPanel.querySelector('#hotspots-btn');
        btn.style.opacity = this.showHotspots ? '1' : '0.5';
        
        console.log(`📍 Hotspots ${this.showHotspots ? 'shown' : 'hidden'}`);
    }
    
    toggleStats() {
        this.showPerformanceStats = !this.showPerformanceStats;
        this.statsPanel.style.opacity = this.showPerformanceStats ? '1' : '0';
        
        const btn = this.controlsPanel.querySelector('#stats-btn');
        btn.style.opacity = this.showPerformanceStats ? '1' : '0.5';
        
        console.log(`📊 Stats ${this.showPerformanceStats ? 'shown' : 'hidden'}`);
    }
    
    toggleFullscreen() {
        if (document.fullscreenElement) {
            document.exitFullscreen();
        } else {
            document.documentElement.requestFullscreen();
        }
    }
    
    showLoadingScreen(message = 'Loading...') {
        this.loadingScreen.classList.remove('hidden');
        this.loadingScreen.querySelector('.loading-text').textContent = message;
        this.loadingScreen.querySelector('.loading-progress-fill').style.width = '0%';
    }
    
    hideLoadingScreen() {
        this.loadingScreen.classList.add('hidden');
    }
    
    updateLoadingProgress(percent, message) {
        const progressFill = this.loadingScreen.querySelector('.loading-progress-fill');
        const loadingText = this.loadingScreen.querySelector('.loading-text');
        
        if (progressFill) {
            progressFill.style.width = `${percent}%`;
        }
        
        if (loadingText && message) {
            loadingText.textContent = `${message} ${Math.round(percent)}%`;
        }
    }
    
    showError(title, message) {
        this.errorScreen.style.opacity = '1';
        this.errorScreen.querySelector('.error-title').textContent = title;
        this.errorScreen.querySelector('#error-message').textContent = message;
        
        // Hide loading screen
        this.hideLoadingScreen();
    }
    
    hideError() {
        this.errorScreen.style.opacity = '0';
    }
    
    updateHotspots() {
        // Clear existing hotspots
        this.hotspotsContainer.innerHTML = '';
        
        const currentRoom = this.roomManager.getCurrentRoom();
        if (!currentRoom || !currentRoom.config.hotspots) return;
        
        // Create hotspot UI elements
        currentRoom.config.hotspots.forEach(hotspot => {
            const hotspotElement = this.createHotspotElement(hotspot);
            this.hotspotsContainer.appendChild(hotspotElement);
        });
    }
    
    createHotspotElement(hotspot) {
        const element = document.createElement('div');
        element.className = 'hotspot-ui';
        element.style.cssText = `
            position: absolute;
            background: rgba(0,150,255,0.9);
            color: white;
            padding: 8px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 500;
            pointer-events: all;
            cursor: pointer;
            transition: all 0.2s ease;
            backdrop-filter: blur(10px);
            border: 2px solid rgba(255,255,255,0.3);
        `;
        
        element.textContent = hotspot.title;
        
        // Position based on 3D coordinates (simplified)
        element.style.left = `${50 + hotspot.position.x * 10}%`;
        element.style.top = `${50 - hotspot.position.y * 10}%`;
        
        // Hover effects
        element.addEventListener('mouseenter', () => {
            element.style.transform = 'scale(1.1)';
            element.style.background = 'rgba(0,150,255,1)';
        });
        
        element.addEventListener('mouseleave', () => {
            element.style.transform = 'scale(1)';
            element.style.background = 'rgba(0,150,255,0.9)';
        });
        
        // Click handler
        element.addEventListener('click', () => {
            this.emit('hotspotClicked', {
                hotspotId: hotspot.id,
                hotspot: hotspot
            });
        });
        
        return element;
    }
    
    setVisible(visible) {
        this.isVisible = visible;
        this.uiContainer.style.display = visible ? 'block' : 'none';
    }
    
    dispose() {
        console.log('🧹 Disposing UI Manager...');
        
        // Remove event listeners
        window.removeEventListener('resize', this.handleResize.bind(this));
        document.removeEventListener('visibilitychange', this.handleVisibilityChange.bind(this));
        
        // Remove UI elements
        if (this.uiContainer && this.uiContainer.parentNode) {
            this.uiContainer.parentNode.removeChild(this.uiContainer);
        }
        
        // Clear state
        this.keys = {};
        this.isFirstPersonMode = false;
        
        this.removeAllListeners();
        console.log('✅ UI Manager disposed');
    }
}