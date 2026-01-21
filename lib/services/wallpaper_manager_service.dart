import 'dart:io';
import 'package:expense_tracker/services/progress_calendar_service.dart';
import 'package:expense_tracker/services/wallpaper_generator_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class WallpaperManagerService {
  static final WallpaperManagerService _instance = WallpaperManagerService._internal();
  factory WallpaperManagerService() => _instance;
  WallpaperManagerService._internal();

  Future<File?> generateWallpaper({
    required WallpaperStyle style,
    bool darkMode = true,
    bool useStatusColors = false,
    Color? themeColor,
    double dotScale = 1.0,
    double verticalOffset = 0.45,
    double gridWidth = 0.8,
    double dotSpacing = 1.0,
  }) async {
    try {
      final service = ProgressCalendarService();
      final yearProgress = await service.getYearProgress(DateTime.now().year);

      // Ultra HD Resolution (4x Screen Size)
      final screenSize = await _getScreenSize();
      final wallpaperSize = Size(screenSize.width * 4, screenSize.height * 4);

      final wallpaperService = WallpaperGeneratorService();
      final file = await wallpaperService.generateProgressWallpaper(
        yearProgress: yearProgress,
        size: wallpaperSize,
        style: style,
        darkMode: darkMode,
        useStatusColors: useStatusColors,
        themeColor: themeColor,
        dotScale: dotScale,
        verticalOffset: verticalOffset,
        gridWidthFactor: gridWidth,
        spacingFactor: dotSpacing,
      );

      return file;
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }

  // Helpers
  Future<File?> getSavedWallpaper() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/progress_wallpaper.png');
    return await file.exists() ? file : null;
  }

  Future<bool> setAsLockScreen(File f) => WallpaperGeneratorService().setAsLockScreen(f);
  Future<bool> setAsHomeScreen(File f) => WallpaperGeneratorService().setAsHomeScreen(f);
  Future<bool> setAsBothScreens(File f) => WallpaperGeneratorService().setAsBothScreens(f);

  Future<Size> _getScreenSize() async {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return Size(
      view.physicalSize.width / view.devicePixelRatio,
      view.physicalSize.height / view.devicePixelRatio,
    );
  }
}