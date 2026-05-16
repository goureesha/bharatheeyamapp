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
  static const String _lastOnlineCheckKey = 'last_online_check_timestamp';

  // ── Constants ──
  static const int _trialMinutes = 30;
  static const int _maxOfflineHours = 24;
  static const int _recheckIntervalMinutes = 5; // Re-check Firestore every 5 minutes

  // ── State ──
  static bool hasSubscription = false;
  static bool manualPremium = false;
  static DateTime? manualPremiumExpiry;
  static DateTime? trialStartDate;
  static DateTime? lastOnlineCheck;

  // ── Periodic re-check timer ──
  static Timer? _recheckTimer;

  /// Notifier that fires when access status changes (revoked or granted).
  /// main.dart listens to this to rebuild the UI and show SupportScreen.
  static final ValueNotifier<int> accessChangeNotifier = ValueNotifier<int>(0);

  // ════════════════════════════════════════════════
  // COMPUTED PROPERTIES FOR UI
  // ════════════════════════════════════════════════

  /// True if the user has access (manual premium OR trial active)
  static bool get hasAccess {
    if (kIsWeb) return true;
    // If offline > 24 hours → no access (must connect)
    if (needsInternetVerification) return false;
    if (manualPremium) {
      // Even offline, check local expiry date — lock out immediately when expired
      if (manualPremiumExpiry != null &&
          manualPremiumExpiry!.isBefore(TrustedTimeService.now())) {
        manualPremium = false;
        hasSubscription = false;
        return false;
      }
      return true;
    }
    return hasSubscription || isTrialActive;
  }

  /// True if the user hasn't connected to the internet in > 24 hours
  static bool get needsInternetVerification {
    if (kIsWeb) return false;
    if (isTrialActive) return false; // Don't block during free trial
    if (lastOnlineCheck == null) return true; // Never verified
    final hoursSinceCheck = TrustedTimeService.now().difference(lastOnlineCheck!).inHours;
    return hoursSinceCheck >= _maxOfflineHours;
  }

  /// Record a successful online verification
  static Future<void> recordOnlineCheck() async {
    lastOnlineCheck = TrustedTimeService.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastOnlineCheckKey, lastOnlineCheck!.millisecondsSinceEpoch);
    debugPrint('🌐 Online check recorded: $lastOnlineCheck');
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

  /// App status text for UI display
  static String get statusText {
    if (manualPremium) {
      if (manualPremiumExpiry != null) {
        final days = manualPremiumExpiry!.difference(TrustedTimeService.now()).inDays;
        return 'Beta Access ✅ ($days ${AppLocale.l('daysRemaining')})';
      }
      return 'Beta Access ✅';
    }
    if (hasSubscription) {
      return '${AppLocale.l('premiumActive')}';
    }
    if (isTrialActive) {
      final m = trialMinutesRemaining;
      return '${AppLocale.l('trialActive').replaceAll('{h}', '$m')} ($m min left)';
    }
    return '${AppLocale.l('trialExpired')}';
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

    // Load last online check timestamp
    final lastCheckTs = prefs.getInt(_lastOnlineCheckKey);
    if (lastCheckTs != null) {
      lastOnlineCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckTs);
    }

    if (kIsWeb) return;

    // Check manual premium from Firestore (admin-set)
    // If successful, this also counts as an online check
    await checkManualPremium();

    // Start periodic re-check so revoked access takes effect without app restart
    _startPeriodicRecheck();
  }

  static void dispose() {
    _recheckTimer?.cancel();
    _recheckTimer = null;
  }

  // ════════════════════════════════════════════════
  // PERIODIC RE-CHECK (detects server-side revocation)
  // ════════════════════════════════════════════════

  /// Starts a timer that re-checks Firestore every N minutes.
  /// If manualPremium is revoked server-side, this will detect it and
  /// trigger a UI rebuild to lock out the user.
  static void _startPeriodicRecheck() {
    _recheckTimer?.cancel();
    _recheckTimer = Timer.periodic(
      Duration(minutes: _recheckIntervalMinutes),
      (_) => _periodicAccessCheck(),
    );
    debugPrint('🔄 Periodic access re-check started (every $_recheckIntervalMinutes min)');
  }

  static Future<void> _periodicAccessCheck() async {
    if (kIsWeb) return;
    if (!GoogleAuthService.isSignedIn) return;

    final hadAccess = hasAccess;
    await checkManualPremium();
    final nowHasAccess = hasAccess;

    if (hadAccess != nowHasAccess) {
      debugPrint('🔒 Access status changed: $hadAccess → $nowHasAccess — triggering UI rebuild');
      // Bump the notifier to trigger ValueListenableBuilder rebuild in main.dart
      accessChangeNotifier.value++;
    }
  }

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

      if (!doc.exists || doc.data() == null) {
        // Successfully reached Firestore — record online check
        await recordOnlineCheck();
        return;
      }

      // Successfully reached Firestore — record online check
      await recordOnlineCheck();

      final data = doc.data()!;
      final isPremium = data['manualPremium'] == true;

      if (isPremium) {
        // Check expiry if set
        final expiryTs = data['manualPremiumExpiry'];
        if (expiryTs != null && expiryTs is Timestamp) {
          final expiryDate = expiryTs.toDate();
          if (expiryDate.isBefore(TrustedTimeService.now())) {
            // Expired — update local state
            manualPremium = false;
            manualPremiumExpiry = null;
            hasSubscription = false;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_subStatusKey, false);
            debugPrint('🔒 Manual premium EXPIRED on $expiryDate');

            // Write back to Firestore so admin dashboard reflects it
            try {
              await FirebaseFirestore.instance
                  .collection('device_bindings')
                  .doc(email!.toLowerCase())
                  .update({'manualPremium': false});
              debugPrint('🔄 Firestore updated: manualPremium → false');
            } catch (_) {
              // Non-critical — dashboard will catch up on next check
            }
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
        debugPrint('🔒 Manual premium REVOKED for $email');
      }
    } catch (e) {
      debugPrint('Manual premium check error: $e');
      // Don't change state on error — keep whatever was cached
    }
  }

  // ── Legacy compatibility ──
  static bool get hasAdFree => hasSubscription;
}
