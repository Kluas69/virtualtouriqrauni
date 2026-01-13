/**
 * InteractionComponent - ECS component for interactive objects (doors, buttons, etc.)
 * Professional implementation for AAA-quality game interactions
 */

export class InteractionComponent {
    constructor(config = {}) {
        this.type = config.type || 'door'; // door, button, lever, etc.
        this.interactionKey = config.interactionKey || 'KeyF';
        this.interactionRange = config.interactionRange || 3.0;
        this.interactionPrompt = config.interactionPrompt || 'Press F to interact';
        
        // State management
        this.state = config.initialState || 'closed'; // closed, opening, open, closing
        this.isInteractable = true;
        this.isPlayerInRange = false;
        
        // Animation configuration
        this.animationDuration = config.animationDuration || 1.0; // seconds
        this.animationEasing = config.animationEasing || 'easeInOutCubic';
        
        // Door-specific properties
        if (this.type === 'door') {
            this.openAngle = config.openAngle || 90; // degrees
            this.openDirection = config.openDirection || 1; // 1 or -1
            this.axis = config.axis || 'y'; // rotation axis
            this.closedRotation = { x: 0, y: 0, z: 0 };
            this.openRotation = { x: 0, y: 0, z: 0 };
            this.currentProgress = 0; // 0 to 1
        }
        
        // Audio configuration
        this.sounds = {
            open: config.sounds?.open || null,
            close: config.sounds?.close || null,
            locked: config.sounds?.locked || null
        };
        
        // Callbacks
        this.onInteract = config.onInteract || null;
        this.onStateChange = config.onStateChange || null;
        
        // Metadata
        this.name = config.name || 'Interactable';
        this.description = config.description || '';
        this.locked = config.locked || false;
        
        console.log(`✅ InteractionComponent created: ${this.name} (${this.type})`);
    }
    
    /**
     * Check if component can be interacted with
     * @returns {boolean} Whether interaction is possible
     */
    canInteract() {
        return this.isInteractable && 
               this.isPlayerInRange && 
               !this.locked &&
               (this.state === 'closed' || this.state === 'open');
    }
    
    /**
     * Trigger interaction
     * @returns {boolean} Whether interaction was successful
     */
    interact() {
        if (!this.canInteract()) {
            if (this.locked && this.sounds.locked) {
                // Play locked sound
                console.log(`🔒 ${this.name} is locked`);
            }
            return false;
        }
        
        // Toggle state
        if (this.state === 'closed') {
            this.open();
        } else if (this.state === 'open') {
            this.close();
        }
        
        // Trigger callback
        if (this.onInteract) {
            this.onInteract(this);
        }
        
        return true;
    }
    
    /**
     * Open the door
     */
    open() {
        if (this.state !== 'closed') return;
        
        this.setState('opening');
        console.log(`🚪 Opening ${this.name}`);
        
        // Play open sound
        if (this.sounds.open) {
            // Sound will be played by DoorInteractionSystem
        }
    }
    
    /**
     * Close the door
     */
    close() {
        if (this.state !== 'open') return;
        
        this.setState('closing');
        console.log(`🚪 Closing ${this.name}`);
        
        // Play close sound
        if (this.sounds.close) {
            // Sound will be played by DoorInteractionSystem
        }
    }
    
    /**
     * Set component state
     * @param {string} newState - New state
     */
    setState(newState) {
        const oldState = this.state;
        this.state = newState;
        
        if (this.onStateChange) {
            this.onStateChange(oldState, newState);
        }
    }
    
    /**
     * Lock/unlock the interactable
     * @param {boolean} locked - Whether to lock
     */
    setLocked(locked) {
        this.locked = locked;
        console.log(`${locked ? '🔒' : '🔓'} ${this.name} ${locked ? 'locked' : 'unlocked'}`);
    }
    
    /**
     * Set player in range status
     * @param {boolean} inRange - Whether player is in range
     */
    setPlayerInRange(inRange) {
        this.isPlayerInRange = inRange;
    }
    
    /**
     * Get interaction prompt text
     * @returns {string} Prompt text
     */
    getPrompt() {
        if (this.locked) {
            return 'Locked';
        }
        return this.interactionPrompt;
    }
    
    /**
     * Clone component
     * @returns {InteractionComponent} Cloned component
     */
    clone() {
        return new InteractionComponent({
            type: this.type,
            interactionKey: this.interactionKey,
            interactionRange: this.interactionRange,
            interactionPrompt: this.interactionPrompt,
            initialState: this.state,
            animationDuration: this.animationDuration,
            animationEasing: this.animationEasing,
            openAngle: this.openAngle,
            openDirection: this.openDirection,
            axis: this.axis,
            sounds: { ...this.sounds },
            name: this.name,
            description: this.description,
            locked: this.locked
        });
    }
}
