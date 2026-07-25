import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import '../core/muhurta_rules.dart';
import '../core/user_muhurta_rules.dart';
import '../constants/strings.dart';

/// ──────────────────────────────────────────────────────────────
/// Pre-computed panchanga data for a single day
/// ──────────────────────────────────────────────────────────────
class CachedPanchangaDay {
  final DateTime date;
  // Panchanga indices
  final int tithiIndex;        // 0-29
  final String tithiName;
  final int nakshatraIndex;    // 0-26
  final String nakshatraName;
  final int yogaIndex;         // 0-26
  final String yogaName;
  final String karanaName;
  final int varaIndex;         // 0=Sun..6=Sat
  final String varaName;
  // Rashi indices
  final int moonRashiIndex;    // 0-11
  final int jupiterRashiIndex; // 0-11
  final int sunRashiIndex;     // 0-11
  // Combustion
  final bool guruCombust;
  final bool venusCombust;
  // Sunrise/Sunset
  final String sunrise;
  final String sunset;
  // Planet longitudes (for any future use)
  final double sunLon;
  final double moonLon;
  final double jupLon;
  // Nakshatra pada
  final int pada;
  // Tithi/Nak end times
  final String tithiEndTime;
  final String nakEndTime;
  // Nakshatra percent (for pada derivation)
  final double nakPercent;
  // Chandra Rashi name
  final String chandraRashi;

  CachedPanchangaDay({
    required this.date,
    required this.tithiIndex,
    required this.tithiName,
    required this.nakshatraIndex,
    required this.nakshatraName,
    required this.yogaIndex,
    required this.yogaName,
    required this.karanaName,
    required this.varaIndex,
    required this.varaName,
    required this.moonRashiIndex,
    required this.jupiterRashiIndex,
    required this.sunRashiIndex,
    required this.guruCombust,
    required this.venusCombust,
    required this.sunrise,
    required this.sunset,
    required this.sunLon,
    required this.moonLon,
    required this.jupLon,
    required this.pada,
    required this.tithiEndTime,
    required this.nakEndTime,
    required this.nakPercent,
    required this.chandraRashi,
  });

  /// Encode to compact list for storage
  List<dynamic> toCompact() => [
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    tithiIndex, tithiName, nakshatraIndex, nakshatraName,
    yogaIndex, yogaName, karanaName,
    moonRashiIndex, jupiterRashiIndex, sunRashiIndex,
    guruCombust ? 1 : 0, venusCombust ? 1 : 0,
    sunrise, sunset,
    (sunLon * 100).round() / 100.0,
    (moonLon * 100).round() / 100.0,
    (jupLon * 100).round() / 100.0,
    pada, tithiEndTime, nakEndTime,
    (nakPercent * 1000).round() / 1000.0,
    chandraRashi,
  ];

  /// Decode from compact list
  factory CachedPanchangaDay.fromCompact(List<dynamic> arr) {
    final dateParts = (arr[0] as String).split('-');
    final date = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
    // Vara from date
    final weekday = date.weekday % 7; // Dart: Mon=1..Sun=7 → Sun=0
    final knVara = ['ಭಾನುವಾರ','ಸೋಮವಾರ','ಮಂಗಳವಾರ','ಬುಧವಾರ','ಗುರುವಾರ','ಶುಕ್ರವಾರ','ಶನಿವಾರ'];
    return CachedPanchangaDay(
      date: date,
      tithiIndex: arr[1] as int,
      tithiName: arr[2] as String,
      nakshatraIndex: arr[3] as int,
      nakshatraName: arr[4] as String,
      yogaIndex: arr[5] as int,
      yogaName: arr[6] as String,
      karanaName: arr[7] as String,
      varaIndex: weekday,
      varaName: knVara[weekday],
      moonRashiIndex: arr[8] as int,
      jupiterRashiIndex: arr[9] as int,
      sunRashiIndex: arr[10] as int,
      guruCombust: arr[11] == 1,
      venusCombust: arr[12] == 1,
      sunrise: arr[13] as String,
      sunset: arr[14] as String,
      sunLon: (arr[15] as num).toDouble(),
      moonLon: (arr[16] as num).toDouble(),
      jupLon: (arr[17] as num).toDouble(),
      pada: arr[18] as int,
      tithiEndTime: arr[19] as String,
      nakEndTime: arr[20] as String,
      nakPercent: (arr[21] as num).toDouble(),
      chandraRashi: arr[22] as String,
    );
  }
}

/// ──────────────────────────────────────────────────────────────
/// PanchangaCache — singleton service for pre-computed data
/// ──────────────────────────────────────────────────────────────
class PanchangaCache {
  PanchangaCache._();
  static final instance = PanchangaCache._();

  List<CachedPanchangaDay>? _days;
  Map<String, CachedPanchangaDay>? _dayMap; // key: "YYYY-MM-DD"

  bool get isLoaded => _days != null && _days!.isNotEmpty;
  int get dayCount => _days?.length ?? 0;

  DateTime? get startDate => _days?.first.date;
  DateTime? get endDate => _days?.last.date;

  /// Location info stored with the cache
  double? _cachedLat;
  double? _cachedLon;
  double? get cachedLat => _cachedLat;
  double? get cachedLon => _cachedLon;

  /// Get cache file path
  Future<File> get _cacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/panchanga_cache_v1.json');
  }

  /// Load from local file
  Future<bool> loadFromStorage() async {
    try {
      final file = await _cacheFile;
      if (!await file.exists()) return false;

      final raw = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(raw);
      _cachedLat = (json['lat'] as num?)?.toDouble();
      _cachedLon = (json['lon'] as num?)?.toDouble();

      final List<dynamic> daysJson = json['days'] as List<dynamic>;
      _days = daysJson.map((d) => CachedPanchangaDay.fromCompact(d as List<dynamic>)).toList();
      _buildIndex();
      return true;
    } catch (e) {
      debugPrint('PanchangaCache load error: $e');
      return false;
    }
  }

  /// Save to local file
  Future<void> saveToStorage() async {
    if (_days == null) return;
    final file = await _cacheFile;
    final json = {
      'v': 1,
      'lat': _cachedLat,
      'lon': _cachedLon,
      'days': _days!.map((d) => d.toCompact()).toList(),
    };
    await file.writeAsString(jsonEncode(json));
  }

  void _buildIndex() {
    _dayMap = {};
    for (final d in _days!) {
      final key = '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}';
      _dayMap![key] = d;
    }
  }

  /// Get cached data for a specific date
  CachedPanchangaDay? getDay(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _dayMap?[key];
  }

  /// Get all days in a date range
  List<CachedPanchangaDay> getDaysInRange(DateTime start, DateTime end) {
    if (_days == null) return [];
    return _days!.where((d) =>
      !d.date.isBefore(DateTime(start.year, start.month, start.day)) &&
      !d.date.isAfter(DateTime(end.year, end.month, end.day))
    ).toList();
  }

  /// ────────────────────────────────────────────────────────────
  /// INSTANT FILTER: Filter days by muhurta rules
  /// Returns days that pass ALL panchanga checks
  /// ────────────────────────────────────────────────────────────
  List<CachedPanchangaDay> filterByRules({
    required MuhurtaEventRules rules,
    required DateTime startDate,
    required DateTime endDate,
    required int janmaNakIdx,
    required int janmaRashiIdx,
  }) {
    final daysInRange = getDaysInRange(startDate, endDate);
    final results = <CachedPanchangaDay>[];

    for (final day in daysInRange) {
      // 1. Tithi check
      if (rules.allowedTithis != null && !rules.allowedTithis!.contains(day.tithiIndex)) continue;

      // 2. Nakshatra check
      if (rules.allowedNakshatras != null && !rules.allowedNakshatras!.contains(day.nakshatraIndex)) continue;

      // 3. Vara check
      if (rules.allowedVaras != null && !rules.allowedVaras!.contains(day.varaIndex)) continue;

      // 4. Yoga check (blocked yogas)
      if (blockedYogaIndices.contains(day.yogaIndex)) continue;

      // 5. Karana check (avoid Vishti/Bhadra)
      if (rules.avoidVishti && (day.karanaName.contains('ವಿಷ್ಟಿ') || day.karanaName.contains('ಭದ್ರಾ'))) continue;

      // 6. Dagdha Yoga check
      final dagdhaList = dagdhaYogaTable[day.varaIndex];
      if (dagdhaList != null && dagdhaList.contains(day.nakshatraIndex)) continue;

      // 7. Shukla Paksha check
      if (rules.requireShukla && day.tithiIndex >= 15) continue;

      // 8. Uttarayana check (Sun in Makara to Mithuna = rashi 9,10,11,0,1,2)
      if (rules.requireUttarayana) {
        final sunRashi = day.sunRashiIndex;
        final isUttarayana = (sunRashi >= 9 || sunRashi <= 2);
        if (!isUttarayana) continue;
      }

      // 9. Guru combustion
      if (day.guruCombust) continue;

      // 10. Tara Bala check
      final taraBala = calculateTaraBala(janmaNakIdx, day.nakshatraIndex);
      if (!taraBala.isGood) continue;

      // 11. Guru Bala check
      final guruBala = calculateGuruBala(janmaRashiIdx, day.jupiterRashiIndex);
      if (guruBala.score == 0) continue;

      results.add(day);
    }
    return results;
  }

  /// ────────────────────────────────────────────────────────────
  /// INSTANT FILTER using user-editable rules
  /// ────────────────────────────────────────────────────────────
  List<CachedPanchangaDay> filterByUserRules({
    required UserMuhurtaRules userRules,
    required DateTime startDate,
    required DateTime endDate,
    required int janmaNakIdx,
    required int janmaRashiIdx,
  }) {
    final daysInRange = getDaysInRange(startDate, endDate);
    final results = <CachedPanchangaDay>[];

    for (final day in daysInRange) {
      // 1. Tithi check
      if (userRules.allowedTithis != null && !userRules.allowedTithis!.contains(day.tithiIndex)) continue;

      // 2. Nakshatra check
      if (userRules.allowedNakshatras != null && !userRules.allowedNakshatras!.contains(day.nakshatraIndex)) continue;

      // 3. Vara check
      if (userRules.allowedVaras != null && !userRules.allowedVaras!.contains(day.varaIndex)) continue;

      // 4. Yoga check (user-customizable blocked yogas)
      final blocked = userRules.blockedYogas ?? blockedYogaIndices;
      if (blocked.contains(day.yogaIndex)) continue;

      // 5. Karana check
      if (userRules.avoidVishti && (day.karanaName.contains('ವಿಷ್ಟಿ') || day.karanaName.contains('ಭದ್ರಾ'))) continue;

      // 6. Dagdha Yoga check
      final dagdhaList = dagdhaYogaTable[day.varaIndex];
      if (dagdhaList != null && dagdhaList.contains(day.nakshatraIndex)) continue;

      // 7. Shukla Paksha check
      if (userRules.requireShukla && day.tithiIndex >= 15) continue;

      // 8. Uttarayana check
      if (userRules.requireUttarayana) {
        final sunRashi = day.sunRashiIndex;
        final isUttarayana = (sunRashi >= 9 || sunRashi <= 2);
        if (!isUttarayana) continue;
      }

      // 9. Guru combustion
      if (day.guruCombust) continue;

      // 10. Tara Bala check (user-toggleable + user-selectable taras)
      if (userRules.requireTaraBala) {
        final taraBala = calculateTaraBala(janmaNakIdx, day.nakshatraIndex);
        if (!userRules.allowedTaras.contains(taraBala.taraIndex)) continue;
      }

      // 11. Guru Bala check (user-toggleable)
      if (userRules.requireGuruBala) {
        final guruBala = calculateGuruBala(janmaRashiIdx, day.jupiterRashiIndex);
        if (guruBala.score == 0) continue;
      }

      results.add(day);
    }
    return results;
  }

  /// ────────────────────────────────────────────────────────────
  /// GENERATE: Compute panchanga for a date range
  /// Calls progress callback with (current, total) for UI updates
  /// ────────────────────────────────────────────────────────────
  Future<void> generate({
    required DateTime startDate,
    required DateTime endDate,
    required double lat,
    required double lon,
    required double tzOffset,
    void Function(int current, int total)? onProgress,
  }) async {
    await Ephemeris.initSweph();

    final days = <CachedPanchangaDay>[];
    DateTime cur = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    // Count total days
    int totalDays = 0;
    DateTime tmp = cur;
    while (!tmp.isAfter(end)) {
      totalDays++;
      tmp = tmp.add(const Duration(days: 1));
    }

    int processed = 0;

    final knVara = ['ಭಾನುವಾರ','ಸೋಮವಾರ','ಮಂಗಳವಾರ','ಬುಧವಾರ','ಗುರುವಾರ','ಶುಕ್ರವಾರ','ಶನಿವಾರ'];

    while (!cur.isAfter(end)) {
      try {
        // Compute sunrise
        final srSs = Ephemeris.findSunriseSetForDate(
          cur.year, cur.month, cur.day,
          lat, lon, tzOffset: tzOffset,
        );
        final srJd = srSs[0];
        final srLocalFrac = ((srJd + 0.5 + (tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
        final hour24 = (srLocalFrac * 24.0) + (1.0 / 60.0);

        // Full precise calculation at sunrise
        final kr = await AstroCalculator.calculate(
          year: cur.year, month: cur.month, day: cur.day,
          hourUtcOffset: tzOffset,
          hour24: hour24,
          lat: lat, lon: lon,
          ayanamsaMode: 'lahiri', trueNode: true,
        );

        if (kr != null) {
          final pan = kr.panchang;
          final varaIdx = cur.weekday % 7;

          final jupDeg = kr.planets['ಗುರು']?.longitude ?? 0;
          final jupRashi = (jupDeg / 30).floor() % 12;
          final sunDeg = kr.planets['ರವಿ']?.longitude ?? 0;
          final sunRashi = (sunDeg / 30).floor() % 12;
          final moonDeg = kr.planets['ಚಂದ್ರ']?.longitude ?? 0;
          final moonRashi = (moonDeg / 30).floor() % 12;

          final guruCombust = kr.planets['ಗುರು']?.isCombust ?? false;
          final venusCombust = kr.planets['ಶುಕ್ರ']?.isCombust ?? false;

          final moonPada = kr.planets['ಚಂದ್ರ']?.pada ?? ((pan.nakPercent * 4).floor() + 1);

          days.add(CachedPanchangaDay(
            date: cur,
            tithiIndex: pan.tithiIndex,
            tithiName: pan.tithi,
            nakshatraIndex: pan.nakshatraIndex,
            nakshatraName: pan.nakshatra,
            yogaIndex: knYoga.indexOf(pan.yoga),
            yogaName: pan.yoga,
            karanaName: pan.karana,
            varaIndex: varaIdx,
            varaName: knVara[varaIdx],
            moonRashiIndex: moonRashi,
            jupiterRashiIndex: jupRashi,
            sunRashiIndex: sunRashi,
            guruCombust: guruCombust,
            venusCombust: venusCombust,
            sunrise: pan.sunrise,
            sunset: pan.sunset,
            sunLon: sunDeg,
            moonLon: moonDeg,
            jupLon: jupDeg,
            pada: moonPada,
            tithiEndTime: pan.tithiEndTime,
            nakEndTime: pan.nakEndTime,
            nakPercent: pan.nakPercent,
            chandraRashi: pan.chandraRashi,
          ));
        }
      } catch (e) {
        debugPrint('PanchangaCache generate error for $cur: $e');
      }

      processed++;
      // Yield to UI every day to keep UI responsive
      onProgress?.call(processed, totalDays);
      await Future.delayed(Duration.zero);

      cur = cur.add(const Duration(days: 1));
    }

    _days = days;
    _cachedLat = lat;
    _cachedLon = lon;
    _buildIndex();

    // Save to persistent storage
    await saveToStorage();
  }

  /// Clear all cached data
  Future<void> clear() async {
    _days = null;
    _dayMap = null;
    _cachedLat = null;
    _cachedLon = null;
    try {
      final file = await _cacheFile;
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

