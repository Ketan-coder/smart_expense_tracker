// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import '../data/model/daily_progress.dart';
//
// enum WallpaperStyle {
//   grid, // The classic "Year in Pixels" grid
//   dial, // The new "Month List + Grid" design
// }
//
// class WallpaperGeneratorService {
//   static final WallpaperGeneratorService _instance = WallpaperGeneratorService._internal();
//   factory WallpaperGeneratorService() => _instance;
//   WallpaperGeneratorService._internal();
//
//   static const platform = MethodChannel('com.yourapp.wallpaper/set');
//
//   Future<File> generateProgressWallpaper({
//     required List<DailyProgress> yearProgress,
//     required Size size,
//     WallpaperStyle style = WallpaperStyle.grid,
//     bool darkMode = true,
//     bool useStatusColors = false,
//     Color? themeColor,
//     double dotScale = 1.0,
//     double verticalOffset = 0.45,
//     double gridWidthFactor = 0.8,
//     double spacingFactor = 1.0,
//   }) async {
//     final recorder = ui.PictureRecorder();
//     final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));
//
//     // 1. Background
//     final bgColor = darkMode ? const Color(0xFF000000) : const Color(0xFFF5F5F5);
//     canvas.drawPaint(Paint()..color = bgColor);
//
//     // ✅ Colors for different day types
//     // Future days (hasn't happened yet)
//     final emptyColorAfter = darkMode
//         ? (themeColor?.withValues(alpha: 0.2) ?? Colors.white.withValues(alpha: 0.1))
//         : (themeColor?.withValues(alpha: 0.25) ?? const Color(0xFFD0D0D0));
//
//     // Past days with no progress (missed days)
//     final emptyColor = darkMode
//         ? const Color(0xFF1A1A1A)
//         : const Color(0xFFE0E0E0);
//
//     // ✅ Single color for all progress when Dynamic Colors is ON
//     Color mainDotColor = darkMode ? const Color(0xFFFFFFFF) : const Color(0xFF333333);
//     if (themeColor != null) {
//       // Use theme color with high contrast
//       mainDotColor = darkMode
//           ? Color.alphaBlend(themeColor.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.2))
//           : Color.alphaBlend(themeColor.withValues(alpha: 0.9), Colors.black.withValues(alpha: 0.1));
//     }
//
//     final todayRingColor = themeColor ?? const Color(0xFFFF5252);
//
//     // 3. Draw Selected Style
//     if (style == WallpaperStyle.grid) {
//       _drawGrid(
//           canvas, size, yearProgress,
//           darkMode, useStatusColors, themeColor,
//           dotScale, verticalOffset, gridWidthFactor, spacingFactor,
//           emptyColor, mainDotColor, todayRingColor, emptyColorAfter
//       );
//     } else {
//       _drawDialDesign(
//           canvas, size, yearProgress,
//           darkMode, useStatusColors, themeColor,
//           dotScale, verticalOffset,
//           emptyColor, mainDotColor, todayRingColor, emptyColorAfter
//       );
//     }
//
//     // 4. Save
//     final picture = recorder.endRecording();
//     final img = await picture.toImage(size.width.toInt(), size.height.toInt());
//     final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//     final buffer = byteData!.buffer.asUint8List();
//
//     final directory = await getApplicationDocumentsDirectory();
//     final file = File('${directory.path}/progress_wallpaper.png');
//     await file.writeAsBytes(buffer);
//     return file;
//   }
//
//   // --- STYLE 1: CLASSIC GRID ---
//   void _drawGrid(
//       Canvas canvas, Size size, List<DailyProgress> yearProgress,
//       bool darkMode, bool useStatusColors, Color? themeColor,
//       double dotScale, double verticalOffset, double gridWidthFactor, double spacingFactor,
//       Color emptyColor, Color mainDotColor, Color todayRingColor, Color emptyColorAfter
//       ) {
//     const cols = 14;
//     final rows = (yearProgress.length / cols).ceil();
//     final contentWidth = size.width * gridWidthFactor;
//     final double cellSize = contentWidth / cols;
//
//     final double dotDiameter = (cellSize * 0.6 * dotScale) / spacingFactor;
//     final gridHeight = cellSize * rows;
//     final startX = (size.width - (cellSize * cols)) / 2;
//     final startY = (size.height - gridHeight) * verticalOffset;
//
//     for (int i = 0; i < yearProgress.length; i++) {
//       final day = yearProgress[i];
//       final col = i % cols;
//       final row = i ~/ cols;
//       final x = startX + (col * cellSize) + (cellSize / 2);
//       final y = startY + (row * cellSize) + (cellSize / 2);
//
//       _drawDot(canvas, x, y, dotDiameter, day, darkMode, useStatusColors, themeColor, emptyColor, mainDotColor, todayRingColor, emptyColorAfter);
//     }
//   }
//
//   void _drawDialDesign(
//       Canvas canvas, Size size, List<DailyProgress> yearProgress,
//       bool darkMode, bool useStatusColors, Color? themeColor,
//       double dotScale, double verticalOffset,
//       Color emptyColor, Color mainDotColor, Color todayRingColor, Color emptyColorAfter
//       ) {
//     final now = DateTime.now();
//     final currentMonth = now.month;
//
//     // Config
//     final leftMargin = size.width * 0.12;
//     final startY = size.height * verticalOffset;
//
//     // Get current month name
//     final monthNameBefore = _getMonthName(currentMonth);
//
//     // Determine which months to show based on current month
//     List<int> monthsToShow;
//     if (monthNameBefore == "January") {
//       monthsToShow = [0, 1, 2, 3, 4];
//     } else if (monthNameBefore == "December") {
//       monthsToShow = [-4, -3, -2, -1, 0];
//     } else {
//       monthsToShow = [-2, -1, 0, 1, 2];
//     }
//
//     double currentY = startY;
//
//     // Draw "..." at top only if not at the beginning
//     if (currentMonth > 3) {
//       _drawText(canvas, "...", leftMargin, currentY - 40, 24, Colors.grey.withOpacity(0.5), false);
//     }
//
//     for (int offset in monthsToShow) {
//       int targetMonth = currentMonth + offset;
//
//       if (targetMonth < 1) {
//         targetMonth += 12;
//       } else if (targetMonth > 12) {
//         targetMonth -= 12;
//       }
//
//       final isPast = offset < 0;
//       final isCurrent = offset == 0;
//       final isFuture = offset > 0;
//
//       double fontSize;
//       if (isCurrent) {
//         fontSize = 150;
//       } else if (isPast) {
//         fontSize = 95;
//       } else {
//         fontSize = (offset == 1) ? 110 : (offset == 2) ? 90 : 75;
//       }
//
//       Color color;
//       if (isCurrent) {
//         color = darkMode ? useStatusColors && themeColor != null ? themeColor.withValues(alpha: 0.6) : Colors.white : useStatusColors && themeColor != null ? themeColor : Colors.black;
//       } else if (isPast) {
//         color = darkMode ? Colors.grey.withOpacity(0.5): Colors.grey.shade500;
//       } else {
//         color = darkMode ? Colors.grey.withOpacity(0.5) : Colors.grey.shade500;
//       }
//
//       bool strikethrough = isPast;
//
//       final monthName = _getMonthName(targetMonth);
//       final textHeight = _drawText(
//           canvas,
//           monthName,
//           leftMargin + 25,
//           currentY,
//           fontSize,
//           color,
//           strikethrough
//       );
//
//       currentY += textHeight + 10;
//
//       if (isCurrent) {
//         currentY += 15;
//         final daysInMonth = yearProgress.where((d) => d.date.month == targetMonth).toList();
//         final gridHeight = _drawMonthGrid(
//             canvas, size, daysInMonth, currentY, leftMargin,
//             dotScale, darkMode, useStatusColors, themeColor, emptyColor, mainDotColor, todayRingColor, emptyColorAfter
//         );
//         currentY += gridHeight + 30;
//       } else {
//         currentY += 25;
//       }
//     }
//
//     if (currentMonth < 9) {
//       _drawText(canvas, "...", leftMargin + 40, currentY, 80, darkMode ? Colors.grey.shade800 : Colors.grey.shade400, false);
//     }
//   }
//
//   double _drawMonthGrid(
//       Canvas canvas, Size size, List<DailyProgress> days, double startY, double startX,
//       double userDotScale, bool darkMode, bool useStatusColors, Color? themeColor, Color emptyColor, Color mainDotColor, Color todayRingColor, Color emptyColorAfter
//       ) {
//     const cols = 7;
//     final double cellSize = (size.width * 0.11);
//     final double dotDiameter = (cellSize * 0.5) * userDotScale;
//
//     if (days.isEmpty) return 0;
//
//     int row = 0;
//     int col = 0;
//
//     for (int i = 0; i < days.length; i++) {
//       final day = days[i];
//
//       final x = startX + (col * cellSize) + (cellSize / 2);
//       final y = startY + (row * cellSize) + (cellSize / 2);
//
//       _drawDot(canvas, x, y, dotDiameter, day, darkMode, useStatusColors, themeColor, emptyColor, mainDotColor, todayRingColor, emptyColorAfter);
//
//       col++;
//       if (col >= cols) {
//         col = 0;
//         row++;
//       }
//     }
//
//     return (row + 1) * cellSize;
//   }
//
//   String _getDefaultFontFamily() {
//     if (Platform.isIOS) {
//       return '.SF Pro Display';
//     } else if (Platform.isAndroid) {
//       return 'Roboto';
//     } else if (Platform.isMacOS) {
//       return '.SF NS Display';
//     } else if (Platform.isWindows) {
//       return 'Segoe UI';
//     } else if (Platform.isLinux) {
//       return 'Ubuntu';
//     } else {
//       return 'Poppins';
//     }
//   }
//
//   double _drawText(Canvas canvas, String text, double x, double y, double fontSize, Color color, bool strikethrough) {
//     final textSpan = TextSpan(
//       text: text,
//       style: TextStyle(
//         color: color,
//         fontSize: fontSize,
//         fontWeight: fontSize > 30 ? FontWeight.bold : FontWeight.normal,
//         fontFamily: _getDefaultFontFamily(),
//         decoration: strikethrough ? TextDecoration.lineThrough : null,
//         decorationColor: Colors.red.withOpacity(0.5),
//         decorationThickness: 2.0,
//       ),
//     );
//     final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
//     tp.layout();
//     tp.paint(canvas, Offset(x, y));
//     return tp.height;
//   }
//
//   String _getMonthName(int month) {
//     const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
//     return months[month - 1];
//   }
//
//   // ✅ CORRECTED: Dynamic Colors OFF = Colorful, Dynamic Colors ON = Single theme color
//   void _drawDot(Canvas canvas, double x, double y, double diameter, DailyProgress day, bool darkMode, bool useStatusColors, Color? themeColor, Color empty, Color main, Color ring, Color emptyColorAfter) {
//     final paint = Paint()..isAntiAlias = true;
//
//     if (day.date.isAfter(DateTime.now())) {
//       // Future days
//       paint.color = emptyColorAfter;
//     } else if (day.isAnyProgressMade) {
//       // Days with progress
//       if (useStatusColors) {
//         // ✅ Dynamic Colors ON: Use single theme color for ALL progress
//         paint.color = main;
//       } else {
//         // ✅ Dynamic Colors OFF: Use colorful status-based colors (green/cyan/orange)
//         paint.color = _getColorfulStatusColor(day, darkMode, themeColor);
//       }
//     } else {
//       // Past days with no progress
//       paint.color = empty;
//     }
//
//     canvas.drawCircle(Offset(x, y), diameter / 2, paint);
//
//     // Today's ring indicator
//     if (_isSameDay(day.date, DateTime.now())) {
//       canvas.drawCircle(Offset(x, y), (diameter / 2) + 5, Paint()
//         ..color = ring
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 3
//       );
//     }
//   }
//
//   // ✅ Colorful status colors (used when Dynamic Colors is OFF)
//   Color _getColorfulStatusColor(DailyProgress day, bool darkMode, Color? themeColor) {
//     final primary = themeColor ?? const Color(0xFF6200EA);
//
//     switch (day.status) {
//       case ProgressStatus.goalCompleted:
//       // Goal: Light green accent with theme blend
//         return Color.alphaBlend(
//           primary.withOpacity(0.7),
//           Colors.lightGreenAccent.withOpacity(0.8),
//         );
//
//       case ProgressStatus.habitCompleted:
//       // Habit: Cyan accent with theme blend
//         return Color.alphaBlend(
//           primary.withOpacity(0.7),
//           Colors.cyanAccent.withOpacity(0.8),
//         );
//
//       case ProgressStatus.productive:
//       // Finance/Productive: Orange accent with theme blend
//         return Color.alphaBlend(
//           primary.withOpacity(0.7),
//           Colors.orangeAccent.withOpacity(0.8),
//         );
//
//       default:
//         return darkMode
//             ? primary.withOpacity(0.25)
//             : primary.withOpacity(0.3);
//     }
//   }
//
//   bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
//   Future<bool> setAsLockScreen(File f) => _setWallpaper(f, 'lock');
//   Future<bool> setAsHomeScreen(File f) => _setWallpaper(f, 'home');
//   Future<bool> setAsBothScreens(File f) => _setWallpaper(f, 'both');
//   Future<bool> _setWallpaper(File file, String loc) async {
//     try {
//       return await platform.invokeMethod('setWallpaper', {'filePath': file.path, 'location': loc}) == true;
//     } catch (e) { return false; }
//   }
// }


import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../data/model/daily_progress.dart';

enum WallpaperStyle {
  grid, // The classic "Year in Pixels" grid
  dial, // The new "Month List + Grid" design
}

class WallpaperGeneratorService {
  static final WallpaperGeneratorService _instance = WallpaperGeneratorService._internal();
  factory WallpaperGeneratorService() => _instance;
  WallpaperGeneratorService._internal();

  static const platform = MethodChannel('com.yourapp.wallpaper/set');

  Future<File> generateProgressWallpaper({
    required List<DailyProgress> yearProgress,
    required Size size,
    WallpaperStyle style = WallpaperStyle.grid,
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

    // ✅ Colors for different day types
    // Future days (hasn't happened yet)
    final emptyColorAfter = darkMode
        ? (themeColor?.withValues(alpha: 0.2) ?? Colors.white.withValues(alpha: 0.1))
        : (themeColor?.withValues(alpha: 0.25) ?? const Color(0xFFD0D0D0));

    // Past days with no progress (missed days)
    final emptyColor = darkMode
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFE0E0E0);

    // ✅ Single color for all progress when Dynamic Colors is ON
    Color mainDotColor = darkMode ? const Color(0xFFFFFFFF) : const Color(0xFF333333);
    if (themeColor != null) {
      // Use theme color with high contrast
      mainDotColor = darkMode
          ? Color.alphaBlend(themeColor.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.2))
          : Color.alphaBlend(themeColor.withValues(alpha: 0.9), Colors.black.withValues(alpha: 0.1));
    }

    final todayRingColor = themeColor ?? const Color(0xFFFF5252);

    // 3. Draw Selected Style
    if (style == WallpaperStyle.grid) {
      _drawGrid(
          canvas, size, yearProgress,
          darkMode, useStatusColors, themeColor,
          dotScale, verticalOffset, gridWidthFactor, spacingFactor,
          emptyColor, mainDotColor, todayRingColor, emptyColorAfter
      );
    } else {
      _drawDialDesign(
          canvas, size, yearProgress,
          darkMode, useStatusColors, themeColor,
          dotScale, verticalOffset,
          emptyColor, mainDotColor, todayRingColor, emptyColorAfter
      );
    }

    // 4. Save
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/progress_wallpaper.png');
    await file.writeAsBytes(buffer);
    return file;
  }

  // --- STYLE 1: CLASSIC GRID ---
  void _drawGrid(
      Canvas canvas, Size size, List<DailyProgress> yearProgress,
      bool darkMode, bool useStatusColors, Color? themeColor,
      double dotScale, double verticalOffset, double gridWidthFactor, double spacingFactor,
      Color emptyColor, Color mainDotColor, Color todayRingColor, Color emptyColorAfter
      ) {
    const cols = 14;
    final rows = (yearProgress.length / cols).ceil();
    final contentWidth = size.width * gridWidthFactor;
    final double cellSize = contentWidth / cols;

    final double dotDiameter = (cellSize * 0.6 * dotScale) / spacingFactor;
    final gridHeight = cellSize * rows;
    final startX = (size.width - (cellSize * cols)) / 2;
    final startY = (size.height - gridHeight) * verticalOffset;

    for (int i = 0; i < yearProgress.length; i++) {
      final day = yearProgress[i];
      final col = i % cols;
      final row = i ~/ cols;
      final x = startX + (col * cellSize) + (cellSize / 2);
      final y = startY + (row * cellSize) + (cellSize / 2);

      _drawDot(canvas, x, y, dotDiameter, day, darkMode, useStatusColors, themeColor, emptyColor, mainDotColor, todayRingColor, emptyColorAfter);
    }
  }

  void _drawDialDesign(
      Canvas canvas, Size size, List<DailyProgress> yearProgress,
      bool darkMode, bool useStatusColors, Color? themeColor,
      double dotScale, double verticalOffset,
      Color emptyColor, Color mainDotColor, Color todayRingColor, Color emptyColorAfter
      ) {
    final now = DateTime.now();
    final currentMonth = now.month;

    // Config
    final leftMargin = size.width * 0.12;
    final startY = size.height * verticalOffset;

    // Get current month name
    final monthNameBefore = _getMonthName(currentMonth);

    // Determine which months to show based on current month
    List<int> monthsToShow;
    if (monthNameBefore == "January") {
      monthsToShow = [0, 1, 2, 3, 4];
    } else if (monthNameBefore == "December") {
      monthsToShow = [-4, -3, -2, -1, 0];
    } else {
      monthsToShow = [-2, -1, 0, 1, 2];
    }

    double currentY = startY;

    // Draw "..." at top only if not at the beginning
    if (currentMonth > 3) {
      _drawText(canvas, "...", leftMargin, currentY - 40, 24, Colors.grey.withOpacity(0.5), false);
    }

    for (int offset in monthsToShow) {
      int targetMonth = currentMonth + offset;

      if (targetMonth < 1) {
        targetMonth += 12;
      } else if (targetMonth > 12) {
        targetMonth -= 12;
      }

      final isPast = offset < 0;
      final isCurrent = offset == 0;
      final isFuture = offset > 0;

      double fontSize;
      if (isCurrent) {
        fontSize = 150;
      } else if (isPast) {
        fontSize = 95;
      } else {
        fontSize = (offset == 1) ? 110 : (offset == 2) ? 90 : 75;
      }

      Color color;
      if (isCurrent) {
        color = darkMode ? useStatusColors && themeColor != null ? themeColor.withValues(alpha: 0.6) : Colors.white : useStatusColors && themeColor != null ? themeColor : Colors.black;
      } else if (isPast) {
        color = darkMode ? Colors.grey.withOpacity(0.5): Colors.grey.shade500;
      } else {
        color = darkMode ? Colors.grey.withOpacity(0.5) : Colors.grey.shade500;
      }

      bool strikethrough = isPast;

      final monthName = _getMonthName(targetMonth);
      final textHeight = _drawText(
          canvas,
          monthName,
          leftMargin + 25,
          currentY,
          fontSize,
          color,
          strikethrough
      );

      currentY += textHeight + 10;

      if (isCurrent) {
        currentY += 15;
        final daysInMonth = yearProgress.where((d) => d.date.month == targetMonth).toList();
        final gridHeight = _drawMonthGrid(
            canvas, size, daysInMonth, currentY, leftMargin,
            dotScale, darkMode, useStatusColors, themeColor, emptyColor, mainDotColor, todayRingColor, emptyColorAfter
        );
        currentY += gridHeight + 30;
      } else {
        currentY += 25;
      }
    }

    if (currentMonth < 9) {
      _drawText(canvas, "...", leftMargin + 40, currentY, 80, darkMode ? Colors.grey.shade800 : Colors.grey.shade400, false);
    }
  }

  double _drawMonthGrid(
      Canvas canvas, Size size, List<DailyProgress> days, double startY, double startX,
      double userDotScale, bool darkMode, bool useStatusColors, Color? themeColor, Color emptyColor, Color mainDotColor, Color todayRingColor, Color emptyColorAfter
      ) {
    const cols = 7;
    final double cellSize = (size.width * 0.11);
    final double dotDiameter = (cellSize * 0.5) * userDotScale;

    if (days.isEmpty) return 0;

    int row = 0;
    int col = 0;

    for (int i = 0; i < days.length; i++) {
      final day = days[i];

      final x = startX + (col * cellSize) + (cellSize / 2);
      final y = startY + (row * cellSize) + (cellSize / 2);

      _drawDot(canvas, x, y, dotDiameter, day, darkMode, useStatusColors, themeColor, emptyColor, mainDotColor, todayRingColor, emptyColorAfter);

      col++;
      if (col >= cols) {
        col = 0;
        row++;
      }
    }

    return (row + 1) * cellSize;
  }

  String _getDefaultFontFamily() {
    if (Platform.isIOS) {
      return '.SF Pro Display';
    } else if (Platform.isAndroid) {
      return 'Roboto';
    } else if (Platform.isMacOS) {
      return '.SF NS Display';
    } else if (Platform.isWindows) {
      return 'Segoe UI';
    } else if (Platform.isLinux) {
      return 'Ubuntu';
    } else {
      return 'Poppins';
    }
  }

  double _drawText(Canvas canvas, String text, double x, double y, double fontSize, Color color, bool strikethrough) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontSize > 30 ? FontWeight.bold : FontWeight.normal,
        fontFamily: _getDefaultFontFamily(),
        decoration: strikethrough ? TextDecoration.lineThrough : null,
        decorationColor: Colors.red.withOpacity(0.5),
        decorationThickness: 2.0,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, y));
    return tp.height;
  }

  String _getMonthName(int month) {
    const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    return months[month - 1];
  }

  // ✅ UPDATED: Shows today's date inside circle with proper color contrast
  void _drawDot(Canvas canvas, double x, double y, double diameter, DailyProgress day, bool darkMode, bool useStatusColors, Color? themeColor, Color empty, Color main, Color ring, Color emptyColorAfter) {
    final paint = Paint()..isAntiAlias = true;
    final isToday = _isSameDay(day.date, DateTime.now());

    if (day.date.isAfter(DateTime.now())) {
      // Future days
      paint.color = emptyColorAfter;
    } else if (day.isAnyProgressMade) {
      // Days with progress
      if (useStatusColors) {
        // ✅ Dynamic Colors ON: Use single theme color for ALL progress
        paint.color = main;
      } else {
        // ✅ Dynamic Colors OFF: Use colorful status-based colors (green/cyan/orange)
        paint.color = _getColorfulStatusColor(day, darkMode, themeColor);
      }
    } else {
      // Past days with no progress
      paint.color = empty;
    }

    // Draw circle
    canvas.drawCircle(Offset(x, y), diameter / 2, paint);

    // Today's ring indicator + date
    if (isToday) {
      // Draw ring
      canvas.drawCircle(Offset(x, y), (diameter / 2) + 5, Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
      );

      // ✅ Draw today's date inside the circle
      final dateText = day.date.day.toString();

      // Choose text color based on background brightness
      Color textColor;
      if (day.isAnyProgressMade) {
        // If there's progress, check what color the dot is
        if (useStatusColors) {
          // Dynamic Colors ON: theme color background
          textColor = darkMode ? Colors.black : Colors.white;
        } else {
          // Dynamic Colors OFF: colorful background
          // Use black for light backgrounds, white for dark
          textColor = darkMode ? Colors.black : Colors.white;
        }
      } else {
        // No progress: empty color background
        textColor = darkMode ? useStatusColors && themeColor != null ? themeColor : Colors.white : Colors.black;
      }

      final textSpan = TextSpan(
        text: dateText,
        style: TextStyle(
          color: textColor,
          fontSize: diameter * 0.45, // Scale with dot size
          fontWeight: FontWeight.w900,
          fontFamily: _getDefaultFontFamily(),
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      // Center the text perfectly
      final textOffset = Offset(
        x - (textPainter.width / 2),
        y - (textPainter.height / 2),
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  // ✅ Colorful status colors (used when Dynamic Colors is OFF)
  Color _getColorfulStatusColor(DailyProgress day, bool darkMode, Color? themeColor) {
    final primary = themeColor ?? const Color(0xFF6200EA);

    switch (day.status) {
      case ProgressStatus.goalCompleted:
        return Color.alphaBlend(
          primary.withOpacity(0.7),
          Colors.lightGreenAccent.withOpacity(0.8),
        );

      case ProgressStatus.habitCompleted:
        return Color.alphaBlend(
          primary.withOpacity(0.7),
          Colors.cyanAccent.withOpacity(0.8),
        );

      case ProgressStatus.productive:
        return Color.alphaBlend(
          primary.withOpacity(0.7),
          Colors.orangeAccent.withOpacity(0.8),
        );

      default:
        return darkMode
            ? primary.withOpacity(0.25)
            : primary.withOpacity(0.3);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  Future<bool> setAsLockScreen(File f) => _setWallpaper(f, 'lock');
  Future<bool> setAsHomeScreen(File f) => _setWallpaper(f, 'home');
  Future<bool> setAsBothScreens(File f) => _setWallpaper(f, 'both');

  Future<bool> _setWallpaper(File file, String loc) async {
    try {
      // Verify file exists and is readable
      if (!await file.exists()) {
        debugPrint('❌ Wallpaper file does not exist: ${file.path}');
        return false;
      }

      final fileSize = await file.length();
      debugPrint('📁 Wallpaper file size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Call native method
      final result = await platform.invokeMethod('setWallpaper', {
        'filePath': file.path,
        'location': loc,
      });

      debugPrint('📱 Native method result: $result');

      if (result == true) {
        debugPrint('✅ Wallpaper set successfully for $loc screen');
        return true;
      } else {
        debugPrint('⚠️ Wallpaper setting returned false');
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint('❌ PlatformException: ${e.code} - ${e.message}');
      debugPrint('Details: ${e.details}');
      return false;
    } catch (e) {
      debugPrint('❌ Error setting wallpaper: $e');
      return false;
    }
  }
}