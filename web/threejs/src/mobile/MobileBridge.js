/**
 * Mobile Bridge
 * Handles mobile-specific communication between Flutter and Three.js
 * Extends FlutterBridge with mobile gaming controls
 */

import { EventEmitter } from '../utils/EventEmitter.js';

export class MobileBridge extends EventEmitter {
    constructor(engine, roomManager, flutterBridge) {
        super();
        
        this.engine = engine;
        this.roomManager = roomManager;
        this.flutterBridge = flutterBridge;
        
        // Mobile control state
        this.isEnabled = false;
        this.movementInput = { x: 0, y: 0 };
        this.cameraInput = { x: 0, y: 0 };
        this.gyroscopeInput = { x: 0, y: 0, z: 0 };
        this.isGyroscopeEnabled = false;
        
        // Control settings
        this.settings = {
            movementSensitivity: 1.0,
            cameraSensitivity: 1.0,
            gyroscopeSensitivity: 0.5,
            deadZone: 0.1,
            smoothing: 0.8
        };
        
        // Smoothing buffers
        this.movementBuffer = [];
        this.cameraBuffer = [];
        this.gyroscopeBuffer = [];
        this.bufferSize = 5;
        
        this.init();
    }
    
    init() {
        console.log('📱 Initializing Mobile Bridge...');
        
        // Setup mobile message handlers
        this.setupMobileMessageHandlers();
        
        // Setup update loop
        this.setupUpdateLoop();
        
        console.log('✅ Mobile Bridge initialized');
    }
    
    setupMobileMessageHandlers() {
        // Listen for mobile control messages from Flutter
        this.flutterBridge.on('unknownMessage', (data) => {
            this.handleMobileMessage(data);
        });
        
        // Override Flutter bridge message processing for mobile messages
        const originalProcessMessage = this.flutterBridge.processFlutterMessage.bind(this.flutterBridge);
        this.flutterBridge.processFlutterMessage = (data) => {
            // Check if it's a mobile message first
            if (this.isMobileMessage(data.type)) {
                this.handleMobileMessage(data);
            } else {
                // Pass to original handler
                originalProcessMessage(data);
            }
        };
    }
    
    isMobileMessage(type) {
        const mobileMessageTypes = [
            'joystick_movement',
            'joystick_camera',
            'gyroscope_rotation',
            'mobile_action',
            'mobile_settings',
            'haptic_feedback_request'
        ];
        
        return mobileMessageTypes.includes(type);
    }
    
    handleMobileMessage(data) {
        const { type, payload } = data;
        
        console.log('📱 Processing mobile message:', type);
        
        switch (type) {
            case 'joystick_movement':
                this.handleMovementInput(payload);
                break;
                
            case 'joystick_camera':
                this.handleCameraInput(payload);
                break;
                
            case 'gyroscope_rotation':
                this.handleGyroscopeInput(payload);
                break;
                
            case 'mobile_action':
                this.handleMobileAction(payload);
                break;
                
            case 'mobile_settings':
                this.handleMobileSettings(payload);
                break;
                
            case 'haptic_feedback_request':
                this.handleHapticFeedbackRequest(payload);
                break;
                
            default:
                console.log(`🤷 Unknown mobile message type: ${type}`);
        }
    }
    
    handleMovementInput(payload) {
        const { x, y } = payload;
        
        // Apply dead zone
        const magnitude = Math.sqrt(x * x + y * y);
        if (magnitude < this.settings.deadZone) {
            this.movementInput = { x: 0, y: 0 };
        } else {
            // Scale to remove dead zone effect
            const scale = (magnitude - this.settings.deadZone) / (1.0 - this.settings.deadZone);
            const normalizedX = (x / magnitude) * scale;
            const normalizedY = (y / magnitude) * scale;
            
            this.movementInput = {
                x: normalizedX * this.settings.movementSensitivity,
                y: normalizedY * this.settings.movementSensitivity
            };
        }
        
        // Add to smoothing buffer
        this.addToBuffer(this.movementBuffer, this.movementInput);
        
        // Emit movement event
        this.emit('movementInput', this.getSmoothedInput(this.movementBuffer));
    }
    
    handleCameraInput(payload) {
        const { x, y } = payload;
        
        // Apply dead zone
        const magnitude = Math.sqrt(x * x + y * y);
        if (magnitude < this.settings.deadZone) {
            this.cameraInput = { x: 0, y: 0 };
        } else {
            // Scale to remove dead zone effect
            const scale = (magnitude - this.settings.deadZone) / (1.0 - this.settings.deadZone);
            const normalizedX = (x / magnitude) * scale;
            const normalizedY = (y / magnitude) * scale;
            
            this.cameraInput = {
                x: normalizedX * this.settings.cameraSensitivity,
                y: normalizedY * this.settings.cameraSensitivity
            };
        }
        
        // Add to smoothing buffer
        this.addToBuffer(this.cameraBuffer, this.cameraInput);
        
        // Emit camera event
        this.emit('cameraInput', this.getSmoothedInput(this.cameraBuffer));
    }
    
    handleGyroscopeInput(payload) {
        if (!this.isGyroscopeEnabled) return;
        
        const { x, y, z } = payload;
        
        this.gyroscopeInput = {
            x: x * this.settings.gyroscopeSensitivity,
            y: y * this.settings.gyroscopeSensitivity,
            z: z * this.settings.gyroscopeSensitivity
        };
        
        // Add to smoothing buffer
        this.addToBuffer(this.gyroscopeBuffer, this.gyroscopeInput);
        
        // Emit gyroscope event
        this.emit('gyroscopeInput', this.getSmoothedInput(this.gyroscopeBuffer));
    }
    
    handleMobileAction(payload) {
        const { action, data } = payload;
        
        console.log(`🎮 Mobile action: ${action}`);
        
        switch (action) {
            case 'jump':
                this.emit('jump');
                this.sendHapticFeedback('medium');
                break;
                
            case 'interact':
                this.emit('interact');
                this.sendHapticFeedback('light');
                break;
                
            case 'menu':
                this.emit('menu');
                break;
                
            case 'gyroscope_toggle':
                this.toggleGyroscope(data?.enabled);
                break;
                
            case 'fullscreen_toggle':
                this.toggleFullscreen(data?.enabled);
                break;
                
            default:
                console.log(`🤷 Unknown mobile action: ${action}`);
        }
    }
    
    handleMobileSettings(payload) {
        const { setting, value } = payload;
        
        console.log(`⚙️ Mobile setting: ${setting} = ${value}`);
        
        switch (setting) {
            case 'movement_sensitivity':
                this.settings.movementSensitivity = Math.max(0.1, Math.min(3.0, value));
                break;
                
            case 'camera_sensitivity':
                this.settings.cameraSensitivity = Math.max(0.1, Math.min(3.0, value));
                break;
                
            case 'gyroscope_sensitivity':
                this.settings.gyroscopeSensitivity = Math.max(0.1, Math.min(2.0, value));
                break;
                
            case 'dead_zone':
                this.settings.deadZone = Math.max(0.0, Math.min(0.5, value));
                break;
                
            case 'smoothing':
                this.settings.smoothing = Math.max(0.0, Math.min(1.0, value));
                break;
                
            default:
                console.log(`🤷 Unknown mobile setting: ${setting}`);
        }
        
        // Send confirmation back to Flutter
        this.flutterBridge.sendMessage('mobile_settings_updated', {
            setting: setting,
            value: this.settings[setting.replace('_', '')]
        });
    }
    
    handleHapticFeedbackRequest(payload) {
        const { type, intensity } = payload;
        
        // Send haptic feedback confirmation back to Flutter
        this.flutterBridge.sendMessage('haptic_feedback_response', {
            type: type,
            intensity: intensity,
            timestamp: Date.now()
        });
    }
    
    toggleGyroscope(enabled) {
        this.isGyroscopeEnabled = enabled !== undefined ? enabled : !this.isGyroscopeEnabled;
        
        console.log(`📱 Gyroscope ${this.isGyroscopeEnabled ? 'enabled' : 'disabled'}`);
        
        // Clear gyroscope buffer when disabled
        if (!this.isGyroscopeEnabled) {
            this.gyroscopeBuffer = [];
            this.gyroscopeInput = { x: 0, y: 0, z: 0 };
        }
        
        // Send status back to Flutter
        this.flutterBridge.sendMessage('gyroscope_status', {
            enabled: this.isGyroscopeEnabled
        });
        
        this.emit('gyroscopeToggle', this.isGyroscopeEnabled);
    }
    
    toggleFullscreen(enabled) {
        // Handle fullscreen toggle
        console.log(`📱 Fullscreen ${enabled ? 'enabled' : 'disabled'}`);
        
        // Send status back to Flutter
        this.flutterBridge.sendMessage('fullscreen_status', {
            enabled: enabled
        });
        
        this.emit('fullscreenToggle', enabled);
    }
    
    sendHapticFeedback(type) {
        this.flutterBridge.sendMessage('haptic_feedback', {
            type: type,
            timestamp: Date.now()
        });
    }
    
    // Smoothing utilities
    addToBuffer(buffer, input) {
        buffer.push(input);
        if (buffer.length > this.bufferSize) {
            buffer.shift();
        }
    }
    
    getSmoothedInput(buffer) {
        if (buffer.length === 0) {
            return { x: 0, y: 0, z: 0 };
        }
        
        // Calculate weighted average with more weight on recent inputs
        let totalWeight = 0;
        let smoothedX = 0;
        let smoothedY = 0;
        let smoothedZ = 0;
        
        for (let i = 0; i < buffer.length; i++) {
            const weight = (i + 1) / buffer.length; // More weight for recent inputs
            const input = buffer[i];
            
            smoothedX += input.x * weight;
            smoothedY += input.y * weight;
            if (input.z !== undefined) {
                smoothedZ += input.z * weight;
            }
            
            totalWeight += weight;
        }
        
        return {
            x: smoothedX / totalWeight,
            y: smoothedY / totalWeight,
            z: smoothedZ / totalWeight
        };
    }
    
    setupUpdateLoop() {
        // Update mobile controls at 60fps
        const updateInterval = 1000 / 60;
        
        setInterval(() => {
            if (this.isEnabled) {
                this.update();
            }
        }, updateInterval);
    }
    
    update() {
        // Send periodic updates to Flutter about performance
        const stats = this.engine.getStats();
        
        // Send performance update every second
        if (Date.now() % 1000 < 16) {
            this.flutterBridge.sendMessage('mobile_performance_update', {
                fps: stats.fps,
                memory: stats.memory,
                drawCalls: stats.drawCalls,
                triangles: stats.triangles,
                timestamp: Date.now()
            });
        }
    }
    
    // Public API
    enable() {
        this.isEnabled = true;
        console.log('📱 Mobile controls enabled');
        
        this.flutterBridge.sendMessage('mobile_controls_enabled', {
            timestamp: Date.now()
        });
    }
    
    disable() {
        this.isEnabled = false;
        
        // Clear all inputs
        this.movementInput = { x: 0, y: 0 };
        this.cameraInput = { x: 0, y: 0 };
        this.gyroscopeInput = { x: 0, y: 0, z: 0 };
        
        // Clear buffers
        this.movementBuffer = [];
        this.cameraBuffer = [];
        this.gyroscopeBuffer = [];
        
        console.log('📱 Mobile controls disabled');
        
        this.flutterBridge.sendMessage('mobile_controls_disabled', {
            timestamp: Date.now()
        });
    }
    
    getCurrentInput() {
        return {
            movement: this.getSmoothedInput(this.movementBuffer),
            camera: this.getSmoothedInput(this.cameraBuffer),
            gyroscope: this.getSmoothedInput(this.gyroscopeBuffer),
            isGyroscopeEnabled: this.isGyroscopeEnabled
        };
    }
    
    getSettings() {
        return { ...this.settings };
    }
    
    updateSettings(newSettings) {
        this.settings = { ...this.settings, ...newSettings };
        
        this.flutterBridge.sendMessage('mobile_settings_updated', {
            settings: this.settings
        });
    }
    
    dispose() {
        console.log('🧹 Disposing Mobile Bridge...');
        
        this.disable();
        this.removeAllListeners();
        
        console.log('✅ Mobile Bridge disposed');
    }
}