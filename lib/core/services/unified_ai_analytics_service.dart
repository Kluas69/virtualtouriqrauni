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
      _databaseService = AIAnalyticsDatab