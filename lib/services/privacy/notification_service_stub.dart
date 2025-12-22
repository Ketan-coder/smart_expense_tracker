// ============================================================================
// FILE: lib/services/notification_service_stub.dart
// Web stub for notification service
// ============================================================================
import 'package:flutter/material.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> initialize() async {
    debugPrint('⚠️ Notifications not supported on web');
  }

  static Future<void> cancelAllNotifications() async {
    debugPrint('⚠️ Notifications not supported on web');
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    debugPrint('⚠️ Notifications not supported on web');
  }
}