import 'dart:async';
import 'package:flutter/material.dart';

/// Fix for screen refreshing issues
/// 
/// This class provides utilities to prevent unnecessary screen refreshes
/// and optimize widget rebuilds for better performance.
class RefreshFix {
  static final RefreshFix _instance = RefreshFix._internal();
  factory RefreshFix() => _instance;
  RefreshFix._internal();
  
  final Set<String> _activeDebounces = {};
  final Map<String, Timer> _debounceTimers = {};
  
  /// Debounce function calls to prevent rapid refreshes
  void debounce(String key, VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    // Cancel existing timer
    _debounceTimers[key]?.cancel();
    
    // Create new timer
    _debounceTimers[key] = Timer(delay, () {
      _activeDebounces.remove(key);
      callback();
    });
    
    _activeDebounces.add(key);
  }
  
  /// Check if a debounce is active
  bool isDebouncing(String key) {
    return _activeDebounces.contains(key);
  }
  
  /// Cancel all active debounces
  void cancelAll() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _activeDebounces.clear();
  }
  
  /// Dispose resources
  void dispose() {
    cancelAll();
  }
}

/// Mixin to prevent unnecessary rebuilds
mixin RefreshOptimizationMixin<T extends StatefulWidget> on State<T> {
  final RefreshFix _refreshFix = RefreshFix();
  bool _isMounted = false;
  
  @override
  void initState() {
    super.initState();
    _isMounted = true;
  }
  
  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }
  
  /// Safe setState that prevents calls on unmounted widgets
  void safeSetState(VoidCallback callback) {
    if (_isMounted && mounted) {
      setState(callback);
    }
  }
  
  /// Debounced setState to prevent rapid refreshes
  void debouncedSetState(VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    final key = '${widget.runtimeType}_${hashCode}';
    _refreshFix.debounce(key, () {
      safeSetState(callback);
    }, delay: delay);
  }
}

/// Widget that prevents unnecessary rebuilds
class StableWidget extends StatefulWidget {
  final Widget child;
  final bool preventRebuild;
  
  const StableWidget({
    super.key,
    required this.child,
    this.preventRebuild = true,
  });
  
  @override
  State<StableWidget> createState() => _StableWidgetState();
}

class _StableWidgetState extends State<StableWidget> with RefreshOptimizationMixin {
  Widget? _cachedChild;
  
  @override
  void initState() {
    super.initState();
    _cachedChild = widget.child;
  }
  
  @override
  void didUpdateWidget(StableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (!widget.preventRebuild || widget.child != oldWidget.child) {
      _cachedChild = widget.child;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return _cachedChild ?? widget.child;
  }
}