/**
 * GameLoop - Professional game loop with fixed timestep physics
 * Implements industry-standard game timing with interpolation
 */

export class GameLoop {
    constructor(options = {}) {
        this.options = {
            targetFPS: 60,
            physicsHz: 120,
            maxFrameTime: 250, // Prevent spiral of death (ms)
            ...options
        };
        
        // Timing calculations
        this.fixedTimeStep = 1000 / this.options.physicsHz; // Physics timestep in ms
        this.maxFrameTime = this.options.maxFrameTime;
        
        // Loop state
        this.accumulator = 0;
        this.currentTime = 0;
        this.lastTime = 0;
        this.running = false;
        this.animationId = null;
        
        // Callbacks
        this.onUpdate = null; // Fixed timestep update callback
        this.onRender = null; // Interpolated render callback
        
        // Performance tracking
        this.frameCount = 0;
        this.lastFPSUpdate = 0;
        this.currentFPS = 0;
        
        console.log('⏱️ Professional GameLoop initialized');
        console.log(`   🔸 Target FPS: ${this.options.targetFPS}`);
        console.log(`   🔸 Physics Hz: ${this.options.physicsHz}`);
        console.log(`   🔸 Fixed timestep: ${this.fixedTimeStep.toFixed(2)}ms`);
    }
    
    /**
     * Start the game loop
     */
    start() {
        if (this.running) {
            console.warn('⚠️ GameLoop already running');
            return;
        }
        
        this.running = true;
        this.currentTime = performance.now();
        this.lastTime = this.currentTime;
        this.accumulator = 0;
        
        this.loop();
        
        console.log('▶️ Professional GameLoop started');
    }
    
    /**
     * Stop the game loop
     */
    stop() {
        if (!this.running) return;
        
        this.running = false;
        
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
            this.animationId = null;
        }
        
        console.log('⏹️ GameLoop stopped');
    }
    
    /**
     * Main game loop implementation
     * Uses fixed timestep for physics and interpolated rendering
     */
    loop() {
        if (!this.running) return;
        
        // Schedule next frame
        this.animationId = requestAnimationFrame(() => this.loop());
        
        // Calculate frame time
        const newTime = performance.now();
        let frameTime = newTime - this.currentTime;
        
        // Prevent spiral of death - cap frame time
        frameTime = Math.min(frameTime, this.maxFrameTime);
        
        this.currentTime = newTime;
        this.accumulator += frameTime;
        
        // Fixed timestep updates (physics)
        let updateCount = 0;
        const maxUpdates = 5; // Prevent too many updates per frame
        
        while (this.accumulator >= this.fixedTimeStep && updateCount < maxUpdates) {
            // Call fixed timestep update
            if (this.onUpdate) {
                this.onUpdate(this.fixedTimeStep, this.currentTime);
            }
            
            this.accumulator -= this.fixedTimeStep;
            updateCount++;
        }
        
        // Calculate interpolation factor for smooth rendering
        const interpolation = this.accumulator / this.fixedTimeStep;
        
        // Interpolated rendering
        if (this.onRender) {
            this.onRender(interpolation);
        }
        
        // Update performance metrics
        this.updatePerformanceMetrics();
    }
    
    /**
     * Update performance metrics
     */
    updatePerformanceMetrics() {
        this.frameCount++;
        
        const now = performance.now();
        if (now - this.lastFPSUpdate >= 1000) {
            this.currentFPS = this.frameCount;
            this.frameCount = 0;
            this.lastFPSUpdate = now;
        }
    }
    
    /**
     * Get current FPS
     * @returns {number} Current FPS
     */
    getFPS() {
        return this.currentFPS;
    }
    
    /**
     * Get frame time in milliseconds
     * @returns {number} Frame time
     */
    getFrameTime() {
        return this.currentTime - this.lastTime;
    }
    
    /**
     * Get timing statistics
     * @returns {Object} Timing statistics
     */
    getTimingStats() {
        return {
            fps: this.currentFPS,
            frameTime: this.getFrameTime(),
            fixedTimeStep: this.fixedTimeStep,
            accumulator: this.accumulator,
            running: this.running,
            targetFPS: this.options.targetFPS,
            physicsHz: this.options.physicsHz
        };
    }
    
    /**
     * Set target FPS (for frame limiting)
     * @param {number} fps - Target FPS
     */
    setTargetFPS(fps) {
        this.options.targetFPS = fps;
        console.log(`🎯 Target FPS set to: ${fps}`);
    }
    
    /**
     * Set physics frequency
     * @param {number} hz - Physics frequency in Hz
     */
    setPhysicsHz(hz) {
        this.options.physicsHz = hz;
        this.fixedTimeStep = 1000 / hz;
        console.log(`⚡ Physics Hz set to: ${hz} (${this.fixedTimeStep.toFixed(2)}ms timestep)`);
    }
    
    /**
     * Dispose of game loop resources
     */
    dispose() {
        this.stop();
        
        this.onUpdate = null;
        this.onRender = null;
        
        console.log('🗑️ GameLoop disposed');
    }
}