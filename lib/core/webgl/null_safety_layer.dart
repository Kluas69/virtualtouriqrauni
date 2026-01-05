import 'dart:html' as html;
import '../logging/app_logger.dart';

/// Null safety layer for DOM operations
/// 
/// Provides comprehensive null checking and validation for all DOM operations
/// to prevent "Unexpected null value" errors in Flutter web platform views.
class NullSafetyLayer {
  static const String _component = 'NullSafetyLayer';
  
  /// Safely execute an operation with null checking and fallback
  static T? safeExecute<T>(
    T Function() operation, {
    T? fallback,
    String? operationName,
  }) {
    try {
      final result = operation();
      if (result == null && fallback != null) {
        AppLogger.warning(
          'Operation returned null, using fallback: ${operationName ?? 'unknown'}',
          component: _component,
        );
        return fallback;
      }
      return result;
    } catch (e) {
      AppLogger.error(
        'Operation failed: ${operationName ?? 'unknown'}',
        component: _component,
        error: e,
      );
      return fallback;
    }
  }
  
  /// Validate that a DOM element is not null and is connected
  static bool validateElement(html.Element? element, {String? elementName}) {
    if (element == null) {
      AppLogger.warning(
        'Element validation failed: element is null (${elementName ?? 'unknown'})',
        component: _component,
      );
      return false;
    }
    
    // Additional validation - check if element is connected to DOM
    try {
      if (element.isConnected == false) {
        AppLogger.warning(
          'Element validation failed: element not connected to DOM (${elementName ?? 'unknown'})',
          component: _component,
        );
        return false;
      }
    } catch (e) {
      AppLogger.warning(
        'Element validation failed: error checking connection (${elementName ?? 'unknown'})',
        component: _component,
        error: e,
      );
      return false;
    }
    
    return true;
  }
  
  /// Create a DOM element with comprehensive null safety
  static html.Element? createSafeElement(
    String tagName, {
    String? id,
    Map<String, String>? attributes,
    Map<String, String>? styles,
  }) {
    return safeExecute<html.Element>(
      () {
        final element = html.document.createElement(tagName);
        if (element == null) {
          throw StateError('Failed to create element: $tagName');
        }
        
        // Set ID if provided
        if (id != null) {
          element.id = id;
        }
        
        // Set attributes if provided
        if (attributes != null) {
          for (final entry in attributes.entries) {
            safeSetAttribute(element, entry.key, entry.value);
          }
        }
        
        // Set styles if provided
        if (styles != null) {
          for (final entry in styles.entries) {
            safeSetStyle(element, entry.key, entry.value);
          }
        }
        
        return element;
      },
      operationName: 'createElement($tagName)',
    );
  }
  
  /// Create a fallback container element for error states
  static html.DivElement createFallbackContainer(
    String errorMessage, {
    String? containerId,
  }) {
    final container = html.DivElement();
    container.id = containerId ?? 'fallback-container-${DateTime.now().millisecondsSinceEpoch}';
    container.style.cssText = '''
      width: 100%;
      height: 100%;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
      color: white;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      text-align: center;
      padding: 24px;
    ''';
    
    // Create error content
    final errorDiv = html.DivElement();
    errorDiv.style.maxWidth = '400px';
    
    final iconDiv = html.DivElement();
    iconDiv.style.cssText = 'font-size: 48px; margin-bottom: 24px;';
    iconDiv.text = '⚠️';
    
    final titleDiv = html.HeadingElement.h2();
    titleDiv.style.cssText = 'font-size: 20px; font-weight: 700; margin-bottom: 16px;';
    titleDiv.text = 'Platform View Error';
    
    final messageDiv = html.DivElement();
    messageDiv.style.cssText = '''
      background: rgba(0,0,0,0.2);
      border-radius: 8px;
      padding: 16px;
      margin-bottom: 24px;
      font-size: 14px;
      line-height: 1.4;
    ''';
    messageDiv.text = errorMessage;
    
    errorDiv.append(iconDiv);
    errorDiv.append(titleDiv);
    errorDiv.append(messageDiv);
    container.append(errorDiv);
    
    return container;
  }
  
  /// Safely append a child element to a parent
  static bool safeAppendChild(html.Element? parent, html.Element? child) {
    if (!validateElement(parent, elementName: 'parent') || 
        !validateElement(child, elementName: 'child')) {
      return false;
    }
    
    return safeExecute<bool>(
      () {
        parent!.append(child!);
        return true;
      },
      fallback: false,
      operationName: 'appendChild',
    ) ?? false;
  }
  
  /// Safely set an attribute on an element
  static bool safeSetAttribute(html.Element? element, String name, String value) {
    if (!validateElement(element, elementName: 'attribute target')) {
      return false;
    }
    
    return safeExecute<bool>(
      () {
        element!.setAttribute(name, value);
        return true;
      },
      fallback: false,
      operationName: 'setAttribute($name)',
    ) ?? false;
  }
  
  /// Safely set a style property on an element
  static bool safeSetStyle(html.Element? element, String property, String value) {
    if (!validateElement(element, elementName: 'style target')) {
      return false;
    }
    
    return safeExecute<bool>(
      () {
        element!.style.setProperty(property, value);
        return true;
      },
      fallback: false,
      operationName: 'setStyle($property)',
    ) ?? false;
  }
  
  /// Safely remove an element from the DOM
  static bool safeRemoveElement(html.Element? element) {
    if (element == null) {
      AppLogger.debug('Element removal skipped: element is null', component: _component);
      return true; // Consider null removal as successful
    }
    
    return safeExecute<bool>(
      () {
        element.remove();
        return true;
      },
      fallback: false,
      operationName: 'removeElement',
    ) ?? false;
  }
  
  /// Safely query for an element
  static html.Element? safeQuerySelector(String selector, {html.Element? parent}) {
    final searchRoot = parent ?? html.document.documentElement;
    
    return safeExecute<html.Element?>(
      () {
        return searchRoot?.querySelector(selector);
      },
      operationName: 'querySelector($selector)',
    );
  }
  
  /// Safely query for multiple elements
  static List<html.Element> safeQuerySelectorAll(String selector, {html.Element? parent}) {
    final searchRoot = parent ?? html.document.documentElement;
    
    return safeExecute<List<html.Element>>(
      () {
        final elements = searchRoot?.querySelectorAll(selector);
        return elements?.cast<html.Element>().toList() ?? <html.Element>[];
      },
      fallback: <html.Element>[],
      operationName: 'querySelectorAll($selector)',
    ) ?? <html.Element>[];
  }
  
  /// Create a safe iframe element with comprehensive validation
  static html.IFrameElement? createSafeIframe({
    required String src,
    String? id,
    Map<String, String>? attributes,
    Map<String, String>? styles,
  }) {
    return safeExecute<html.IFrameElement>(
      () {
        final iframe = html.IFrameElement();
        if (iframe == null) {
          throw StateError('Failed to create iframe element');
        }
        
        // Set source using both property and attribute for better compatibility
        iframe.src = src;
        iframe.setAttribute('src', src);
        
        // Set ID if provided
        if (id != null) {
          iframe.id = id;
        }
        
        // Set default safe attributes
        iframe.setAttribute('loading', 'lazy');
        iframe.setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        
        // Set additional attributes if provided
        if (attributes != null) {
          for (final entry in attributes.entries) {
            safeSetAttribute(iframe, entry.key, entry.value);
          }
        }
        
        // Set additional styles if provided
        if (styles != null) {
          for (final entry in styles.entries) {
            safeSetStyle(iframe, entry.key, entry.value);
          }
        }
        
        return iframe;
      },
      operationName: 'createIframe($src)',
    );
  }
  
  /// Validate iframe creation and setup
  static bool validateIframe(html.IFrameElement? iframe) {
    if (!validateElement(iframe, elementName: 'iframe')) {
      return false;
    }
    
    // Additional iframe-specific validation with improved error handling
    try {
      // Check if iframe has a src attribute set (more reliable than checking src property)
      final srcAttribute = iframe?.getAttribute('src');
      if (srcAttribute == null || srcAttribute.isEmpty) {
        AppLogger.warning('Iframe validation failed: no src attribute', component: _component);
        return false;
      }
      
      // Validate that the iframe is properly attached to DOM
      if (iframe?.parentNode == null) {
        AppLogger.warning('Iframe validation failed: not attached to DOM', component: _component);
        return false;
      }
      
    } catch (e) {
      AppLogger.warning('Iframe validation failed: error during validation', 
        component: _component, error: e);
      // Don't fail validation on exceptions - iframe might still work
      AppLogger.info('Continuing with iframe despite validation exception', component: _component);
      return true;
    }
    
    return true;
  }
}