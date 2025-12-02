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
//     this.margin = const EdgeInsets.all(16.0),
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
//                   color: widget.backgroundColor ?? colorScheme.surfaceContainerHigh.withOpacity(0.95),
//                   child: Container(
//                     height: widget.height,
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
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
//                   const SizedBox(width: 16), // More separation
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
//           boxShadow: [
//             BoxShadow(
//               color: colorScheme.primary.withOpacity(0.4),
//               blurRadius: 16,
//               spreadRadius: 2,
//               offset: const Offset(0, 6),
//             ),
//           ],
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
//                 //     'Create',
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
//                     selectedColor.withOpacity(0.12),
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
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../core/helpers.dart';

// ============================================================================
// QUICK ACTION MODEL
// ============================================================================
class QuickAction {
  final String id;
  final String label;
  final String type; // 'expense' or 'income'
  final double amount;
  final String? description;
  final List<int> categoryKeys;
  final String method;

  QuickAction({
    required this.id,
    required this.label,
    required this.type,
    required this.amount,
    this.description,
    required this.categoryKeys,
    required this.method,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type,
    'amount': amount,
    'description': description,
    'categoryKeys': categoryKeys,
    'method': method,
  };

  factory QuickAction.fromJson(Map<String, dynamic> json) => QuickAction(
    id: json['id'],
    label: json['label'],
    type: json['type'],
    amount: json['amount'],
    description: json['description'],
    categoryKeys: List<int>.from(json['categoryKeys']),
    method: json['method'],
  );

  QuickAction copyWith({
    String? id,
    String? label,
    String? type,
    double? amount,
    String? description,
    List<int>? categoryKeys,
    String? method,
  }) {
    return QuickAction(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryKeys: categoryKeys ?? this.categoryKeys,
      method: method ?? this.method,
    );
  }
}

// ============================================================================
// QUICK ACTION MANAGER (Handles persistence)
// ============================================================================
class QuickActionManager {
  static const String _storageKey = 'quick_actions';

  static Future<List<QuickAction>> loadQuickActions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => QuickAction.fromJson(json)).toList();
  }

  static Future<void> saveQuickActions(List<QuickAction> actions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = actions.map((action) => action.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }

  static Future<void> addQuickAction(QuickAction action) async {
    final actions = await loadQuickActions();
    actions.add(action);
    await saveQuickActions(actions);
  }

  static Future<void> updateQuickAction(QuickAction action) async {
    final actions = await loadQuickActions();
    final index = actions.indexWhere((a) => a.id == action.id);
    if (index != -1) {
      actions[index] = action;
      await saveQuickActions(actions);
    }
  }

  static Future<void> deleteQuickAction(String id) async {
    final actions = await loadQuickActions();
    actions.removeWhere((a) => a.id == id);
    await saveQuickActions(actions);
  }
}

// ============================================================================
// ENHANCED FLOATING TOOLBAR WITH QUICK ACTIONS
// ============================================================================
class FloatingToolbarWithQuickActions extends StatefulWidget {
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

  // Quick Actions properties
  final bool showQuickActions;
  final List<QuickAction> quickActions;
  final Function(QuickAction)? onQuickActionTap;
  final Function(QuickAction)? onQuickActionEdit;
  final VoidCallback? onAddQuickAction;

  const FloatingToolbarWithQuickActions({
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
    this.showQuickActions = false,
    this.quickActions = const [],
    this.onQuickActionTap,
    this.onQuickActionEdit,
    this.onAddQuickAction,
  });

  @override
  State<FloatingToolbarWithQuickActions> createState() =>
      _FloatingToolbarWithQuickActionsState();
}

class _FloatingToolbarWithQuickActionsState
    extends State<FloatingToolbarWithQuickActions>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String _currentCurrency = 'INR';

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
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
    if (mounted) setState(() {});
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick Actions Toolbar (show when enabled, even if empty)
        if (widget.showQuickActions)
          _buildQuickActionsToolbar(context),

        if (widget.showQuickActions)
          const SizedBox(height: 1),

        // Main Toolbar
        _buildMainToolbar(context),
      ],
    );
  }

  Widget _buildQuickActionsToolbar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.only(
              left: widget.margin!.left,
              right: widget.margin!.right,
            ),
            alignment: AlignmentGeometry.centerLeft,
            height: 58,
            // width: 340,
            child: Material(
              elevation: widget.elevation!,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(29),
              // color: widget.backgroundColor ??
              //     colorScheme.surfaceContainerHigh.withOpacity(0.95),
              color: widget.backgroundColor?.withValues(alpha: 0.3) ??
                      colorScheme.surfaceContainerHigh.withValues(alpha: .45),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: widget.quickActions.length + 1,
                itemBuilder: (context, index) {
                  if (index == widget.quickActions.length) {
                    return _buildAddQuickActionButton(context);
                  }
                  return _buildQuickActionChip(
                    context,
                    widget.quickActions[index],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionChip(BuildContext context, QuickAction action) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpense = action.type == 'expense';
    final chipColor = isExpense ? colorScheme.error : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onLongPress: () {
          widget.onQuickActionEdit?.call(action);
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              widget.onQuickActionTap?.call(action);
            },
            borderRadius: BorderRadius.circular(21),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(
                  color: chipColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 18,
                    color: chipColor,
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        action.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: chipColor,
                        ),
                      ),
                      const SizedBox(width: 5,),
                      Text(
                        ': $_currentCurrency ${action.amount.toStringAsFixed(0)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: chipColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddQuickActionButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onAddQuickAction,
          borderRadius: BorderRadius.circular(21),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: .32),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Quick Action',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainToolbar(BuildContext context) {
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
                Material(
                  elevation: widget.elevation!,
                  borderRadius: widget.borderRadius ??
                      BorderRadius.circular(widget.height! / 2),
                  color: widget.backgroundColor ??
                      colorScheme.surfaceContainerHigh.withOpacity(0.95),
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
                if (widget.primaryButton != null) ...[
                  const SizedBox(width: 16),
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
      elevation: widget.elevation! + 4,
      borderRadius: BorderRadius.circular(24),
      color: colorScheme.primary,
      child: Container(
        height: 64,
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
                if (widget.primaryButton is Icon)
                  Icon(
                    (widget.primaryButton as Icon).icon,
                    color: colorScheme.onPrimary,
                    size: 26,
                  )
                else
                  widget.primaryButton!,
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
    final unselectedColor =
        widget.unselectedColor ?? colorScheme.onSurfaceVariant;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 150),
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
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
                  horizontal: isSelected && item.label != null ? 14 : 12,
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
                        isSelected
                            ? (item.selectedIcon ?? item.icon)
                            : item.icon,
                        key: ValueKey(isSelected),
                        color: Color.lerp(unselectedColor, selectedColor, value),
                        size: 22,
                      ),
                    ),
                    if (item.label != null && isSelected) ...[
                      const SizedBox(width: 6),
                      AnimatedOpacity(
                        opacity: value,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        child: Text(
                          item.label!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: selectedColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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

// ============================================================================
// ORIGINAL FLOATING TOOLBAR ITEM (Unchanged)
// ============================================================================
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

// ============================================================================
// WRAPPER WIDGET (Unchanged)
// ============================================================================
class FloatingBottomToolbar extends StatelessWidget {
  final FloatingToolbarWithQuickActions toolbar;

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

// ============================================================================
// BACKWARD COMPATIBILITY WRAPPER
// ============================================================================
class FloatingToolbar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return FloatingToolbarWithQuickActions(
      items: items,
      onItemTapped: onItemTapped,
      selectedIndex: selectedIndex,
      backgroundColor: backgroundColor,
      selectedColor: selectedColor,
      unselectedColor: unselectedColor,
      margin: margin,
      padding: padding,
      elevation: elevation,
      borderRadius: borderRadius,
      height: height,
      animationDuration: animationDuration,
      primaryButton: primaryButton,
      onPrimaryPressed: onPrimaryPressed,
      showQuickActions: false,
    );
  }
}