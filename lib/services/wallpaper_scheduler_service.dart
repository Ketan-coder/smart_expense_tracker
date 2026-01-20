import 'package:expense_tracker/services/progress_calendar_service.dart';
import 'package:expense_tracker/services/wallpaper_generator_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:workmanager/workmanager.dart';

import '../data/model/daily_progress.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('🌙 Midnight wallpaper update started');

      // Initialize Hive
      await Hive.initFlutter();
      await Hive.openBox<DailyProgress>('daily_progress');

      // Generate new wallpaper
      final service = ProgressCalendarService();
      final yearProgress = await service.getYearProgress(DateTime.now().year);

      final wallpaperService = WallpaperGeneratorService();
      final wallpaperFile = await wallpaperService.generateProgressWallpaper(
        yearProgress: yearProgress,
        size: const Size(1080, 2400), // Adjust to device screen
        darkMode: true,
      );

      // Set as lock screen wallpaper
      await wallpaperService.setAsLockScreen(
        wallpaperFile,
      );

      // Refresh today's progress
      await service.refreshTodayProgress();

      debugPrint('✅ Wallpaper updated successfully');
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Wallpaper update failed: $e');
      return Future.value(false);
    }
  });
}

class WallpaperSchedulerService {
  static final WallpaperSchedulerService _instance =
  WallpaperSchedulerService._internal();
  factory WallpaperSchedulerService() => _instance;
  WallpaperSchedulerService._internal();

  /// Initialize wallpaper scheduler
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Schedule daily wallpaper update at midnight
  Future<void> scheduleDailyUpdate() async {
    await Workmanager().registerPeriodicTask(
      'wallpaper_update',
      'wallpaperUpdateTask',
      frequency: const Duration(hours: 24),
      initialDelay: _getDurationUntilMidnight(),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: true,
      ),
    );

    debugPrint('✅ Daily wallpaper update scheduled');
  }

  /// Cancel scheduled updates
  Future<void> cancelScheduledUpdates() async {
    await Workmanager().cancelByUniqueName('wallpaper_update');
  }

  /// Get duration until next midnight
  Duration _getDurationUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  /// Manual wallpaper update (for testing)
  Future<void> updateWallpaperNow() async {
    try {
      final service = ProgressCalendarService();
      final yearProgress = await service.getYearProgress(DateTime.now().year);

      final wallpaperService = WallpaperGeneratorService();
      final wallpaperFile = await wallpaperService.generateProgressWallpaper(
        yearProgress: yearProgress,
        size: const Size(1080, 2400),
        darkMode: true,
      );

      await wallpaperService.setAsLockScreen(
        wallpaperFile,
      );

      debugPrint('✅ Manual wallpaper update complete');
    } catch (e) {
      debugPrint('❌ Manual update failed: $e');
    }
  }
}