import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trusted_time_service.dart';
import 'google_auth_service.dart';
import '../widgets/common.dart';

class SubscriptionService {
  // ── Pref keys ──
  static const String _subStatusKey = 'has_active_subscription';
  static const String _trialStartKey = 'trial_start_timestamp';

  // ── Constants ──
  static const int _trialMinutes = 30;

  // ── State ──
  static bool hasSubscription = false;
  static bool manualPremium = false;
  static DateTime? manualPremiumExpiry;
  static DateTime? trialStartDate;

  // ════════════════════════════════════════════════
  // COMPUTED PROPERTIES FOR UI
  // ════════════════════════════════════════════════

  /// True if the user has access (manual premium OR trial active)
  static bool get hasAccess {
    if (kIsWeb) return true;
    if (manualPremium) return true;
    return hasSubscription || isTrialActive;
  }

  /// True if the free trial is still active (30 minutes)
  static bool get isTrialActive {
    if (trialStartDate == null) return false;
    final now = TrustedTimeService.now();
    final elapsed = now.difference(trialStartDate!);
    return elapsed.inMinutes < _trialMinutes;
  }

  /// Minutes remaining in trial (0 if expired)
  static int get trialMinutesRemaining {
    if (trialStartDate == null) return 0;
    final now = TrustedTimeService.now();
    final elapsed = now.difference(trialStartDate!);
    final remaining = _trialMinutes - elapsed.inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// Subscription status text for UI display
  static String get statusText {
    if (manualPremium) {
      if (manualPremiumExpiry != null) {
        final days = manualPremiumExpiry!.difference(TrustedTimeService.now()).inDays;
        return 'Premium Active ✅ ($days days left)';
      }
      return 'Premium Active ✅ (Lifetime)';
    }
    if (hasSubscription) {
      return '${AppLocale.l('premiumActive')} (Premium Active)';
    }
    if (isTrialActive) {
      final m = trialMinutesRemaining;
      return '${AppLocale.l('trialActive').replaceAll('{h}', '$m')} ($m min left)';
    }
    return '${AppLocale.l('noSubscription')} (No subscription)';
  }

  // ════════════════════════════════════════════════
  // INITIALIZATION
  // ════════════════════════════════════════════════

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cached state
    hasSubscription = prefs.getBool(_subStatusKey) ?? false;

    final trialTs = prefs.getInt(_trialStartKey);
    if (trialTs != null) {
      trialStartDate = DateTime.fromMillisecondsSinceEpoch(trialTs);
    } else {
      // First install — start trial
      trialStartDate = TrustedTimeService.now();
      await prefs.setInt(_trialStartKey, trialStartDate!.millisecondsSinceEpoch);
    }

    if (kIsWeb) return;

    // Check manual premium from Firestore (admin-set)
    await checkManualPremium();
  }

  static void dispose() {}

  // ════════════════════════════════════════════════
  // FIRESTORE TRIAL SYNC (prevents trial reset on reinstall)
  // ════════════════════════════════════════════════

  /// Call AFTER sign-in + device binding. Syncs trial start with Firestore
  /// so uninstall/reinstall with same Gmail does NOT reset the trial.
  static Future<void> syncTrialWithFirestore() async {
    if (kIsWeb) return;
    final email = GoogleAuthService.userEmail;
    if (email == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('device_bindings')
          .doc(email.toLowerCase());

      final doc = await docRef.get().timeout(const Duration(seconds: 8));
      if (!doc.exists || doc.data() == null) return;

      final data = doc.data()!;
      final firestoreTrialTs = data['trialStartedAt'];

      if (firestoreTrialTs != null && firestoreTrialTs is Timestamp) {
        // Firestore has a trial start → restore it (prevents trial reset)
        final firestoreTrialDate = firestoreTrialTs.toDate();
        final prefs = await SharedPreferences.getInstance();
        final localTs = prefs.getInt(_trialStartKey);

        if (localTs == null || firestoreTrialDate.isBefore(DateTime.fromMillisecondsSinceEpoch(localTs))) {
          // Firestore date is earlier (original) → use it
          trialStartDate = firestoreTrialDate;
          await prefs.setInt(_trialStartKey, firestoreTrialDate.millisecondsSinceEpoch);
          debugPrint('🔄 Trial restored from Firestore: $firestoreTrialDate (no free trial on reinstall)');
        }
      } else {
        // No trial in Firestore yet → write current trial start
        if (trialStartDate != null) {
          await docRef.update({
            'trialStartedAt': Timestamp.fromDate(trialStartDate!),
          }).catchError((_) {});
          debugPrint('📝 Trial start written to Firestore: $trialStartDate');
        }
      }
    } catch (e) {
      debugPrint('Trial Firestore sync error: $e');
    }
  }

  // ════════════════════════════════════════════════
  // MANUAL PREMIUM (admin-set via Firestore)
  // ════════════════════════════════════════════════

  /// Check if the admin has manually granted premium for this user.
  /// Reads `manualPremium` flag from Firestore `device_bindings/{email}`.
  static Future<void> checkManualPremium() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('device_bindings')
          .doc(email.toLowerCase())
          .get()
          .timeout(const Duration(seconds: 8));

      if (!doc.exists || doc.data() == null) return;

      final data = doc.data()!;
      final isPremium = data['manualPremium'] == true;

      if (isPremium) {
        // Check expiry if set
        final expiryTs = data['manualPremiumExpiry'];
        if (expiryTs != null && expiryTs is Timestamp) {
          final expiryDate = expiryTs.toDate();
          if (expiryDate.isBefore(TrustedTimeService.now())) {
            // Expired
            manualPremium = false;
            manualPremiumExpiry = null;
            hasSubscription = false;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_subStatusKey, false);
            debugPrint('🔒 Manual premium EXPIRED on $expiryDate');
            return;
          }
          manualPremiumExpiry = expiryDate;
        } else {
          manualPremiumExpiry = null; // Lifetime
        }

        manualPremium = true;
        hasSubscription = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_subStatusKey, true);
        debugPrint('✅ Manual premium ACTIVE for $email');
      } else {
        manualPremium = false;
        manualPremiumExpiry = null;
        hasSubscription = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_subStatusKey, false);
      }
    } catch (e) {
      debugPrint('Manual premium check error: $e');
      // Don't change state on error — keep whatever was cached
    }
  }

  // ── Legacy compatibility ──
  static bool get hasAdFree => hasSubscription;
}
