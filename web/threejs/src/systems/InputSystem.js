/**
 * InputSystem - Professional input handling with buffering and multi-device support
 * Handles keyboard, mouse, touch, gamepad, and mobile sensor inputs
 */

export class InputSystem {
    constructor(options = {}) {
        this.options = {
            enableKeyboard: true,
            enableMouse: true,
            enableTouch: true,
            enableGamepad: true,
            enableMobile: true,
            bufferSize: 60, // Input buffer for 60 frames
            deadzone: 0.1,
            sensitivity: 1.0,
            enableGestures: true,
            mobilePerformanceOptimizer: null, // Reference to mobile performance optimizer
            ...options
        };
        
        // Input state
        this.keys = new Map();
        this.mouse = {
            position: { x: 0, y: 0 },
            delta: { x: 0, y: 0 },
            buttons: new Map(),
            wheel: 0,
            locked: false
        };
        
        // Touch input
        this.touches = new Map();
        this.gestures = {
            pinch: { active: false, scale: 1.0, lastScale: 1.0 },
            pan: { active: false, delta: { x: 0, y: 0 } },
            rotate: { active: false, angle: 0, lastAngle: 0 }
        };
        
        // Gamepad input
        this.gamepads = new Map();
        this.gamepadDeadzone = this.options.deadzone;
        
        // Mobile sensors
        this.gyroscope = { x: 0, y: 0, z: 0, enabled: false };
        this.accelerometer = { x: 0, y: 0, z: 0, enabled: false };
        
        // Input buffering
        this.inputBuffer = [];
        this.bufferIndex = 0;
        
        // Event listeners
        this.eventListeners = new Map();
        
        // Input callbacks
        this.callbacks = new Map();
        
        console.log('✅ InputSystem initialized with multi-device support');
    }

    /**
     * Initialize input system
     */
    async initialize() {
        // Setup keyboard input
        if (this.options.enableKeyboard) {
            this.setupKeyboard();
        }
        
        // Setup mouse input
        if (this.options.enableMouse) {
            this.setupMouse();
        }
        
        // Setup touch input
        if (this.options.enableTouch) {
            this.setupTouch();
        }
        
        // Setup gamepad input
        if (this.options.enableGamepad) {
            this.setupGamepad();
        }
        
        // Setup mobile sensors
        if (this.options.enableMobile) {
            await this.setupMobileSensors();
        }
        
        // Initialize input buffer
        this.initializeBuffer();
        
        console.log('🎮 InputSystem initialized');
    }

    /**
     * Setup keyboard input handling
     */
    setupKeyboard() {
        const keydownHandler = (event) => {
            this.keys.set(event.code, {
                pressed: true,
                timestamp: performance.now(),
                repeat: event.repeat
            });
            
            this.bufferInput('keyboard', {
                type: 'keydown',
                code: event.code,
                key: event.key,
                timestamp: performance.now()
            });
            
            this.triggerCallback('keydown', event);
        };
        
        const keyupHandler = (event) => {
            this.keys.set(event.code, {
                pressed: false,
                timestamp: performance.now(),
                repeat: false
            });
            
            this.bufferInput('keyboard', {
                type: 'keyup',
                code: event.code,
                key: event.key,
                timestamp: performance.now()
            });
            
            this.triggerCallback('keyup', event);
        };
        
        document.addEventListener('keydown', keydownHandler);
        document.addEventListener('keyup', keyupHandler);
        
        this.eventListeners.set('keydown', keydownHandler);
        this.eventListeners.set('keyup', keyupHandler);
        
        console.log('⌨️ Keyboard input initialized');
    }

    /**
     * Setup mouse input handling
     */
    setupMouse() {
        const mousemoveHandler = (event) => {
            const deltaX = event.movementX || 0;
            const deltaY = event.movementY || 0;
            
            this.mouse.position.x = event.clientX;
            this.mouse.position.y = event.clientY;
            this.mouse.delta.x = deltaX;
            this.mouse.delta.y = deltaY;
            
            this.bufferInput('mouse', {
                type: 'mousemove',
                position: { ...this.mouse.position },
                delta: { x: deltaX, y: deltaY },
                timestamp: performance.now()
            });
            
            this.triggerCallback('mousemove', {
                position: this.mouse.position,
                delta: this.mouse.delta
            });
        };
        
        const mousedownHandler = (event) => {
            this.mouse.buttons.set(event.button, {
                pressed: true,
                timestamp: performance.now()
            });
            
            this.bufferInput('mouse', {
                type: 'mousedown',
                button: event.button,
                position: { ...this.mouse.position },
                timestamp: performance.now()
            });
            
            this.triggerCallback('mousedown', event);
        };
        
        const mouseupHandler = (event) => {
            this.mouse.buttons.set(event.button, {
                pressed: false,
                timestamp: performance.now()
            });
            
            this.bufferInput('mouse', {
                type: 'mouseup',
                button: event.button,
                position: { ...this.mouse.position },
                timestamp: performance.now()
            });
            
            this.triggerCallback('mouseup', event);
        };
        
        const wheelHandler = (event) => {
            this.mouse.wheel = event.deltaY;
            
            this.bufferInput('mouse', {
                type: 'wheel',
                delta: event.deltaY,
                timestamp: performance.now()
            });
            
            this.triggerCallback('wheel', { delta: event.deltaY });
        };
        
        document.addEventListener('mousemove', mousemoveHandler);
        document.addEventListener('mousedown', mousedownHandler);
        document.addEventListener('mouseup', mouseupHandler);
        document.addEventListener('wheel', wheelHandler);
        
        this.eventListeners.set('mousemove', mousemoveHandler);
        this.eventListeners.set('mousedown', mousedownHandler);
        this.eventListeners.set('mouseup', mouseupHandler);
        this.eventListeners.set('wheel', wheelHandler);
        
        console.log('🖱️ Mouse input initialized');
    }

    /**
     * Setup touch input handling
     */
    setupTouch() {
        let throttledTouchStartHandler = null;
        let throttledTouchMoveHandler = null;
        let throttledTouchEndHandler = null;
        
        // Create throttled handlers using mobile performance optimizer if available
        if (this.options.mobilePerformanceOptimizer) {
            const optimizer = this.options.mobilePerformanceOptimizer;
            
            throttledTouchStartHandler = optimizer.throttleTouchEvents((event) => {
                this.handleTouchStart(event);
            });
            
            throttledTouchMoveHandler = optimizer.throttleTouchEvents((event) => {
                this.handleTouchMove(event);
            });
            
            throttledTouchEndHandler = optimizer.throttleTouchEvents((event) => {
                this.handleTouchEnd(event);
            });
            
            console.log('👆 Touch input initialized with mobile performance optimization');
        } else {
            // Fallback to direct handlers
            throttledTouchStartHandler = { handler: (event) => this.handleTouchStart(event) };
            throttledTouchMoveHandler = { handler: (event) => this.handleTouchMove(event) };
            throttledTouchEndHandler = { handler: (event) => this.handleTouchEnd(event) };
            
            console.log('👆 Touch input initialized with fallback handling');
        }
        
        document.addEventListener('touchstart', throttledTouchStartHandler.handler, { passive: false });
        document.addEventListener('touchmove', throttledTouchMoveHandler.handler, { passive: false });
        document.addEventListener('touchend', throttledTouchEndHandler.handler, { passive: false });
        
        this.eventListeners.set('touchstart', throttledTouchStartHandler.handler);
        this.eventListeners.set('touchmove', throttledTouchMoveHandler.handler);
        this.eventListeners.set('touchend', throttledTouchEndHandler.handler);
        
        // Store throttled handlers for cleanup
        this.throttledTouchHandlers = {
            start: throttledTouchStartHandler,
            move: throttledTouchMoveHandler,
            end: throttledTouchEndHandler
        };
    }
    
    /**
     * Handle touch start event
     */
    handleTouchStart(event) {
        event.preventDefault();
        
        for (const touch of event.changedTouches) {
            this.touches.set(touch.identifier, {
                position: { x: touch.clientX, y: touch.clientY },
                startPosition: { x: touch.clientX, y: touch.clientY },
                timestamp: performance.now()
            });
        }
        
        this.updateGestures(event);
        this.triggerCallback('touchstart', event);
    }
    
    /**
     * Handle touch move event
     */
    handleTouchMove(event) {
        event.preventDefault();
        
        for (const touch of event.changedTouches) {
            const existingTouch = this.touches.get(touch.identifier);
            if (existingTouch) {
                const deltaX = touch.clientX - existingTouch.position.x;
                const deltaY = touch.clientY - existingTouch.position.y;
                
                existingTouch.position.x = touch.clientX;
                existingTouch.position.y = touch.clientY;
                existingTouch.delta = { x: deltaX, y: deltaY };
            }
        }
        
        this.updateGestures(event);
        this.triggerCallback('touchmove', event);
    }
    
    /**
     * Handle touch end event
     */
    handleTouchEnd(event) {
        event.preventDefault();
        
        for (const touch of event.changedTouches) {
            this.touches.delete(touch.identifier);
        }
        
        this.updateGestures(event);
        this.triggerCallback('touchend', event);
    }

    /**
     * Setup gamepad input handling
     */
    setupGamepad() {
        const gamepadconnectedHandler = (event) => {
            const gamepad = event.gamepad;
            this.gamepads.set(gamepad.index, {
                id: gamepad.id,
                buttons: new Array(gamepad.buttons.length).fill(false),
                axes: new Array(gamepad.axes.length).fill(0),
                timestamp: performance.now()
            });
            
            console.log(`🎮 Gamepad connected: ${gamepad.id}`);
            this.triggerCallback('gamepadconnected', gamepad);
        };
        
        const gamepaddisconnectedHandler = (event) => {
            this.gamepads.delete(event.gamepad.index);
            console.log(`🎮 Gamepad disconnected: ${event.gamepad.id}`);
            this.triggerCallback('gamepaddisconnected', event.gamepad);
        };
        
        window.addEventListener('gamepadconnected', gamepadconnectedHandler);
        window.addEventListener('gamepaddisconnected', gamepaddisconnectedHandler);
        
        this.eventListeners.set('gamepadconnected', gamepadconnectedHandler);
        this.eventListeners.set('gamepaddisconnected', gamepaddisconnectedHandler);
        
        console.log('🎮 Gamepad input initialized');
    }

    /**
     * Setup mobile sensor input
     */
    async setupMobileSensors() {
        // Request permission for device orientation
        if (typeof DeviceOrientationEvent !== 'undefined' && DeviceOrientationEvent.requestPermission) {
            try {
                const permission = await DeviceOrientationEvent.requestPermission();
                if (permission === 'granted') {
                    this.setupGyroscope();
                }
            } catch (error) {
                console.warn('⚠️ Device orientation permission denied:', error);
            }
        } else if (typeof DeviceOrientationEvent !== 'undefined') {
            this.setupGyroscope();
        }
        
        // Setup accelerometer
        if (typeof DeviceMotionEvent !== 'undefined') {
            this.setupAccelerometer();
        }
        
        console.log('📱 Mobile sensors initialized');
    }

    /**
     * Setup gyroscope input
     */
    setupGyroscope() {
        const orientationHandler = (event) => {
            if (this.gyroscope.enabled) {
                this.gyroscope.x = event.beta || 0;  // X-axis rotation
                this.gyroscope.y = event.gamma || 0; // Y-axis rotation
                this.gyroscope.z = event.alpha || 0; // Z-axis rotation
                
                this.bufferInput('gyroscope', {
                    type: 'orientation',
                    x: this.gyroscope.x,
                    y: this.gyroscope.y,
                    z: this.gyroscope.z,
                    timestamp: performance.now()
                });
                
                this.triggerCallback('gyroscope', this.gyroscope);
            }
        };
        
        window.addEventListener('deviceorientation', orientationHandler);
        this.eventListeners.set('deviceorientation', orientationHandler);
        
        console.log('📱 Gyroscope initialized');
    }

    /**
     * Setup accelerometer input
     */
    setupAccelerometer() {
        const motionHandler = (event) => {
            if (this.accelerometer.enabled && event.accelerationIncludingGravity) {
                this.accelerometer.x = event.accelerationIncludingGravity.x || 0;
                this.accelerometer.y = event.accelerationIncludingGravity.y || 0;
                this.accelerometer.z = event.accelerationIncludingGravity.z || 0;
                
                this.bufferInput('accelerometer', {
                    type: 'motion',
                    x: this.accelerometer.x,
                    y: this.accelerometer.y,
                    z: this.accelerometer.z,
                    timestamp: performance.now()
                });
                
                this.triggerCallback('accelerometer', this.accelerometer);
            }
        };
        
        window.addEventListener('devicemotion', motionHandler);
        this.eventListeners.set('devicemotion', motionHandler);
        
        console.log('📱 Accelerometer initialized');
    }

    /**
     * Initialize input buffer
     */
    initializeBuffer() {
        this.inputBuffer = new Array(this.options.bufferSize);
        for (let i = 0; i < this.options.bufferSize; i++) {
            this.inputBuffer[i] = {
                keyboard: [],
                mouse: [],
                touch: [],
                gamepad: [],
                gyroscope: [],
                accelerometer: []
            };
        }
        
        console.log(`📊 Input buffer initialized (${this.options.bufferSize} frames)`);
    }

    /**
     * Buffer input for frame-perfect input handling
     * @param {string} type - Input type
     * @param {Object} data - Input data
     */
    bufferInput(type, data) {
        const currentFrame = this.inputBuffer[this.bufferIndex];
        if (currentFrame && currentFrame[type]) {
            currentFrame[type].push(data);
        }
    }

    /**
     * Update input system (call every frame)
     * @param {number} delta - Time delta
     */
    update(delta) {
        // Update gamepad state
        this.updateGamepads();
        
        // Clear mouse delta for next frame
        this.mouse.delta.x = 0;
        this.mouse.delta.y = 0;
        this.mouse.wheel = 0;
        
        // Advance buffer
        this.bufferIndex = (this.bufferIndex + 1) % this.options.bufferSize;
        
        // Clear next frame buffer
        const nextFrame = this.inputBuffer[this.bufferIndex];
        if (nextFrame) {
            for (const type in nextFrame) {
                nextFrame[type] = [];
            }
        }
    }

    /**
     * Update gamepad state
     */
    updateGamepads() {
        const gamepads = navigator.getGamepads();
        
        for (let i = 0; i < gamepads.length; i++) {
            const gamepad = gamepads[i];
            if (gamepad && this.gamepads.has(i)) {
                const storedGamepad = this.gamepads.get(i);
                
                // Update buttons
                for (let j = 0; j < gamepad.buttons.length; j++) {
                    const pressed = gamepad.buttons[j].pressed;
                    const wasPressed = storedGamepad.buttons[j];
                    
                    if (pressed !== wasPressed) {
                        storedGamepad.buttons[j] = pressed;
                        
                        this.bufferInput('gamepad', {
                            type: pressed ? 'buttondown' : 'buttonup',
                            gamepadIndex: i,
                            button: j,
                            timestamp: performance.now()
                        });
                        
                        this.triggerCallback(pressed ? 'gamepadButtonDown' : 'gamepadButtonUp', {
                            gamepadIndex: i,
                            button: j
                        });
                    }
                }
                
                // Update axes
                for (let j = 0; j < gamepad.axes.length; j++) {
                    let value = gamepad.axes[j];
                    
                    // Apply deadzone
                    if (Math.abs(value) < this.gamepadDeadzone) {
                        value = 0;
                    }
                    
                    const oldValue = storedGamepad.axes[j];
                    if (Math.abs(value - oldValue) > 0.01) {
                        storedGamepad.axes[j] = value;
                        
                        this.bufferInput('gamepad', {
                            type: 'axis',
                            gamepadIndex: i,
                            axis: j,
                            value: value,
                            timestamp: performance.now()
                        });
                        
                        this.triggerCallback('gamepadAxis', {
                            gamepadIndex: i,
                            axis: j,
                            value: value
                        });
                    }
                }
            }
        }
    }

    /**
     * Update gesture recognition
     * @param {TouchEvent} event - Touch event
     */
    updateGestures(event) {
        if (!this.options.enableGestures) return;
        
        const touches = Array.from(event.touches);
        
        if (touches.length === 2) {
            // Pinch gesture
            const touch1 = touches[0];
            const touch2 = touches[1];
            
            const distance = Math.sqrt(
                Math.pow(touch2.clientX - touch1.clientX, 2) +
                Math.pow(touch2.clientY - touch1.clientY, 2)
            );
            
            if (this.gestures.pinch.active) {
                const scale = distance / this.gestures.pinch.lastDistance;
                this.gestures.pinch.scale = scale;
                
                this.triggerCallback('pinch', {
                    scale: scale,
                    delta: scale - this.gestures.pinch.lastScale
                });
                
                this.gestures.pinch.lastScale = scale;
            } else {
                this.gestures.pinch.active = true;
                this.gestures.pinch.lastDistance = distance;
                this.gestures.pinch.lastScale = 1.0;
            }
        } else {
            this.gestures.pinch.active = false;
        }
        
        // Pan gesture
        if (touches.length === 1) {
            const touch = touches[0];
            const storedTouch = this.touches.get(touch.identifier);
            
            if (storedTouch && storedTouch.delta) {
                this.gestures.pan.active = true;
                this.gestures.pan.delta = storedTouch.delta;
                
                this.triggerCallback('pan', this.gestures.pan.delta);
            }
        } else {
            this.gestures.pan.active = false;
        }
    }

    /**
     * Check if key is currently pressed
     * @param {string} keyCode - Key code to check
     * @returns {boolean} Whether key is pressed
     */
    isKeyPressed(keyCode) {
        const key = this.keys.get(keyCode);
        return key ? key.pressed : false;
    }

    /**
     * Check if mouse button is currently pressed
     * @param {number} button - Mouse button (0=left, 1=middle, 2=right)
     * @returns {boolean} Whether button is pressed
     */
    isMouseButtonPressed(button) {
        const mouseButton = this.mouse.buttons.get(button);
        return mouseButton ? mouseButton.pressed : false;
    }

    /**
     * Get gamepad axis value
     * @param {number} gamepadIndex - Gamepad index
     * @param {number} axis - Axis index
     * @returns {number} Axis value (-1 to 1)
     */
    getGamepadAxis(gamepadIndex, axis) {
        const gamepad = this.gamepads.get(gamepadIndex);
        return gamepad && gamepad.axes[axis] !== undefined ? gamepad.axes[axis] : 0;
    }

    /**
     * Check if gamepad button is pressed
     * @param {number} gamepadIndex - Gamepad index
     * @param {number} button - Button index
     * @returns {boolean} Whether button is pressed
     */
    isGamepadButtonPressed(gamepadIndex, button) {
        const gamepad = this.gamepads.get(gamepadIndex);
        return gamepad && gamepad.buttons[button] !== undefined ? gamepad.buttons[button] : false;
    }

    /**
     * Enable/disable gyroscope
     * @param {boolean} enabled - Whether to enable gyroscope
     */
    setGyroscopeEnabled(enabled) {
        this.gyroscope.enabled = enabled;
        console.log(`📱 Gyroscope ${enabled ? 'enabled' : 'disabled'}`);
    }

    /**
     * Enable/disable accelerometer
     * @param {boolean} enabled - Whether to enable accelerometer
     */
    setAccelerometerEnabled(enabled) {
        this.accelerometer.enabled = enabled;
        console.log(`📱 Accelerometer ${enabled ? 'enabled' : 'disabled'}`);
    }

    /**
     * Set mobile performance optimizer reference
     * @param {MobilePerformanceOptimizer} optimizer - Mobile performance optimizer instance
     */
    setMobilePerformanceOptimizer(optimizer) {
        this.options.mobilePerformanceOptimizer = optimizer;
        console.log('📱 Mobile performance optimizer set for InputSystem');
    }
    
    /**
     * Set input sensitivity
     * @param {number} sensitivity - Sensitivity multiplier
     */
    setSensitivity(sensitivity) {
        this.options.sensitivity = Math.max(0.1, Math.min(5.0, sensitivity));
        console.log(`🎯 Input sensitivity set to: ${this.options.sensitivity}`);
    }

    /**
     * Register input callback
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
     * Unregister input callback
     * @param {string} event - Event type
     * @param {Function} callback - Callback function
     */
    off(event, callback) {
        const callbacks = this.callbacks.get(event);
        if (callbacks) {
            const index = callbacks.indexOf(callback);
            if (index !== -1) {
                callbacks.splice(index, 1);
            }
        }
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
                    console.error(`❌ Input callback error for ${event}:`, error);
                }
            });
        }
    }

    /**
     * Get input statistics
     * @returns {Object} Input statistics
     */
    getStatistics() {
        return {
            activeKeys: Array.from(this.keys.entries()).filter(([, key]) => key.pressed).length,
            activeTouches: this.touches.size,
            connectedGamepads: this.gamepads.size,
            gyroscopeEnabled: this.gyroscope.enabled,
            accelerometerEnabled: this.accelerometer.enabled,
            bufferSize: this.options.bufferSize,
            sensitivity: this.options.sensitivity
        };
    }

    /**
     * Dispose of input system
     */
    dispose() {
        // Remove all event listeners
        for (const [event, handler] of this.eventListeners) {
            if (event.startsWith('gamepad')) {
                window.removeEventListener(event, handler);
            } else if (event.startsWith('device')) {
                window.removeEventListener(event, handler);
            } else {
                document.removeEventListener(event, handler);
            }
        }
        
        // Dispose throttled touch handlers if they exist
        if (this.throttledTouchHandlers) {
            if (this.throttledTouchHandlers.start && this.throttledTouchHandlers.start.dispose) {
                this.throttledTouchHandlers.start.dispose();
            }
            if (this.throttledTouchHandlers.move && this.throttledTouchHandlers.move.dispose) {
                this.throttledTouchHandlers.move.dispose();
            }
            if (this.throttledTouchHandlers.end && this.throttledTouchHandlers.end.dispose) {
                this.throttledTouchHandlers.end.dispose();
            }
        }
        
        // Clear state
        this.keys.clear();
        this.mouse.buttons.clear();
        this.touches.clear();
        this.gamepads.clear();
        this.callbacks.clear();
        this.eventListeners.clear();
        
        console.log('🗑️ InputSystem disposed');
    }
}