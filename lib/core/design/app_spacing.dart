import 'package:flutter/material.dart';

/// Enhanced spacing system for consistent layout throughout the application
class AppSpacing {
  // Base spacing constants
  static const double sectionVertical = 120.0;
  static const double sectionHorizontal = 64.0;
  static const double cardSpacing = 24.0;
  static const double elementSpacing = 16.0;
  static const double microSpacing = 8.0;
  static const double macroSpacing = 48.0;
  
  // Responsive breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
  
  /// Get responsive vertical spacing based on screen height
  static double getVerticalSpacing(double screenHeight, {double multiplier = 1.0}) {
    final baseSpacing = sectionVertical * multiplier;
    final responsiveMultiplier = (screenHeight / 1080).clamp(0.7, 1.3);
    return baseSpacing * responsiveMultiplier;
  }
  
  /// Get responsive horizontal spacing based on screen width
  static double getHorizontalSpacing(double screenWidth, {double multiplier = 1.0}) {
    final baseSpacing = sectionHorizontal * multiplier;
    if (screenWidth < mobileBreakpoint) {
      return baseSpacing * 0.5; // Reduced spacing on mobile
    } else if (screenWidth < tabletBreakpoint) {
      return baseSpacing * 0.75; // Medium spacing on tablet
    } else {
      return baseSpacing * multiplier; // Full spacing on desktop
    }
  }
  
  /// Get responsive padding for sections
  static EdgeInsets getSectionPadding(Size screenSize) {
    final horizontal = getHorizontalSpacing(screenSize.width);
    final vertical = getVerticalSpacing(screenSize.height, multiplier: 0.6);
    
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }
  
  /// Get responsive padding for cards and components
  static EdgeInsets getCardPadding(Size screenSize) {
    if (screenSize.width < mobileBreakpoint) {
      return const EdgeInsets.all(16.0);
    } else if (screenSize.width < tabletBreakpoint) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }
  
  /// Get spacing between sections
  static double getSectionSpacing(Size screenSize) {
    return getVerticalSpacing(screenSize.height, multiplier: 0.8);
  }
  
  /// Get spacing between elements within a section
  static double getElementSpacing(Size screenSize) {
    if (screenSize.width < mobileBreakpoint) {
      return elementSpacing * 0.75;
    } else {
      return elementSpacing;
    }
  }
  
  /// Get grid spacing for card layouts
  static double getGridSpacing(Size screenSize) {
    if (screenSize.width < mobileBreakpoint) {
      return cardSpacing * 0.75;
    } else if (screenSize.width < tabletBreakpoint) {
      return cardSpacing * 0.875;
    } else {
      return cardSpacing;
    }
  }
  
  /// Get responsive border radius
  static double getBorderRadius(Size screenSize, {double baseRadius = 16.0}) {
    if (screenSize.width < mobileBreakpoint) {
      return baseRadius * 0.75;
    } else {
      return baseRadius;
    }
  }
  
  /// Get responsive padding value
  static double getResponsivePadding(Size screenSize) {
    if (screenSize.width < mobileBreakpoint) {
      return 16.0;
    } else if (screenSize.width < tabletBreakpoint) {
      return 20.0;
    } else {
      return 24.0;
    }
  }
}

/// Extension to make spacing easier to use with MediaQuery
extension SpacingExtension on BuildContext {
  AppSpacing get spacing => AppSpacing();
  
  EdgeInsets get sectionPadding => AppSpacing.getSectionPadding(MediaQuery.of(this).size);
  EdgeInsets get cardPadding => AppSpacing.getCardPadding(MediaQuery.of(this).size);
  double get sectionSpacing => AppSpacing.getSectionSpacing(MediaQuery.of(this).size);
  double get elementSpacing => AppSpacing.getElementSpacing(MediaQuery.of(this).size);
  double get gridSpacing => AppSpacing.getGridSpacing(MediaQuery.of(this).size);
}