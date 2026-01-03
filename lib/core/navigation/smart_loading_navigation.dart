import 'dart:async';
import 'package:flutter/material.dart';
import '../logging/app_logger.dart';

/// Smart navigation with loading overlay
/// Shows loading only when navigating from categories screen
class SmartLoadingNavigation {
  static final SmartLoadingNavigation _instance = SmartLoadingNavigation._internal();
  factory SmartLoadingNavigation() => _instance;
  SmartLoadingNavigation._internal();
  
  OverlayEntry? _loadingOverlay;
  bool _isLoading = false;
  
  /// Navigate with smart loading (only from categories)
  static Future<T?> navigateWithLoading<T extends Object?>(
    BuildContext context,
    Widget destination, {
    bool showLoading = true,
    String loadingText = 'Loading...',
    Duration minLoadingTime = const Duration(milliseconds: 800),
  }) async {
    final navigator = Navigator.of(context);
    SmartLoadingNavigation instance = SmartLoadingNavigation();
    
    if (showLoading && !instance._isLoading) {
      instance._showLoadingOverlay(context, loadingText);
    }
    
    try {
      // Start navigation immediately
      final navigationFuture = navigator.push<T>(
        PageRouteBuilder<T>(
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      
      // Wait for minimum loading time and navigation
      final results = await Future.wait([
        navigationFuture,
        Future.delayed(minLoadingTime),
      ]);
      
      return results[0] as T?;
    } finally {
      if (showLoading) {
        instance._hideLoadingOverlay();
      }
    }
  }
  
  void _showLoadingOverlay(BuildContext context, String text) {
    if (_isLoading) return;
    
    _isLoading = true;
    _loadingOverlay = OverlayEntry(
      builder: (context) => _LoadingOverlay(text: text),
    );
    
    Overlay.of(context).insert(_loadingOverlay!);
    AppLogger.debug('Loading overlay shown', component: 'SmartLoadingNavigation');
  }
  
  void _hideLoadingOverlay() {
    if (!_isLoading) return;
    
    _loadingOverlay?.remove();
    _loadingOverlay = null;
    _isLoading = false;
    AppLogger.debug('Loading overlay hidden', component: 'SmartLoadingNavigation');
  }
}

/// Loading overlay widget
class _LoadingOverlay extends StatefulWidget {
  final String text;
  
  const _LoadingOverlay({required this.text});
  
  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}