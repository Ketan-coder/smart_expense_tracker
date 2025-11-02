import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model for each showcase step
class ShowcaseStep {
  final GlobalKey key;
  final String title;
  final String description;
  final ShapeBorder? targetShape;
  final ScrollController? scrollController;
  final Duration scrollDuration;

  ShowcaseStep({
    required this.key,
    required this.title,
    required this.description,
    this.targetShape,
    this.scrollController,
    this.scrollDuration = const Duration(milliseconds: 500),
  });
}

/// Main showcase controller
class ShowcaseController extends ChangeNotifier {
  List<ShowcaseStep> _steps = [];
  int _currentIndex = 0;
  bool _isActive = false;

  bool get isActive => _isActive;
  int get currentIndex => _currentIndex;
  ShowcaseStep? get currentStep =>
      _isActive && _currentIndex < _steps.length ? _steps[_currentIndex] : null;

  void start(List<ShowcaseStep> steps) {
    _steps = steps;
    _currentIndex = 0;
    _isActive = true;
    notifyListeners();
  }

  void next() {
    if (_currentIndex < _steps.length - 1) {
      _currentIndex++;
      notifyListeners();
    } else {
      finish();
    }
  }

  void finish() {
    _isActive = false;
    _currentIndex = 0;
    _steps = [];
    notifyListeners();
  }

  void skip() {
    finish();
  }
}

/// Overlay widget that shows the showcase
class ShowcaseOverlay extends StatefulWidget {
  final ShowcaseController controller;
  final Widget child;

  const ShowcaseOverlay({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);

  @override
  State<ShowcaseOverlay> createState() => _ShowcaseOverlayState();
}

class _ShowcaseOverlayState extends State<ShowcaseOverlay> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateOverlay);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateOverlay);
    _removeOverlay();
    super.dispose();
  }

  void _updateOverlay() {
    if (widget.controller.isActive) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => _ShowcaseContent(
        controller: widget.controller,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// The actual showcase content with highlight and description
class _ShowcaseContent extends StatelessWidget {
  final ShowcaseController controller;

  const _ShowcaseContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final step = controller.currentStep;
        if (step == null) return const SizedBox.shrink();

        return _ShowcaseLayer(
          step: step,
          controller: controller,
        );
      },
    );
  }
}

class _ShowcaseLayer extends StatefulWidget {
  final ShowcaseStep step;
  final ShowcaseController controller;

  const _ShowcaseLayer({
    required this.step,
    required this.controller,
  });

  @override
  State<_ShowcaseLayer> createState() => _ShowcaseLayerState();
}

class _ShowcaseLayerState extends State<_ShowcaseLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTargetPosition();
    });
  }

  @override
  void didUpdateWidget(_ShowcaseLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      _animController.reset();
      _animController.forward();
      _calculateTargetPosition();
    }
  }

  void _calculateTargetPosition() {
    // Wait a frame to ensure layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
      widget.step.key.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;

        // Check if widget is off-screen or partially visible
        final isOffScreen = position.dy < 0 || position.dy > screenHeight;
        final isPartiallyVisible = position.dy < 100 || position.dy > screenHeight - 200;

        if ((isOffScreen || isPartiallyVisible) && widget.step.scrollController != null) {
          // Widget needs scrolling
          _scrollToTarget();
        } else {
          // Widget is visible, update rect
          if (mounted) {
            setState(() {
              _targetRect = position & renderBox.size;
            });
          }
        }
      } else {
        // Widget not rendered yet, try scrolling after delay
        if (widget.step.scrollController != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _scrollToTarget();
          });
        }
      }
    });
  }

  Future<void> _scrollToTarget() async {
    final scrollController = widget.step.scrollController;
    if (scrollController == null || !scrollController.hasClients) {
      debugPrint('⚠ [Showcase] ScrollController not available');
      return;
    }

    // Wait for context to be available
    await Future.delayed(const Duration(milliseconds: 100));

    final RenderBox? renderBox =
    widget.step.key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null && renderBox.hasSize) {
      try {
        final position = renderBox.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;

        debugPrint('🔍 [Showcase] Widget position: ${position.dy}, Screen height: $screenHeight');
        debugPrint('🔍 [Showcase] Current scroll offset: ${scrollController.offset}');

        // Calculate target scroll position to center the widget
        final currentScrollOffset = scrollController.offset;
        final widgetOffsetFromTop = position.dy;
        final targetPosition = currentScrollOffset + widgetOffsetFromTop - (screenHeight / 2) + (renderBox.size.height / 2);

        final clampedTarget = targetPosition.clamp(
          scrollController.position.minScrollExtent,
          scrollController.position.maxScrollExtent,
        );

        debugPrint('🔍 [Showcase] Scrolling to: $clampedTarget');

        // Scroll to make widget visible
        await scrollController.animateTo(
          clampedTarget,
          duration: widget.step.scrollDuration,
          curve: Curves.easeInOutCubic,
        );

        // Wait for scroll to complete and layout to settle
        await Future.delayed(const Duration(milliseconds: 300));

        // Recalculate position after scroll
        if (mounted) {
          final newRenderBox = widget.step.key.currentContext?.findRenderObject() as RenderBox?;
          if (newRenderBox != null && newRenderBox.hasSize) {
            final newPosition = newRenderBox.localToGlobal(Offset.zero);
            setState(() {
              _targetRect = newPosition & newRenderBox.size;
            });
            debugPrint('✅ [Showcase] Widget now at position: ${newPosition.dy}');
          }
        }
      } catch (e) {
        debugPrint('⚠ [Showcase] Error scrolling to target: $e');
        // If scrolling fails, try to show widget anyway
        if (mounted) {
          setState(() {
            final position = renderBox.localToGlobal(Offset.zero);
            _targetRect = position & renderBox.size;
          });
        }
      }
    } else {
      debugPrint('⚠ [Showcase] RenderBox not available for scrolling');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_targetRect == null) {
      // Show loading state while scrolling/finding widget
      return Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      );
    }

    // Get primary color from your AppColors
    final primaryColor = Theme.of(context).primaryColor; // Replace with AppColors.primaryLightColor

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Faded background with transparent hole
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _HighlightPainter(
                targetRect: _targetRect!,
                targetShape: widget.step.targetShape ?? const CircleBorder(),
                primaryColor: primaryColor,
              ),
            ),

            // Pulsing ring animation around target
            Positioned(
              left: _targetRect!.left - 12,
              top: _targetRect!.top - 12,
              child: _PulsingRing(
                size: Size(_targetRect!.width + 24, _targetRect!.height + 24),
                shape: widget.step.targetShape ?? const CircleBorder(),
                color: primaryColor,
              ),
            ),

            // Description card with modern design
            Positioned(
              left: 20,
              right: 20,
              top: _getDescriptionTop(context),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                        spreadRadius: 0,
                      ),
                    ],
                    border: Border.all(
                      color: primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.lightbulb_outline_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.step.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.step.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black.withOpacity(0.7),
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Progress indicator
                          Row(
                            children: List.generate(
                              widget.controller._steps.length,
                                  (index) => Container(
                                margin: const EdgeInsets.only(right: 6),
                                width: index == widget.controller.currentIndex ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == widget.controller.currentIndex
                                      ? primaryColor
                                      : primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => widget.controller.skip(),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black54,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: const Text(
                                  'Skip',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => widget.controller.next(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  widget.controller.currentIndex <
                                      widget.controller._steps.length - 1
                                      ? 'Next'
                                      : 'Got it!',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getDescriptionTop(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final targetBottom = _targetRect!.bottom;

    if (screenHeight - targetBottom > 300) {
      return targetBottom + 30;
    } else {
      return _targetRect!.top - 280;
    }
  }
}

/// Pulsing ring animation
class _PulsingRing extends StatefulWidget {
  final Size size;
  final ShapeBorder shape;
  final Color color;

  const _PulsingRing({
    required this.size,
    required this.shape,
    required this.color,
  });

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: false);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: widget.size,
          painter: _RingPainter(
            progress: _animation.value,
            shape: widget.shape,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final ShapeBorder shape;
  final Color color;

  _RingPainter({
    required this.progress,
    required this.shape,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);

    final paint = Paint()
      ..color = color.withOpacity((1 - progress) * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.scale(1 + progress * 0.2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => true;
}

/// Custom painter for the highlight effect with TRANSPARENT hole
class _HighlightPainter extends CustomPainter {
  final Rect targetRect;
  final ShapeBorder targetShape;
  final Color primaryColor;

  _HighlightPainter({
    required this.targetRect,
    required this.targetShape,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a layer for proper transparency
    canvas.saveLayer(Rect.largest, Paint());

    // Draw semi-transparent background
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.85);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Cut out the target area with CLEAR blend mode
    final holePaint = Paint()
      ..blendMode = BlendMode.clear;

    final expandedRect = targetRect.inflate(12);
    final path = targetShape.getOuterPath(expandedRect);
    canvas.drawPath(path, holePaint);

    // Restore to apply the layer
    canvas.restore();

    // Draw glowing border around target
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    // Draw solid border
    final borderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_HighlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}

/// Helper to check if showcase should be shown
class ShowcaseHelper {
  static const String keyPrefix = 'showcase_seen';

  /// Set this to true during development to always show showcase
  /// This bypasses SharedPreferences completely for easier testing
  static bool debugMode = false;

  static Future<bool> shouldShow(String screenId) async {
    if (debugMode) {
      debugPrint('🔍 [Showcase Debug] shouldShow("$screenId") - DEBUG MODE: Always returning TRUE');
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasSeenBefore = prefs.getBool('$keyPrefix$screenId') ?? false;
    debugPrint('🔍 [Showcase] shouldShow("$screenId") - Has seen before: $hasSeenBefore');
    return !hasSeenBefore;
  }

  static Future<void> markAsShown(String screenId) async {
    if (debugMode) {
      debugPrint('🔍 [Showcase Debug] markAsShown("$screenId") - DEBUG MODE: Skipping save to SharedPreferences');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$keyPrefix$screenId', true);
    debugPrint('✅ [Showcase] markAsShown("$screenId") - Saved to SharedPreferences');
  }

  static Future<void> reset(String screenId) async {
    if (debugMode) {
      debugPrint('🔍 [Showcase Debug] reset("$screenId") - DEBUG MODE: Nothing to reset');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$keyPrefix$screenId');
    debugPrint('🗑 [Showcase] reset("$screenId") - Removed from SharedPreferences');
  }

  /// Reset all showcases (useful for testing)
  static Future<void> resetAll() async {
    if (debugMode) {
      debugPrint('🔍 [Showcase Debug] resetAll() - DEBUG MODE: Nothing to reset');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(keyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
    debugPrint('🗑 [Showcase] resetAll() - Removed ${keys.length} showcases');
  }
}