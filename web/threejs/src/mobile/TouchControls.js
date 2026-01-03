/**
 * Touch Controls
 * Handles mobile touch input and translates it to 3D camera/movement controls
 */

import * as THREE from 'three';

export class TouchControls {
    constructor(camera, domElement, mobileBridge) {
        this.camera = camera;
        this.domElement = domElement || document.body;
        this.mobileBridge = mobileBridge;
        
        // Control state
        this.enabled = true;
        this.isFirstPerson = false;
        
        // Movement settings
        this.movementSpeed = 5.0;
        this.runMultiplier = 2.0;
        this.jumpHeight = 3.0;
        this.gravity = -9.81;
        
        // Camera settings
        this.lookSpeed = 0.005;
        this.verticalMin = -Math.PI / 2;
        this.verticalMax = Math.PI / 2;
        
        // Current state
        this.velocity = new THREE.Vector3();
        this.isOnGround = true;
        this.isRunning = false;
        this.isJumping = false;
        
        // Camera rotation
        this.euler = new THREE.Euler(0, 0, 0, 'YXZ');
        this.pitchObject = new THREE.Object3D();
        this.yawObject = new THREE.Object3D();
        
        // Input state
        this.keys = {
            forward: false,
            backward: false,
            left: false,
            right: false,
            jump: false,
            run: false
        };
        
        // Mobile input
        this.mobileInput = {
            movement: { x: 0, y: 0 },
            camera: { x: 0, y: 0 },
            gyroscope: { x: 0, y: 0, z: 0 }
        };
        
        // Collision detection
        this.raycaster = new THREE.Raycaster();
        this.collisionObjects = [];
        
        this.init();
    }
    
    init() {
        console.log('🎮 Initializing Touch Controls...');
        
        // Setup camera hierarchy
        this.setupCameraHierarchy();
        
        // Setup mobile bridge listeners
        this.setupMobileBridgeListeners();
        
        // Setup keyboard listeners (for desktop fallback)
        this.setupKeyboardListeners();
        
        // Setup touch listeners
        this.setupTouchListeners();
        
        console.log('✅ Touch Controls initialized');
    }
    
    setupCameraHierarchy() {
        // Create camera hierarchy for first-person controls
        this.yawObject.add(this.pitchObject);
        this.pitchObject.add(this.camera);
        
        // Set initial camera position
        this.camera.position.set(0, 0, 0);
        this.yawObject.position.set(0, 1.6, 0); // Eye height
    }
    
    setupMobileBridgeListeners() {
        if (!this.mobileBridge) return;
        
        // Listen for mobile input events
        this.mobileBridge.on('movementInput', (input) => {
            this.updateMovementInput(input.x, input.y);
        });
        
        this.mobileBridge.on('cameraInput', (input) => {
            this.updateCameraInput(input.x, input.y);
        });
        
        this.mobileBridge.on('gyroscopeInput', (input) => {
            this.updateGyroscopeInput(input.x, input.y, input.z);
        });
        
        this.mobileBridge.on('jump', () => {
            this.jump();
        });
        
        this.mobileBridge.on('interact', () => {
            this.interact();
        });
        
        this.mobileBridge.on('menu', () => {
            this.toggleMenu();
        });
    }
    
    setupKeyboardListeners() {
        document.addEventListener('keydown', (event) => {
            if (!this.enabled || !this.isFirstPerson) return;
            
            switch (event.code) {
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
                case 'Space':
                    this.keys.jump = true;
                    event.preventDefault();
                    break;
                case 'ShiftLeft':
                case 'ShiftRight':
                    this.keys.run = true;
                    break;
            }
        });
        
        document.addEventListener('keyup', (event) => {
            if (!this.enabled || !this.isFirstPerson) return;
            
            switch (event.code) {
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
                case 'Space':
                    this.keys.jump = false;
                    break;
                case 'ShiftLeft':
                case 'ShiftRight':
                    this.keys.run = false;
                    break;
            }
        });
    }
    
    setupTouchListeners() {
        // Handle touch events for entering first-person mode
        this.domElement.addEventListener('touchstart', (event) => {
            if (!this.enabled) return;
            
            // Enter first-person mode on touch
            if (!this.isFirstPerson) {
                this.enterFirstPersonMode();
            }
        });
        
        // Prevent context menu on long press
        this.domElement.addEventListener('contextmenu', (event) => {
            event.preventDefault();
        });
    }
    
    updateMovementInput(x, y) {
        this.mobileInput.movement.x = x;
        this.mobileInput.movement.y = y;
        
        // Convert joystick input to key states
        this.keys.forward = y > 0.1;
        this.keys.backward = y < -0.1;
        this.keys.left = x < -0.1;
        this.keys.right = x > 0.1;
        
        // Determine if running based on input magnitude
        const magnitude = Math.sqrt(x * x + y * y);
        this.keys.run = magnitude > 0.8;
    }
    
    updateCameraInput(x, y) {
        if (!this.isFirstPerson) return;
        
        this.mobileInput.camera.x = x;
        this.mobileInput.camera.y = y;
        
        // Apply camera rotation
        this.euler.setFromQuaternion(this.camera.quaternion);
        
        this.euler.y -= x * this.lookSpeed;
        this.euler.x -= y * this.lookSpeed;
        
        this.euler.x = Math.max(this.verticalMin, Math.min(this.verticalMax, this.euler.x));
        
        this.camera.quaternion.setFromEuler(this.euler);
    }
    
    updateGyroscopeInput(x, y, z) {
        if (!this.isFirstPerson) return;
        
        this.mobileInput.gyroscope.x = x;
        this.mobileInput.gyroscope.y = y;
        this.mobileInput.gyroscope.z = z;
        
        // Apply gyroscope rotation (additive to joystick input)
        this.euler.setFromQuaternion(this.camera.quaternion);
        
        this.euler.y -= y * 0.01; // Yaw
        this.euler.x -= x * 0.01; // Pitch
        
        this.euler.x = Math.max(this.verticalMin, Math.min(this.verticalMax, this.euler.x));
        
        this.camera.quaternion.setFromEuler(this.euler);
    }
    
    jump() {
        if (!this.enabled || !this.isFirstPerson || !this.isOnGround) return;
        
        this.velocity.y = Math.sqrt(2 * -this.gravity * this.jumpHeight);
        this.isOnGround = false;
        this.isJumping = true;
        
        console.log('🦘 Jump!');
    }
    
    interact() {
        if (!this.enabled || !this.isFirstPerson) return;
        
        // Perform raycast to find interactable objects
        this.raycaster.setFromCamera(new THREE.Vector2(0, 0), this.camera);
        const intersects = this.raycaster.intersectObjects(this.collisionObjects, true);
        
        if (intersects.length > 0) {
            const object = intersects[0].object;
            console.log('🤝 Interact with:', object.name || 'unnamed object');
            
            // Emit interaction event
            if (this.mobileBridge) {
                this.mobileBridge.flutterBridge.sendMessage('object_interaction', {
                    objectName: object.name,
                    position: intersects[0].point,
                    distance: intersects[0].distance
                });
            }
        }
    }
    
    toggleMenu() {
        console.log('📱 Toggle menu');
        
        if (this.mobileBridge) {
            this.mobileBridge.flutterBridge.sendMessage('menu_toggle', {
                timestamp: Date.now()
            });
        }
    }
    
    enterFirstPersonMode() {
        this.isFirstPerson = true;
        console.log('👁️ Entered first-person mode');
        
        // Lock pointer on desktop
        if (!this.isMobile()) {
            this.domElement.requestPointerLock();
        }
        
        // Notify Flutter
        if (this.mobileBridge) {
            this.mobileBridge.flutterBridge.sendMessage('first_person_entered', {
                timestamp: Date.now()
            });
        }
    }
    
    exitFirstPersonMode() {
        this.isFirstPerson = false;
        console.log('👁️ Exited first-person mode');
        
        // Exit pointer lock
        if (document.pointerLockElement) {
            document.exitPointerLock();
        }
        
        // Reset velocity
        this.velocity.set(0, 0, 0);
        
        // Notify Flutter
        if (this.mobileBridge) {
            this.mobileBridge.flutterBridge.sendMessage('first_person_exited', {
                timestamp: Date.now()
            });
        }
    }
    
    update(delta) {
        if (!this.enabled || !this.isFirstPerson) return;
        
        // Update movement
        this.updateMovement(delta);
        
        // Update physics
        this.updatePhysics(delta);
        
        // Update collision detection
        this.updateCollisions();
    }
    
    updateMovement(delta) {
        const moveSpeed = this.movementSpeed * (this.keys.run ? this.runMultiplier : 1.0);
        
        // Get movement direction from camera
        const direction = new THREE.Vector3();
        this.camera.getWorldDirection(direction);
        direction.y = 0; // Keep movement horizontal
        direction.normalize();
        
        const right = new THREE.Vector3();
        right.crossVectors(direction, new THREE.Vector3(0, 1, 0));
        
        // Calculate movement vector
        const movement = new THREE.Vector3();
        
        if (this.keys.forward) movement.add(direction);
        if (this.keys.backward) movement.sub(direction);
        if (this.keys.right) movement.add(right);
        if (this.keys.left) movement.sub(right);
        
        // Apply mobile joystick input
        if (this.mobileInput.movement.x !== 0 || this.mobileInput.movement.y !== 0) {
            const joystickMovement = new THREE.Vector3();
            joystickMovement.add(direction.clone().multiplyScalar(this.mobileInput.movement.y));
            joystickMovement.add(right.clone().multiplyScalar(this.mobileInput.movement.x));
            
            movement.add(joystickMovement);
        }
        
        movement.normalize();
        movement.multiplyScalar(moveSpeed * delta);
        
        // Apply movement to velocity
        this.velocity.x = movement.x;
        this.velocity.z = movement.z;
    }
    
    updatePhysics(delta) {
        // Apply gravity
        if (!this.isOnGround) {
            this.velocity.y += this.gravity * delta;
        }
        
        // Apply velocity to position
        this.yawObject.position.add(this.velocity.clone().multiplyScalar(delta));
        
        // Ground check
        if (this.yawObject.position.y <= 1.6) {
            this.yawObject.position.y = 1.6;
            this.velocity.y = 0;
            this.isOnGround = true;
            this.isJumping = false;
        }
    }
    
    updateCollisions() {
        // Simple collision detection with scene objects
        // This would be expanded based on the specific scene setup
        
        // Check for walls/obstacles
        const directions = [
            new THREE.Vector3(1, 0, 0),   // Right
            new THREE.Vector3(-1, 0, 0),  // Left
            new THREE.Vector3(0, 0, 1),   // Forward
            new THREE.Vector3(0, 0, -1)   // Backward
        ];
        
        directions.forEach(direction => {
            this.raycaster.set(this.yawObject.position, direction);
            const intersects = this.raycaster.intersectObjects(this.collisionObjects, true);
            
            if (intersects.length > 0 && intersects[0].distance < 0.5) {
                // Push back from collision
                const pushBack = direction.clone().multiplyScalar(-0.1);
                this.yawObject.position.add(pushBack);
            }
        });
    }
    
    // Utility methods
    isMobile() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    }
    
    setCollisionObjects(objects) {
        this.collisionObjects = objects;
    }
    
    getPosition() {
        return this.yawObject.position.clone();
    }
    
    setPosition(x, y, z) {
        this.yawObject.position.set(x, y, z);
    }
    
    getDirection() {
        const direction = new THREE.Vector3();
        this.camera.getWorldDirection(direction);
        return direction;
    }
    
    // Public API
    enable() {
        this.enabled = true;
    }
    
    disable() {
        this.enabled = false;
        this.exitFirstPersonMode();
    }
    
    dispose() {
        console.log('🧹 Disposing Touch Controls...');
        
        this.disable();
        
        // Remove event listeners
        document.removeEventListener('keydown', this.handleKeyDown);
        document.removeEventListener('keyup', this.handleKeyUp);
        
        console.log('✅ Touch Controls disposed');
    }
}