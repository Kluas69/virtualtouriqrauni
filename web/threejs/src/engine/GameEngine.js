/**
 * GameEngine - Professional game engine core with modular architecture
 * Implements component-based entity system with fixed timestep physics
 */

import * as THREE from 'three';
import { GameLoop } from './GameLoop.js';
import { EntityManager } from './EntityManager.js';
import { ComponentRegistry } from './ComponentRegistry.js';
import { RenderingSystem } from '../systems/RenderingSystem.js';
import { PhysicsSystem } from '../systems/PhysicsSystem.js';
import { AssetSystem } from '../systems/AssetSystem.js';
import { InputSystem } from '../systems/InputSystem.js';
import { PerformanceSystem } from '../systems/PerformanceSystem.js';
import { ErrorHandler } from '../core/ErrorHandler.js';

export class GameEngine {
    constructor(container, options = {}) {
        this.container = container;
        this.options = {
            targetFPS: 60,
            physicsHz: 120,
            enableDebug: false,
            enableStats: false,
            enableVR: false,
            qualityLevel: 'high',
            ...options
        };
        
        // Core engine components
        this.gameLoop = null;
        this.entityManager = null;
        this.componentRegistry = null;
        this.errorHandler = null;
        
        // Game systems
        this.systems = new Map();
        this.systemOrder = [
            'input',
            'physics', 
            'rendering',
            'performance'
        ];
        
        // Engine state
        this.isInitialized = false;
        this.isRunning = false;
        this.isPaused = false;
        
        // Performance tracking
        this.frameCount = 0;
        this.lastFrameTime = 0;
        this.averageFPS = 0;
        
        // Global references for debugging
        window.gameEngine = this;
        
        console.log('🎮 GameEngine created with professional architecture');
    }
    
    /**
     * Initialize the game engine and all systems
     */
    async initialize() {
        if (this.isInitialized) {
            console.warn('⚠️ GameEngine already initialized');
            return;
        }
        
        try {
            console.log('🚀 Initializing Professional Game Engine...');
            
            // Initialize error handler first
            this.errorHandler = new ErrorHandler({
                enableLogging: true,
                enableUserNotifications: true,
                enableAutoRecovery: true,
                debugMode: this.options.enableDebug
            });
            
            // Initialize core engine components
            this.initializeCoreComponents();
            
            // Initialize game systems
            await this.initializeSystems();
            
            // Setup game loop
            this.setupGameLoop();
            
            // Setup global event handlers
            this.setupEventHandlers();
            
            this.isInitialized = true;
            console.log('✅ Professional Game Engine initialized successfully');
            
        } catch (error) {
            console.error('❌ GameEngine initialization failed:', error);
            this.errorHandler?.handleError('GameEngineInit', error);
            throw error;
        }
    }
    
    /**
     * Initialize core engine components
     */
    initializeCoreComponents() {
        // Entity-Component-System architecture
        this.componentRegistry = new ComponentRegistry();
        this.entityManager = new EntityManager(this.componentRegistry);
        
        console.log('✅ Core ECS components initialized');
    }
    
    /**
     * Initialize all game systems
     */
    async initializeSystems() {
        try {
            // Rendering system (Three.js integration)
            const renderingSystem = new RenderingSystem(this.container, {
                antialias: true,
                enableShadows: true,
                enablePostProcessing: true,
                qualityLevel: this.options.qualityLevel,
                debugMode: this.options.enableDebug
            });
            await renderingSystem.initialize();
            this.systems.set('rendering', renderingSystem);
            
            // Physics system (enhanced collision detection)
            const physicsSystem = new PhysicsSystem({
                gravity: -9.81,
                enableCollisions: true,
                enableCCD: true, // Continuous collision detection
                debugMode: this.options.enableDebug
            });
            await physicsSystem.initialize();
            this.systems.set('physics', physicsSystem);
            
            // Asset system (streaming and LOD)
            const assetSystem = new AssetSystem({
                baseURL: '../assets/',
                enableStreaming: true,
                enableCompression: true,
                enableLOD: true,
                debugMode: this.options.enableDebug
            });
            await assetSystem.initialize();
            this.systems.set('assets', assetSystem);
            
            // Input system (multi-device support)
            const inputSystem = new InputSystem({
                enableKeyboard: true,
                enableMouse: true,
                enableTouch: true,
                enableGamepad: true,
                enableBuffering: true,
                debugMode: this.options.enableDebug
            });
            await inputSystem.initialize();
            this.systems.set('input', inputSystem);
            
            // Performance system (quality scaling)
            const performanceSystem = new PerformanceSystem({
                targetFPS: this.options.targetFPS,
                enableAutoScaling: true,
                enableProfiling: true,
                debugMode: this.options.enableDebug
            });
            await performanceSystem.initialize();
            this.systems.set('performance', performanceSystem);
            
            console.log('✅ All game systems initialized');
            
            // Verify critical systems are ready
            const criticalSystems = ['rendering', 'physics', 'assets', 'input'];
            const missingSystems = criticalSystems.filter(name => !this.systems.has(name));
            
            if (missingSystems.length > 0) {
                throw new Error(`Critical systems failed to initialize: ${missingSystems.join(', ')}`);
            }
            
            console.log('✅ All critical systems verified and ready');
            
        } catch (error) {
            console.error('❌ System initialization failed:', error);
            throw error;
        }
    }
    
    /**
     * Setup professional game loop with fixed timestep
     */
    setupGameLoop() {
        this.gameLoop = new GameLoop({
            targetFPS: this.options.targetFPS,
            physicsHz: this.options.physicsHz,
            maxFrameTime: 250 // Prevent spiral of death
        });
        
        // Bind update and render callbacks
        this.gameLoop.onUpdate = (deltaTime, totalTime) => {
            this.update(deltaTime, totalTime);
        };
        
        this.gameLoop.onRender = (interpolation) => {
            this.render(interpolation);
        };
        
        console.log('✅ Professional game loop configured');
    }
    
    /**
     * Setup global event handlers
     */
    setupEventHandlers() {
        // Window resize
        window.addEventListener('resize', () => {
            this.onResize(window.innerWidth, window.innerHeight);
        });
        
        // Visibility change (performance optimization)
        document.addEventListener('visibilitychange', () => {
            this.onVisibilityChange(!document.hidden);
        });
        
        // WebGL context loss recovery
        const canvas = this.systems.get('rendering')?.getCanvas();
        if (canvas) {
            canvas.addEventListener('webglcontextlost', (event) => {
                event.preventDefault();
                this.onWebGLContextLost();
            });
            
            canvas.addEventListener('webglcontextrestored', () => {
                this.onWebGLContextRestored();
            });
        }
        
        console.log('✅ Global event handlers setup');
    }
    
    /**
     * Start the game engine
     */
    start() {
        if (!this.isInitialized) {
            throw new Error('GameEngine must be initialized before starting');
        }
        
        if (this.isRunning) {
            console.warn('⚠️ GameEngine already running');
            return;
        }
        
        this.isRunning = true;
        this.isPaused = false;
        this.gameLoop.start();
        
        console.log('🎮 Professional Game Engine started');
    }
    
    /**
     * Stop the game engine
     */
    stop() {
        if (!this.isRunning) return;
        
        this.isRunning = false;
        this.gameLoop.stop();
        
        console.log('⏹️ Game Engine stopped');
    }
    
    /**
     * Pause the game engine
     */
    pause() {
        this.isPaused = true;
        console.log('⏸️ Game Engine paused');
    }
    
    /**
     * Resume the game engine
     */
    resume() {
        this.isPaused = false;
        console.log('▶️ Game Engine resumed');
    }
    
    /**
     * Update all systems (fixed timestep)
     * @param {number} deltaTime - Fixed timestep delta
     * @param {number} totalTime - Total elapsed time
     */
    update(deltaTime, totalTime) {
        if (this.isPaused) return;
        
        try {
            // Update systems in order
            for (const systemName of this.systemOrder) {
                const system = this.systems.get(systemName);
                if (system && system.update) {
                    system.update(deltaTime, totalTime);
                }
            }
            
            // Update entity manager
            this.entityManager.update(deltaTime, totalTime);
            
            // Update performance tracking
            this.updatePerformanceMetrics(deltaTime);
            
        } catch (error) {
            console.error('❌ Update loop error:', error);
            this.errorHandler.handleError('UpdateLoop', error);
        }
    }
    
    /**
     * Render all systems (interpolated)
     * @param {number} interpolation - Interpolation factor for smooth rendering
     */
    render(interpolation) {
        if (this.isPaused) return;
        
        try {
            // Render systems
            const renderingSystem = this.systems.get('rendering');
            if (renderingSystem && renderingSystem.render) {
                renderingSystem.render(interpolation);
            }
            
            // Update frame count
            this.frameCount++;
            
        } catch (error) {
            console.error('❌ Render loop error:', error);
            this.errorHandler.handleError('RenderLoop', error);
        }
    }
    
    /**
     * Update performance metrics
     * @param {number} deltaTime - Frame delta time
     */
    updatePerformanceMetrics(deltaTime) {
        const currentTime = performance.now();
        
        if (currentTime - this.lastFrameTime >= 1000) {
            this.averageFPS = this.frameCount;
            this.frameCount = 0;
            this.lastFrameTime = currentTime;
            
            // Update performance system
            const performanceSystem = this.systems.get('performance');
            if (performanceSystem) {
                performanceSystem.updateMetrics({
                    fps: this.averageFPS,
                    frameTime: deltaTime,
                    timestamp: currentTime
                });
            }
        }
    }
    
    /**
     * Handle window resize
     * @param {number} width - New width
     * @param {number} height - New height
     */
    onResize(width, height) {
        try {
            const renderingSystem = this.systems.get('rendering');
            if (renderingSystem && renderingSystem.onResize) {
                renderingSystem.onResize(width, height);
            }
            
            console.log(`📐 Engine resized to ${width}×${height}`);
        } catch (error) {
            this.errorHandler.handleError('Resize', error, { width, height });
        }
    }
    
    /**
     * Handle visibility change
     * @param {boolean} visible - Whether page is visible
     */
    onVisibilityChange(visible) {
        try {
            if (visible) {
                this.resume();
            } else {
                this.pause();
            }
        } catch (error) {
            this.errorHandler.handleError('VisibilityChange', error, { visible });
        }
    }
    
    /**
     * Handle WebGL context loss
     */
    onWebGLContextLost() {
        console.warn('🔄 WebGL context lost - pausing engine');
        this.pause();
        
        // Notify all systems
        for (const [name, system] of this.systems) {
            if (system.onContextLost) {
                system.onContextLost();
            }
        }
    }
    
    /**
     * Handle WebGL context restoration
     */
    async onWebGLContextRestored() {
        console.log('🔄 WebGL context restored - recovering engine');
        
        try {
            // Restore all systems
            for (const [name, system] of this.systems) {
                if (system.onContextRestored) {
                    await system.onContextRestored();
                }
            }
            
            this.resume();
            console.log('✅ WebGL context recovery complete');
            
        } catch (error) {
            console.error('❌ WebGL context recovery failed:', error);
            this.errorHandler.handleError('WebGLRecovery', error);
        }
    }
    
    /**
     * Get system by name
     * @param {string} name - System name
     * @returns {Object|null} System instance
     */
    getSystem(name) {
        return this.systems.get(name) || null;
    }
    
    /**
     * Add entity to the game world
     * @param {Object} entity - Entity to add
     * @returns {number} Entity ID
     */
    addEntity(entity) {
        return this.entityManager.addEntity(entity);
    }
    
    /**
     * Remove entity from the game world
     * @param {number} entityId - Entity ID to remove
     */
    removeEntity(entityId) {
        this.entityManager.removeEntity(entityId);
    }
    
    /**
     * Get entity by ID
     * @param {number} entityId - Entity ID
     * @returns {Object|null} Entity instance
     */
    getEntity(entityId) {
        return this.entityManager.getEntity(entityId);
    }
    
    /**
     * Get engine statistics
     * @returns {Object} Engine statistics
     */
    getStatistics() {
        return {
            isInitialized: this.isInitialized,
            isRunning: this.isRunning,
            isPaused: this.isPaused,
            averageFPS: this.averageFPS,
            frameCount: this.frameCount,
            entityCount: this.entityManager?.getEntityCount() || 0,
            systemCount: this.systems.size,
            systems: Array.from(this.systems.keys()),
            performance: this.systems.get('performance')?.getMetrics() || null
        };
    }
    
    /**
     * Dispose of all engine resources
     */
    dispose() {
        try {
            // Stop engine
            this.stop();
            
            // Dispose all systems
            for (const [name, system] of this.systems) {
                if (system.dispose) {
                    system.dispose();
                }
            }
            this.systems.clear();
            
            // Dispose core components
            if (this.entityManager) {
                this.entityManager.dispose();
            }
            
            if (this.componentRegistry) {
                this.componentRegistry.dispose();
            }
            
            if (this.gameLoop) {
                this.gameLoop.dispose();
            }
            
            if (this.errorHandler) {
                this.errorHandler.dispose();
            }
            
            // Clear global references
            if (window.gameEngine === this) {
                delete window.gameEngine;
            }
            
            this.isInitialized = false;
            console.log('🗑️ GameEngine disposed');
            
        } catch (error) {
            console.error('❌ Error during GameEngine disposal:', error);
        }
    }
}