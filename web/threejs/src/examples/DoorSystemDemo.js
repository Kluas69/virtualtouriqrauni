/**
 * DoorSystemDemo - Example implementation of the professional door interaction system
 * Shows how to integrate doors into your 3D scene with AAA-quality interactions
 */

import { GameEngine } from '../engine/GameEngine.js';
import { ModelLoader } from '../loaders/ModelLoader.js';

export class DoorSystemDemo {
    constructor(container) {
        this.container = container;
        this.gameEngine = null;
        this.modelLoader = null;
        this.loadedModel = null;
    }
    
    /**
     * Initialize the demo
     */
    async initialize() {
        try {
            console.log('🎮 Initializing Door System Demo...');
            
            // Initialize game engine
            this.gameEngine = new GameEngine(this.container, {
                targetFPS: 60,
                enableDebug: true,
                qualityLevel: 'high'
            });
            
            await this.gameEngine.initialize();
            
            // Initialize model loader
            this.modelLoader = new ModelLoader({
                enableProgress: true,
                debugMode: true
            });
            
            // Load the 3D model with doors
            await this.loadModel();
            
            // Setup camera and controls
            this.setupCamera();
            
            // Start the game engine
            this.gameEngine.start();
            
            console.log('✅ Door System Demo initialized successfully');
            
        } catch (error) {
            console.error('❌ Failed to initialize Door System Demo:', error);
            throw error;
        }
    }
    
    /**
     * Load the 3D model containing doors
     */
    async loadModel() {
        try {
            console.log('📦 Loading 3D model with doors...');
            
            // Load your model (replace with your actual model file)
            const modelResult = await this.modelLoader.loadModel('classroom.glb');
            this.loadedModel = modelResult.model;
            
            // Add model to scene
            const renderingSystem = this.gameEngine.getSystem('rendering');
            const scene = renderingSystem.getScene();
            scene.add(this.loadedModel.scene);
            
            // The DoorInteractionSystem will automatically detect doors named 'LR_DOOR'
            // You can also manually register doors if needed
            this.registerCustomDoors();
            
            console.log('✅ Model loaded and doors registered');
            
        } catch (error) {
            console.error('❌ Failed to load model:', error);
            throw error;
        }
    }
    
    /**
     * Register custom doors or configure existing ones
     */
    registerCustomDoors() {
        const doorSystem = this.gameEngine.getSystem('doors');
        
        // Find doors in the loaded model
        this.loadedModel.scene.traverse((object) => {
            if (object.isMesh && object.name && object.name.includes('LR_DOOR')) {
                console.log(`🚪 Found door: ${object.name}`);
                
                // The door is already auto-detected, but you can customize it
                const doorData = doorSystem.getDoorByObject(object);
                if (doorData) {
                    // Customize door properties
                    doorData.component.interactionPrompt = 'Press F to open door';
                    doorData.component.animationDuration = 1.5; // Slower animation
                    doorData.component.openAngle = 90; // 90 degree opening
                    
                    // Add custom callbacks
                    doorData.component.onInteract = (component) => {
                        console.log(`🎯 Player interacted with: ${component.name}`);
                    };
                    
                    doorData.component.onStateChange = (oldState, newState) => {
                        console.log(`🔄 Door state changed: ${oldState} → ${newState}`);
                    };
                }
            }
        });
    }
    
    /**
     * Setup camera and player controls
     */
    setupCamera() {
        const renderingSystem = this.gameEngine.getSystem('rendering');
        const camera = renderingSystem.getCamera();
        
        // Position camera for good view of doors
        camera.position.set(0, 2, 5);
        camera.lookAt(0, 0, 0);
        
        // Add basic WASD movement (you can enhance this)
        this.setupBasicMovement(camera);
    }
    
    /**
     * Setup basic WASD movement for testing
     * @param {THREE.Camera} camera - Camera to control
     */
    setupBasicMovement(camera) {
        const inputSystem = this.gameEngine.getSystem('input');
        const moveSpeed = 5.0;
        
        // Movement update function
        const updateMovement = (deltaTime) => {
            const moveDistance = moveSpeed * deltaTime;
            
            if (inputSystem.isKeyPressed('KeyW')) {
                camera.translateZ(-moveDistance);
            }
            if (inputSystem.isKeyPressed('KeyS')) {
                camera.translateZ(moveDistance);
            }
            if (inputSystem.isKeyPressed('KeyA')) {
                camera.translateX(-moveDistance);
            }
            if (inputSystem.isKeyPressed('KeyD')) {
                camera.translateX(moveDistance);
            }
            if (inputSystem.isKeyPressed('KeyQ')) {
                camera.position.y += moveDistance;
            }
            if (inputSystem.isKeyPressed('KeyE')) {
                camera.position.y -= moveDistance;
            }
        };
        
        // Add to game loop
        const originalUpdate = this.gameEngine.update.bind(this.gameEngine);
        this.gameEngine.update = (deltaTime, totalTime) => {
            originalUpdate(deltaTime, totalTime);
            updateMovement(deltaTime);
        };
        
        console.log('🎮 Basic WASD movement setup (W/A/S/D to move, Q/E for up/down, F to interact with doors)');
    }
    
    /**
     * Get demo statistics
     * @returns {Object} Demo statistics
     */
    getStatistics() {
        const doorSystem = this.gameEngine.getSystem('doors');
        const engineStats = this.gameEngine.getStatistics();
        const doorStats = doorSystem.getStatistics();
        
        return {
            engine: engineStats,
            doors: doorStats,
            modelLoaded: !!this.loadedModel
        };
    }
    
    /**
     * Dispose of demo resources
     */
    dispose() {
        if (this.gameEngine) {
            this.gameEngine.dispose();
        }
        
        if (this.modelLoader) {
            this.modelLoader.dispose();
        }
        
        console.log('🗑️ Door System Demo disposed');
    }
}

// Usage example:
// const demo = new DoorSystemDemo(document.getElementById('game-container'));
// demo.initialize().then(() => {
//     console.log('Demo ready! Use WASD to move, F to interact with doors');
// });