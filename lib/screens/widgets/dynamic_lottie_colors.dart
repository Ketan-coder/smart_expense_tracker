// widgets/dynamic_lottie_colors.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DynamicLottieColors extends StatelessWidget {
  final String assetPath;
  final bool isIncome;
  final double size;
  final bool applyDynamicColors;
  final List<ValueDelegate>? customDelegates;

  const DynamicLottieColors({
    super.key,
    required this.assetPath,
    required this.isIncome,
    this.size = 80,
    this.applyDynamicColors = true,
    this.customDelegates,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = isIncome ? colorScheme.primary : colorScheme.error;
    final containerColor = isIncome ? colorScheme.primaryContainer : colorScheme.errorContainer;

    // If dynamic colors are disabled, show original animation
    if (!applyDynamicColors) {
      return Lottie.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Lottie Error for $assetPath: $error');
          return _buildFallbackIcon(primaryColor);
        },
      );
    }

    // If custom delegates are provided, use them
    if (customDelegates != null && customDelegates!.isNotEmpty) {
      return Lottie.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        delegates: LottieDelegates(values: customDelegates!),
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Lottie Delegate Error for $assetPath: $error');
          // Fallback to ColorFiltered if delegates fail
          return _buildColorFilteredLottie(primaryColor);
        },
      );
    }

    // Default: Use ColorFiltered (safest, works with any Lottie structure)
    return _buildColorFilteredLottie(primaryColor);
  }

  Widget _buildColorFilteredLottie(Color primaryColor) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        primaryColor,
        BlendMode.srcATop,
      ),
      child: Lottie.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Lottie Error for $assetPath: $error');
          return _buildFallbackIcon(primaryColor);
        },
      ),
    );
  }

  Widget _buildFallbackIcon(Color primaryColor) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Icon(
        isIncome ? Icons.currency_rupee : Icons.check_circle,
        size: size * 0.8,
        color: primaryColor,
      ),
    );
  }
}

// ============================================
// HELPER: Pre-built delegate configurations
// ============================================
class LottieColorDelegates {
  /// Delegates for SuccessSendLottie.json (checkmark with paper plane)
  static List<ValueDelegate> successSendDelegates({
    required Color primaryColor,
    required Color containerColor,
  }) {
    return [
      // Global catch-all for all colors
      ValueDelegate.colorFilter(
        const ['**'],
        value: ColorFilter.mode(primaryColor, BlendMode.srcATop),
      ),

      // Specific overrides for lighter color elements
      ValueDelegate.colorFilter(
        const ['Shape Layer 2', '**'],
        value: ColorFilter.mode(containerColor, BlendMode.srcATop),
      ),

      // For the paper plane composition
      ValueDelegate.colorFilter(
        const ['New_Plane', '**', 'Shape Layer 3', '**'],
        value: ColorFilter.mode(containerColor, BlendMode.srcATop),
      ),
    ];
  }

  /// Generic two-color delegates (for animations with primary and accent colors)
  static List<ValueDelegate> twoColorDelegates({
    required Color primaryColor,
    required Color secondaryColor,
    List<String>? secondaryPaths,
  }) {
    return [
      // Apply primary color to everything first
      ValueDelegate.colorFilter(
        const ['**'],
        value: ColorFilter.mode(primaryColor, BlendMode.srcATop),
      ),

      // Apply secondary color to specific paths if provided
      if (secondaryPaths != null)
        ...secondaryPaths.map(
              (path) => ValueDelegate.colorFilter(
            [path, '**'],
            value: ColorFilter.mode(secondaryColor, BlendMode.srcATop),
          ),
        ),
    ];
  }
}