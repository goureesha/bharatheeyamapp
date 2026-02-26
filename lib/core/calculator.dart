import 'dart:math';
import '../constants/strings.dart';
import 'ephemeris.dart';

// ============================================================
// KUNDALI RESULT DATA MODELS
// ============================================================

class PlanetInfo {
  final String name;
  final double longitude; // sidereal, degrees
  final double speed;
  final String nakshatra;
  final int pada;
  final String rashi;
  final int rashiIndex;

  PlanetInfo({
    required this.name,
    required this.longitude,
    required this.speed,
    required this.nakshatra,
    required this.pada,
    required this.rashi,
    required this.rashiIndex,
  });
}

class PanchangData {
  final String vara;
  final String tithi;
  final String nakshatra;
  final String yoga;
  final String karana;
  final String chandraRashi;
  final String udayadiGhati;
  final String gataGhati;
  final String paramaGhati;
  final String shesha;
  final String dashaBalance;
  final String dashaLord;
  final int nakshatraIndex;
  final double nakPercent;

  PanchangData({
    required this.vara,
    required this.tithi,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.chandraRashi,
    required this.udayadiGhati,
    required this.gataGhati,
    required this.paramaGhati,
    required this.shesha,
    required this.dashaBalance,
    required this.dashaLord,
    required this.nakshatraIndex,
    required this.nakPercent,
  });
}

class DashaEntry {
  final String lord;
  final DateTime start;
  final DateTime end;
  final List<DashaEntry> antardashas;

  DashaEntry({
    required this.lord,
    required this.start,
    required this.end,
    this.antardashas = const [],
  });
}

class KundaliResult {
  final Map<String, PlanetInfo> planets; // key = Kannada planet name
  final List<double> bhavas; // 12 house cusps
  final PanchangData panchang;
  final List<DashaEntry> dashas;
  final List<int> savBindus;   // Sarvashtakavarga
  final Map<String, List<int>> bavBindus; // Bhinnashtakavarga
  final Map<String, double> advSphutas; // 16 upagrahas

  KundaliResult({
    required this.planets,
    required this.bhavas,
    required this.panchang,
    required this.dashas,
    required this.savBindus,
    required this.bavBindus,
    required this.advSphutas,
  });
}

// ============================================================
// HELPER FORMATTING
// ============================================================

String formatGhati(double decVal) {
  final g = decVal.floor();
  final rem = decVal - g;
  final v = (rem * 60).round();
  final vActual = v == 60 ? 0 : v;
  final gActual = v == 60 ? g + 1 : g;
  return '$gActual.${vActual.toString().padLeft(2, '0')}';
}

String formatDeg(double deg) {
  final rem = deg % 30;
  final tSec = (rem * 3600).round();
  int dg = tSec ~/ 3600;
  int mn = (tSec % 3600) ~/ 60;
  int sc = tSec % 60;
  if (dg == 30) { dg = 29; mn = 59; sc = 59; }
  return '$dgÂ° ${mn.toString().padLeft(2, '0')}\' ${sc.toString().padLeft(2, '0')}"';
}

// ============================================================
// MAIN CALCULATOR  â€” exact port of Python logic
// ============================================================
class AstroCalculator {
  static const double _nakSize = 13.333333333;

  static String _norm(double d) => ((d % 360) + 360).remainder(360).toStringAsFixed(4);

  static double normDeg(double d) => ((d % 360) + 360) % 360;

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Nakshatra info from longitude
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static (String nak, int pada) nakFromDeg(double deg) {
    final idx = (deg / _nakSize).floor() % 27;
    final pada = ((deg % _nakSize) / (_nakSize / 4)).floor() + 1;
    return (knNak[idx], pada.clamp(1, 4));
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // MANDI calculation â€” exact Python port
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static double calcMandi({
    required double jdBirth,
    required double lat,
    required double lon,
    required DateTime dob,
    required String ayanamsaMode,
  }) {
    final y = dob.year; final m = dob.month; final d = dob.day;
    final sr = Ephemeris.findSunrise(y, m, d, lat, lon);
    final ss = Ephemeris.findSunset(y, m, d, lat, lon);

    final pyWeekday = dob.weekday % 7; // Mon=1..Sun=0
    final civilWdayIdx = (pyWeekday + 1) % 7; // Sun=0

    final bool isNight = !(jdBirth >= sr && jdBirth < ss);

    int vedWday;
    double startBase, duration, panchSr;

    if (!isNight) {
      vedWday = civilWdayIdx;
      panchSr = sr;
      startBase = sr;
      duration = ss - sr;
    } else {
      if (jdBirth < sr) {
        vedWday = (civilWdayIdx - 1 + 7) % 7;
        final prev = dob.subtract(const Duration(days: 1));
        final pSr = Ephemeris.findSunrise(prev.year, prev.month, prev.day, lat, lon);
        final pSs = Ephemeris.findSunset(prev.year, prev.month, prev.day, lat, lon);
        startBase = pSs;
        duration = sr - pSs;
        panchSr = pSr;
      } else {
        vedWday = civilWdayIdx;
        final next = dob.add(const Duration(days: 1));
        final nSr = Ephemeris.findSunrise(next.year, next.month, next.day, lat, lon);
        startBase = ss;
        duration = nSr - ss;
        panchSr = sr;
      }
    }

    final List<int> dayFactors = isNight
        ? [10, 6, 2, 26, 22, 18, 14]
        : [26, 22, 18, 14, 10, 6, 2];

    final factor = dayFactors[vedWday];
    final mandiJd = startBase + (duration * factor / 30.0);

    //  Lagna at Mandi time = Mandi degree
    final ayn = _getAyanamsa(mandiJd, ayanamsaMode);
    final gst = Ephemeris.gmst(mandiJd);
    final cusps = Ephemeris.placidusHouses(mandiJd, lat, lon, ayn);
    return cusps[0]; // Ascendant at Mandi time
  }

  static double _getAyanamsa(double jd, String mode) {
    switch (mode) {
      case 'raman': return Ephemeris.ayanamsaRaman(jd);
      case 'kp':    return Ephemeris.ayanamsaKP(jd);
      default:      return Ephemeris.ayanamsaLahiri(jd);
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Find nakshatra boundary (binary search) â€” Python port
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static double findNakLimit(double jd, double targetDeg, String ayanamsaMode) {
    double low = jd - 1.2, high = jd + 1.2;
    for (int i = 0; i < 20; i++) {
      final mid = (low + high) / 2;
      final ayn = _getAyanamsa(mid, ayanamsaMode);
      final planets = Ephemeris.calcAll(mid, ayanamsaMode, true);
      final moonTrop = planets['Moon']![0] + ayn; // back to tropical
      final mDeg = normDeg(moonTrop - ayn);
      final diff = ((mDeg - targetDeg + 180) % 360) - 180;
      if (diff < 0) low = mid; else high = mid;
    }
    return (low + high) / 2;
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ASHTAKAVARGA â€” exact Python port
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static (List<int> sav, Map<String, List<int>> bav) calcAshtakavarga(
      Map<String, double> positions) {
    // P_KEYS in order: Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn, Lagna
    final pKeys = ['à²°à²µà²¿', 'à²šà²‚à²¦à³à²°', 'à²•à³à²œ', 'à²¬à³à²§', 'à²—à³à²°à³', 'à²¶à³à²•à³à²°', 'à²¶à²¨à²¿', 'à²²à²—à³à²¨'];
    final rIdx = {for (var k in pKeys) k: (positions[k]! / 30).floor()};

    final sav = List<int>.filled(12, 0);
    final bav = {
      for (var p in ['à²°à²µà²¿', 'à²šà²‚à²¦à³à²°', 'à²•à³à²œ', 'à²¬à³à²§', 'à²—à³à²°à³', 'à²¶à³à²•à³à²°', 'à²¶à²¨à²¿'])
        p: List<int>.filled(12, 0)
    };

    const bavRules = {
      'à²°à²µà²¿': [[1,2,4,7,8,9,10,11],[3,6,10,11],[1,2,4,7,8,9,10,11],[3,5,6,9,10,11,12],[5,6,9,11],[6,7,12],[1,2,4,7,8,9,10,11],[3,4,6,10,11,12]],
      'à²šà²‚à²¦à³à²°': [[3,6,7,8,10,11],[1,3,6,7,10,11],[2,3,5,6,9,10,11],[1,3,4,5,7,8,10,11],[1,4,7,8,10,11,12],[3,4,5,7,9,10,11],[3,5,6,11],[3,6,10,11]],
      'à²•à³à²œ': [[3,5,6,10,11],[3,6,11],[1,2,4,7,8,10,11],[3,5,6,11],[6,10,11,12],[6,8,11,12],[1,4,7,8,9,10,11],[1,3,6,10,11]],
      'à²¬à³à²§': [[5,6,9,11,12],[2,4,6,8,10,11],[1,2,4,7,8,9,10,11],[1,3,5,6,9,10,11,12],[6,8,11,12],[1,2,3,4,5,8,9,11],[1,2,4,7,8,9,10,11],[1,2,4,6,8,10,11]],
      'à²—à³à²°à³': [[1,2,3,4,7,8,9,10,11],[2,5,7,9,11],[1,2,4,7,8,10,11],[1,2,4,5,6,9,10,11],[1,2,3,4,7,8,10,11],[2,5,6,9,10,11],[3,5,6,12],[1,2,4,5,6,9,10,11]],
      'à²¶à³à²•à³à²°': [[8,11,12],[1,2,3,4,5,8,9,11,12],[3,5,6,9,11,12],[3,5,6,9,11],[5,8,9,10,11],[1,2,3,4,5,8,9,10,11],[3,4,5,8,9,10,11],[1,2,3,4,5,8,9,11]],
      'à²¶à²¨à²¿': [[1,2,4,7,8,10,11],[3,6,11],[3,5,6,10,11,12],[6,8,9,10,11,12],[5,6,11,12],[6,11,12],[3,5,6,11],[1,3,4,6,10,11]],
    };

    for (final target in ['à²°à²µà²¿', 'à²šà²‚à²¦à³à²°', 'à²•à³à²œ', 'à²¬à³à²§', 'à²—à³à²°à³', 'à²¶à³à²•à³à²°', 'à²¶à²¨à²¿']) {
      final rules = bavRules[target]!;
      for (int refIdx = 0; refIdx < pKeys.length; refIdx++) {
        final refRashi = rIdx[pKeys[refIdx]]!;
        for (final h in rules[refIdx]) {
          final signIdx = (refRashi + h - 1) % 12;
          bav[target]![signIdx]++;
          sav[signIdx]++;
        }
      }
    }
    return (sav, bav);
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // VIMSHOTTARI DASHA â€” exact Python port
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static List<DashaEntry> calcDasha(DateTime birthDate, int nIdx, double perc) {
    final List<DashaEntry> result = [];
    DateTime cur = birthDate;
    final si = nIdx % 9;

    for (int i = 0; i < 9; i++) {
      final im = (si + i) % 9;
      final yMul = (i == 0) ? (1 - perc) : 1.0;
      final mdDays = (dashaYears[im] * yMul * 365.25).round();
      final mdEnd = cur.add(Duration(days: mdDays));

      final List<DashaEntry> antars = [];
      DateTime cad = cur;
      for (int j = 0; j < 9; j++) {
        final ia = (im + j) % 9;
        double adY = dashaYears[im] * dashaYears[ia] / 120.0;
        if (i == 0) adY *= (1 - perc);
        final adDays = (adY * 365.25).round();
        final ae = cad.add(Duration(days: adDays));
        antars.add(DashaEntry(lord: dashaLords[ia], start: cad, end: ae));
        cad = ae;
      }

      result.add(DashaEntry(
        lord: dashaLords[im],
        start: cur,
        end: mdEnd,
        antardashas: antars,
      ));
      cur = mdEnd;
    }
    return result;
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // FULL CALCULATION â€” main entry point
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static KundaliResult? calculate({
    required int year,
    required int month,
    required int day,
    required double hourUtcOffset, // hours offset from UTC (IST = 5.5)
    required double hour24,        // local time in hours
    required double lat,
    required double lon,
    required String ayanamsaMode,  // 'lahiri','raman','kp'
    required bool trueNode,
  }) {
    try {
      // Julian Day (UT)
      final jdBirth = Ephemeris.julday(year, month, day, hour24 - hourUtcOffset);
      final dob = DateTime(year, month, day);
      final ayn = _getAyanamsa(jdBirth, ayanamsaMode);

      // Planet positions
      final rawPlanets = Ephemeris.calcAll(jdBirth, ayanamsaMode, trueNode);

      final Map<String, double> positions = {};
      final Map<String, double> speeds = {};
      const engToKn = {
        'Sun': 'à²°à²µà²¿', 'Moon': 'à²šà²‚à²¦à³à²°', 'Mercury': 'à²¬à³à²§', 'Venus': 'à²¶à³à²•à³à²°',
        'Mars': 'à²•à³à²œ', 'Jupiter': 'à²—à³à²°à³', 'Saturn': 'à²¶à²¨à²¿',
        'Rahu': 'à²°à²¾à²¹à³', 'Ketu': 'à²•à³‡à²¤à³',
      };

      for (final entry in rawPlanets.entries) {
        final kn = engToKn[entry.key]!;
        positions[kn] = entry.value[0];
        speeds[kn] = entry.value[1];
      }

      // Lagna (Ascendant)
      final cusps = Ephemeris.placidusHouses(jdBirth, lat, lon, ayn);
      positions['à²²à²—à³à²¨'] = cusps[0];
      speeds['à²²à²—à³à²¨'] = 0;

      // Mandi
      final mandiDeg = calcMandi(
          jdBirth: jdBirth, lat: lat, lon: lon, dob: dob, ayanamsaMode: ayanamsaMode);
      positions['à²®à²¾à²‚à²¦à²¿'] = mandiDeg;
      speeds['à²®à²¾à²‚à²¦à²¿'] = 0;

      // Create PlanetInfo for each
      final Map<String, PlanetInfo> planetInfoMap = {};
      for (final kn in [...positions.keys]) {
        final deg = positions[kn]!;
        final (nak, pada) = nakFromDeg(deg);
        final ri = (deg / 30).floor() % 12;
        planetInfoMap[kn] = PlanetInfo(
          name: kn,
          longitude: deg,
          speed: speeds[kn] ?? 0,
          nakshatra: nak,
          pada: pada,
          rashi: knRashi[ri],
          rashiIndex: ri,
        );
      }

      // Panchang
      final mDeg = positions['à²šà²‚à²¦à³à²°']!;
      final sDeg = positions['à²°à²µà²¿']!;
      final tIdx = (((mDeg - sDeg + 360) % 360) / 12).floor().clamp(0, 29);
      final nIdx  = (mDeg / _nakSize).floor() % 27;
      final yDeg  = (mDeg + sDeg) % 360;
      final yIdx  = (yDeg / _nakSize).floor() % 27;

      final kIdx  = (((mDeg - sDeg + 360) % 360) / 6).floor();
      String kName;
      if (kIdx == 0) kName = 'à²•à²¿à²‚à²¸à³à²¤à³à²˜à³à²¨';
      else if (kIdx == 57) kName = 'à²¶à²•à³à²¨à²¿';
      else if (kIdx == 58) kName = 'à²šà²¤à³à²·à³à²ªà²¾à²¦';
      else if (kIdx == 59) kName = 'à²¨à²¾à²—';
      else {
        const kArr = ['à²¬à²µ', 'à²¬à²¾à²²à²µ', 'à²•à³Œà²²à²µ', 'à²¤à³ˆà²¤à²¿à²²', 'à²—à²°', 'à²µà²£à²¿à²œ', 'à²­à²¦à³à²°à²¾ (à²µà²¿à²·à³à²Ÿà²¿)'];
        kName = kArr[(kIdx - 1) % 7];
      }

      // Sunrise for panchang
      final panSr = Ephemeris.findSunrise(year, month, day, lat, lon);
      final udayadiGhati = formatGhati((jdBirth - panSr) * 60);

      // Nakshatra ghatis
      final js = findNakLimit(jdBirth, nIdx * _nakSize, ayanamsaMode);
      final je = findNakLimit(jdBirth, (nIdx + 1) * _nakSize, ayanamsaMode);
      final gataGhati = formatGhati((jdBirth - js) * 60);
      final paramaGhati = formatGhati((je - js) * 60);
      final sheshaGhati = formatGhati((je - jdBirth) * 60);

      final perc = (mDeg % _nakSize) / _nakSize;
      final bal = dashaYears[nIdx % 9] * (1 - perc);
      final dashaLord = dashaLords[nIdx % 9];

      // Weekday (in Vedic: Sun=0)
      // Python: civil_weekday_idx = (py_weekday + 1) % 7
      // Dart DateTime: Mon=1..Sun=7
      final pyWeekday = dob.weekday % 7;
      final varaIdx = (pyWeekday + 1) % 7;

      final panchang = PanchangData(
        vara: knVara[varaIdx],
        tithi: knTithi[tIdx],
        nakshatra: knNak[nIdx],
        yoga: knYoga[yIdx],
        karana: kName,
        chandraRashi: knRashi[(mDeg / 30).floor() % 12],
        udayadiGhati: udayadiGhati,
        gataGhati: gataGhati,
        paramaGhati: paramaGhati,
        shesha: sheshaGhati,
        dashaBalance: '${bal.floor()}à²µ ${((bal % 1) * 12).floor()}à²¤à²¿',
        dashaLord: dashaLord,
        nakshatraIndex: nIdx,
        nakPercent: perc,
      );

      // Dashas
      final dashas = calcDasha(DateTime(year, month, day), nIdx, perc);

      // Ashtakavarga
      final (sav, bav) = calcAshtakavarga(positions);

      // Advanced Sphutas (16) â€” exact Python port
      final S   = positions['à²°à²µà²¿']!;
      final M   = positions['à²šà²‚à²¦à³à²°']!;
      final J   = positions['à²—à³à²°à³']!;
      final V   = positions['à²¶à³à²•à³à²°']!;
      final Ma  = positions['à²•à³à²œ']!;
      final R   = positions['à²°à²¾à²¹à³']!;
      final Asc = positions['à²²à²—à³à²¨']!;
      final Md  = positions['à²®à²¾à²‚à²¦à²¿']!;

      final dhooma     = normDeg(S + 133.333333);
      final vyatipata  = normDeg(360 - dhooma);
      final parivesha  = normDeg(vyatipata + 180);
      final indrachapa = normDeg(360 - parivesha);
      final upaketu    = normDeg(indrachapa + 16.666667);
      final bhrigu     = normDeg((M + R) / 2);
      final beeja      = normDeg(S + V + J);
      final kshetra    = normDeg(M + Ma + J);
      final yogi       = normDeg(S + M + 93.333333);
      final trisphuta  = normDeg(Asc + M + Md);
      final chatusphuta  = normDeg(trisphuta + S);
      final panchasphuta = normDeg(chatusphuta + R);
      final prana      = normDeg(Asc * 5 + Md);
      final deha       = normDeg(M * 8 + Md);
      final mrityu     = normDeg(Md * 7 + S);
      final sookshma   = normDeg(prana + deha + mrityu);

      final advSphutas = <String, double>{
        'à²§à³‚à²®': dhooma, 'à²µà³à²¯à²¤à³€à²ªà²¾à²¤': vyatipata, 'à²ªà²°à²¿à²µà³‡à²·': parivesha,
        'à²‡à²‚à²¦à³à²°à²šà²¾à²ª': indrachapa, 'à²‰à²ªà²•à³‡à²¤à³': upaketu, 'à²­à³ƒà²—à³ à²¬à²¿.': bhrigu,
        'à²¬à³€à²œ': beeja, 'à²•à³à²·à³‡à²¤à³à²°': kshetra, 'à²¯à³‹à²—à²¿': yogi,
        'à²¤à³à²°à²¿à²¸à³à²«à³à²Ÿ': trisphuta, 'à²šà²¤à³à²ƒà²¸à³à²«à³à²Ÿ': chatusphuta,
        'à²ªà²‚à²šà²¸à³à²«à³à²Ÿ': panchasphuta, 'à²ªà³à²°à²¾à²£': prana, 'à²¦à³‡à²¹': deha,
        'à²®à³ƒà²¤à³à²¯à³': mrityu, 'à²¸à³‚à²•à³à²·à³à²® à²¤à³à²°à²¿.': sookshma,
      };

      return KundaliResult(
        planets: planetInfoMap,
        bhavas: cusps,
        panchang: panchang,
        dashas: dashas,
        savBindus: sav,
        bavBindus: bav,
        advSphutas: advSphutas,
      );
    } catch (e) {
      return null;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Planet popup detail (Vargas) â€” exact Python port
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Map<String, dynamic> getPlanetDetail(String pName, double deg, double speed, double sunDeg) {
    final degFmt = formatDeg(deg);
    bool isAsta = false;
    String gati = 'à²…à²¨à³à²µà²¯à²¿à²¸à³à²µà³à²¦à²¿à²²à³à²²';

    if (!['à²°à²µà²¿', 'à²°à²¾à²¹à³', 'à²•à³‡à²¤à³', 'à²²à²—à³à²¨', 'à²®à²¾à²‚à²¦à²¿'].contains(pName)) {
      double diff = (deg - sunDeg).abs();
      if (diff > 180) diff = 360 - diff;
      const limits = {'à²šà²‚à²¦à³à²°': 12, 'à²•à³à²œ': 17, 'à²¬à³à²§': 14, 'à²—à³à²°à³': 11, 'à²¶à³à²•à³à²°': 10, 'à²¶à²¨à²¿': 15};
      if (diff <= (limits[pName] ?? 0)) isAsta = true;
      gati = (pName == 'à²šà²‚à²¦à³à²°') ? 'à²¨à³‡à²°' : (speed < 0 ? 'à²µà²•à³à²°à²¿' : 'à²¨à³‡à²°');
    } else if (['à²°à²¾à²¹à³', 'à²•à³‡à²¤à³'].contains(pName)) {
      gati = 'à²µà²•à³à²°à²¿';
    } else if (pName == 'à²°à²µà²¿') {
      gati = 'à²¨à³‡à²°';
    }

    final d1Idx = (deg / 30).floor() % 12;
    final dr = deg % 30;
    final isOdd = (d1Idx % 2 == 0);

    int d2Idx = isOdd ? (dr < 15 ? 4 : 3) : (dr < 15 ? 3 : 4);
    int trueD3Idx = dr < 10 ? d1Idx : (dr < 20 ? (d1Idx + 4) % 12 : (d1Idx + 8) % 12);
    final d9Exact = (deg * 9) % 360;
    final d9Idx   = (d9Exact / 30).floor() % 12;
    final d12Idx  = (d1Idx + (dr / 2.5).floor()) % 12;

    int d30Idx;
    if (isOdd) {
      if (dr < 5) d30Idx = 0;
      else if (dr < 10) d30Idx = 10;
      else if (dr < 18) d30Idx = 8;
      else if (dr < 25) d30Idx = 2;
      else d30Idx = 6;
    } else {
      if (dr < 5) d30Idx = 5;
      else if (dr < 12) d30Idx = 2;
      else if (dr < 20) d30Idx = 8;
      else if (dr < 25) d30Idx = 10;
      else d30Idx = 0;
    }

    return {
      'degFmt': degFmt,
      'gati': gati,
      'isAsta': isAsta,
      'd1': knRashi[d1Idx],
      'd2': knRashi[d2Idx],
      'd3': knRashi[trueD3Idx],
      'd9': knRashi[d9Idx],
      'd12': knRashi[d12Idx],
      'd30': knRashi[d30Idx],
    };
  }
}
