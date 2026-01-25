// utils/transaction_sheet.dart
import 'package:expense_tracker/core/app_constants.dart';
import 'package:flutter/material.dart';
import '../../services/langs/localzation_extension.dart';
import '../../services/number_formatter_service.dart';
import 'dynamic_lottie_colors.dart';
import 'celebration_overlay.dart';

class TransactionSheet {
  static void show({
    required BuildContext context,
    required bool isIncome,
    required double amount,
    required String currency,
    String? description,
  }) {
    // Show celebration overlay for big income (1000+ rupees)
    CelebrationOverlay.showIfNeeded(
      context: context,
      amount: amount,
      isIncome: isIncome,
      threshold: 15000,
      duration: const Duration(seconds: 3),
    );

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

class _TransactionSheetContent extends StatefulWidget {
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
  State<_TransactionSheetContent> createState() => _TransactionSheetContentState();
}

class _TransactionSheetContentState extends State<_TransactionSheetContent> {
  @override
  void initState() {
    super.initState();
    // Auto close after 3 seconds using the sheet's own context
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

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
            // Animated Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: DynamicLottieColors(
                assetPath: widget.isIncome
                    ? AppConstants.spinningIndianRupeeCoin
                    : AppConstants.successSendLottieJsonPath,
                isIncome: widget.isIncome,
                size: 60,
                applyDynamicColors: !widget.isIncome,
                // For expense animation, use custom delegates
                customDelegates: !widget.isIncome
                    ? LottieColorDelegates.successSendDelegates(
                  primaryColor: colorScheme.error,
                  containerColor: colorScheme.errorContainer,
                )
                    : null,
              ),
            ),

            const SizedBox(height: 16),

            // Title with extra flair for big amounts
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isIncome && widget.amount >= 15000)
                  const Text('🎉 ', style: TextStyle(fontSize: 20)),
                Text(
                  widget.isIncome ? context.t('income_added') : context.t('expense_recorded'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (widget.isIncome && widget.amount >= 15000)
                  const Text(' 🎉', style: TextStyle(fontSize: 20)),
              ],
            ),

            const SizedBox(height: 8),

            // Amount
            Text(
              '${widget.currency} ${NumberFormatterService().formatForDisplay(widget.amount)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.isIncome
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
            ),

            if (widget.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.description!,
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
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
      },
    );
  }
}