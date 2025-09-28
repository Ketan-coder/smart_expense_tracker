import 'package:flutter/material.dart';

class Dialogs {
  /// 1. Confirmation dialog (Yes/No)
  static Future<bool?> showConfirmation({
    required BuildContext context,
    String title = "Confirm",
    String message = "Are you sure?",
    String yesText = "Yes",
    String noText = "No",
  }) {
    return showDialog<bool>(
      useSafeArea: true,
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(noText),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(yesText),
            ),
          ],
        );
      },
    );
  }

  /// 2. Info dialog
  static Future<void> showInfo({
    required BuildContext context,
    String title = "Info",
    String message = "Something happened",
    String buttonText = "OK",
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  /// 3. Custom dialog (pass any widget as child)
  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isFullScreenDialog = true,
  }) {
    return showDialog<T>(
      context: context,
      useSafeArea: true,
      fullscreenDialog: isFullScreenDialog,
      builder: (context) {
        return AlertDialog(
          title: title != null ? Text(title) : null,
          content: child,
        );
      },
    );
  }
}
