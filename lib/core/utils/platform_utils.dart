import 'dart:ui';
import 'package:flutter/material.dart';

class PlatformOptimizedBlur extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;

  const PlatformOptimizedBlur({
    super.key,
    required this.child,
    this.sigmaX = 10,
    this.sigmaY = 10,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Disable expensive blur on mobile
    if (isMobile) {
      return Container(color: Colors.black.withOpacity(0.1), child: child);
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: sigmaX * 0.5, // Reduce blur intensity
          sigmaY: sigmaY * 0.5,
        ),
        child: child,
      ),
    );
  }
}
