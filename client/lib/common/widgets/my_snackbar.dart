import 'package:flutter/material.dart';

/// Type of SnackBar to show
enum SnackBarType {
  /// Success message (green)
  success,

  /// Error message (red)
  error,

  /// Info message (blue)
  info,

  /// Warning message (amber)
  warning,
}

/// Utility class for showing consistently styled SnackBars across the app
class MySnackBar {
  /// Private constructor to prevent instantiation
  MySnackBar._();

  /// Shows a snackbar with consistent styling
  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final bool isDesktop = MediaQuery.of(context).size.width > 600;

    // Clear any existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();

    // For desktop, use a different approach without width
    if (isDesktop) {
      // Show the new snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getIconForType(type),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: _getBackgroundColorForType(type),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.3,
            vertical: 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: duration,
          dismissDirection: DismissDirection.horizontal,
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } else {
      // Mobile version
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              _getIconForType(type),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: _getBackgroundColorForType(type),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: duration,
          dismissDirection: DismissDirection.horizontal,
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// Shows a success snackbar
  static void showSuccess(BuildContext context, String message) {
    show(context: context, message: message, type: SnackBarType.success);
  }

  /// Shows an error snackbar
  static void showError(BuildContext context, String message) {
    show(context: context, message: message, type: SnackBarType.error);
  }

  /// Shows an info snackbar
  static void showInfo(BuildContext context, String message) {
    show(context: context, message: message);
  }

  /// Shows a warning snackbar
  static void showWarning(BuildContext context, String message) {
    show(context: context, message: message, type: SnackBarType.warning);
  }

  /// Get the appropriate icon for the snackbar type
  static Widget _getIconForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return const Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: 20,
        );
      case SnackBarType.error:
        return const Icon(Icons.error_outline, color: Colors.white, size: 20);
      case SnackBarType.warning:
        return const Icon(
          Icons.warning_amber_outlined,
          color: Colors.white,
          size: 20,
        );
      case SnackBarType.info:
        return const Icon(Icons.info_outline, color: Colors.white, size: 20);
    }
  }

  /// Get the appropriate background color for the snackbar type
  static Color _getBackgroundColorForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Colors.green.shade700;
      case SnackBarType.error:
        return Colors.red.shade700;
      case SnackBarType.warning:
        return Colors.amber.shade700;
      case SnackBarType.info:
        return Colors.blue.shade700;
    }
  }
}
