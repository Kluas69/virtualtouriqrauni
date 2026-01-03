// Performance Configuration for Production Deployment
window.PERFORMANCE_CONFIG = {
    // Device detection
    isMobile: /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent),
    isLowEndDevice: navigator.hardwareConcurrency <= 2 || navigator.deviceMemory <= 2,
    
    // Performance settings
    getOptimalSettings() {
        const shouldOptimize = this.isMobile || this.isLowEndDevice;
        
        return {
            pixelRatio: shouldOptimize ? Math.min(window.devicePixelRatio, 1.5) : window.devicePixelRatio,
            shadowMapSize: shouldOptimize ? 512 : 2048,
            antialias: !shouldOptimize,
            maxLights: shouldOptimize ? 2 : 4,
            modelScale: shouldOptimize ? 0.8 : 1.0,
            fogDistance: shouldOptimize ? 500 : 750,
            enableShadows: !shouldOptimize,
            textureQuality: shouldOptimize ? 0.5 : 1.0,
            geometryLOD: shouldOptimize ? 2 : 1,
            
            // Memory management
            enableMemoryOptimization: shouldOptimize,
            maxTextureSize: shouldOptimize ? 1024 : 2048,
            compressTextures: shouldOptimize,
            
            // Loading optimization
            progressiveLoading: true,
            lazyLoadAssets: shouldOptimize,
            preloadCriticalAssets: !shouldOptimize
        };
    },
    
    // Error handling configuration
    errorHandling: {
        maxRetries: 3,
        retryDelay: 1000,
        fallbackContent: true,
        enableAnalytics: true
    },
    
    // Caching configuration
    caching: {
        enableServiceWorker: true,
        cacheAssets: true,
        cacheDuration: 24 * 60 * 60 * 1000, // 24 hours
        enableOfflineMode: false
    }
};

// Export for use in modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = window.PERFORMANCE_CONFIG;
}