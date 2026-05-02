import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'google_auth_service.dart';
import 'subscription_service.dart';

/// Manages one-Gmail-one-device binding using Firestore for cross-device enforcement.
///
/// SECURITY: Firestore is the SOLE source of truth.
/// If Firestore is unreachable, we BLOCK (fail-closed) to prevent bypass.
///
/// Flow:
///   1. Each device gets a unique UUID (persisted in SharedPreferences).
///   2. On sign-in, we check Firestore: `device_bindings/{email}` → stored deviceId.
///   3. If no binding exists → register this device.
///   4. If binding exists AND matches this device → OK.
///   5. If binding exists AND does NOT match → BLOCK (show mismatch screen).
///   6. "Migrate Device" updates Firestore to the new device.
class DeviceBindingService {
  static const _deviceIdKey = 'bharatheeyam_device_id';
  static const _firestoreCollection = 'device_bindings';
  static const _localBoundEmailKey = 'bharatheeyam_bound_email';
  static const _localBoundDeviceKey = 'bharatheeyam_bound_device_id';
  static const _lastFirestoreCheckKey = 'bharatheeyam_last_firestore_check';

  static String? _deviceId;
  static bool _isDeviceBound = false; // FAIL-CLOSED: default to blocked until verified
  static bool _hasCheckedOnce = false;

  static bool get isDeviceBound => _isDeviceBound;
  static bool get hasCheckedOnce => _hasCheckedOnce;
  static String? get deviceId => _deviceId;

  /// Get or generate a unique device ID (persisted locally)
  static Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, _deviceId!);
      debugPrint('DeviceBinding: new deviceId=$_deviceId');
    }
    return _deviceId!;
  }

  /// Collect rich device + subscription details for Firestore
  static Future<Map<String, dynamic>> _getDeviceDetails(String email, String devId) async {
    final data = <String, dynamic>{
      'deviceId': devId,
      'email': email.toLowerCase(),
      'lastSeen': FieldValue.serverTimestamp(),
    };

    // Device info
    try {
      if (!kIsWeb) {
        final deviceInfo = DeviceInfoPlugin();
        if (defaultTargetPlatform == TargetPlatform.android) {
          final android = await deviceInfo.androidInfo;
          data['deviceName'] = '${android.brand} ${android.model}';
          data['deviceBrand'] = android.brand;
          data['deviceModel'] = android.model;
          data['androidVersion'] = android.version.release;
          data['sdkInt'] = android.version.sdkInt;
          data['manufacturer'] = android.manufacturer;
          data['product'] = android.product;
          data['fingerprint'] = android.fingerprint;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final ios = await deviceInfo.iosInfo;
          data['deviceName'] = ios.name;
          data['deviceModel'] = ios.model;
          data['iosVersion'] = ios.systemVersion;
        }
      }
    } catch (e) {
      debugPrint('DeviceBinding: device info error: $e');
    }

    // App version
    try {
      final pkgInfo = await PackageInfo.fromPlatform();
      data['appVersion'] = pkgInfo.version;
      data['buildNumber'] = pkgInfo.buildNumber;
    } catch (_) {}

    // Subscription details
    data['hasSubscription'] = SubscriptionService.hasSubscription;
    data['isTrialActive'] = SubscriptionService.isTrialActive;
    data['trialMinutesRemaining'] = SubscriptionService.trialMinutesRemaining;
    if (SubscriptionService.purchaseDate != null) {
      data['subscribedAt'] = Timestamp.fromDate(SubscriptionService.purchaseDate!);
      data['subscriptionDaysRemaining'] = SubscriptionService.subscriptionDaysRemaining;
    }
    if (SubscriptionService.trialStartDate != null) {
      data['trialStartedAt'] = Timestamp.fromDate(SubscriptionService.trialStartDate!);
    }

    return data;
  }

  /// Ensure Firebase is initialized (reuse the centralized init)
  static Future<bool> _ensureFirebase() async {
    try {
      if (Firebase.apps.isNotEmpty) return true;
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyAkG1hdauVlL9b8nHM5o2B25yPQ6IANci4',
            appId: '1:212430902387:web:149c933fd3d29aa5014606',
            messagingSenderId: '212430902387',
            projectId: 'bharatheeyam-app',
            authDomain: 'bharatheeyam-app.firebaseapp.com',
            storageBucket: 'bharatheeyam-app.firebasestorage.app',
            measurementId: 'G-BNTGY2WSLZ',
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      return true;
    } catch (e) {
      debugPrint('DeviceBinding: Firebase init error: $e');
      return Firebase.apps.isNotEmpty; // still might be usable
    }
  }

  /// Check if current device is bound to the signed-in email using Firestore.
  /// Returns true if bound (or first time → auto-registers).
  ///
  /// SECURITY: If Firestore is unreachable, we use a LIMITED local fallback:
  ///   - Only allows if we've previously verified via Firestore AND device+email match
  ///   - New devices that never verified via Firestore are BLOCKED
  static Future<bool> checkBinding() async {
    // Skip device binding on web — no persistent device identity
    if (kIsWeb) {
      _isDeviceBound = true;
      _hasCheckedOnce = true;
      return true;
    }

    final email = GoogleAuthService.userEmail;
    if (email == null) {
      // Not signed in — no binding to check
      _isDeviceBound = true;
      _hasCheckedOnce = true;
      return true;
    }

    final devId = await getDeviceId();

    try {
      final firebaseReady = await _ensureFirebase();
      if (!firebaseReady) {
        debugPrint('DeviceBinding: Firebase NOT ready, using strict local fallback');
        return _strictLocalFallback(email, devId);
      }

      final docRef = FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(email.toLowerCase());

      final doc = await docRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firestore timeout');
        },
      );

      if (!doc.exists || doc.data() == null) {
        // No binding exists → register this device (FIRST TIME)
        final details = await _getDeviceDetails(email, devId);
        details['boundAt'] = FieldValue.serverTimestamp();
        details['bindEvent'] = 'first_bind';
        await docRef.set(details);
        await _cacheLocalBinding(email, devId);
        _isDeviceBound = true;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: FIRST BIND ✅ email=$email devId=$devId');
        return true;
      }

      final storedDeviceId = doc.data()!['deviceId'] as String?;

      if (storedDeviceId == null || storedDeviceId.isEmpty) {
        // Corrupted entry → re-register
        final details = await _getDeviceDetails(email, devId);
        details['boundAt'] = FieldValue.serverTimestamp();
        details['bindEvent'] = 'rebind_corrupted';
        await docRef.set(details);
        await _cacheLocalBinding(email, devId);
        _isDeviceBound = true;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: RE-BIND (corrupted) ✅ email=$email devId=$devId');
        return true;
      }

      if (storedDeviceId == devId) {
        // SAME device → allowed — update with full details
        try {
          final details = await _getDeviceDetails(email, devId);
          await docRef.update(details);
        } catch (_) {
          await docRef.update({'lastSeen': FieldValue.serverTimestamp()}).catchError((_) {});
        }
        await _cacheLocalBinding(email, devId);
        _isDeviceBound = true;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: MATCH ✅ email=$email');
        return true;
      }

      // ── DEVICE MISMATCH ──
      // Import: only enforce for SUBSCRIBED users.
      // Non-subscribed users get auto-rebound (nothing to protect).
      // This prevents false blocks when SharedPreferences gets cleared
      // (app update, clear cache, reinstall) which generates a new UUID.
      final hasActiveSub = (await SharedPreferences.getInstance()).getBool('has_active_subscription') ?? false;
      
      if (!hasActiveSub) {
        // Not subscribed → auto-rebind silently (no subscription to share)
        final details = await _getDeviceDetails(email, devId);
        details['boundAt'] = FieldValue.serverTimestamp();
        details['autoRebound'] = true;
        details['previousDeviceId'] = storedDeviceId;
        details['bindEvent'] = 'auto_rebind_no_sub';
        await docRef.set(details);
        await _cacheLocalBinding(email, devId);
        _isDeviceBound = true;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: AUTO-REBIND (no subscription) ✅ email=$email devId=$devId oldDev=$storedDeviceId');
        return true;
      }

      // SUBSCRIBED user on DIFFERENT device → check one-time auto-migrate
      final prefs = await SharedPreferences.getInstance();
      final rebindVersion = prefs.getInt('bharatheeyam_rebind_version') ?? 0;
      if (rebindVersion < 47) {
        // One-time auto-migrate for this version
        final details = await _getDeviceDetails(email, devId);
        details['boundAt'] = FieldValue.serverTimestamp();
        details['migratedAt'] = FieldValue.serverTimestamp();
        details['autoMigrateVersion'] = 47;
        details['bindEvent'] = 'auto_migrate_v47';
        await docRef.set(details);
        await _cacheLocalBinding(email, devId);
        await prefs.setInt('bharatheeyam_rebind_version', 47);
        _isDeviceBound = true;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: AUTO-MIGRATE v47 ✅ email=$email devId=$devId');
        return true;
      }

      _isDeviceBound = false;
      _hasCheckedOnce = true;
      await _clearLocalBinding();
      debugPrint('DeviceBinding: MISMATCH ❌ email=$email thisDevice=$devId storedDevice=$storedDeviceId');
      return false;
    } catch (e) {
      debugPrint('DeviceBinding check error: $e');
      return _strictLocalFallback(email, devId);
    }
  }
  /// Cache a successful Firestore verification locally
  static Future<void> _cacheLocalBinding(String email, String devId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localBoundEmailKey, email.toLowerCase());
    await prefs.setString(_localBoundDeviceKey, devId);
    await prefs.setInt(_lastFirestoreCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Clear local binding cache (called on mismatch)
  static Future<void> _clearLocalBinding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localBoundEmailKey);
    await prefs.remove(_localBoundDeviceKey);
    await prefs.remove(_lastFirestoreCheckKey);
  }

  /// STRICT local fallback: only allows if we've previously verified via Firestore
  /// AND the cached email+device match the current ones.
  /// New devices that never verified via Firestore are BLOCKED.
  static Future<bool> _strictLocalFallback(String email, String devId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEmail = prefs.getString(_localBoundEmailKey);
      final cachedDevice = prefs.getString(_localBoundDeviceKey);
      final lastCheck = prefs.getInt(_lastFirestoreCheckKey) ?? 0;

      // If never verified via Firestore → BLOCK
      if (cachedEmail == null || cachedDevice == null || lastCheck == 0) {
        _isDeviceBound = false;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: STRICT LOCAL ❌ never verified via Firestore');
        return false;
      }

      // If cached email doesn't match → BLOCK
      if (cachedEmail.toLowerCase() != email.toLowerCase()) {
        _isDeviceBound = false;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: STRICT LOCAL ❌ email mismatch cached=$cachedEmail current=$email');
        return false;
      }

      // If cached device doesn't match → BLOCK
      if (cachedDevice != devId) {
        _isDeviceBound = false;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: STRICT LOCAL ❌ device mismatch');
        return false;
      }

      // Check if the last Firestore verification was within 7 days
      final daysSinceCheck = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastCheck))
          .inDays;
      if (daysSinceCheck > 7) {
        // Stale cache → BLOCK (force online verification)
        _isDeviceBound = false;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: STRICT LOCAL ❌ cache stale ($daysSinceCheck days old)');
        return false;
      }

      // All checks passed → same email, same device, recent Firestore verification
      _isDeviceBound = true;
      _hasCheckedOnce = true;
      debugPrint('DeviceBinding: STRICT LOCAL ✅ cached verification valid ($daysSinceCheck days old)');
      return true;
    } catch (e) {
      debugPrint('DeviceBinding strict local error: $e');
      _isDeviceBound = false; // FAIL-CLOSED
      _hasCheckedOnce = true;
      return false;
    }
  }

  /// Migrate: bind current device to the signed-in email (overwrites old binding in Firestore)
  static Future<bool> migrateDevice() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) {
      debugPrint('DeviceBinding migrate: NO EMAIL — user not signed in');
      return false;
    }

    try {
      final firebaseReady = await _ensureFirebase();
      if (!firebaseReady) {
        debugPrint('DeviceBinding migrate: Firebase NOT ready');
        return false;
      }

      // Re-authenticate to ensure fresh Firebase Auth token for Firestore rules
      try {
        await GoogleAuthService.signInSilently();
        debugPrint('DeviceBinding migrate: re-auth OK');
      } catch (e) {
        debugPrint('DeviceBinding migrate: re-auth failed=$e, trying anyway');
      }

      final devId = await getDeviceId();
      final docRef = FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(email.toLowerCase());

      // Try full details, fallback to minimal if _getDeviceDetails fails
      Map<String, dynamic> details;
      try {
        details = await _getDeviceDetails(email, devId);
      } catch (e) {
        debugPrint('DeviceBinding migrate: details error=$e, using minimal');
        details = {
          'deviceId': devId,
          'email': email.toLowerCase(),
          'lastSeen': FieldValue.serverTimestamp(),
        };
      }

      details['boundAt'] = FieldValue.serverTimestamp();
      details['migratedAt'] = FieldValue.serverTimestamp();
      details['bindEvent'] = 'manual_migrate';
      await docRef.set(details);

      // Cache locally
      await _cacheLocalBinding(email, devId);

      _isDeviceBound = true;
      _hasCheckedOnce = true;
      debugPrint('DeviceBinding: MIGRATED ✅ email=$email devId=$devId');
      return true;
    } catch (e, stack) {
      debugPrint('DeviceBinding migrate error: $e');
      debugPrint('DeviceBinding migrate stack: $stack');
      return false;
    }
  }
}
