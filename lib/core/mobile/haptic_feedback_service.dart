import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service for managing haptic feedback on mobile devices
class HapticFeedbackService {
  static bool _isSupported = true;
  static bool _isEnabled = true;

  /// Check if haptic feedback is supported on this device
  static bool get isSupported => _isSupported && !kIsWeb;

  /// Check if haptic feedback is currently enabled
  static bool get isEnabled => _isEnabled && isSupported;

  /// Enable or disable haptic feedback
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Light impact feedback - for subtle interactions
  static Future<void> lightImpact() async {
    if (!isEnabled) return;
    
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      _isSupported = false;
    }
  }

  /// Medium impact feedback - for standard interactions
  static Future<void> mediumImpact() async {
    if (!isEnabled) return;
    
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      _isSupported = false;
    }
  }

  /// Heavy impact feedback - for important interactions
  static Future<void> heavyImpact() async {
    if (!isEnabled) return;
    
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      _isSupported = false;
    }
  }

  /// Selection click feedback - for UI selections
  static Future<void> selectionClick() async {
    if (!isEnabled) return;
    
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      _isSupported = false;
    }
  }

  /// Vibrate pattern for game events
  static Future<void> gameEvent({
    required GameEventType type,
  }) async {
    if (!isEnabled) return;

    switch (type) {
      case GameEventType.jump:
        await lightImpact();
        break;
      case GameEventType.interact:
        await mediumImpact();
        break;
      case GameEventType.collision:
        await heavyImpact();
        break;
      case GameEventType.pickup:
        await selectionClick();
        break;
      case GameEventType.error:
        // Double tap for errors
        await heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await heavyImpact();
        break;
      case GameEventType.success:
        // Triple tap for success
        await lightImpact();
        await Future.delayed(const Duration(milliseconds: 50));
        await lightImpact();
        await Future.delayed(const Duration(milliseconds: 50));
        await mediumImpact();
        break;
    }
  }

  /// Test haptic feedback functionality
  static Future<void> testHaptics() async {
    if (!isSupported) return;

    await lightImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await mediumImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await heavyImpact();
  }
}

/// Types of game events for haptic feedback
enum GameEventType {
  jump,
  interact,
  collision,
  pickup,
  error,
  success,
}