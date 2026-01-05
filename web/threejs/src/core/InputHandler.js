/**
 * InputHandler - Professional input management for 3D games
 * Handles keyboard, mouse, touch, and gamepad inputs with game-level precision
 */

import * as THREE from 'three';

export class InputHandler {
    constructor(options = {}) {
        this.options = {
            enableKeyboard: true,
            enableMouse: true,
            enableTouch: true,
            enableGamepad: false,
            mouseSensitivity: 0.002,
            touchSensitivity: 0.003,
            debugMode: false,
            ...options
        };
        
        // Input state
        this.keys = {
            forward: false,
            backward: false,
            left: false,
            right: false,
            run: false,
            jump: false,
            crouch: false,
            interact: false
        };
        
        this.mouse = {
            x: 0,
            y: 0,
            deltaX: 0,
            deltaY: 0,
            leftButton: false,
            rightButton: false,
            middleButton: false
        };
        
        this.touch = {
            touches: [],
            isActive: false
        };
        
        // Event listeners storage for cleanup
        this.eventListeners = [];
        
        this.setupEventListeners();
        
        console.log('✅ InputHandler initialized with game-level precision');
    }

    /**
     * Setup all input event listeners
     */
    setupEventListeners() {
        if (this.options.enableKeyboard) {
            this.setupKeyboardEvents();
        }
        
        if (this.options.enableMouse) {
            this.setupMouseEvents();
        }
        
        if (this.options.enableTouch) {
            this.setupTouchEvents();
        }
        
        if (this.options.enableGamepad) {
            this.setupGamepadEvents();
        }
    }

    /**
     * Setup keyboard event listeners
     */
    setupKeyboardEvents() {
        const onKeyDown = (event) => this.onKeyDown(event);
        const onKeyUp = (event) => this.onKeyUp(event);
        
        document.addEventListener('keydown', onKeyDown);
        document.addEventListener('keyup', onKeyUp);
        
        this.eventListeners.push(
            { element: document, event: 'keydown', handler: onKeyDown },
            { element: document, event: 'keyup', handler: onKeyUp }
        );
        
        console.log('⌨️ Keyboard events setup');
    }

    /**
     * Setup mouse event listeners
     */
    setupMouseEvents() {
        const onMouseMove = (event) => this.onMouseMove(event);
        const onMouseDown = (event) => this.onMouseDown(event);
        const onMouseUp = (event) => this.onMouseUp(event);
        const onWheel = (event) => this.onWheel(event);
        
        document.addEventListener('mousemove', onMouseMove);
        document.addEventListener('mousedown', onMouseDown);
        document.addEventListener('mouseup', onMouseUp);
        document.addEventListener('wheel', onWheel);
        
        this.eventListeners.push(
            { element: document, event: 'mousemove', handler: onMouseMove },
            { element: document, event: 'mousedown', handler: onMouseDown },
            { element: document, event: 'mouseup', handler: onMouseUp },
            { element: document, event: 'wheel', handler: onWheel }
        );
        
        console.log('🖱️ Mouse events setup');
    }

    /**
     * Setup touch event listeners for mobile
     */
    setupTouchEvents() {
        const onTouchStart = (event) => this.onTouchStart(event);
        const onTouchMove = (event) => this.onTouchMove(event);
        const onTouchEnd = (event) => this.onTouchEnd(event);
        
        document.addEventListener('touchstart', onTouchStart, { passive: false });
        document.addEventListener('touchmove', onTouchMove, { passive: false });
        document.addEventListener('touchend', onTouchEnd, { passive: false });
        
        this.eventListeners.push(
            { element: document, event: 'touchstart', handler: onTouchStart },
            { element: document, event: 'touchmove', handler: onTouchMove },
            { element: document, event: 'touchend', handler: onTouchEnd }
        );
        
        console.log('📱 Touch events setup');
    }

    /**
     * Setup gamepad event listeners
     */
    setupGamepadEvents() {
        const onGamepadConnected = (event) => this.onGamepadConnected(event);
        const onGamepadDisconnected = (event) => this.onGamepadDisconnected(event);
        
        window.addEventListener('gamepadconnected', onGamepadConnected);
        window.addEventListener('gamepaddisconnected', onGamepadDisconnected);
        
        this.eventListeners.push(
            { element: window, event: 'gamepadconnected', handler: onGamepadConnected },
            { element: window, event: 'gamepaddisconnected', handler: onGamepadDisconnected }
        );
        
        console.log('🎮 Gamepad events setup');
    }

    /**
     * Handle keydown events
     * @param {KeyboardEvent} event - Keyboard event
     */
    onKeyDown(event) {
        switch (event.code) {
            // Movement keys
            case 'KeyW':
            case 'ArrowUp':
                this.keys.forward = true;
                break;
            case 'KeyS':
            case 'ArrowDown':
                this.keys.backward = true;
                break;
            case 'KeyA':
            case 'ArrowLeft':
                this.keys.left = true;
                break;
            case 'KeyD':
            case 'ArrowRight':
                this.keys.right = true;
                break;
                
            // Action keys
            case 'ShiftLeft':
            case 'ShiftRight':
                this.keys.run = true;
                break;
            case 'Space':
                this.keys.jump = true;
                event.preventDefault(); // Prevent page scroll
                break;
            case 'ControlLeft':
            case 'ControlRight':
                this.keys.crouch = true;
                break;
            case 'KeyE':
            case 'KeyF':
                this.keys.interact = true;
                break;
                
            // System keys
            case 'Escape':
                this.handleEscapeKey();
                break;
        }
        
        if (this.options.debugMode) {
            console.log('⌨️ Key down:', event.code);
        }
    }

    /**
     * Handle keyup events
     * @param {KeyboardEvent} event - Keyboard event
     */
    onKeyUp(event) {
        switch (event.code) {
            // Movement keys
            case 'KeyW':
            case 'ArrowUp':
                this.keys.forward = false;
                break;
            case 'KeyS':
            case 'ArrowDown':
                this.keys.backward = false;
                break;
            case 'KeyA':
            case 'ArrowLeft':
                this.keys.left = false;
                break;
            case 'KeyD':
            case 'ArrowRight':
                this.keys.right = false;
                break;
                
            // Action keys
            case 'ShiftLeft':
            case 'ShiftRight':
                this.keys.run = false;
                break;
            case 'Space':
                this.keys.jump = false;
                break;
            case 'ControlLeft':
            case 'ControlRight':
                this.keys.crouch = false;
                break;
            case 'KeyE':
            case 'KeyF':
                this.keys.interact = false;
                break;
        }
        
        if (this.options.debugMode) {
            console.log('⌨️ Key up:', event.code);
        }
    }

    /**
     * Handle mouse move events
     * @param {MouseEvent} event - Mouse event
     */
    onMouseMove(event) {
        this.mouse.deltaX = event.movementX || 0;
        this.mouse.deltaY = event.movementY || 0;
        this.mouse.x = event.clientX;
        this.mouse.y = event.clientY;
        
        if (this.options.debugMode && (this.mouse.deltaX !== 0 || this.mouse.deltaY !== 0)) {
            console.log('🖱️ Mouse delta:', { x: this.mouse.deltaX, y: this.mouse.deltaY });
        }
    }

    /**
     * Handle mouse button down events
     * @param {MouseEvent} event - Mouse event
     */
    onMouseDown(event) {
        switch (event.button) {
            case 0: // Left button
                this.mouse.leftButton = true;
                break;
            case 1: // Middle button
                this.mouse.middleButton = true;
                break;
            case 2: // Right button
                this.mouse.rightButton = true;
                break;
        }
        
        if (this.options.debugMode) {
            console.log('🖱️ Mouse down:', event.button);
        }
    }

    /**
     * Handle mouse button up events
     * @param {MouseEvent} event - Mouse event
     */
    onMouseUp(event) {
        switch (event.button) {
            case 0: // Left button
                this.mouse.leftButton = false;
                break;
            case 1: // Middle button
                this.mouse.middleButton = false;
                break;
            case 2: // Right button
                this.mouse.rightButton = false;
                break;
        }
        
        if (this.options.debugMode) {
            console.log('🖱️ Mouse up:', event.button);
        }
    }

    /**
     * Handle mouse wheel events
     * @param {WheelEvent} event - Wheel event
     */
    onWheel(event) {
        // Can be used for zoom, weapon switching, etc.
        if (this.options.debugMode) {
            console.log('🖱️ Mouse wheel:', event.deltaY);
        }
    }

    /**
     * Handle touch start events
     * @param {TouchEvent} event - Touch event
     */
    onTouchStart(event) {
        this.touch.isActive = true;
        this.touch.touches = Array.from(event.touches);
        
        if (this.options.debugMode) {
            console.log('📱 Touch start:', this.touch.touches.length);
        }
    }

    /**
     * Handle touch move events
     * @param {TouchEvent} event - Touch event
     */
    onTouchMove(event) {
        event.preventDefault(); // Prevent scrolling
        
        const newTouches = Array.from(event.touches);
        
        // Calculate touch deltas for camera rotation
        if (this.touch.touches.length > 0 && newTouches.length > 0) {
            const oldTouch = this.touch.touches[0];
            const newTouch = newTouches[0];
            
            this.mouse.deltaX = (newTouch.clientX - oldTouch.clientX) * this.options.touchSensitivity;
            this.mouse.deltaY = (newTouch.clientY - oldTouch.clientY) * this.options.touchSensitivity;
        }
        
        this.touch.touches = newTouches;
        
        if (this.options.debugMode) {
            console.log('📱 Touch move:', { deltaX: this.mouse.deltaX, deltaY: this.mouse.deltaY });
        }
    }

    /**
     * Handle touch end events
     * @param {TouchEvent} event - Touch event
     */
    onTouchEnd(event) {
        this.touch.touches = Array.from(event.touches);
        
        if (this.touch.touches.length === 0) {
            this.touch.isActive = false;
        }
        
        if (this.options.debugMode) {
            console.log('📱 Touch end:', this.touch.touches.length);
        }
    }

    /**
     * Handle gamepad connected
     * @param {GamepadEvent} event - Gamepad event
     */
    onGamepadConnected(event) {
        console.log('🎮 Gamepad connected:', event.gamepad.id);
    }

    /**
     * Handle gamepad disconnected
     * @param {GamepadEvent} event - Gamepad event
     */
    onGamepadDisconnected(event) {
        console.log('🎮 Gamepad disconnected:', event.gamepad.id);
    }

    /**
     * Handle escape key press
     */
    handleEscapeKey() {
        // Unlock pointer controls if locked
        if (window.classroomViewer && window.classroomViewer.camera) {
            const camera = window.classroomViewer.camera;
            if (camera.isLocked && camera.isLocked()) {
                camera.unlock();
            }
        }
        
        if (this.options.debugMode) {
            console.log('⌨️ Escape key pressed - unlocking controls');
        }
    }

    /**
     * Get normalized movement vector based on current input state
     * @returns {THREE.Vector3} Normalized movement vector
     */
    getMovementVector() {
        const movement = new THREE.Vector3();
        
        if (this.keys.forward) movement.z -= 1;
        if (this.keys.backward) movement.z += 1;
        if (this.keys.left) movement.x -= 1;
        if (this.keys.right) movement.x += 1;
        
        return movement.normalize();
    }

    /**
     * Get mouse rotation delta with sensitivity applied
     * @returns {Object} Mouse rotation delta
     */
    getMouseDelta() {
        return {
            x: this.mouse.deltaX * this.options.mouseSensitivity,
            y: this.mouse.deltaY * this.options.mouseSensitivity
        };
    }

    /**
     * Check if running key is pressed
     * @returns {boolean} Whether running
     */
    isRunning() {
        return this.keys.run;
    }

    /**
     * Check if jump key is pressed
     * @returns {boolean} Whether jumping
     */
    isJumping() {
        return this.keys.jump;
    }

    /**
     * Check if crouch key is pressed
     * @returns {boolean} Whether crouching
     */
    isCrouching() {
        return this.keys.crouch;
    }

    /**
     * Check if interact key is pressed
     * @returns {boolean} Whether interacting
     */
    isInteracting() {
        return this.keys.interact;
    }

    /**
     * Check if any mouse button is pressed
     * @returns {boolean} Whether any mouse button is pressed
     */
    isMousePressed() {
        return this.mouse.leftButton || this.mouse.rightButton || this.mouse.middleButton;
    }

    /**
     * Check if touch is active
     * @returns {boolean} Whether touch is active
     */
    isTouchActive() {
        return this.touch.isActive;
    }

    /**
     * Reset mouse deltas (call after processing)
     */
    resetMouseDeltas() {
        this.mouse.deltaX = 0;
        this.mouse.deltaY = 0;
    }

    /**
     * Set mouse sensitivity
     * @param {number} sensitivity - Mouse sensitivity value
     */
    setMouseSensitivity(sensitivity) {
        this.options.mouseSensitivity = sensitivity;
    }

    /**
     * Set touch sensitivity
     * @param {number} sensitivity - Touch sensitivity value
     */
    setTouchSensitivity(sensitivity) {
        this.options.touchSensitivity = sensitivity;
    }

    /**
     * Get current input state for debugging
     * @returns {Object} Current input state
     */
    getInputState() {
        return {
            keys: { ...this.keys },
            mouse: { ...this.mouse },
            touch: { ...this.touch },
            movement: this.getMovementVector(),
            mouseDelta: this.getMouseDelta()
        };
    }

    /**
     * Dispose of all event listeners
     */
    dispose() {
        // Remove all event listeners
        this.eventListeners.forEach(({ element, event, handler }) => {
            element.removeEventListener(event, handler);
        });
        
        this.eventListeners = [];
        
        // Reset state
        this.keys = {};
        this.mouse = {};
        this.touch = {};
        
        console.log('🗑️ InputHandler disposed');
    }
}