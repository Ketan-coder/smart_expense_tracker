import 'package:flutter/material.dart';

class AppTheme {
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
  ).copyWith(
    // Ensure containers & onContainers are always defined
    primaryContainer: Colors.deepPurple.shade100,
    onPrimaryContainer: Colors.deepPurple.shade900,
    secondaryContainer: Colors.deepPurple.shade50,
    onSecondaryContainer: Colors.deepPurple.shade800,
    tertiaryContainer: Colors.orange.shade100,
    onTertiaryContainer: Colors.orange.shade900,
    errorContainer: Colors.red.shade100,
    onErrorContainer: Colors.red.shade900,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.dark,
  ).copyWith(
    primaryContainer: Colors.deepPurple.shade700,
    onPrimaryContainer: Colors.white,
    secondaryContainer: Colors.deepPurple.shade600,
    onSecondaryContainer: Colors.white,
    tertiaryContainer: Colors.orange.shade700,
    onTertiaryContainer: Colors.white,
    errorContainer: Colors.red.shade700,
    onErrorContainer: Colors.white,
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _lightScheme,
    brightness: Brightness.light,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _darkScheme,
    brightness: Brightness.dark,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}
