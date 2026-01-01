import 'package:flutter/material.dart';

/// Utility class for color operations and deprecated API handling
/// 
/// This class provides safe color operations that work across different
/// Flutter versions and handles the transition from deprecated APIs.
class ColorUtils {
  /// Safe color opacity method that uses the new withValues API
  /// while maintaining backward compatibility
  static Color withOpacity(Color color, double opacity) {
    try {
      // Use the new withValues method (Flutter 3.27+)
      return color.withValues(alpha: opacity);
    } catch (e) {
      // Fallback to deprecated withOpacity for older Flutter versions
      // ignore: deprecated_member_use
      return color.withOpacity(opacity);
    }
  }
  
  /// Create a color with alpha value (0.0 to 1.0)
  static Color withAlpha(Color color, double alpha) {
    return withOpacity(color, alpha);
  }
  
  /// Create a semi-transparent version of a color
  static Color transparent(Color color, [double opacity = 0.5]) {
    return withOpacity(color, opacity);
  }
  
  /// Create a lighter version of a color
  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// Create a darker version of a color
  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// Get contrasting text color (black or white) for a background color
  static Color getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
  
  /// Blend two colors together
  static Color blend(Color color1, Color color2, double ratio) {
    return Color.lerp(color1, color2, ratio) ?? color1;
  }
  
  /// Create a gradient-like color between two colors
  static List<Color> createGradient(Color start, Color end, int steps) {
    final colors = <Color>[];
    for (int i = 0; i < steps; i++) {
      final ratio = i / (steps - 1);
      colors.add(blend(start, end, ratio));
    }
    return colors;
  }
  
  /// Get material design color variants
  static MaterialColor createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    
    for (final strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    
    return MaterialColor(color.toARGB32(), swatch);
  }
  
  /// Theme-aware color selection
  static Color adaptiveColor(BuildContext context, Color lightColor, Color darkColor) {
    return Theme.of(context).brightness == Brightness.dark ? darkColor : lightColor;
  }
  
  /// Get platform-appropriate colors
  static Color getPlatformColor(BuildContext context, {
    Color? ios,
    Color? android,
    Color? web,
    Color? fallback,
  }) {
    final theme = Theme.of(context);
    final platform = Theme.of(context).platform;
    
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios ?? fallback ?? theme.primaryColor;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return android ?? fallback ?? theme.primaryColor;
      default:
        return web ?? fallback ?? theme.primaryColor;
    }
  }
}

/// Extension methods for Color class to provide convenient utilities
extension ColorExtensions on Color {
  /// Safe opacity method using ColorUtils
  Color safeWithOpacity(double opacity) => ColorUtils.withOpacity(this, opacity);
  
  /// Get a lighter version of this color
  Color lighter([double amount = 0.1]) => ColorUtils.lighten(this, amount);
  
  /// Get a darker version of this color
  Color darker([double amount = 0.1]) => ColorUtils.darken(this, amount);
  
  /// Get contrasting text color for this background color
  Color get contrastingTextColor => ColorUtils.getContrastingTextColor(this);
  
  /// Check if this color is considered light
  bool get isLight => computeLuminance() > 0.5;
  
  /// Check if this color is considered dark
  bool get isDark => !isLight;
  
  /// Convert to hex string
  String toHex() => '#${toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
}

/// Predefined color palettes for consistent theming
class AppColorPalettes {
  static const List<Color> blue = [
    Color(0xFF0D47A1),
    Color(0xFF1565C0),
    Color(0xFF1976D2),
    Color(0xFF1E88E5),
    Color(0xFF2196F3),
    Color(0xFF42A5F5),
    Color(0xFF64B5F6),
    Color(0xFF90CAF9),
    Color(0xFFBBDEFB),
    Color(0xFFE3F2FD),
  ];
  
  static const List<Color> green = [
    Color(0xFF1B5E20),
    Color(0xFF2E7D32),
    Color(0xFF388E3C),
    Color(0xFF43A047),
    Color(0xFF4CAF50),
    Color(0xFF66BB6A),
    Color(0xFF81C784),
    Color(0xFFA5D6A7),
    Color(0xFFC8E6C9),
    Color(0xFFE8F5E8),
  ];
  
  static const List<Color> orange = [
    Color(0xFFE65100),
    Color(0xFFEF6C00),
    Color(0xFFF57C00),
    Color(0xFFFF8F00),
    Color(0xFFFF9800),
    Color(0xFFFFB74D),
    Color(0xFFFFCC02),
    Color(0xFFFFE082),
    Color(0xFFFFF3C4),
    Color(0xFFFFFDE7),
  ];
  
  /// Get a color from a palette by index
  static Color getColor(List<Color> palette, int index) {
    return palette[index.clamp(0, palette.length - 1)];
  }
  
  /// Get a random color from a palette
  static Color getRandomColor(List<Color> palette) {
    return palette[(DateTime.now().millisecondsSinceEpoch % palette.length)];
  }
}