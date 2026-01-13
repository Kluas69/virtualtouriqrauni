// lib/core/responsive/adaptive_layout.dart
/// Professional adaptive layout system for all screen sizes
/// Handles responsive design with performance optimization

import 'package:flutter/material.dart';
import 'package:virtualtouriu/core/performance/performance_monitor.dart';
import 'package:virtualtouriu/core/assets/asset_manager.dart';

/// Screen size categories with precise breakpoints
enum ScreenSize {
  mobile,    // < 600px
  tablet,    // 600px - 1024px
  desktop,   // 1024px - 1440px
  ultrawide, // > 1440px
}

/// Device orientation
enum DeviceOrientation {
  portrait,
  landscape,
}

/// Adaptive layout configuration
class AdaptiveConfig {
  final ScreenSize screenSize;
  final DeviceOrientation orientation;
  final double width;
  final double height;
  final double aspectRatio;
  final bool isTouch;
  final double pixelRatio;

  const AdaptiveConfig({
    required this.screenSize,
    required this.orientation,
    required this.width,
    required this.height,
    required this.aspectRatio,
    required this.isTouch,
    required this.pixelRatio,
  });

  /// Check if device is mobile
  bool get isMobile => screenSize == ScreenSize.mobile;
  
  /// Check if device is tablet
  bool get isTablet => screenSize == ScreenSize.tablet;
  
  /// Check if device is desktop
  bool get isDesktop => screenSize == ScreenSize.desktop || screenSize == ScreenSize.ultrawide;
  
  /// Check if device is in portrait mode
  bool get isPortrait => orientation == DeviceOrientation.portrait;
  
  /// Check if device is in landscape mode
  bool get isLandscape => orientation == DeviceOrientation.landscape;
  
  /// Get optimal padding for current screen
  EdgeInsets get screenPadding {
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
      case ScreenSize.ultrawide:
        return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
  }
  
  /// Get optimal content width
  double get contentWidth {
    switch (screenSize) {
      case ScreenSize.mobile:
        return width * 0.95;
      case ScreenSize.tablet:
        return width * 0.90;
      case ScreenSize.desktop:
        return (width * 0.85).clamp(800, 1200);
      case ScreenSize.ultrawide:
        return (width * 0.80).clamp(1000, 1400);
    }
  }
  
  /// Get grid columns for current screen
  int get gridColumns {
    switch (screenSize) {
      case ScreenSize.mobile:
        return isPortrait ? 1 : 2;
      case ScreenSize.tablet:
        return isPortrait ? 2 : 3;
      case ScreenSize.desktop:
        return 4;
      case ScreenSize.ultrawide:
        return 5;
    }
  }
}

/// Adaptive layout builder
class AdaptiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, AdaptiveConfig config) builder;
  final bool enablePerformanceOptimization;

  const AdaptiveLayout({
    Key? key,
    required this.builder,
    this.enablePerformanceOptimization = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final config = _createAdaptiveConfig(context, constraints);
        
        if (enablePerformanceOptimization) {
          return RepaintBoundary(
            child: builder(context, config),
          );
        }
        
        return builder(context, config);
      },
    );
  }

  AdaptiveConfig _createAdaptiveConfig(BuildContext context, BoxConstraints constraints) {
    final mediaQuery = MediaQuery.of(context);
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    
    // Determine screen size
    final screenSize = _getScreenSize(width);
    
    // Determine orientation
    final orientation = width > height 
        ? DeviceOrientation.landscape 
        : DeviceOrientation.portrait;
    
    return AdaptiveConfig(
      screenSize: screenSize,
      orientation: orientation,
      width: width,
      height: height,
      aspectRatio: width / height,
      isTouch: _isTouchDevice(context),
      pixelRatio: mediaQuery.devicePixelRatio,
    );
  }

  ScreenSize _getScreenSize(double width) {
    if (width < 600) return ScreenSize.mobile;
    if (width < 1024) return ScreenSize.tablet;
    if (width < 1440) return ScreenSize.desktop;
    return ScreenSize.ultrawide;
  }

  bool _isTouchDevice(BuildContext context) {
    // Simple heuristic: assume mobile and tablet are touch devices
    final width = MediaQuery.of(context).size.width;
    return width < 1024;
  }
}

/// Responsive spacing utility
class ResponsiveSpacing {
  static double small(AdaptiveConfig config) {
    switch (config.screenSize) {
      case ScreenSize.mobile: return 8.0;
      case ScreenSize.tablet: return 12.0;
      case ScreenSize.desktop: return 16.0;
      case ScreenSize.ultrawide: return 20.0;
    }
  }

  static double medium(AdaptiveConfig config) {
    switch (config.screenSize) {
      case ScreenSize.mobile: return 16.0;
      case ScreenSize.tablet: return 24.0;
      case ScreenSize.desktop: return 32.0;
      case ScreenSize.ultrawide: return 40.0;
    }
  }

  static double large(AdaptiveConfig config) {
    switch (config.screenSize) {
      case ScreenSize.mobile: return 24.0;
      case ScreenSize.tablet: return 32.0;
      case ScreenSize.desktop: return 48.0;
      case ScreenSize.ultrawide: return 64.0;
    }
  }

  static double extraLarge(AdaptiveConfig config) {
    switch (config.screenSize) {
      case ScreenSize.mobile: return 32.0;
      case ScreenSize.tablet: return 48.0;
      case ScreenSize.desktop: return 64.0;
      case ScreenSize.ultrawide: return 80.0;
    }
  }
}

/// Responsive typography
class ResponsiveTypography {
  static double headline1(AdaptiveConfig config) {
    switch (config.screenSize) {
      case ScreenSize.mobile: return 32.0;
      case ScreenSize.tablet: return 48.0;
      case ScreenSize.desktop: return 64.0;
      case ScreenSize.ultrawide: return 72.0;
    }
  }

  static double headline2(AdaptiveConfig config) {
    switch (config.screenSize) {
      case ScreenSize.mobile: return 24.0;
      case ScreenSize.tablet: return 32.0;
      case ScreenSize.desktop: return 48.0;
      case ScreenSize.ultrawide: return 56.0;
    }
  }

  static double headline3(AdaptiveConfig config) {
    switch (config.screenSize) {
      case ScreenSize.mobile: return 20.0;
      case ScreenSize.tablet: return 24.0;
      case ScreenSize.desktop: return 32.0;
      case ScreenSize.ultrawide: return 40.0;
    }
  }

  static double body1(AdaptiveConfig config) {
    switch (config.screenSize) {
      case ScreenSize.mobile: return 14.0;
      case ScreenSize.tablet: return 16.0;
      case ScreenSize.desktop: return 18.0;
      case ScreenSize.ultrawide: return 20.0;
    }
  }

  static double body2(AdaptiveConfig config) {
    switch (config.screenSize) {
      case ScreenSize.mobile: return 12.0;
      case ScreenSize.tablet: return 14.0;
      case ScreenSize.desktop: return 16.0;
      case ScreenSize.ultrawide: return 18.0;
    }
  }

  static double caption(AdaptiveConfig config) {
    switch (config.screenSize) {
      case ScreenSize.mobile: return 10.0;
      case ScreenSize.tablet: return 12.0;
      case ScreenSize.desktop: return 14.0;
      case ScreenSize.ultrawide: return 16.0;
    }
  }
}

/// Adaptive image sizing
class AdaptiveImageSize {
  static Size thumbnail(AdaptiveConfig config) {
    switch (config.screenSize) {
      case ScreenSize.mobile: return const Size(80, 80);
      case ScreenSize.tablet: return const Size(120, 120);
      case ScreenSize.desktop: return const Size(160, 160);
      case ScreenSize.ultrawide: return const Size(200, 200);
    }
  }

  static Size card(AdaptiveConfig config) {
    switch (config.screenSize) {
      case ScreenSize.mobile: return const Size(300, 200);
      case ScreenSize.tablet: return const Size(400, 300);
      case ScreenSize.desktop: return const Size(500, 350);
      case ScreenSize.ultrawide: return const Size(600, 400);
    }
  }

  static Size hero(AdaptiveConfig config) {
    final width = config.contentWidth;
    final height = config.isPortrait ? width * 0.6 : width * 0.4;
    return Size(width, height);
  }
}

/// Performance-optimized responsive widget
abstract class ResponsiveWidget extends StatefulWidget {
  const ResponsiveWidget({Key? key}) : super(key: key);
}

abstract class ResponsiveWidgetState<T extends ResponsiveWidget> 
    extends State<T> with PerformanceOptimizedWidget {
  
  AdaptiveConfig? _currentConfig;
  
  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      builder: (context, config) {
        // Cache config to avoid rebuilds
        if (_currentConfig?.width != config.width || 
            _currentConfig?.height != config.height) {
          _currentConfig = config;
          onConfigChanged(config);
        }
        
        return buildResponsive(context, config);
      },
    );
  }

  /// Override this method to build responsive UI
  Widget buildResponsive(BuildContext context, AdaptiveConfig config);
  
  /// Called when adaptive configuration changes
  void onConfigChanged(AdaptiveConfig config) {}
  
  /// Get current adaptive configuration
  AdaptiveConfig? get currentConfig => _currentConfig;
}

/// Responsive grid widget
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? forceColumns;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.forceColumns,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      builder: (context, config) {
        final columns = forceColumns ?? config.gridColumns;
        
        return Padding(
          padding: padding ?? config.screenPadding,
          child: Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: children.map((child) {
              final itemWidth = (config.contentWidth - (spacing * (columns - 1))) / columns;
              return SizedBox(
                width: itemWidth,
                child: RepaintBoundary(child: child),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// Responsive container with adaptive sizing
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final double? maxWidth;
  final bool centerContent;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.maxWidth,
    this.centerContent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      builder: (context, config) {
        Widget content = Container(
          width: maxWidth ?? config.contentWidth,
          padding: padding ?? config.screenPadding,
          margin: margin,
          decoration: decoration,
          child: child,
        );

        if (centerContent) {
          content = Center(child: content);
        }

        return content;
      },
    );
  }
}

/// Responsive text widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double Function(AdaptiveConfig)? fontSizeBuilder;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSizeBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      builder: (context, config) {
        final fontSize = fontSizeBuilder?.call(config) ?? ResponsiveTypography.body1(config);
        
        return Text(
          text,
          style: (style ?? const TextStyle()).copyWith(fontSize: fontSize),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// Responsive image widget with adaptive sizing
class ResponsiveImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final Size Function(AdaptiveConfig)? sizeBuilder;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ResponsiveImage({
    Key? key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.sizeBuilder,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      builder: (context, config) {
        final size = sizeBuilder?.call(config) ?? AdaptiveImageSize.card(config);
        
        return OptimizedImage(
          path: imagePath,
          fit: fit,
          targetSize: Size(size.width, size.height),
          placeholder: placeholder,
          errorWidget: errorWidget,
        );
      },
    );
  }
}