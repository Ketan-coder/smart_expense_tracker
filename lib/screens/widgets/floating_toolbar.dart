// import 'package:flutter/material.dart';
// import 'package:hive_ce/hive.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
//
// import '../../core/helpers.dart';
//
// // ============================================================================
// // QUICK ACTION MODEL
// // ============================================================================
// class QuickAction {
//   final String id;
//   final String label;
//   final String type; // 'expense' or 'income'
//   final double amount;
//   final String? description;
//   final List<int> categoryKeys;
//   final String method;
//
//   QuickAction({
//     required this.id,
//     required this.label,
//     required this.type,
//     required this.amount,
//     this.description,
//     required this.categoryKeys,
//     required this.method,
//   });
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'label': label,
//     'type': type,
//     'amount': amount,
//     'description': description,
//     'categoryKeys': categoryKeys,
//     'method': method,
//   };
//
//   factory QuickAction.fromJson(Map<String, dynamic> json) => QuickAction(
//     id: json['id'],
//     label: json['label'],
//     type: json['type'],
//     amount: json['amount'],
//     description: json['description'],
//     categoryKeys: List<int>.from(json['categoryKeys']),
//     method: json['method'],
//   );
//
//   QuickAction copyWith({
//     String? id,
//     String? label,
//     String? type,
//     double? amount,
//     String? description,
//     List<int>? categoryKeys,
//     String? method,
//   }) {
//     return QuickAction(
//       id: id ?? this.id,
//       label: label ?? this.label,
//       type: type ?? this.type,
//       amount: amount ?? this.amount,
//       description: description ?? this.description,
//       categoryKeys: categoryKeys ?? this.categoryKeys,
//       method: method ?? this.method,
//     );
//   }
// }
//
// // ============================================================================
// // QUICK ACTION MANAGER (Handles persistence)
// // ============================================================================
// class QuickActionManager {
//   static const String _storageKey = 'quick_actions';
//
//   static Future<List<QuickAction>> loadQuickActions() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonString = prefs.getString(_storageKey);
//     if (jsonString == null) return [];
//
//     final List<dynamic> jsonList = json.decode(jsonString);
//     return jsonList.map((json) => QuickAction.fromJson(json)).toList();
//   }
//
//   static Future<void> saveQuickActions(List<QuickAction> actions) async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonList = actions.map((action) => action.toJson()).toList();
//     await prefs.setString(_storageKey, json.encode(jsonList));
//   }
//
//   static Future<void> addQuickAction(QuickAction action) async {
//     final actions = await loadQuickActions();
//     actions.add(action);
//     await saveQuickActions(actions);
//   }
//
//   static Future<void> updateQuickAction(QuickAction action) async {
//     final actions = await loadQuickActions();
//     final index = actions.indexWhere((a) => a.id == action.id);
//     if (index != -1) {
//       actions[index] = action;
//       await saveQuickActions(actions);
//     }
//   }
//
//   static Future<void> deleteQuickAction(String id) async {
//     final actions = await loadQuickActions();
//     actions.removeWhere((a) => a.id == id);
//     await saveQuickActions(actions);
//   }
// }
//
// // ============================================================================
// // ENHANCED FLOATING TOOLBAR WITH QUICK ACTIONS
// // ============================================================================
// class FloatingToolbarWithQuickActions extends StatefulWidget {
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
//   // Quick Actions properties
//   final bool showQuickActions;
//   final List<QuickAction> quickActions;
//   final Function(QuickAction)? onQuickActionTap;
//   final Function(QuickAction)? onQuickActionEdit;
//   final VoidCallback? onAddQuickAction;
//
//   const FloatingToolbarWithQuickActions({
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
//     this.showQuickActions = false,
//     this.quickActions = const [],
//     this.onQuickActionTap,
//     this.onQuickActionEdit,
//     this.onAddQuickAction,
//   });
//
//   @override
//   State<FloatingToolbarWithQuickActions> createState() =>
//       _FloatingToolbarWithQuickActionsState();
// }
//
// class _FloatingToolbarWithQuickActionsState
//     extends State<FloatingToolbarWithQuickActions>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   String _currentCurrency = 'INR';
//   final ScrollController _scrollController = ScrollController();
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
//     _loadInitialData();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadInitialData() async {
//     _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
//     if (mounted) setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Quick Actions Toolbar (show when enabled, even if empty)
//         if (widget.showQuickActions)
//           _buildQuickActionsToolbar(context),
//
//         if (widget.showQuickActions)
//           const SizedBox(height: 0),
//
//         // Main Toolbar
//         _buildMainToolbar(context),
//       ],
//     );
//   }
//
//   Widget _buildQuickActionsToolbar(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     return AnimatedBuilder(
//       animation: _scaleAnimation,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _scaleAnimation.value,
//           child: Container(
//             margin: EdgeInsets.only(
//               left: widget.margin!.left,
//               right: widget.margin!.right,
//             ),
//             height: 42, // Compact chip height
//             child: Stack(
//               children: [
//                 // Main scrollable content
//                 Material(
//                   elevation: 0, //widget.elevation! - 3
//                   borderRadius: widget.borderRadius ?? BorderRadius.circular(21),
//                   color: widget.backgroundColor?.withValues(alpha: 0.8) ??
//                       colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
//                   // color: Colors.transparent,
//                   child: ShaderMask(
//                     shaderCallback: (Rect bounds) {
//                       return LinearGradient(
//                         begin: Alignment.centerLeft,
//                         end: Alignment.centerRight,
//                         colors: const [
//                           Colors.transparent,
//                           Colors.white,
//                           Colors.white,
//                           Colors.transparent,
//                         ],
//                         stops: const [0.0, 0.03, 0.97, 1.0],
//                       ).createShader(bounds);
//                     },
//                     blendMode: BlendMode.dstIn,
//                     child: ListView.builder(
//                       controller: _scrollController,
//                       scrollDirection: Axis.horizontal,
//                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
//                       physics: const BouncingScrollPhysics(),
//                       itemCount: widget.quickActions.length + 1,
//                       itemBuilder: (context, index) {
//                         if (index == widget.quickActions.length) {
//                           return _buildAddQuickActionButton(context);
//                         }
//                         return _buildQuickActionChip(
//                           context,
//                           widget.quickActions[index],
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//
//                 // Scroll indicators (left/right fade edges)
//                 if (widget.quickActions.isNotEmpty)
//                   Positioned(
//                     left: 0,
//                     top: 0,
//                     bottom: 0,
//                     child: IgnorePointer(
//                       child: Container(
//                         width: 16,
//                         decoration: BoxDecoration(
//                           borderRadius: const BorderRadius.only(
//                             topLeft: Radius.circular(21),
//                             bottomLeft: Radius.circular(21),
//                           ),
//                           gradient: LinearGradient(
//                             begin: Alignment.centerLeft,
//                             end: Alignment.centerRight,
//                             colors: [
//                               colorScheme.surfaceContainerHigh.withValues(alpha: .55),
//                               colorScheme.surfaceContainerHigh.withValues(alpha: 0),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 if (widget.quickActions.isNotEmpty)
//                   Positioned(
//                     right: 0,
//                     top: 0,
//                     bottom: 0,
//                     child: IgnorePointer(
//                       child: Container(
//                         width: 16,
//                         decoration: BoxDecoration(
//                           borderRadius: const BorderRadius.only(
//                             topRight: Radius.circular(21),
//                             bottomRight: Radius.circular(21),
//                           ),
//                           gradient: LinearGradient(
//                             begin: Alignment.centerLeft,
//                             end: Alignment.centerRight,
//                             colors: [
//                               colorScheme.surfaceContainerHigh.withValues(alpha: 0),
//                               colorScheme.surfaceContainerHigh.withValues(alpha: .55),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildQuickActionChip(BuildContext context, QuickAction action) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final isExpense = action.type == 'expense';
//     final chipColor = isExpense ? colorScheme.error : colorScheme.primary;
//
//     return Padding(
//       padding: const EdgeInsets.only(right: 6), // Compact spacing
//       child: GestureDetector(
//         onLongPress: () {
//           widget.onQuickActionEdit?.call(action);
//         },
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: () {
//               widget.onQuickActionTap?.call(action);
//             },
//             borderRadius: BorderRadius.circular(15),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Compact chip padding
//               decoration: BoxDecoration(
//                 color: chipColor.withValues(alpha: .12),
//                 borderRadius: BorderRadius.circular(15),
//                 border: Border.all(
//                   color: chipColor.withValues(alpha: .4),
//                   width: .5,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: chipColor.withValues(alpha: 0.15),
//                     blurRadius: 4,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Icon with background
//                   Container(
//                     padding: const EdgeInsets.all(2.5),
//                     decoration: BoxDecoration(
//                       color: chipColor.withValues(alpha: .35),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
//                       size: 11, // Compact icon
//                       color: chipColor,
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   // Label and amount
//                   Flexible(
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Text(
//                           '$_currentCurrency${action.amount.toStringAsFixed(0)} -',
//                           style: theme.textTheme.labelSmall?.copyWith(
//                             fontWeight: FontWeight.w900,
//                             color: chipColor,
//                             fontSize: 11, // Compact text
//                             height: 1.2,
//                           ),
//                         ),
//                         const SizedBox(width: 3),
//                         Flexible(
//                           child: Text(
//                             action.label,
//                             style: theme.textTheme.labelSmall?.copyWith(
//                               fontWeight: FontWeight.w500,
//                               color: chipColor,
//                               fontSize: 11, // Compact text
//                               height: 1.2,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAddQuickActionButton(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     return Padding(
//       padding: const EdgeInsets.only(right: 6), // Compact spacing
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: widget.onAddQuickAction,
//           borderRadius: BorderRadius.circular(15),
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Compact chip padding
//             decoration: BoxDecoration(
//               color: colorScheme.primaryContainer.withValues(alpha: .35),
//               borderRadius: BorderRadius.circular(15),
//               border: Border.all(
//                 color: colorScheme.primary.withValues(alpha:0.4),
//                 width: 1.5,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: colorScheme.primary.withValues(alpha:0.1),
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   Icons.add_circle_outline_rounded,
//                   size: 14, // Compact icon
//                   color: colorScheme.primary,
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   'Add Quick',
//                   style: theme.textTheme.labelSmall?.copyWith(
//                     fontWeight: FontWeight.w700,
//                     color: colorScheme.primary,
//                     fontSize: 11, // Compact text
//                     height: 1.2,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMainToolbar(BuildContext context) {
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
//                 Material(
//                   elevation: widget.elevation!,
//                   borderRadius: widget.borderRadius ??
//                       BorderRadius.circular(widget.height! / 2),
//                   color: widget.backgroundColor ??
//                       colorScheme.surfaceContainerHigh.withValues(alpha:0.95),
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
//                 if (widget.primaryButton != null) ...[
//                   const SizedBox(width: 16),
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
//       elevation: widget.elevation! + 4,
//       borderRadius: BorderRadius.circular(24),
//       color: colorScheme.primary,
//       child: Container(
//         height: 64,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(24),
//           boxShadow: [
//             BoxShadow(
//               color: colorScheme.primary.withValues(alpha:0.4),
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
//                 if (widget.primaryButton is Icon)
//                   Icon(
//                     (widget.primaryButton as Icon).icon,
//                     color: colorScheme.onPrimary,
//                     size: 26,
//                   )
//                 else
//                   widget.primaryButton!,
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
//     final unselectedColor =
//         widget.unselectedColor ?? colorScheme.onSurfaceVariant;
//
//     return TweenAnimationBuilder<double>(
//       duration: const Duration(milliseconds: 150),
//       tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
//       curve: Curves.easeOutCubic,
//       builder: (context, value, child) {
//         return Container(
//           margin: const EdgeInsets.symmetric(horizontal: 2),
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
//                   horizontal: isSelected && item.label != null ? 14 : 12,
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Color.lerp(
//                     Colors.transparent,
//                     selectedColor.withValues(alpha:0.12),
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
//                         isSelected
//                             ? (item.selectedIcon ?? item.icon)
//                             : item.icon,
//                         key: ValueKey(isSelected),
//                         color: Color.lerp(unselectedColor, selectedColor, value),
//                         size: 22,
//                       ),
//                     ),
//                     if (item.label != null && isSelected) ...[
//                       const SizedBox(width: 6),
//                       AnimatedOpacity(
//                         opacity: value,
//                         duration: const Duration(milliseconds: 150),
//                         curve: Curves.easeOutCubic,
//                         child: Text(
//                           item.label!,
//                           style: theme.textTheme.labelSmall?.copyWith(
//                             color: selectedColor,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 12,
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
// // ============================================================================
// // ORIGINAL FLOATING TOOLBAR ITEM (Unchanged)
// // ============================================================================
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
// // ============================================================================
// // WRAPPER WIDGET (Unchanged)
// // ============================================================================
// class FloatingBottomToolbar extends StatelessWidget {
//   final FloatingToolbarWithQuickActions toolbar;
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
//
// // ============================================================================
// // BACKWARD COMPATIBILITY WRAPPER
// // ============================================================================
// class FloatingToolbar extends StatelessWidget {
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
//   Widget build(BuildContext context) {
//     return FloatingToolbarWithQuickActions(
//       items: items,
//       onItemTapped: onItemTapped,
//       selectedIndex: selectedIndex,
//       backgroundColor: backgroundColor,
//       selectedColor: selectedColor,
//       unselectedColor: unselectedColor,
//       margin: margin,
//       padding: padding,
//       elevation: elevation,
//       borderRadius: borderRadius,
//       height: height,
//       animationDuration: animationDuration,
//       primaryButton: primaryButton,
//       onPrimaryPressed: onPrimaryPressed,
//       showQuickActions: false,
//     );
//   }
// }

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io' show Platform;

import '../../core/helpers.dart';
import '../../services/number_formatter_service.dart';

// ============================================================================
// PLATFORM DETECTION & DEBUG TOGGLE
// ============================================================================
class PlatformHelper {
  // Debug toggle - set to true to force iOS styling on Android for testing
  static bool forceIOSStyle = false;

  static bool get isIOS {
    if (kIsWeb) return false;
    return forceIOSStyle || Platform.isIOS;
  }

  static bool get isAndroid {
    if (kIsWeb) return false;
    return !forceIOSStyle && Platform.isAndroid;
  }
}

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
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
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
        // Quick Actions Toolbar
        if (widget.showQuickActions)
          _buildQuickActionsToolbar(context),

        if (widget.showQuickActions)
          SizedBox(height: PlatformHelper.isIOS ? 8 : 0),

        // Main Toolbar
        _buildMainToolbar(context),
      ],
    );
  }

  Widget _buildQuickActionsToolbar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isIOS = PlatformHelper.isIOS;

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
            height: isIOS ? 46 : 42,
            child: Stack(
              children: [
                // Main scrollable content
                Material(
                  elevation: isIOS ? 0 : 0,
                  borderRadius: BorderRadius.circular(isIOS ? 23 : 21),
                  color: isIOS
                      ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.75)
                      : (widget.backgroundColor?.withValues(alpha: 0.8) ??
                      colorScheme.surfaceContainerHigh.withValues(alpha: 0.9)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isIOS ? 23 : 21),
                    child: isIOS
                        ? _buildIOSBackdrop(
                      child: _buildScrollableContent(),
                    )
                        : _buildScrollableContent(),
                  ),
                ),

                // Scroll indicators
                if (widget.quickActions.isNotEmpty) ...[
                  _buildScrollIndicator(context, isLeft: true, isIOS: isIOS),
                  _buildScrollIndicator(context, isLeft: false, isIOS: isIOS),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIOSBackdrop({required Widget child}) {
    return Stack(
      children: [
        // Blur effect simulation
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildScrollableContent() {
    final isIOS = PlatformHelper.isIOS;

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: const [0.0, 0.03, 0.97, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: isIOS ? 8 : 6,
          vertical: isIOS ? 7 : 6,
        ),
        physics: isIOS
            ? const BouncingScrollPhysics()
            : const BouncingScrollPhysics(),
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
    );
  }

  Widget _buildScrollIndicator(BuildContext context, {required bool isLeft, required bool isIOS}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          width: isIOS ? 20 : 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: isLeft ? Radius.circular(isIOS ? 23 : 21) : Radius.zero,
              bottomLeft: isLeft ? Radius.circular(isIOS ? 23 : 21) : Radius.zero,
              topRight: !isLeft ? Radius.circular(isIOS ? 23 : 21) : Radius.zero,
              bottomRight: !isLeft ? Radius.circular(isIOS ? 23 : 21) : Radius.zero,
            ),
            gradient: LinearGradient(
              begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                colorScheme.surfaceContainerHigh.withValues(alpha: isIOS ? .75 : .55),
                colorScheme.surfaceContainerHigh.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(BuildContext context, QuickAction action) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpense = action.type == 'expense';
    final chipColor = isExpense ? colorScheme.error : colorScheme.primary;
    final isIOS = PlatformHelper.isIOS;

    return Padding(
      padding: EdgeInsets.only(right: isIOS ? 8 : 6),
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
            borderRadius: BorderRadius.circular(isIOS ? 16 : 15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isIOS ? 12 : 10,
                vertical: isIOS ? 5 : 4,
              ),
              decoration: BoxDecoration(
                color: isIOS
                    ? chipColor.withValues(alpha: .18)
                    : chipColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(isIOS ? 16 : 15),
                border: isIOS
                    ? null
                    : Border.all(
                  color: chipColor.withValues(alpha: .4),
                  width: .5,
                ),
                boxShadow: isIOS
                    ? [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(isIOS ? 3 : 2.5),
                    decoration: BoxDecoration(
                      color: chipColor.withValues(alpha: isIOS ? .4 : .35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: isIOS ? 12 : 11,
                      color: chipColor,
                    ),
                  ),
                  SizedBox(width: isIOS ? 7 : 6),
                  // Label and amount
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '$_currentCurrency${NumberFormatterService().formatForDisplay(action.amount)} -',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: isIOS ? FontWeight.w800 : FontWeight.w900,
                            color: chipColor,
                            fontSize: isIOS ? 12 : 11,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            action.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: isIOS ? FontWeight.w600 : FontWeight.w500,
                              color: chipColor,
                              fontSize: isIOS ? 12 : 11,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
    final isIOS = PlatformHelper.isIOS;

    return Padding(
      padding: EdgeInsets.only(right: isIOS ? 8 : 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onAddQuickAction,
          borderRadius: BorderRadius.circular(isIOS ? 16 : 15),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isIOS ? 12 : 10,
              vertical: isIOS ? 5 : 4,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: isIOS ? .4 : .35),
              borderRadius: BorderRadius.circular(isIOS ? 16 : 15),
              border: isIOS
                  ? null
                  : Border.all(
                color: colorScheme.primary.withValues(alpha:0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha:isIOS ? 0.15 : 0.1),
                  blurRadius: isIOS ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isIOS ? Icons.add_circle_rounded : Icons.add_circle_outline_rounded,
                  size: isIOS ? 15 : 14,
                  color: colorScheme.primary,
                ),
                SizedBox(width: isIOS ? 7 : 6),
                Text(
                  'Add Quick',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isIOS ? FontWeight.w600 : FontWeight.w700,
                    color: colorScheme.primary,
                    fontSize: isIOS ? 12 : 11,
                    height: 1.2,
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
    final isIOS = PlatformHelper.isIOS;

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
                  elevation: isIOS ? 0 : widget.elevation!,
                  borderRadius: widget.borderRadius ??
                      BorderRadius.circular(widget.height! / 2),
                  color: isIOS
                      ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.75)
                      : (widget.backgroundColor ??
                      colorScheme.surfaceContainerHigh.withValues(alpha:0.95)),
                  child: ClipRRect(
                    borderRadius: widget.borderRadius ??
                        BorderRadius.circular(widget.height! / 2),
                    child: isIOS
                        ? _buildIOSBackdrop(
                      child: Container(
                        height: widget.height,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildToolbarItems(),
                      ),
                    )
                        : Container(
                      height: widget.height,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildToolbarItems(),
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

  Widget _buildToolbarItems() {
    return Row(
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
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isIOS = PlatformHelper.isIOS;

    return Material(
      elevation: isIOS ? 0 : (widget.elevation! + 4),
      borderRadius: BorderRadius.circular(24),
      color: colorScheme.primary,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha:isIOS ? 0.5 : 0.4),
              blurRadius: isIOS ? 20 : 16,
              spreadRadius: isIOS ? 1 : 2,
              offset: Offset(0, isIOS ? 4 : 6),
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
    final isIOS = PlatformHelper.isIOS;

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
                    selectedColor.withValues(alpha:isIOS ? 0.18 : 0.12),
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
                            fontWeight: isIOS ? FontWeight.w600 : FontWeight.w600,
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