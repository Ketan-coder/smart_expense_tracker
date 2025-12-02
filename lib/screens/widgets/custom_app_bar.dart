// import 'dart:math' as math;
// import 'dart:async';
// import 'package:flutter/material.dart';
//
// enum AnimationType {
//   typeWriter,
//   fadeInOut,
//   slideInOut,
// }
//
// enum AnimationEffect {
//   bounce,
//   smooth,
//   easeIn,
//   easeOut,
//   easeInOut,
// }
//
// class SimpleCustomAppBar extends StatefulWidget {
//   final String title;
//   final Widget child;
//   final List<Widget>? actions;
//   final bool hasContent;
//   final Function? onRefresh;
//   final double expandedHeight;
//   final bool centerTitle;
//
//   // New animation parameters
//   final List<String>? animatedTexts;
//   final AnimationType animationType;
//   final AnimationEffect animationEffect;
//   final Duration animationDuration;
//   final bool animationRepeat;
//
//   const SimpleCustomAppBar({
//     super.key,
//     required this.title,
//     required this.child,
//     required this.hasContent,
//     this.actions,
//     this.onRefresh,
//     this.expandedHeight = 180.0,
//     this.centerTitle = true,
//     this.animatedTexts,
//     this.animationType = AnimationType.fadeInOut,
//     this.animationEffect = AnimationEffect.smooth,
//     this.animationDuration = const Duration(seconds: 3),
//     this.animationRepeat = false,
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
//   // Text animation controllers
//   late AnimationController _textAnimationController;
//   Timer? _textAnimationTimer;
//   int _currentTextIndex = 0;
//   String _displayedText = '';
//
//   double _scrollOffset = 0.0;
//   bool _isExpanded = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll);
//
//     // Setup smooth animations for scroll
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
//
//     // Setup text animation controller
//     _textAnimationController = AnimationController(
//       duration: widget.animationDuration,
//       vsync: this,
//     );
//
//     // Start text animations if provided
//     if (widget.animatedTexts != null && widget.animatedTexts!.isNotEmpty) {
//       _startTextAnimation();
//     }
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _animationController.dispose();
//     _textAnimationController.dispose();
//     _textAnimationTimer?.cancel();
//     super.dispose();
//   }
//
//   void _startTextAnimation() {
//     if (widget.animatedTexts == null || widget.animatedTexts!.isEmpty) return;
//
//     _currentTextIndex = 0;
//     _animateCurrentText();
//   }
//
//   void _animateCurrentText() {
//     if (!_isExpanded) return; // Only animate when expanded
//
//     final currentText = widget.animatedTexts![_currentTextIndex];
//
//     switch (widget.animationType) {
//       case AnimationType.typeWriter:
//         _animateTypeWriter(currentText);
//         break;
//       case AnimationType.fadeInOut:
//         _animateFadeInOut(currentText);
//         break;
//       case AnimationType.slideInOut:
//         _animateSlideInOut(currentText);
//         break;
//     }
//   }
//
//   void _animateTypeWriter(String text) {
//     _displayedText = '';
//     int charIndex = 0;
//
//     _textAnimationTimer?.cancel();
//     _textAnimationTimer = Timer.periodic(
//       Duration(milliseconds: (widget.animationDuration.inMilliseconds / text.length).round()),
//           (timer) {
//         if (!_isExpanded) {
//           timer.cancel();
//           return;
//         }
//
//         if (charIndex < text.length) {
//           setState(() {
//             _displayedText = text.substring(0, charIndex + 1);
//           });
//           charIndex++;
//         } else {
//           timer.cancel();
//           _scheduleNextText();
//         }
//       },
//     );
//   }
//
//   void _animateFadeInOut(String text) {
//     setState(() {
//       _displayedText = text;
//     });
//
//     _textAnimationController.reset();
//     _textAnimationController.forward().then((_) {
//       if (_isExpanded) {
//         _scheduleNextText();
//       }
//     });
//   }
//
//   void _animateSlideInOut(String text) {
//     setState(() {
//       _displayedText = text;
//     });
//
//     _textAnimationController.reset();
//     _textAnimationController.forward().then((_) {
//       if (_isExpanded) {
//         _scheduleNextText();
//       }
//     });
//   }
//
//   void _scheduleNextText() {
//     if (widget.animatedTexts == null || !_isExpanded) return;
//
//     Future.delayed(const Duration(milliseconds: 500), () {
//       if (!mounted || !_isExpanded) return;
//
//       if (widget.animationRepeat) {
//         _currentTextIndex = (_currentTextIndex + 1) % widget.animatedTexts!.length;
//         _animateCurrentText();
//       } else if (_currentTextIndex < widget.animatedTexts!.length - 1) {
//         _currentTextIndex++;
//         _animateCurrentText();
//       }
//     });
//   }
//
//   Curve _getAnimationCurve() {
//     switch (widget.animationEffect) {
//       case AnimationEffect.bounce:
//         return Curves.bounceOut;
//       case AnimationEffect.smooth:
//         return Curves.easeInOutCubic;
//       case AnimationEffect.easeIn:
//         return Curves.easeIn;
//       case AnimationEffect.easeOut:
//         return Curves.easeOut;
//       case AnimationEffect.easeInOut:
//         return Curves.easeInOut;
//     }
//   }
//
//   void _onScroll() {
//     final double offset = _scrollController.offset;
//     setState(() {
//       _scrollOffset = offset;
//     });
//
//     final double expandedHeight = widget.expandedHeight;
//     const double collapsedHeight = kToolbarHeight;
//     final double maxScroll = expandedHeight - collapsedHeight;
//     final double animationProgress = (offset / maxScroll).clamp(0.0, 1.0);
//
//     _animationController.value = animationProgress;
//
//     // Check if we've collapsed
//     final bool wasExpanded = _isExpanded;
//     _isExpanded = animationProgress < 0.5;
//
//     // Restart animation when expanding
//     if (!wasExpanded && _isExpanded && widget.animatedTexts != null) {
//       _startTextAnimation();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     final double expandedHeight = widget.expandedHeight;
//     const double collapsedHeight = kToolbarHeight;
//
//     final double maxScroll = expandedHeight - collapsedHeight;
//     final double scrollProgress = (_scrollOffset / maxScroll).clamp(0.0, 1.0);
//
//     final double titleOpacity = _easeOutCubic(1.0 - scrollProgress * 1.2).clamp(0.0, 1.0);
//     final double actionsOpacity = _easeOutCubic(1.0 - scrollProgress * 1.8).clamp(0.0, 1.0);
//     final bool showCollapsedTitle = scrollProgress > 0.6;
//
//     Widget buildContent() {
//       return CustomScrollView(
//         controller: _scrollController,
//         physics: const BouncingScrollPhysics(),
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
//                     // Main title and animated text
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
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             crossAxisAlignment: widget.centerTitle && scrollProgress < 0.5
//                                 ? CrossAxisAlignment.center
//                                 : CrossAxisAlignment.start,
//                             children: [
//                               // Static title
//                               AnimatedDefaultTextStyle(
//                                 duration: const Duration(milliseconds: 200),
//                                 curve: Curves.easeOutCubic,
//                                 style: TextStyle(
//                                   color: colorScheme.onSurface,
//                                   fontSize: _interpolate(36.0, 20.0, scrollProgress),
//                                   fontWeight: FontWeight.w700,
//                                   letterSpacing: _interpolate(0.5, 0.0, scrollProgress),
//                                 ),
//                                 child: Text(
//                                   widget.title,
//                                   textAlign: widget.centerTitle && scrollProgress < 0.5
//                                       ? TextAlign.center
//                                       : TextAlign.left,
//                                 ),
//                               ),
//
//                               // Animated text (only when expanded)
//                               if (widget.animatedTexts != null &&
//                                   widget.animatedTexts!.isNotEmpty &&
//                                   _isExpanded)
//                                 Padding(
//                                   padding: const EdgeInsets.only(top: 8.0),
//                                   child: _buildAnimatedText(colorScheme, scrollProgress),
//                                 ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     // Bottom actions when expanded
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
//                                         alpha: actionsOpacity.clamp(0.0, 1.0)
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
//               title: scrollProgress > 0.85
//                   ? AnimatedOpacity(
//                 duration: const Duration(milliseconds: 100),
//                 opacity: ((scrollProgress - 0.85) / 0.15).clamp(0.0, 1.0),
//                 child: Builder(
//                   builder: (context) {
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
//                 left: _hasAutomaticBackButton(context) ? 10 : 0,
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
//   Widget _buildAnimatedText(ColorScheme colorScheme, double scrollProgress) {
//     final textStyle = TextStyle(
//       color: colorScheme.onSurface.withValues(alpha: 0.7),
//       fontSize: 16.0,
//       fontWeight: FontWeight.w400,
//       letterSpacing: 0.3,
//     );
//
//     switch (widget.animationType) {
//       case AnimationType.typeWriter:
//         return Text(
//           _displayedText,
//           style: textStyle,
//           textAlign: widget.centerTitle && scrollProgress < 0.5
//               ? TextAlign.center
//               : TextAlign.left,
//         );
//
//       case AnimationType.fadeInOut:
//         return FadeTransition(
//           opacity: CurvedAnimation(
//             parent: _textAnimationController,
//             curve: _getAnimationCurve(),
//           ),
//           child: Text(
//             _displayedText,
//             style: textStyle,
//             textAlign: widget.centerTitle && scrollProgress < 0.5
//                 ? TextAlign.center
//                 : TextAlign.left,
//           ),
//         );
//
//       case AnimationType.slideInOut:
//         return SlideTransition(
//           position: Tween<Offset>(
//             begin: const Offset(0, 0.5),
//             end: Offset.zero,
//           ).animate(CurvedAnimation(
//             parent: _textAnimationController,
//             curve: _getAnimationCurve(),
//           )),
//           child: FadeTransition(
//             opacity: CurvedAnimation(
//               parent: _textAnimationController,
//               curve: _getAnimationCurve(),
//             ),
//             child: Text(
//               _displayedText,
//               style: textStyle,
//               textAlign: widget.centerTitle && scrollProgress < 0.5
//                   ? TextAlign.center
//                   : TextAlign.left,
//             ),
//           ),
//         );
//     }
//   }
//
//   double _interpolate(double start, double end, double progress) {
//     return start + (end - start) * progress;
//   }
//
//   bool _hasAutomaticBackButton(BuildContext context) {
//     final navigator = Navigator.of(context);
//     final route = ModalRoute.of(context);
//     return navigator.canPop() && route?.settings.name != '/';
//   }
//
//   double _easeOutCubic(double t) {
//     return 1.0 - math.pow(1.0 - t, 3.0);
//   }
// }
//
// // Example usage demonstrating all animation types
// class ExampleUsage extends StatelessWidget {
//   const ExampleUsage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SimpleCustomAppBar(
//         title: "My Notebooks",
//         hasContent: true,
//         expandedHeight: 250.0,
//         centerTitle: true,
//
//         // Animated text configuration
//         animatedTexts: [
//           "Create, organize, and share your ideas",
//           "Collaborate with your team in real-time",
//           "Access your notes from anywhere",
//           "Stay productive and organized"
//         ],
//         animationType: AnimationType.fadeInOut,
//         animationEffect: AnimationEffect.smooth,
//         animationDuration: const Duration(seconds: 3),
//         animationRepeat: true,
//
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () {},
//           ),
//         ],
//         child: Column(
//           children: [
//             Container(
//               margin: const EdgeInsets.all(16),
//               child: TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Search notebooks',
//                   prefixIcon: const Icon(Icons.search),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   filled: true,
//                 ),
//               ),
//             ),
//             ...List.generate(40, (index) => Column(
//               children: [
//                 ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.deepPurple,
//                     child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
//                   ),
//                   title: Text('Notebook $index'),
//                   subtitle: Text('Last edited ${index + 1} days ago'),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                 ),
//                 if (index < 39) const Divider(height: 1),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Different animation type examples
// class AnimationExamples extends StatelessWidget {
//   const AnimationExamples({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Animation Examples'),
//           bottom: const TabBar(
//             tabs: [
//               Tab(text: 'TypeWriter'),
//               Tab(text: 'Fade In/Out'),
//               Tab(text: 'Slide In/Out'),
//             ],
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             // TypeWriter Animation
//             SimpleCustomAppBar(
//               title: "TypeWriter Effect",
//               hasContent: true,
//               expandedHeight: 220.0,
//               animatedTexts: const [
//                 "Watch the text appear character by character...",
//                 "This creates a typing effect!",
//                 "Perfect for storytelling"
//               ],
//               animationType: AnimationType.typeWriter,
//               animationEffect: AnimationEffect.smooth,
//               animationDuration: const Duration(seconds: 4),
//               animationRepeat: true,
//               child: const Center(child: Text('Scroll to see animation')),
//             ),
//
//             // Fade In/Out Animation
//             SimpleCustomAppBar(
//               title: "Fade Effect",
//               hasContent: true,
//               expandedHeight: 220.0,
//               animatedTexts: const [
//                 "Smooth fade transitions",
//                 "Elegant and professional",
//                 "Great for subtle messaging"
//               ],
//               animationType: AnimationType.fadeInOut,
//               animationEffect: AnimationEffect.easeInOut,
//               animationDuration: const Duration(seconds: 2),
//               animationRepeat: true,
//               child: const Center(child: Text('Scroll to see animation')),
//             ),
//
//             // Slide In/Out Animation
//             SimpleCustomAppBar(
//               title: "Slide Effect",
//               hasContent: true,
//               expandedHeight: 220.0,
//               animatedTexts: const [
//                 "Dynamic slide animations",
//                 "Catches user attention",
//                 "Modern and engaging"
//               ],
//               animationType: AnimationType.slideInOut,
//               animationEffect: AnimationEffect.bounce,
//               animationDuration: const Duration(milliseconds: 1500),
//               animationRepeat: true,
//               child: const Center(child: Text('Scroll to see animation')),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';

// Data class for Action Items
class CustomAppBarActionItem {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  const CustomAppBarActionItem({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });
}

enum AnimationType { typeWriter, fadeInOut, slideInOut }
enum AnimationEffect { bounce, smooth, easeIn, easeOut, easeInOut }

class SimpleCustomAppBar extends StatefulWidget {
  final String title;
  final Widget child;

  // Standard Actions (No Animation, standard behavior)
  final List<Widget>? actions;

  // Feature Actions (Animated with Pills & Tooltips)
  final List<CustomAppBarActionItem>? actionItems;

  final bool hasContent;
  final Function? onRefresh;
  final double expandedHeight;
  final bool centerTitle;

  // Animation parameters
  final List<String>? animatedTexts;
  final AnimationType animationType;
  final AnimationEffect animationEffect;
  final Duration animationDuration;
  final bool animationRepeat;

  // Unique key to identify this page for tooltip tracking
  final String? pageKey;

  const SimpleCustomAppBar({
    super.key,
    required this.title,
    required this.child,
    required this.hasContent,
    this.actions,
    this.actionItems,
    this.onRefresh,
    this.expandedHeight = 180.0,
    this.centerTitle = true,
    this.animatedTexts,
    this.animationType = AnimationType.fadeInOut,
    this.animationEffect = AnimationEffect.smooth,
    this.animationDuration = const Duration(seconds: 3),
    this.animationRepeat = false,
    this.pageKey,
  });

  @override
  State<SimpleCustomAppBar> createState() => _SimpleCustomAppBarState();
}

class _SimpleCustomAppBarState extends State<SimpleCustomAppBar>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late AnimationController _textAnimationController;
  late AnimationController _buttonExpandController;
  Timer? _textAnimationTimer;

  int _currentTextIndex = 0;
  String _displayedText = '';
  double _scrollOffset = 0.0;
  bool _isExpanded = true;

  // Tooltip Sequencing State
  int? _activeTooltipIndex;
  bool _hasPlayedAnimation = false;

  // Static set to track which pages have shown tooltips
  static final Set<String> _pagesWithShownTooltips = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _textAnimationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Button expand/collapse animation controller
    _buttonExpandController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    if (widget.animatedTexts != null && widget.animatedTexts!.isNotEmpty) {
      _startTextAnimation();
    }

    // Start initial button animation (with or without tooltips)
    _runInitialButtonAnimation();
  }

  // --- Initial Button Animation with Optional Tooltip Sequence ---
  Future<void> _runInitialButtonAnimation() async {
    if (widget.actionItems == null || widget.actionItems!.isEmpty) return;
    if (_hasPlayedAnimation) return;

    _hasPlayedAnimation = true;

    // Check if we should show tooltips for this page
    final String currentPageKey = widget.pageKey ?? widget.title;
    final bool shouldShowTooltips = !_pagesWithShownTooltips.contains(currentPageKey);

    // Mark this page as having shown tooltips
    if (shouldShowTooltips) {
      _pagesWithShownTooltips.add(currentPageKey);
    }

    // Wait 1 second before starting
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Expand buttons
    await _buttonExpandController.forward();

    // Only show tooltips if this is the first time on this page
    if (shouldShowTooltips) {
      // Wait a moment before showing tooltips
      await Future.delayed(const Duration(milliseconds: 500));

      // Show tooltips sequentially
      for (int i = 0; i < widget.actionItems!.length; i++) {
        if (!mounted) return;

        setState(() {
          _activeTooltipIndex = i;
        });

        // Show current tooltip for 3.5 seconds
        await Future.delayed(const Duration(milliseconds: 3500));

        if (!mounted) return;

        setState(() {
          _activeTooltipIndex = null;
        });

        // Pause between tooltips
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Wait a moment after last tooltip
      await Future.delayed(const Duration(milliseconds: 800));
    } else {
      // If no tooltips, just wait a bit while buttons are expanded
      await Future.delayed(const Duration(milliseconds: 2000));
    }

    if (!mounted) return;

    // Collapse buttons back
    await _buttonExpandController.reverse();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _textAnimationController.dispose();
    _buttonExpandController.dispose();
    _textAnimationTimer?.cancel();
    super.dispose();
  }

  // --- Text Animation Logic ---
  void _startTextAnimation() {
    if (widget.animatedTexts == null || widget.animatedTexts!.isEmpty) return;
    _currentTextIndex = 0;
    _animateCurrentText();
  }

  void _animateCurrentText() {
    if (!_isExpanded) return;
    final currentText = widget.animatedTexts![_currentTextIndex];

    switch (widget.animationType) {
      case AnimationType.typeWriter: _animateTypeWriter(currentText); break;
      case AnimationType.fadeInOut: _animateFadeInOut(currentText); break;
      case AnimationType.slideInOut: _animateSlideInOut(currentText); break;
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
          setState(() => _displayedText = text.substring(0, charIndex + 1));
          charIndex++;
        } else {
          timer.cancel();
          _scheduleNextText();
        }
      },
    );
  }

  void _animateFadeInOut(String text) {
    setState(() => _displayedText = text);
    _textAnimationController.reset();
    _textAnimationController.forward().then((_) {
      if (_isExpanded) _scheduleNextText();
    });
  }

  void _animateSlideInOut(String text) {
    setState(() => _displayedText = text);
    _textAnimationController.reset();
    _textAnimationController.forward().then((_) {
      if (_isExpanded) _scheduleNextText();
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
      case AnimationEffect.bounce: return Curves.bounceOut;
      case AnimationEffect.smooth: return Curves.easeInOutCubic;
      case AnimationEffect.easeIn: return Curves.easeIn;
      case AnimationEffect.easeOut: return Curves.easeOut;
      case AnimationEffect.easeInOut: return Curves.easeInOut;
    }
  }

  void _onScroll() {
    final double offset = _scrollController.offset;
    setState(() => _scrollOffset = offset);

    final double maxScroll = widget.expandedHeight - kToolbarHeight;
    final double animationProgress = (offset / maxScroll).clamp(0.0, 1.0);
    _animationController.value = animationProgress;

    final bool wasExpanded = _isExpanded;
    _isExpanded = animationProgress < 0.5;

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

    final bool hasAnyActions = (widget.actions?.isNotEmpty ?? false) ||
        (widget.actionItems?.isNotEmpty ?? false);

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
            // COLLAPSED ACTIONS (Only standard actions, no animated pills)
            actions: showCollapsedTitle && widget.actions != null ?
            widget.actions!.map((action) {
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
                    // Title Area
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        alignment: widget.centerTitle
                            ? Alignment.lerp(Alignment.center, Alignment.centerLeft, scrollProgress)!
                            : Alignment.centerLeft,
                        padding: EdgeInsets.only(
                          left: widget.centerTitle ? _interpolate(0, 20, scrollProgress) : 20,
                          bottom: hasAnyActions ? _interpolate(0, 50, scrollProgress) : 0,
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: titleOpacity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: widget.centerTitle && scrollProgress < 0.5
                                ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: _interpolate(36.0, 20.0, scrollProgress),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: _interpolate(0.5, 0.0, scrollProgress),
                                ),
                                child: Text(widget.title),
                              ),
                              if (widget.animatedTexts != null && widget.animatedTexts!.isNotEmpty && _isExpanded)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: _buildAnimatedText(colorScheme, scrollProgress),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // EXPANDED ACTIONS
                    if (hasAnyActions)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          opacity: actionsOpacity,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // A. Animated Pills with Sequential Tooltips
                              if (widget.actionItems != null)
                                ...widget.actionItems!.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  final showTooltip = index == _activeTooltipIndex;

                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: _ExpandingActionButton(
                                      item: item,
                                      colorScheme: colorScheme,
                                      showTooltip: showTooltip,
                                      expandController: _buttonExpandController,
                                    ),
                                  );
                                }),

                              // B. Standard Actions
                              if (widget.actions != null)
                                ...widget.actions!.map((action) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: _StyledStandardAction(
                                      colorScheme: colorScheme,
                                      child: action,
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              title: scrollProgress > 0.85 ? _buildCollapsedTitle(colorScheme, scrollProgress) : null,
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
      return RefreshIndicator(onRefresh: () async => await widget.onRefresh!(), child: buildContent());
    }
    return buildContent();
  }

  Widget _buildCollapsedTitle(ColorScheme colorScheme, double scrollProgress) {
    return AnimatedOpacity(
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
                  fontWeight: FontWeight.w600
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedText(ColorScheme colorScheme, double scrollProgress) {
    final textStyle = TextStyle(
      color: colorScheme.onSurface.withOpacity(0.7),
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.3,
    );

    switch (widget.animationType) {
      case AnimationType.typeWriter:
        return Text(
          _displayedText,
          style: textStyle,
          textAlign: widget.centerTitle && scrollProgress < 0.5 ? TextAlign.center : TextAlign.left,
        );
      case AnimationType.fadeInOut:
        return FadeTransition(
          opacity: CurvedAnimation(parent: _textAnimationController, curve: _getAnimationCurve()),
          child: Text(
            _displayedText,
            style: textStyle,
            textAlign: widget.centerTitle && scrollProgress < 0.5 ? TextAlign.center : TextAlign.left,
          ),
        );
      case AnimationType.slideInOut:
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
              .animate(CurvedAnimation(parent: _textAnimationController, curve: _getAnimationCurve())),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _textAnimationController, curve: _getAnimationCurve()),
            child: Text(
              _displayedText,
              style: textStyle,
              textAlign: widget.centerTitle && scrollProgress < 0.5 ? TextAlign.center : TextAlign.left,
            ),
          ),
        );
    }
  }

  double _interpolate(double start, double end, double progress) => start + (end - start) * progress;
  bool _hasAutomaticBackButton(BuildContext context) {
    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context);
    return navigator.canPop() && route?.settings.name != '/';
  }
  double _easeOutCubic(double t) => 1.0 - math.pow(1.0 - t, 3.0);
}

// --------------------------------------------------------------------------
// Styled Wrapper for Standard Actions (Consistency)
// --------------------------------------------------------------------------
class _StyledStandardAction extends StatelessWidget {
  final Widget child;
  final ColorScheme colorScheme;

  const _StyledStandardAction({required this.child, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

// --------------------------------------------------------------------------
// Expanding Action Button with iMessage Style Tooltip
// --------------------------------------------------------------------------
class _ExpandingActionButton extends StatefulWidget {
  final CustomAppBarActionItem item;
  final ColorScheme colorScheme;
  final bool showTooltip;
  final AnimationController expandController;

  const _ExpandingActionButton({
    required this.item,
    required this.colorScheme,
    required this.showTooltip,
    required this.expandController,
  });

  @override
  State<_ExpandingActionButton> createState() => _ExpandingActionButtonState();
}

class _ExpandingActionButtonState extends State<_ExpandingActionButton> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.expandController,
      builder: (context, child) {
        // Use easeInOut curve for smooth animation
        final curvedValue = Curves.easeInOut.transform(widget.expandController.value);
        final isExpanded = curvedValue > 0.5;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. The iMessage Tooltip Bubble
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: widget.showTooltip ? 1.0 : 0.0,
              child: widget.showTooltip ? _TooltipBubble(
                message: widget.item.tooltip,
                colorScheme: widget.colorScheme,
              ) : const SizedBox(height: 0),
            ),

            if (widget.showTooltip) const SizedBox(height: 8),

            // 2. The Button with Rounded Square Shape
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              height: 48,
              padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16 : 5),
              decoration: BoxDecoration(
                color: widget.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.item.onPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(isExpanded ? 0 : 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.item.icon,
                          color: widget.colorScheme.onPrimaryContainer,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: SizedBox(
                            width: isExpanded ? null : 0,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                widget.item.label,
                                style: TextStyle(
                                  color: widget.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --------------------------------------------------------------------------
// iMessage Style Bubble Widget
// --------------------------------------------------------------------------
class _TooltipBubble extends StatelessWidget {
  final String message;
  final ColorScheme colorScheme;

  const _TooltipBubble({required this.message, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(color: colorScheme.inverseSurface),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onInverseSurface,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

// Custom Painter for the Bubble Shape with Tail
class _BubblePainter extends CustomPainter {
  final Color color;
  _BubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double arrowHeight = 8.0;
    final double arrowWidth = 12.0;
    final double radius = 12.0;

    final Path path = Path();

    // Bubble Body
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - arrowHeight),
      Radius.circular(radius),
    ));

    // Arrow (Pinpoint) at bottom center
    final double centerX = size.width / 2;
    path.moveTo(centerX - (arrowWidth / 2), size.height - arrowHeight);
    path.lineTo(centerX, size.height);
    path.lineTo(centerX + (arrowWidth / 2), size.height - arrowHeight);
    path.close();

    // Draw Shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.15), 4.0, false);

    // Draw Bubble
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}