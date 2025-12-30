import 'package:flutter/material.dart';

class ResponsiveImageLoader {
  static Widget loadOptimizedImage({
    required String imagePath,
    required BoxFit fit,
    double? width,
    double? height,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final screenScale = MediaQuery.of(context).devicePixelRatio;

        // Calculate optimal cache dimensions based on device
        final cacheWidth =
            isMobile
                ? (constraints.maxWidth * screenScale * 0.5).toInt()
                : (constraints.maxWidth * screenScale * 0.8).toInt();

        final cacheHeight =
            isMobile
                ? (constraints.maxHeight * screenScale * 0.5).toInt()
                : (constraints.maxHeight * screenScale * 0.8).toInt();

        return Image.asset(
          imagePath,
          fit: fit,
          width: width,
          height: height,
          cacheWidth: cacheWidth.clamp(100, 800),
          cacheHeight: cacheHeight.clamp(100, 800),
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image, size: 48),
            );
          },
          // Enable memory-efficient loading
          isAntiAlias: false,
          filterQuality: isMobile ? FilterQuality.low : FilterQuality.medium,
        );
      },
    );
  }
}
