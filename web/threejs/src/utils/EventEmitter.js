/**
 * Simple Event Emitter
 * Lightweight event system for component communication
 */

export class EventEmitter {
    constructor() {
        this.events = new Map();
    }
    
    on(event, callback) {
        if (!this.events.has(event)) {
            this.events.set(event, []);
        }
        this.events.get(event).push(callback);
        
        // Return unsubscribe function
        return () => this.off(event, callback);
    }
    
    once(event, callback) {
        const onceCallback = (...args) => {
            callback(...args);
            this.off(event, onceCallback);
        };
        
        return this.on(event, onceCallback);
    }
    
    off(event, callback) {
        if (!this.events.has(event)) return;
        
        const callbacks = this.events.get(event);
        const index = callbacks.indexOf(callback);
        
        if (index > -1) {
            callbacks.splice(index, 1);
        }
        
        if (callbacks.length === 0) {
            this.events.delete(event);
        }
    }
    
    emit(event, ...args) {
        if (!this.events.has(event)) return;
        
        const callbacks = this.events.get(event);
        callbacks.forEach(callback => {
            try {
                callback(...args);
            } catch (error) {
                console.error(`Error in event callback for '${event}':`, error);
            }
        });
    }
    
    removeAllListeners(event) {
        if (event) {
            this.events.delete(event);
        } else {
            this.events.clear();
        }
    }
    
    listenerCount(event) {
        return this.events.has(event) ? this.events.get(event).length : 0;
    }
    
    eventNames() {
        return Array.from(this.events.keys());
    }
}