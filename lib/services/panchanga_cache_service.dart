import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import 'location_service.dart';

/// Pre-computes and caches full PanchangData for 10 years.
///
/// On first launch: computes all days with a progress callback, saves to SharedPreferences.
/// On subsequent launches: loads instantly from cache.
class PanchangaCacheService {
  static final Map<DateTime, PanchangData> _cache = {};
  static bool _isReady = false;
  static bool _isComputing = false;

  static const String _prefix = 'pc_'; // panchanga cache
  static const String _versionKey = 'pc_ver';
  static const int _version = 1;

  /// Whether the cache is ready (loaded or computed)
  static bool get isReady => _isReady;
  static bool get isComputing => _isComputing;

  /// Get cached PanchangData for a specific date (instant)
  static PanchangData? getPanchang(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _cache[key];
  }

  /// Check if pre-computation has been done (data exists on disk)
  static Future<bool> isPrecomputed() async {
    final prefs = await SharedPreferences.getInstance();
    final ver = prefs.getInt(_versionKey) ?? 0;
    return ver == _version;
  }

  /// Load all cached data from disk into memory
  static Future<bool> loadFromDisk() async {
    if (_isReady) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ver = prefs.getInt(_versionKey) ?? 0;
      if (ver != _version) return false;

      final now = DateTime.now();
      final startYear = now.year - 5;
      final endYear = now.year + 5;
      bool anyLoaded = false;

      for (int year = startYear; year <= endYear; year++) {
        for (int month = 1; month <= 12; month++) {
          final jsonStr = prefs.getString('$_prefix${year}_$month');
          if (jsonStr == null) continue;
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          for (final entry in data.entries) {
            final day = int.parse(entry.key);
            final date = DateTime(year, month, day);
            _cache[date] = PanchangData.fromJson(entry.value as Map<String, dynamic>);
            anyLoaded = true;
          }
        }
      }

      if (anyLoaded) {
        _isReady = true;
        debugPrint('PanchangaCache: Loaded ${_cache.length} days from disk');
      }
      return anyLoaded;
    } catch (e) {
      debugPrint('PanchangaCache: Load error: $e');
      return false;
    }
  }

  /// Pre-compute PanchangData for 10 years (current ± 5)
  /// [onProgress] callback receives (completedDays, totalDays, currentYearLabel)
  static Future<void> precompute({
    void Function(int completed, int total, String label)? onProgress,
  }) async {
    if (_isComputing) return;
    _isComputing = true;

    final now = DateTime.now();
    final startYear = now.year - 5;
    final endYear = now.year + 5;

    // Count total days
    int totalDays = 0;
    for (int y = startYear; y <= endYear; y++) {
      for (int m = 1; m <= 12; m++) {
        totalDays += DateTime(y, m + 1, 0).day;
      }
    }

    int completed = 0;
    final lat = LocationService.lat;
    final lon = LocationService.lon;
    final tz = LocationService.tzOffset;

    try {
      await Ephemeris.initSweph();
    } catch (e) {
      debugPrint('PanchangaCache: Ephemeris init failed: $e');
      _isComputing = false;
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    for (int year = startYear; year <= endYear; year++) {
      for (int month = 1; month <= 12; month++) {
        final daysInMonth = DateTime(year, month + 1, 0).day;
        final monthData = <String, dynamic>{};

        for (int day = 1; day <= daysInMonth; day++) {
          try {
            final srSs = Ephemeris.findSunriseSetForDate(year, month, day, lat, lon, tzOffset: tz);
            final srFrac = ((srSs[0] + 0.5 + (tz / 24.0)) % 1.0 + 1.0) % 1.0;
            final h24 = (srFrac * 24.0) + (1.0 / 60.0);

            final result = await AstroCalculator.calculate(
              year: year, month: month, day: day,
              hourUtcOffset: tz, hour24: h24,
              lat: lat, lon: lon,
              ayanamsaMode: 'lahiri', trueNode: true,
            );

            if (result != null) {
              final dateKey = DateTime(year, month, day);
              _cache[dateKey] = result.panchang;
              monthData['$day'] = result.panchang.toJson();
            }
          } catch (e) {
            debugPrint('PanchangaCache: Error $year-$month-$day: $e');
          }

          completed++;
          // Update progress every 5 days to avoid UI jank
          if (completed % 5 == 0 || completed == totalDays) {
            onProgress?.call(completed, totalDays, '$year');
            await Future.delayed(Duration.zero); // yield to UI
          }
        }

        // Save this month to disk
        if (monthData.isNotEmpty) {
          await prefs.setString('$_prefix${year}_$month', jsonEncode(monthData));
        }
      }
    }

    await prefs.setInt(_versionKey, _version);
    _isReady = true;
    _isComputing = false;
    debugPrint('PanchangaCache: Pre-computed ${_cache.length} days ($startYear-$endYear)');
  }

  /// Clear all cached data
  static Future<void> clear() async {
    _cache.clear();
    _isReady = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
      await prefs.remove(_versionKey);
    } catch (_) {}
  }
}
