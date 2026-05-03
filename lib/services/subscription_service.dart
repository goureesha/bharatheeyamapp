import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trusted_time_service.dart';
import 'google_auth_service.dart';
import '../widgets/common.dart';

class SubscriptionService {
  static const String _subscriptionProductId = 'ad_free_yearly_500';

  // ── Pref keys ──
  static const String _subStatusKey = 'has_active_subscription';
  static const String _trialStartKey = 'trial_start_timestamp';
  static const String _lastVerifiedKey = 'last_verified_timestamp';
  static const String _purchaseDateKey = 'purchase_date_timestamp';
  static const String _graceCountKey = 'grace_period_count';
  static const String _graceYearKey = 'grace_period_year';
  static const String _graceStartKey = 'grace_start_timestamp';
  static const String _graceActiveKey = 'grace_active';
  static const String _lastPlayCheckKey = 'last_play_check_date';
  static const String _pendingAckKey = 'pending_purchase_ack';

  // ── Constants ──
  static const int _trialMinutes = 30;
  static const int _offlineGraceDays = 2;
  static const int _maxGracePeriodsPerYear = 10;
  static const int _subscriptionDurationDays = 365;

  static InAppPurchase get _iap => InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  // ── State ──
  static bool hasSubscription = false;
  static DateTime? trialStartDate;
  static DateTime? lastVerifiedDate;
  static DateTime? purchaseDate;

  // ── Grace period state ──
  static bool isGracePeriodActive = false;
  static DateTime? graceStartDate;
  static int gracePeriodsUsedThisYear = 0;
  static int _graceYear = 0;

  /// Whether the app must show the "connect to internet" screen
  static bool needsInternetVerification = false;

  // ── Acknowledgment tracking ──
  static String ackStatus = 'unknown';  // 'passed', 'failed', 'pending', 'unknown'
  static DateTime? lastAckTime;
  static String? lastAckError;

  // ════════════════════════════════════════════════
  // COMPUTED PROPERTIES FOR UI
  // ════════════════════════════════════════════════

  /// True if the user has access (subscribed + verified recently, OR trial active)
  static bool get hasAccess {
    if (kIsWeb) return true;
    if (needsInternetVerification) return false;
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

  /// Days remaining in subscription (0 if expired or not subscribed)
  static int get subscriptionDaysRemaining {
    if (!hasSubscription || purchaseDate == null) return 0;
    final expiryDate = purchaseDate!.add(const Duration(days: _subscriptionDurationDays));
    final remaining = expiryDate.difference(TrustedTimeService.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Hours remaining in current grace period (0 if not active)
  static int get gracePeriodRemainingHours {
    if (!isGracePeriodActive || graceStartDate == null) return 0;
    final elapsed = TrustedTimeService.now().difference(graceStartDate!);
    final remainingHours = (_offlineGraceDays * 24) - elapsed.inHours;
    return remainingHours > 0 ? remainingHours : 0;
  }

  /// Grace periods remaining this year
  static int get gracePeriodsRemainingThisYear {
    final remaining = _maxGracePeriodsPerYear - gracePeriodsUsedThisYear;
    return remaining > 0 ? remaining : 0;
  }

  /// Subscription status text for UI display
  static String get statusText {
    if (!hasSubscription && !isTrialActive) {
      return '${AppLocale.l('noSubscription')} (No subscription)';
    }
    if (isTrialActive) {
      final m = trialMinutesRemaining;
      return '${AppLocale.l('trialActive').replaceAll('{h}', '$m')} ($m min left)';
    }
    if (hasSubscription) {
      final days = subscriptionDaysRemaining;
      if (days > 0) {
        return AppLocale.l('premiumActive').replaceAll('{days}', '$days');
      } else {
        return AppLocale.l('subExpired');
      }
    }
    return '';
  }

  /// Grace period status text for UI display
  static String get graceStatusText {
    if (isGracePeriodActive) {
      final hrs = gracePeriodRemainingHours;
      return AppLocale.l('graceActive').replaceAll('{hrs}', '$hrs').replaceAll('{used}', '$gracePeriodsUsedThisYear').replaceAll('{max}', '$_maxGracePeriodsPerYear');
    }
    return AppLocale.l('graceInactive').replaceAll('{used}', '$gracePeriodsUsedThisYear').replaceAll('{max}', '$_maxGracePeriodsPerYear');
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

    final lastVerTs = prefs.getInt(_lastVerifiedKey);
    if (lastVerTs != null) {
      lastVerifiedDate = DateTime.fromMillisecondsSinceEpoch(lastVerTs);
    }

    final purchaseTs = prefs.getInt(_purchaseDateKey);
    if (purchaseTs != null) {
      purchaseDate = DateTime.fromMillisecondsSinceEpoch(purchaseTs);
    }

    // Load grace period state
    _graceYear = prefs.getInt(_graceYearKey) ?? TrustedTimeService.now().year;
    gracePeriodsUsedThisYear = prefs.getInt(_graceCountKey) ?? 0;
    isGracePeriodActive = prefs.getBool(_graceActiveKey) ?? false;
    final graceStartTs = prefs.getInt(_graceStartKey);
    if (graceStartTs != null) {
      graceStartDate = DateTime.fromMillisecondsSinceEpoch(graceStartTs);
    }

    // Reset grace count if new year
    if (_graceYear != TrustedTimeService.now().year) {
      _graceYear = TrustedTimeService.now().year;
      gracePeriodsUsedThisYear = 0;
      await prefs.setInt(_graceYearKey, _graceYear);
      await prefs.setInt(_graceCountKey, 0);
    }

    // Check if existing grace period has expired
    if (isGracePeriodActive && graceStartDate != null) {
      final elapsed = TrustedTimeService.now().difference(graceStartDate!);
      if (elapsed.inDays >= _offlineGraceDays) {
        // Grace period expired
        isGracePeriodActive = false;
        await prefs.setBool(_graceActiveKey, false);
        debugPrint('⏰ Grace period expired on startup');
      }
    }

    if (kIsWeb) return;

    // Setup purchase listener
    _purchaseSub = _iap.purchaseStream.listen(
      (list) => _listenToPurchaseUpdated(list),
      onDone: () => _purchaseSub?.cancel(),
      onError: (e) => debugPrint('Purchase stream error: $e'),
    );

    // CRITICAL: Acknowledge any purchases that failed to acknowledge previously
    // This prevents the 72-hour Google Play auto-refund
    await _acknowledgePendingPurchases();

    // Verify subscription with Play Store — only once per day
    if (_shouldCheckToday()) {
      await _verifyWithPlayStore();
    } else {
      debugPrint('📋 Subscription already verified today — skipping Play Store check');
    }
  }

  static void dispose() {
    if (!kIsWeb) {
      _purchaseSub?.cancel();
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
  // PLAY STORE VERIFICATION
  // ════════════════════════════════════════════════

  /// Checks subscription status with Google Play.
  /// Strategy: ASSUME REVOKED, then GRANT only if Play Store confirms active purchase.
  static Future<void> _verifyWithPlayStore() async {
    bool storeReachable = false;
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        debugPrint('🔌 Play Store not available — activating grace period');
        await _activateGracePeriod();
        return;
      }
      storeReachable = true;

      // Reset: assume no active purchase until stream confirms one
      _foundActiveDuringRestore = false;

      // This triggers the purchase stream with current purchase state
      await _iap.restorePurchases();

      // Wait for the stream to process any restored purchases.
      // If subscription expired, the stream may not fire at all.
      await Future.delayed(const Duration(milliseconds: 2500));

      // Record that we successfully talked to Play Store
      await _updateLastVerified();
      await _recordCheckDate();
      needsInternetVerification = false;

      // Deactivate grace period since we successfully verified
      await _deactivateGracePeriod();

      // KEY FIX: If we had a subscription but Play Store didn't confirm it,
      // it means the subscription has expired → REVOKE
      if (!_foundActiveDuringRestore && hasSubscription) {
        debugPrint('⚠️ Play Store did NOT confirm active subscription → REVOKING');
        await _revokeAccess();
      }
    } catch (e) {
      debugPrint('Play Store verification error: $e');

      if (storeReachable) {
        // Store WAS reachable but restorePurchases() threw an error
        // (e.g. rate-limited, Play Store glitch).
        // Activate grace period — don't revoke on rate limit.
        debugPrint('⚠️ Store reachable but restore threw — activating grace period');
        await _activateGracePeriod();
      } else {
        // Store truly not reachable — genuine offline scenario
        await _activateGracePeriod();
      }
    }
  }

  // ════════════════════════════════════════════════
  // GRACE PERIOD MANAGEMENT
  // ════════════════════════════════════════════════

  /// Activate a grace period (offline or rate-limited)
  static Future<void> _activateGracePeriod() async {
    if (!hasSubscription) {
      // Not subscribed, nothing to grace-period
      needsInternetVerification = false;
      return;
    }

    // If already in an active grace period, check if it's still valid
    if (isGracePeriodActive && graceStartDate != null) {
      final elapsed = TrustedTimeService.now().difference(graceStartDate!);
      if (elapsed.inDays < _offlineGraceDays) {
        // Still within active grace period — allow access, don't count again
        needsInternetVerification = false;
        debugPrint('📟 Still within grace period (${elapsed.inHours}h elapsed). Access allowed.');
        return;
      } else {
        // This grace period expired — fall through to start a new one (if allowed)
        isGracePeriodActive = false;
      }
    }

    // Reset year counter if needed
    final currentYear = TrustedTimeService.now().year;
    if (_graceYear != currentYear) {
      _graceYear = currentYear;
      gracePeriodsUsedThisYear = 0;
    }

    // Check if grace periods are exhausted for this year
    if (gracePeriodsUsedThisYear >= _maxGracePeriodsPerYear) {
      // No more grace periods — LOCK until internet
      needsInternetVerification = true;
      isGracePeriodActive = false;
      debugPrint('🚫 All $gracePeriodsUsedThisYear grace periods used this year. LOCKED.');
      await _saveGraceState();
      return;
    }

    // Activate a NEW grace period
    isGracePeriodActive = true;
    graceStartDate = TrustedTimeService.now();
    gracePeriodsUsedThisYear++;
    needsInternetVerification = false;
    debugPrint('🛡️ Grace period #$gracePeriodsUsedThisYear activated (${_offlineGraceDays} days). Access allowed.');

    await _saveGraceState();
  }

  /// Deactivate grace period (after successful verification)
  static Future<void> _deactivateGracePeriod() async {
    if (isGracePeriodActive) {
      isGracePeriodActive = false;
      graceStartDate = null;
      debugPrint('✅ Grace period deactivated — verified online.');
      await _saveGraceState();
    }
  }

  /// Save grace period state to SharedPreferences
  static Future<void> _saveGraceState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_graceActiveKey, isGracePeriodActive);
    await prefs.setInt(_graceCountKey, gracePeriodsUsedThisYear);
    await prefs.setInt(_graceYearKey, _graceYear);
    if (graceStartDate != null) {
      await prefs.setInt(_graceStartKey, graceStartDate!.millisecondsSinceEpoch);
    }
  }

  /// Record the timestamp of successful Play Store communication
  static Future<void> _updateLastVerified() async {
    lastVerifiedDate = TrustedTimeService.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastVerifiedKey, lastVerifiedDate!.millisecondsSinceEpoch);
  }

  // ════════════════════════════════════════════════
  // CONNECTIVITY RE-CHECK (call from app lifecycle)
  // ════════════════════════════════════════════════

  /// Call this when the app detects internet connectivity during a grace period.
  /// Also call on app resume to re-check.
  static Future<void> checkOnReconnect() async {
    if (kIsWeb) return;

    // Only re-verify if we are in grace period or need verification
    if (isGracePeriodActive || needsInternetVerification) {
      debugPrint('🔄 Internet detected during grace/lock — re-verifying with Play Store');
      await _verifyWithPlayStore();
      return;
    }

    // Normal resume: only re-check if not already verified today
    if (_shouldCheckToday()) {
      debugPrint('🔄 New day — re-verifying subscription on resume');
      await _verifyWithPlayStore();
    }
  }

  // ════════════════════════════════════════════════
  // PURCHASE FLOW
  // ════════════════════════════════════════════════

  /// Trigger the purchase flow
  static Future<bool> buySubscription() async {
    if (kIsWeb) return false;

    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint('Store not available');
      return false;
    }

    final ProductDetailsResponse detailResponse =
        await _iap.queryProductDetails({_subscriptionProductId});

    if (detailResponse.notFoundIDs.isNotEmpty) {
      debugPrint('Product $_subscriptionProductId not found on the Store.');
      return false;
    }

    if (detailResponse.productDetails.isEmpty) {
      return false;
    }

    final ProductDetails productDetails = detailResponse.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Manually restore purchases (user-triggered)
  static Future<void> restorePurchases() async {
    try {
      _foundActiveDuringRestore = false;
      await _iap.restorePurchases();
      await Future.delayed(const Duration(milliseconds: 2500));
      await _updateLastVerified();
      needsInternetVerification = false;

      // Deactivate grace if we successfully verified
      await _deactivateGracePeriod();

      // If no active purchase was found during restore, revoke
      if (!_foundActiveDuringRestore && hasSubscription) {
        await _revokeAccess();
      }
    } catch (e) {
      debugPrint('Restore failed: $e');
    }
  }

  /// Re-verify subscription (can be called from settings or periodically)
  /// This always calls Play Store regardless of daily check (user-triggered).
  static Future<void> reVerify() async {
    await _verifyWithPlayStore();
  }

  // ════════════════════════════════════════════════
  // DAILY CHECK THROTTLE
  // ════════════════════════════════════════════════

  /// Returns true if we should check Play Store today (haven't checked yet today)
  static bool _shouldCheckToday() {
    if (!hasSubscription && !isTrialActive) return false; // No sub to check
    if (lastVerifiedDate == null) return true; // Never verified
    final now = TrustedTimeService.now();
    final lastCheck = lastVerifiedDate!;
    // Different calendar day → should check
    return now.year != lastCheck.year ||
           now.month != lastCheck.month ||
           now.day != lastCheck.day;
  }

  /// Record today's date as the last Play Store check date
  static Future<void> _recordCheckDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlayCheckKey, TrustedTimeService.now().toIso8601String());
  }

  // ════════════════════════════════════════════════
  // PURCHASE STREAM HANDLER
  // ════════════════════════════════════════════════

  static bool _foundActiveDuringRestore = false;

  static Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    if (purchaseDetailsList.isEmpty) {
      // Empty restore result — no active purchases
      await _revokeAccess();
      return;
    }

    bool foundActive = false;

    for (final pd in purchaseDetailsList) {
      if (pd.status == PurchaseStatus.pending) {
        continue;
      }

      if (pd.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${pd.error}');
      } else if (pd.status == PurchaseStatus.purchased ||
                 pd.status == PurchaseStatus.restored) {
        if (pd.productID == _subscriptionProductId) {
          foundActive = true;
          _foundActiveDuringRestore = true;

          // Save the Play Store's transaction date as trusted timestamp
          if (pd.transactionDate != null) {
            final txDateMs = int.tryParse(pd.transactionDate!);
            if (txDateMs != null) {
              purchaseDate = DateTime.fromMillisecondsSinceEpoch(txDateMs);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt(_purchaseDateKey, txDateMs);
            }
          }

          await _grantAccess();
        }
      } else if (pd.status == PurchaseStatus.canceled) {
        debugPrint('Purchase canceled for ${pd.productID}');
      }

      if (pd.pendingCompletePurchase) {
        await _robustCompletePurchase(pd);
      }
    }

    // If we processed a restore batch and found nothing active, revoke
    if (!foundActive && purchaseDetailsList.any((pd) =>
        pd.status == PurchaseStatus.restored || pd.status == PurchaseStatus.canceled)) {
      await _revokeAccess();
    }
  }

  // ════════════════════════════════════════════════
  // GRANT / REVOKE ACCESS
  // ════════════════════════════════════════════════

  static Future<void> _grantAccess() async {
    hasSubscription = true;
    needsInternetVerification = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subStatusKey, true);
    debugPrint('✅ Subscription GRANTED');
  }

  static Future<void> _revokeAccess() async {
    hasSubscription = false;
    isGracePeriodActive = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subStatusKey, false);
    await prefs.setBool(_graceActiveKey, false);
    debugPrint('🔒 Subscription REVOKED — no active purchase found');
  }

  // ════════════════════════════════════════════════
  // ROBUST PURCHASE ACKNOWLEDGMENT (prevents 72-hour auto-refund)
  // ════════════════════════════════════════════════

  /// Acknowledge a purchase with retry logic.
  /// If it fails, saves the purchase token to SharedPreferences
  /// so it can be retried on next app launch.
  static Future<void> _robustCompletePurchase(PurchaseDetails pd) async {
    ackStatus = 'pending';
    lastAckError = null;
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await _iap.completePurchase(pd);
        debugPrint('✅ Purchase acknowledged on attempt #$attempt (${pd.productID})');

        // Clear any saved pending acknowledgment
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_pendingAckKey);

        // Track success
        ackStatus = 'passed';
        lastAckTime = TrustedTimeService.now();
        lastAckError = null;
        await prefs.setString('ack_status', 'passed');
        await prefs.setInt('ack_time', lastAckTime!.millisecondsSinceEpoch);
        await prefs.remove('ack_error');
        return;
      } catch (e) {
        debugPrint('⚠️ completePurchase attempt #$attempt failed: $e');
        lastAckError = e.toString();
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    // All 3 attempts failed — save purchase info for retry on next app start
    debugPrint('🚨 All acknowledgment attempts failed! Saving for retry...');
    ackStatus = 'failed';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingAckKey, pd.purchaseID ?? pd.productID);
      await prefs.setString('ack_status', 'failed');
      await prefs.setString('ack_error', lastAckError ?? 'Unknown error');
      debugPrint('💾 Pending acknowledgment saved: ${pd.purchaseID ?? pd.productID}');
    } catch (_) {}
  }

  /// Called at initialization — retries acknowledging any purchase that
  /// failed to acknowledge in a previous session.
  /// This is the safety net that prevents the 72-hour Google auto-refund.
  static Future<void> _acknowledgePendingPurchases() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load saved ack status
      ackStatus = prefs.getString('ack_status') ?? 'unknown';
      final ackTimeMs = prefs.getInt('ack_time');
      if (ackTimeMs != null) lastAckTime = DateTime.fromMillisecondsSinceEpoch(ackTimeMs);
      lastAckError = prefs.getString('ack_error');

      final pendingId = prefs.getString(_pendingAckKey);

      if (pendingId == null) return;

      debugPrint('🔄 Found pending acknowledgment: $pendingId — triggering restore...');
      ackStatus = 'pending';

      // Restore purchases to get the PurchaseDetails object again.
      // The purchase stream listener (_listenToPurchaseUpdated) will
      // handle calling _robustCompletePurchase again.
      _foundActiveDuringRestore = false;
      await _iap.restorePurchases();
      await Future.delayed(const Duration(milliseconds: 3000));

      // Check if the pending ack was cleared (meaning it was acknowledged)
      final stillPending = prefs.getString(_pendingAckKey);
      if (stillPending == null) {
        debugPrint('✅ Pending purchase successfully acknowledged on retry!');
      } else {
        debugPrint('⚠️ Pending purchase still not acknowledged — will retry next launch');
        ackStatus = 'failed';
        await prefs.setString('ack_status', 'failed');
      }
    } catch (e) {
      debugPrint('Pending acknowledgment retry error: $e');
      ackStatus = 'failed';
      lastAckError = e.toString();
    }
  }

  // ── Legacy compatibility ──
  static bool get hasAdFree => hasSubscription;
  static Future<bool> buyAdFreeSubscription() => buySubscription();
}
