import 'dart:async';
import 'package:flutter/foundation.dart';
import 'firebase_analytics_service.dart';
import 'ai_analytics_database_service.dart';
import 'ai_analytics_aggregator.dart';
import '../models/ai_analytics_models.dart';
import '../logging/app_logger.dart';

/// Unified AI Analytics Service
/// Provides a single interface for all analytics operations
class UnifiedAIAnalyticsService {
  static UnifiedAIAnalyticsService? _instance;
  factory UnifiedAIAnalyticsService() => _instance ??= UnifiedAIAnalyticsService._internal();
  UnifiedAIAnalyticsService._internal();

  static const String _logComponent = 'UnifiedAIAnalyticsService';
  
  // Service instances
  late FirebaseAnalyticsService _firebaseService;
  late AIAnalyticsDatabaseService _databaseService;
  late AIAnalyticsAggregator _aggregatorService;
  
  bool _isInitialized = false;

  /// Initialize all analytics services
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      AppLogger.info('Initializing Unified AI Analytics Service', component: _logComponent);
      
      // Initialize services in order
      _firebaseService = FirebaseAnalyticsService();
      _databaseService = AIAnalyticsDatabaseService();
      _aggregatorService = AIAnalyticsAggregator();
      
      await _firebaseService.initialize();
      await _databaseService.initialize();
      await _aggregatorService.initialize();
      
      _isInitialized = true;
      AppLogger.info('Unified AI Analytics Service initialized successfully', component: _logComponent);
      
    } catch (e) {
      AppLogger.error('Failed to initialize analytics service: $e', component: _logComponent);
      rethrow;
    }
  }
  
  /// Log an analytics event
  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    if (!_isInitialized) return;
    
    try {
      // Log to Firebase
      await _firebaseService.logEvent(name, parameters);
      
      // Store in local database
      await _databaseService.storeData({
        'event': name,
        'parameters': parameters,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      AppLogger.error('Failed to log analytics event: $e', component: _logComponent);
    }
  }
}