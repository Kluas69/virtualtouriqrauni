import 'dart:async';
// TODO: Replace with package:web for WASM compatibility
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../logging/app_logger.dart';

/// Web-specific performance optimizations for Google-level performance
class WebPerformanceOptimizer {
  static WebPerformanceOptimizer? _instance;
  static WebPerformanceOptimizer get instance => _instance ??= WebPerformanceOptimizer._();
  
  WebPerformanceOptimizer._();

  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized || !kIsWeb) return;
    
    try {
      AppLogger.info('Initializing web performance optimizations',
        component: 'WebPerformanceOptimizer');
      
      // 1. Add resource hints for faster loading
      _addResourceHints();
      
      // 2. Configure service worker caching
      _configureServiceWorker();
      
      // 3. Implement lazy loading for images
      _setupLazyImageLoading();
      
      // 4. Add performance observers
      _setupPerformanceObservers();
      
      // 5. Configure code splitting hints
      _addCodeSplittingHints();
      
      _isInitialized = true;
      AppLogger.info('Web performance optimizations initialized',
        component: 'WebPerformanceOptimizer');
    } catch (e) {
      AppLogger.error('Failed to initialize web performance optimizations',
        component: 'WebPerformanceOptimizer', error: e);
    }
  }
  
  /// Add resource hints for faster loading
  void _addResourceHints() {
    final head = html.document.head;
    if (head == null) return;
    
    // Preload critical assets
    final criticalAssets = [
      'assets/models/classroom.glb',
      'assets/app_data.json',
    ];
    
    for (final asset in criticalAssets) {
      final link = html.LinkElement()
        ..rel = 'preload'
        ..href = asset
        ..setAttribute('as', asset.endsWith('.glb') ? 'fetch' : 'fetch')
        ..setAttribute('crossorigin', 'anonymous');
      head.append(link);
    }
    
    // DNS prefetch for external resources
    final externalDomains = [
      'fonts.googleapis.com',
      'fonts.gstatic.com',
    ];
    
    for (final domain in externalDomains) {
      final link = html.LinkElement()
        ..rel = 'dns-prefetch'
        ..href = 'https://$domain';
      head.append(link);
    }
    
    AppLogger.debug('Added resource hints',
      component: 'WebPerformanceOptimizer',
      metadata: {
        'preloadAssets': criticalAssets.length,
        'dnsPrefetch': externalDomains.length,
      });
  }
  
  /// Configure service worker for caching
  void _configureServiceWorker() {
    if (html.window.navigator.serviceWorker == null) return;
    
    html.window.navigator.serviceWorker!.register('/flutter_service_worker.js')
      .then((registration) {
        AppLogger.info('Service worker registered successfully',
          component: 'WebPerformanceOptimizer');
      })
      .catchError((error) {
        AppLogger.warning('Service worker registration failed',
          component: 'WebPerformanceOptimizer', error: error);
      });
  }
  
  /// Setup lazy loading for images
  void _setupLazyImageLoading() {
    // Add intersection observer for lazy loading
    final script = html.ScriptElement()
      ..text = '''
        if ('IntersectionObserver' in window) {
          const imageObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
              if (entry.isIntersecting) {
                const img = entry.target;
                if (img.dataset.src) {
                  img.src = img.dataset.src;
                  img.removeAttribute('data-src');
                  observer.unobserve(img);
                }
              }
            });
          }, {
            rootMargin: '50px 0px',
            threshold: 0.01
          });
          
          // Observe all images with data-src
          document.querySelectorAll('img[data-src]').forEach(img => {
            imageObserver.observe(img);
          });
          
          // Observer for dynamically added images
          const mutationObserver = new MutationObserver(mutations => {
            mutations.forEach(mutation => {
              mutation.addedNodes.forEach(node => {
                if (node.nodeType === 1) {
                  const images = node.querySelectorAll ? node.querySelectorAll('img[data-src]') : [];
                  images.forEach(img => imageObserver.observe(img));
                }
              });
            });
          });
          
          mutationObserver.observe(document.body, {
            childList: true,
            subtree: true
          });
        }
      ''';
    
    html.document.head?.append(script);
  }
  
  /// Setup performance observers for monitoring
  void _setupPerformanceObservers() {
    final script = html.ScriptElement()
      ..text = '''
        if ('PerformanceObserver' in window) {
          // Observe Core Web Vitals
          const observer = new PerformanceObserver((list) => {
            for (const entry of list.getEntries()) {
              if (entry.entryType === 'largest-contentful-paint') {
                console.log('LCP:', entry.startTime);
              } else if (entry.entryType === 'first-input') {
                console.log('FID:', entry.processingStart - entry.startTime);
              } else if (entry.entryType === 'layout-shift') {
                if (!entry.hadRecentInput) {
                  console.log('CLS:', entry.value);
                }
              }
            }
          });
          
          try {
            observer.observe({entryTypes: ['largest-contentful-paint', 'first-input', 'layout-shift']});
          } catch (e) {
            console.warn('Performance observer not supported:', e);
          }
        }
      ''';
    
    html.document.head?.append(script);
  }
  
  /// Add code splitting hints
  void _addCodeSplittingHints() {
    // Add module preload hints for code splitting
    final head = html.document.head;
    if (head == null) return;
    
    final moduleHints = [
      '/assets/packages/flutter/assets/FontManifest.json',
    ];
    
    for (final module in moduleHints) {
      final link = html.LinkElement()
        ..rel = 'modulepreload'
        ..href = module;
      head.append(link);
    }
  }
  
  /// Optimize images for web
  static String optimizeImageUrl(String originalUrl, {int? width, int? height, int quality = 85}) {
    // For production, you'd integrate with a CDN like Cloudinary or ImageKit
    // This is a placeholder for image optimization
    return originalUrl;
  }
  
  /// Preload critical resources
  void preloadCriticalResources(List<String> resources) {
    final head = html.document.head;
    if (head == null) return;
    
    for (final resource in resources) {
      final link = html.LinkElement()
        ..rel = 'preload'
        ..href = resource
        ..setAttribute('as', _getResourceType(resource));
      head.append(link);
    }
    
    AppLogger.debug('Preloaded critical resources',
      component: 'WebPerformanceOptimizer',
      metadata: {'count': resources.length});
  }
  
  String _getResourceType(String url) {
    if (url.endsWith('.js')) return 'script';
    if (url.endsWith('.css')) return 'style';
    if (url.endsWith('.woff2') || url.endsWith('.woff')) return 'font';
    if (url.contains('image') || url.endsWith('.jpg') || url.endsWith('.png')) return 'image';
    return 'fetch';
  }
  
  /// Get Core Web Vitals metrics
  Future<Map<String, double>> getCoreWebVitals() async {
    final completer = Completer<Map<String, double>>();
    
    final script = html.ScriptElement()
      ..text = '''
        (function() {
          const vitals = {};
          
          if ('PerformanceObserver' in window) {
            const observer = new PerformanceObserver((list) => {
              for (const entry of list.getEntries()) {
                if (entry.entryType === 'largest-contentful-paint') {
                  vitals.lcp = entry.startTime;
                } else if (entry.entryType === 'first-input') {
                  vitals.fid = entry.processingStart - entry.startTime;
                }
              }
              
              // Send vitals back to Flutter
              window.postMessage({
                type: 'core-web-vitals',
                vitals: vitals
              }, '*');
            });
            
            observer.observe({entryTypes: ['largest-contentful-paint', 'first-input']});
            
            // Timeout after 5 seconds
            setTimeout(() => {
              window.postMessage({
                type: 'core-web-vitals',
                vitals: vitals
              }, '*');
            }, 5000);
          }
        })();
      ''';
    
    // Listen for the response
    late StreamSubscription subscription;
    subscription = html.window.onMessage.listen((event) {
      if (event.data is Map && event.data['type'] == 'core-web-vitals') {
        final vitals = Map<String, double>.from(event.data['vitals'] ?? {});
        subscription.cancel();
        completer.complete(vitals);
      }
    });
    
    html.document.head?.append(script);
    
    return completer.future;
  }
}