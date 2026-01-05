/**
 * Camera - Camera setup and management
 */

import * as THREE from 'three';
import { PointerLockControls } from 'three/addons/controls/PointerLockControls.js';

export class Camera {
    constructor(options = {}) {
        this.options = {
            fov: 75,
            near: 0.1,
            far: 1000,
            position: { x: 0, y: 1.6, z: 5 },
            enablePointerLock: true,
            ...options
        };
        
        this.camera = null;
        this.controls = null;
        
        this.setupCamera();
        this.setupControls();
        
        console.log('✅ Camera initialized');
    }

    /**
     * Setup perspective camera
     */
    setupCamera() {
        this.camera = new THREE.PerspectiveCamera(
            this.options.fov,
            window.innerWidth / window.innerHeight,
            this.options.near,
            this.options.far
        );
        
        // Set initial position
        this.camera.position.set(
            this.options.position.x,
            this.options.position.y,
            this.options.position.z
        );
        
        console.log('📷 Perspective camera created');
    }

    /**
     * Setup camera controls
     */
    setupControls() {
        if (this.options.enablePointerLock) {
            this.controls = new PointerLockControls(this.camera, document.body);
            
            // Setup pointer lock events
            this.setupPointerLockEvents();
            
            console.log('🎮 Pointer lock controls enabled');
        }
    }

    /**
     * Setup pointer lock event handlers
     */
    setupPointerLockEvents() {
        if (!this.controls) return;
        
        // Click to enable controls
        const container = document.getElementById('container');
        if (container) {
            container.addEventListener('click', () => {
                if (!this.controls.isLocked) {
                    this.controls.lock();
                }
            });
        }

        // Lock event
        this.controls.addEventListener('lock', () => {
            console.log('🔒 Pointer lock activated');
            this.updateStatus('Player control mode - Use WASD to move, SPACE to jump');
            
            // Emit lock event
            if (window.classroomViewer && window.classroomViewer.onPointerLock) {
                window.classroomViewer.onPointerLock(true);
            }
        });

        // Unlock event
        this.controls.addEventListener('unlock', () => {
            console.log('🔓 Pointer lock deactivated');
            this.updateStatus('Click to enter player control mode');
            
            // Emit unlock event
            if (window.classroomViewer && window.classroomViewer.onPointerLock) {
                window.classroomViewer.onPointerLock(false);
            }
        });
    }

    /**
     * Update status message
     * @param {string} message - Status message
     */
    updateStatus(message) {
        const statusElement = document.getElementById('status');
        if (statusElement) {
            statusElement.textContent = message;
        }
        console.log('📋 Status:', message);
    }

    /**
     * Handle window resize
     * @param {number} width - New width
     * @param {number} height - New height
     */
    onResize(width, height) {
        this.camera.aspect = width / height;
        this.camera.updateProjectionMatrix();
        
        console.log(`📐 Camera aspect ratio updated: ${(width/height).toFixed(2)}`);
    }

    /**
     * Get camera instance
     * @returns {THREE.PerspectiveCamera} Camera instance
     */
    getCamera() {
        return this.camera;
    }

    /**
     * Get controls instance
     * @returns {PointerLockControls} Controls instance
     */
    getControls() {
        return this.controls;
    }

    /**
     * Check if pointer is locked
     * @returns {boolean} Whether pointer is locked
     */
    isLocked() {
        return this.controls ? this.controls.isLocked : false;
    }

    /**
     * Lock pointer
     */
    lock() {
        if (this.controls) {
            this.controls.lock();
        }
    }

    /**
     * Unlock pointer
     */
    unlock() {
        if (this.controls) {
            this.controls.unlock();
        }
    }

    /**
     * Set camera position
     * @param {number} x - X coordinate
     * @param {number} y - Y coordinate
     * @param {number} z - Z coordinate
     */
    setPosition(x, y, z) {
        this.camera.position.set(x, y, z);
    }

    /**
     * Get camera position
     * @returns {THREE.Vector3} Camera position
     */
    getPosition() {
        return this.camera.position.clone();
    }

    /**
     * Set camera rotation
     * @param {number} x - X rotation (radians)
     * @param {number} y - Y rotation (radians)
     * @param {number} z - Z rotation (radians)
     */
    setRotation(x, y, z) {
        this.camera.rotation.set(x, y, z);
    }

    /**
     * Get camera rotation
     * @returns {THREE.Euler} Camera rotation
     */
    getRotation() {
        return this.camera.rotation.clone();
    }

    /**
     * Look at target
     * @param {number} x - Target X coordinate
     * @param {number} y - Target Y coordinate
     * @param {number} z - Target Z coordinate
     */
    lookAt(x, y, z) {
        this.camera.lookAt(x, y, z);
    }

    /**
     * Reset camera to default position
     */
    reset() {
        this.setPosition(
            this.options.position.x,
            this.options.position.y,
            this.options.position.z
        );
        this.lookAt(0, 1, 0);
        
        if (this.controls && this.controls.isLocked) {
            this.controls.unlock();
        }
        
        console.log('📷 Camera reset to default position');
    }

    /**
     * Set field of view
     * @param {number} fov - Field of view in degrees
     */
    setFOV(fov) {
        this.options.fov = fov;
        this.camera.fov = fov;
        this.camera.updateProjectionMatrix();
    }

    /**
     * Get field of view
     * @returns {number} Field of view in degrees
     */
    getFOV() {
        return this.camera.fov;
    }

    /**
     * Set near and far clipping planes
     * @param {number} near - Near clipping plane
     * @param {number} far - Far clipping plane
     */
    setClippingPlanes(near, far) {
        this.options.near = near;
        this.options.far = far;
        this.camera.near = near;
        this.camera.far = far;
        this.camera.updateProjectionMatrix();
    }

    /**
     * Get camera information for debugging
     * @returns {Object} Camera debug info
     */
    getDebugInfo() {
        return {
            position: this.camera.position.clone(),
            rotation: this.camera.rotation.clone(),
            fov: this.camera.fov,
            aspect: this.camera.aspect,
            near: this.camera.near,
            far: this.camera.far,
            isLocked: this.isLocked()
        };
    }

    /**
     * Dispose of resources
     */
    dispose() {
        if (this.controls) {
            this.controls.dispose();
            this.controls = null;
        }
        
        this.camera = null;
        
        console.log('🗑️ Camera disposed');
    }
}