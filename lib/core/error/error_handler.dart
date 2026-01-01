import 'dart:async';
import 'package:flutter/foundation.dart';
import '../logging/app_logger.dart';

/// Global error handler for the application
/// 
/// This handler provides centralized error handling with recovery strategies,
/// structured logging, and graceful degradation for platform-specific features.
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();
  
  /// Initialize global error handling
  static void initialize() {
    // Handle uncaught errors in the Flutter framework
    FlutterError.onError = (FlutterErrorDetails details) {
      _instance.handleFlutterError(details);
    };
    
    // Handle uncaught errors in async operations
    PlatformDispatcher.instance.onError = (error, stack) {
      _instance.handleAsyncError(error, stack);
      return true; // Prevent crash
    };
  }
  
  /// Handle Flutter framework errors
  void handleFlutterError(FlutterErrorDetails details) {
    final context = ErrorContext(
      component: 'Flutter',
      operation: 'Widget Build/Render',
      metadata: {
        'library': details.library ?? 'unknown',
        'context': details.context?.toString() ?? 'unknown',
      },
      stackTrace: details.stack,
    );
    
    AppLogger.error(
      details.summary.toString(),
      component: context.component,
      metadata: context.toMap(),
      error: details.exception,
      stackTrace: details.stack,
    );
    
    // In debug mode, also show the red screen
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }
  
  /// Handle async errors
  void handleAsyncError(Object error, StackTrace stackTrace) {
    final context = ErrorContext(
      component: 'Async',
      operation: 'Async Operation',
      stackTrace: stackTrace,
    );
    
    AppLogger.error(
      'Unhandled async error: ${error.toString()}',
      component: context.component,
      metadata: context.toMap(),
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Handle platform-specific feature errors with graceful degradation
  T? handlePlatformError<T>(
    String component,
    String operation,
    T Function() action, {
    T? fallback,
    String? fallbackMessage,
  }) {
    try {
      return action();
    } catch (error, stackTrace) {
      final context = ErrorContext(
        component: component,
        operation: operation,
        metadata: {
          'hasFallback': fallback != null,
          'fallbackMessage': fallbackMessage,
        },
        stackTrace: stackTrace,
      );
      
      AppLogger.warning(
        'Platform feature failed, using fallback: ${error.toString()}',
        component: context.component,
        metadata: context.toMap(),
        error: error,
        stackTrace: stackTrace,
      );
      
      return fallback;
    }
  }
  
  /// Handle asset loading errors with retry logic
  Future<T?> handleAssetError<T>(
    String component,
    String assetPath,
    Future<T> Function() loader, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    T? fallback,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await loader();
      } catch (error, stackTrace) {
        final context = ErrorContext(
          component: component,
          operation: 'Asset Loading',
          metadata: {
            'assetPath': assetPath,
            'attempt': attempt,
            'maxRetries': maxRetries,
          },
          stackTrace: stackTrace,
        );
        
        if (attempt == maxRetries) {
          AppLogger.error(
            'Asset loading failed after $maxRetries attempts: $assetPath',
            component: context.component,
            metadata: context.toMap(),
            error: error,
            stackTrace: stackTrace,
          );
          return fallback;
        } else {
          AppLogger.warning(
            'Asset loading failed (attempt $attempt/$maxRetries): $assetPath',
            component: context.component,
            metadata: context.toMap(),
            error: error,
          );
          await Future.delayed(retryDelay);
        }
      }
    }
    return fallback;
  }
  
  /// Handle network errors with exponential backoff
  Future<T?> handleNetworkError<T>(
    String component,
    String url,
    Future<T> Function() networkCall, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    T? fallback,
  }) async {
    Duration delay = initialDelay;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await networkCall();
      } catch (error, stackTrace) {
        final context = ErrorContext(
          component: component,
          operation: 'Network Request',
          metadata: {
            'url': url,
            'attempt': attempt,
            'maxRetries': maxRetries,
            'delay': delay.inMilliseconds,
          },
          stackTrace: stackTrace,
        );
        
        if (attempt == maxRetries) {
          AppLogger.error(
            'Network request failed after $maxRetries attempts: $url',
            component: context.component,
            metadata: context.toMap(),
            error: error,
            stackTrace: stackTrace,
          );
          return fallback;
        } else {
          AppLogger.warning(
            'Network request failed (attempt $attempt/$maxRetries): $url',
            component: context.component,
            metadata: context.toMap(),
            error: error,
          );
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff
        }
      }
    }
    return fallback;
  }
}

