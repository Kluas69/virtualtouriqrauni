/**
 * DoorInteractionSystem - Professional door interaction system
 * Implements AAA-quality door mechanics with smooth animations, proximity detection, and raycasting
 */

import * as THREE from 'three';
import { InteractionComponent } from '../components/InteractionComponent.js';

export class DoorInteractionSystem {
    constructor(options = {}) {
        this.options = {
            maxInteractionDistance: 5.0,
            raycastPrecision: 0.1,
            enableUI: true,
            enableSounds: true,
            debugMode: false,
            ...options
        };
        
        // Core references
        this.scene = null;
        this.camera = null;
        this.inputSystem = null;
        this.renderer = null;
        
        // Door management
        this.doors = new Map(); // entityId -> door data
        this.activeDoor = null; // Currently highlighted door
        this.animatingDoors = new Set(); // Doors currently animating
        
        // Raycasting
        this.raycaster = new THREE.Raycaster();
        this.rayDirection = new THREE.Vector3();
        
        // Animation system
        this.animationTweens = new Map();
        
        // UI elements
        this.uiElements = {
            interactionPrompt: null,
            crosshair: null
        };
        
        // Input handling
        this.inputCallbacks = new Map();
        
        console.log('✅ DoorInteractionSystem initialized');
    }
    
    /**
     * Initialize the door interaction system
     * @param {Object} gameEngine - Reference to game engine
     */
    async initialize(gameEngine) {
        this.scene = gameEngine.getSystem('rendering')?.getScene();
        this.camera = gameEngine.getSystem('rendering')?.getCamera();
        this.inputSystem = gameEngine.getSystem('input');
        this.renderer = gameEngine.getSystem('rendering')?.getRenderer();
        
        if (!this.scene || !this.camera || !this.inputSystem) {
            throw new Error('DoorInteractionSystem requires scene, camera, and input system');
        }
        
        // Setup input handling
        this.setupInputHandling();
        
        // Setup UI
        if (this.options.enableUI) {
            this.setupUI();
        }
        
        // Auto-detect doors in scene
        this.autoDetectDoors();
        
        console.log('🚪 DoorInteractionSystem initialized with professional features');
    }
    
    /**
     * Setup input handling for door interactions
     */
    setupInputHandling() {
        // Register F key handler
        const keydownCallback = (event) => {
            if (event.code === 'KeyF' && this.activeDoor) {
                this.interactWithDoor(this.activeDoor);
            }
        };
        
        this.inputSystem.on('keydown', keydownCallback);
        this.inputCallbacks.set('keydown', keydownCallback);
        
        console.log('⌨️ Door interaction input handling setup');
    }
    
    /**
     * Setup UI elements for door interactions
     */
    setupUI() {
        // Create interaction prompt
        this.uiElements.interactionPrompt = this.createInteractionPrompt();
        
        // Create enhanced crosshair
        this.uiElements.crosshair = this.createCrosshair();
        
        console.log('🎨 Door interaction UI setup');
    }
    
    /**
     * Create interaction prompt UI element
     * @returns {HTMLElement} Prompt element
     */
    createInteractionPrompt() {
        const prompt = document.createElement('div');
        prompt.id = 'door-interaction-prompt';
        prompt.style.cssText = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(0, 0, 0, 0.8);
            color: white;
            padding: 12px 20px;
            border-radius: 8px;
            font-family: 'Arial', sans-serif;
            font-size: 16px;
            font-weight: bold;
            text-align: center;
            pointer-events: none;
            z-index: 1000;
            opacity: 0;
            transition: opacity 0.3s ease;
            border: 2px solid #00ff88;
            box-shadow: 0 0 20px rgba(0, 255, 136, 0.3);
            backdrop-filter: blur(5px);
        `;
        
        document.body.appendChild(prompt);
        return prompt;
    }
    
    /**
     * Create enhanced crosshair
     * @returns {HTMLElement} Crosshair element
     */
    createCrosshair() {
        const crosshair = document.createElement('div');
        crosshair.id = 'door-crosshair';
        crosshair.style.cssText = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 20px;
            height: 20px;
            pointer-events: none;
            z-index: 999;
            transition: all 0.2s ease;
        `;
        
        crosshair.innerHTML = `
            <div style="
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                width: 2px;
                height: 12px;
                background: white;
                box-shadow: 0 0 4px rgba(0,0,0,0.5);
            "></div>
            <div style="
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                width: 12px;
                height: 2px;
                background: white;
                box-shadow: 0 0 4px rgba(0,0,0,0.5);
            "></div>
        `;
        
        document.body.appendChild(crosshair);
        return crosshair;
    }
    
    /**
     * Auto-detect doors in the scene by name pattern
     */
    autoDetectDoors() {
        let doorCount = 0;
        
        this.scene.traverse((object) => {
            if (object.isMesh && object.name && 
                (object.name.includes('LR_DOOR') || 
                 object.name.includes('DOOR') || 
                 object.name.toLowerCase().includes('door'))) {
                this.registerDoor(object);
                doorCount++;
            }
        });
        
        console.log(`🔍 Auto-detected ${doorCount} doors in scene`);
    }
    
    /**
     * Register a door object for interaction
     * @param {THREE.Object3D} doorObject - Door mesh object
     * @param {Object} config - Door configuration
     */
    registerDoor(doorObject, config = {}) {
        const doorId = doorObject.uuid;
        
        // Create interaction component
        const interactionComponent = new InteractionComponent({
            type: 'door',
            name: doorObject.name || 'Door',
            interactionKey: 'KeyF',
            interactionRange: 3.0,
            interactionPrompt: 'Press F to open door',
            animationDuration: 1.2,
            openAngle: 90,
            openDirection: 1,
            axis: 'y',
            sounds: {
                open: 'door_open.mp3',
                close: 'door_close.mp3',
                locked: 'door_locked.mp3'
            },
            ...config
        });
        
        // Store original rotation
        interactionComponent.closedRotation = {
            x: doorObject.rotation.x,
            y: doorObject.rotation.y,
            z: doorObject.rotation.z
        };
        
        // Calculate open rotation
        const openRotationRadians = THREE.MathUtils.degToRad(interactionComponent.openAngle * interactionComponent.openDirection);
        interactionComponent.openRotation = { ...interactionComponent.closedRotation };
        interactionComponent.openRotation[interactionComponent.axis] += openRotationRadians;
        
        // Store door data
        this.doors.set(doorId, {
            object: doorObject,
            component: interactionComponent,
            boundingBox: new THREE.Box3().setFromObject(doorObject),
            originalPosition: doorObject.position.clone(),
            originalRotation: doorObject.rotation.clone()
        });
        
        console.log(`🚪 Registered door: ${interactionComponent.name} (${doorId.substring(0, 8)}...)`);
    }
    
    /**
     * Update system (called every frame)
     * @param {number} deltaTime - Time since last frame
     */
    update(deltaTime) {
        // Update door proximity detection
        this.updateProximityDetection();
        
        // Update door animations
        this.updateAnimations(deltaTime);
        
        // Update UI
        if (this.options.enableUI) {
            this.updateUI();
        }
        
        // Debug logging (only occasionally to avoid spam)
        if (this.options.debugMode && Math.random() < 0.01) { // 1% chance per frame
            this.logDebugInfo();
        }
    }
    
    /**
     * Log debug information about door system
     */
    logDebugInfo() {
        console.log('🔧 Door System Debug:', {
            totalDoors: this.doors.size,
            activeDoor: this.activeDoor ? this.activeDoor.component.name : 'none',
            animatingDoors: this.animatingDoors.size,
            cameraPosition: this.camera ? this.camera.position : 'no camera',
            doorsInRange: Array.from(this.doors.values()).filter(d => d.component.playerInRange).length
        });
    }
    
    /**
     * Update proximity detection using advanced raycasting and distance checks
     */
    updateProximityDetection() {
        if (!this.camera) return;
        
        let closestDoor = null;
        let closestDistance = Infinity;
        
        // Get camera position and direction
        const cameraPosition = this.camera.position.clone();
        const cameraDirection = new THREE.Vector3();
        this.camera.getWorldDirection(cameraDirection);
        
        // Check each door with multiple detection methods
        for (const [doorId, doorData] of this.doors) {
            const { object, component } = doorData;
            
            // Method 1: Direct distance check to door center
            const doorPosition = new THREE.Vector3();
            object.getWorldPosition(doorPosition);
            const directDistance = cameraPosition.distanceTo(doorPosition);
            
            // Method 2: Bounding box distance (more accurate for complex door shapes)
            const boundingBox = new THREE.Box3().setFromObject(object);
            const closestPoint = boundingBox.clampPoint(cameraPosition, new THREE.Vector3());
            const boundingBoxDistance = cameraPosition.distanceTo(closestPoint);
            
            // Method 3: Enhanced distance calculation considering door size
            const doorSize = boundingBox.getSize(new THREE.Vector3());
            const maxDoorDimension = Math.max(doorSize.x, doorSize.y, doorSize.z);
            const adjustedRange = component.interactionRange + (maxDoorDimension * 0.5);
            
            // Use the most accurate distance
            const actualDistance = Math.min(directDistance, boundingBoxDistance);
            
            // Check if door is within interaction range
            if (actualDistance <= adjustedRange) {
                // Method 4: Field of view check (door must be somewhat visible)
                const directionToDoor = new THREE.Vector3().subVectors(doorPosition, cameraPosition).normalize();
                const dotProduct = cameraDirection.dot(directionToDoor);
                const isInFOV = dotProduct > -0.7; // Allow doors in a wider field of view (about 135°)
                
                // Method 5: Height check (player and door should be on similar level)
                const heightDifference = Math.abs(cameraPosition.y - doorPosition.y);
                const isOnSameLevel = heightDifference <= 3.0; // Allow 3 units height difference
                
                // Door is valid if it meets distance, FOV, and height criteria
                if (isInFOV && isOnSameLevel) {
                    if (actualDistance < closestDistance) {
                        closestDistance = actualDistance;
                        closestDoor = doorData;
                    }
                    component.setPlayerInRange(true);
                } else {
                    component.setPlayerInRange(false);
                }
            } else {
                component.setPlayerInRange(false);
            }
        }
        
        // Update active door with smooth transition
        if (closestDoor !== this.activeDoor) {
            this.setActiveDoor(closestDoor);
        }
    }
    
    /**
     * Set the currently active door
     * @param {Object|null} doorData - Door data or null
     */
    setActiveDoor(doorData) {
        // Reset previous active door
        if (this.activeDoor) {
            this.highlightDoor(this.activeDoor, false);
        }
        
        this.activeDoor = doorData;
        
        // Highlight new active door
        if (this.activeDoor) {
            this.highlightDoor(this.activeDoor, true);
        }
    }
    
    /**
     * Highlight door when in range
     * @param {Object} doorData - Door data
     * @param {boolean} highlight - Whether to highlight
     */
    highlightDoor(doorData, highlight) {
        const { object } = doorData;
        
        if (highlight) {
            // Add highlight effect
            object.traverse((child) => {
                if (child.isMesh && child.material) {
                    if (!child.originalEmissive) {
                        child.originalEmissive = child.material.emissive.clone();
                    }
                    child.material.emissive.setHex(0x004400); // Subtle green glow
                }
            });
        } else {
            // Remove highlight effect
            object.traverse((child) => {
                if (child.isMesh && child.material && child.originalEmissive) {
                    child.material.emissive.copy(child.originalEmissive);
                }
            });
        }
    }
    
    /**
     * Interact with a door
     * @param {Object} doorData - Door data
     */
    interactWithDoor(doorData) {
        const { component } = doorData;
        
        if (component.interact()) {
            this.animateDoor(doorData);
        }
    }
    
    /**
     * Animate door opening/closing
     * @param {Object} doorData - Door data
     */
    animateDoor(doorData) {
        const { object, component } = doorData;
        const doorId = object.uuid;
        
        // Cancel existing animation
        if (this.animationTweens.has(doorId)) {
            this.animationTweens.get(doorId).stop();
        }
        
        this.animatingDoors.add(doorId);
        
        // Determine target rotation
        const isOpening = component.state === 'opening';
        const targetRotation = isOpening ? component.openRotation : component.closedRotation;
        
        // Create smooth animation using custom easing
        const startRotation = {
            x: object.rotation.x,
            y: object.rotation.y,
            z: object.rotation.z
        };
        
        const animationData = {
            progress: 0,
            duration: component.animationDuration,
            startTime: performance.now()
        };
        
        // Store animation
        this.animationTweens.set(doorId, {
            doorData,
            animationData,
            startRotation,
            targetRotation,
            isOpening,
            stop: () => {
                this.animatingDoors.delete(doorId);
                this.animationTweens.delete(doorId);
            }
        });
        
        console.log(`🎬 Animating door: ${component.name} (${isOpening ? 'opening' : 'closing'})`);
    }
    
    /**
     * Update door animations
     * @param {number} deltaTime - Time since last frame
     */
    updateAnimations(deltaTime) {
        for (const [doorId, tween] of this.animationTweens) {
            const { doorData, animationData, startRotation, targetRotation, isOpening } = tween;
            const { object, component } = doorData;
            
            // Calculate progress
            const elapsed = (performance.now() - animationData.startTime) / 1000;
            const progress = Math.min(elapsed / animationData.duration, 1);
            
            // Apply easing
            const easedProgress = this.easeInOutCubic(progress);
            
            // Interpolate rotation
            object.rotation.x = this.lerp(startRotation.x, targetRotation.x, easedProgress);
            object.rotation.y = this.lerp(startRotation.y, targetRotation.y, easedProgress);
            object.rotation.z = this.lerp(startRotation.z, targetRotation.z, easedProgress);
            
            component.currentProgress = isOpening ? easedProgress : (1 - easedProgress);
            
            // Check if animation is complete
            if (progress >= 1) {
                // Finalize state
                component.setState(isOpening ? 'open' : 'closed');
                
                // Clean up animation
                tween.stop();
                
                console.log(`✅ Door animation complete: ${component.name}`);
            }
        }
    }
    
    /**
     * Update UI elements
     */
    updateUI() {
        const prompt = this.uiElements.interactionPrompt;
        const crosshair = this.uiElements.crosshair;
        
        if (this.activeDoor && this.activeDoor.component.canInteract()) {
            // Show interaction prompt
            if (prompt) {
                prompt.textContent = this.activeDoor.component.getPrompt();
                prompt.style.opacity = '1';
            }
            
            // Enhance crosshair
            if (crosshair) {
                crosshair.style.transform = 'translate(-50%, -50%) scale(1.2)';
                crosshair.style.filter = 'drop-shadow(0 0 8px #00ff88)';
            }
        } else {
            // Hide interaction prompt
            if (prompt) {
                prompt.style.opacity = '0';
            }
            
            // Reset crosshair
            if (crosshair) {
                crosshair.style.transform = 'translate(-50%, -50%) scale(1)';
                crosshair.style.filter = 'none';
            }
        }
    }
    
    /**
     * Cubic easing function
     * @param {number} t - Progress (0-1)
     * @returns {number} Eased progress
     */
    easeInOutCubic(t) {
        return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
    }
    
    /**
     * Linear interpolation
     * @param {number} a - Start value
     * @param {number} b - End value
     * @param {number} t - Progress (0-1)
     * @returns {number} Interpolated value
     */
    lerp(a, b, t) {
        return a + (b - a) * t;
    }
    
    /**
     * Get door by object
     * @param {THREE.Object3D} object - Door object
     * @returns {Object|null} Door data
     */
    getDoorByObject(object) {
        return this.doors.get(object.uuid) || null;
    }
    
    /**
     * Get all doors
     * @returns {Map} All doors
     */
    getAllDoors() {
        return new Map(this.doors);
    }
    
    /**
     * Remove door from system
     * @param {THREE.Object3D} doorObject - Door object to remove
     */
    removeDoor(doorObject) {
        const doorId = doorObject.uuid;
        
        if (this.doors.has(doorId)) {
            // Stop any active animation
            if (this.animationTweens.has(doorId)) {
                this.animationTweens.get(doorId).stop();
            }
            
            // Remove from active door if needed
            if (this.activeDoor && this.activeDoor.object.uuid === doorId) {
                this.setActiveDoor(null);
            }
            
            this.doors.delete(doorId);
            console.log(`🗑️ Removed door: ${doorObject.name}`);
        }
    }
    
    /**
     * Get system statistics
     * @returns {Object} System statistics
     */
    getStatistics() {
        return {
            totalDoors: this.doors.size,
            animatingDoors: this.animatingDoors.size,
            activeDoor: this.activeDoor ? this.activeDoor.component.name : null,
            interactionRange: this.options.maxInteractionDistance
        };
    }
    
    /**
     * Test door proximity for debugging
     * @param {string} doorName - Name of door to test
     * @returns {Object} Debug information
     */
    testDoorProximity(doorName) {
        if (!this.camera) return { error: 'No camera available' };
        
        const cameraPosition = this.camera.position.clone();
        const cameraDirection = new THREE.Vector3();
        this.camera.getWorldDirection(cameraDirection);
        
        for (const [doorId, doorData] of this.doors) {
            const { object, component } = doorData;
            
            if (object.name === doorName || component.name === doorName) {
                const doorPosition = new THREE.Vector3();
                object.getWorldPosition(doorPosition);
                const distance = cameraPosition.distanceTo(doorPosition);
                
                const directionToDoor = new THREE.Vector3().subVectors(doorPosition, cameraPosition).normalize();
                const dotProduct = cameraDirection.dot(directionToDoor);
                
                const boundingBox = new THREE.Box3().setFromObject(object);
                const closestPoint = boundingBox.clampPoint(cameraPosition, new THREE.Vector3());
                const boundingBoxDistance = cameraPosition.distanceTo(closestPoint);
                
                return {
                    doorName: object.name,
                    distance: distance.toFixed(2),
                    boundingBoxDistance: boundingBoxDistance.toFixed(2),
                    interactionRange: component.interactionRange,
                    inRange: distance <= component.interactionRange,
                    dotProduct: dotProduct.toFixed(3),
                    inFOV: dotProduct > -0.7,
                    cameraPosition: cameraPosition,
                    doorPosition: doorPosition,
                    heightDifference: Math.abs(cameraPosition.y - doorPosition.y).toFixed(2),
                    playerInRange: component.playerInRange,
                    isActive: this.activeDoor === doorData
                };
            }
        }
        
        return { error: `Door "${doorName}" not found` };
    }
    
    /**
     * Get all doors with their current status
     * @returns {Array} Array of door status objects
     */
    getAllDoorStatus() {
        if (!this.camera) return [];
        
        const cameraPosition = this.camera.position.clone();
        const results = [];
        
        for (const [doorId, doorData] of this.doors) {
            const { object, component } = doorData;
            const doorPosition = new THREE.Vector3();
            object.getWorldPosition(doorPosition);
            const distance = cameraPosition.distanceTo(doorPosition);
            
            results.push({
                name: object.name,
                distance: distance.toFixed(2),
                inRange: distance <= component.interactionRange,
                playerInRange: component.playerInRange,
                state: component.state,
                isActive: this.activeDoor === doorData
            });
        }
        
        return results.sort((a, b) => parseFloat(a.distance) - parseFloat(b.distance));
    }
    
    /**
     * Dispose of system resources
     */
    dispose() {
        // Stop all animations
        for (const tween of this.animationTweens.values()) {
            tween.stop();
        }
        this.animationTweens.clear();
        
        // Remove input callbacks
        for (const [event, callback] of this.inputCallbacks) {
            this.inputSystem.off(event, callback);
        }
        this.inputCallbacks.clear();
        
        // Remove UI elements
        if (this.uiElements.interactionPrompt) {
            this.uiElements.interactionPrompt.remove();
        }
        if (this.uiElements.crosshair) {
            this.uiElements.crosshair.remove();
        }
        
        // Clear doors
        this.doors.clear();
        this.animatingDoors.clear();
        this.activeDoor = null;
        
        console.log('🗑️ DoorInteractionSystem disposed');
    }
}