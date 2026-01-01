import 'dart:developer' as developer;

/// Log levels for structured logging
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Structured logging system to replace print statements
/// 
/// This logger provides structured logging with levels, metadata,
/// and proper error context for debugging and monitoring.
class AppLogger {
  static bool _isEnabled = true;
  static LogLevel _minimumLevel = LogLevel.info;
  
  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
  
  /// Set minimum log level
  static void setMinimumLevel(LogLevel level) {
    _minimumLevel = level;
  }
  
  /// Log a debug message
  static void debug(String message, {
    String? component,
    Map<String, dynamic>? metadata,
  }) {
    log(LogLevel.debug, message, component: component, metadata: metadata);
  }
  
  /// Log an info message
  static void info(String message, {
    String? component,
    Map<String, dynamic>? metadata,
  }) {
    log(LogLevel.info, message, component: component, metadata: metadata);
  }
  
  /// Log a warning message
  static void warning(String message, {
    String? component,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(LogLevel.warning, message, 
        component: component, metadata: metadata, error: error, stackTrace: stackTrace);
  }
  
  /// Log an error message
  static void error(String message, {
    String? component,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(LogLevel.error, message, 
        component: component, metadata: metadata, error: error, stackTrace: stackTrace);
  }
  
  /// Log a fatal error message
  static void fatal(String message, {
    String? component,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(LogLevel.fatal, message, 
        component: component, metadata: metadata, error: error, stackTrace: stackTrace);
  }
  
  /// Core logging method with structured output
  static void log(
    LogLevel level,
    String message, {
    String? component,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_isEnabled || level.index < _minimumLevel.index) {
      return;
    }
    
    final timestamp = DateTime.now().toIso8601String();
    final levelName = level.name.toUpperCase();
    
    // Build structured log entry
    final logEntry = <String, dynamic>{
      'timestamp': timestamp,
      'level': levelName,
      'message': message,
      if (component != null) 'component': component,
      if (metadata != null) 'metadata': metadata,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
    
    // Format for console output
    final consoleMessage = _formatForConsole(logEntry);
    
    // Use developer.log for better debugging support
    developer.log(
      consoleMessage,
      name: component ?? 'VirtualTour',
      level: _getLevelValue(level),
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Format log entry for console output
  static String _formatForConsole(Map<String, dynamic> logEntry) {
    final buffer = StringBuffer();
    buffer.write('[${logEntry['timestamp']}] ');
    buffer.write('${logEntry['level']}: ');
    
    if (logEntry['component'] != null) {
      buffer.write('[${logEntry['component']}] ');
    }
    
    buffer.write(logEntry['message']);
    
    if (logEntry['metadata'] != null) {
      buffer.write(' | Metadata: ${logEntry['metadata']}');
    }
    
    if (logEntry['error'] != null) {
      buffer.write(' | Error: ${logEntry['error']}');
    }
    
    return buffer.toString();
  }
  
  /// Convert LogLevel to numeric value for developer.log
  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
    }
  }
}

/// Error context for structured error reporting
class ErrorContext {
  final String component;
  final String operation;
  final Map<String, dynamic> metadata;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  
  ErrorContext({
    required this.component,
    required this.operation,
    this.metadata = const {},
    this.stackTrace,
  }) : timestamp = DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'component': component,
      'operation': operation,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
  }
}