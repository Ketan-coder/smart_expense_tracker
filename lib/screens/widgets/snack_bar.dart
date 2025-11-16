import 'package:flutter/material.dart';

enum SnackBarType { info, success, warning, error }

class SnackBars {
  static void show(
      BuildContext context, {
        required String message,
        SnackBarType type = SnackBarType.info,
        SnackBarBehavior behavior = SnackBarBehavior.fixed,
        String? actionLabel,
        VoidCallback? onAction,
        bool withCancel = false,
      }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    // Pick base colors with null-safe fallbacks
    Color backgroundColor;
    Color foregroundColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = scheme.primaryContainer;
        foregroundColor = scheme.onPrimaryContainer;
        icon = Icons.check_circle;
        break;
      case SnackBarType.warning:
        backgroundColor = scheme.tertiaryContainer;
        foregroundColor = scheme.onTertiaryContainer;
        icon = Icons.warning_amber;
        break;
      case SnackBarType.error:
        backgroundColor = scheme.errorContainer;
        foregroundColor = scheme.onErrorContainer;
        icon = Icons.error_outline;
        break;
      case SnackBarType.info:
        backgroundColor = scheme.secondaryContainer;
        foregroundColor = scheme.onSecondaryContainer;
        icon = Icons.info_outline;
        break;
      // default:
      //   backgroundColor = scheme.secondaryContainer;
      //   foregroundColor = scheme.onSecondaryContainer;
      //   icon = Icons.info_outline;
      //   break;
    }

    // Build snackbar
    final snackBar = SnackBar(
      behavior: behavior,
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 3),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foregroundColor),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: foregroundColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          if (actionLabel != null && onAction != null)...[
            const Spacer(),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: foregroundColor,
              ),
              child: Text(actionLabel),
            ),
          ],
          if (withCancel)
            TextButton(
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              style: TextButton.styleFrom(
                foregroundColor: foregroundColor,
              ),
              child: const Text("Cancel"),
            ),
        ],
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
