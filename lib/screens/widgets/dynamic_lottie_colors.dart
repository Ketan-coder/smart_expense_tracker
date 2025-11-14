// widgets/fixed_dynamic_lottie.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DynamicLottieColors extends StatelessWidget {
  final String assetPath;
  final bool isIncome;
  final double size;

  const DynamicLottieColors({
    Key? key,
    required this.assetPath,
    required this.isIncome,
    this.size = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = isIncome ? colorScheme.primary : colorScheme.error;
    final containerColor = isIncome ? colorScheme.primaryContainer : colorScheme.errorContainer;

    return Lottie.asset(
      assetPath,
      width: size,
      height: size,
      delegates: LottieDelegates(
        values: [
          // Use ColorFilter approach which is more reliable
          ValueDelegate.colorFilter(
            const ['**'],
            value: ColorFilter.mode(primaryColor, BlendMode.srcATop),
          ),

          ValueDelegate.colorFilter(
            const ['Shape Layer 2', '**'],
            value: ColorFilter.mode(containerColor, BlendMode.srcATop),
          ),

          ValueDelegate.colorFilter(
            const ['New_Plane', '**', 'Shape Layer 3', '**'],
            value: ColorFilter.mode(containerColor, BlendMode.srcATop),
          ),
        ],
      ),
    );
  }
}