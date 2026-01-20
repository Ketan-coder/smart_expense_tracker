import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../data/model/daily_progress.dart';

class WallpaperGeneratorService {
  static final WallpaperGeneratorService _instance = WallpaperGeneratorService._internal();
  factory WallpaperGeneratorService() => _instance;
  WallpaperGeneratorService._internal();

  static const platform = MethodChannel('com.yourapp.wallpaper/set');

  Future<File> generateProgressWallpaper({
    required List<DailyProgress> yearProgress,
    required Size size,
    bool darkMode = true,
    bool useStatusColors = false,
    Color? themeColor,
    double dotScale = 1.0,
    double verticalOffset = 0.45,
    double gridWidthFactor = 0.8,
    double spacingFactor = 1.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    // 1. Background
    final bgColor = darkMode ? const Color(0xFF000000) : const Color(0xFFF5F5F5);
    canvas.drawPaint(Paint()..color = bgColor);

    // 2. Grid Setup
    const cols = 15;
    final rows = (yearProgress.length / cols).ceil();
    final contentWidth = size.width * gridWidthFactor;
    final double cellSize = contentWidth / cols;

    final double dotDiameter = (cellSize * 0.6 * dotScale) / spacingFactor;
    final gridHeight = cellSize * rows;
    final startX = (size.width - (cellSize * cols)) / 2;
    final startY = (size.height - gridHeight) * verticalOffset;

    // 3. Contrast Colors
    // Slightly more visible "empty" state
    final emptyColorAfter = darkMode
        ? useStatusColors && themeColor != null ? themeColor.withValues(alpha: .1) : Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFD0D0D0);

    final emptyColor = darkMode
        ? useStatusColors && themeColor != null ? themeColor.withValues(alpha: 0.25) : Colors.red.withValues(alpha: 0.2)
        : const Color(0xFFD0D0D0);

    // Improved Main Dot Color (Light shade of theme color for better contrast)
    Color mainDotColor = darkMode ? const Color(0xFFFFFFFF) : const Color(0xFF333333);
    if (!useStatusColors && themeColor != null) {
      // Mix theme color with white to get a lighter, high-contrast shade
      mainDotColor = Color.alphaBlend(themeColor.withValues(alpha:0.8), Colors.white.withValues(alpha:0.2));
    }

    final todayRingColor = themeColor ?? const Color(0xFFFF5252);

    for (int i = 0; i < yearProgress.length; i++) {
      final day = yearProgress[i];
      final col = i % cols;
      final row = i ~/ cols;

      final x = startX + (col * cellSize) + (cellSize / 2);
      final y = startY + (row * cellSize) + (cellSize / 2);

      final paint = Paint()..isAntiAlias = true;

      if (day.date.isAfter(DateTime.now())) {
        paint.color = emptyColorAfter;
      } else if (day.isAnyProgressMade) {
        if (useStatusColors) {
          paint.color = _getHighContrastStatusColor(day);
        } else {
          paint.color = mainDotColor;
        }
      } else {
        paint.color = emptyColor;
      }

      canvas.drawCircle(Offset(x, y), dotDiameter / 2, paint);

      if (_isSameDay(day.date, DateTime.now())) {
        canvas.drawCircle(
            Offset(x, y),
            (dotDiameter / 2) + 6,
            Paint()
              ..color = todayRingColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
        );
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/progress_wallpaper.png');
    await file.writeAsBytes(buffer);
    return file;
  }

  // Uses lighter, more vibrant "Accent" colors for better visibility on dark wallpapers
  Color _getHighContrastStatusColor(DailyProgress day) {
    switch (day.status) {
      case ProgressStatus.goalCompleted:
        return Colors.lightGreenAccent;
      case ProgressStatus.habitCompleted:
        return Colors.cyanAccent;
      case ProgressStatus.productive:
        return Colors.orangeAccent;
      default:
        return Colors.white;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<bool> setAsLockScreen(File f) => _setWallpaper(f, 'lock');
  Future<bool> setAsHomeScreen(File f) => _setWallpaper(f, 'home');
  Future<bool> setAsBothScreens(File f) => _setWallpaper(f, 'both');

  Future<bool> _setWallpaper(File file, String loc) async {
    try {
      return await platform.invokeMethod('setWallpaper', {'filePath': file.path, 'location': loc}) == true;
    } catch (e) { return false; }
  }
}