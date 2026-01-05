/**
 * EntityManager - Professional Entity-Component-System manager
 * Handles entity lifecycle and component queries efficiently
 */

export class EntityManager {
    constructor(componentRegistry) {
        this.componentRegistry = componentRegistry;
        
        // Entity storage
        this.entities = new Map(); // entityId -> entity data
        this.components = new Map(); // componentType -> Map(entityId -> component)
        this.entityComponents = new Map(); // entityId -> Set(componentTypes)
        
        // Entity ID generation
        this.nextEntityId = 1;
        this.freeEntityIds = [];
        
        // Query cache for performance
        this.queryCache = new Map();
        this.queryCacheValid = true;
        
        // Performance tracking
        this.entityCount = 0;
        this.componentCount = 0;
        
        console.log('🏗️ EntityManager initialized with ECS architecture');
    }
    
    /**
     * Create a new entity
     * @param {Object} entityData - Initial entity data
     * @returns {number} Entity ID
     */
    createEntity(entityData = {}) {
        // Get entity ID (reuse freed IDs for efficiency)
        const entityId = this.freeEntityIds.length > 0 
            ? this.freeEntityIds.pop() 
            : this.nextEntityId++;
        
        // Store entity data
        this.entities.set(entityId, {
            id: entityId,
            active: true,
            created: performance.now(),
            ...entityData
        });
        
        // Initialize component tracking
        this.entityComponents.set(entityId, new Set());
        
        this.entityCount++;
        this.invalidateQueryCache();
        
        console.log(`🆕 Entity created: ${entityId}`);
        return entityId;
    }
    
    /**
     * Destroy an entity and all its components
     * @param {number} entityId - Entity ID to destroy
     */
    destroyEntity(entityId) {
        if (!this.entities.has(entityId)) {
            console.warn(`⚠️ Attempted to destroy non-existent entity: ${entityId}`);
            return;
        }
        
        // Remove all components from this entity
        const componentTypes = this.entityComponents.get(entityId);
        if (componentTypes) {
            for (const componentType of componentTypes) {
                this.removeComponent(entityId, componentType);
            }
        }
        
        // Remove entity data
        this.entities.delete(entityId);
        this.entityComponents.delete(entityId);
        
        // Add ID to free list for reuse
        this.freeEntityIds.push(entityId);
        
        this.entityCount--;
        this.invalidateQueryCache();
        
        console.log(`🗑️ Entity destroyed: ${entityId}`);
    }
    
    /**
     * Get entity data
     * @param {number} entityId - Entity ID
     * @returns {Object|null} Entity data
     */
    getEntity(entityId) {
        return this.entities.get(entityId) || null;
    }
    
    /**
     * Check if entity exists and is active
     * @param {number} entityId - Entity ID
     * @returns {boolean} Whether entity exists and is active
     */
    isEntityActive(entityId) {
        const entity = this.entities.get(entityId);
        return entity && entity.active;
    }
    
    /**
     * Set entity active state
     * @param {number} entityId - Entity ID
     * @param {boolean} active - Active state
     */
    setEntityActive(entityId, active) {
        const entity = this.entities.get(entityId);
        if (entity) {
            entity.active = active;
            this.invalidateQueryCache();
        }
    }
    
    /**
     * Add component to entity
     * @param {number} entityId - Entity ID
     * @param {string} componentType - Component type name
     * @param {Object} componentData - Component data
     */
    addComponent(entityId, componentType, componentData = {}) {
        if (!this.entities.has(entityId)) {
            console.warn(`⚠️ Attempted to add component to non-existent entity: ${entityId}`);
            return;
        }
        
        // Ensure component type map exists
        if (!this.components.has(componentType)) {
            this.components.set(componentType, new Map());
        }
        
        // Create component instance
        const ComponentClass = this.componentRegistry.getComponent(componentType);
        const component = ComponentClass ? new ComponentClass(componentData) : componentData;
        
        // Store component
        this.components.get(componentType).set(entityId, component);
        this.entityComponents.get(entityId).add(componentType);
        
        this.componentCount++;
        this.invalidateQueryCache();
        
        console.log(`🔧 Component added: ${componentType} to entity ${entityId}`);
    }
    
    /**
     * Remove component from entity
     * @param {number} entityId - Entity ID
     * @param {string} componentType - Component type name
     */
    removeComponent(entityId, componentType) {
        const componentMap = this.components.get(componentType);
        if (componentMap && componentMap.has(entityId)) {
            // Dispose component if it has a dispose method
            const component = componentMap.get(entityId);
            if (component && typeof component.dispose === 'function') {
                component.dispose();
            }
            
            componentMap.delete(entityId);
            this.entityComponents.get(entityId)?.delete(componentType);
            
            this.componentCount--;
            this.invalidateQueryCache();
            
            console.log(`🗑️ Component removed: ${componentType} from entity ${entityId}`);
        }
    }
    
    /**
     * Get component from entity
     * @param {number} entityId - Entity ID
     * @param {string} componentType - Component type name
     * @returns {Object|null} Component instance
     */
    getComponent(entityId, componentType) {
        const componentMap = this.components.get(componentType);
        return componentMap ? componentMap.get(entityId) || null : null;
    }
    
    /**
     * Check if entity has component
     * @param {number} entityId - Entity ID
     * @param {string} componentType - Component type name
     * @returns {boolean} Whether entity has component
     */
    hasComponent(entityId, componentType) {
        const componentMap = this.components.get(componentType);
        return componentMap ? componentMap.has(entityId) : false;
    }
    
    /**
     * Get all components of an entity
     * @param {number} entityId - Entity ID
     * @returns {Map} Map of componentType -> component
     */
    getEntityComponents(entityId) {
        const result = new Map();
        const componentTypes = this.entityComponents.get(entityId);
        
        if (componentTypes) {
            for (const componentType of componentTypes) {
                const component = this.getComponent(entityId, componentType);
                if (component) {
                    result.set(componentType, component);
                }
            }
        }
        
        return result;
    }
    
    /**
     * Query entities with specific components
     * @param {string[]} requiredComponents - Required component types
     * @param {string[]} excludedComponents - Excluded component types
     * @returns {number[]} Array of entity IDs matching query
     */
    queryEntities(requiredComponents = [], excludedComponents = []) {
        // Create cache key
        const cacheKey = `${requiredComponents.sort().join(',')}|${excludedComponents.sort().join(',')}`;
        
        // Check cache
        if (this.queryCacheValid && this.queryCache.has(cacheKey)) {
            return this.queryCache.get(cacheKey);
        }
        
        const result = [];
        
        // Find entities with all required components and none of the excluded ones
        for (const [entityId, entity] of this.entities) {
            if (!entity.active) continue;
            
            const entityComponentTypes = this.entityComponents.get(entityId);
            if (!entityComponentTypes) continue;
            
            // Check required components
            const hasAllRequired = requiredComponents.every(type => 
                entityComponentTypes.has(type)
            );
            
            // Check excluded components
            const hasAnyExcluded = excludedComponents.some(type => 
                entityComponentTypes.has(type)
            );
            
            if (hasAllRequired && !hasAnyExcluded) {
                result.push(entityId);
            }
        }
        
        // Cache result
        this.queryCache.set(cacheKey, result);
        
        return result;
    }
    
    /**
     * Get all entities with a specific component
     * @param {string} componentType - Component type name
     * @returns {number[]} Array of entity IDs
     */
    getEntitiesWithComponent(componentType) {
        return this.queryEntities([componentType]);
    }
    
    /**
     * Invalidate query cache (called when entities/components change)
     */
    invalidateQueryCache() {
        this.queryCache.clear();
        this.queryCacheValid = true;
    }
    
    /**
     * Update all entities (called each frame)
     * @param {number} deltaTime - Frame delta time
     * @param {number} totalTime - Total elapsed time
     */
    update(deltaTime, totalTime) {
        // Update all components that have update methods
        for (const [componentType, componentMap] of this.components) {
            for (const [entityId, component] of componentMap) {
                if (component && typeof component.update === 'function') {
                    const entity = this.entities.get(entityId);
                    if (entity && entity.active) {
                        component.update(deltaTime, totalTime, entity);
                    }
                }
            }
        }
    }
    
    /**
     * Get entity count
     * @returns {number} Number of active entities
     */
    getEntityCount() {
        return this.entityCount;
    }
    
    /**
     * Get component count
     * @returns {number} Total number of components
     */
    getComponentCount() {
        return this.componentCount;
    }
    
    /**
     * Get statistics
     * @returns {Object} EntityManager statistics
     */
    getStatistics() {
        return {
            entityCount: this.entityCount,
            componentCount: this.componentCount,
            componentTypes: Array.from(this.components.keys()),
            queryCacheSize: this.queryCache.size,
            freeEntityIds: this.freeEntityIds.length,
            nextEntityId: this.nextEntityId
        };
    }
    
    /**
     * Clear all entities and components
     */
    clear() {
        // Dispose all components
        for (const [componentType, componentMap] of this.components) {
            for (const [entityId, component] of componentMap) {
                if (component && typeof component.dispose === 'function') {
                    component.dispose();
                }
            }
        }
        
        // Clear all data
        this.entities.clear();
        this.components.clear();
        this.entityComponents.clear();
        this.queryCache.clear();
        this.freeEntityIds = [];
        
        this.entityCount = 0;
        this.componentCount = 0;
        this.nextEntityId = 1;
        
        console.log('🧹 EntityManager cleared');
    }
    
    /**
     * Dispose of EntityManager resources
     */
    dispose() {
        this.clear();
        console.log('🗑️ EntityManager disposed');
    }
}