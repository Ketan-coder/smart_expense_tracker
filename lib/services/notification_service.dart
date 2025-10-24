import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class _PendingNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String channelId;
  final String channelName;
  final String channelDescription;
  bool isShown;

  _PendingNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    this.isShown = false,
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static final List<_PendingNotification> _manualNotifications = [];

  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[INIT] Notification Service already initialized');
      return;
    }

    debugPrint('[INIT] Initializing Notification Service...');

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      debugPrint('[INIT] Timezone set to: ${tz.local}');

      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

      // Initialize notifications plugin
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[NOTIFICATION] Notification tapped: ${response.payload}');
        },
      );

      // Create notification channel FIRST
      await createNotificationChannel();

      // Request permissions
      await requestExactAlarmsPermission();

      _isInitialized = true;
      debugPrint('[INIT] Notification Service initialized successfully');

    } catch (e) {
      debugPrint('[ERROR] Failed to initialize Notification Service: $e');
    }
  }

  static Future<void> createNotificationChannel() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'reminder_channel',
          'Reminders',
          description: 'Channel for reminder notifications',
          importance: Importance.max,
          // priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Create test channel as well
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'test_channel',
          'Test',
          description: 'Test notification channel',
          importance: Importance.max,
          // priority: Priority.high,
        ),
      );

      debugPrint('[CHANNEL] Notification channels created successfully');
    } catch (e) {
      debugPrint('[ERROR] Failed to create notification channel: $e');
    }
  }

  static Future<void> requestExactAlarmsPermission() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestExactAlarmsPermission();
      debugPrint('[PERMISSION] Exact alarms permission granted: $granted');
    } catch (e) {
      debugPrint('[ERROR] Failed to request exact alarms permission: $e');
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_isInitialized) {
      debugPrint('[ERROR] Notification Service not initialized');
      return;
    }

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    if (tzDate.isBefore(now)) {
      debugPrint('[SCHEDULE] Scheduled time is in the past. Showing immediately.');
      await showNotification(id: id, title: title, body: body);
      return;
    }

    debugPrint('[SCHEDULE] Scheduling Notification → ID: $id');
    debugPrint('[SCHEDULE] Title: $title');
    debugPrint('[SCHEDULE] Scheduled for: $tzDate');

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Channel for reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
        ),
        // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'reminder_$id',
      );

      debugPrint('[SCHEDULE] Notification scheduled successfully');

      // Verify scheduling
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      debugPrint('[DEBUG] Total Pending Notifications: ${pending.length}');

    } catch (e) {
      debugPrint('[ERROR] Failed to schedule notification: $e');
      // Fallback: Use manual scheduling
      await scheduleUsingShow(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        channelId: 'reminder_channel',
        channelName: 'Reminders',
      );
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = 'reminder_channel',
    String channelName = 'Reminders',
  }) async {
    if (!_isInitialized) {
      debugPrint('[ERROR] Notification Service not initialized');
      return;
    }

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: 'Channel for notifications',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
        ),
        payload: 'shown_$id',
      );
      debugPrint('[SHOW] Notification shown successfully → ID: $id');
    } catch (e) {
      debugPrint('[ERROR] Failed to show notification: $e');
    }
  }

  static Future<void> scheduleUsingShow({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    required String channelName,
    String channelDescription = 'Channel for scheduled notifications',
    bool showWhen = true,
    bool onGoing = false,
    bool autoCancel = true,
    bool enableVibration = true,
    bool playSound = true,
    Int64List? vibrationPattern,
    List<AndroidNotificationAction>? actions = const [],
  }) async {
    final now = DateTime.now();
    final delay = scheduledDate.difference(now);

    if (delay.isNegative) {
      debugPrint('[SCHEDULE] Scheduled time is in the past. Showing immediately.');
      await showNotification(id: id, title: title, body: body);
      return;
    }

    debugPrint('[SCHEDULE] Manual scheduling - will show in ${delay.inSeconds} seconds');

    // Use Timer for manual scheduling (works in background)
    Timer(delay, () async {
      debugPrint('[SCHEDULE] Showing manually scheduled notification now...');
      await showNotification(id: id, title: title, body: body);
    });
  }

  static Future<void> testImmediateNotification() async {
    debugPrint('[TEST] Showing immediate test notification...');
    await showNotification(
      id: 99,
      title: 'Immediate Test',
      body: 'This should appear instantly 🔔',
      channelId: 'test_channel',
      channelName: 'Test',
    );
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      debugPrint('[CANCEL] Notification ID $id cancelled.');
    } catch (e) {
      debugPrint('[ERROR] Failed to cancel notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('[CANCEL] All notifications cancelled.');
    } catch (e) {
      debugPrint('[ERROR] Failed to cancel all notifications: $e');
    }
  }

  // Call this when app starts to reschedule any missed notifications
  static Future<void> rescheduleMissedNotifications() async {
    debugPrint('[RESCHEDULE] Checking for missed notifications...');
    // Add your logic here to reschedule notifications from your database/local storage
  }
}