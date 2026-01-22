import 'dart:ui';
import 'package:expense_tracker/services/progress_calendar_service.dart';
import 'package:expense_tracker/services/wallpaper_generator_service.dart';
import 'package:flutter/material.dart'; // Needed for Color
import 'package:hive_ce_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../core/app_constants.dart';
import '../data/model/daily_progress.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('🌙 Midnight wallpaper update started');

      // 1. Initialize DB
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(DailyProgressAdapter().typeId)) {
        Hive.registerAdapter(DailyProgressAdapter());
      }

      // ✅ Force recalculate all progress (temporary during testing)
      await Hive.box<DailyProgress>(AppConstants.dailyProgress).clear();

      await Hive.openBox<DailyProgress>(AppConstants.dailyProgress);

      // 2. Load User Preferences
      final prefs = await SharedPreferences.getInstance();

      final bool darkMode = prefs.getBool('wp_dark') ?? true;
      final bool useStatusColors = prefs.getBool('wp_colors') ?? false;

      // Load Style
      final int styleIndex = prefs.getInt('wp_style') ?? 0;
      // final WallpaperStyle style = WallpaperStyle.values[styleIndex];

      final double dotScale = prefs.getDouble('wp_scale') ?? 1.0;
      final double verticalOffset = prefs.getDouble('wp_offset') ?? 0.45;
      final double gridWidth = prefs.getDouble('wp_width') ?? 0.8;
      final double spacing = prefs.getDouble('wp_spacing') ?? 1.0;

      Color? themeColor;
      final int? savedColor = prefs.getInt('wp_theme_color');
      if (savedColor != null) {
        themeColor = Color(savedColor);
      }

      // 3. Generate
      final service = ProgressCalendarService();
      final yearProgress = await service.getYearProgress(DateTime.now().year);

      final wallpaperService = WallpaperGeneratorService();
      final wallpaperFile = await wallpaperService.generateProgressWallpaper(
        yearProgress: yearProgress,
        size: const Size(1080, 2400), // Standard resolution
        // style: style, // Use loaded style
        darkMode: darkMode,
        useStatusColors: useStatusColors,
        themeColor: themeColor,
        dotScale: dotScale,
        verticalOffset: verticalOffset,
        gridWidthFactor: gridWidth,
        spacingFactor: spacing,
      );

      // 4. Set
      await wallpaperService.setAsLockScreen(wallpaperFile);

      // 5. Refresh Data
      await service.refreshTodayProgress();

      // debugPrint('✅ Wallpaper updated successfully with style: ${style.name}');
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Wallpaper update failed: $e');
      return Future.value(false);
    }
  });
}

class WallpaperSchedulerService {
  static final WallpaperSchedulerService _instance = WallpaperSchedulerService._internal();
  factory WallpaperSchedulerService() => _instance;
  WallpaperSchedulerService._internal();

  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

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
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
    debugPrint('✅ Daily wallpaper update scheduled');
  }

  Future<void> cancelScheduledUpdates() async {
    await Workmanager().cancelByUniqueName('wallpaper_update');
  }

  Duration _getDurationUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }
}