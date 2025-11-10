// import 'package:flutter/material.dart';
//
// class BottomSheetUtil {
//   /// Show a universal modal bottom sheet
//   static Future<T?> show<T>({
//     required BuildContext context,
//     required Widget child,
//     double? height,
//     double? width,
//     bool isDismissible = true,
//     bool enableDrag = true,
//     String title = '',
//     bool showHandle = true,
//     bool showCloseIcon = true,
//   }) {
//     return showModalBottomSheet<T>(
//       context: context,
//       isDismissible: isDismissible,
//       enableDrag: enableDrag,
//       useSafeArea: true,
//       isScrollControlled: true,
//       showDragHandle: true,
//       constraints: BoxConstraints(
//         // You might want to set maxHeight here if you want to enforce it
//         // maxHeight: MediaQuery.of(context).size.height * 0.7,
//       ),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (context) {
//         return SafeArea(
//           child: SizedBox(
//             // Changed from 0.4 to 0.7 for 70% height
//             height: height ?? MediaQuery.of(context).size.height * 0.7,
//             width:
//                 width ??
//                 MediaQuery.of(context).size.width,
//             child: Container(
//               padding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         title,
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       if (showCloseIcon) ...[
//                         TextButton.icon(
//                           onPressed: () {
//                             Navigator.pop(context);
//                           },
//                           icon: Icon(
//                             Icons.cancel_presentation,
//                             size: 24,
//                             color: Colors.grey.shade400,
//                           ),
//                           label: const Text('Close'),
//                           iconAlignment: IconAlignment.start,
//                           style: TextButton.styleFrom(
//                             foregroundColor: Colors.grey.shade400,
//                               backgroundColor: Colors.transparent,
//                               side: BorderSide(width: 0, color: Colors.transparent)
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                   Divider(),
//                   const SizedBox(height: 10),
//                   // Important: Ensure the child is appropriately scrollable or constrained
//                   // if its content might exceed the 70% height.
//                   Expanded(
//                     // Use Expanded to make the SingleChildScrollView take available space
//                     child: SingleChildScrollView(
//                       scrollDirection: Axis.vertical,
//                       physics: const BouncingScrollPhysics(),
//                       keyboardDismissBehavior:
//                           ScrollViewKeyboardDismissBehavior.onDrag,
//                       child: child,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }


import 'package:flutter/material.dart';

class BottomSheetUtil {
  /// Show a universal modal bottom sheet with floating card design
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? height,
    double? width,
    bool isDismissible = true,
    bool enableDrag = true,
    String title = '',
    bool showHandle = true,
    bool showCloseIcon = true,
    bool isScrollable = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final bottomPadding = mediaQuery.viewInsets.bottom;
        final safeAreaBottom = mediaQuery.padding.bottom;

        return GestureDetector(
          onTap: () {
            if (isDismissible) {
              Navigator.pop(context);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withOpacity(0.4),
            padding: EdgeInsets.only(bottom: bottomPadding + safeAreaBottom),
            child: DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              snap: true,
              snapSizes: const [0.4, 0.7, 0.9],
              builder: (context, scrollController) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        if (showHandle)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (showCloseIcon)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => Navigator.pop(context),
                                  style: IconButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const Divider(height: 1),

                        // Content
                        Expanded(
                          child: isScrollable
                              ? SingleChildScrollView(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: child,
                            ),
                          )
                              : Padding(
                            padding: const EdgeInsets.all(20),
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Show a quick action bottom sheet (like the transaction selector)
  static Future<T?> showQuickAction<T>({
    required BuildContext context,
    required Widget child,
    double? height,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () {
            if (isDismissible) {
              Navigator.pop(context);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withOpacity(0.4),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}