import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logging/app_logger.dart';

/// Mobile game controller for PUBG-style landscape gaming experience
class MobileGameController {
  static MobileGameController? _instance;
  factory MobileGameController() => _instance ??= MobileGameController._internal();
  MobileGameController._internal();
  
  static MobileGameController get instance => _instance ??= MobileGameController._internal();
  
  bool _isLandscapeMode = false;
  bool _isFullscreen = false;
  
  /// Enable landscape mode for mobile gaming
  Future<void> enableLandscapeMode() async {
    try {
      AppLogger.info('Enabling landscape mode for mobile gaming', component: 'MobileGameController');
      
      // Force landscape orientation
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      // Enable fullscreen mode
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      
      _isLandscapeMode = true;
      _isFullscreen = true;
      
      AppLogger.info('Landscape mode enabled successfully', component: 'MobileGameController');
    } catch (e) {
      AppLogger.error('Failed to enable landscape mode', 
        component: 'MobileGameController', 
        error: e);
    }
  }
  
  /// Disable landscape mode and restore normal orientation
  Future<void> disableLandscapeMode() async {
    try {
      AppLogger.info('Disabling landscape mode', component: 'MobileGameController');
      
      // Restore all orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      // Restore system UI
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      
      _isLandscapeMode = false;
      _isFullscreen = false;
      
      AppLogger.info('Landscape mode disabled successfully', component: 'MobileGameController');
    } catch (e) {
      AppLogger.error('Failed to disable landscape mode', 
        component: 'MobileGameController', 
        error: e);
    }
  }
  
  /// Toggle fullscreen mode
  Future<void> toggleFullscreen() async {
    try {
      if (_isFullscreen) {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
        _isFullscreen = false;
        AppLogger.info('Fullscreen disabled', component: 'MobileGameController');
      } else {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky,
          overlays: [],
        );
        _isFullscreen = true;
        AppLogger.info('Fullscreen enabled', component: 'MobileGameController');
      }
    } catch (e) {
      AppLogger.error('Failed to toggle fullscreen', 
        component: 'MobileGameController', 
        error: e);
    }
  }
  
  /// Enable fullscreen + landscape mode for mobile gaming (like mobile games)
  Future<void> enableFullscreenLandscapeMode() async {
    try {
      AppLogger.info('Enabling fullscreen + landscape mode for mobile gaming', component: 'MobileGameController');
      
      // Force landscape orientation
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      // Enable immersive fullscreen mode (hide all system UI)
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      
      _isLandscapeMode = true;
      _isFullscreen = true;
      
      AppLogger.info('Fullscreen + landscape mode enabled successfully', component: 'MobileGameController');
    } catch (e) {
      AppLogger.error('Failed to enable fullscreen + landscape mode', 
        component: 'MobileGameController', 
        error: e);
    }
  }
  
  /// Exit fullscreen + landscape mode and restore normal mode
  Future<void> exitFullscreenLandscapeMode() async {
    try {
      AppLogger.info('Exiting fullscreen + landscape mode', component: 'MobileGameController');
      
      // Restore all orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      // Restore system UI
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      
      _isLandscapeMode = false;
      _isFullscreen = false;
      
      AppLogger.info('Fullscreen + landscape mode exited successfully', component: 'MobileGameController');
    } catch (e) {
      AppLogger.error('Failed to exit fullscreen + landscape mode', 
        component: 'MobileGameController', 
        error: e);
    }
  }
  
  /// Check if device is in landscape mode
  bool get isLandscapeMode => _isLandscapeMode;
  
  /// Check if device is in fullscreen mode
  bool get isFullscreen => _isFullscreen;
  
  /// Get optimal button size for mobile gaming
  double getOptimalButtonSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    
    if (isTablet) {
      return 70.0; // Larger buttons for tablets
    } else {
      return 60.0; // Standard size for phones
    }
  }
  
  /// Get optimal text size for mobile gaming UI
  double getOptimalTextSize(BuildContext context, {bool isTitle = false}) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    
    if (isTitle) {
      return isTablet ? 24.0 : 18.0;
    } else {
      return isTablet ? 16.0 : 14.0;
    }
  }
  
  /// Get optimal padding for mobile gaming UI
  EdgeInsets getOptimalPadding(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    
    if (isTablet) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }
  
  /// Provide haptic feedback for mobile gaming
  Future<void> provideFeedback({HapticFeedbackType type = HapticFeedbackType.lightImpact}) async {
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      AppLogger.warning('Haptic feedback not available', 
        component: 'MobileGameController', 
        error: e);
    }
  }
}

/// Enum for haptic feedback types
enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
}