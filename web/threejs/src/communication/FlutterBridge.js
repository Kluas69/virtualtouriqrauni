/**
 * Flutter Bridge
 * Handles communication between Three.js and Flutter WebView
 */

import { EventEmitter } from '../utils/EventEmitter.js';

export class FlutterBridge extends EventEmitter {
    constructor(engine, roomManager) {
        super();
        
        this.engine = engine;
        this.roomManager = roomManager;
        
        // Communication state
        this.isConnected = false;
        this.messageQueue = [];
        this.messageId = 0;
        this.pendingCallbacks = new Map();
        
        // Flutter WebView detection
        this.isFlutterWebView = this.detectFlutterWebView();
        
        this.init();
    }
    
    init() {
        console.log('🌉 Initializing Flutter Bridge...');
        
        // Setup message listeners
        this.setupMessageListeners();
        
        // Setup engine event forwarding
        this.setupEngineEventForwarding();
        
        // Setup room manager event forwarding
        this.setupRoomManagerEventForwarding();
        
        // Attempt connection
        this.attemptConnection();
        
        console.log('✅ Flutter Bridge initialized');
    }
    
    detectFlutterWebView() {
        // Check for Flutter WebView indicators
        const userAgent = navigator.userAgent.toLowerCase();
        const isFlutter = userAgent.includes('flutter') || 
                         userAgent.includes('webview') ||
                         window.flutter_inappwebview !== undefined ||
                         window.flutter !== undefined;
        
        console.log(`🔍 Flutter WebView detected: ${isFlutter}`);
        return isFlutter;
    }
    
    setupMessageListeners() {
        // Listen for messages from Flutter
        window.addEventListener('message', this.handleFlutterMessage.bind(this));
        
        // Listen for Flutter WebView specific events
        if (this.isFlutterWebView) {
            // Flutter InAppWebView communication
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler = this.handleFlutterCall.bind(this);
            }
            
            // Custom Flutter communication channel
            if (window.flutter) {
                window.flutter.postMessage = this.handleFlutterMessage.bind(this);
            }
        }
    }
    
    setupEngineEventForwarding() {
        // Forward engine events to Flutter
        this.engine.on('initialized', () => {
            this.sendMessage('engineInitialized', {
                timestamp: Date.now(),
                capabilities: this.engine.getStats()
            });
        });
        
        this.engine.on('performanceWarning', (data) => {
            this.sendMessage('performanceWarning', {
                ...data,
                timestamp: Date.now()
            });
        });
        
        this.engine.on('memoryPressure', (data) => {
            this.sendMessage('memoryPressure', {
                ...data,
                timestamp: Date.now()
            });
        });
        
        this.engine.on('error', (error) => {
            this.sendMessage('engineError', {
                error: error.message || error.toString(),
                timestamp: Date.now()
            });
        });
        
        this.engine.on('frame', (data) => {
            // Send periodic performance updates (throttled)
            if (data.time % 1000 < 16) { // ~1 second intervals
                this.sendMessage('performanceUpdate', {
                    fps: data.fps,
                    timestamp: data.time
                });
            }
        });
    }
    
    setupRoomManagerEventForwarding() {
        this.roomManager.on('roomLoadStart', (data) => {
            this.sendMessage('roomLoadStart', data);
        });
        
        this.roomManager.on('roomLoadComplete', (data) => {
            this.sendMessage('roomLoadComplete', data);
        });
        
        this.roomManager.on('roomChanged', (data) => {
            this.sendMessage('roomChanged', data);
        });
        
        this.roomManager.on('loadingProgress', (data) => {
            this.sendMessage('loadingProgress', data);
        });
        
        this.roomManager.on('roomLoadError', (data) => {
            this.sendMessage('roomLoadError', data);
        });
    }
    
    attemptConnection() {
        console.log('🔌 Attempting Flutter connection...');
        
        // Send connection request
        this.sendMessage('connectionRequest', {
            timestamp: Date.now(),
            userAgent: navigator.userAgent,
            isFlutterWebView: this.isFlutterWebView,
            capabilities: {
                webgl: true,
                threejs: true,
                rooms: this.roomManager.getRoomList()
            }
        });
        
        // Set connection timeout
        setTimeout(() => {
            if (!this.isConnected) {
                console.log('⚠️ Flutter connection timeout - operating in standalone mode');
                this.emit('connectionTimeout');
            }
        }, 5000);
    }
    
    handleFlutterMessage(event) {
        try {
            let data;
            
            // Handle different message formats
            if (typeof event.data === 'string') {
                data = JSON.parse(event.data);
            } else if (typeof event.data === 'object') {
                data = event.data;
            } else {
                return; // Ignore non-JSON messages
            }
            
            // Validate message structure
            if (!data.type) {
                return; // Ignore messages without type
            }
            
            console.log('📨 Received Flutter message:', data.type);
            
            this.processFlutterMessage(data);
            
        } catch (error) {
            console.warn('⚠️ Failed to process Flutter message:', error);
        }
    }
    
    handleFlutterCall(handlerName, ...args) {
        console.log('📞 Flutter call:', handlerName, args);
        
        // Convert Flutter call to message format
        const data = {
            type: 'flutterCall',
            handler: handlerName,
            args: args,
            timestamp: Date.now()
        };
        
        this.processFlutterMessage(data);
    }
    
    processFlutterMessage(data) {
        const { type, payload, messageId } = data;
        
        switch (type) {
            case 'connectionResponse':
                this.handleConnectionResponse(payload);
                break;
                
            case 'loadRoom':
                this.handleLoadRoomRequest(payload, messageId);
                break;
                
            case 'getRoomList':
                this.handleGetRoomListRequest(messageId);
                break;
                
            case 'getCurrentRoom':
                this.handleGetCurrentRoomRequest(messageId);
                break;
                
            case 'setQuality':
                this.handleSetQualityRequest(payload);
                break;
                
            case 'getStats':
                this.handleGetStatsRequest(messageId);
                break;
                
            case 'hotspotClick':
                this.handleHotspotClick(payload);
                break;
                
            case 'cameraPosition':
                this.handleCameraPositionRequest(payload);
                break;
                
            case 'flutterCall':
                this.handleGenericFlutterCall(data);
                break;
                
            default:
                console.log(`🤷 Unknown Flutter message type: ${type}`);
                this.emit('unknownMessage', data);
        }
    }
    
    handleConnectionResponse(payload) {
        this.isConnected = true;
        console.log('✅ Flutter connection established');
        
        // Process queued messages
        this.processMessageQueue();
        
        this.emit('connected', payload);
    }
    
    async handleLoadRoomRequest(payload, messageId) {
        try {
            const { roomId } = payload;
            await this.roomManager.loadRoom(roomId);
            
            this.sendResponse(messageId, {
                success: true,
                roomId: roomId,
                room: this.roomManager.getCurrentRoom()
            });
        } catch (error) {
            this.sendResponse(messageId, {
                success: false,
                error: error.message
            });
        }
    }
    
    handleGetRoomListRequest(messageId) {
        const roomList = this.roomManager.getRoomList();
        this.sendResponse(messageId, {
            success: true,
            rooms: roomList
        });
    }
    
    handleGetCurrentRoomRequest(messageId) {
        const currentRoom = this.roomManager.getCurrentRoom();
        this.sendResponse(messageId, {
            success: true,
            room: currentRoom
        });
    }
    
    handleSetQualityRequest(payload) {
        const { level } = payload;
        this.engine.setQuality(level);
        
        console.log(`🎛️ Quality set to: ${level}`);
    }
    
    handleGetStatsRequest(messageId) {
        const stats = {
            engine: this.engine.getStats(),
            room: this.roomManager.getCurrentRoom(),
            performance: {
                timestamp: Date.now()
            }
        };
        
        this.sendResponse(messageId, {
            success: true,
            stats: stats
        });
    }
    
    handleHotspotClick(payload) {
        const { hotspotId, roomId } = payload;
        
        console.log(`🎯 Hotspot clicked: ${hotspotId} in room: ${roomId}`);
        
        // Emit event for UI manager or other components
        this.emit('hotspotClicked', { hotspotId, roomId });
        
        // Send acknowledgment back to Flutter
        this.sendMessage('hotspotClickResponse', {
            hotspotId,
            roomId,
            timestamp: Date.now()
        });
    }
    
    handleCameraPositionRequest(payload) {
        const { position, lookAt } = payload;
        
        if (position) {
            this.engine.camera.setPosition(position.x, position.y, position.z);
        }
        
        if (lookAt) {
            this.engine.camera.lookAt(lookAt.x, lookAt.y, lookAt.z);
        }
        
        console.log('📷 Camera position updated from Flutter');
    }
    
    handleGenericFlutterCall(data) {
        const { handler, args } = data;
        
        // Handle generic Flutter calls
        switch (handler) {
            case 'pauseRendering':
                this.engine.pause();
                break;
                
            case 'resumeRendering':
                this.engine.resume();
                break;
                
            case 'resetCamera':
                this.resetCameraToDefault();
                break;
                
            case 'enableVR':
                this.enableVRMode();
                break;
                
            default:
                console.log(`🤷 Unknown Flutter call: ${handler}`);
        }
    }
    
    resetCameraToDefault() {
        const currentRoom = this.roomManager.getCurrentRoom();
        if (currentRoom && currentRoom.config.camera) {
            const camera = currentRoom.config.camera;
            this.engine.camera.setPosition(
                camera.startPosition.x,
                camera.startPosition.y,
                camera.startPosition.z
            );
            
            if (camera.lookAt) {
                this.engine.camera.lookAt(
                    camera.lookAt.x,
                    camera.lookAt.y,
                    camera.lookAt.z
                );
            }
        }
    }
    
    enableVRMode() {
        // VR mode implementation would go here
        console.log('🥽 VR mode requested (not implemented)');
        
        this.sendMessage('vrModeResponse', {
            success: false,
            error: 'VR mode not implemented'
        });
    }
    
    // Public API
    sendMessage(type, payload = {}) {
        const message = {
            type: type,
            payload: payload,
            timestamp: Date.now(),
            source: 'threejs'
        };
        
        if (this.isConnected) {
            this.postMessageToFlutter(message);
        } else {
            // Queue message for later
            this.messageQueue.push(message);
        }
    }
    
    sendResponse(messageId, payload) {
        if (!messageId) return;
        
        const response = {
            type: 'response',
            messageId: messageId,
            payload: payload,
            timestamp: Date.now(),
            source: 'threejs'
        };
        
        this.postMessageToFlutter(response);
    }
    
    postMessageToFlutter(message) {
        try {
            console.log('📤 Attempting to send message to Flutter:', message.type, message);
            
            if (this.isFlutterWebView) {
                // Flutter WebView specific posting
                if (window.flutter_inappwebview && window.flutter_inappwebview.postMessage) {
                    console.log('📤 Using flutter_inappwebview.postMessage');
                    window.flutter_inappwebview.postMessage(JSON.stringify(message));
                } else if (window.flutter && window.flutter.postMessage) {
                    console.log('📤 Using window.flutter.postMessage');
                    window.flutter.postMessage(JSON.stringify(message));
                } else {
                    // Fallback to standard postMessage
                    console.log('📤 Using fallback window.parent.postMessage');
                    window.parent.postMessage(message, '*');
                }
            } else {
                // Standard iframe communication
                console.log('📤 Using standard window.parent.postMessage');
                window.parent.postMessage(message, '*');
            }
            
            console.log('✅ Message sent to Flutter successfully:', message.type);
        } catch (error) {
            console.error('❌ Failed to send message to Flutter:', error);
            console.error('Message details:', message);
        }
    }
    
    processMessageQueue() {
        console.log(`📬 Processing ${this.messageQueue.length} queued messages`);
        
        while (this.messageQueue.length > 0) {
            const message = this.messageQueue.shift();
            this.postMessageToFlutter(message);
        }
    }
    
    // Utility methods
    requestFromFlutter(type, payload = {}) {
        return new Promise((resolve, reject) => {
            const messageId = ++this.messageId;
            
            // Store callback
            this.pendingCallbacks.set(messageId, { resolve, reject });
            
            // Send request
            const message = {
                type: type,
                payload: payload,
                messageId: messageId,
                timestamp: Date.now(),
                source: 'threejs'
            };
            
            this.postMessageToFlutter(message);
            
            // Timeout after 10 seconds
            setTimeout(() => {
                if (this.pendingCallbacks.has(messageId)) {
                    this.pendingCallbacks.delete(messageId);
                    reject(new Error(`Flutter request timeout: ${type}`));
                }
            }, 10000);
        });
    }
    
    dispose() {
        console.log('🧹 Disposing Flutter Bridge...');
        
        // Clear message queue
        this.messageQueue.length = 0;
        
        // Clear pending callbacks
        this.pendingCallbacks.clear();
        
        // Remove event listeners
        window.removeEventListener('message', this.handleFlutterMessage.bind(this));
        
        this.isConnected = false;
        
        this.removeAllListeners();
        console.log('✅ Flutter Bridge disposed');
    }
}