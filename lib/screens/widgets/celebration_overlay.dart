// widgets/celebration_overlay.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CelebrationOverlay {
  /// Show celebration overlay for big transactions
  ///
  /// [context] - BuildContext
  /// [amount] - Transaction amount
  /// [isIncome] - Whether it's income or expense
  /// [threshold] - Minimum amount to trigger celebration (default: 1000)
  /// [duration] - How long to show the animation (default: 3 seconds)
  static void showIfNeeded({
    required BuildContext context,
    required double amount,
    required bool isIncome,
    double threshold = 15000,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Only show for income and if amount exceeds threshold
    if (!isIncome || amount < threshold) return;

    show(
      context: context,
      duration: duration,
      amount: amount,
    );
  }

  /// Manually show celebration overlay
  static void show({
    required BuildContext context,
    Duration duration = const Duration(seconds: 3),
    double? amount,
  }) {
    final overlay = OverlayEntry(
      builder: (context) => _CelebrationOverlayWidget(
        duration: duration,
        amount: amount,
      ),
    );

    Overlay.of(context).insert(overlay);

    // Auto-remove after duration
    Future.delayed(duration, () {
      if (overlay.mounted) {
        overlay.remove();
      }
    });
  }
}

class _CelebrationOverlayWidget extends StatefulWidget {
  final Duration duration;
  final double? amount;

  const _CelebrationOverlayWidget({
    required this.duration,
    this.amount,
  });

  @override
  State<_CelebrationOverlayWidget> createState() =>
      _CelebrationOverlayWidgetState();
}

class _CelebrationOverlayWidgetState extends State<_CelebrationOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Fade in quickly, stay, then fade out
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Money rain animation (full screen, pointer events disabled)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildMoneyRain(context),
              ),
            ),
          ),

          // Optional: Congratulations message
          // if (widget.amount != null)
          //   Positioned(
          //     top: MediaQuery.of(context).size.height * 0.3,
          //     left: 0,
          //     right: 0,
          //     child: IgnorePointer(
          //       child: FadeTransition(
          //         opacity: _fadeAnimation,
          //         child: _buildCongratsMessage(context),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _buildMoneyRain(BuildContext context) {
    // Check if you have a money rain Lottie animation
    // If not, we'll create a fallback effect
    // const moneyRainPath = AppConstants.moneyRainDashboardJsonPath;
    const moneyRainPath = 'assets/icons/WiliinglyWrong';

    return Lottie.asset(
      moneyRainPath,
      fit: BoxFit.cover,
      repeat: true,
      errorBuilder: (context, error, stackTrace) {
        // Fallback: Use confetti or create custom particle effect
        return _buildFallbackCelebration(context);
      },
    );
  }

  Widget _buildFallbackCelebration(BuildContext context) {
    // Simple fallback with emoji particles
    return Stack(
      children: List.generate(
        40,
            (index) => _AnimatedEmoji(
          emoji: ['💰', '💵', '💴', '💶', '💷', '🤑'][index % 6],
          delay: Duration(milliseconds: index * 100),
        ),
      ),
    );
  }

  Widget _buildCongratsMessage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Congratulations! 🎉',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            if (widget.amount != null) ...[
              const SizedBox(height: 4),
              Text(
                'Big income of ₹${widget.amount!.toStringAsFixed(0)}!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Animated emoji particle for fallback
class _AnimatedEmoji extends StatefulWidget {
  final String emoji;
  final Duration delay;

  const _AnimatedEmoji({
    required this.emoji,
    required this.delay,
  });

  @override
  State<_AnimatedEmoji> createState() => _AnimatedEmojiState();
}

class _AnimatedEmojiState extends State<_AnimatedEmoji>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _verticalAnimation;
  late Animation<double> _horizontalAnimation;
  late Animation<double> _opacityAnimation;
  late double _startX;

  @override
  void initState() {
    super.initState();
    _startX = (widget.emoji.hashCode % 100) / 100.0;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _verticalAnimation = Tween<double>(
      begin: -0.1,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _horizontalAnimation = Tween<double>(
      begin: 0,
      end: (widget.emoji.hashCode % 40 - 20) / 100.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_controller);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
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
        return Positioned(
          top: MediaQuery.of(context).size.height * _verticalAnimation.value,
          left: MediaQuery.of(context).size.width *
              (_startX + _horizontalAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.rotate(
              angle: _controller.value * 6.28, // Full rotation
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }
}