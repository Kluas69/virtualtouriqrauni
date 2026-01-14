/**
 * Door Proximity System Demo
 * Demonstrates professional game-like door interaction
 */

import * as THREE from 'three';
import { DoorInteractionSystem } from '../systems/DoorInteractionSystem.js';

export class DoorProximityDemo {
    constructor() {
        this.scene = null;
        this.camera = null;
        this.doorSystem = null;
        this.testDoors = [];
    }

    /**
     * Initialize the demo
     */
    async initialize(scene, camera, inputSystem, gameEngine) {
        this.scene = scene;
        this.camera = camera;

        // Create door interaction system with professional settings
        this.doorSystem = new DoorInteractionSystem({
            maxInteractionDistance: 2.5,  // Realistic game range
            fovAngle: 60,                 // Standard game FOV
            heightTolerance: 1.5,         // Same floor only
            strictProximity: true,        // Enable line-of-sight
            enableUI: true,               // Show prompts
            debugMode: true               // Enable for testing
        });

        // Initialize with game engine
        await this.doorSystem.initialize(gameEngine);

        // Create test doors
        this.createTestDoors();

        console.log('✅ Door Proximity Demo initialized');
        console.log('📋 Use WASD to move, Mouse to look, F to interact');
        console.log('🎮 Professional game-like proximity detection active');
    }

    /**
     * Create test doors for demonstration
     */
    createTestDoors() {
        // Door 1: Standard door at origin
        const door1 = this.createDoorMesh('DOOR_001', new THREE.Vector3(0, 0, -5));
        this.doorSystem.registerDoor(door1, {
            interactionRange: 2.0,
            interactionPrompt: 'Press F to open Main Door',
            openAngle: 90
        });

        // Door 2: Wide door to the right
        const door2 = this.createDoorMesh('DOOR_002', new THREE.Vector3(5, 0, -5));
        this.doorSystem.registerDoor(door2, {
            interactionRange: 2.5,
            interactionPrompt: 'Press F to open Wide Door',
            openAngle: 120
        });

        // Door 3: Small door to the left
        const door3 = this.createDoorMesh('DOOR_003', new THREE.Vector3(-5, 0, -5));
        this.doorSystem.registerDoor(door3, {
            interactionRange: 1.5,
            interactionPrompt: 'Press F to open Small Door',
            openAngle: 75
        });

        // Door 4: Door on different level (should not interact from ground)
        const door4 = this.createDoorMesh('DOOR_004', new THREE.Vector3(0, 3, -5));
        this.doorSystem.registerDoor(door4, {
            interactionRange: 2.0,
            interactionPrompt: 'Press F to open Upper Door'
        });

        console.log(`🚪 Created ${this.testDoors.length} test doors`);
    }

    /**
     * Create a door mesh for testing
     */
    createDoorMesh(name, position) {
        const doorGroup = new THREE.Group();
        doorGroup.name = name;
        doorGroup.position.copy(position);

        // Door frame
        const frameGeometry = new THREE.BoxGeometry(2.2, 2.5, 0.2);
        const frameMaterial = new THREE.MeshStandardMaterial({
            color: 0x8B4513,
            roughness: 0.8,
            metalness: 0.2
        });
        const frame = new THREE.Mesh(frameGeometry, frameMaterial);
        doorGroup.add(frame);

        // Door panel (the part that opens)
        const panelGeometry = new THREE.BoxGeometry(1.8, 2.2, 0.15);
        const panelMaterial = new THREE.MeshStandardMaterial({
            color: 0xA0522D,
            roughness: 0.6,
            metalness: 0.1
        });
        const panel = new THREE.Mesh(panelGeometry, panelMaterial);
        panel.position.set(0, 0, 0.05);
        doorGroup.add(panel);

        // Door handle
        const handleGeometry = new THREE.CylinderGeometry(0.05, 0.05, 0.3, 8);
        const handleMaterial = new THREE.MeshStandardMaterial({
            color: 0xFFD700,
            roughness: 0.3,
            metalness: 0.8
        });
        const handle = new THREE.Mesh(handleGeometry, handleMaterial);
        handle.rotation.z = Math.PI / 2;
        handle.position.set(0.7, 0, 0.15);
        doorGroup.add(handle);

        // Add to scene
        this.scene.add(doorGroup);
        this.testDoors.push(doorGroup);

        return doorGroup;
    }

    /**
     * Update demo (called every frame)
     */
    update(deltaTime) {
        if (this.doorSystem) {
            this.doorSystem.update(deltaTime);
        }
    }

    /**
     * Test proximity detection
     */
    testProximity() {
        console.log('\n🔍 Testing Door Proximity Detection:');
        console.log('=====================================');

        const allStatus = this.doorSystem.getAllDoorStatus();
        allStatus.forEach(door => {
            console.log(`\n🚪 ${door.name}:`);
            console.log(`   Distance: ${door.distance}m`);
            console.log(`   In Range: ${door.inRange ? '✅' : '❌'}`);
            console.log(`   Active: ${door.isActive ? '✅ HIGHLIGHTED' : '⚪'}`);
            console.log(`   State: ${door.state}`);
        });

        console.log('\n=====================================\n');
    }

    /**
     * Demonstrate different proximity configurations
     */
    demonstrateConfigurations() {
        console.log('\n🎮 Proximity Configuration Examples:');
        console.log('====================================');

        // Configuration 1: Strict game-like (default)
        console.log('\n1️⃣ Strict Game-Like (Recommended):');
        this.doorSystem.configureProximity({
            maxInteractionDistance: 2.5,
            fovAngle: 60,
            heightTolerance: 1.5,
            strictProximity: true
        });

        // Configuration 2: Forgiving (easier for players)
        console.log('\n2️⃣ Forgiving Mode:');
        this.doorSystem.configureProximity({
            maxInteractionDistance: 3.5,
            fovAngle: 90,
            heightTolerance: 2.5,
            strictProximity: false
        });

        // Configuration 3: Realistic (very strict)
        console.log('\n3️⃣ Realistic Mode:');
        this.doorSystem.configureProximity({
            maxInteractionDistance: 2.0,
            fovAngle: 45,
            heightTolerance: 1.0,
            strictProximity: true
        });

        // Configuration 4: Performance (for large scenes)
        console.log('\n4️⃣ Performance Mode:');
        this.doorSystem.configureProximity({
            maxInteractionDistance: 2.5,
            fovAngle: 60,
            heightTolerance: 1.5,
            strictProximity: false  // Disable raycasting
        });

        console.log('\n====================================\n');

        // Reset to default
        this.doorSystem.configureProximity({
            maxInteractionDistance: 2.5,
            fovAngle: 60,
            heightTolerance: 1.5,
            strictProximity: true
        });
    }

    /**
     * Get statistics
     */
    getStats() {
        const stats = this.doorSystem.getStatistics();
        console.log('\n📊 Door System Statistics:');
        console.log('==========================');
        console.log(`Total Doors: ${stats.totalDoors}`);
        console.log(`Animating: ${stats.animatingDoors}`);
        console.log(`Active Door: ${stats.activeDoor || 'None'}`);
        console.log(`Interaction Range: ${stats.interactionRange}m`);
        console.log('==========================\n');
        return stats;
    }

    /**
     * Dispose of demo resources
     */
    dispose() {
        // Remove test doors
        this.testDoors.forEach(door => {
            this.scene.remove(door);
            door.traverse(child => {
                if (child.geometry) child.geometry.dispose();
                if (child.material) child.material.dispose();
            });
        });
        this.testDoors = [];

        // Dispose door system
        if (this.doorSystem) {
            this.doorSystem.dispose();
        }

        console.log('🗑️ Door Proximity Demo disposed');
    }
}

// Export for use in other modules
export default DoorProximityDemo;

// Console commands for testing (attach to window for easy access)
if (typeof window !== 'undefined') {
    window.DoorProximityDemo = DoorProximityDemo;
    
    // Helper functions for console testing
    window.testDoorProximity = () => {
        if (window.doorDemo) {
            window.doorDemo.testProximity();
        } else {
            console.log('❌ Demo not initialized. Create instance first.');
        }
    };

    window.showDoorConfigs = () => {
        if (window.doorDemo) {
            window.doorDemo.demonstrateConfigurations();
        } else {
            console.log('❌ Demo not initialized. Create instance first.');
        }
    };

    window.doorStats = () => {
        if (window.doorDemo) {
            return window.doorDemo.getStats();
        } else {
            console.log('❌ Demo not initialized. Create instance first.');
        }
    };

    console.log('🎮 Door Proximity Demo loaded!');
    console.log('📋 Console commands available:');
    console.log('   - testDoorProximity() - Test current proximity detection');
    console.log('   - showDoorConfigs() - Show configuration examples');
    console.log('   - doorStats() - Show system statistics');
}
