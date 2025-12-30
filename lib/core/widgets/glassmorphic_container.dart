import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isDark;
  final Color? backgroundColor;
  final Border? border;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    required this.isDark,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color:
                backgroundColor ??
                (isDark
                    ? Colors.black.withOpacity(0.6)
                    : Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(borderRadius),
            border:
                border ??
                Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
