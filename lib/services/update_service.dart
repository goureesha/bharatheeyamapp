import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UpdateService — checks Google Play for a new version and triggers the
// appropriate in-app update flow:
//
//   • IMMEDIATE  — full-screen blocking update (critical releases).
//                  Set via Play Console → Release → In-app update priority 5.
//   • FLEXIBLE   — background download, user can continue using app.
//                  Shown for priority 1-4. A snackbar prompts restart when done.
//
// Call UpdateService.check(context) once from your home screen's initState.
// ─────────────────────────────────────────────────────────────────────────────

class UpdateService {
  UpdateService._();

  /// Call once after the home screen is ready.
  /// Silently ignored on errors (e.g. no network, not Play Store build).
  static Future<void> check(BuildContext context) async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return; // already up to date
      }

      // ── IMMEDIATE update (priority 5 set in Play Console) ──────────────
      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      // ── FLEXIBLE update (background download) ──────────────────────────
      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();

        // Listen for download completion, then prompt restart
        InAppUpdate.completeFlexibleUpdate().then((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'ಹೊಸ ಅಪ್‌ಡೇಟ್ ಸಿದ್ಧವಾಗಿದೆ! ಅನ್ವಯಿಸಲು ಮರುಪ್ರಾರಂಭಿಸಿ.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                action: SnackBarAction(
                  label: 'RESTART',
                  onPressed: () => InAppUpdate.completeFlexibleUpdate(),
                ),
                duration: const Duration(seconds: 10),
                backgroundColor: const Color(0xFF6B46C1),
              ),
            );
          }
        });
      }
    } catch (_) {
      // Silently ignore — not a Play Store build, no network, etc.
    }
  }
}
