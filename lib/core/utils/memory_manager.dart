import 'package:flutter/material.dart';

class MemoryManager {
  static void clearImageCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  static void setImageCacheLimits({bool isMobile = false}) {
    if (isMobile) {
      imageCache.maximumSize = 50; // Reduce from default 1000
      imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB instead of 100MB
    }
  }

  static void optimizeForDevice(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    setImageCacheLimits(isMobile: isMobile);

    if (isMobile) {
      // Clear cache periodically on mobile
      Future.delayed(const Duration(minutes: 5), () {
        clearImageCache();
      });
    }
  }
}
