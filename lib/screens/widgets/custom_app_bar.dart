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
import 'dart:async';
import 'package:flutter/material.dart';

enum AnimationType {
  typeWriter,
  fadeInOut,
  slideInOut,
}

enum AnimationEffect {
  bounce,
  smooth,
  easeIn,
  easeOut,
  easeInOut,
}

class SimpleCustomAppBar extends StatefulWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool hasContent;
  final Function? onRefresh;
  final double expandedHeight;
  final bool centerTitle;

  // New animation parameters
  final List<String>? animatedTexts;
  final AnimationType animationType;
  final AnimationEffect animationEffect;
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
    this.animatedTexts,
    this.animationType = AnimationType.fadeInOut,
    this.animationEffect = AnimationEffect.smooth,
    this.animationDuration = const Duration(seconds: 3),
    this.animationRepeat = false,
  });

  @override
  State<SimpleCustomAppBar> createState() => _SimpleCustomAppBarState();
}

class _SimpleCustomAppBarState extends State<SimpleCustomAppBar>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // Text animation controllers
  late AnimationController _textAnimationController;
  Timer? _textAnimationTimer;
  int _currentTextIndex = 0;
  String _displayedText = '';

  double _scrollOffset = 0.0;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Setup smooth animations for scroll
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.5, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    // Setup text animation controller
    _textAnimationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Start text animations if provided
    if (widget.animatedTexts != null && widget.animatedTexts!.isNotEmpty) {
      _startTextAnimation();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _textAnimationController.dispose();
    _textAnimationTimer?.cancel();
    super.dispose();
  }

  void _startTextAnimation() {
    if (widget.animatedTexts == null || widget.animatedTexts!.isEmpty) return;

    _currentTextIndex = 0;
    _animateCurrentText();
  }

  void _animateCurrentText() {
    if (!_isExpanded) return; // Only animate when expanded

    final currentText = widget.animatedTexts![_currentTextIndex];

    switch (widget.animationType) {
      case AnimationType.typeWriter:
        _animateTypeWriter(currentText);
        break;
      case AnimationType.fadeInOut:
        _animateFadeInOut(currentText);
        break;
      case AnimationType.slideInOut:
        _animateSlideInOut(currentText);
        break;
    }
  }

  void _animateTypeWriter(String text) {
    _displayedText = '';
    int charIndex = 0;

    _textAnimationTimer?.cancel();
    _textAnimationTimer = Timer.periodic(
      Duration(milliseconds: (widget.animationDuration.inMilliseconds / text.length).round()),
          (timer) {
        if (!_isExpanded) {
          timer.cancel();
          return;
        }

        if (charIndex < text.length) {
          setState(() {
            _displayedText = text.substring(0, charIndex + 1);
          });
          charIndex++;
        } else {
          timer.cancel();
          _scheduleNextText();
        }
      },
    );
  }

  void _animateFadeInOut(String text) {
    setState(() {
      _displayedText = text;
    });

    _textAnimationController.reset();
    _textAnimationController.forward().then((_) {
      if (_isExpanded) {
        _scheduleNextText();
      }
    });
  }

  void _animateSlideInOut(String text) {
    setState(() {
      _displayedText = text;
    });

    _textAnimationController.reset();
    _textAnimationController.forward().then((_) {
      if (_isExpanded) {
        _scheduleNextText();
      }
    });
  }

  void _scheduleNextText() {
    if (widget.animatedTexts == null || !_isExpanded) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || !_isExpanded) return;

      if (widget.animationRepeat) {
        _currentTextIndex = (_currentTextIndex + 1) % widget.animatedTexts!.length;
        _animateCurrentText();
      } else if (_currentTextIndex < widget.animatedTexts!.length - 1) {
        _currentTextIndex++;
        _animateCurrentText();
      }
    });
  }

  Curve _getAnimationCurve() {
    switch (widget.animationEffect) {
      case AnimationEffect.bounce:
        return Curves.bounceOut;
      case AnimationEffect.smooth:
        return Curves.easeInOutCubic;
      case AnimationEffect.easeIn:
        return Curves.easeIn;
      case AnimationEffect.easeOut:
        return Curves.easeOut;
      case AnimationEffect.easeInOut:
        return Curves.easeInOut;
    }
  }

  void _onScroll() {
    final double offset = _scrollController.offset;
    setState(() {
      _scrollOffset = offset;
    });

    final double expandedHeight = widget.expandedHeight;
    const double collapsedHeight = kToolbarHeight;
    final double maxScroll = expandedHeight - collapsedHeight;
    final double animationProgress = (offset / maxScroll).clamp(0.0, 1.0);

    _animationController.value = animationProgress;

    // Check if we've collapsed
    final bool wasExpanded = _isExpanded;
    _isExpanded = animationProgress < 0.5;

    // Restart animation when expanding
    if (!wasExpanded && _isExpanded && widget.animatedTexts != null) {
      _startTextAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double expandedHeight = widget.expandedHeight;
    const double collapsedHeight = kToolbarHeight;

    final double maxScroll = expandedHeight - collapsedHeight;
    final double scrollProgress = (_scrollOffset / maxScroll).clamp(0.0, 1.0);

    final double titleOpacity = _easeOutCubic(1.0 - scrollProgress * 1.2).clamp(0.0, 1.0);
    final double actionsOpacity = _easeOutCubic(1.0 - scrollProgress * 1.8).clamp(0.0, 1.0);
    final bool showCollapsedTitle = scrollProgress > 0.6;

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
            floating: false,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 1,
            actions: showCollapsedTitle ? widget.actions?.map((action) {
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: scrollProgress > 0.7 ? 1.0 : 0.0,
                child: action,
              );
            }).toList() : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: colorScheme.surface,
                child: Stack(
                  children: [
                    // Main title and animated text
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        alignment: widget.centerTitle
                            ? Alignment.lerp(
                            Alignment.center,
                            Alignment.centerLeft,
                            scrollProgress
                        )!
                            : Alignment.centerLeft,
                        padding: EdgeInsets.only(
                          left: widget.centerTitle
                              ? _interpolate(0, 20, scrollProgress)
                              : 20,
                          bottom: widget.actions != null
                              ? _interpolate(0, 50, scrollProgress)
                              : 0,
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: titleOpacity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: widget.centerTitle && scrollProgress < 0.5
                                ? CrossAxisAlignment.center
                                : CrossAxisAlignment.start,
                            children: [
                              // Static title
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: _interpolate(36.0, 20.0, scrollProgress),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: _interpolate(0.5, 0.0, scrollProgress),
                                ),
                                child: Text(
                                  widget.title,
                                  textAlign: widget.centerTitle && scrollProgress < 0.5
                                      ? TextAlign.center
                                      : TextAlign.left,
                                ),
                              ),

                              // Animated text (only when expanded)
                              if (widget.animatedTexts != null &&
                                  widget.animatedTexts!.isNotEmpty &&
                                  _isExpanded)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: _buildAnimatedText(colorScheme, scrollProgress),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom actions when expanded
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
                                    color: colorScheme.primaryContainer.withValues(
                                        alpha: actionsOpacity.clamp(0.0, 1.0)
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: actionsOpacity > 0.3 ? [
                                      BoxShadow(
                                        color: colorScheme.shadow.withValues(alpha: 0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ] : [],
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
          SliverToBoxAdapter(
            child: widget.child,
          ),
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

  Widget _buildAnimatedText(ColorScheme colorScheme, double scrollProgress) {
    final textStyle = TextStyle(
      color: colorScheme.onSurface.withValues(alpha: 0.7),
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.3,
    );

    switch (widget.animationType) {
      case AnimationType.typeWriter:
        return Text(
          _displayedText,
          style: textStyle,
          textAlign: widget.centerTitle && scrollProgress < 0.5
              ? TextAlign.center
              : TextAlign.left,
        );

      case AnimationType.fadeInOut:
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _textAnimationController,
            curve: _getAnimationCurve(),
          ),
          child: Text(
            _displayedText,
            style: textStyle,
            textAlign: widget.centerTitle && scrollProgress < 0.5
                ? TextAlign.center
                : TextAlign.left,
          ),
        );

      case AnimationType.slideInOut:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _textAnimationController,
            curve: _getAnimationCurve(),
          )),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _textAnimationController,
              curve: _getAnimationCurve(),
            ),
            child: Text(
              _displayedText,
              style: textStyle,
              textAlign: widget.centerTitle && scrollProgress < 0.5
                  ? TextAlign.center
                  : TextAlign.left,
            ),
          ),
        );
    }
  }

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

// Example usage demonstrating all animation types
class ExampleUsage extends StatelessWidget {
  const ExampleUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SimpleCustomAppBar(
        title: "My Notebooks",
        hasContent: true,
        expandedHeight: 250.0,
        centerTitle: true,

        // Animated text configuration
        animatedTexts: [
          "Create, organize, and share your ideas",
          "Collaborate with your team in real-time",
          "Access your notes from anywhere",
          "Stay productive and organized"
        ],
        animationType: AnimationType.fadeInOut,
        animationEffect: AnimationEffect.smooth,
        animationDuration: const Duration(seconds: 3),
        animationRepeat: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {},
          ),
        ],
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search notebooks',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
            ),
            ...List.generate(40, (index) => Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text('Notebook $index'),
                  subtitle: Text('Last edited ${index + 1} days ago'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
                if (index < 39) const Divider(height: 1),
              ],
            )),
          ],
        ),
      ),
    );
  }
}

// Different animation type examples
class AnimationExamples extends StatelessWidget {
  const AnimationExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Animation Examples'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'TypeWriter'),
              Tab(text: 'Fade In/Out'),
              Tab(text: 'Slide In/Out'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TypeWriter Animation
            SimpleCustomAppBar(
              title: "TypeWriter Effect",
              hasContent: true,
              expandedHeight: 220.0,
              animatedTexts: const [
                "Watch the text appear character by character...",
                "This creates a typing effect!",
                "Perfect for storytelling"
              ],
              animationType: AnimationType.typeWriter,
              animationEffect: AnimationEffect.smooth,
              animationDuration: const Duration(seconds: 4),
              animationRepeat: true,
              child: const Center(child: Text('Scroll to see animation')),
            ),

            // Fade In/Out Animation
            SimpleCustomAppBar(
              title: "Fade Effect",
              hasContent: true,
              expandedHeight: 220.0,
              animatedTexts: const [
                "Smooth fade transitions",
                "Elegant and professional",
                "Great for subtle messaging"
              ],
              animationType: AnimationType.fadeInOut,
              animationEffect: AnimationEffect.easeInOut,
              animationDuration: const Duration(seconds: 2),
              animationRepeat: true,
              child: const Center(child: Text('Scroll to see animation')),
            ),

            // Slide In/Out Animation
            SimpleCustomAppBar(
              title: "Slide Effect",
              hasContent: true,
              expandedHeight: 220.0,
              animatedTexts: const [
                "Dynamic slide animations",
                "Catches user attention",
                "Modern and engaging"
              ],
              animationType: AnimationType.slideInOut,
              animationEffect: AnimationEffect.bounce,
              animationDuration: const Duration(milliseconds: 1500),
              animationRepeat: true,
              child: const Center(child: Text('Scroll to see animation')),
            ),
          ],
        ),
      ),
    );
  }
}