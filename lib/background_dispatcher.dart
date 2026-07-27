// lib/background_dispatcher.dart

import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'core/app_constants.dart';
import 'data/model/daily_progress.dart';
import 'data/model/expense.dart';
import 'data/model/income.dart';
import 'data/model/goal.dart';
import 'data/model/habit.dart';
import 'services/progress_calendar_service.dart';
import 'services/wallpaper_generator_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // NO debugPrint here — use print() in background isolates
      print('🌙 Task started: $task at ${DateTime.now()}');

      // ✅ Debug notification — shows immediately when task starts
      await _showDebugNotification(
        id: 9001,
        title: '🌙 Wallpaper Task Started',
        body: 'Task: $task | Time: ${DateTime.now().toString().substring(0, 16)}',
      );

      await Hive.initFlutter();

      void registerIfNeeded<T>(TypeAdapter<T> adapter) {
        if (!Hive.isAdapterRegistered(adapter.typeId)) {
          Hive.registerAdapter(adapter);
        }
      }

      registerIfNeeded(DailyProgressAdapter());
      registerIfNeeded(ExpenseAdapter());
      registerIfNeeded(IncomeAdapter());
      registerIfNeeded(GoalAdapter());
      registerIfNeeded(HabitAdapter());

      await Hive.openBox<DailyProgress>(AppConstants.dailyProgress);
      await Hive.openBox<Expense>(AppConstants.expenses);
      await Hive.openBox<Income>(AppConstants.incomes);
      await Hive.openBox<Goal>(AppConstants.goals);
      await Hive.openBox<Habit>(AppConstants.habits);

      print('✅ Hive initialized in background');

      final prefs = await SharedPreferences.getInstance();
      final bool darkMode = prefs.getBool('wp_dark') ?? true;
      final bool useStatusColors = prefs.getBool('wp_colors') ?? false;
      final int styleIndex = prefs.getInt('wp_style') ?? 0;
      final WallpaperStyle style = WallpaperStyle.values[styleIndex];
      final double dotScale = prefs.getDouble('wp_scale') ?? 1.0;
      final double verticalOffset = prefs.getDouble('wp_offset') ?? 0.45;
      final double gridWidth = prefs.getDouble('wp_width') ?? 0.8;
      final double spacing = prefs.getDouble('wp_spacing') ?? 1.0;

      Color? themeColor;
      final int? savedColor = prefs.getInt('wp_theme_color');
      if (savedColor != null) themeColor = Color(savedColor);

      final calendarService = ProgressCalendarService();
      await calendarService.refreshTodayProgress();
      final yearProgress = await calendarService.getYearProgress(DateTime.now().year);

      final wallpaperService = WallpaperGeneratorService();
      final wallpaperFile = await wallpaperService.generateProgressWallpaper(
        yearProgress: yearProgress,
        size: const Size(1080, 2400),
        style: style,
        darkMode: darkMode,
        useStatusColors: useStatusColors,
        themeColor: themeColor,
        dotScale: dotScale,
        verticalOffset: verticalOffset,
        gridWidthFactor: gridWidth,
        spacingFactor: spacing,
      );

      final success = await wallpaperService.setAsLockScreen(wallpaperFile);

      if (success) {
        await prefs.setString('last_wallpaper_update', DateTime.now().toIso8601String());
        print('✅ Background wallpaper update successful');
      }

      // ✅ Notification on completion
      await _showDebugNotification(
        id: 9002,
        title: success ? '✅ Wallpaper Updated!' : '❌ Wallpaper Failed',
        body: 'Finished at ${DateTime.now().toString().substring(0, 16)}',
      );

      await Hive.close();
      return success;

    } catch (e, stack) {
      print('❌ Background task crashed: $e\n$stack');
      return false;
    }
  });
}

// Minimal notification helper for background isolate
// (can't use your full NotificationService here — wrong isolate)
Future<void> _showDebugNotification({
  required int id,
  required String title,
  required String body,
}) async {
  try {
    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    await plugin.initialize(
      const InitializationSettings(android: initSettings),
    );

    await plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'wallpaper_debug',
          'Wallpaper Debug',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  } catch (e) {
    print('Notification failed: $e');
  }
}