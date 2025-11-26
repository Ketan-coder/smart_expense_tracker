// import 'dart:math' as math;
//
// import 'package:flutter/material.dart';
//
// class SimpleCustomAppBar extends StatefulWidget {
//   final String title;
//   final Widget child;
//   final List<Widget>? actions;
//   final bool hasContent;
//   final Function? onRefresh;
//   final double expandedHeight; // New parameter for custom height
//   final bool centerTitle; // New parameter to control centering
//
//   const SimpleCustomAppBar({
//     super.key,
//     required this.title,
//     required this.child,
//     required this.hasContent,
//     this.actions,
//     this.onRefresh,
//     this.expandedHeight = 180.0, // Default height
//     this.centerTitle = true, // Default to centered
//   });
//
//   @override
//   State<SimpleCustomAppBar> createState() => _SimpleCustomAppBarState();
// }
//
// class _SimpleCustomAppBarState extends State<SimpleCustomAppBar>
//     with TickerProviderStateMixin {
//   final ScrollController _scrollController = ScrollController();
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   double _scrollOffset = 0.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll);
//
//     // Setup smooth animations
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//
//     _fadeAnimation = Tween<double>(
//       begin: 1.0,
//       end: 0.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOutCubic,
//     ));
//
//     _scaleAnimation = Tween<double>(
//       begin: 1.0,
//       end: 0.8,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOutCubic,
//     ));
//
//     _slideAnimation = Tween<Offset>(
//       begin: Offset.zero,
//       end: const Offset(-0.5, 0),
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOutCubic,
//     ));
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   void _onScroll() {
//     final double offset = _scrollController.offset;
//     setState(() {
//       _scrollOffset = offset;
//     });
//
//     const double expandedHeight = 180.0;
//     const double collapsedHeight = kToolbarHeight;
//     final double maxScroll = expandedHeight - collapsedHeight;
//     final double animationProgress = (offset / maxScroll).clamp(0.0, 1.0);
//
//     _animationController.value = animationProgress;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     // final screenWidth = MediaQuery.of(context).size.width;
//
//     final double expandedHeight = widget.expandedHeight;
//     const double collapsedHeight = kToolbarHeight;
//
//     // Calculate animation values with smooth curves
//     final double maxScroll = expandedHeight - collapsedHeight;
//     final double scrollProgress = (_scrollOffset / maxScroll).clamp(0.0, 1.0);
//
//     // Use easing functions for smoother animations
//     final double titleOpacity = _easeOutCubic(1.0 - scrollProgress * 1.2).clamp(0.0, 1.0);
//     final double actionsOpacity = _easeOutCubic(1.0 - scrollProgress * 1.8).clamp(0.0, 1.0);
//     final bool showCollapsedTitle = scrollProgress > 0.6;
//
//     // Calculate title positioning
//     // final double titleWidth = _calculateTextWidth(widget.title, TextStyle(
//     //   fontSize: _interpolate(36.0, 20.0, scrollProgress),
//     //   fontWeight: FontWeight.w700,
//     // ), context);
//
//     // True centering calculation
//     // final double titleStartX = widget.centerTitle
//     //     ? (screenWidth - titleWidth) / 2
//     //     : 20.0;
//     // final double titleEndX = 20.0;
//
//     Widget buildContent() {
//       return CustomScrollView(
//         controller: _scrollController,
//         physics: const BouncingScrollPhysics(), // Smoother scroll physics
//         slivers: [
//           SliverAppBar(
//             backgroundColor: colorScheme.surface,
//             surfaceTintColor: colorScheme.surface,
//             expandedHeight: widget.hasContent ? expandedHeight : collapsedHeight + 20,
//             collapsedHeight: collapsedHeight,
//             toolbarHeight: collapsedHeight,
//             floating: false,
//             pinned: true,
//             elevation: 0,
//             scrolledUnderElevation: 1,
//             // Show actions only when collapsed with smooth transition
//             actions: showCollapsedTitle ? widget.actions?.map((action) {
//               return AnimatedOpacity(
//                 duration: const Duration(milliseconds: 200),
//                 opacity: scrollProgress > 0.7 ? 1.0 : 0.0,
//                 child: action,
//               );
//             }).toList() : null,
//             flexibleSpace: FlexibleSpaceBar(
//               background: Container(
//                 color: colorScheme.surface,
//                 child: Stack(
//                   children: [
//                     // Single title with smooth position interpolation
//                     Positioned.fill(
//                       child: AnimatedContainer(
//                         duration: const Duration(milliseconds: 200),
//                         curve: Curves.easeOutCubic,
//                         alignment: widget.centerTitle
//                             ? Alignment.lerp(
//                             Alignment.center,
//                             Alignment.centerLeft,
//                             scrollProgress
//                         )!
//                             : Alignment.centerLeft,
//                         padding: EdgeInsets.only(
//                           left: widget.centerTitle
//                               ? _interpolate(0, 20, scrollProgress)
//                               : 20,
//                           bottom: widget.actions != null
//                               ? _interpolate(0, 50, scrollProgress)
//                               : 0,
//                         ),
//                         child: AnimatedOpacity(
//                           duration: const Duration(milliseconds: 150),
//                           opacity: titleOpacity,
//                           child: AnimatedDefaultTextStyle(
//                             duration: const Duration(milliseconds: 200),
//                             curve: Curves.easeOutCubic,
//                             style: TextStyle(
//                               color: colorScheme.onSurface,
//                               fontSize: _interpolate(36.0, 20.0, scrollProgress),
//                               fontWeight: FontWeight.w700,
//                               letterSpacing: _interpolate(0.5, 0.0, scrollProgress),
//                             ),
//                             child: Text(
//                               widget.title,
//                               textAlign: widget.centerTitle && scrollProgress < 0.5
//                                   ? TextAlign.center
//                                   : TextAlign.left,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     // Bottom actions when expanded with smooth fade
//                     if (widget.actions != null)
//                       Positioned(
//                         right: 20,
//                         bottom: 16,
//                         child: AnimatedOpacity(
//                           duration: const Duration(milliseconds: 200),
//                           curve: Curves.easeOutCubic,
//                           opacity: actionsOpacity,
//                           child: AnimatedScale(
//                             duration: const Duration(milliseconds: 200),
//                             curve: Curves.easeOutCubic,
//                             scale: _interpolate(1.0, 0.8, scrollProgress).clamp(0.0, 1.0),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: widget.actions!.asMap().entries.map((entry) {
//                                 final int index = entry.key;
//                                 final Widget action = entry.value;
//
//                                 return AnimatedContainer(
//                                   duration: Duration(milliseconds: 150 + (index * 25)),
//                                   curve: Curves.easeOutCubic,
//                                   margin: const EdgeInsets.only(left: 8),
//                                   decoration: BoxDecoration(
//                                     color: colorScheme.primaryContainer.withValues(
//                                        alpha:  actionsOpacity.clamp(0.0, 1.0)
//                                     ),
//                                     borderRadius: BorderRadius.circular(16),
//                                     boxShadow: actionsOpacity > 0.3 ? [
//                                       BoxShadow(
//                                         color: colorScheme.shadow.withValues(alpha: 0.1),
//                                         blurRadius: 6,
//                                         offset: const Offset(0, 2),
//                                       ),
//                                     ] : [],
//                                   ),
//                                   child: action is IconButton
//                                       ? IconButton(
//                                     onPressed: action.onPressed,
//                                     icon: action.icon,
//                                     color: colorScheme.onPrimaryContainer,
//                                     splashRadius: 20,
//                                   )
//                                       : action,
//                                 );
//                               }).toList(),
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//               // Collapsed title that only shows when fully collapsed
//               // title: scrollProgress > 0.85
//               //     ? AnimatedOpacity(
//               //   duration: const Duration(milliseconds: 100),
//               //   opacity: ((scrollProgress - 0.85) / 0.15).clamp(0.0, 1.0), // Fixed: clamp opacity
//               //   child: Text(
//               //     widget.title,
//               //     style: TextStyle(
//               //       color: colorScheme.onSurface,
//               //       fontSize: 20,
//               //       fontWeight: FontWeight.w600,
//               //     ),
//               //   ),
//               // )
//               //     : null,
//               // titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
//
//               // Collapsed title that only shows when fully collapsed
//               title: scrollProgress > 0.85
//                   ? AnimatedOpacity(
//                 duration: const Duration(milliseconds: 100),
//                 opacity: ((scrollProgress - 0.85) / 0.15).clamp(0.0, 1.0),
//                 child: Builder(
//                   builder: (context) {
//                     // Detect if there's an automatically added back button
//                     final bool hasBackButton = _hasAutomaticBackButton(context);
//
//                     return Padding(
//                       padding: EdgeInsets.only(
//                         left: hasBackButton ? 48.0 : 16.0,
//                         bottom: 16,
//                       ),
//                       child: Text(
//                         widget.title,
//                         style: TextStyle(
//                           color: colorScheme.onSurface,
//                           fontSize: 20,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               )
//                   : null,
//               titlePadding: EdgeInsets.only(
//                   left: _hasAutomaticBackButton(context) ? 10 : 0,
//               ),
//             ),
//           ),
//           SliverToBoxAdapter(
//             child: widget.child,
//           ),
//         ],
//       );
//     }
//
//     if (widget.onRefresh != null) {
//       return RefreshIndicator(
//         onRefresh: () async => await widget.onRefresh!(),
//         child: buildContent(),
//       );
//     }
//
//     return buildContent();
//   }
//
//   // Helper function to calculate text width for proper centering
//   // double _calculateTextWidth(String text, TextStyle style, BuildContext context) {
//   //   final TextPainter textPainter = TextPainter(
//   //     text: TextSpan(text: text, style: style),
//   //     maxLines: 1,
//   //     textDirection: TextDirection.ltr,
//   //   );
//   //   textPainter.layout();
//   //   return textPainter.width;
//   // }
//
//   // Smooth interpolation function
//   double _interpolate(double start, double end, double progress) {
//     return start + (end - start) * progress;
//   }
//
//   bool _hasAutomaticBackButton(BuildContext context) {
//     final navigator = Navigator.of(context);
//     final route = ModalRoute.of(context);
//
//     // debugPrint('Can pop: ${navigator.canPop()}');
//     // debugPrint('Route name: ${route?.settings.name}');
//     // debugPrint('Is first: ${route?.isFirst}');
//
//     // Only add padding when we can pop AND we're not on the main/home screen
//     return navigator.canPop() && route?.settings.name != '/';
//   }
//
//   // Easing function for smoother animations
//   double _easeOutCubic(double t) {
//     return 1.0 - math.pow(1.0 - t, 3.0);
//   }
// }
//
// // // Import math for easing functions
// // import 'dart:math' as math;
// //
// // // Example usage
// // class ExampleUsage extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: SimpleCustomAppBar(
// //         title: "Notebooks",
// //         hasContent: true,
// //         expandedHeight: 250.0, // Custom height!
// //         centerTitle: true, // Center the title when expanded
// //         actions: [
// //           IconButton(
// //             icon: Icon(Icons.refresh),
// //             onPressed: () {},
// //           ),
// //           IconButton(
// //             icon: Icon(Icons.logout),
// //             onPressed: () {},
// //           ),
// //         ],
// //         child: Column(
// //           children: [
// //             // Search bar
// //             Container(
// //               margin: const EdgeInsets.all(16),
// //               child: TextField(
// //                 decoration: InputDecoration(
// //                   hintText: 'Search notebooks',
// //                   prefixIcon: Icon(Icons.search),
// //                   border: OutlineInputBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                   filled: true,
// //                 ),
// //               ),
// //             ),
// //
// //             // List items
// //             ...List.generate(40, (index) => Column(
// //               children: [
// //                 ListTile(
// //                   leading: CircleAvatar(
// //                     backgroundColor: Colors.deepPurple,
// //                     child: Text('${index + 1}', style: TextStyle(color: Colors.white)),
// //                   ),
// //                   title: Text('Item $index'),
// //                   subtitle: Text('Subtitle for item $index'),
// //                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
// //                 ),
// //                 if (index < 39) Divider(height: 1),
// //               ],
// //             )),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // Different height examples:
// // class HeightExamples extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Column(
// //       children: [
// //         // Small height
// //         Expanded(
// //           child: SimpleCustomAppBar(
// //             title: "Small Header",
// //             expandedHeight: 120.0,
// //             hasContent: true,
// //             child: Text("Content here"),
// //           ),
// //         ),
// //
// //         // Medium height
// //         Expanded(
// //           child: SimpleCustomAppBar(
// //             title: "Medium Header",
// //             expandedHeight: 200.0,
// //             hasContent: true,
// //             child: Text("Content here"),
// //           ),
// //         ),
// //
// //         // Large height
// //         Expanded(
// //           child: SimpleCustomAppBar(
// //             title: "Large Header",
// //             expandedHeight: 300.0,
// //             hasContent: true,
// //             child: Text("Content here"),
// //           ),
// //         ),
// //
// //         // Left-aligned title
// //         Expanded(
// //           child: SimpleCustomAppBar(
// //             title: "Left Aligned",
// //             expandedHeight: 180.0,
// //             centerTitle: false, // Disable centering
// //             hasContent: true,
// //             child: Text("Content here"),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }

import 'dart:math' as math;
import 'package:flutter/material.dart';

// 1. Define Animation Enums
enum AppBarAnimationType {
  typeWriter,
  fadeIn,
  slideIn,
}

enum AppBarAnimationEffect {
  bounce,
  smooth,
  easeIn,
  easeInOut,
}

class SimpleCustomAppBar extends StatefulWidget {
  final String title;
  final String? animatedText; // Optional specific text to animate
  final Widget child;
  final List<Widget>? actions;
  final bool hasContent;
  final Function? onRefresh;
  final double expandedHeight;
  final bool centerTitle;

  // New Animation Parameters
  final AppBarAnimationType animationType;
  final AppBarAnimationEffect animationEffect;
  final Duration animationDuration;
  final bool animationRepeat;

  const SimpleCustomAppBar({
    super.key,
    required this.title,
    required this.child,
    required this.hasContent,
    this.actions,
    this.onRefresh,
    this.expandedHeight = 180.0,
    this.centerTitle = true,
    // Animation Defaults
    this.animatedText,
    this.animationType = AppBarAnimationType.fadeIn,
    this.animationEffect = AppBarAnimationEffect.smooth,
    this.animationDuration = const Duration(milliseconds: 600),
    this.animationRepeat = false,
  });

  @override
  State<SimpleCustomAppBar> createState() => _SimpleCustomAppBarState();
}

class _SimpleCustomAppBarState extends State<SimpleCustomAppBar>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // Controller for the Title Entrance Animation
  late AnimationController _titleAnimController;
  late Animation<double> _titleCurveAnimation;

  double _scrollOffset = 0.0;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize Title Animation Controller
    _titleAnimController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Determine Curve based on Effect
    Curve curve;
    switch (widget.animationEffect) {
      case AppBarAnimationEffect.bounce:
        curve = Curves.bounceOut;
        break;
      case AppBarAnimationEffect.easeIn:
        curve = Curves.easeIn;
        break;
      case AppBarAnimationEffect.easeInOut:
        curve = Curves.easeInOut;
        break;
      case AppBarAnimationEffect.smooth:
      default:
        curve = Curves.easeInOutCubic; // Premium smooth feel
        break;
    }

    _titleCurveAnimation = CurvedAnimation(
      parent: _titleAnimController,
      curve: curve,
    );

    // Start Animation
    _playAnimation();
  }

  void _playAnimation() {
    if (widget.animationRepeat) {
      _titleAnimController.repeat(reverse: true);
    } else {
      _titleAnimController.forward();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleAnimController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final double offset = _scrollController.offset;

    // Logic to pause animation when collapsed (Save Battery/Resources)
    const double kToolbarThreshold = kToolbarHeight * 1.5;
    final bool currentlyCollapsed = offset > (widget.expandedHeight - kToolbarThreshold);

    if (currentlyCollapsed != _isCollapsed) {
      _isCollapsed = currentlyCollapsed;
      if (_isCollapsed) {
        _titleAnimController.stop(); // Pause when minimized
      } else {
        if (_titleAnimController.status != AnimationStatus.completed || widget.animationRepeat) {
          _playAnimation(); // Resume if not done or repeating
        }
      }
    }

    setState(() {
      _scrollOffset = offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double expandedHeight = widget.expandedHeight;
    const double collapsedHeight = kToolbarHeight;

    // Calculate scroll progress (0.0 = Expanded, 1.0 = Collapsed)
    final double maxScroll = expandedHeight - collapsedHeight;
    final double scrollProgress = (_scrollOffset / maxScroll).clamp(0.0, 1.0);

    // Interpolations for scroll effects
    final double titleOpacity = _easeOutCubic(1.0 - scrollProgress * 1.2).clamp(0.0, 1.0);
    final double actionsOpacity = _easeOutCubic(1.0 - scrollProgress * 1.8).clamp(0.0, 1.0);
    final bool showCollapsedTitle = scrollProgress > 0.6;

    // Determine text content
    final String textContent = widget.animatedText ?? widget.title;

    Widget buildContent() {
      return CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surface,
            expandedHeight: widget.hasContent ? expandedHeight : collapsedHeight + 20,
            collapsedHeight: collapsedHeight,
            toolbarHeight: collapsedHeight,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 1,

            // --- 1. Collapsed Actions (Fade In) ---
            actions: showCollapsedTitle
                ? widget.actions?.map((action) {
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: scrollProgress > 0.7 ? 1.0 : 0.0,
                child: action,
              );
            }).toList()
                : null,

            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: colorScheme.surface,
                child: Stack(
                  children: [
                    // --- 2. Expanded Animated Title ---
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        // Move alignment based on scroll
                        alignment: widget.centerTitle
                            ? Alignment.lerp(
                            Alignment.center, Alignment.centerLeft, scrollProgress)!
                            : Alignment.centerLeft,
                        padding: EdgeInsets.only(
                          left: widget.centerTitle ? _interpolate(0, 20, scrollProgress) : 20,
                          // Move up slightly as we scroll
                          bottom: widget.actions != null ? _interpolate(0, 50, scrollProgress) : 0,
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: titleOpacity, // Fades out on scroll
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              // Shrink size on scroll
                              fontSize: _interpolate(36.0, 20.0, scrollProgress),
                              fontWeight: FontWeight.w700,
                              letterSpacing: _interpolate(0.5, 0.0, scrollProgress),
                            ),
                            child: _buildAnimatedTitleWidget(textContent),
                          ),
                        ),
                      ),
                    ),

                    // --- 3. Expanded Actions (Bottom Right) ---
                    if (widget.actions != null)
                      Positioned(
                        right: 20,
                        bottom: 16,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          opacity: actionsOpacity,
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            scale: _interpolate(1.0, 0.8, scrollProgress).clamp(0.0, 1.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: widget.actions!.asMap().entries.map((entry) {
                                final int index = entry.key;
                                final Widget action = entry.value;
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 150 + (index * 25)),
                                  curve: Curves.easeOutCubic,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer.withOpacity(
                                        actionsOpacity.clamp(0.0, 1.0)),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: actionsOpacity > 0.3
                                        ? [
                                      BoxShadow(
                                        color: colorScheme.shadow.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                        : [],
                                  ),
                                  child: action is IconButton
                                      ? IconButton(
                                    onPressed: action.onPressed,
                                    icon: action.icon,
                                    color: colorScheme.onPrimaryContainer,
                                    splashRadius: 20,
                                  )
                                      : action,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // --- 4. Collapsed Title (Standard) ---
              title: scrollProgress > 0.85
                  ? AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: ((scrollProgress - 0.85) / 0.15).clamp(0.0, 1.0),
                child: Builder(
                  builder: (context) {
                    final bool hasBackButton = _hasAutomaticBackButton(context);
                    return Padding(
                      padding: EdgeInsets.only(
                        left: hasBackButton ? 48.0 : 16.0,
                        bottom: 16,
                      ),
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              )
                  : null,
              titlePadding: EdgeInsets.only(
                left: _hasAutomaticBackButton(context) ? 10 : 0,
              ),
            ),
          ),
          SliverToBoxAdapter(child: widget.child),
        ],
      );
    }

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: () async => await widget.onRefresh!(),
        child: buildContent(),
      );
    }

    return buildContent();
  }

  /// Builds the specific animation based on [AppBarAnimationType]
  Widget _buildAnimatedTitleWidget(String text) {
    return AnimatedBuilder(
      animation: _titleCurveAnimation,
      builder: (context, child) {
        switch (widget.animationType) {
        // 1. TypeWriter Effect
          case AppBarAnimationType.typeWriter:
            final int len = text.length;
            final int currentLen = (_titleCurveAnimation.value * len).round();
            return Text(
              text.substring(0, currentLen.clamp(0, len)),
              textAlign: widget.centerTitle ? TextAlign.center : TextAlign.left,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            );

        // 2. Slide In Effect
          case AppBarAnimationType.slideIn:
          // Slides from bottom-left offset to zero
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _titleCurveAnimation.value)),
              child: Opacity(
                opacity: _titleCurveAnimation.value.clamp(0.0, 1.0),
                child: Text(
                  text,
                  textAlign: widget.centerTitle ? TextAlign.center : TextAlign.left,
                ),
              ),
            );

        // 3. Fade In Effect (Default)
          case AppBarAnimationType.fadeIn:
          default:
            return Opacity(
              opacity: _titleCurveAnimation.value.clamp(0.0, 1.0),
              child: Text(
                text,
                textAlign: widget.centerTitle ? TextAlign.center : TextAlign.left,
              ),
            );
        }
      },
    );
  }

  // --- Helpers ---

  double _interpolate(double start, double end, double progress) {
    return start + (end - start) * progress;
  }

  bool _hasAutomaticBackButton(BuildContext context) {
    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context);
    return navigator.canPop() && route?.settings.name != '/';
  }

  double _easeOutCubic(double t) {
    return 1.0 - math.pow(1.0 - t, 3.0);
  }
}