import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';

/// Runtime security checks — root/emulator/debugger detection.
/// Blocks tampered environments from accessing the app.
class SecurityService {
  static bool _initialized = false;
  static bool isRooted = false;
  static bool isEmulator = false;
  static bool isDebuggerAttached = false;
  static bool isTampered = false;

  /// Run all security checks. Call once during app startup.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Skip on web — no native APIs
    if (kIsWeb) return;

    try {
      // Run checks in parallel for speed
      final results = await Future.wait([
        _checkRoot(),
        _checkEmulator(),
        _checkDebugger(),
      ]);

      isRooted = results[0];
      isEmulator = results[1];
      isDebuggerAttached = results[2];

      // Tampered if ANY check fails
      isTampered = isRooted || isDebuggerAttached;
      // Note: emulator alone doesn't block (dev/testing), but logs warning

      if (isRooted) {
        debugPrint('\u{1F6A8} SECURITY: Device is ROOTED');
      }
      if (isEmulator) {
        debugPrint('\u{26A0}\u{FE0F} SECURITY: Running on EMULATOR');
      }
      if (isDebuggerAttached) {
        debugPrint('\u{1F6A8} SECURITY: Debugger ATTACHED');
      }
    } catch (e) {
      debugPrint('SecurityService init error: $e');
      // Fail-open to prevent blocking legitimate users on unusual devices
    }
  }

  /// Check if device is rooted (Android) or jailbroken (iOS)
  static Future<bool> _checkRoot() async {
    try {
      return await SafeDevice.isJailBroken;
    } catch (e) {
      debugPrint('Root check error: $e');
    }
    return false;
  }

  /// Check if running on an emulator
  static Future<bool> _checkEmulator() async {
    try {
      final isReal = await SafeDevice.isRealDevice;
      return !isReal;
    } catch (e) {
      debugPrint('Emulator check error: $e');
    }
    return false;
  }

  /// Check if a debugger is attached (release builds only)
  static Future<bool> _checkDebugger() async {
    // In debug/profile mode, debugger is expected — don't flag it
    if (!kReleaseMode) return false;
    try {
      // Dart's assert-based detection: asserts are stripped in release mode.
      // If we detect the profile says "debug", something is wrong.
      bool debugMode = false;
      assert(() {
        debugMode = true;
        return true;
      }());
      return debugMode; // true in release = tampered
    } catch (_) {}
    return false;
  }

  /// Human-readable reason string (for UI display)
  static String get tamperReason {
    final reasons = <String>[];
    if (isRooted) reasons.add('Rooted/Jailbroken device');
    if (isDebuggerAttached) reasons.add('Debugger detected');
    return reasons.join(', ');
  }
}
