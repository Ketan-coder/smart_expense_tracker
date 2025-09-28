import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
