import 'dart:async';
import 'dart:html' as html;
import '../logging/app_logger.dart';

/// WebGL Context Registry Entry
class WebGLContextEntry {
  final String contextId;
  final String viewerId;
  final DateTime createdAt;
  DateTime lastAccessedAt;
  final String browserType;
  bool isActive;
  final Map<String, dynamic> metadata;
  html.IFrameElement? iframe;
  
  WebGLContextEntry({
    required this.contextId,
    required this.viewerId,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.browserType,
    required this.isActive,
    this.metadata = const {},
    this.iframe,
  });
  
  /// Update last accessed time
  void updateAccess() {
    lastAccessedAt = DateTime.now();
  }
  
  /// Mark context as inactive
  void markInactive() {
    isActive = false;
  }
  
  /// Get age of context in milliseconds
  int get ageInMilliseconds => DateTime.now().difference(createdAt).inMilliseconds;
  
  /// Get time since last access in milliseconds
  int get timeSinceLastAccessInMilliseconds => DateTime.now().difference(lastAccessedAt).inMilliseconds;
}

/// Enhanced WebGL Context Manager
/// 
/// Manages WebGL context lifecycle, limits, and cleanup to prevent browser crashes
class WebGLContextManager {
  static WebGLContextManager? _instance;
  static WebGLContextManager get instance => _instance ??= WebGLContextManager._internal();
  
  WebGLContextManager._internal();
  
  static const String _component = 'WebGLContextManager';
  
  // Context registry
  final Map<String, WebGLContextEntry> _contextRegistry = {};
  
  // Browser-specific context limits
  static const Map<String, int> _browserContextLimits = {
    'chrome': 32,
    'firefox': 16,
    'safari': 8,
    'edge': 16,
    'default': 16,
  };
  
  // Context counter for unique IDs
  int _contextCounter = 0;
  
  // Memory monitoring
  Timer? _memoryMonitorTimer;
  static const Duration _memoryCheckInterval = Duration(seconds: 30);
  
  /// Initialize the context manager
  Future<void> initialize() async {
    AppLogger.info('Initializing WebGL Context Manager', component: _component);
    
    // Start memory monitoring
    _startMemoryMonitoring();
    
    // Cleanup any existing contexts from previous sessions
    await _cleanupStaleContexts();
    
    AppLogger.info('WebGL Context Manager initialized', 
      component: _component,
      metadata: {
        'maxContextLimit': maxContextLimit,
        'browserType': _getBrowserType(),
      });
  }
  
  /// Create a new WebGL context
  Future<String> createContext(String viewerId) async {
    // Check if we need to cleanup before creating new context
    if (_contextRegistry.length >= maxContextLimit) {
      AppLogger.warning('Context limit reached, cleaning up oldest contexts',
        component: _component,
        metadata: {
          'currentCount': _contextRegistry.length,
          'limit': maxContextLimit,
        });
      
      await cleanupExcessiveContexts();
    }
    
    // Generate unique context ID
    final contextId = 'webgl_context_${_contextCounter++}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create context entry
    final entry = WebGLContextEntry(
      contextId: contextId,
      viewerId: viewerId,
      createdAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      browserType: _getBrowserType(),
      isActive: true,
      metadata: {
        'userAgent': html.window.navigator.userAgent,
        'platform': html.window.navigator.platform,
      },
    );
    
    // Register context
    _contextRegistry[contextId] = entry;
    
    AppLogger.info('WebGL context created',
      component: _component,
      metadata: {
        'contextId': contextId,
        'viewerId': viewerId,
        'totalContexts': _contextRegistry.length,
      });
    
    return contextId;
  }
  
  /// Dispose a WebGL context
  Future<void> disposeContext(String contextId) async {
    final entry = _contextRegistry[contextId];
    if (entry == null) {
      AppLogger.warning('Attempted to dispose non-existent context',
        component: _component,
        metadata: {'contextId': contextId});
      return;
    }
    
    try {
      // Send cleanup message to iframe if available
      if (entry.iframe != null) {
        try {
          entry.iframe!.contentWindow?.postMessage({
            'type': 'dispose_context',
            'contextId': contextId,
            'viewerId': entry.viewerId,
            'source': 'flutter',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }, '*');
        } catch (e) {
          AppLogger.warning('Failed to send dispose message to iframe',
            component: _component,
            error: e,
            metadata: {'contextId': contextId});
        }
        
        // Remove iframe from DOM
        try {
          entry.iframe!.remove();
        } catch (e) {
          AppLogger.warning('Failed to remove iframe from DOM',
            component: _component,
            error: e,
            metadata: {'contextId': contextId});
        }
      }
      
      // Remove from registry
      _contextRegistry.remove(contextId);
      
      AppLogger.info('WebGL context disposed',
        component: _component,
        metadata: {
          'contextId': contextId,
          'viewerId': entry.viewerId,
          'remainingContexts': _contextRegistry.length,
        });
        
    } catch (e) {
      AppLogger.error('Error disposing WebGL context',
        component: _component,
        error: e,
        metadata: {'contextId': contextId});
    }
  }
  
  /// Cleanup excessive contexts when limit is reached
  Future<void> cleanupExcessiveContexts() async {
    if (_contextRegistry.length <= maxContextLimit) {
      return; // No cleanup needed
    }
    
    final contextsToRemove = _contextRegistry.length - maxContextLimit + 1;
    
    AppLogger.info('Cleaning up excessive WebGL contexts',
      component: _component,
      metadata: {
        'currentCount': _contextRegistry.length,
        'toRemove': contextsToRemove,
        'limit': maxContextLimit,
      });
    
    // Get contexts sorted by priority (inactive first, then oldest)
    final sortedContexts = _contextRegistry.values.toList()
      ..sort((a, b) {
        // Inactive contexts first
        if (!a.isActive && b.isActive) return -1;
        if (a.isActive && !b.isActive) return 1;
        
        // Then by last access time (oldest first)
        return a.lastAccessedAt.compareTo(b.lastAccessedAt);
      });
    
    // Remove oldest/inactive contexts
    final contextsToDispose = sortedContexts.take(contextsToRemove).toList();
    
    for (final context in contextsToDispose) {
      await disposeContext(context.contextId);
    }
    
    AppLogger.info('Excessive context cleanup completed',
      component: _component,
      metadata: {
        'removedCount': contextsToDispose.length,
        'remainingCount': _contextRegistry.length,
      });
  }
  
  /// Register an iframe with a context
  void registerIframe(String contextId, html.IFrameElement iframe) {
    final entry = _contextRegistry[contextId];
    if (entry != null) {
      entry.iframe = iframe;
      entry.updateAccess();
      
      // Set context tracking attributes
      iframe.setAttribute('data-context-id', contextId);
      iframe.setAttribute('data-viewer-id', entry.viewerId);
      
      AppLogger.debug('Iframe registered with context',
        component: _component,
        metadata: {
          'contextId': contextId,
          'viewerId': entry.viewerId,
        });
    }
  }
  
  /// Update context access time
  void updateContextAccess(String contextId) {
    final entry = _contextRegistry[contextId];
    if (entry != null) {
      entry.updateAccess();
    }
  }
  
  /// Mark context as inactive
  void markContextInactive(String contextId) {
    final entry = _contextRegistry[contextId];
    if (entry != null) {
      entry.markInactive();
      AppLogger.debug('Context marked as inactive',
        component: _component,
        metadata: {'contextId': contextId});
    }
  }
  
  /// Get current active context count
  int get activeContextCount => _contextRegistry.values.where((e) => e.isActive).length;
  
  /// Get maximum context limit for current browser
  int get maxContextLimit {
    final browserType = _getBrowserType();
    return _browserContextLimits[browserType] ?? _browserContextLimits['default']!;
  }
  
  /// Get list of inactive context IDs
  List<String> get inactiveContexts {
    return _contextRegistry.entries
        .where((entry) => !entry.value.isActive)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get context information
  WebGLContextEntry? getContext(String contextId) {
    return _contextRegistry[contextId];
  }
  
  /// Get all contexts for a viewer
  List<WebGLContextEntry> getContextsForViewer(String viewerId) {
    return _contextRegistry.values
        .where((entry) => entry.viewerId == viewerId)
        .toList();
  }
  
  /// Cleanup stale contexts from previous sessions
  Future<void> _cleanupStaleContexts() async {
    // Look for any existing WebGL containers in the DOM that might be stale
    try {
      final staleContainers = html.document.querySelectorAll('[id*="webgl-container"]');
      for (final container in staleContainers) {
        try {
          container.remove();
        } catch (e) {
          AppLogger.warning('Failed to remove stale container',
            component: _component,
            error: e);
        }
      }
      
      if (staleContainers.isNotEmpty) {
        AppLogger.info('Cleaned up ${staleContainers.length} stale WebGL containers',
          component: _component);
      }
    } catch (e) {
      AppLogger.warning('Error during stale context cleanup',
        component: _component,
        error: e);
    }
  }
  
  /// Start memory monitoring
  void _startMemoryMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = Timer.periodic(_memoryCheckInterval, (_) {
      _checkMemoryUsage();
    });
  }
  
  /// Check memory usage and trigger cleanup if needed
  void _checkMemoryUsage() {
    try {
      // Check if we have too many contexts
      if (_contextRegistry.length > maxContextLimit * 0.8) {
        AppLogger.info('Memory check: High context count detected',
          component: _component,
          metadata: {
            'contextCount': _contextRegistry.length,
            'threshold': (maxContextLimit * 0.8).round(),
          });
        
        // Cleanup inactive contexts
        _cleanupInactiveContexts();
      }
      
      // Log memory status periodically
      AppLogger.debug('Memory check completed',
        component: _component,
        metadata: {
          'totalContexts': _contextRegistry.length,
          'activeContexts': activeContextCount,
          'inactiveContexts': inactiveContexts.length,
        });
        
    } catch (e) {
      AppLogger.warning('Error during memory check',
        component: _component,
        error: e);
    }
  }
  
  /// Cleanup inactive contexts
  Future<void> _cleanupInactiveContexts() async {
    final inactiveIds = inactiveContexts;
    if (inactiveIds.isEmpty) return;
    
    AppLogger.info('Cleaning up inactive contexts',
      component: _component,
      metadata: {'count': inactiveIds.length});
    
    for (final contextId in inactiveIds) {
      await disposeContext(contextId);
    }
  }
  
  /// Get browser type for context limits
  String _getBrowserType() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    
    if (userAgent.contains('chrome') && !userAgent.contains('edge')) {
      return 'chrome';
    } else if (userAgent.contains('firefox')) {
      return 'firefox';
    } else if (userAgent.contains('safari') && !userAgent.contains('chrome')) {
      return 'safari';
    } else if (userAgent.contains('edge')) {
      return 'edge';
    }
    
    return 'default';
  }
  
  /// Dispose the context manager
  void dispose() {
    AppLogger.info('Disposing WebGL Context Manager', component: _component);
    
    // Cancel memory monitoring
    _memoryMonitorTimer?.cancel();
    
    // Dispose all contexts
    final contextIds = _contextRegistry.keys.toList();
    for (final contextId in contextIds) {
      disposeContext(contextId);
    }
    
    _contextRegistry.clear();
    _contextCounter = 0;
    
    AppLogger.info('WebGL Context Manager disposed', component: _component);
  }
  
  /// Get context statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalContexts': _contextRegistry.length,
      'activeContexts': activeContextCount,
      'inactiveContexts': inactiveContexts.length,
      'maxContextLimit': maxContextLimit,
      'browserType': _getBrowserType(),
      'contexts': _contextRegistry.values.map((entry) => {
        'contextId': entry.contextId,
        'viewerId': entry.viewerId,
        'isActive': entry.isActive,
        'ageMs': entry.ageInMilliseconds,
        'timeSinceAccessMs': entry.timeSinceLastAccessInMilliseconds,
      }).toList(),
    };
  }
}