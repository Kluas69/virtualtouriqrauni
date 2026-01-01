import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logging/app_logger.dart';

/// Error boundary widget that catches and handles widget errors gracefully
/// 
/// This widget wraps other widgets and provides fallback UI when errors occur,
/// preventing app crashes and providing better user experience.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final String? errorMessage;
  final VoidCallback? onError;
  final bool showErrorDetails;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.errorMessage,
    this.onError,
    this.showErrorDetails = false,
  });
  
  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback ?? _buildDefaultErrorWidget(context);
    }
    
    return ErrorCatchingWidget(
      onError: _handleError,
      child: widget.child,
    );
  }
  
  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      _error = error;
    });
    
    // Log the error
    AppLogger.error('Widget error caught by ErrorBoundary',
      component: 'ErrorBoundary',
      error: error,
      stackTrace: stackTrace);
    
    // Call custom error handler
    widget.onError?.call();
    
    // Provide haptic feedback on mobile
    HapticFeedback.lightImpact();
  }
  
  Widget _buildDefaultErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            widget.errorMessage ?? 'Something went wrong',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.showErrorDetails && _error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

/// Widget that catches errors in its child widget tree
class ErrorCatchingWidget extends StatelessWidget {
  final Widget child;
  final Function(Object error, StackTrace stackTrace) onError;
  
  const ErrorCatchingWidget({
    super.key,
    required this.child,
    required this.onError,
  });
  
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          onError(error, stackTrace);
          return const SizedBox.shrink();
        }
      },
    );
  }
}

/// Mixin for widgets that need error handling capabilities
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  /// Handle errors with automatic logging and user feedback
  void handleError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
    VoidCallback? onRetry,
  }) {
    AppLogger.error(
      'Error in ${T.toString()}${context != null ? ': $context' : ''}',
      component: T.toString(),
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
    
    // Show user-friendly error message
    if (mounted) {
      _showErrorSnackBar(error.toString(), onRetry);
    }
  }
  
  /// Handle async operations with error catching
  Future<R?> handleAsync<R>(
    Future<R> Function() operation, {
    String? operationName,
    R? fallback,
    bool showUserError = true,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        context: operationName,
      );
      
      if (!showUserError && fallback != null) {
        return fallback;
      }
      
      return null;
    }
  }
  
  void _showErrorSnackBar(String message, VoidCallback? onRetry) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Error: ${message.length > 100 ? '${message.substring(0, 100)}...' : message}',
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Global error widget builder for unhandled errors
class GlobalErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;
  
  const GlobalErrorWidget({
    super.key,
    required this.errorDetails,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.red.shade50,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'Application Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The application encountered an unexpected error.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Restart the app or navigate to a safe screen
                SystemNavigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restart App'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Configure global error handling
class ErrorBoundaryConfig {
  static void configure() {
    // Set custom error widget builder
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      AppLogger.error('Global widget error',
        component: 'GlobalErrorWidget',
        error: errorDetails.exception,
        stackTrace: errorDetails.stack);
      
      return GlobalErrorWidget(errorDetails: errorDetails);
    };
    
    AppLogger.info('Global error boundary configured',
      component: 'ErrorBoundaryConfig');
  }
}