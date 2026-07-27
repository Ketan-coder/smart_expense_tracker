import 'dart:ui';
import 'package:expense_tracker/services/progress_calendar_service.dart';
import 'package:expense_tracker/services/wallpaper_generator_service.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('🌙 ========================================');
      debugPrint('🌙 Wallpaper update started at ${DateTime.now()}');
      debugPrint('🌙 Task: $task');
      debugPrint('🌙 ========================================');

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
      debugPrint('🖼️ Generating wallpaper...');
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

      // Verify file exists
      final exists = await wallpaperFile.exists();
      final size = exists ? await wallpaperFile.length() : 0;
      debugPrint('📁 File exists: $exists, Size: ${(size / 1024).toStringAsFixed(2)} KB');

      // 6. Set wallpaper
      debugPrint('📱 Setting wallpaper...');
      final success = await wallpaperService.setAsLockScreen(wallpaperFile);

      if (success) {
        debugPrint('✅ ========================================');
        debugPrint('✅ Wallpaper updated successfully!');
        debugPrint('✅ Time: ${DateTime.now()}');
        debugPrint('✅ ========================================');

        // Save last update time
        await prefs.setString('last_wallpaper_update', DateTime.now().toIso8601String());
      } else {
        debugPrint('❌ ========================================');
        debugPrint('❌ Wallpaper setting failed');
        debugPrint('❌ ========================================');
      }

      // Close boxes to free memory
      await Hive.close();

      return Future.value(success);
    } catch (e, stackTrace) {
      debugPrint('❌ ========================================');
      debugPrint('❌ Wallpaper update CRASHED: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('❌ ========================================');
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
      isInDebugMode: kDebugMode,
    );
    debugPrint('✅ Workmanager initialized');
  }

  Future<void> scheduleDailyUpdate() async {
    // Cancel any existing tasks first
    // await Workmanager().cancelAll();

    final nextMidnight = _getDurationUntilMidnight();
    debugPrint('⏰ Next wallpaper update in: ${nextMidnight.inHours}h ${nextMidnight.inMinutes % 60}m');

    // Schedule daily update at midnight
    await Workmanager().registerPeriodicTask(
      'wallpaper_daily_update',
      'wallpaperDailyTask',
      frequency: const Duration(hours: 24),
      initialDelay: nextMidnight,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );

    debugPrint('✅ Daily wallpaper update scheduled for midnight');

    // Also schedule a backup update every 6 hours in case midnight fails
    // await Workmanager().registerPeriodicTask(
    //   'wallpaper_backup_update',
    //   'wallpaperBackupTask',
    //   frequency: const Duration(hours: 6),
    //   constraints: Constraints(
    //     networkType: NetworkType.notRequired,
    //     requiresBatteryNotLow: false,
    //   ),
    //   existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    // );
    //
    // debugPrint('✅ Backup wallpaper update scheduled (every 6 hours)');
  }

  // In WallpaperSchedulerService, add this:
  Future<bool> runDirectUpdate() async {
    try {
      debugPrint('🖼️ Running direct wallpaper update...');

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
        debugPrint('✅ Direct wallpaper update successful');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Direct wallpaper update failed: $e');
      return false;
    }
  }

  Future<void> runCatchUpIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdateStr = prefs.getString('last_wallpaper_update');

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    if (lastUpdateStr == null) {
      debugPrint('🔄 No previous update found, running directly...');
      await runDirectUpdate(); // ← direct, not via Workmanager
      return;
    }

    final lastUpdate = DateTime.parse(lastUpdateStr);
    final lastUpdateDay = DateTime(lastUpdate.year, lastUpdate.month, lastUpdate.day);

    if (lastUpdateDay.isBefore(today)) {
      final daysLate = today.difference(lastUpdateDay).inDays;
      debugPrint('🔄 Wallpaper is $daysLate day(s) outdated, running directly...');
      await runDirectUpdate(); // ← direct, not via Workmanager
    } else {
      debugPrint('✅ Wallpaper already up to date');
    }
  }

  Future<void> runImmediately() async {
    await Workmanager().registerOneOffTask(
      'wallpaper_manual_update',
      'wallpaperManualTask',
      initialDelay: const Duration(seconds: 3),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
      ),
    );
    debugPrint('🧪 Manual wallpaper update scheduled in 3 seconds');
  }

  Future<void> cancelScheduledUpdates() async {
    await Workmanager().cancelAll();
    debugPrint('❌ Cancelled all scheduled wallpaper updates');
  }

  Duration _getDurationUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1, 0, 5, 0); // 5 minutes after midnight for safety
    return midnight.difference(now);
  }

  // Check when last update happened
  Future<DateTime?> getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString('last_wallpaper_update');
    if (lastUpdate != null) {
      return DateTime.parse(lastUpdate);
    }
    return null;
  }
}