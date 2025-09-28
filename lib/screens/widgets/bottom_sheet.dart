import 'package:flutter/material.dart';

class BottomSheetUtil {
  /// Show a universal modal bottom sheet
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
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        // You might want to set maxHeight here if you want to enforce it
        // maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            // Changed from 0.4 to 0.7 for 70% height
            height: height ?? MediaQuery.of(context).size.height * 0.7,
            width:
                width ??
                MediaQuery.of(context).size.width,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (showCloseIcon) ...[
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.cancel_presentation,
                            size: 24,
                            color: Colors.grey.shade400,
                          ),
                          label: const Text('Close'),
                          iconAlignment: IconAlignment.start,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade400,
                              backgroundColor: Colors.transparent,
                              side: BorderSide(width: 0, color: Colors.transparent)
                          ),
                        ),
                      ],
                    ],
                  ),
                  Divider(),
                  const SizedBox(height: 10),
                  // Important: Ensure the child is appropriately scrollable or constrained
                  // if its content might exceed the 70% height.
                  Expanded(
                    // Use Expanded to make the SingleChildScrollView take available space
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
