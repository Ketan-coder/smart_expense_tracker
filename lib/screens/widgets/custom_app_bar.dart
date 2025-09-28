import 'dart:math' as math;

import 'package:flutter/material.dart';

class SmartCustomAppBar extends StatefulWidget {
  final String title;
  final bool isCollapsible;
  final Widget child;
  final List<Widget>? actions;
  final double expandedHeight;
  final Color? backgroundColor;
  final Color? titleColor;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final Widget? leading;
  final bool pinned;
  final bool floating;
  final Function? onRefresh;
  final ScrollController? scrollController;
  final bool hasContent;

  const SmartCustomAppBar({
    super.key,
    required this.title,
    required this.child,
    required this.hasContent,
    this.isCollapsible = true,
    this.actions,
    this.expandedHeight = 200.0, // Reduced from 250
    this.backgroundColor,
    this.titleColor,
    this.titleFontSize = 32, // Reduced from 48
    this.titleFontWeight = FontWeight.w700,
    this.leading,
    this.pinned = true,
    this.floating = false,
    this.onRefresh,
    this.scrollController,
  });

  @override
  State<SmartCustomAppBar> createState() => _SmartCustomAppBarState();
}

class _SmartCustomAppBarState extends State<SmartCustomAppBar> {
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  // Calculate title opacity and size based on scroll
  double get _titleOpacity {
    if (!widget.isCollapsible || !widget.hasContent) return 1.0;

    final double maxScroll = widget.expandedHeight - kToolbarHeight;
    final double opacity = (1.0 - (_scrollOffset / (maxScroll * 0.7))).clamp(0.0, 1.0);
    return opacity;
  }

  // Calculate title size for smooth transition
  double get _titleSize {
    if (!widget.isCollapsible || !widget.hasContent) return 20.0;

    final double maxScroll = widget.expandedHeight - kToolbarHeight;
    final double progress = (_scrollOffset / maxScroll).clamp(0.0, 1.0);
    return widget.titleFontSize * (1.0 - progress) + 20.0 * progress;
  }

  // Calculate title position
  double get _titleBottom {
    if (!widget.isCollapsible || !widget.hasContent) return 16.0;

    final double maxScroll = widget.expandedHeight - kToolbarHeight;
    final double progress = (_scrollOffset / maxScroll).clamp(0.0, 1.0);
    final double startBottom = (widget.actions != null) ? 70.0 : 20.0;
    return startBottom * (1.0 - progress) + 16.0 * progress;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use subtle colors instead of bright ones
    final backgroundColor = widget.backgroundColor ?? colorScheme.surface;
    final titleColor = widget.titleColor ?? colorScheme.onSurface;

    bool shouldCollapse = widget.isCollapsible && widget.hasContent;

    Widget buildScrollView() {
      return CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: backgroundColor,
            surfaceTintColor: backgroundColor,
            expandedHeight: shouldCollapse ? widget.expandedHeight : null,
            collapsedHeight: kToolbarHeight,
            toolbarHeight: kToolbarHeight,
            floating: widget.floating,
            pinned: widget.pinned,
            leading: widget.leading,
            // Show actions in collapsed state
            actions: shouldCollapse ?
            (_scrollOffset > (widget.expandedHeight - kToolbarHeight - 50) ? widget.actions : null)
                : widget.actions,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: backgroundColor,
                child: Stack(
                  children: [
                    // Title with smooth animation
                    Positioned(
                      left: 20,
                      bottom: _titleBottom,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _titleOpacity,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: TextStyle(
                            color: titleColor,
                            fontSize: shouldCollapse ? _titleSize : 20,
                            fontWeight: widget.titleFontWeight,
                          ),
                          child: Text(widget.title),
                        ),
                      ),
                    ),
                    // Actions at bottom when expanded
                    if (shouldCollapse && widget.actions != null)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _scrollOffset < (widget.expandedHeight - kToolbarHeight - 50) ? 1.0 : 0.0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: widget.actions!.map((action) {
                              if (action is IconButton) {
                                return Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: action.onPressed,
                                    icon: action.icon,
                                    color: colorScheme.primary,
                                  ),
                                );
                              }
                              return Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: action,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Show title in collapsed state
              title: shouldCollapse && _scrollOffset > (widget.expandedHeight - kToolbarHeight - 20)
                  ? Text(
                widget.title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              )
                  : null,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: backgroundColor,
              child: widget.child,
            ),
          ),
        ],
      );
    }

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: () async {
          await widget.onRefresh!();
        },
        child: buildScrollView(),
      );
    }

    return buildScrollView();
  }
}

// Simpler version with better color handling and smooth animations
class SimpleCustomAppBar extends StatefulWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool hasContent;
  final Function? onRefresh;
  final double expandedHeight; // New parameter for custom height
  final bool centerTitle; // New parameter to control centering

  const SimpleCustomAppBar({
    super.key,
    required this.title,
    required this.child,
    required this.hasContent,
    this.actions,
    this.onRefresh,
    this.expandedHeight = 180.0, // Default height
    this.centerTitle = true, // Default to centered
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

  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Setup smooth animations
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final double offset = _scrollController.offset;
    setState(() {
      _scrollOffset = offset;
    });

    const double expandedHeight = 180.0;
    const double collapsedHeight = kToolbarHeight;
    final double maxScroll = expandedHeight - collapsedHeight;
    final double animationProgress = (offset / maxScroll).clamp(0.0, 1.0);

    _animationController.value = animationProgress;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // final screenWidth = MediaQuery.of(context).size.width;

    final double expandedHeight = widget.expandedHeight;
    const double collapsedHeight = kToolbarHeight;

    // Calculate animation values with smooth curves
    final double maxScroll = expandedHeight - collapsedHeight;
    final double scrollProgress = (_scrollOffset / maxScroll).clamp(0.0, 1.0);

    // Use easing functions for smoother animations
    final double titleOpacity = _easeOutCubic(1.0 - scrollProgress * 1.2).clamp(0.0, 1.0);
    final double actionsOpacity = _easeOutCubic(1.0 - scrollProgress * 1.8).clamp(0.0, 1.0);
    final bool showCollapsedTitle = scrollProgress > 0.6;

    // Calculate title positioning
    // final double titleWidth = _calculateTextWidth(widget.title, TextStyle(
    //   fontSize: _interpolate(36.0, 20.0, scrollProgress),
    //   fontWeight: FontWeight.w700,
    // ), context);

    // True centering calculation
    // final double titleStartX = widget.centerTitle
    //     ? (screenWidth - titleWidth) / 2
    //     : 20.0;
    // final double titleEndX = 20.0;

    Widget buildContent() {
      return CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(), // Smoother scroll physics
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
            // Show actions only when collapsed with smooth transition
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
                    // Single title with smooth position interpolation
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
                          child: AnimatedDefaultTextStyle(
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
                        ),
                      ),
                    ),
                    // Bottom actions when expanded with smooth fade
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
                                       alpha:  actionsOpacity.clamp(0.0, 1.0)
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
              // Collapsed title that only shows when fully collapsed
              title: scrollProgress > 0.85
                  ? AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: ((scrollProgress - 0.85) / 0.15).clamp(0.0, 1.0), // Fixed: clamp opacity
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  : null,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
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

  // Helper function to calculate text width for proper centering
  // double _calculateTextWidth(String text, TextStyle style, BuildContext context) {
  //   final TextPainter textPainter = TextPainter(
  //     text: TextSpan(text: text, style: style),
  //     maxLines: 1,
  //     textDirection: TextDirection.ltr,
  //   );
  //   textPainter.layout();
  //   return textPainter.width;
  // }

  // Smooth interpolation function
  double _interpolate(double start, double end, double progress) {
    return start + (end - start) * progress;
  }

  // Easing function for smoother animations
  double _easeOutCubic(double t) {
    return 1.0 - math.pow(1.0 - t, 3.0);
  }
}

// // Import math for easing functions
// import 'dart:math' as math;
//
// // Example usage
// class ExampleUsage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SimpleCustomAppBar(
//         title: "Notebooks",
//         hasContent: true,
//         expandedHeight: 250.0, // Custom height!
//         centerTitle: true, // Center the title when expanded
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: Icon(Icons.logout),
//             onPressed: () {},
//           ),
//         ],
//         child: Column(
//           children: [
//             // Search bar
//             Container(
//               margin: const EdgeInsets.all(16),
//               child: TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Search notebooks',
//                   prefixIcon: Icon(Icons.search),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   filled: true,
//                 ),
//               ),
//             ),
//
//             // List items
//             ...List.generate(40, (index) => Column(
//               children: [
//                 ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.deepPurple,
//                     child: Text('${index + 1}', style: TextStyle(color: Colors.white)),
//                   ),
//                   title: Text('Item $index'),
//                   subtitle: Text('Subtitle for item $index'),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                 ),
//                 if (index < 39) Divider(height: 1),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Different height examples:
// class HeightExamples extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Small height
//         Expanded(
//           child: SimpleCustomAppBar(
//             title: "Small Header",
//             expandedHeight: 120.0,
//             hasContent: true,
//             child: Text("Content here"),
//           ),
//         ),
//
//         // Medium height
//         Expanded(
//           child: SimpleCustomAppBar(
//             title: "Medium Header",
//             expandedHeight: 200.0,
//             hasContent: true,
//             child: Text("Content here"),
//           ),
//         ),
//
//         // Large height
//         Expanded(
//           child: SimpleCustomAppBar(
//             title: "Large Header",
//             expandedHeight: 300.0,
//             hasContent: true,
//             child: Text("Content here"),
//           ),
//         ),
//
//         // Left-aligned title
//         Expanded(
//           child: SimpleCustomAppBar(
//             title: "Left Aligned",
//             expandedHeight: 180.0,
//             centerTitle: false, // Disable centering
//             hasContent: true,
//             child: Text("Content here"),
//           ),
//         ),
//       ],
//     );
//   }
// }