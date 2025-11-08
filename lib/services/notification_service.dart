import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum NotificationActionType {
  openHome,
  openExpense,
  openIncome,
  openReports,
  openGoal,
  openHabit,
}


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

  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

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
          _handleNotificationClick(response.payload);
        },
      );


      // Create notification channel FIRST
      await createNotificationChannel();

      // Request notification permissions (not exact alarms)
      await requestNotificationPermission();

      _isInitialized = true;
      debugPrint('[INIT] Notification Service initialized successfully');
    } catch (e) {
      debugPrint('[ERROR] Failed to initialize Notification Service: $e');
    }
  }

  static void _handleNotificationClick(String? payload) {
    if (payload == null) return;

    // Delay a bit so navigation happens after context is ready
    Future.delayed(const Duration(milliseconds: 300), () {
      switch (payload) {
        case 'open_expense_page':
          _navigatorKey.currentState?.pushNamed('/expense');
          break;
        case 'open_income_page':
          _navigatorKey.currentState?.pushNamed('/income');
          break;
        case 'open_reports_page':
          _navigatorKey.currentState?.pushNamed('/reports');
          break;
        case 'open_goal_page':
          _navigatorKey.currentState?.pushNamed('/goal');
          break;
        case 'open_habit_page':
          _navigatorKey.currentState?.pushNamed('/habit');
          break;
        case 'open_home_page':
          _navigatorKey.currentState?.pushNamed('/home');
          break;
        default:
          _navigatorKey.currentState?.pushNamed('/home');
          break;
      }
    });
  }


  static Future<void> createNotificationChannel() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'reminder_channel',
          'Reminders',
          description: 'Channel for reminder notifications',
          importance: Importance.max,
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
        ),
      );

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'habit_detection',
          'Habit Detection',
          description: 'Notifications about detected habit patterns',
          importance: Importance.high,
          enableVibration: true,
        ),
      );

      // Add these to your existing createNotificationChannel method
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'wallet_alerts',
          'Wallet Alerts',
          description: 'Notifications for wallet balance alerts',
          importance: Importance.high,
          enableVibration: true,
        ),
      );

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'transaction_alerts',
          'Transaction Alerts',
          description: 'Notifications for large transactions',
          importance: Importance.defaultImportance,
          enableVibration: true,
        ),
      );

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'budget_alerts',
          'Budget Alerts',
          description: 'Notifications for budget tracking',
          importance: Importance.high,
          enableVibration: true,
        ),
      );

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'habit_alerts',
          'Habit Alerts',
          description: 'Notifications for habit streaks and patterns',
          importance: Importance.defaultImportance,
          enableVibration: true,
        ),
      );

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'savings_alerts',
          'Savings Alerts',
          description: 'Notifications for savings milestones',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'summary_alerts',
          'Financial Summary',
          description: 'Daily and weekly financial summaries',
          importance: Importance.low,
          enableVibration: false,
        ),
      );

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'pattern_alerts',
          'Spending Patterns',
          description: 'Notifications about spending patterns',
          importance: Importance.defaultImportance,
          enableVibration: true,
        ),
      );

      debugPrint('[CHANNEL] Notification channels created successfully');
    } catch (e) {
      debugPrint('[ERROR] Failed to create notification channel: $e');
    }
  }

  // NEW: Request notification permission instead of exact alarms
  static Future<bool> requestNotificationPermission() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // For Android 13+ (API 33+), we need to request notification permission
      final bool? permissionGranted = await androidImplementation
          ?.requestNotificationsPermission();

      debugPrint(
        '[PERMISSION] Notification permission granted: $permissionGranted',
      );
      return permissionGranted ?? false;
    } catch (e) {
      debugPrint('[ERROR] Failed to request notification permission: $e');
      return false;
    }
  }

  // Keep this method but don't call it automatically
  static Future<bool> requestExactAlarmsPermission() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final bool? granted = await androidImplementation
          ?.requestExactAlarmsPermission();
      debugPrint('[PERMISSION] Exact alarms permission granted: $granted');
      return granted ?? false;
    } catch (e) {
      debugPrint('[ERROR] Failed to request exact alarms permission: $e');
      return false;
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String payload = 'open_home_page',
  }) async {
    if (!_isInitialized) {
      debugPrint('[ERROR] Notification Service not initialized');
      return;
    }

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    if (tzDate.isBefore(now)) {
      debugPrint(
        '[SCHEDULE] Scheduled time is in the past. Showing immediately.',
      );
      await showNotification(id: id, title: title, body: body, payload: payload);
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
    String payload = 'open_expense_page',
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
        payload: payload ?? 'shown_$id',
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
      debugPrint(
        '[SCHEDULE] Scheduled time is in the past. Showing immediately.',
      );
      await showNotification(id: id, title: title, body: body);
      return;
    }

    debugPrint(
      '[SCHEDULE] Manual scheduling - will show in ${delay.inSeconds} seconds',
    );

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

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final bool? enabled = await androidImplementation
          ?.areNotificationsEnabled();
      return enabled ?? false;
    } catch (e) {
      debugPrint('[ERROR] Failed to check notification status: $e');
      return false;
    }
  }

  // Call this when app starts to reschedule any missed notifications
  static Future<void> rescheduleMissedNotifications() async {
    debugPrint('[RESCHEDULE] Checking for missed notifications...');
    // Add your logic here to reschedule notifications from your database/local storage
  }
}
