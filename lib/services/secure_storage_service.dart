import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Encrypted key-value storage backed by Android Keystore / iOS Keychain.
/// On first use, auto-migrates sensitive keys from plain SharedPreferences.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _migrationDoneKey = '_secure_migration_v1';

  // ── Keys to migrate from SharedPreferences ──
  static const _keysToMigrate = [
    'has_active_access',
    'has_active_subscription', // legacy
    'trial_used_seconds',
    'trial_open_count',
    'last_online_check_timestamp',
    'user_blocked',
    'user_blocked_reason',
    'bharatheeyam_device_id',
    'muhurta_unlocked',
    'is_student',
    'device_blocked',
    'device_blocked_reason',
    'bharatheeyam_bound_email',
    'bharatheeyam_bound_device_id',
    'bharatheeyam_last_firestore_check',
  ];

  /// Initialize and migrate from SharedPreferences if not done yet.
  static Future<void> initialize() async {
    if (kIsWeb) return; // flutter_secure_storage doesn't work on web

    try {
      final alreadyMigrated = await _storage.read(key: _migrationDoneKey);
      if (alreadyMigrated == 'true') return;

      final prefs = await SharedPreferences.getInstance();

      for (final key in _keysToMigrate) {
        // Check if the key exists in SharedPreferences
        if (prefs.containsKey(key)) {
          final value = prefs.get(key);
          if (value != null) {
            await _storage.write(key: key, value: value.toString());
          }
          // Remove from plain storage after migration
          await prefs.remove(key);
        }
      }

      await _storage.write(key: _migrationDoneKey, value: 'true');
      debugPrint('🔐 Migrated ${_keysToMigrate.length} keys to encrypted storage');
    } catch (e) {
      debugPrint('SecureStorage migration error: $e');
      // Migration failure is non-fatal — data stays in SharedPreferences
    }
  }

  // ── Read helpers ──

  static Future<String?> getString(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('SecureStorage read error ($key): $e');
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? defaultValue;
    }
    try {
      final val = await _storage.read(key: key);
      if (val == null) return defaultValue;
      return val == 'true';
    } catch (e) {
      debugPrint('SecureStorage read error ($key): $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? defaultValue;
    }
  }

  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key) ?? defaultValue;
    }
    try {
      final val = await _storage.read(key: key);
      if (val == null) return defaultValue;
      return int.tryParse(val) ?? defaultValue;
    } catch (e) {
      debugPrint('SecureStorage read error ($key): $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key) ?? defaultValue;
    }
  }

  // ── Write helpers ──

  static Future<void> setString(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      return;
    }
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('SecureStorage write error ($key): $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  static Future<void> setBool(String key, bool value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      return;
    }
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (e) {
      debugPrint('SecureStorage write error ($key): $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    }
  }

  static Future<void> setInt(String key, int value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
      return;
    }
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (e) {
      debugPrint('SecureStorage write error ($key): $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    }
  }

  /// Delete a key from secure storage
  static Future<void> delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      return;
    }
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('SecureStorage delete error ($key): $e');
    }
  }

  /// Check if a key exists
  static Future<bool> containsKey(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    }
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      return false;
    }
  }
}
