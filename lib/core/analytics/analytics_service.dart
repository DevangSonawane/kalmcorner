import 'package:flutter/foundation.dart';

abstract class AnalyticsService {
  void log(String event, [Map<String, Object?>? params]);
  void setUserId(String? userId);
  void setUserProperties(Map<String, Object?> properties);
}

class NoopAnalytics implements AnalyticsService {
  @override
  void log(String event, [Map<String, Object?>? params]) {
    if (kDebugMode) {
      debugPrint('[Analytics] $event $params');
    }
  }

  @override
  void setUserId(String? userId) {}

  @override
  void setUserProperties(Map<String, Object?> properties) {}
}
