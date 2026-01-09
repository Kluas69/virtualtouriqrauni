import 'dart:async';
import 'dart:html' as html;
import '../logging/app_logger.dart';

/// Security configuration for WebGL iframe and postMessage communication
class SecurityConfig {
  final Map<String, String> iframeAttributes;
  final Map<String, String> cspHeaders;
  final List<String> allowedOrigins;
  final int maxMessagesPerSecond;
  final Duration rateLimitWindow;
  
  const SecurityConfig({
    required this.iframeAttributes,
    required this.cspHeaders,
    required this.allowedOrigins,
    this.maxMessagesPerSecond = 60,
    this.rateLimitWindow = const Duration(seconds: 1),
  });
}

/// Rate limiting information for postMessage communications
class RateLimitInfo {
  int messageCount = 0;
  DateTime windowStart = DateTime.now();
  
  void reset() {
    messageCount = 0;
    windowStart = DateTime.now();
  }
  
  bool isWithinLimit(int maxMessages, Duration window) {
    final now = DateTime.now();
    if (now.difference(windowStart) > window) {
      reset();
    }
    return messageCount < maxMessages;
  }
  
  void incrementCount() {
    messageCount++;
  }
}

/// Security manager for WebGL iframe and postMessage communications
/// Implements enterprise-grade security measures to prevent XSS and injection attacks
class SecurityManager {
  static const String _logComponent = 'SecurityManager';
  
  /// Secure iframe sandbox attributes - removes dangerous permissions
  static const Map<String, String> secureIframeAttributes = {
    'sandbox': 'allow-scripts allow-pointer-lock allow-orientation-lock',
    'allow': 'accelerometer; gyroscope; magnetometer; xr-spatial-tracking; gamepad',
    'referrerpolicy': 'no-referrer-when-downgrade',
    'loading': 'lazy',
  };
  
  /// Comprehensive Content Security Policy headers
  static const Map<String, String> cspHeaders = {
    'Content-Security-Policy': "default-src 'self'; "
        "script-src 'self' 'unsafe-inline' https://unpkg.com; "
        "style-src 'self' 'unsafe-inline'; "
        "img-src 'self' data: blob:; "
        "connect-src 'self'; "
        "frame-ancestors 'none'; "
        "object-src 'none'; "
        "base-uri 'self';",
    'X-Frame-Options': 'DENY',
    'X-Content-Type-Options': 'nosniff',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'no-referrer-when-downgrade',
    'Permissions-Policy': 'accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()',
  };
  
  /// Default allowed origins for postMessage communication
  static const List<String> defaultAllowedOrigins = [
    'https://localhost',
    'https://127.0.0.1',
    'https://unpkg.com',
  ];
  
  /// Rate limiting tracking for each origin
  final Map<String, RateLimitInfo> _rateLimitMap = {};
  
  /// Security configuration
  late final SecurityConfig _config;
  
  /// Message validation patterns
  static const List<String> _dangerousPatterns = [
    '<script',
    'javascript:',
    'data:text/html',
    'vbscript:',
    'onload=',
    'onerror=',
    'onclick=',
    'eval(',
    'Function(',
    'setTimeout(',
    'setInterval(',
  ];
  
  /// Initialize security manager with configuration
  SecurityManager({SecurityConfig? config}) {
    _config = config ?? SecurityConfig(
      iframeAttributes: secureIframeAttributes,
      cspHeaders: cspHeaders,
      allowedOrigins: defaultAllowedOrigins,
    );
    
    AppLogger.info('Security manager initialized with ${_config.allowedOrigins.length} allowed origins',
      component: _logComponent);
  }
  
  /// Validate postMessage origin against allowed domains
  bool validateMessageOrigin(String origin, [List<String>? customAllowedOrigins]) {
    try {
      final allowedOrigins = customAllowedOrigins ?? _config.allowedOrigins;
      
      // Parse the origin URL
      final uri = Uri.tryParse(origin);
      if (uri == null) {
        AppLogger.warning('Invalid origin URL format: $origin', component: _logComponent);
        return false;
      }
      
      // Check against allowed origins
      for (final allowedOrigin in allowedOrigins) {
        final allowedUri = Uri.tryParse(allowedOrigin);
        if (allowedUri == null) continue;
        
        // Match scheme, host, and port
        if (uri.scheme == allowedUri.scheme &&
            uri.host == allowedUri.host &&
            uri.port == allowedUri.port) {
          return true;
        }
        
        // Allow localhost variations
        if ((uri.host == 'localhost' || uri.host == '127.0.0.1') &&
            (allowedUri.host == 'localhost' || allowedUri.host == '127.0.0.1')) {
          return true;
        }
      }
      
      AppLogger.warning('Origin not in allowed list: $origin', 
        component: _logComponent,
        metadata: {'allowedOrigins': allowedOrigins});
      return false;
      
    } catch (e) {
      AppLogger.error('Error validating message origin: $e',
        component: _logComponent,
        error: e,
        metadata: {'origin': origin});
      return false;
    }
  }
  
  /// Rate limit postMessages to prevent flooding attacks
  bool rateLimitMessages(String origin, [int? maxMessagesPerSecond]) {
    try {
      final maxMessages = maxMessagesPerSecond ?? _config.maxMessagesPerSecond;
      
      // Get or create rate limit info for this origin
      final rateLimitInfo = _rateLimitMap.putIfAbsent(origin, () => RateLimitInfo());
      
      // Check if within rate limit
      if (!rateLimitInfo.isWithinLimit(maxMessages, _config.rateLimitWindow)) {
        AppLogger.warning('Rate limit exceeded for origin: $origin',
          component: _logComponent,
          metadata: {
            'messageCount': rateLimitInfo.messageCount,
            'maxMessages': maxMessages,
            'windowStart': rateLimitInfo.windowStart.toIso8601String(),
          });
        return false;
      }
      
      // Increment message count
      rateLimitInfo.incrementCount();
      return true;
      
    } catch (e) {
      AppLogger.error('Error in rate limiting: $e',
        component: _logComponent,
        error: e,
        metadata: {'origin': origin});
      return false;
    }
  }
  
  /// Validate and sanitize postMessage content
  bool validateMessageContent(dynamic messageData) {
    try {
      // Convert to string for validation
      final messageString = messageData.toString().toLowerCase();
      
      // Check for dangerous patterns
      for (final pattern in _dangerousPatterns) {
        if (messageString.contains(pattern.toLowerCase())) {
          AppLogger.warning('Dangerous pattern detected in message: $pattern',
            component: _logComponent,
            metadata: {'messagePreview': messageString.substring(0, 100)});
          return false;
        }
      }
      
      // Additional validation for object messages
      if (messageData is Map) {
        return _validateMessageObject(messageData);
      }
      
      return true;
      
    } catch (e) {
      AppLogger.error('Error validating message content: $e',
        component: _logComponent,
        error: e);
      return false;
    }
  }
  
  /// Validate message object structure
  bool _validateMessageObject(Map<dynamic, dynamic> messageObj) {
    try {
      // Check for required fields
      if (!messageObj.containsKey('type') || !messageObj.containsKey('source')) {
        AppLogger.warning('Message missing required fields (type, source)',
          component: _logComponent);
        return false;
      }
      
      // Validate message type
      final messageType = messageObj['type'];
      if (messageType is! String || messageType.isEmpty) {
        AppLogger.warning('Invalid message type', component: _logComponent);
        return false;
      }
      
      // Validate source
      final source = messageObj['source'];
      if (source is! String || source.isEmpty) {
        AppLogger.warning('Invalid message source', component: _logComponent);
        return false;
      }
      
      // Check for timestamp (optional but recommended)
      if (messageObj.containsKey('timestamp')) {
        final timestamp = messageObj['timestamp'];
        if (timestamp is! int || timestamp <= 0) {
          AppLogger.warning('Invalid timestamp in message', component: _logComponent);
          return false;
        }
        
        // Check if timestamp is too old (prevent replay attacks)
        final now = DateTime.now().millisecondsSinceEpoch;
        final messageAge = now - timestamp;
        if (messageAge > 30000) { // 30 seconds
          AppLogger.warning('Message timestamp too old: ${messageAge}ms',
            component: _logComponent);
          return false;
        }
      }
      
      return true;
      
    } catch (e) {
      AppLogger.error('Error validating message object: $e',
        component: _logComponent,
        error: e);
      return false;
    }
  }
  
  /// Create secure iframe with hardened sandbox attributes
  html.IFrameElement? createSecureIframe({
    required String src,
    required String id,
    Map<String, String>? additionalStyles,
    Map<String, String>? additionalAttributes,
  }) {
    try {
      AppLogger.info('Creating secure iframe: $id', 
        component: _logComponent,
        metadata: {'src': src});
      
      // Validate source URL
      if (!_validateIframeSrc(src)) {
        AppLogger.error('Invalid iframe source URL: $src', component: _logComponent);
        return null;
      }
      
      final iframe = html.IFrameElement();
      
      // Set secure attributes
      for (final entry in _config.iframeAttributes.entries) {
        iframe.setAttribute(entry.key, entry.value);
      }
      
      // Add additional attributes if provided (but validate them)
      if (additionalAttributes != null) {
        for (final entry in additionalAttributes.entries) {
          if (_isSecureAttribute(entry.key, entry.value)) {
            iframe.setAttribute(entry.key, entry.value);
          } else {
            AppLogger.warning('Rejected insecure iframe attribute: ${entry.key}=${entry.value}',
              component: _logComponent);
          }
        }
      }
      
      // Set source and ID
      iframe.src = src;
      iframe.id = id;
      
      // Apply styles
      iframe.style.border = 'none';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      
      if (additionalStyles != null) {
        for (final entry in additionalStyles.entries) {
          iframe.style.setProperty(entry.key, entry.value);
        }
      }
      
      AppLogger.info('Secure iframe created successfully: $id', component: _logComponent);
      return iframe;
      
    } catch (e) {
      AppLogger.error('Failed to create secure iframe: $e',
        component: _logComponent,
        error: e,
        metadata: {'src': src, 'id': id});
      return null;
    }
  }
  
  /// Validate iframe source URL
  bool _validateIframeSrc(String src) {
    try {
      // Allow relative URLs
      if (src.startsWith('./') || src.startsWith('/')) {
        return true;
      }
      
      // Validate absolute URLs
      final uri = Uri.tryParse(src);
      if (uri == null) {
        return false;
      }
      
      // Only allow HTTPS and localhost HTTP
      if (uri.scheme != 'https' && 
          !(uri.scheme == 'http' && (uri.host == 'localhost' || uri.host == '127.0.0.1'))) {
        AppLogger.warning('Iframe source must use HTTPS or localhost HTTP: $src',
          component: _logComponent);
        return false;
      }
      
      return true;
      
    } catch (e) {
      AppLogger.error('Error validating iframe source: $e',
        component: _logComponent,
        error: e);
      return false;
    }
  }
  
  /// Check if iframe attribute is secure
  bool _isSecureAttribute(String key, String value) {
    // Dangerous attributes that should not be allowed
    const dangerousAttributes = [
      'allow-same-origin',
      'allow-popups',
      'allow-top-navigation',
      'allow-forms', // Can be dangerous
    ];
    
    // Check sandbox attribute specifically
    if (key == 'sandbox') {
      for (final dangerous in dangerousAttributes) {
        if (value.contains(dangerous)) {
          return false;
        }
      }
    }
    
    // Check for script injection in attributes
    if (value.toLowerCase().contains('javascript:') ||
        value.toLowerCase().contains('<script') ||
        value.toLowerCase().contains('onload=') ||
        value.toLowerCase().contains('onerror=')) {
      return false;
    }
    
    return true;
  }
  
  /// Setup secure postMessage listener with validation
  StreamSubscription<html.MessageEvent> setupSecureMessageListener(
    void Function(Map<String, dynamic>) onValidMessage, {
    List<String>? customAllowedOrigins,
    int? customRateLimit,
  }) {
    
    AppLogger.info('Setting up secure postMessage listener', component: _logComponent);
    
    return html.window.onMessage.listen((html.MessageEvent event) {
      try {
        final origin = event.origin ?? '';
        
        // Validate origin
        if (!validateMessageOrigin(origin, customAllowedOrigins)) {
          return; // Silently ignore invalid origins
        }
        
        // Rate limit messages
        if (!rateLimitMessages(origin, customRateLimit)) {
          return; // Silently ignore rate-limited messages
        }
        
        // Validate message content
        if (!validateMessageContent(event.data)) {
          return; // Silently ignore invalid content
        }
        
        // Convert to Map if possible
        Map<String, dynamic>? messageData;
        if (event.data is Map) {
          messageData = Map<String, dynamic>.from(event.data as Map);
        } else {
          AppLogger.debug('Non-map message received from $origin',
            component: _logComponent);
          return;
        }
        
        // Additional object validation
        if (!_validateMessageObject(messageData)) {
          return;
        }
        
        AppLogger.debug('Valid message received from $origin: ${messageData['type']}',
          component: _logComponent);
        
        // Call the handler with validated message
        onValidMessage(messageData);
        
      } catch (e) {
        AppLogger.error('Error processing postMessage: $e',
          component: _logComponent,
          error: e);
      }
    });
  }
  
  /// Send secure postMessage with validation
  bool sendSecureMessage(
    html.WindowBase? targetWindow,
    Map<String, dynamic> message,
    String targetOrigin,
  ) {
    try {
      // Validate target window
      if (targetWindow == null) {
        AppLogger.warning('Target window is null', component: _logComponent);
        return false;
      }
      
      // Validate message content
      if (!validateMessageContent(message)) {
        AppLogger.warning('Message content validation failed', component: _logComponent);
        return false;
      }
      
      // Add security metadata
      final secureMessage = Map<String, dynamic>.from(message);
      secureMessage['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      secureMessage['source'] = 'flutter';
      
      // Send message
      targetWindow.postMessage(secureMessage, targetOrigin);
      
      AppLogger.debug('Secure message sent to $targetOrigin: ${message['type']}',
        component: _logComponent);
      
      return true;
      
    } catch (e) {
      AppLogger.error('Failed to send secure message: $e',
        component: _logComponent,
        error: e,
        metadata: {'targetOrigin': targetOrigin, 'messageType': message['type']});
      return false;
    }
  }
  
  /// Get security configuration
  SecurityConfig get config => _config;
  
  /// Get current rate limit statistics
  Map<String, Map<String, dynamic>> getRateLimitStats() {
    final stats = <String, Map<String, dynamic>>{};
    
    for (final entry in _rateLimitMap.entries) {
      final origin = entry.key;
      final info = entry.value;
      
      stats[origin] = {
        'messageCount': info.messageCount,
        'windowStart': info.windowStart.toIso8601String(),
        'isWithinLimit': info.isWithinLimit(_config.maxMessagesPerSecond, _config.rateLimitWindow),
      };
    }
    
    return stats;
  }
  
  /// Clear rate limit data (for testing or reset)
  void clearRateLimitData() {
    _rateLimitMap.clear();
    AppLogger.info('Rate limit data cleared', component: _logComponent);
  }
  
  /// Dispose of resources
  void dispose() {
    _rateLimitMap.clear();
    AppLogger.info('Security manager disposed', component: _logComponent);
  }
}