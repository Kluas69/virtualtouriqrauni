import 'dart:async';
import 'package:flutter/material.dart';
import '../logging/app_logger.dart';
import '../memory/memory_manager.dart';

/// Global application state manager
/// 
/// This class provides centralized state management with automatic
/// persistence, memory optimization, and error recovery.
class AppStateManager extends ChangeNotifier {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal();
  
  final Map<String, dynamic> _state = {};
  final Map<String, StreamController> _stateStreams = {};
  final MemoryManager _memoryManager = MemoryManager();
  
  bool _isInitialized = false;
  Timer? _persistenceTimer;
  
  /// Initialize the state manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _memoryManager.initialize();
      
      // Load persisted state
      await _loadPersistedState();
      
      // Setup automatic persistence every 30 seconds
      _persistenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _persistState();
      });
      
      _isInitialized = true;
      AppLogger.info('App state manager initialized',
        component: 'AppStateManager',
        metadata: {'stateKeys': _state.keys.length});
    } catch (e) {
      AppLogger.error('Failed to initialize app state manager',
        component: 'AppStateManager',
        error: e);
    }
  }
  
  /// Set a state value
  void setState<T>(String key, T value, {bool persist = true}) {
    try {
      final oldValue = _state[key];
      _state[key] = value;
      
      // Cache the value for quick access
      _memoryManager.cache(key, value);
      
      // Notify stream listeners
      final controller = _stateStreams[key];
      if (controller != null && !controller.isClosed) {
        controller.add(value);
      }
      
      // Notify change notifier listeners
      notifyListeners();
      
      AppLogger.debug('State updated',
        component: 'AppStateManager',
        metadata: {
          'key': key,
          'valueType': T.toString(),
          'hasChanged': oldValue != value,
        });
      
      if (persist) {
        _persistState();
      }
    } catch (e) {
      AppLogger.error('Failed to set state',
        component: 'AppStateManager',
        error: e,
        metadata: {'key': key});
    }
  }
  
  /// Get a state value
  T? getState<T>(String key, {T? defaultValue}) {
    try {
      // Try cache first for performance
      final cachedValue = _memoryManager.getCached<T>(key);
      if (cachedValue != null) {
        return cachedValue;
      }
      
      // Fallback to main state
      final value = _state[key];
      if (value is T) {
        // Cache for next time
        _memoryManager.cache(key, value);
        return value;
      }
      
      return defaultValue;
    } catch (e) {
      AppLogger.warning('Failed to get state',
        component: 'AppStateManager',
        error: e,
        metadata: {'key': key});
      return defaultValue;
    }
  }
  
  /// Remove a state value
  void removeState(String key) {
    try {
      _state.remove(key);
      _memoryManager.removeCached(key);
      
      // Close and remove stream
      final controller = _stateStreams.remove(key);
      controller?.close();
      
      notifyListeners();
      _persistState();
      
      AppLogger.debug('State removed',
        component: 'AppStateManager',
        metadata: {'key': key});
    } catch (e) {
      AppLogger.error('Failed to remove state',
        component: 'AppStateManager',
        error: e,
        metadata: {'key': key});
    }
  }
  
  /// Get a stream for state changes
  Stream<T> getStateStream<T>(String key) {
    try {
      if (!_stateStreams.containsKey(key)) {
        _stateStreams[key] = StreamController<T>.broadcast();
      }
      
      final controller = _stateStreams[key]!;
      return controller.stream.cast<T>();
    } catch (e) {
      AppLogger.error('Failed to create state stream',
        component: 'AppStateManager',
        error: e,
        metadata: {'key': key});
      return const Stream.empty();
    }
  }
  
  /// Check if a state key exists
  bool hasState(String key) {
    return _state.containsKey(key);
  }
  
  /// Get all state keys
  List<String> getStateKeys() {
    return _state.keys.toList();
  }
  
  /// Clear all state
  void clearState({bool persist = true}) {
    try {
      final keyCount = _state.length;
      _state.clear();
      _memoryManager.clearCache();
      
      // Close all streams
      for (final controller in _stateStreams.values) {
        controller.close();
      }
      _stateStreams.clear();
      
      notifyListeners();
      
      if (persist) {
        _persistState();
      }
      
      AppLogger.info('All state cleared',
        component: 'AppStateManager',
        metadata: {'clearedKeys': keyCount});
    } catch (e) {
      AppLogger.error('Failed to clear state',
        component: 'AppStateManager',
        error: e);
    }
  }
  
  /// Get memory usage statistics
  Map<String, dynamic> getStats() {
    return {
      'stateKeys': _state.length,
      'activeStreams': _stateStreams.length,
      'isInitialized': _isInitialized,
      'memoryStats': _memoryManager.getMemoryStats(),
    };
  }
  
  /// Load persisted state from storage
  Future<void> _loadPersistedState() async {
    try {
      // In a real implementation, this would load from SharedPreferences
      // or another persistence mechanism
      AppLogger.debug('Loading persisted state',
        component: 'AppStateManager');
    } catch (e) {
      AppLogger.warning('Failed to load persisted state',
        component: 'AppStateManager',
        error: e);
    }
  }
  
  /// Persist current state to storage
  Future<void> _persistState() async {
    try {
      // In a real implementation, this would save to SharedPreferences
      // or another persistence mechanism
      AppLogger.debug('Persisting state',
        component: 'AppStateManager',
        metadata: {'stateKeys': _state.length});
    } catch (e) {
      AppLogger.warning('Failed to persist state',
        component: 'AppStateManager',
        error: e);
    }
  }
  
  @override
  void dispose() {
    _persistenceTimer?.cancel();
    
    // Close all streams
    for (final controller in _stateStreams.values) {
      controller.close();
    }
    _stateStreams.clear();
    
    _memoryManager.dispose();
    _isInitialized = false;
    
    AppLogger.info('App state manager disposed',
      component: 'AppStateManager');
    
    super.dispose();
  }
}

/// Mixin for widgets that need state management
mixin StateMixin<T extends StatefulWidget> on State<T> {
  final AppStateManager _stateManager = AppStateManager();
  final List<StreamSubscription> _subscriptions = [];
  
  /// Set state value
  void setAppState<V>(String key, V value, {bool persist = true}) {
    _stateManager.setState(key, value, persist: persist);
  }
  
  /// Get state value
  V? getAppState<V>(String key, {V? defaultValue}) {
    return _stateManager.getState<V>(key, defaultValue: defaultValue);
  }
  
  /// Listen to state changes
  void listenToState<V>(String key, void Function(V value) onChanged) {
    final subscription = _stateManager.getStateStream<V>(key).listen(onChanged);
    _subscriptions.add(subscription);
  }
  
  /// Remove state value
  void removeAppState(String key) {
    _stateManager.removeState(key);
  }
  
  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    super.dispose();
  }
}

/// State-aware widget that rebuilds when specific state changes
class StateBuilder<T> extends StatefulWidget {
  final String stateKey;
  final T? defaultValue;
  final Widget Function(BuildContext context, T? value) builder;
  
  const StateBuilder({
    super.key,
    required this.stateKey,
    required this.builder,
    this.defaultValue,
  });
  
  @override
  State<StateBuilder<T>> createState() => _StateBuilderState<T>();
}

class _StateBuilderState<T> extends State<StateBuilder<T>> with StateMixin {
  T? _currentValue;
  
  @override
  void initState() {
    super.initState();
    _currentValue = getAppState<T>(widget.stateKey, defaultValue: widget.defaultValue);
    
    listenToState<T>(widget.stateKey, (value) {
      if (mounted) {
        setState(() {
          _currentValue = value;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentValue);
  }
}