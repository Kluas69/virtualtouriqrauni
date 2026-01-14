import 'package:flutter/material.dart';
import 'package:virtualtouriu/core/animation/clean_animations.dart';
import 'package:virtualtouriu/core/utils/image_utils.dart';

/// Enhanced image loader with progressive loading, fade-in animations,
/// and memory-efficient caching
class OptimizedImageLoader extends StatefulWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableFadeIn;
  final Duration fadeInDuration;
  final BorderRadius? borderRadius;

  const OptimizedImageLoader({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.enableFadeIn = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.borderRadius,
  });

  /// Factory constructor for responsive loading
  factory OptimizedImageLoader.responsive({
    required String imagePath,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
    bool enableFadeIn = true,
    Duration fadeInDuration = const Duration(milliseconds: 300),
    BorderRadius? borderRadius,
  }) {
    return OptimizedImageLoader(
      imagePath: imagePath,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder,
      errorWidget: errorWidget,
      enableFadeIn: enableFadeIn,
      fadeInDuration: fadeInDuration,
      borderRadius: borderRadius,
    );
  }

  @override
  State<OptimizedImageLoader> createState() => _OptimizedImageLoaderState();
}

class _OptimizedImageLoaderState extends State<OptimizedImageLoader>
    with SingleTickerProviderStateMixin {
  bool _isLoaded = false;
  bool _hasError = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onImageLoaded() {
    if (mounted && !_isLoaded) {
      setState(() => _isLoaded = true);
      if (widget.enableFadeIn) {
        _fadeController.forward();
      }
    }
  }

  void _onImageError() {
    if (mounted && !_hasError) {
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final screenScale = MediaQuery.of(context).devicePixelRatio;

        // Calculate optimal cache dimensions
        final cacheWidth = _calculateCacheWidth(
          constraints.maxWidth,
          screenScale,
          isMobile,
        );
        final cacheHeight = _calculateCacheHeight(
          constraints.maxHeight,
          screenScale,
          isMobile,
        );

        Widget imageWidget = _buildImageWidget(
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          isMobile: isMobile,
        );

        // Apply border radius if specified
        if (widget.borderRadius != null) {
          imageWidget = ClipRRect(
            borderRadius: widget.borderRadius!,
            child: imageWidget,
          );
        }

        return imageWidget;
      },
    );
  }

  Widget _buildImageWidget({
    required int cacheWidth,
    required int cacheHeight,
    required bool isMobile,
  }) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Placeholder
        if (!_isLoaded) _buildPlaceholder(),
        
        // Main image
        Image.asset(
          widget.imagePath,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          isAntiAlias: false,
          filterQuality: isMobile ? FilterQuality.low : FilterQuality.medium,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              _onImageLoaded();
              
              if (widget.enableFadeIn && !wasSynchronouslyLoaded) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: child,
                );
              }
              return child;
            }
            return _buildPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) {
            _onImageError();
            return _buildErrorWidget();
          },
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: CleanAnimations.shimmer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: widget.borderRadius,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: widget.borderRadius,
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateCacheWidth(double maxWidth, double screenScale, bool isMobile) {
    final baseWidth = widget.width ?? maxWidth;
    final scaledWidth = baseWidth * screenScale;
    
    if (isMobile) {
      return (scaledWidth * 0.5).toInt().clamp(100, 600);
    } else {
      return (scaledWidth * 0.8).toInt().clamp(200, 1200);
    }
  }

  int _calculateCacheHeight(double maxHeight, double screenScale, bool isMobile) {
    final baseHeight = widget.height ?? maxHeight;
    final scaledHeight = baseHeight * screenScale;
    
    if (isMobile) {
      return (scaledHeight * 0.5).toInt().clamp(100, 600);
    } else {
      return (scaledHeight * 0.8).toInt().clamp(200, 1200);
    }
  }
}

/// Enhanced version of the existing ResponsiveImageLoader for backward compatibility
extension ResponsiveImageLoaderExtension on ResponsiveImageLoader {
  /// Load optimized image with enhanced features
  static Widget loadOptimizedImageEnhanced({
    required String imagePath,
    required BoxFit fit,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
    bool enableFadeIn = true,
    BorderRadius? borderRadius,
  }) {
    return OptimizedImageLoader(
      imagePath: imagePath,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder,
      errorWidget: errorWidget,
      enableFadeIn: enableFadeIn,
      borderRadius: borderRadius,
    );
  }
}