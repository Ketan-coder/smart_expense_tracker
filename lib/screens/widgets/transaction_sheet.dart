// utils/transaction_sheet.dart
import 'package:expense_tracker/core/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'dynamic_lottie_colors.dart';

class TransactionSheet {
  static void show({
    required BuildContext context,
    required bool isIncome,
    required double amount,
    required String currency,
    String? description,
  }) {
    // Auto close after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      builder: (context) => _TransactionSheetContent(
        isIncome: isIncome,
        amount: amount,
        currency: currency,
        description: description,
      ),
    );
  }
}

class _TransactionSheetContent extends StatelessWidget {
  final bool isIncome;
  final double amount;
  final String currency;
  final String? description;

  const _TransactionSheetContent({
    required this.isIncome,
    required this.amount,
    required this.currency,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Check Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isIncome
                    ? colorScheme.primaryContainer
                    : colorScheme.errorContainer,
              ),
              child: DynamicLottieColors(
                assetPath: AppConstants.successSendLottieJsonPath,
                isIncome: isIncome,
                size: 60,
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              isIncome ? 'Income Added!' : 'Expense Recorded!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            // Amount
            Text(
              '$currency ${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isIncome
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
            ),

            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 16),

            // Auto-close indicator
            _CountdownIndicator(duration: 3),
          ],
        ),
      ),
    );
  }
}

class _CountdownIndicator extends StatefulWidget {
  final int duration;

  const _CountdownIndicator({required this.duration});

  @override
  State<_CountdownIndicator> createState() => _CountdownIndicatorState();
}

class _CountdownIndicatorState extends State<_CountdownIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: LinearProgressIndicator(
        value: _controller.value,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}