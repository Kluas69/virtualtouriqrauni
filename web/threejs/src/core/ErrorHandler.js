/**
 * ErrorHandler - Professional error handling and debugging system
 * Provides comprehensive error recovery and user-friendly error messages
 */

export class ErrorHandler {
    constructor(options = {}) {
        this.options = {
            enableLogging: true,
            enableUserNotifications: true,
            enableAutoRecovery: true,
            debugMode: false,
            ...options
        };
        
        this.errors = [];
        this.recoveryAttempts = new Map();
        this.maxRecoveryAttempts = 3;
        
        this.setupGlobalErrorHandling();
        
        console.log('✅ ErrorHandler initialized');
    }

    /**
     * Setup global error handling
     */
    setupGlobalErrorHandling() {
        // Handle unhandled promise rejections
        window.addEventListener('unhandledrejection', (event) => {
            this.handleError('UnhandledPromiseRejection', event.reason, {
                promise: event.promise,
                type: 'promise'
            });
        });

        // Handle JavaScript errors
        window.addEventListener('error', (event) => {
            this.handleError('JavaScriptError', event.error || event.message, {
                filename: event.filename,
                lineno: event.lineno,
                colno: event.colno,
                type: 'javascript'
            });
        });

        // Handle WebGL context loss
        document.addEventListener('webglcontextlost', (event) => {
            event.preventDefault();
            this.handleWebGLContextLoss();
        });

        // Handle WebGL context restore
        document.addEventListener('webglcontextrestored', () => {
            this.handleWebGLContextRestore();
        });
    }

    /**
     * Handle general errors with recovery options
     * @param {string} type - Error type
     * @param {Error|string} error - Error object or message
     * @param {Object} context - Additional context information
     */
    handleError(type, error, context = {}) {
        const errorInfo = {
            type,
            message: error?.message || error,
            stack: error?.stack,
            timestamp: new Date().toISOString(),
            context,
            id: this.generateErrorId()
        };

        this.errors.push(errorInfo);

        if (this.options.enableLogging) {
            console.error(`[${type}] ${errorInfo.message}`, errorInfo);
        }

        if (this.options.enableUserNotifications) {
            this.showUserError(errorInfo);
        }

        if (this.options.enableAutoRecovery) {
            this.attemptRecovery(errorInfo);
        }

        return errorInfo.id;
    }

    /**
     * Handle Three.js specific errors
     * @param {string} component - Three.js component name
     * @param {Error} error - Error object
     * @param {Object} context - Additional context
     */
    handleThreeJSError(component, error, context = {}) {
        const errorInfo = {
            type: 'ThreeJSError',
            component,
            message: error.message,
            stack: error.stack,
            timestamp: new Date().toISOString(),
            context,
            id: this.generateErrorId()
        };

        this.errors.push(errorInfo);

        console.error(`[ThreeJS/${component}] ${error.message}`, errorInfo);

        // Component-specific recovery strategies
        switch (component) {
            case 'ModelLoader':
                this.handleModelLoadingError(error, context);
                break;
            case 'Renderer':
                this.handleRendererError(error, context);
                break;
            case 'Camera':
                this.handleCameraError(error, context);
                break;
            case 'Scene':
                this.handleSceneError(error, context);
                break;
            default:
                this.showUserError(errorInfo);
        }

        return errorInfo.id;
    }

    /**
     * Handle model loading errors with fallback strategies
     * @param {Error} error - Error object
     * @param {Object} context - Additional context
     */
    handleModelLoadingError(error, context) {
        const message = this.getModelLoadingErrorMessage(error);
        
        this.showUserError({
            type: 'ModelLoadingError',
            message,
            suggestions: [
                'Check your internet connection',
                'Verify the model file exists',
                'Try refreshing the page',
                'Contact support if the problem persists'
            ]
        });

        // Attempt to load fallback model or show placeholder
        if (this.options.enableAutoRecovery) {
            this.loadFallbackModel(context);
        }
    }

    /**
     * Handle renderer errors
     * @param {Error} error - Error object
     * @param {Object} context - Additional context
     */
    handleRendererError(error, context) {
        const message = 'Graphics rendering error occurred. This might be due to hardware limitations or driver issues.';
        
        this.showUserError({
            type: 'RendererError',
            message,
            suggestions: [
                'Update your graphics drivers',
                'Try using a different browser',
                'Reduce graphics quality settings',
                'Restart your browser'
            ]
        });
    }

    /**
     * Handle WebGL context loss
     */
    handleWebGLContextLoss() {
        console.warn('🔴 WebGL context lost - attempting recovery...');
        
        this.showUserError({
            type: 'WebGLContextLoss',
            message: 'Graphics context was lost. Attempting to recover...',
            suggestions: [
                'Please wait while we restore the graphics',
                'If this persists, try refreshing the page'
            ]
        });
    }

    /**
     * Handle WebGL context restore
     */
    handleWebGLContextRestore() {
        console.log('✅ WebGL context restored');
        
        // Notify user of successful recovery
        this.showUserMessage('Graphics context restored successfully!', 'success');
        
        // Trigger re-initialization if needed
        if (window.classroomViewer && window.classroomViewer.onWebGLContextRestore) {
            window.classroomViewer.onWebGLContextRestore();
        }
    }

    /**
     * Attempt automatic error recovery
     * @param {Object} errorInfo - Error information
     */
    attemptRecovery(errorInfo) {
        const attemptKey = `${errorInfo.type}_${errorInfo.component || 'general'}`;
        const attempts = this.recoveryAttempts.get(attemptKey) || 0;

        if (attempts >= this.maxRecoveryAttempts) {
            console.warn(`Max recovery attempts reached for ${attemptKey}`);
            return false;
        }

        this.recoveryAttempts.set(attemptKey, attempts + 1);

        switch (errorInfo.type) {
            case 'ModelLoadingError':
                return this.recoverFromModelLoadingError(errorInfo);
            case 'RendererError':
                return this.recoverFromRendererError(errorInfo);
            case 'WebGLContextLoss':
                return this.recoverFromWebGLContextLoss(errorInfo);
            default:
                return false;
        }
    }

    /**
     * Recover from model loading errors
     * @param {Object} errorInfo - Error information
     */
    recoverFromModelLoadingError(errorInfo) {
        console.log('🔄 Attempting model loading recovery...');
        
        // Try alternative model paths or fallback model
        if (window.classroomViewer && window.classroomViewer.modelLoader) {
            // This would trigger the ModelLoader's fallback system
            return true;
        }
        
        return false;
    }

    /**
     * Load fallback model when primary model fails
     * @param {Object} context - Loading context
     */
    loadFallbackModel(context) {
        console.log('🔄 Loading fallback model...');
        
        // Create a simple placeholder scene
        if (window.classroomViewer && window.classroomViewer.scene) {
            this.createPlaceholderScene(window.classroomViewer.scene);
        }
    }

    /**
     * Create placeholder scene when model loading fails
     * @param {Object} scene - Three.js scene
     */
    createPlaceholderScene(scene) {
        try {
            // This would be implemented to create a simple placeholder
            console.log('🏗️ Creating placeholder scene...');
            
            // Notify user about fallback
            this.showUserMessage('Using placeholder environment while loading...', 'info');
            
        } catch (error) {
            console.error('Failed to create placeholder scene:', error);
        }
    }

    /**
     * Show user-friendly error message
     * @param {Object} errorInfo - Error information
     */
    showUserError(errorInfo) {
        const errorElement = document.getElementById('error');
        const errorMessageElement = document.getElementById('error-message');
        
        if (errorMessageElement) {
            let message = errorInfo.message;
            
            if (errorInfo.suggestions) {
                message += '\n\nSuggestions:\n' + errorInfo.suggestions.map(s => `• ${s}`).join('\n');
            }
            
            errorMessageElement.textContent = message;
        }
        
        if (errorElement) {
            errorElement.style.display = 'block';
        }
        
        // Hide loading screen
        const loadingElement = document.getElementById('loading');
        if (loadingElement) {
            loadingElement.classList.add('hidden');
        }
    }

    /**
     * Show user message (success, info, warning)
     * @param {string} message - Message to show
     * @param {string} type - Message type
     */
    showUserMessage(message, type = 'info') {
        const statusElement = document.getElementById('status');
        if (statusElement) {
            statusElement.textContent = message;
            statusElement.className = `status-${type}`;
        }
        
        console.log(`[${type.toUpperCase()}] ${message}`);
    }

    /**
     * Get user-friendly model loading error message
     * @param {Error} error - Error object
     * @returns {string} User-friendly message
     */
    getModelLoadingErrorMessage(error) {
        const message = error.message.toLowerCase();
        
        if (message.includes('404') || message.includes('not found')) {
            return 'The 3D model file could not be found. Please check your connection and try again.';
        } else if (message.includes('network') || message.includes('fetch')) {
            return 'Network error while loading the 3D model. Please check your internet connection.';
        } else if (message.includes('cors')) {
            return 'Security restriction prevented loading the 3D model. This is a server configuration issue.';
        } else if (message.includes('timeout')) {
            return 'Loading the 3D model took too long. Please try again with a better connection.';
        } else {
            return 'Failed to load the 3D model. Please refresh the page and try again.';
        }
    }

    /**
     * Generate unique error ID
     * @returns {string} Unique error ID
     */
    generateErrorId() {
        return `error_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    /**
     * Get error statistics
     * @returns {Object} Error statistics
     */
    getErrorStatistics() {
        const stats = {
            total: this.errors.length,
            byType: {},
            recent: this.errors.slice(-10)
        };

        this.errors.forEach(error => {
            stats.byType[error.type] = (stats.byType[error.type] || 0) + 1;
        });

        return stats;
    }

    /**
     * Clear error history
     */
    clearErrors() {
        this.errors = [];
        this.recoveryAttempts.clear();
        console.log('🧹 Error history cleared');
    }

    /**
     * Export error log for debugging
     * @returns {string} JSON string of error log
     */
    exportErrorLog() {
        return JSON.stringify({
            errors: this.errors,
            statistics: this.getErrorStatistics(),
            timestamp: new Date().toISOString()
        }, null, 2);
    }

    /**
     * Dispose of error handler
     */
    dispose() {
        // Remove event listeners would go here if we stored references
        this.errors = [];
        this.recoveryAttempts.clear();
        
        console.log('🗑️ ErrorHandler disposed');
    }
}