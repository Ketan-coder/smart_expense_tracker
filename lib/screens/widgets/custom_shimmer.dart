import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CustomShimmer  —  synced page-wide sweep, scrollable, 4 animation styles.
//
// ANIMATION STYLES:
//   ShimmerStyle.sweep       — classic horizontal sweep          (default)
//   ShimmerStyle.pulse       — whole element breathes in/out
//   ShimmerStyle.wave        — diagonal (30°) sweep band
//   ShimmerStyle.shimmerGlow — sweep + gentle opacity pulse overlay
// ═════════════════════════════════════════════════════════════════════════════

// ── Animation style ───────────────────────────────────────────────────────────
enum ShimmerStyle {
  sweep,
  pulse,
  wave,
  shimmerGlow,
}

// ── InheritedWidget: one controller shared by the whole tree ─────────────────
class _ShimmerScope extends InheritedWidget {
  final AnimationController controller;
  final Color baseColor;
  final Color highlightColor;
  final ShimmerStyle style;

  const _ShimmerScope({
    required this.controller,
    required this.baseColor,
    required this.highlightColor,
    required this.style,
    required super.child,
  });

  static _ShimmerScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();

  @override
  bool updateShouldNotify(_ShimmerScope old) =>
      controller != old.controller ||
          baseColor != old.baseColor ||
          highlightColor != old.highlightColor ||
          style != old.style;
}

// ── Root widget ───────────────────────────────────────────────────────────────
class CustomShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration period;
  final ShimmerStyle style;

  const CustomShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.period = const Duration(milliseconds: 1500),
    this.style = ShimmerStyle.sweep,
  });

  factory CustomShimmer.fromColors({
    Key? key,
    required Widget child,
    required Color baseColor,
    required Color highlightColor,
    Duration period = const Duration(milliseconds: 1500),
    ShimmerStyle style = ShimmerStyle.sweep,
  }) =>
      CustomShimmer(
        key: key,
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: period,
        style: style,
        child: child,
      );

  @override
  State<CustomShimmer> createState() => _CustomShimmerState();
}

class _CustomShimmerState extends State<CustomShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);
    // pulse reverses; everything else is a forward repeat
    if (widget.style == ShimmerStyle.pulse) {
      _controller.repeat(reverse: true);
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      controller: _controller,
      baseColor: widget.baseColor,
      highlightColor: widget.highlightColor,
      style: widget.style,
      child: widget.child,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _SyncedShimmerItem  —  the internal widget used by ShimmerBox / ShimmerCircle
//
// Global-coordinate sync:
//   We find this widget's RenderBox and call localToGlobal(Offset.zero) to get
//   its screen position. The painter subtracts globalOffsetX from the gradient's
//   travel position so the highlight band appears at the same screen X for every
//   item — even items at different depths inside cards, rows, or paddings.
// ═════════════════════════════════════════════════════════════════════════════
class _SyncedShimmerItem extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _SyncedShimmerItem({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final scope = _ShimmerScope.of(context);

    // No CustomShimmer ancestor — render static fallback
    if (scope == null) {
      return Container(
        width: width == double.infinity ? null : width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: borderRadius,
        ),
      );
    }

    return AnimatedBuilder(
      animation: scope.controller,
      builder: (ctx, _) {
        // ── Resolve global position ──────────────────────────────────────
        double globalOffsetX = 0;
        final screenWidth = MediaQuery.of(ctx).size.width;

        final ro = ctx.findRenderObject();
        if (ro is RenderBox && ro.hasSize) {
          try {
            globalOffsetX = ro.localToGlobal(Offset.zero).dx;
          } catch (_) {
            // localToGlobal can throw if the object is not yet attached
          }
        }

        return CustomPaint(
          painter: _ShimmerPainter(
            progress: scope.controller.value,
            baseColor: scope.baseColor,
            highlightColor: scope.highlightColor,
            borderRadius: borderRadius,
            globalOffsetX: globalOffsetX,
            screenWidth: screenWidth,
            style: scope.style,
          ),
          child: SizedBox(
            width: width == double.infinity ? null : width,
            height: height,
          ),
        );
      },
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────
class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color baseColor;
  final Color highlightColor;
  final BorderRadius borderRadius;
  final double globalOffsetX;
  final double screenWidth;
  final ShimmerStyle style;

  const _ShimmerPainter({
    required this.progress,
    required this.baseColor,
    required this.highlightColor,
    required this.borderRadius,
    required this.globalOffsetX,
    required this.screenWidth,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect =
    borderRadius.toRRect(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.save();
    canvas.clipRRect(rrect);

    // Base fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = baseColor,
    );

    switch (style) {
      case ShimmerStyle.sweep:
        _paintSweep(canvas, size, diagonal: false);
      case ShimmerStyle.wave:
        _paintSweep(canvas, size, diagonal: true);
      case ShimmerStyle.pulse:
        _paintPulse(canvas, size, rrect);
      case ShimmerStyle.shimmerGlow:
        _paintSweep(canvas, size, diagonal: false);
        _paintGlowOverlay(canvas, size, rrect);
    }

    canvas.restore();
  }

  // ── Classic / diagonal sweep ─────────────────────────────────────────────
  void _paintSweep(Canvas canvas, Size size, {required bool diagonal}) {
    final double bandWidth = screenWidth * 0.55;
    final double travelRange = screenWidth + bandWidth;
    // Leading edge in screen coordinates
    final double screenLeading = travelRange * progress - bandWidth;
    // Convert to local widget coordinates
    final double localLeading = screenLeading - globalOffsetX;

    final Rect gradientRect =
    Rect.fromLTWH(localLeading, 0, bandWidth, size.height);

    List<Color> colors;
    List<double> stops;

    if (diagonal) {
      // Wave: softer, slightly wider highlight zone
      colors = [baseColor, highlightColor, highlightColor, baseColor];
      stops = [0.0, 0.3, 0.7, 1.0];
    } else {
      // Sweep: sharper highlight center
      colors = [baseColor, highlightColor, baseColor];
      stops = [0.0, 0.5, 1.0];
    }

    final gradient = LinearGradient(
      colors: colors,
      stops: stops,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final paint = Paint()..shader = gradient.createShader(gradientRect);

    if (diagonal) {
      // Shear the canvas slightly for the diagonal look
      canvas.save();
      final matrix = Matrix4.identity()..setEntry(0, 1, -0.15);
      canvas.transform(matrix.storage);
      canvas.drawRect(gradientRect, paint);
      canvas.restore();
    } else {
      canvas.drawRect(gradientRect, paint);
    }
  }

  // ── Pulse: lerp between base and highlight ───────────────────────────────
  void _paintPulse(Canvas canvas, Size size, RRect rrect) {
    final Color blended = Color.lerp(baseColor, highlightColor, progress)!;
    canvas.drawRRect(rrect, Paint()..color = blended);
  }

  // ── Glow overlay (used by shimmerGlow on top of sweep) ───────────────────
  void _paintGlowOverlay(Canvas canvas, Size size, RRect rrect) {
    // Triangle wave: 0 → 1 → 0 over one cycle
    final double t = 1.0 - (2.0 * progress - 1.0).abs();
    final Color glow = highlightColor.withValues(alpha: t * 0.22);
    canvas.drawRRect(rrect, Paint()..color = glow);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      old.progress != progress ||
          old.baseColor != baseColor ||
          old.highlightColor != highlightColor ||
          old.globalOffsetX != globalOffsetX ||
          old.style != style;
}

// ═════════════════════════════════════════════════════════════════════════════
// Public placeholder widgets
// ═════════════════════════════════════════════════════════════════════════════

/// Rectangular shimmer placeholder. Must be inside a [CustomShimmer].
class ShimmerBox extends StatelessWidget {
  final double height;

  /// Omit (or pass null) to stretch to available width.
  final double? width;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return _SyncedShimmerItem(
      width: width ?? double.infinity,
      height: height,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

/// Circular shimmer placeholder. Must be inside a [CustomShimmer].
class ShimmerCircle extends StatelessWidget {
  final double radius;

  const ShimmerCircle({super.key, required this.radius});

  @override
  Widget build(BuildContext context) {
    return _SyncedShimmerItem(
      width: radius * 2,
      height: radius * 2,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

/// Neutral card shell for grouping shimmer placeholders.
/// The card background itself does NOT shimmer — only [ShimmerBox] /
/// [ShimmerCircle] children do.
class ShimmerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? cardColor;

  const ShimmerCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 16,
    this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor ??
            (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9F9F9)),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ClassesHomeScreenShimmer  —  full page skeleton for ClassesHomeScreen
//
// ┌─ HOW TO USE ────────────────────────────────────────────────────────────┐
// │                                                                         │
// │  // Replace homeShimmer() in _ClassesHomeScreenState with:             │
// │  Widget homeShimmer(BuildContext context) =>                            │
// │      ClassesHomeScreenShimmer(scrollController: scrollController);      │
// │                                                                         │
// │  // To try different animation styles:                                  │
// │  ClassesHomeScreenShimmer(style: ShimmerStyle.wave)                     │
// │  ClassesHomeScreenShimmer(style: ShimmerStyle.pulse)                    │
// │  ClassesHomeScreenShimmer(style: ShimmerStyle.shimmerGlow)              │
// │  ClassesHomeScreenShimmer(style: ShimmerStyle.sweep)  ← default        │
// │                                                                         │
// └─────────────────────────────────────────────────────────────────────────┘
// ═════════════════════════════════════════════════════════════════════════════