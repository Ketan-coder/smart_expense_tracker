import 'dart:ui';
import 'package:flutter/material.dart';

/// Blurs or masks sensitive financial data when privacy mode is active
class PrivacyOverlay extends StatelessWidget {
  final Widget child;
  final bool isPrivacyActive;
  final String? placeholder;
  final bool useBlur; // true = blur, false = mask with dots

  const PrivacyOverlay({
    super.key,
    required this.child,
    required this.isPrivacyActive,
    this.placeholder,
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPrivacyActive) {
      return child;
    }

    if (useBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            child,
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Mask with dots
      return Text(
        placeholder ?? '••••••',
        style: DefaultTextStyle.of(context).style,
      );
    }
  }
}

/// Specialized widget for currency amounts
class PrivacyCurrency extends StatelessWidget {
  final String amount;
  final bool isPrivacyActive;
  final TextStyle? style;

  const PrivacyCurrency({
    super.key,
    required this.amount,
    required this.isPrivacyActive,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      child: Text(
        isPrivacyActive ? '••••••' : amount,
        key: ValueKey(isPrivacyActive),
        style: style,
      ),
    );
  }
}

/// Privacy indicator badge for AppBar or status bar
class PrivacyIndicator extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;

  const PrivacyIndicator({
    super.key,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.visibility_off : Icons.visibility,
              size: 16,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                'Privacy',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple dimming overlay - replaces vignette to avoid light mode glitches
/// Just a subtle black overlay to reduce brightness
class MyDimmingOverlay extends StatelessWidget {
  final bool isActive;

  const MyDimmingOverlay({
    super.key,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: isActive ? 1.0 : 0.0,
        child: Container(
          color: Colors.black.withOpacity(0.65), // Simple 15% black overlay
        ),
      ),
    );
  }
}

/// Alert shown when multiple faces detected
class MultipleWatchersAlert extends StatelessWidget {
  const MultipleWatchersAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.shade100,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Someone's watching 👀",
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}