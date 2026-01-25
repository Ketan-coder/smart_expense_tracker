import 'dart:ui';
import 'package:expense_tracker/services/progress_calendar_service.dart';
import 'package:expense_tracker/services/wallpaper_generator_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../core/app_constants.dart';
import '../data/model/daily_progress.dart';
import '../data/model/expense.dart';
import '../data/model/income.dart';
import '../data/model/goal.dart';
import '../data/model/habit.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('🌙 Midnight wallpaper update started at ${DateTime.now()}');

      // 1. Initialize Hive and register ALL adapters
      await Hive.initFlutter();

      // Register all adapters
      if (!Hive.isAdapterRegistered(DailyProgressAdapter().typeId)) {
        Hive.registerAdapter(DailyProgressAdapter());
      }
      if (!Hive.isAdapterRegistered(ExpenseAdapter().typeId)) {
        Hive.registerAdapter(ExpenseAdapter());
      }
      if (!Hive.isAdapterRegistered(IncomeAdapter().typeId)) {
        Hive.registerAdapter(IncomeAdapter());
      }
      if (!Hive.isAdapterRegistered(GoalAdapter().typeId)) {
        Hive.registerAdapter(GoalAdapter());
      }
      if (!Hive.isAdapterRegistered(HabitAdapter().typeId)) {
        Hive.registerAdapter(HabitAdapter());
      }

      // Open ALL required boxes
      await Hive.openBox<DailyProgress>(AppConstants.dailyProgress);
      await Hive.openBox<Expense>(AppConstants.expenses);
      await Hive.openBox<Income>(AppConstants.incomes);
      await Hive.openBox<Goal>(AppConstants.goals);
      await Hive.openBox<Habit>(AppConstants.habits);

      debugPrint('✅ All Hive boxes opened successfully');

      // 2. Load User Preferences
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
      if (savedColor != null) {
        themeColor = Color(savedColor);
      }

      debugPrint('📱 Loaded preferences: darkMode=$darkMode, style=$style');

      // 3. Refresh today's progress first
      final service = ProgressCalendarService();
      await service.refreshTodayProgress();

      // 4. Get year progress
      final yearProgress = await service.getYearProgress(DateTime.now().year);
      debugPrint('📊 Loaded ${yearProgress.length} days of progress');

      // 5. Generate wallpaper
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

      debugPrint('🖼️ Wallpaper generated: ${wallpaperFile.path}');

      // 6. Set wallpaper
      final success = await wallpaperService.setAsLockScreen(wallpaperFile);

      if (success) {
        debugPrint('✅ Wallpaper updated successfully at ${DateTime.now()}');
      } else {
        debugPrint('⚠️ Wallpaper set might have failed');
      }

      // Close boxes to free memory
      await Hive.close();

      return Future.value(true);
    } catch (e, stackTrace) {
      debugPrint('❌ Wallpaper update failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return Future.value(false);
    }
  });
}

class WallpaperSchedulerService {
  static final WallpaperSchedulerService _instance = WallpaperSchedulerService._internal();
  factory WallpaperSchedulerService() => _instance;
  WallpaperSchedulerService._internal();

  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // ✅ Set to true for debugging
    );
    debugPrint('✅ Workmanager initialized');
  }

  Future<void> scheduleDailyUpdate() async {
    // Cancel any existing tasks first
    await Workmanager().cancelByUniqueName('wallpaper_update');

    final nextMidnight = _getDurationUntilMidnight();
    debugPrint('⏰ Next wallpaper update in: ${nextMidnight.inHours}h ${nextMidnight.inMinutes % 60}m');

    await Workmanager().registerPeriodicTask(
      'wallpaper_update',
      'wallpaperUpdateTask',
      frequency: const Duration(hours: 24),
      initialDelay: nextMidnight,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false, // ✅ Changed to false so it runs even on low battery
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    debugPrint('✅ Daily wallpaper update scheduled for midnight');
  }

  // ✅ Add this for testing
  Future<void> runImmediately() async {
    await Workmanager().registerOneOffTask(
      'wallpaper_update_test',
      'wallpaperUpdateTask',
      initialDelay: const Duration(seconds: 5),
    );
    debugPrint('🧪 Test wallpaper update scheduled in 5 seconds');
  }

  Future<void> cancelScheduledUpdates() async {
    await Workmanager().cancelByUniqueName('wallpaper_update');
    debugPrint('❌ Cancelled scheduled wallpaper updates');
  }

  Duration _getDurationUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    return midnight.difference(now);
  }
}