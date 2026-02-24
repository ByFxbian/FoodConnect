import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable themed SnackBar helper — consistent across the entire app.
class AppSnackBar {
  static void success(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    _show(context, message, Icons.check_circle_outline, Colors.green.shade700);
  }

  static void error(BuildContext context, String message) {
    HapticFeedback.heavyImpact();
    _show(context, message, Icons.error_outline, Colors.red.shade700);
  }

  static void info(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    _show(
      context,
      message,
      Icons.info_outline,
      Theme.of(context).colorScheme.inverseSurface,
    );
  }

  static void _show(
      BuildContext context, String message, IconData icon, Color bg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// SnackBar with undo action
  static void withUndo(BuildContext context, String message,
      {required VoidCallback onUndo}) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        action: SnackBarAction(
          label: 'Rückgängig',
          textColor: Theme.of(context).primaryColor,
          onPressed: onUndo,
        ),
      ),
    );
  }
}
