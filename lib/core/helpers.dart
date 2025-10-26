import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Helpers {
  /// Format currency (₹, $, etc.)
  static String formatCurrency(double amount, {String symbol = "₹"}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Format date
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  /// Short category icons (you can later map to emojis/icons)
  static String getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return "🍔";
      case 'travel':
        return "🚗";
      case 'shopping':
        return "🛍️";
      default:
        return "💸";
    }
  }

  bool isLightMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light;
  }

  // Custom transition (left-to-right, slow like iOS)
  Route createRoute(Widget secondScreen) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600), // Slow transition
      pageBuilder: (context, animation, secondaryAnimation) => secondScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0); // Start from the left
        const end = Offset.zero; // End at the center
        const curve = Curves.easeInOut; // Smooth slow effect

        var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  /// Navigate to another screen using custom route (Right → Left)
  static Future<T?> navigateTo<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Start from the right
          const end = Offset.zero;        // End at center
          const curve = Curves.easeInOut;

          var tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Checks if two DateTime objects are on the same day, ignoring time.
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Formats a double value into a compact currency string (e.g., 1500 -> 1.5k).
  String formatCompactCurrency(double value) {
    if (value < 1000) {
      return value.toStringAsFixed(0);
    }
    return NumberFormat.compact().format(value);
  }

  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Color hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return Colors.grey;
    }
    hex = hex.replaceFirst('#', '');
    if (hex.length != 6 && hex.length != 8) {
      return Colors.grey;
    }
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      debugPrint('Invalid hex color: $hex, error: $e');
      return Colors.grey;
    }
  }

  List<String> getPaymentMethods() {
    return ["UPI", "Cash", "NEFT", "IMPS", "RTGS", "Card", "Online"];
  }
  
  Future<String?> getCurrentCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedCurrency') ?? '₹';
  }

  Future<void> setCurrentCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCurrency', currency);
  }

  Future<String?> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedLanguage') ?? 'English';
  }

  Future<void> setCurrentLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
  }

  Future<bool?> getCurrentNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notificationState') ?? false;
  }

  Future<void> setCurrentNotificationState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationState', state);
  }

  Future<bool?> getCurrentDarkThemeState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('darkThemeState') ?? false;
  }

  Future<void> setCurrentDarkThemeState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkThemeState', state);
  }

  Future<bool?> getCurrentAutoThemeState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('autoThemeState') ?? true;
  }

  Future<void> setCurrentAutoThemeState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoThemeState', state);
  }

  // In Helpers class
  Future<bool?> getCurrentBiometricState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_state') ?? false;
  }

  Future<void> setCurrentBiometricState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_state', state);
  }

  Future<bool?> getCurrentSmsParsingState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sms_parsing_enabled') ?? true; // Default true
  }

  Future<void> setCurrentSmsParsingState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sms_parsing_enabled', state);
  }
}
