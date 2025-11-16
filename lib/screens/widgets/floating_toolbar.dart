// import 'package:flutter/material.dart';
//
// class FloatingToolbar extends StatefulWidget {
//   final List<FloatingToolbarItem> items;
//   final Function(int)? onItemTapped;
//   final int selectedIndex;
//   final Color? backgroundColor;
//   final Color? selectedColor;
//   final Color? unselectedColor;
//   final EdgeInsets? margin;
//   final EdgeInsets? padding;
//   final double? elevation;
//   final BorderRadius? borderRadius;
//   final double? height;
//   final Duration animationDuration;
//   final Widget? primaryButton;
//   final VoidCallback? onPrimaryPressed;
//
//   const FloatingToolbar({
//     super.key,
//     required this.items,
//     this.onItemTapped,
//     this.selectedIndex = 0,
//     this.backgroundColor,
//     this.selectedColor,
//     this.unselectedColor,
//     this.margin = const EdgeInsets.all(10.0),
//     this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//     this.elevation = 8.0,
//     this.borderRadius,
//     this.height = 60.0,
//     this.animationDuration = const Duration(milliseconds: 300),
//     this.primaryButton,
//     this.onPrimaryPressed,
//   });
//
//   @override
//   State<FloatingToolbar> createState() => _FloatingToolbarState();
// }
//
// class _FloatingToolbarState extends State<FloatingToolbar>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(
//       begin: 0.95,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOutQuart,
//     ));
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     return AnimatedBuilder(
//       animation: _scaleAnimation,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _scaleAnimation.value,
//           child: Container(
//             margin: widget.margin,
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Main toolbar items - compact and width-optimized
//                 Material(
//                   elevation: widget.elevation!,
//                   borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height! / 2),
//                   color: widget.backgroundColor ?? colorScheme.surfaceContainerHigh.withValues(alpha: .95),
//                   child: Container(
//                     height: widget.height,
//                     padding: const EdgeInsets.symmetric(horizontal: 10),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: widget.items.asMap().entries.map((entry) {
//                         final index = entry.key;
//                         final item = entry.value;
//                         final isSelected = index == widget.selectedIndex;
//
//                         return _buildToolbarItem(
//                           context,
//                           item,
//                           index,
//                           isSelected,
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 ),
//
//                 // Primary button - completely detached and dominant
//                 if (widget.primaryButton != null) ...[
//                   const SizedBox(width: 10), // More separation
//                   _buildPrimaryButton(context),
//                 ],
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildPrimaryButton(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     return Material(
//       elevation: widget.elevation! + 4, // Higher elevation for dominance
//       borderRadius: BorderRadius.circular(24),
//       color: colorScheme.primary,
//       child: Container(
//         height: 64, // Bigger than main toolbar
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(24),
//           // boxShadow: [
//           //   BoxShadow(
//           //     color: colorScheme.primary.withOpacity(0.4),
//           //     blurRadius: 16,
//           //     spreadRadius: 2,
//           //     offset: const Offset(0, 6),
//           //   ),
//           // ],
//         ),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(24),
//           onTap: widget.onPrimaryPressed,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Check if primary button is just an icon or has text
//                 if (widget.primaryButton is Icon)
//                   Icon(
//                     (widget.primaryButton as Icon).icon,
//                     color: colorScheme.onPrimary,
//                     size: 26,
//                   )
//                 else
//                   widget.primaryButton!,
//
//                 // If it's an add/create button, add text
//                 // if (widget.primaryButton is Icon &&
//                 //     ((widget.primaryButton as Icon).icon == Icons.add ||
//                 //         (widget.primaryButton as Icon).icon == Icons.create ||
//                 //         (widget.primaryButton as Icon).icon == Icons.add_circle_outline)) ...[
//                 //   const SizedBox(width: 12),
//                 //   Text(
//                 //     'Add',
//                 //     style: theme.textTheme.titleSmall?.copyWith(
//                 //       color: colorScheme.onPrimary,
//                 //       fontWeight: FontWeight.bold,
//                 //       fontSize: 16,
//                 //     ),
//                 //   ),
//                 // ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildToolbarItem(
//       BuildContext context,
//       FloatingToolbarItem item,
//       int index,
//       bool isSelected,
//       ) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     final selectedColor = widget.selectedColor ?? colorScheme.primary;
//     final unselectedColor = widget.unselectedColor ?? colorScheme.onSurfaceVariant;
//
//     return TweenAnimationBuilder<double>(
//       duration: const Duration(milliseconds: 150),
//       tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
//       curve: Curves.easeOutCubic,
//       builder: (context, value, child) {
//         return Container(
//           margin: const EdgeInsets.symmetric(horizontal: 2), // Reduced margin for compactness
//           child: Material(
//             color: Colors.transparent,
//             borderRadius: BorderRadius.circular(20),
//             child: InkWell(
//               borderRadius: BorderRadius.circular(20),
//               onTap: () {
//                 widget.onItemTapped?.call(index);
//               },
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 150),
//                 curve: Curves.easeOutCubic,
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isSelected && item.label != null ? 14 : 12, // Dynamic padding
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Color.lerp(
//                     Colors.transparent,
//                     selectedColor.withValues(alpha: .12),
//                     value,
//                   ),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     AnimatedSwitcher(
//                       duration: const Duration(milliseconds: 150),
//                       switchInCurve: Curves.easeOutCubic,
//                       switchOutCurve: Curves.easeInCubic,
//                       child: Icon(
//                         isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
//                         key: ValueKey(isSelected),
//                         color: Color.lerp(unselectedColor, selectedColor, value),
//                         size: 22, // Slightly smaller for compactness
//                       ),
//                     ),
//                     if (item.label != null && isSelected) ...[
//                       const SizedBox(width: 6), // Reduced spacing
//                       AnimatedOpacity(
//                         opacity: value,
//                         duration: const Duration(milliseconds: 150),
//                         curve: Curves.easeOutCubic,
//                         child: Text(
//                           item.label!,
//                           style: theme.textTheme.labelSmall?.copyWith(
//                             color: selectedColor,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 12, // Smaller text for compactness
//                           ),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// class FloatingToolbarItem {
//   final IconData icon;
//   final IconData? selectedIcon;
//   final String? label;
//   final VoidCallback? onTap;
//   final bool isPrimary;
//
//   const FloatingToolbarItem({
//     required this.icon,
//     this.selectedIcon,
//     this.label,
//     this.onTap,
//     this.isPrimary = false,
//   });
// }
//
// // Wrapper widget to position the toolbar at the bottom
// class FloatingBottomToolbar extends StatelessWidget {
//   final FloatingToolbar toolbar;
//
//   const FloatingBottomToolbar({
//     super.key,
//     required this.toolbar,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.bottomCenter,
//       child: toolbar,
//     );
//   }
// }

import 'package:flutter/material.dart';

class FloatingToolbar extends StatefulWidget {
  final List<FloatingToolbarItem> items;
  final Function(int)? onItemTapped;
  final int selectedIndex;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final double? height;
  final Duration animationDuration;
  final Widget? primaryButton;
  final VoidCallback? onPrimaryPressed;

  const FloatingToolbar({
    super.key,
    required this.items,
    this.onItemTapped,
    this.selectedIndex = 0,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.margin = const EdgeInsets.all(16.0),
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    this.elevation = 8.0,
    this.borderRadius,
    this.height = 60.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.primaryButton,
    this.onPrimaryPressed,
  });

  @override
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main toolbar items - compact and width-optimized
                Material(
                  elevation: widget.elevation!,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height! / 2),
                  color: widget.backgroundColor ?? colorScheme.surfaceContainerHigh.withOpacity(0.95),
                  child: Container(
                    height: widget.height,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isSelected = index == widget.selectedIndex;

                        return _buildToolbarItem(
                          context,
                          item,
                          index,
                          isSelected,
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Primary button - completely detached and dominant
                if (widget.primaryButton != null) ...[
                  const SizedBox(width: 16), // More separation
                  _buildPrimaryButton(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: widget.elevation! + 4, // Higher elevation for dominance
      borderRadius: BorderRadius.circular(24),
      color: colorScheme.primary,
      child: Container(
        height: 64, // Bigger than main toolbar
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onPrimaryPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Check if primary button is just an icon or has text
                if (widget.primaryButton is Icon)
                  Icon(
                    (widget.primaryButton as Icon).icon,
                    color: colorScheme.onPrimary,
                    size: 26,
                  )
                else
                  widget.primaryButton!,

                // If it's an add/create button, add text
                // if (widget.primaryButton is Icon &&
                //     ((widget.primaryButton as Icon).icon == Icons.add ||
                //         (widget.primaryButton as Icon).icon == Icons.create ||
                //         (widget.primaryButton as Icon).icon == Icons.add_circle_outline)) ...[
                //   const SizedBox(width: 12),
                //   Text(
                //     'Create',
                //     style: theme.textTheme.titleSmall?.copyWith(
                //       color: colorScheme.onPrimary,
                //       fontWeight: FontWeight.bold,
                //       fontSize: 16,
                //     ),
                //   ),
                // ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarItem(
      BuildContext context,
      FloatingToolbarItem item,
      int index,
      bool isSelected,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedColor = widget.selectedColor ?? colorScheme.primary;
    final unselectedColor = widget.unselectedColor ?? colorScheme.onSurfaceVariant;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 150),
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2), // Reduced margin for compactness
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                widget.onItemTapped?.call(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected && item.label != null ? 14 : 12, // Dynamic padding
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    Colors.transparent,
                    selectedColor.withOpacity(0.12),
                    value,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Icon(
                        isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                        key: ValueKey(isSelected),
                        color: Color.lerp(unselectedColor, selectedColor, value),
                        size: 22, // Slightly smaller for compactness
                      ),
                    ),
                    if (item.label != null && isSelected) ...[
                      const SizedBox(width: 6), // Reduced spacing
                      AnimatedOpacity(
                        opacity: value,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        child: Text(
                          item.label!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: selectedColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12, // Smaller text for compactness
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class FloatingToolbarItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String? label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const FloatingToolbarItem({
    required this.icon,
    this.selectedIcon,
    this.label,
    this.onTap,
    this.isPrimary = false,
  });
}

// Wrapper widget to position the toolbar at the bottom
class FloatingBottomToolbar extends StatelessWidget {
  final FloatingToolbar toolbar;

  const FloatingBottomToolbar({
    super.key,
    required this.toolbar,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: toolbar,
    );
  }
}