import 'calculator.dart';
import 'prediction_texts.dart';
import 'prediction_texts_en.dart';
import 'prediction_texts_hi.dart';
import 'prediction_texts_ta.dart';
import 'prediction_texts_te.dart';
import 'prediction_texts_ml.dart';
import '../widgets/common.dart';

// ═══════════════════════════════════════════
// PREDICTION ENGINE — Bhava & Dasha Phala Analysis
// Based on Brihat Parashara Hora Shastra & Phaladeepika
// ═══════════════════════════════════════════

// ─── Planet Kannada names (matching calculator.dart keys) ───
const _sun = 'ರವಿ';
const _moon = 'ಚಂದ್ರ';
const _mars = 'ಕುಜ';
const _merc = 'ಬುಧ';
const _jup = 'ಗುರು';
const _ven = 'ಶುಕ್ರ';
const _sat = 'ಶನಿ';
const _rahu = 'ರಾಹು';
const _ketu = 'ಕೇತು';
const _lagna = 'ಲಗ್ನ';

const List<String> _ninePlanets = [_sun, _moon, _mars, _merc, _jup, _ven, _sat, _rahu, _ketu];

// ─── Rashi lordship ───
const List<String> _rashiLord = [
  _mars, _ven, _merc, _moon, _sun, _merc,
  _ven, _mars, _jup, _sat, _sat, _jup,
];

// ─── Exaltation / Debilitation / Own signs ───
const Map<String, int> _exaltRashi = {
  _sun: 0, _moon: 1, _mars: 9, _merc: 5,
  _jup: 3, _ven: 11, _sat: 6,
};

const Map<String, int> _debilRashi = {
  _sun: 6, _moon: 7, _mars: 3, _merc: 11,
  _jup: 9, _ven: 5, _sat: 0,
};

const Map<String, List<int>> _ownSigns = {
  _sun: [4], _moon: [3], _mars: [0, 7], _merc: [2, 5],
  _jup: [8, 11], _ven: [1, 6], _sat: [9, 10],
};

// ─── Natural benefics / malefics ───
const Set<String> _benefics = {_jup, _ven, _merc, _moon};
const Set<String> _malefics = {_sun, _mars, _sat, _rahu, _ketu};

// ─── House classifications ───
const Set<int> _kendras = {1, 4, 7, 10};
const Set<int> _trikonas = {1, 5, 9};
const Set<int> _dusthanas = {6, 8, 12};
const Set<int> _upachayas = {3, 6, 10, 11};

// ═══════════════════════════════════════════
// RESULT MODELS
// ═══════════════════════════════════════════

/// Prediction quality: positive, mixed, or challenging
enum PhalaQuality { shubha, mishra, ashubha }

/// Complete prediction result for a chart
class PredictionResult {
  final List<BhavaPrediction> bhavas;           // 12 house predictions
  final DashaPeriodPrediction? currentDasha;     // current running period
  final List<MahaDashaPrediction> allDashas;     // all 9 mahadasha predictions
  final List<String> highlights;                 // top key points

  const PredictionResult({
    required this.bhavas,
    this.currentDasha,
    required this.allDashas,
    required this.highlights,
  });
}

/// Prediction for a single bhava (house)
class BhavaPrediction {
  final int bhavaNum;              // 1-12
  final String bhavaName;          // e.g., 'ತನು'
  final String significations;     // key significations
  final String lordName;           // house lord planet name
  final int lordInHouse;           // which house the lord sits in
  final String lordDignity;        // exalted/debilitated/own/neutral
  final List<String> planetsInHouse; // planets sitting in this house
  final List<String> aspectingPlanets; // planets aspecting this house
  final String phala;              // detailed prediction text
  final String remedy;             // remedy if challenging
  final PhalaQuality quality;      // overall quality

  const BhavaPrediction({
    required this.bhavaNum,
    required this.bhavaName,
    required this.significations,
    required this.lordName,
    required this.lordInHouse,
    required this.lordDignity,
    required this.planetsInHouse,
    required this.aspectingPlanets,
    required this.phala,
    required this.remedy,
    required this.quality,
  });
}

/// Prediction for current dasha-bhukti period
class DashaPeriodPrediction {
  final String mdLord;
  final String adLord;
  final DateTime mdStart;
  final DateTime mdEnd;
  final DateTime adStart;
  final DateTime adEnd;
  final String relationship;       // kendra, trikona, 6-8, 2-12, etc.
  final String mdPhala;            // mahadasha lord phala
  final String adPhala;            // dasha-bhukti combination phala
  final PhalaQuality quality;

  const DashaPeriodPrediction({
    required this.mdLord,
    required this.adLord,
    required this.mdStart,
    required this.mdEnd,
    required this.adStart,
    required this.adEnd,
    required this.relationship,
    required this.mdPhala,
    required this.adPhala,
    required this.quality,
  });
}

/// Prediction for a Mahadasha period with all its bhukti sub-predictions
class MahaDashaPrediction {
  final String lord;
  final DateTime start;
  final DateTime end;
  final String phala;
  final PhalaQuality quality;
  final List<BhuktiPrediction> bhuktis;

  const MahaDashaPrediction({
    required this.lord,
    required this.start,
    required this.end,
    required this.phala,
    required this.quality,
    required this.bhuktis,
  });
}

/// Prediction for an Antardasha (bhukti) period
class BhuktiPrediction {
  final String lord;
  final DateTime start;
  final DateTime end;
  final String phala;
  final PhalaQuality quality;

  const BhuktiPrediction({
    required this.lord,
    required this.start,
    required this.end,
    required this.phala,
    required this.quality,
  });
}

// ═══════════════════════════════════════════
// PREDICTION ENGINE
// ═══════════════════════════════════════════

class PredictionEngine {
  /// Generate complete predictions for a KundaliResult
  static PredictionResult analyze(KundaliResult result) {
    final planets = result.planets;
    if (planets.isEmpty || !planets.containsKey(_lagna)) {
      return const PredictionResult(bhavas: [], allDashas: [], highlights: []);
    }

    final _lang = AppLocale.current;

    // Multi-language inline text helper
    String _t({required String kn, String? hi, String? ta, String? te, String? ml, String? en}) {
      switch (_lang) {
        case 'en': return en ?? kn;
        case 'hi': return hi ?? kn;
        case 'ta': return ta ?? kn;
        case 'te': return te ?? kn;
        case 'ml': return ml ?? kn;
        default: return kn;
      }
    }

    // Locale-aware text sources — select by language
    List<BhavaInfo> _selectBhavaInfo() {
      switch (_lang) {
        case 'en': return bhavaInfoListEn;
        case 'hi': return bhavaInfoListHi;
        case 'ta': return bhavaInfoListTa;
        case 'te': return bhavaInfoListTe;
        case 'ml': return bhavaInfoListMl;
        default: return bhavaInfoList;
      }
    }
    Map<String, List<String>> _selectPlanetInHouse() {
      switch (_lang) {
        case 'en': return planetInHousePhalaEn;
        case 'hi': return planetInHousePhalaHi;
        case 'ta': return planetInHousePhalaTa;
        case 'te': return planetInHousePhalaTe;
        case 'ml': return planetInHousePhalaMl;
        default: return planetInHousePhala;
      }
    }
    List<List<String>> _selectLordInHouse() {
      switch (_lang) {
        case 'en': return lordInHousePhalaEn;
        case 'hi': return lordInHousePhalaHi;
        case 'ta': return lordInHousePhalaTa;
        case 'te': return lordInHousePhalaTe;
        case 'ml': return lordInHousePhalaMl;
        default: return lordInHousePhala;
      }
    }
    Map<String, String> _selectMahadasha() {
      switch (_lang) {
        case 'en': return mahadashaPhalasEn;
        case 'hi': return mahadashaPhalasHi;
        case 'ta': return mahadashaPhalasTa;
        case 'te': return mahadashaPhalasTe;
        case 'ml': return mahadashaPhalasMl;
        default: return mahadashaPhalas;
      }
    }
    Map<String, Map<String, String>> _selectDashaBhukti() {
      switch (_lang) {
        case 'en': return dashaBhuktiPhalasEn;
        case 'hi': return dashaBhuktiPhalasHi;
        case 'ta': return dashaBhuktiPhalasTa;
        case 'te': return dashaBhuktiPhalasTe;
        case 'ml': return dashaBhuktiPhalasMl;
        default: return dashaBhuktiPhalas;
      }
    }
    Map<String, String> _selectDignity() {
      switch (_lang) {
        case 'en': return dignityModifiersEn;
        case 'hi': return dignityModifiersHi;
        case 'ta': return dignityModifiersTa;
        case 'te': return dignityModifiersTe;
        case 'ml': return dignityModifiersMl;
        default: return dignityModifiers;
      }
    }
    Map<String, PlanetRemedy> _selectRemedies() {
      switch (_lang) {
        case 'en': return planetRemediesEn;
        case 'hi': return planetRemediesHi;
        case 'ta': return planetRemediesTa;
        case 'te': return planetRemediesTe;
        case 'ml': return planetRemediesMl;
        default: return planetRemedies;
      }
    }

    final _bhavaInfo = _selectBhavaInfo();
    final _planetInHouse = _selectPlanetInHouse();
    final _lordInHouse = _selectLordInHouse();
    final _mahadashaP = _selectMahadasha();
    final _dashaBhuktiP = _selectDashaBhukti();
    final _dignityMod = _selectDignity();
    final _remedies = _selectRemedies();

    final lagnaRashi = planets[_lagna]!.rashiIndex;

    // ── Helper functions ──

    /// Get house number (1-12) of a planet from Lagna
    int houseOf(String planet) {
      final p = planets[planet];
      if (p == null) return 0;
      return (p.rashiIndex - lagnaRashi + 12) % 12 + 1;
    }

    /// Get lord of a house (1-12)
    String lordOfHouse(int house) {
      final rashiIdx = (lagnaRashi + house - 1) % 12;
      return _rashiLord[rashiIdx];
    }

    /// Get planets in a house (all 9 planets)
    List<String> planetsInHouse(int house) {
      return _ninePlanets.where((p) => houseOf(p) == house).toList();
    }

    /// Check if planet aspects a house (Parashari drishti — only 7 graha)
    bool aspects(String planet, int targetHouse) {
      // Rahu & Ketu have NO drishti (shadow planets)
      if (planet == _rahu || planet == _ketu) return false;
      final fromHouse = houseOf(planet);
      if (fromHouse == 0) return false;
      final diff = (targetHouse - fromHouse + 12) % 12;
      if (diff == 6) return true; // all planets aspect 7th
      if (planet == _mars && (diff == 3 || diff == 7)) return true;  // 4th, 8th
      if (planet == _jup && (diff == 4 || diff == 8)) return true;   // 5th, 9th
      if (planet == _sat && (diff == 2 || diff == 9)) return true;   // 3rd, 10th
      return false;
    }

    /// Get planets aspecting a house (only 7 graha, no Rahu/Ketu)
    List<String> aspectingPlanets(int house) {
      const sevenPlanets = [_sun, _moon, _mars, _merc, _jup, _ven, _sat];
      return sevenPlanets.where((p) {
        final h = houseOf(p);
        return h != house && aspects(p, house);
      }).toList();
    }

    /// Get ALL dignity states of a planet (can be multiple)
    List<String> dignityList(String planet) {
      final p = planets[planet];
      if (p == null) return [];
      final states = <String>[];
      if (_exaltRashi[planet] == p.rashiIndex) states.add('ಉಚ್ಚ');
      if (_debilRashi[planet] == p.rashiIndex) states.add('ನೀಚ');
      if (_ownSigns[planet]?.contains(p.rashiIndex) ?? false) states.add('ಸ್ವಕ್ಷೇತ್ರ');
      if (p.speed < 0) states.add('ವಕ್ರ');
      if (p.isCombust) states.add('ಅಸ್ತ');
      return states;
    }

    /// Single dignity label for display
    String dignity(String planet) {
      final states = dignityList(planet);
      return states.isEmpty ? 'ಸಾಮಾನ್ಯ' : states.join(', ');
    }

    /// Evaluate quality of a bhava based on its factors
    PhalaQuality evaluateBhavaQuality(int house, String lord, List<String> inHouse, List<String> aspecters) {
      int score = 0;

      // Lord placement
      final lordHouse = houseOf(lord);
      if (_kendras.contains(lordHouse) || _trikonas.contains(lordHouse)) score += 2;
      if (_dusthanas.contains(lordHouse)) score -= 2;
      if (_upachayas.contains(lordHouse)) score += 1;

      // Lord dignity
      final d = dignity(lord);
      if (d == 'ಉಚ್ಚ' || d == 'ಸ್ವಕ್ಷೇತ್ರ') score += 2;
      if (d == 'ನೀಚ') score -= 2;
      if (d == 'ಅಸ್ತ') score -= 1;

      // Benefics in house
      for (final p in inHouse) {
        if (_benefics.contains(p)) score += 1;
        if (_malefics.contains(p) && p != lord) score -= 1;
      }

      // Benefic aspects
      for (final p in aspecters) {
        if (p == _jup) score += 2; // Jupiter aspect is best
        if (_benefics.contains(p)) score += 1;
        if (_malefics.contains(p)) score -= 1;
      }

      if (score >= 2) return PhalaQuality.shubha;
      if (score <= -2) return PhalaQuality.ashubha;
      return PhalaQuality.mishra;
    }

    // ── Build Bhava Predictions ──
    final bhavas = <BhavaPrediction>[];
    final highlights = <String>[];

    for (int h = 1; h <= 12; h++) {
      final lord = lordOfHouse(h);
      final lordH = houseOf(lord);
      final inHouse = planetsInHouse(h);
      final aspecters = aspectingPlanets(h);
      final lordDig = dignity(lord);
      final quality = evaluateBhavaQuality(h, lord, inHouse, aspecters);

      // Build phala text by combining lord placement + planets in house + aspects
      final phalaBuffer = StringBuffer();

      // 1. Lord placement phala
      if (_lordInHouse.length > h - 1 && _lordInHouse[h - 1].length > lordH - 1) {
        phalaBuffer.write(_lordInHouse[h - 1][lordH - 1]);
      }

      // 2. Planet-in-house phalas
      for (final p in inHouse) {
        final phalas = _planetInHouse[p];
        if (phalas != null && phalas.length > h - 1) {
          phalaBuffer.write(' ${phalas[h - 1]}');
        }
      }


      // 3. Dignity modifiers (asta, vakri, etc. — can be multiple)
      for (final state in dignityList(lord)) {
        if (_dignityMod.containsKey(state)) {
          phalaBuffer.write(' ${_dignityMod[state]}');
        }
      }
      // Also check dignity of planets IN the house
      for (final p in inHouse) {
        final pStates = dignityList(p);
        for (final s in pStates) {
          if (s == 'ವಕ್ರ') phalaBuffer.write(_t(
            kn: ' $p ವಕ್ರಗತಿಯಲ್ಲಿದ್ದು ಫಲಗಳಲ್ಲಿ ವಿಳಂಬ ಅಥವಾ ತೀವ್ರತೆ ಸಾಧ್ಯ.',
            hi: ' $p वक्रगति में है, फल में विलंब या तीव्रता संभव.',
            ta: ' $p வக்ரகதியில் உள்ளது, பலன்களில் தாமதம் அல்லது தீவிரம் சாத்தியம்.',
            te: ' $p వక్రగతిలో ఉంది, ఫలాల్లో ఆలస్యం లేదా తీవ్రత సాధ్యం.',
            ml: ' $p വക്രഗതിയിലാണ്, ഫലങ്ങളിൽ താമസം അല്ലെങ്കിൽ തീവ്രത സാധ്യം.',
            en: ' $p is retrograde, causing delays or intensity in results.'));
          if (s == 'ಅಸ್ತ') phalaBuffer.write(_t(
            kn: ' $p ಅಸ್ತಂಗತವಾಗಿದ್ದು ತನ್ನ ಪೂರ್ಣ ಫಲ ನೀಡಲು ಅಸಮರ್ಥ.',
            hi: ' $p अस्त है और अपना पूर्ण फल देने में असमर्थ.',
            ta: ' $p அஸ்தமானது, முழு பலனை வழங்க இயலாது.',
            te: ' $p అస్తమై ఉంది, పూర్ణ ఫలం ఇవ్వలేదు.',
            ml: ' $p അസ്തമായിരിക്കുന്നു, പൂർണ ഫലം നൽകാൻ അസമർഥം.',
            en: ' $p is combust and unable to deliver its full results.'));
        }
      }

      // 4. Aspect effects
      if (aspecters.isNotEmpty) {
        final beneficAspecters = aspecters.where((p) => _benefics.contains(p)).toList();
        final maleficAspecters = aspecters.where((p) => _malefics.contains(p)).toList();
        if (beneficAspecters.isNotEmpty) {
          phalaBuffer.write(_t(
            kn: ' ${beneficAspecters.join(', ')} ದೃಷ್ಟಿಯಿಂದ ಶುಭ ಫಲ ವೃದ್ಧಿ.',
            hi: ' ${beneficAspecters.join(', ')} की दृष्टि से शुभ फल में वृद्धि.',
            ta: ' ${beneficAspecters.join(', ')} பார்வையால் நல்ல பலன் அதிகரிக்கும்.',
            te: ' ${beneficAspecters.join(', ')} దృష్టి వల్ల శుభ ఫలాలు పెరుగుతాయి.',
            ml: ' ${beneficAspecters.join(', ')} ദൃഷ്ടിയാൽ ശുഭ ഫലം വർധിക്കും.',
            en: ' ${beneficAspecters.join(', ')} aspect enhances positive results.'));
        }
        if (maleficAspecters.isNotEmpty) {
          phalaBuffer.write(_t(
            kn: ' ${maleficAspecters.join(', ')} ದೃಷ್ಟಿಯಿಂದ ಕೆಲವು ಸವಾಲುಗಳು ಸಾಧ್ಯ.',
            hi: ' ${maleficAspecters.join(', ')} की दृष्टि से कुछ चुनौतियाँ संभव.',
            ta: ' ${maleficAspecters.join(', ')} பார்வையால் சில சவால்கள் சாத்தியம்.',
            te: ' ${maleficAspecters.join(', ')} దృష్టి వల్ల కొన్ని సవాళ్లు సాధ్యం.',
            ml: ' ${maleficAspecters.join(', ')} ദൃഷ്ടിയാൽ ചില വെല്ലുവിളികൾ സാധ്യം.',
            en: ' ${maleficAspecters.join(', ')} aspect may bring some challenges.'));
        }
      }

      // 5. Remedy for challenging houses
      String remedy = '';
      if (quality == PhalaQuality.ashubha) {
        final rem = _remedies[lord];
        if (rem != null) {
          remedy = _t(
            kn: 'ಪರಿಹಾರ: ${rem.mantra} ಜಪಿಸಿ. ${rem.gemstone} ಧರಿಸಿ. ${rem.day} ${rem.charity}. ${rem.deity} ಪೂಜೆ ಮಾಡಿ.',
            hi: 'उपाय: ${rem.mantra} जपें. ${rem.gemstone} धारण करें. ${rem.day} ${rem.charity}. ${rem.deity} पूजा करें.',
            ta: 'பரிகாரம்: ${rem.mantra} ஜபிக்கவும். ${rem.gemstone} அணியவும். ${rem.day} ${rem.charity}. ${rem.deity} பூஜை செய்யவும்.',
            te: 'పరిహారం: ${rem.mantra} జపించండి. ${rem.gemstone} ధరించండి. ${rem.day} ${rem.charity}. ${rem.deity} పూజ చేయండి.',
            ml: 'പരിഹാരം: ${rem.mantra} ജപിക്കുക. ${rem.gemstone} ധരിക്കുക. ${rem.day} ${rem.charity}. ${rem.deity} പൂജ ചെയ്യുക.',
            en: 'Remedy: Chant ${rem.mantra}. Wear ${rem.gemstone}. On ${rem.day}, ${rem.charity}. Worship ${rem.deity}.');
        }
      } else if (quality == PhalaQuality.mishra) {
        final rem = _remedies[lord];
        if (rem != null) {
          remedy = _t(
            kn: 'ಸಲಹೆ: ${rem.deity} ಪ್ರಾರ್ಥನೆ ಮಾಡಿ. ${rem.day} ${rem.color} ಬಣ್ಣದ ಬಟ್ಟೆ ಧರಿಸಿ.',
            hi: 'सलाह: ${rem.deity} से प्रार्थना करें. ${rem.day} ${rem.color} रंग के कपड़े पहनें.',
            ta: 'ஆலோசனை: ${rem.deity} வழிபடவும். ${rem.day} ${rem.color} நிற ஆடை அணியவும்.',
            te: 'సలహా: ${rem.deity} ప్రార్థన చేయండి. ${rem.day} ${rem.color} రంగు బట్టలు ధరించండి.',
            ml: 'ഉപദേശം: ${rem.deity} പ്രാർഥിക്കുക. ${rem.day} ${rem.color} നിറത്തിലുള്ള വസ്ത്രം ധരിക്കുക.',
            en: 'Advice: Pray to ${rem.deity}. On ${rem.day}, wear ${rem.color} colored clothes.');
        }
      }

      // Generate highlights for exceptional placements
      if (quality == PhalaQuality.shubha && (h == 1 || h == 5 || h == 9 || h == 10)) {
        final info = _bhavaInfo[h - 1];
        highlights.add(_t(
          kn: '${info.nameKn} ಭಾವ ಬಲಿಷ್ಠ — ${info.significations} ವಿಷಯದಲ್ಲಿ ಶುಭ ಫಲ',
          en: '${info.nameKn} house is strong — positive results in ${info.significations}'));
      }
      if (quality == PhalaQuality.ashubha && (h == 1 || h == 7 || h == 8)) {
        final info = _bhavaInfo[h - 1];
        highlights.add(_t(
          kn: '${info.nameKn} ಭಾವಕ್ಕೆ ಗಮನ ಬೇಕು — ಪರಿಹಾರ ಅನುಸರಿಸಿ',
          en: '${info.nameKn} house needs attention — follow remedies'));
      }

      bhavas.add(BhavaPrediction(
        bhavaNum: h,
        bhavaName: _bhavaInfo[h - 1].nameKn,
        significations: _bhavaInfo[h - 1].significations,
        lordName: lord,
        lordInHouse: lordH,
        lordDignity: lordDig,
        planetsInHouse: inHouse,
        aspectingPlanets: aspecters,
        phala: phalaBuffer.toString(),
        remedy: remedy,
        quality: quality,
      ));
    }

    // ── Build Dasha Predictions ──
    DashaPeriodPrediction? currentDasha;
    final allDashas = <MahaDashaPrediction>[];
    final now = DateTime.now();

    for (final md in result.dashas) {
      final mdLord = md.lord;
      final mdHouse = houseOf(mdLord);
      final mdDig = dignity(mdLord);

      // Mahadasha phala from texts
      final mdPhalaText = _mahadashaP[mdLord] ?? '';
      String mdPhala = mdPhalaText;
      if (mdDig != 'ಸಾಮಾನ್ಯ' && _dignityMod.containsKey(mdDig)) {
        mdPhala += ' ${_dignityMod[mdDig]}';
      }

      // Evaluate MD quality
      PhalaQuality mdQuality;
      if (_kendras.contains(mdHouse) || _trikonas.contains(mdHouse)) {
        mdQuality = PhalaQuality.shubha;
      } else if (_dusthanas.contains(mdHouse)) {
        mdQuality = PhalaQuality.ashubha;
      } else {
        mdQuality = PhalaQuality.mishra;
      }
      if (mdDig == 'ಉಚ್ಚ' || mdDig == 'ಸ್ವಕ್ಷೇತ್ರ') {
        if (mdQuality == PhalaQuality.mishra) mdQuality = PhalaQuality.shubha;
      }
      if (mdDig == 'ನೀಚ') {
        if (mdQuality == PhalaQuality.shubha) mdQuality = PhalaQuality.mishra;
        else mdQuality = PhalaQuality.ashubha;
      }

      // Build bhukti predictions
      final bhuktis = <BhuktiPrediction>[];
      for (final ad in md.antardashas) {
        final adLord = ad.lord;
        final adHouse = houseOf(adLord);

        // Dasha-bhukti combination phala from texts
        final dbPhala = _dashaBhuktiP[mdLord]?[adLord] ?? '';

        // Evaluate MD-AD relationship
        final diff = (adHouse - mdHouse + 12) % 12;
        String relationship;
        PhalaQuality adQuality;
        if (diff == 0) {
          relationship = _t(kn: 'ಸಮ ಸ್ಥಾನ', hi: 'सम स्थान', ta: 'சம நிலை', te: 'సమ స్థానం', ml: 'സമ സ്ഥാനം', en: 'Same Sign');
          adQuality = PhalaQuality.shubha;
        } else if ({3, 6, 9}.contains(diff)) {
          relationship = _t(kn: 'ಕೇಂದ್ರ', hi: 'केंद्र', ta: 'கேந்திர', te: 'కేంద్ర', ml: 'കേന്ദ്ര', en: 'Kendra');
          adQuality = PhalaQuality.shubha;
        } else if ({4, 8}.contains(diff)) {
          relationship = _t(kn: 'ತ್ರಿಕೋಣ', hi: 'त्रिकोण', ta: 'திரிகோண', te: 'త్రికోణ', ml: 'ത്രികോണ', en: 'Trikona');
          adQuality = PhalaQuality.shubha;
        } else if ({5, 7}.contains(diff)) {
          relationship = _t(kn: 'ಷಡಷ್ಟಕ (6-8)', hi: 'षडष्टक (6-8)', ta: 'சடாஷ்டக (6-8)', te: 'షడష్టక (6-8)', ml: 'ഷഡഷ്ടക (6-8)', en: 'Shadashtaka (6-8)');
          adQuality = PhalaQuality.ashubha;
        } else if ({1, 11}.contains(diff)) {
          relationship = _t(kn: 'ದ್ವಿರ್ದ್ವಾದಶ (2-12)', hi: 'द्विर्द्वादश (2-12)', ta: 'த்விர்த்வாதச (2-12)', te: 'ద్విర్ద్వాదశ (2-12)', ml: 'ദ്വിർദ്വാദശ (2-12)', en: 'Dwirdwadasha (2-12)');
          adQuality = PhalaQuality.mishra;
        } else {
          relationship = _t(kn: 'ಸಾಮಾನ್ಯ', hi: 'सामान्य', ta: 'சாமான்ய', te: 'సామాన్య', ml: 'സാമാന്യ', en: 'Neutral');
          adQuality = PhalaQuality.mishra;
        }

        bhuktis.add(BhuktiPrediction(
          lord: adLord,
          start: ad.start,
          end: ad.end,
          phala: dbPhala,
          quality: adQuality,
        ));

        // Check if this is the CURRENT running dasha-bhukti
        if (now.isAfter(md.start) && now.isBefore(md.end) &&
            now.isAfter(ad.start) && now.isBefore(ad.end)) {
          currentDasha = DashaPeriodPrediction(
            mdLord: mdLord,
            adLord: adLord,
            mdStart: md.start,
            mdEnd: md.end,
            adStart: ad.start,
            adEnd: ad.end,
            relationship: relationship,
            mdPhala: mdPhala,
            adPhala: dbPhala,
            quality: adQuality,
          );
        }
      }

      allDashas.add(MahaDashaPrediction(
        lord: mdLord,
        start: md.start,
        end: md.end,
        phala: mdPhala,
        quality: mdQuality,
        bhuktis: bhuktis,
      ));
    }

    return PredictionResult(
      bhavas: bhavas,
      currentDasha: currentDasha,
      allDashas: allDashas,
      highlights: highlights,
    );
  }
}
