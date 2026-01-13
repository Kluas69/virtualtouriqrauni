/// AI Analytics Models
/// Data models for analytics system

class AnalyticsEvent {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;

  const AnalyticsEvent({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.userId,
    this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      id: json['id'] as String,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String?,
      sessionId: json['sessionId'] as String?,
    );
  }
}

class AnalyticsSession {
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? userId;
  final Map<String, dynamic> metadata;
  final List<AnalyticsEvent> events;

  const AnalyticsSession({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    this.userId,
    required this.metadata,
    required this.events,
  });

  Duration? get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'userId': userId,
      'metadata': metadata,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  factory AnalyticsSession.fromJson(Map<String, dynamic> json) {
    return AnalyticsSession(
      sessionId: json['sessionId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      userId: json['userId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>,
      events: (json['events'] as List)
          .map((e) => AnalyticsEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AnalyticsInsight {
  final String id;
  final String type;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final DateTime generatedAt;
  final double confidence;

  const AnalyticsInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.data,
    required this.generatedAt,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'data': data,
      'generatedAt': generatedAt.toIso8601String(),
      'confidence': confidence,
    };
  }

  factory AnalyticsInsight.fromJson(Map<String, dynamic> json) {
    return AnalyticsInsight(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      data: json['data'] as Map<String, dynamic>,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}