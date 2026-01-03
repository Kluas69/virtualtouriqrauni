/**
 * Room Manager
 * Handles dynamic room loading and management
 */

import * as THREE from 'three';
import { EventEmitter } from '../utils/EventEmitter.js';

export class RoomManager extends EventEmitter {
    constructor(engine, modelLoader) {
        super();
        
        this.engine = engine;
        this.modelLoader = modelLoader;
        
        // Room state
        this.currentRoom = null;
        this.loadedRooms = new Map();
        this.roomConfigs = new Map();
        
        // Room loading state
        this.isLoading = false;
        this.loadingProgress = 0;
        
        this.init();
    }
    
    init() {
        console.log('🏠 Initializing Room Manager...');
        
        // Load room configurations
        this.loadRoomConfigurations();
        
        console.log('✅ Room Manager initialized');
    }
    
    loadRoomConfigurations() {
        // Room configurations with actual model paths
        const defaultRooms = {
            classroom: {
                id: 'classroom',
                name: 'Virtual Classroom',
                modelUrl: '/assets/models/classroom.glb', // Served from public directory
                description: 'Interactive 3D classroom environment',
                hotspots: [
                    {
                        id: 'whiteboard',
                        position: { x: 0, y: 1.5, z: -3 },
                        title: 'Interactive Whiteboard',
                        description: 'Smart board for presentations and lessons',
                        action: 'showInfo'
                    },
                    {
                        id: 'teacher_desk',
                        position: { x: -2, y: 0.8, z: -2 },
                        title: 'Teacher\'s Desk',
                        description: 'Main teaching station with computer access',
                        action: 'showInfo'
                    },
                    {
                        id: 'student_area',
                        position: { x: 1, y: 0.8, z: 1 },
                        title: 'Student Seating',
                        description: 'Collaborative learning space for students',
                        action: 'showInfo'
                    }
                ],
                lighting: {
                    ambient: { color: 0x404040, intensity: 0.4 },
                    directional: { 
                        color: 0xffffff, 
                        intensity: 0.8,
                        position: { x: 10, y: 10, z: 5 }
                    }
                },
                camera: {
                    startPosition: { x: 0, y: 1.6, z: 5 },
                    lookAt: { x: 0, y: 1, z: 0 }
                },
                settings: {
                    enableShadows: true,
                    enableFog: false,
                    maxMemoryMB: 80
                }
            },
            library: {
                id: 'library',
                name: 'University Library',
                modelUrl: 'https://threejs.org/examples/models/gltf/Soldier.glb', // Placeholder
                description: 'Modern digital library with study areas',
                hotspots: [
                    {
                        id: 'reading_area',
                        position: { x: -3, y: 0.8, z: 2 },
                        title: 'Reading Area',
                        description: 'Quiet study space with comfortable seating',
                        action: 'showInfo'
                    },
                    {
                        id: 'computer_lab',
                        position: { x: 3, y: 0.8, z: -1 },
                        title: 'Computer Lab',
                        description: 'Digital resources and research stations',
                        action: 'showInfo'
                    }
                ],
                lighting: {
                    ambient: { color: 0x505050, intensity: 0.5 },
                    directional: { 
                        color: 0xffffff, 
                        intensity: 0.7,
                        position: { x: 5, y: 15, z: 10 }
                    }
                },
                camera: {
                    startPosition: { x: 0, y: 1.6, z: 8 },
                    lookAt: { x: 0, y: 1, z: 0 }
                },
                settings: {
                    enableShadows: true,
                    enableFog: true,
                    maxMemoryMB: 100
                }
            },
            lab: {
                id: 'lab',
                name: 'Science Laboratory',
                modelUrl: 'https://threejs.org/examples/models/gltf/RobotExpressive/RobotExpressive.glb', // Placeholder
                description: 'Modern science lab with equipment',
                hotspots: [
                    {
                        id: 'experiment_station',
                        position: { x: 2, y: 0.9, z: 0 },
                        title: 'Experiment Station',
                        description: 'Hands-on learning with lab equipment',
                        action: 'showInfo'
                    },
                    {
                        id: 'safety_station',
                        position: { x: -2, y: 1.2, z: -2 },
                        title: 'Safety Equipment',
                        description: 'Emergency shower and safety protocols',
                        action: 'showInfo'
                    }
                ],
                lighting: {
                    ambient: { color: 0x404040, intensity: 0.3 },
                    directional: { 
                        color: 0xffffff, 
                        intensity: 0.9,
                        position: { x: 0, y: 10, z: 0 }
                    }
                },
                camera: {
                    startPosition: { x: 0, y: 1.6, z: 6 },
                    lookAt: { x: 0, y: 1, z: 0 }
                },
                settings: {
                    enableShadows: true,
                    enableFog: false,
                    maxMemoryMB: 90
                }
            }
        };
        
        // Store configurations
        Object.values(defaultRooms).forEach(room => {
            this.roomConfigs.set(room.id, room);
        });
        
        console.log(`📋 Loaded ${this.roomConfigs.size} room configurations`);
    }
    
    async loadRoom(roomId) {
        if (this.isLoading) {
            throw new Error('Another room is currently loading');
        }
        
        const config = this.roomConfigs.get(roomId);
        if (!config) {
            throw new Error(`Room configuration not found: ${roomId}`);
        }
        
        console.log(`🏠 Loading room: ${config.name}`);
        
        this.isLoading = true;
        this.loadingProgress = 0;
        
        this.emit('roomLoadStart', { 
            roomId, 
            roomName: config.name,
            config 
        });
        
        try {
            // Check if room is already loaded
            if (this.loadedRooms.has(roomId)) {
                console.log(`💾 Room loaded from cache: ${roomId}`);
                await this.switchToRoom(roomId);
                return;
            }
            
            // Load the 3D model
            this.loadingProgress = 10;
            this.emit('loadingProgress', { roomId, progress: this.loadingProgress });
            
            const model = await this.modelLoader.loadModel(config.modelUrl, {
                enableCache: true,
                optimize: true
            });
            
            this.loadingProgress = 60;
            this.emit('loadingProgress', { roomId, progress: this.loadingProgress });
            
            // Setup room environment
            const roomData = await this.setupRoomEnvironment(config, model);
            
            this.loadingProgress = 90;
            this.emit('loadingProgress', { roomId, progress: this.loadingProgress });
            
            // Store loaded room
            this.loadedRooms.set(roomId, roomData);
            
            // Switch to the new room
            await this.switchToRoom(roomId);
            
            this.loadingProgress = 100;
            this.emit('loadingProgress', { roomId, progress: this.loadingProgress });
            
            console.log(`✅ Room loaded successfully: ${config.name}`);
            
        } catch (error) {
            console.error(`❌ Failed to load room: ${roomId}`, error);
            this.emit('roomLoadError', { roomId, error: error.message });
            throw error;
        } finally {
            this.isLoading = false;
            this.emit('roomLoadComplete', { roomId });
        }
    }
    
    async setupRoomEnvironment(config, model) {
        console.log(`🎨 Setting up environment for: ${config.name}`);
        
        const roomData = {
            id: config.id,
            name: config.name,
            model: model,
            hotspots: [],
            lighting: null,
            config: config
        };
        
        // Add model to scene
        this.engine.scene.addModel(model);
        
        // Setup lighting
        if (config.lighting) {
            roomData.lighting = this.engine.scene.setupLighting(config.lighting);
        }
        
        // Create hotspots
        if (config.hotspots) {
            roomData.hotspots = this.createHotspots(config.hotspots);
            roomData.hotspots.forEach(hotspot => {
                this.engine.scene.addHotspot(hotspot);
            });
        }
        
        // Apply room settings
        if (config.settings) {
            this.applyRoomSettings(config.settings);
        }
        
        return roomData;
    }
    
    createHotspots(hotspotsConfig) {
        return hotspotsConfig.map(hotspotConfig => {
            const hotspot = {
                id: hotspotConfig.id,
                position: hotspotConfig.position,
                title: hotspotConfig.title,
                description: hotspotConfig.description,
                action: hotspotConfig.action,
                mesh: this.createHotspotMesh(hotspotConfig.position),
                isVisible: true,
                isInteractive: true
            };
            
            // Setup interaction
            hotspot.mesh.userData = {
                type: 'hotspot',
                id: hotspot.id,
                data: hotspot
            };
            
            return hotspot;
        });
    }
    
    createHotspotMesh(position) {
        // Create a simple sphere mesh for hotspot visualization
        const geometry = new THREE.SphereGeometry(0.1, 16, 16);
        const material = new THREE.MeshBasicMaterial({
            color: 0x00ff00,
            transparent: true,
            opacity: 0.7
        });
        
        const mesh = new THREE.Mesh(geometry, material);
        mesh.position.set(position.x, position.y, position.z);
        
        // Add pulsing animation
        const originalScale = mesh.scale.clone();
        mesh.userData.animate = (time) => {
            const scale = 1 + Math.sin(time * 0.005) * 0.2;
            mesh.scale.copy(originalScale).multiplyScalar(scale);
        };
        
        return mesh;
    }
    
    applyRoomSettings(settings) {
        if (settings.enableShadows !== undefined) {
            this.engine.renderer.shadowMap.enabled = settings.enableShadows;
        }
        
        if (settings.enableFog && this.engine.scene) {
            this.engine.scene.fog = new THREE.Fog(0xcccccc, 10, 50);
        }
        
        if (settings.maxMemoryMB) {
            // Notify engine about memory constraints
            this.engine.emit('memoryConstraint', { maxMB: settings.maxMemoryMB });
        }
    }
    
    async switchToRoom(roomId) {
        const roomData = this.loadedRooms.get(roomId);
        if (!roomData) {
            throw new Error(`Room not loaded: ${roomId}`);
        }
        
        console.log(`🔄 Switching to room: ${roomData.name}`);
        
        // Clear current room from scene
        if (this.currentRoom) {
            this.clearCurrentRoom();
        }
        
        // Add new room to scene
        this.engine.scene.addModel(roomData.model);
        
        // Add hotspots
        roomData.hotspots.forEach(hotspot => {
            this.engine.scene.addHotspot(hotspot);
        });
        
        // Setup camera position
        if (roomData.config.camera) {
            const camera = roomData.config.camera;
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
        
        this.currentRoom = roomData;
        
        this.emit('roomChanged', {
            roomId: roomData.id,
            roomName: roomData.name,
            config: roomData.config
        });
        
        console.log(`✅ Switched to room: ${roomData.name}`);
    }
    
    clearCurrentRoom() {
        if (!this.currentRoom) return;
        
        console.log(`🧹 Clearing current room: ${this.currentRoom.name}`);
        
        // Remove model from scene
        this.engine.scene.removeModel(this.currentRoom.model);
        
        // Remove hotspots
        this.currentRoom.hotspots.forEach(hotspot => {
            this.engine.scene.removeHotspot(hotspot);
        });
        
        // Clear fog
        if (this.engine.scene.fog) {
            this.engine.scene.fog = null;
        }
    }
    
    // Public API
    getRoomList() {
        return Array.from(this.roomConfigs.values()).map(config => ({
            id: config.id,
            name: config.name,
            description: config.description,
            isLoaded: this.loadedRooms.has(config.id)
        }));
    }
    
    getCurrentRoom() {
        return this.currentRoom ? {
            id: this.currentRoom.id,
            name: this.currentRoom.name,
            config: this.currentRoom.config
        } : null;
    }
    
    isRoomLoaded(roomId) {
        return this.loadedRooms.has(roomId);
    }
    
    unloadRoom(roomId) {
        if (this.currentRoom && this.currentRoom.id === roomId) {
            this.clearCurrentRoom();
            this.currentRoom = null;
        }
        
        const roomData = this.loadedRooms.get(roomId);
        if (roomData) {
            // Dispose of room resources
            this.disposeRoomData(roomData);
            this.loadedRooms.delete(roomId);
            
            console.log(`🗑️ Unloaded room: ${roomData.name}`);
            this.emit('roomUnloaded', { roomId });
        }
    }
    
    disposeRoomData(roomData) {
        // Dispose model
        if (roomData.model) {
            roomData.model.traverse((child) => {
                if (child.geometry) child.geometry.dispose();
                if (child.material) {
                    if (Array.isArray(child.material)) {
                        child.material.forEach(mat => mat.dispose());
                    } else {
                        child.material.dispose();
                    }
                }
            });
        }
        
        // Dispose hotspots
        roomData.hotspots.forEach(hotspot => {
            if (hotspot.mesh) {
                if (hotspot.mesh.geometry) hotspot.mesh.geometry.dispose();
                if (hotspot.mesh.material) hotspot.mesh.material.dispose();
            }
        });
    }
    
    dispose() {
        console.log('🧹 Disposing Room Manager...');
        
        // Clear current room
        if (this.currentRoom) {
            this.clearCurrentRoom();
        }
        
        // Dispose all loaded rooms
        this.loadedRooms.forEach((roomData, roomId) => {
            this.disposeRoomData(roomData);
        });
        
        this.loadedRooms.clear();
        this.roomConfigs.clear();
        this.currentRoom = null;
        
        this.removeAllListeners();
        console.log('✅ Room Manager disposed');
    }
}