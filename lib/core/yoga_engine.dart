import 'calculator.dart';

// ═══════════════════════════════════════════
// YOGA ENGINE — Evaluates classical Vedic planetary Yogas
// ═══════════════════════════════════════════

class YogaResult {
  final String nameKn;   // Kannada name
  final String nameEn;   // English name
  final String category; // 'raja', 'dhana', 'pancha', 'chandra', 'graha', 'other'
  final String descKn;   // Kannada description/explanation
  final String descEn;   // English description/explanation
  final bool isPositive; // true = Shubha, false = Ashubha

  const YogaResult({
    required this.nameKn,
    required this.nameEn,
    required this.category,
    required this.descKn,
    required this.descEn,
    this.isPositive = true,
  });
}

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

// ─── Rashi lordship: rashiIndex → planet key ───
const List<String> _rashiLord = [
  _mars,  // 0  Aries
  _ven,   // 1  Taurus
  _merc,  // 2  Gemini
  _moon,  // 3  Cancer
  _sun,   // 4  Leo
  _merc,  // 5  Virgo
  _ven,   // 6  Libra
  _mars,  // 7  Scorpio
  _jup,   // 8  Sagittarius
  _sat,   // 9  Capricorn
  _sat,   // 10 Aquarius
  _jup,   // 11 Pisces
];

// ─── Exaltation rashi for each planet ───
const Map<String, int> _exaltRashi = {
  _sun: 0, _moon: 1, _mars: 9, _merc: 5,
  _jup: 3, _ven: 11, _sat: 6,
};

// ─── Debilitation rashi ───
const Map<String, int> _debilRashi = {
  _sun: 6, _moon: 7, _mars: 3, _merc: 11,
  _jup: 9, _ven: 5, _sat: 0,
};

// ─── Own signs ───
const Map<String, List<int>> _ownSigns = {
  _sun: [4],
  _moon: [3],
  _mars: [0, 7],
  _merc: [2, 5],
  _jup: [8, 11],
  _ven: [1, 6],
  _sat: [9, 10],
};

// ─── Natural benefics ───
const Set<String> _benefics = {_jup, _ven, _merc, _moon};

// ─── Kendra houses ───
const Set<int> _kendras = {1, 4, 7, 10};

// ─── Trikona houses ───
const Set<int> _trikonas = {1, 5, 9};

// ─── Dusthana houses ───
const Set<int> _dusthanas = {6, 8, 12};

// ─── 7 main planets (exclude Rahu, Ketu, Lagna, Maandi) ───
const List<String> _sevenPlanets = [_sun, _moon, _mars, _merc, _jup, _ven, _sat];

// ─── Planets for Chandra yoga check (exclude Sun, Rahu, Ketu) ───
const List<String> _chandraYogaPlanets = [_mars, _merc, _jup, _ven, _sat];

class YogaEngine {
  /// Evaluate all yogas for a given KundaliResult
  static List<YogaResult> evaluate(KundaliResult result) {
    final planets = result.planets;
    if (planets.isEmpty || !planets.containsKey(_lagna)) return [];

    final lagnaRashi = planets[_lagna]!.rashiIndex;
    final yogas = <YogaResult>[];

    // Helper: get house number (1-12) from lagna
    int houseOf(String planet) {
      final p = planets[planet];
      if (p == null) return 0;
      return (p.rashiIndex - lagnaRashi + 12) % 12 + 1;
    }

    // Helper: get house from Moon
    int houseFromMoon(String planet) {
      final moonRashi = planets[_moon]?.rashiIndex ?? 0;
      final p = planets[planet];
      if (p == null) return 0;
      return (p.rashiIndex - moonRashi + 12) % 12 + 1;
    }

    // Helper: check if planet is in own sign
    bool isInOwnSign(String planet) {
      final p = planets[planet];
      if (p == null) return false;
      return _ownSigns[planet]?.contains(p.rashiIndex) ?? false;
    }

    // Helper: check if planet is exalted
    bool isExalted(String planet) {
      final p = planets[planet];
      if (p == null) return false;
      return _exaltRashi[planet] == p.rashiIndex;
    }

    // Helper: check if planet is debilitated
    bool isDebilitated(String planet) {
      final p = planets[planet];
      if (p == null) return false;
      return _debilRashi[planet] == p.rashiIndex;
    }

    // Helper: check if planet is retrograde
    bool isRetro(String planet) {
      final p = planets[planet];
      if (p == null) return false;
      return p.speed < 0;
    }

    // Helper: check if two planets are in same rashi
    bool conjunct(String a, String b) {
      final pa = planets[a];
      final pb = planets[b];
      if (pa == null || pb == null) return false;
      return pa.rashiIndex == pb.rashiIndex;
    }

    // Helper: get lord of a house (1-12)
    String lordOfHouse(int house) {
      final rashiIdx = (lagnaRashi + house - 1) % 12;
      return _rashiLord[rashiIdx];
    }

    // Helper: check vedic aspect (planet aspects target house from its own house)
    bool aspects(String planet, int targetHouse) {
      final fromHouse = houseOf(planet);
      if (fromHouse == 0) return false;
      final diff = (targetHouse - fromHouse + 12) % 12;
      // All planets aspect 7th
      if (diff == 6) return true;
      // Mars aspects 4th and 8th
      if (planet == _mars && (diff == 3 || diff == 7)) return true;
      // Jupiter aspects 5th and 9th
      if (planet == _jup && (diff == 4 || diff == 8)) return true;
      // Saturn aspects 3rd and 10th
      if (planet == _sat && (diff == 2 || diff == 9)) return true;
      return false;
    }

    // Helper: planets in a given house
    List<String> planetsInHouse(int house) {
      return _sevenPlanets.where((p) => houseOf(p) == house).toList();
    }

    // ═══════════════════════════════════════
    // 1. GAJA KESARI YOGA
    // Jupiter in Kendra (1,4,7,10) from Moon
    // ═══════════════════════════════════════
    {
      final jupFromMoon = houseFromMoon(_jup);
      if (_kendras.contains(jupFromMoon)) {
        yogas.add(const YogaResult(
          nameKn: 'ಗಜಕೇಸರಿ ಯೋಗ',
          nameEn: 'Gaja Kesari Yoga',
          category: 'raja',
          descKn: 'ಗುರು ಚಂದ್ರನಿಂದ ಕೇಂದ್ರದಲ್ಲಿದ್ದಾರೆ. ಕೀರ್ತಿ, ಬುದ್ಧಿ ಮತ್ತು ಸಂಪತ್ತು ಲಭಿಸುತ್ತದೆ.',
          descEn: 'Jupiter in Kendra from Moon. Bestows fame, wisdom and wealth.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 2. BUDHADITYA YOGA
    // Sun + Mercury in same house
    // ═══════════════════════════════════════
    if (conjunct(_sun, _merc)) {
      final h = houseOf(_sun);
      if (!_dusthanas.contains(h)) {
        yogas.add(const YogaResult(
          nameKn: 'ಬುಧಾದಿತ್ಯ ಯೋಗ',
          nameEn: 'Budhaditya Yoga',
          category: 'graha',
          descKn: 'ರವಿ ಮತ್ತು ಬುಧ ಒಂದೇ ರಾಶಿಯಲ್ಲಿದ್ದಾರೆ. ಬುದ್ಧಿಶಕ್ತಿ, ವಾಕ್ಚಾತುರ್ಯ ಮತ್ತು ವಿದ್ಯೆಯಲ್ಲಿ ಉನ್ನತಿ.',
          descEn: 'Sun and Mercury conjunct. Intelligence, eloquence and learning.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 3. CHANDRA-MANGAL YOGA
    // Moon + Mars in same house
    // ═══════════════════════════════════════
    if (conjunct(_moon, _mars)) {
      yogas.add(const YogaResult(
        nameKn: 'ಚಂದ್ರ-ಮಂಗಳ ಯೋಗ',
        nameEn: 'Chandra-Mangal Yoga',
        category: 'dhana',
        descKn: 'ಚಂದ್ರ ಮತ್ತು ಕುಜ ಒಂದೇ ರಾಶಿಯಲ್ಲಿದ್ದಾರೆ. ಧನಪ್ರಾಪ್ತಿ ಮತ್ತು ಸಾಹಸ ಪ್ರವೃತ್ತಿ.',
        descEn: 'Moon and Mars conjunct. Wealth through courage and enterprise.',
      ));
    }

    // ═══════════════════════════════════════
    // 4-8. PANCHA MAHAPURUSHA YOGAS
    // Planet in own/exalted sign in Kendra from Lagna
    // ═══════════════════════════════════════
    final _mahapurushaData = [
      [_mars, 'ರುಚಕ ಯೋಗ', 'Ruchaka Yoga', 'ಕುಜ ಸ್ವಕ್ಷೇತ್ರ/ಉಚ್ಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿದ್ದಾರೆ. ಶೌರ್ಯ, ನಾಯಕತ್ವ ಮತ್ತು ಭೂಸಂಪತ್ತು.',
        'Mars in own/exalted sign in Kendra. Valor, leadership and landed property.'],
      [_merc, 'ಭದ್ರ ಯೋಗ', 'Bhadra Yoga', 'ಬುಧ ಸ್ವಕ್ಷೇತ್ರ/ಉಚ್ಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿದ್ದಾರೆ. ವಿದ್ಯೆ, ವಾಣಿಜ್ಯ ಮತ್ತು ವಾಕ್ಶಕ್ತಿ.',
        'Mercury in own/exalted sign in Kendra. Learning, commerce and eloquence.'],
      [_jup, 'ಹಂಸ ಯೋಗ', 'Hamsa Yoga', 'ಗುರು ಸ್ವಕ್ಷೇತ್ರ/ಉಚ್ಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿದ್ದಾರೆ. ಧಾರ್ಮಿಕತೆ, ಜ್ಞಾನ ಮತ್ತು ಉನ್ನತ ಪದವಿ.',
        'Jupiter in own/exalted sign in Kendra. Spirituality, wisdom and high status.'],
      [_ven, 'ಮಾಲವ್ಯ ಯೋಗ', 'Malavya Yoga', 'ಶುಕ್ರ ಸ್ವಕ್ಷೇತ್ರ/ಉಚ್ಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿದ್ದಾರೆ. ಸೌಂದರ್ಯ, ಕಲೆ ಮತ್ತು ಭೋಗಸುಖ.',
        'Venus in own/exalted sign in Kendra. Beauty, art and luxuries.'],
      [_sat, 'ಶಶ ಯೋಗ', 'Shasha Yoga', 'ಶನಿ ಸ್ವಕ್ಷೇತ್ರ/ಉಚ್ಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿದ್ದಾರೆ. ಅಧಿಕಾರ, ಶಿಸ್ತು ಮತ್ತು ದೀರ್ಘಾಯುಷ್ಯ.',
        'Saturn in own/exalted sign in Kendra. Authority, discipline and longevity.'],
    ];
    for (final data in _mahapurushaData) {
      final planet = data[0] as String;
      final h = houseOf(planet);
      if (_kendras.contains(h) && (isInOwnSign(planet) || isExalted(planet))) {
        yogas.add(YogaResult(
          nameKn: data[1] as String,
          nameEn: data[2] as String,
          category: 'pancha',
          descKn: data[3] as String,
          descEn: data[4] as String,
        ));
      }
    }

    // ═══════════════════════════════════════
    // 9. SUNAPHA YOGA
    // Planets (except Sun, Rahu, Ketu) in 2nd from Moon
    // ═══════════════════════════════════════
    {
      final in2nd = _chandraYogaPlanets.where((p) => houseFromMoon(p) == 2).toList();
      if (in2nd.isNotEmpty) {
        yogas.add(const YogaResult(
          nameKn: 'ಸುನಫಾ ಯೋಗ',
          nameEn: 'Sunapha Yoga',
          category: 'chandra',
          descKn: 'ಚಂದ್ರನಿಂದ ೨ನೇ ಮನೆಯಲ್ಲಿ ಗ್ರಹವಿದೆ. ಸ್ವಪ್ರಯತ್ನದಿಂದ ಸಂಪತ್ತು ಮತ್ತು ಅಧಿಕಾರ.',
          descEn: 'Planet in 2nd from Moon. Self-earned wealth and authority.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 10. ANAPHA YOGA
    // Planets (except Sun, Rahu, Ketu) in 12th from Moon
    // ═══════════════════════════════════════
    {
      final in12th = _chandraYogaPlanets.where((p) => houseFromMoon(p) == 12).toList();
      if (in12th.isNotEmpty) {
        yogas.add(const YogaResult(
          nameKn: 'ಅನಫಾ ಯೋಗ',
          nameEn: 'Anapha Yoga',
          category: 'chandra',
          descKn: 'ಚಂದ್ರನಿಂದ ೧೨ನೇ ಮನೆಯಲ್ಲಿ ಗ್ರಹವಿದೆ. ಆಧ್ಯಾತ್ಮಿಕ ಒಲವು, ಉದಾರತೆ.',
          descEn: 'Planet in 12th from Moon. Spiritual inclination and generosity.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 11. DURDHURA YOGA
    // Planets in both 2nd and 12th from Moon
    // ═══════════════════════════════════════
    {
      final in2nd = _chandraYogaPlanets.any((p) => houseFromMoon(p) == 2);
      final in12th = _chandraYogaPlanets.any((p) => houseFromMoon(p) == 12);
      if (in2nd && in12th) {
        yogas.add(const YogaResult(
          nameKn: 'ದುರ್ಧುರಾ ಯೋಗ',
          nameEn: 'Durdhura Yoga',
          category: 'chandra',
          descKn: 'ಚಂದ್ರನ ೨ ಮತ್ತು ೧೨ನೇ ಮನೆಯಲ್ಲಿ ಗ್ರಹಗಳಿವೆ. ಐಶ್ವರ್ಯ, ವಾಹನ ಮತ್ತು ಸಂಪತ್ತು.',
          descEn: 'Planets in 2nd and 12th from Moon. Wealth, vehicles and prosperity.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 12. KEMADRUMA YOGA (Ashubha)
    // No planets in 2nd or 12th from Moon
    // ═══════════════════════════════════════
    {
      final in2nd = _chandraYogaPlanets.any((p) => houseFromMoon(p) == 2);
      final in12th = _chandraYogaPlanets.any((p) => houseFromMoon(p) == 12);
      final inKendraFromMoon = _sevenPlanets.where((p) => p != _moon).any((p) {
        final h = houseFromMoon(p);
        return _kendras.contains(h);
      });
      if (!in2nd && !in12th && !inKendraFromMoon) {
        yogas.add(const YogaResult(
          nameKn: 'ಕೇಮದ್ರುಮ ಯೋಗ',
          nameEn: 'Kemadruma Yoga',
          category: 'chandra',
          descKn: 'ಚಂದ್ರನ ೨ ಮತ್ತು ೧೨ನೇ ಮನೆಯಲ್ಲಿ ಯಾವ ಗ್ರಹವೂ ಇಲ್ಲ. ಆರ್ಥಿಕ ಕಷ್ಟ, ಒಂಟಿತನ.',
          descEn: 'No planets in 2nd/12th from Moon or Kendra. Financial hardship and loneliness.',
          isPositive: false,
        ));
      }
    }

    // ═══════════════════════════════════════
    // 13. SHAKATA YOGA (Ashubha)
    // Jupiter in 6, 8, or 12 from Moon
    // ═══════════════════════════════════════
    {
      final jupFromMoon = houseFromMoon(_jup);
      if (_dusthanas.contains(jupFromMoon)) {
        yogas.add(const YogaResult(
          nameKn: 'ಶಕಟ ಯೋಗ',
          nameEn: 'Shakata Yoga',
          category: 'chandra',
          descKn: 'ಗುರು ಚಂದ್ರನಿಂದ ೬/೮/೧೨ನೇ ಮನೆಯಲ್ಲಿದ್ದಾರೆ. ಅಸ್ಥಿರ ಅದೃಷ್ಟ, ಏರಿಳಿತಗಳು.',
          descEn: 'Jupiter in 6/8/12 from Moon. Fluctuating fortune and ups-downs.',
          isPositive: false,
        ));
      }
    }

    // ═══════════════════════════════════════
    // 14. AMALA YOGA
    // Natural benefic in 10th from Lagna
    // ═══════════════════════════════════════
    {
      final in10th = _benefics.where((p) => houseOf(p) == 10).toList();
      if (in10th.isNotEmpty) {
        yogas.add(const YogaResult(
          nameKn: 'ಅಮಲ ಯೋಗ',
          nameEn: 'Amala Yoga',
          category: 'raja',
          descKn: 'ಶುಭ ಗ್ರಹ ೧೦ನೇ ಮನೆಯಲ್ಲಿದೆ. ಶುದ್ಧ ಕೀರ್ತಿ, ಸತ್ಕಾರ್ಯ ಮತ್ತು ಯಶಸ್ಸು.',
          descEn: 'Benefic in 10th house. Spotless reputation, good deeds and success.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 15. VIPAREETHA RAJA YOGA
    // Lord of 6/8/12 placed in another 6/8/12
    // ═══════════════════════════════════════
    {
      final dusthanaHouses = [6, 8, 12];
      for (final dh in dusthanaHouses) {
        final lord = lordOfHouse(dh);
        final lordH = houseOf(lord);
        if (_dusthanas.contains(lordH) && lordH != dh) {
          yogas.add(YogaResult(
            nameKn: 'ವಿಪರೀತ ರಾಜಯೋಗ',
            nameEn: 'Vipareetha Raja Yoga',
            category: 'raja',
            descKn: '${dh}ನೇ ಮನೆಯ ಅಧಿಪತಿ ${lordH}ನೇ ಮನೆಯಲ್ಲಿದ್ದಾರೆ. ಕಷ್ಟಗಳ ಮೂಲಕ ಉನ್ನತಿ.',
            descEn: 'Lord of house $dh in house $lordH. Rise through adversity.',
          ));
          break; // Show only once
        }
      }
    }

    // ═══════════════════════════════════════
    // 16. NEECHABHANGA RAJA YOGA
    // Debilitated planet with cancellation conditions
    // ═══════════════════════════════════════
    for (final planet in _sevenPlanets) {
      if (!isDebilitated(planet)) continue;
      final pInfo = planets[planet]!;
      final debRashi = pInfo.rashiIndex;
      final lordOfDebSign = _rashiLord[debRashi];

      // Cancellation 1: Lord of debilitation sign in Kendra from Lagna/Moon
      final lordH = houseOf(lordOfDebSign);
      final lordHMoon = houseFromMoon(lordOfDebSign);
      // Cancellation 2: Planet is retrograde
      // Cancellation 3: Exaltation lord aspects the debilitated planet
      bool cancelled = false;
      if (_kendras.contains(lordH) || _kendras.contains(lordHMoon)) cancelled = true;
      if (isRetro(planet)) cancelled = true;

      if (cancelled) {
        yogas.add(YogaResult(
          nameKn: 'ನೀಚಭಂಗ ರಾಜಯೋಗ',
          nameEn: 'Neechabhanga Raja Yoga',
          category: 'raja',
          descKn: 'ನೀಚ ಗ್ರಹದ ಭಂಗ. ನೀಚ ಸ್ಥಿತಿ ರದ್ದಾಗಿ ರಾಜಯೋಗ ಫಲ ಲಭಿಸುತ್ತದೆ.',
          descEn: 'Debilitation cancelled. Turns weakness into great strength and rise.',
        ));
        break; // Show only once
      }
    }

    // ═══════════════════════════════════════
    // 17. LAKSHMI YOGA
    // Lord of 9th in Kendra/Trikona and strong
    // ═══════════════════════════════════════
    {
      final lord9 = lordOfHouse(9);
      final lord9H = houseOf(lord9);
      if ((_kendras.contains(lord9H) || _trikonas.contains(lord9H)) &&
          (isInOwnSign(lord9) || isExalted(lord9))) {
        yogas.add(const YogaResult(
          nameKn: 'ಲಕ್ಷ್ಮೀ ಯೋಗ',
          nameEn: 'Lakshmi Yoga',
          category: 'dhana',
          descKn: '೯ನೇ ಅಧಿಪತಿ ಕೇಂದ್ರ/ತ್ರಿಕೋಣದಲ್ಲಿ ಬಲಿಷ್ಠವಾಗಿದ್ದಾರೆ. ಮಹಾ ಸಂಪತ್ತು ಮತ್ತು ಸೌಭಾಗ್ಯ.',
          descEn: 'Lord of 9th strong in Kendra/Trikona. Great wealth and fortune.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 18. KENDRA-TRIKONA RAJA YOGA
    // Lord of Kendra + Lord of Trikona conjunct/in same house
    // ═══════════════════════════════════════
    {
      final kendraLords = <String>{};
      final trikonaLords = <String>{};
      for (final k in _kendras) {
        final l = lordOfHouse(k);
        if (l != _sun && l != _moon) kendraLords.add(l);
      }
      for (final t in _trikonas) {
        final l = lordOfHouse(t);
        if (l != _sun && l != _moon) trikonaLords.add(l);
      }

      bool found = false;
      for (final kl in kendraLords) {
        for (final tl in trikonaLords) {
          if (kl == tl) continue; // Same planet can't form this yoga
          if (conjunct(kl, tl)) {
            yogas.add(const YogaResult(
              nameKn: 'ಕೇಂದ್ರ-ತ್ರಿಕೋಣ ರಾಜಯೋಗ',
              nameEn: 'Kendra-Trikona Raja Yoga',
              category: 'raja',
              descKn: 'ಕೇಂದ್ರ ಮತ್ತು ತ್ರಿಕೋಣ ಅಧಿಪತಿಗಳ ಸಂಯೋಗ. ಅಧಿಕಾರ, ಯಶಸ್ಸು ಮತ್ತು ಸಾಮಾಜಿಕ ಗೌರವ.',
              descEn: 'Lords of Kendra and Trikona conjunct. Power, success and social honour.',
            ));
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }

    // ═══════════════════════════════════════
    // 19. SARASWATI YOGA
    // Jupiter, Venus, Mercury in Kendra/Trikona/2nd
    // ═══════════════════════════════════════
    {
      final goodHouses = {..._kendras, ..._trikonas, 2};
      final jupH = houseOf(_jup);
      final venH = houseOf(_ven);
      final merH = houseOf(_merc);
      if (goodHouses.contains(jupH) && goodHouses.contains(venH) && goodHouses.contains(merH)) {
        yogas.add(const YogaResult(
          nameKn: 'ಸರಸ್ವತಿ ಯೋಗ',
          nameEn: 'Saraswati Yoga',
          category: 'other',
          descKn: 'ಗುರು, ಶುಕ್ರ, ಬುಧ ಕೇಂದ್ರ/ತ್ರಿಕೋಣ/೨ನೇ ಮನೆಯಲ್ಲಿದ್ದಾರೆ. ವಿದ್ಯೆ, ಕಲೆ ಮತ್ತು ವಾಗ್ಮಿತ್ವ.',
          descEn: 'Jupiter, Venus, Mercury in Kendra/Trikona/2nd. Learning, arts and eloquence.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 20. DHANA YOGA
    // Lord of 2nd and Lord of 11th in Kendra/Trikona
    // ═══════════════════════════════════════
    {
      final lord2 = lordOfHouse(2);
      final lord11 = lordOfHouse(11);
      final lord2H = houseOf(lord2);
      final lord11H = houseOf(lord11);
      final good = {..._kendras, ..._trikonas};
      if (good.contains(lord2H) && good.contains(lord11H)) {
        yogas.add(const YogaResult(
          nameKn: 'ಧನ ಯೋಗ',
          nameEn: 'Dhana Yoga',
          category: 'dhana',
          descKn: '೨ ಮತ್ತು ೧೧ನೇ ಅಧಿಪತಿಗಳು ಕೇಂದ್ರ/ತ್ರಿಕೋಣದಲ್ಲಿದ್ದಾರೆ. ಧನ ಪ್ರಾಪ್ತಿ ಮತ್ತು ಆರ್ಥಿಕ ಸ್ಥಿರತೆ.',
          descEn: 'Lords of 2nd and 11th in Kendra/Trikona. Wealth acquisition and financial stability.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 21. ADHI YOGA
    // Benefics in 6th, 7th, 8th from Moon
    // ═══════════════════════════════════════
    {
      final beneficsFrom678 = _benefics.where((p) {
        final h = houseFromMoon(p);
        return h == 6 || h == 7 || h == 8;
      }).toList();
      if (beneficsFrom678.length >= 2) {
        yogas.add(const YogaResult(
          nameKn: 'ಅಧಿ ಯೋಗ',
          nameEn: 'Adhi Yoga',
          category: 'raja',
          descKn: 'ಚಂದ್ರನಿಂದ ೬/೭/೮ನೇ ಮನೆಯಲ್ಲಿ ಶುಭ ಗ್ರಹಗಳಿವೆ. ನಾಯಕತ್ವ, ಅಧಿಕಾರ ಮತ್ತು ಸಮೃದ್ಧಿ.',
          descEn: 'Benefics in 6/7/8 from Moon. Leadership, authority and prosperity.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 22. VOSHI YOGA
    // Planet (not Moon, Rahu, Ketu) in 2nd from Sun
    // ═══════════════════════════════════════
    {
      final sunRashi = planets[_sun]?.rashiIndex ?? 0;
      final in2ndFromSun = [_mars, _merc, _jup, _ven, _sat].where((p) {
        final pr = planets[p]?.rashiIndex ?? -1;
        return (pr - sunRashi + 12) % 12 == 1;
      }).toList();
      if (in2ndFromSun.isNotEmpty) {
        yogas.add(const YogaResult(
          nameKn: 'ವೋಶಿ ಯೋಗ',
          nameEn: 'Voshi Yoga',
          category: 'graha',
          descKn: 'ರವಿಯಿಂದ ೨ನೇ ಮನೆಯಲ್ಲಿ ಗ್ರಹವಿದೆ. ಸ್ಮರಣಶಕ್ತಿ, ಧೈರ್ಯ ಮತ್ತು ಸಾಮರ್ಥ್ಯ.',
          descEn: 'Planet in 2nd from Sun. Good memory, courage and ability.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 23. VESHI YOGA
    // Planet (not Moon, Rahu, Ketu) in 12th from Sun
    // ═══════════════════════════════════════
    {
      final sunRashi = planets[_sun]?.rashiIndex ?? 0;
      final in12thFromSun = [_mars, _merc, _jup, _ven, _sat].where((p) {
        final pr = planets[p]?.rashiIndex ?? -1;
        return (pr - sunRashi + 12) % 12 == 11;
      }).toList();
      if (in12thFromSun.isNotEmpty) {
        yogas.add(const YogaResult(
          nameKn: 'ವೇಶಿ ಯೋಗ',
          nameEn: 'Veshi Yoga',
          category: 'graha',
          descKn: 'ರವಿಯಿಂದ ೧೨ನೇ ಮನೆಯಲ್ಲಿ ಗ್ರಹವಿದೆ. ದಾನಶೀಲತೆ, ಸತ್ಯಪ್ರಿಯತೆ.',
          descEn: 'Planet in 12th from Sun. Charitable nature and truthfulness.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 24. UBHAYACHARI YOGA
    // Planets in both 2nd and 12th from Sun
    // ═══════════════════════════════════════
    {
      final sunRashi = planets[_sun]?.rashiIndex ?? 0;
      final in2 = [_mars, _merc, _jup, _ven, _sat].any((p) {
        final pr = planets[p]?.rashiIndex ?? -1;
        return (pr - sunRashi + 12) % 12 == 1;
      });
      final in12 = [_mars, _merc, _jup, _ven, _sat].any((p) {
        final pr = planets[p]?.rashiIndex ?? -1;
        return (pr - sunRashi + 12) % 12 == 11;
      });
      if (in2 && in12) {
        yogas.add(const YogaResult(
          nameKn: 'ಉಭಯಚಾರಿ ಯೋಗ',
          nameEn: 'Ubhayachari Yoga',
          category: 'graha',
          descKn: 'ರವಿಯ ೨ ಮತ್ತು ೧೨ನೇ ಮನೆಯಲ್ಲಿ ಗ್ರಹಗಳಿವೆ. ಸರ್ವಗುಣ ಸಂಪನ್ನ, ರಾಜ ಸಮಾನ.',
          descEn: 'Planets in 2nd and 12th from Sun. Kingly qualities, all-round ability.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 25. KAHALA YOGA
    // Lord of 4th and Jupiter in mutual Kendra
    // ═══════════════════════════════════════
    {
      final lord4 = lordOfHouse(4);
      final lord4H = houseOf(lord4);
      final jupH = houseOf(_jup);
      final diff = (jupH - lord4H + 12) % 12;
      if (diff == 0 || diff == 3 || diff == 6 || diff == 9) {
        if (lord4 != _jup && (_kendras.contains(lord4H) || _kendras.contains(jupH))) {
          yogas.add(const YogaResult(
            nameKn: 'ಕಹಳ ಯೋಗ',
            nameEn: 'Kahala Yoga',
            category: 'other',
            descKn: '೪ನೇ ಅಧಿಪತಿ ಮತ್ತು ಗುರು ಪರಸ್ಪರ ಕೇಂದ್ರದಲ್ಲಿದ್ದಾರೆ. ಧೈರ್ಯ ಮತ್ತು ಸಾಹಸ.',
            descEn: 'Lord of 4th and Jupiter in mutual Kendra. Courage and adventurous spirit.',
          ));
        }
      }
    }

    return yogas;
  }
}
