/**
 * Professional Camera Controller
 * Handles perspective camera with smooth controls
 */

import * as THREE from 'three';
import { PointerLockControls } from 'three/examples/jsm/controls/PointerLockControls.js';

export class Camera {
    constructor(options = {}) {
        this.options = {
            fov: 75,
            near: 0.1,
            far: 1000,
            position: { x: 0, y: 1.6, z: 5 },
            enableControls: true,
            walkSpeed: 100,
            runSpeed: 200,
            ...options
        };
        
        // Camera and controls
        this.camera = null;
        this.controls = null;
        
        // Movement state
        this.movement = {
            forward: false,
            backward: false,
            left: false,
            right: false,
            running: false
        };
        
        // Movement physics
        this.velocity = new THREE.Vector3();
        this.direction = new THREE.Vector3();
        
        this.init();
    }
    
    init() {
        console.log('📷 Initializing Camera...');
        
        // Create perspective camera
        this.camera = new THREE.PerspectiveCamera(
            this.options.fov,
            window.innerWidth / window.innerHeight,
            this.options.near,
            this.options.far
        );
        
        // Set initial position
        const pos = this.options.position;
        this.camera.position.set(pos.x, pos.y, pos.z);
        
        // Setup controls
        if (this.options.enableControls) {
            this.setupControls();
        }
        
        console.log('✅ Camera initialized');
    }
    
    setupControls() {
        // Create pointer lock controls
        this.controls = new PointerLockControls(this.camera, document.body);
        
        // Setup event listeners
        this.setupEventListeners();
        
        // Click to enable controls
        document.body.addEventListener('click', () => {
            if (!this.controls.isLocked) {
                this.controls.lock();
            }
        });
        
        // Controls events
        this.controls.addEventListener('lock', () => {
            console.log('🔒 Controls locked');
            this.showControlsHint();
        });
        
        this.controls.addEventListener('unlock', () => {
            console.log('🔓 Controls unlocked');
            this.hideControlsHint();
        });
    }
    
    setupEventListeners() {
        // Keyboard events
        document.addEventListener('keydown', this.onKeyDown.bind(this));
        document.addEventListener('keyup', this.onKeyUp.bind(this));
        
        // Touch events for mobile
        if (this.isMobileDevice()) {
            this.setupTouchControls();
        }
    }
    
    setupTouchControls() {
        // Virtual joystick for mobile (simplified)
        const joystick = this.createVirtualJoystick();
        document.body.appendChild(joystick);
    }
    
    createVirtualJoystick() {
        const joystick = document.createElement('div');
        joystick.style.cssText = `
            position: fixed;
            bottom: 20px;
            left: 20px;
            width: 100px;
            height: 100px;
            background: rgba(255, 255, 255, 0.2);
            border: 2px solid rgba(255, 255, 255, 0.5);
            border-radius: 50%;
            display: none;
            z-index: 1000;
        `;
        
        // Show on mobile
        if (this.isMobileDevice()) {
            joystick.style.display = 'block';
        }
        
        return joystick;
    }
    
    onKeyDown(event) {
        switch (event.code) {
            case 'KeyW':
            case 'ArrowUp':
                this.movement.forward = true;
                break;
            case 'KeyS':
            case 'ArrowDown':
                this.movement.backward = true;
                break;
            case 'KeyA':
            case 'ArrowLeft':
                this.movement.left = true;
                break;
            case 'KeyD':
            case 'ArrowRight':
                this.movement.right = true;
                break;
            case 'ShiftLeft':
            case 'ShiftRight':
                this.movement.running = true;
                break;
            case 'Escape':
                if (this.controls && this.controls.isLocked) {
                    this.controls.unlock();
                }
                break;
        }
    }
    
    onKeyUp(event) {
        switch (event.code) {
            case 'KeyW':
            case 'ArrowUp':
                this.movement.forward = false;
                break;
            case 'KeyS':
            case 'ArrowDown':
                this.movement.backward = false;
                break;
            case 'KeyA':
            case 'ArrowLeft':
                this.movement.left = false;
                break;
            case 'KeyD':
            case 'ArrowRight':
                this.movement.right = false;
                break;
            case 'ShiftLeft':
            case 'ShiftRight':
                this.movement.running = false;
                break;
        }
    }
    
    update(delta, time) {
        if (!this.controls || !this.controls.isLocked) return;
        
        // Calculate movement
        const speed = this.movement.running ? this.options.runSpeed : this.options.walkSpeed;
        
        // Apply damping
        this.velocity.x -= this.velocity.x * 10.0 * delta;
        this.velocity.z -= this.velocity.z * 10.0 * delta;
        
        // Calculate direction
        this.direction.z = Number(this.movement.forward) - Number(this.movement.backward);
        this.direction.x = Number(this.movement.right) - Number(this.movement.left);
        this.direction.normalize();
        
        // Apply movement
        if (this.movement.forward || this.movement.backward) {
            this.velocity.z -= this.direction.z * speed * delta;
        }
        if (this.movement.left || this.movement.right) {
            this.velocity.x -= this.direction.x * speed * delta;
        }
        
        // Move camera
        this.controls.moveRight(-this.velocity.x * delta);
        this.controls.moveForward(-this.velocity.z * delta);
        
        // Prevent camera from going below ground
        if (this.camera.position.y < 0.5) {
            this.camera.position.y = 0.5;
        }
    }
    
    showControlsHint() {
        const hint = document.getElementById('controls-hint');
        if (hint) {
            hint.classList.add('visible');
            
            // Auto-hide after 5 seconds
            setTimeout(() => {
                hint.classList.remove('visible');
            }, 5000);
        }
    }
    
    hideControlsHint() {
        const hint = document.getElementById('controls-hint');
        if (hint) {
            hint.classList.remove('visible');
        }
    }
    
    // First-person movement methods (for UIManager compatibility)
    moveForward(distance) {
        if (this.controls && this.controls.isLocked) {
            this.controls.moveForward(distance);
        } else if (this.camera) {
            // Fallback for non-locked mode
            const direction = new THREE.Vector3();
            this.camera.getWorldDirection(direction);
            this.camera.position.addScaledVector(direction, distance);
        }
    }
    
    moveBackward(distance) {
        this.moveForward(-distance);
    }
    
    moveLeft(distance) {
        if (this.controls && this.controls.isLocked) {
            this.controls.moveRight(-distance);
        } else if (this.camera) {
            // Fallback for non-locked mode
            const direction = new THREE.Vector3();
            this.camera.getWorldDirection(direction);
            const right = new THREE.Vector3();
            right.crossVectors(direction, this.camera.up).normalize();
            this.camera.position.addScaledVector(right, -distance);
        }
    }
    
    moveRight(distance) {
        if (this.controls && this.controls.isLocked) {
            this.controls.moveRight(distance);
        } else if (this.camera) {
            // Fallback for non-locked mode
            const direction = new THREE.Vector3();
            this.camera.getWorldDirection(direction);
            const right = new THREE.Vector3();
            right.crossVectors(direction, this.camera.up).normalize();
            this.camera.position.addScaledVector(right, distance);
        }
    }
    
    moveUp(distance) {
        if (this.camera) {
            this.camera.position.y += distance;
        }
    }
    
    moveDown(distance) {
        if (this.camera) {
            this.camera.position.y -= distance;
            // Prevent going below ground
            if (this.camera.position.y < 0.5) {
                this.camera.position.y = 0.5;
            }
        }
    }
    
    rotate(deltaX, deltaY) {
        if (this.controls && this.controls.isLocked) {
            // PointerLockControls handles rotation automatically
            // This method is for manual rotation when not locked
            return;
        }
        
        if (this.camera) {
            // Manual rotation for touch/mobile controls
            this.camera.rotation.y -= deltaX;
            this.camera.rotation.x -= deltaY;
            
            // Clamp vertical rotation
            this.camera.rotation.x = Math.max(
                -Math.PI / 2,
                Math.min(Math.PI / 2, this.camera.rotation.x)
            );
        }
    }

    // Camera positioning
    setPosition(x, y, z) {
        if (this.camera) {
            this.camera.position.set(x, y, z);
        }
    }
    
    lookAt(x, y, z) {
        if (this.camera) {
            this.camera.lookAt(x, y, z);
        }
    }
    
    updateAspect(aspect) {
        if (this.camera) {
            this.camera.aspect = aspect;
            this.camera.updateProjectionMatrix();
        }
    }
    
    // Smooth transitions
    animateToPosition(targetPosition, duration = 2000) {
        return new Promise((resolve) => {
            const startPosition = this.camera.position.clone();
            const startTime = performance.now();
            
            const animate = (currentTime) => {
                const elapsed = currentTime - startTime;
                const progress = Math.min(elapsed / duration, 1);
                
                // Smooth easing
                const eased = this.easeInOutCubic(progress);
                
                this.camera.position.lerpVectors(startPosition, targetPosition, eased);
                
                if (progress < 1) {
                    requestAnimationFrame(animate);
                } else {
                    resolve();
                }
            };
            
            requestAnimationFrame(animate);
        });
    }
    
    easeInOutCubic(t) {
        return t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;
    }
    
    // Utility methods
    isMobileDevice() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    }
    
    getCamera() {
        return this.camera;
    }
    
    getControls() {
        return this.controls;
    }
    
    getPosition() {
        return this.camera ? this.camera.position.clone() : new THREE.Vector3();
    }
    
    getDirection() {
        const direction = new THREE.Vector3();
        if (this.camera) {
            this.camera.getWorldDirection(direction);
        }
        return direction;
    }
    
    dispose() {
        // Remove event listeners
        document.removeEventListener('keydown', this.onKeyDown.bind(this));
        document.removeEventListener('keyup', this.onKeyUp.bind(this));
        
        // Dispose controls
        if (this.controls) {
            this.controls.dispose();
            this.controls = null;
        }
        
        this.camera = null;
    }
}