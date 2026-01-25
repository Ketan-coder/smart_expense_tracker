import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

enum NumberFormatType {
  indian, // 1,00,000.00
  western, // 100,000.00
  european, // 100.000,00
  none, // 100000.00
}

class NumberFormatterService {
  static final NumberFormatterService _instance = NumberFormatterService._internal();
  factory NumberFormatterService() => _instance;
  NumberFormatterService._internal();

  NumberFormatType _currentFormat = NumberFormatType.indian;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final formatIndex = prefs.getInt('number_format') ?? 0;
    _currentFormat = NumberFormatType.values[formatIndex];
  }

  Future<void> setFormat(NumberFormatType format) async {
    _currentFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('number_format', format.index);
  }

  NumberFormatType get currentFormat => _currentFormat;

  /// Check if a number has significant decimal places
  bool _hasSignificantDecimals(double amount, int maxDecimals) {
    // Convert to string with max decimals
    final stringValue = amount.toStringAsFixed(maxDecimals);

    // Check if there are any non-zero digits after decimal
    final parts = stringValue.split('.');
    if (parts.length < 2) return false;

    final decimalPart = parts[1];
    for (int i = 0; i < decimalPart.length; i++) {
      if (decimalPart[i] != '0') {
        return true;
      }
    }
    return false;
  }

  /// Determine optimal number of decimals to show
  int _determineOptimalDecimals(double amount, {int defaultDecimals = 2}) {
    if (!_hasSignificantDecimals(amount, defaultDecimals)) {
      // No significant decimals, show integer
      return 0;
    }

    // Check for common decimal patterns (like .5, .25, etc.)
    final stringValue = amount.toStringAsFixed(6); // Check up to 6 decimal places
    final parts = stringValue.split('.');
    if (parts.length < 2) return 0;

    final decimalPart = parts[1];

    // Find last non-zero digit
    int lastNonZeroIndex = -1;
    for (int i = decimalPart.length - 1; i >= 0; i--) {
      if (decimalPart[i] != '0') {
        lastNonZeroIndex = i;
        break;
      }
    }

    if (lastNonZeroIndex == -1) return 0;

    // Return minimum needed decimals (last non-zero position + 1)
    // But cap at defaultDecimals
    return (lastNonZeroIndex + 1).clamp(1, defaultDecimals);
  }

  /// Format a number for display (adds commas/dots)
  String formatForDisplay(double amount, {int maxDecimals = 2, bool smartDecimals = true}) {
    if (_currentFormat == NumberFormatType.none) {
      if (smartDecimals && !_hasSignificantDecimals(amount, maxDecimals)) {
        return amount.toInt().toString();
      }
      return amount.toStringAsFixed(maxDecimals);
    }

    // Determine optimal decimals
    int decimalsToUse = maxDecimals;
    if (smartDecimals) {
      decimalsToUse = _determineOptimalDecimals(amount, defaultDecimals: maxDecimals);
    }

    switch (_currentFormat) {
      case NumberFormatType.indian:
        return _formatIndian(amount, decimalsToUse, smartDecimals);
      case NumberFormatType.western:
        return _formatWestern(amount, decimalsToUse, smartDecimals);
      case NumberFormatType.european:
        return _formatEuropean(amount, decimalsToUse, smartDecimals);
      case NumberFormatType.none:
        if (smartDecimals && !_hasSignificantDecimals(amount, maxDecimals)) {
          return amount.toInt().toString();
        }
        return amount.toStringAsFixed(decimalsToUse);
    }
  }

  /// Parse a formatted string back to double (removes formatting)
  double parseFromDisplay(String formatted) {
    // Remove all formatting characters
    String cleaned = formatted
        .replaceAll(' ', '')
        .replaceAll('\u00A0', ''); // Non-breaking space

    // Handle European format (swap comma and dot)
    if (_currentFormat == NumberFormatType.european) {
      // In European: 1.000,50 should become 1000.50
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // For Indian/Western: just remove commas
      cleaned = cleaned.replaceAll(',', '');
    }

    return double.tryParse(cleaned) ?? 0.0;
  }

  String _formatIndian(double amount, int decimals, bool smartDecimals) {
    // If no decimals needed, format as integer
    if (smartDecimals && decimals == 0) {
      final integerAmount = amount.toInt();
      return _formatIntegerIndian(integerAmount);
    }

    final parts = amount.toStringAsFixed(decimals).split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    if (integerPart.length <= 3) {
      return '$integerPart.$decimalPart';
    }

    // Last 3 digits
    final lastThree = integerPart.substring(integerPart.length - 3);
    final remaining = integerPart.substring(0, integerPart.length - 3);

    // Add comma every 2 digits for remaining
    final formattedRemaining = remaining.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
          (Match m) => '${m[1]},',
    );

    return '$formattedRemaining,$lastThree.$decimalPart';
  }

  String _formatIntegerIndian(int amount) {
    final integerPart = amount.toString();

    if (integerPart.length <= 3) {
      return integerPart;
    }

    // Last 3 digits
    final lastThree = integerPart.substring(integerPart.length - 3);
    final remaining = integerPart.substring(0, integerPart.length - 3);

    // Add comma every 2 digits for remaining
    final formattedRemaining = remaining.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
          (Match m) => '${m[1]},',
    );

    return '$formattedRemaining,$lastThree';
  }

  String _formatWestern(double amount, int decimals, bool smartDecimals) {
    // If no decimals needed, format as integer
    if (smartDecimals && decimals == 0) {
      final integerAmount = amount.toInt();
      final formatter = NumberFormat('#,##0', 'en_US');
      return formatter.format(integerAmount);
    }

    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'en_US');
    return formatter.format(amount);
  }

  String _formatEuropean(double amount, int decimals, bool smartDecimals) {
    // If no decimals needed, format as integer
    if (smartDecimals && decimals == 0) {
      final integerAmount = amount.toInt();
      final formatter = NumberFormat('#,##0', 'de_DE');
      return formatter.format(integerAmount);
    }

    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'de_DE');
    return formatter.format(amount);
  }

  String getFormatName(NumberFormatType format) {
    switch (format) {
      case NumberFormatType.indian:
        return 'Indian (1,00,000.00)';
      case NumberFormatType.western:
        return 'Western (100,000.00)';
      case NumberFormatType.european:
        return 'European (100.000,00)';
      case NumberFormatType.none:
        return 'None (100000.00)';
    }
  }

  /// Quick format without smart decimals (for backwards compatibility)
  String format(double amount, {int decimals = 2}) {
    return formatForDisplay(amount, maxDecimals: decimals, smartDecimals: false);
  }
}

// Extension for easy usage throughout the app
extension NumberFormattingExtension on double {
  String toFormattedString({int maxDecimals = 2, bool smartDecimals = true}) {
    return NumberFormatterService().formatForDisplay(
        this,
        maxDecimals: maxDecimals,
        smartDecimals: smartDecimals
    );
  }

  /// Backwards compatibility method
  String format({int decimals = 2}) {
    return NumberFormatterService().format(this, decimals: decimals);
  }
}

// Extension for integers too
extension IntFormattingExtension on int {
  String toFormattedString() {
    return NumberFormatterService().formatForDisplay(
        this.toDouble(),
        maxDecimals: 0,
        smartDecimals: true
    );
  }
}