// Janana / Marana Dosha Engine
// Checks birth panchanga for classical inauspicious combinations.
// References: Muhurta Chintamani, Brihat Jataka, Jataka Parijata,
// Surya Siddhanta, Prasna Marga, Hora Sara, Muhurta Bodhane.

import '../constants/strings.dart';

/// Category of dosha
enum DoshaType { janana, marana }

/// Severity levels for doshas
enum DoshaSeverity { tivra, madhyama, saumya }

/// A single detected dosha
class DoshaResult {
  final String id;
  final String nameKn;
  final String nameEn;
  final DoshaSeverity severity;
  final String descriptionKn;
  final String descriptionEn;
  final String remedyKn;
  final String remedyEn;
  final Map<String, String> details;
  final DoshaType type;

  const DoshaResult({
    required this.id,
    required this.nameKn,
    required this.nameEn,
    required this.severity,
    required this.descriptionKn,
    required this.descriptionEn,
    required this.remedyKn,
    required this.remedyEn,
    this.details = const {},
    this.type = DoshaType.janana,
  });
}

/// Input data for dosha analysis
class DoshaInput {
  final int nakshatraIndex;    // 0-26 (0=Ashwini, 26=Revati)
  final int pada;              // 1-4
  final double nakPercent;     // fraction of nakshatra elapsed (0.0-1.0)
  final int tithiIndex;        // 0-29
  final double tithiPercent;   // fraction of tithi elapsed (0.0-1.0)
  final int varaIndex;         // 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat
  final int moonRashiIndex;    // 0-11 (0=Mesha, 11=Meena)
  final double moonLongitude;  // sidereal degrees (0-360)
  final int lagnaRashiIndex;   // 0-11
  final double lagnaLongitude; // sidereal degrees (0-360)
  final int yogaIndex;         // 0-26
  final String karanaString;   // raw karana name from PanchangData
  final int sunNakshatraIndex; // 0-26 (for Kala Dosha calculation)

  const DoshaInput({
    required this.nakshatraIndex,
    required this.pada,
    required this.nakPercent,
    required this.tithiIndex,
    this.tithiPercent = 0.5,
    required this.varaIndex,
    required this.moonRashiIndex,
    required this.moonLongitude,
    required this.lagnaRashiIndex,
    this.lagnaLongitude = 0.0,
    required this.yogaIndex,
    this.karanaString = '',
    this.sunNakshatraIndex = 0,
  });
}

/// Panchanga summary for display
class PanchangaSummary {
  final String tithi;
  final String nakshatra;
  final String pada;
  final String vara;
  final String yoga;
  final String karana;
  final String chandraRashi;
  final String lagnaRashi;

  const PanchangaSummary({
    required this.tithi,
    required this.nakshatra,
    required this.pada,
    required this.vara,
    required this.yoga,
    required this.karana,
    required this.chandraRashi,
    required this.lagnaRashi,
  });
}

/// Main analysis — returns all found doshas
List<DoshaResult> analyzeJananaMaranaDosha(DoshaInput input) {
  final doshas = <DoshaResult>[];

  // ── GROUP 1: Gandanta doshas ──
  _checkNakshatraGandanta(input, doshas);
  _checkRevatiAshwiniShanti(input, doshas);
  _checkRashiGandanta(input, doshas);
  _checkLagnaGandanta(input, doshas);
  _checkTithiGandanta(input, doshas);

  // ── GROUP 2: Nakshatra-specific doshas ──
  _checkGandamula(input, doshas);
  _checkAbhuktaMoola(input, doshas);
  _checkMoolaNakshatraPada(input, doshas);
  _checkAshleshasPada(input, doshas);
  _checkJyeshthaSegments(input, doshas);

  // ── GROUP 3: Tithi doshas ──
  _checkKrishnaChaturdashi(input, doshas);
  _checkAmavasya(input, doshas);
  _checkDagdhaTithi(input, doshas);

  // ── GROUP 4: Vara+Nakshatra/Yoga doshas ──
  _checkMrityuYoga(input, doshas);
  _checkInauspiciousYoga(input, doshas);

  // ── GROUP 5: Karana dosha ──
  _checkVishtiKarana(input, doshas);

  // ── GROUP 6: Combined panchanga ──
  _checkTripadaDosha(input, doshas);

  // ── GROUP 7: Marana doshas ──
  _checkPanchakaDosha(input, doshas);
  _checkTripadaNakshatra(input, doshas);
  _checkDwipadaNakshatra(input, doshas);
  _checkTithiDoshaMarana(input, doshas);
  _checkVaraDoshaMarana(input, doshas);
  _checkDwipushkaraYoga(input, doshas);
  _checkTripushkaraYoga(input, doshas);
  _checkKalaDosha(input, doshas);

  return doshas;
}

// ═══════════════════════════════════════════════════════════
// 1. NAKSHATRA GANDANTA (ನಕ್ಷತ್ರ ಗಂಡಾಂತ)
// Last pada of Ashlesha(8)/Jyeshtha(17)/Revati(26) →
// First pada of Magha(9)/Moola(18)/Ashwini(0)
// ═══════════════════════════════════════════════════════════
void _checkNakshatraGandanta(DoshaInput input, List<DoshaResult> doshas) {
  bool isGandanta = false;
  String zone = '';

  if (input.nakshatraIndex == 8 && input.pada == 4) {
    isGandanta = true;
    zone = 'ಆಶ್ಲೇಷ 4ನೇ ಪಾದ';
  } else if (input.nakshatraIndex == 9 && input.pada == 1) {
    isGandanta = true;
    zone = 'ಮಘ 1ನೇ ಪಾದ';
  } else if (input.nakshatraIndex == 17 && input.pada == 4) {
    isGandanta = true;
    zone = 'ಜ್ಯೇಷ್ಠ 4ನೇ ಪಾದ';
  } else if (input.nakshatraIndex == 18 && input.pada == 1) {
    isGandanta = true;
    zone = 'ಮೂಲ 1ನೇ ಪಾದ';
  } else if (input.nakshatraIndex == 26 && input.pada == 4) {
    isGandanta = true;
    zone = 'ರೇವತಿ 4ನೇ ಪಾದ';
  } else if (input.nakshatraIndex == 0 && input.pada == 1) {
    isGandanta = true;
    zone = 'ಅಶ್ವಿನಿ 1ನೇ ಪಾದ';
  }

  if (isGandanta) {
    final isMoola = input.nakshatraIndex == 17 || input.nakshatraIndex == 18;
    doshas.add(DoshaResult(
      id: 'nakshatraGandanta',
      nameKn: 'ನಕ್ಷತ್ರ ಗಂಡಾಂತ ದೋಷ',
      nameEn: 'Nakshatra Gandanta Dosha',
      severity: isMoola ? DoshaSeverity.tivra : DoshaSeverity.madhyama,
      descriptionKn: 'ಆಶ್ಲೇಷ/ಜ್ಯೇಷ್ಠ/ರೇವತಿಯಿಂದ ಮಘ/ಮೂಲ/ಅಶ್ವಿನಿಗೆ ಸಂಧಿ. ಸ್ಥಾನ: $zone.',
      descriptionEn: 'Birth at junction of Ashlesha/Jyeshtha/Revati to Magha/Moola/Ashwini. Zone: $zone.',
      remedyKn: 'ಗಂಡಾಂತ ಶಾಂತಿ ಪೂಜೆ, ಮೃತ್ಯುಂಜಯ ಜಪ, ದಾನ ಮಾಡಬೇಕು.',
      remedyEn: 'Gandanta Shanti Puja, Mrityunjaya Japa, and charitable donations.',
      details: {'zone': zone},
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 2. REVATI/ASHWINI JANANA SHANTI (ರೇವತಿ/ಅಶ್ವಿನಿ ಜನನ-ಶಾಂತಿ)
// Birth in last 2 ghatikas of Revati OR first 2 ghatikas of Ashwini.
// 1 nakshatra = 60 ghatikas, so last/first 2 ghatikas = last/first 3.33%
// ═══════════════════════════════════════════════════════════
void _checkRevatiAshwiniShanti(DoshaInput input, List<DoshaResult> doshas) {
  bool found = false;
  String zone = '';

  // Revati last 2 ghatikas (~last 3.33% = nakPercent > 0.9667)
  if (input.nakshatraIndex == 26 && input.nakPercent > 0.9667) {
    found = true;
    zone = 'ರೇವತಿ ಕೊನೆಯ 2 ಘಟಿಕೆ';
  }
  // Ashwini first 2 ghatikas (~first 3.33% = nakPercent < 0.0333)
  else if (input.nakshatraIndex == 0 && input.nakPercent < 0.0333) {
    found = true;
    zone = 'ಅಶ್ವಿನಿ ಮೊದಲ 2 ಘಟಿಕೆ';
  }

  if (found) {
    doshas.add(DoshaResult(
      id: 'revatiAshwiniShanti',
      nameKn: 'ರೇವತಿ/ಅಶ್ವಿನಿ ಜನನ-ಶಾಂತಿ',
      nameEn: 'Revati/Ashwini Janana-Shanti',
      severity: DoshaSeverity.tivra,
      descriptionKn: 'ರೇವತಿಯ ಕೊನೆಯ 2 ಘಟಿಕೆ, ಅಥವಾ ಅಶ್ವಿನಿಯ ಮೊದಲ 2 ಘಟಿಕೆ. ಸ್ಥಾನ: $zone.',
      descriptionEn: 'Birth in last 2 ghatikas of Revati or first 2 ghatikas of Ashwini. Position: $zone.',
      remedyKn: 'ತಕ್ಷಣ ಜನನ ಶಾಂತಿ ಪೂಜೆ ಮಾಡಬೇಕು. ಗಂಡಾಂತ ಶಾಂತಿ ಅತ್ಯಗತ್ಯ.',
      remedyEn: 'Immediate Janana Shanti Puja required. Gandanta Shanti is essential.',
      details: {'zone': zone},
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 3. RASHI GANDANTA (ರಾಶಿ ಗಂಡಾಂತ)
// Moon at junction of water → fire signs (last/first 3°20')
// ═══════════════════════════════════════════════════════════
void _checkRashiGandanta(DoshaInput input, List<DoshaResult> doshas) {
  final moonDeg = input.moonLongitude % 30.0;
  bool isGandanta = false;
  String zone = '';

  const waterSigns = {3, 7, 11};
  const fireSigns = {0, 4, 8};

  if (waterSigns.contains(input.moonRashiIndex) && moonDeg >= 26.67) {
    isGandanta = true;
    zone = '${knRashi[input.moonRashiIndex]} ಕೊನೆ';
  } else if (fireSigns.contains(input.moonRashiIndex) && moonDeg <= 3.33) {
    isGandanta = true;
    zone = '${knRashi[input.moonRashiIndex]} ಆರಂಭ';
  }

  if (isGandanta) {
    doshas.add(DoshaResult(
      id: 'rashiGandanta',
      nameKn: 'ರಾಶಿ ಗಂಡಾಂತ ದೋಷ',
      nameEn: 'Rashi Gandanta Dosha',
      severity: DoshaSeverity.madhyama,
      descriptionKn: 'ಚಂದ್ರನು ಜಲ-ಅಗ್ನಿ ರಾಶಿ ಸಂಧಿಯ ಸಮೀಪದಲ್ಲಿ. ಸ್ಥಾನ: $zone, ${moonDeg.toStringAsFixed(1)}°.',
      descriptionEn: 'Moon near water-fire sign junction. Position: $zone, ${moonDeg.toStringAsFixed(1)}°.',
      remedyKn: 'ರಾಶಿ ಗಂಡಾಂತ ಶಾಂತಿ, ಚಂದ್ರ ಗ್ರಹ ಶಾಂತಿ ಮಾಡಬೇಕು.',
      remedyEn: 'Rashi Gandanta Shanti and Chandra Graha Shanti recommended.',
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 4. LAGNA GANDANTA (ಲಗ್ನ ಗಂಡಾಂತ)
// Lagna at junction of water → fire signs (last/first 3°20')
// ═══════════════════════════════════════════════════════════
void _checkLagnaGandanta(DoshaInput input, List<DoshaResult> doshas) {
  final lagnaDeg = input.lagnaLongitude % 30.0;
  bool isGandanta = false;
  String zone = '';

  const waterSigns = {3, 7, 11};
  const fireSigns = {0, 4, 8};

  if (waterSigns.contains(input.lagnaRashiIndex) && lagnaDeg >= 26.67) {
    isGandanta = true;
    zone = '${knRashi[input.lagnaRashiIndex]} ಕೊನೆ';
  } else if (fireSigns.contains(input.lagnaRashiIndex) && lagnaDeg <= 3.33) {
    isGandanta = true;
    zone = '${knRashi[input.lagnaRashiIndex]} ಆರಂಭ';
  }

  if (isGandanta) {
    doshas.add(DoshaResult(
      id: 'lagnaGandanta',
      nameKn: 'ಲಗ್ನ ಗಂಡಾಂತ ದೋಷ',
      nameEn: 'Lagna Gandanta Dosha',
      severity: DoshaSeverity.madhyama,
      descriptionKn: 'ಲಗ್ನವು ಜಲ-ಅಗ್ನಿ ರಾಶಿ ಸಂಧಿಯ ಸಮೀಪದಲ್ಲಿ. ಸ್ಥಾನ: $zone, ${lagnaDeg.toStringAsFixed(1)}°.',
      descriptionEn: 'Lagna near water-fire sign junction. Position: $zone, ${lagnaDeg.toStringAsFixed(1)}°.',
      remedyKn: 'ಲಗ್ನ ಗಂಡಾಂತ ಶಾಂತಿ, ಲಗ್ನ ಅಧಿಪತಿ ಗ್ರಹ ಶಾಂತಿ ಮಾಡಬೇಕು.',
      remedyEn: 'Lagna Gandanta Shanti and Lagna lord Graha Shanti recommended.',
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 5. TITHI GANDANTA (ತಿಥಿ ಗಂಡಾಂತ)
// Junction tithis: Purnima→K.Padyami, Amavasya→S.Padyami,
// Shukla/Krishna Panchami→Shashthi
// ═══════════════════════════════════════════════════════════
void _checkTithiGandanta(DoshaInput input, List<DoshaResult> doshas) {
  const gandantaTithis = {0, 5, 14, 15, 19, 20, 29};

  if (gandantaTithis.contains(input.tithiIndex)) {
    final tithiName = knTithi[input.tithiIndex];
    doshas.add(DoshaResult(
      id: 'tithiGandanta',
      nameKn: 'ತಿಥಿ ಗಂಡಾಂತ ದೋಷ',
      nameEn: 'Tithi Gandanta Dosha',
      severity: DoshaSeverity.saumya,
      descriptionKn: 'ಪೂರ್ಣ ತಿಥಿಯಿಂದ ನಂತರದ ನಂದಾ ತಿಥಿಗೆ ಸಂಧಿ. ಜನ್ಮ ತಿಥಿ: $tithiName.',
      descriptionEn: 'Birth at tithi junction (Purnima/Amavasya/Panchami changeover). Birth tithi: $tithiName.',
      remedyKn: 'ತಿಥಿ ಶಾಂತಿ ಪೂಜೆ, ತಿಥಿ ಅಧಿದೇವತೆಗೆ ಪ್ರಾರ್ಥನೆ.',
      remedyEn: 'Tithi Shanti Puja and prayer to tithi deity.',
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 6. GANDAMULA DOSHA (ಗಂಡಮೂಲ ದೋಷ)
// Moon in any of 6 gandamula nakshatras:
// Ashwini(0), Ashlesha(8), Magha(9), Jyeshtha(17), Moola(18), Revati(26)
// ═══════════════════════════════════════════════════════════
void _checkGandamula(DoshaInput input, List<DoshaResult> doshas) {
  const moolaNaks = {0, 8, 9, 17, 18, 26};

  if (moolaNaks.contains(input.nakshatraIndex)) {
    final nakName = knNak[input.nakshatraIndex];
    final isSevere = input.nakshatraIndex == 17 || input.nakshatraIndex == 18;
    doshas.add(DoshaResult(
      id: 'gandamula',
      nameKn: 'ಗಂಡಮೂಲ ದೋಷ',
      nameEn: 'Gandamula Dosha',
      severity: isSevere ? DoshaSeverity.tivra : DoshaSeverity.madhyama,
      descriptionKn: 'ಚಂದ್ರನು ಆರು ಗಂಡಮೂಲ ನಕ್ಷತ್ರಗಳಲ್ಲಿ ಒಂದರಲ್ಲಿದ್ದಾನೆ. ಜನ್ಮ ನಕ್ಷತ್ರ: $nakName.',
      descriptionEn: 'Moon is in one of 6 gandamula nakshatras. Birth star: $nakName.',
      remedyKn: 'ಗಂಡಮೂಲ ಶಾಂತಿ ಪೂಜೆ, 27ನೇ ದಿನ ನಕ್ಷತ್ರ ಶಾಂತಿ ಮಾಡಬೇಕು.',
      remedyEn: 'Gandamula Shanti Puja; nakshatra shanti on 27th day.',
      details: {'nakshatra': nakName},
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 7. ABHUKTA MOOLA (ಅಭುಕ್ತ ಮೂಲ)
// Last quarter of Jyeshtha, first part of Moola
// Most specific version: exact junction zone
// ═══════════════════════════════════════════════════════════
void _checkAbhuktaMoola(DoshaInput input, List<DoshaResult> doshas) {
  // Jyeshtha last pada (4) — Abhukta Moola starts
  // Moola first pada (1) — most dangerous zone
  bool found = false;
  String desc = '';

  if (input.nakshatraIndex == 17 && input.pada == 4) {
    found = true;
    desc = 'ಜ್ಯೇಷ್ಠಾ ಕೊನೆಯ ಪಾದ, ಮೂಲಕ್ಕಿಂತ ಸ್ಲ್ಪ ಮೊದಲು';
  } else if (input.nakshatraIndex == 18 && input.pada == 1) {
    found = true;
    desc = 'ಮೂಲ ಮೊದಲ ಪಾದ — ಅತ್ಯಂತ ತೀವ್ರ';
  }

  if (found) {
    doshas.add(DoshaResult(
      id: 'abhuktaMoola',
      nameKn: 'ಅಭುಕ್ತ ಮೂಲ ದೋಷ',
      nameEn: 'Abhukta Moola Dosha',
      severity: (input.nakshatraIndex == 18 && input.pada == 1)
          ? DoshaSeverity.tivra
          : DoshaSeverity.madhyama,
      descriptionKn: 'ಜ್ಯೇಷ್ಠಾ ಕೊನೆಯ ಪಾದ-ಮೂಲಕ್ಕಿಂತ ಸ್ಲ್ಪ ಮೊದಲು ಸ್ಥಾನ. $desc.',
      descriptionEn: 'Birth in Abhukta Moola zone (Jyeshtha 4th pada to Moola 1st pada). $desc.',
      remedyKn: 'ಮೂಲ ನಕ್ಷತ್ರ ಶಾಂತಿ ಪೂಜೆ ಅತ್ಯಗತ್ಯ. ತಂದೆಗೆ 27 ದಿನ ಮಗುವನ್ನು ತೋರಿಸಬೇಡಿ.',
      remedyEn: 'Moola Nakshatra Shanti Puja essential. Avoid showing child to father for 27 days.',
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 8. MOOLA NAKSHATRA PADA EFFECTS (ಮೂಲ ನಕ್ಷತ್ರ ಪಾದದ ಪ್ರಕಾರ)
// Moon in Moola(18) — pada-specific effects:
//   Pada 1: danger to father (ಅತ್ಯಂತ ತೀವ್ರ)
//   Pada 2: danger to mother (ತೀವ್ರ)
//   Pada 3: loss of wealth (ಮಧ್ಯಮ)
//   Pada 4: auspicious (ಶುಭ — no dosha)
// ═══════════════════════════════════════════════════════════
void _checkMoolaNakshatraPada(DoshaInput input, List<DoshaResult> doshas) {
  if (input.nakshatraIndex != 18) return;

  const padaDescKn = <int, String>{
    1: 'ತಂದೆಗೆ ಅಪಾಯ ಸೂಚಕ',
    2: 'ತಾಯಿಗೆ ಅಪಾಯ ಸೂಚಕ',
    3: 'ಧನ ಹಾನಿ ಸೂಚಕ',
  };
  const padaDescEn = <int, String>{
    1: 'Indicates danger to father',
    2: 'Indicates danger to mother',
    3: 'Indicates loss of wealth',
  };
  const padaSeverity = <int, DoshaSeverity>{
    1: DoshaSeverity.tivra,
    2: DoshaSeverity.tivra,
    3: DoshaSeverity.madhyama,
  };

  if (!padaDescKn.containsKey(input.pada)) return; // Pada 4 is auspicious

  doshas.add(DoshaResult(
    id: 'moolaPada',
    nameKn: 'ಮೂಲ ನಕ್ಷತ್ರ, ಪಾದದ ಪ್ರಕಾರ',
    nameEn: 'Moola Nakshatra Pada Effect',
    severity: padaSeverity[input.pada]!,
    descriptionKn: 'ಚಂದ್ರನು ಮೂಲದಲ್ಲಿದ್ದಾನೆ; ಗುರಿ ಪಾದ ${input.pada} ಮೇಲೆ ಅವಲಂಬಿತ. ${padaDescKn[input.pada]}.',
    descriptionEn: 'Moon in Moola; effect depends on pada. Pada ${input.pada}: ${padaDescEn[input.pada]}.',
    remedyKn: 'ಮೂಲ ಶಾಂತಿ, ಕೇತು ಗ್ರಹ ಶಾಂತಿ, ಮೃತ್ಯುಂಜಯ ಜಪ 11,000 ಬಾರಿ ಮಾಡಬೇಕು.',
    remedyEn: 'Moola Shanti, Ketu Graha Shanti, Mrityunjaya Japa 11,000 times.',
    details: {'pada': '${input.pada}', 'effect': padaDescEn[input.pada] ?? ''},
  ));
}

// ═══════════════════════════════════════════════════════════
// 9. ASHLESHA NAKSHATRA PADA EFFECTS (ಆಶ್ಲೇಷಾ ನಕ್ಷತ್ರ ಪಾದದ ಪ್ರಕಾರ)
// Moon in Ashlesha(8) — pada-specific effects:
//   Pada 1: danger to mother-in-law
//   Pada 2: danger to father
//   Pada 3: danger to mother
//   Pada 4: less severe (still noted)
// ═══════════════════════════════════════════════════════════
void _checkAshleshasPada(DoshaInput input, List<DoshaResult> doshas) {
  if (input.nakshatraIndex != 8) return;

  const padaDescKn = <int, String>{
    1: 'ಅತ್ತೆ/ಮಾವನಿಗೆ ಅಪಾಯ ಸೂಚಕ',
    2: 'ತಂದೆಗೆ ಅಪಾಯ ಸೂಚಕ',
    3: 'ತಾಯಿಗೆ ಅಪಾಯ ಸೂಚಕ',
    4: 'ಸ್ವಂತಕ್ಕೆ ಕಷ್ಟ',
  };
  const padaDescEn = <int, String>{
    1: 'Indicates danger to in-laws',
    2: 'Indicates danger to father',
    3: 'Indicates danger to mother',
    4: 'Self difficulties',
  };

  doshas.add(DoshaResult(
    id: 'ashleshasPada',
    nameKn: 'ಆಶ್ಲೇಷಾ ನಕ್ಷತ್ರ, ಪಾದದ ಪ್ರಕಾರ',
    nameEn: 'Ashlesha Nakshatra Pada Effect',
    severity: input.pada <= 3 ? DoshaSeverity.madhyama : DoshaSeverity.saumya,
    descriptionKn: 'ಚಂದ್ರನು ಆಶ್ಲೇಷದಲ್ಲಿದ್ದಾನೆ; ಗುರಿ ಪಾದ ${input.pada} ಮೇಲೆ ಅವಲಂಬಿತ. ${padaDescKn[input.pada]}.',
    descriptionEn: 'Moon in Ashlesha; effect depends on pada. Pada ${input.pada}: ${padaDescEn[input.pada]}.',
    remedyKn: 'ಆಶ್ಲೇಷ ಶಾಂತಿ, ಸರ್ಪ ದೋಷ ನಿವಾರಣ ಪೂಜೆ, ರಾಹು-ಕೇತು ಶಾಂತಿ ಮಾಡಬೇಕು.',
    remedyEn: 'Ashlesha Shanti, Sarpa Dosha Nivarana Puja, and Rahu-Ketu Shanti.',
    details: {'pada': '${input.pada}', 'effect': padaDescEn[input.pada] ?? ''},
  ));
}

// ═══════════════════════════════════════════════════════════
// 10. JYESHTHA NAKSHATRA 10 SEGMENTS (ಜ್ಯೇಷ್ಠಾ ನಕ್ಷತ್ರ 10 ಭಾಗಗಳು)
// Jyeshtha(17) divided into 10 equal parts.
// Each part has different classical effects.
// ═══════════════════════════════════════════════════════════
void _checkJyeshthaSegments(DoshaInput input, List<DoshaResult> doshas) {
  if (input.nakshatraIndex != 17) return;

  final segment = (input.nakPercent * 10).floor().clamp(0, 9) + 1; // 1-10

  // Classical effects per segment (from Hora Sara / traditional texts)
  const segDescKn = <int, String>{
    1:  'ಹಿರಿಯ ಸಹೋದರ/ಅಕ್ಕನಿಗೆ ಅಪಾಯ',
    2:  'ತಂದೆ ಕಡೆ ಕಷ್ಟ',
    3:  'ತಾಯಿ ಕಡೆ ಕಷ್ಟ',
    4:  'ಧನ ಹಾನಿ',
    5:  'ತ್ರಾಸ ಮತ್ತು ಅಶಾಂತಿ',
    6:  'ಉತ್ತಮ — ಶುಭ ಭಾಗ',
    7:  'ಶತ್ರು ಭಯ',
    8:  'ರೋಗ ಭಯ',
    9:  'ಧನ ಸಂಪತ್ತು — ಶುಭ ಭಾಗ',
    10: 'ಅಕ್ಕ-ತಂಗಿಗೆ ಅಪಾಯ',
  };
  const segDescEn = <int, String>{
    1:  'Danger to elder sibling',
    2:  'Difficulties from paternal side',
    3:  'Difficulties from maternal side',
    4:  'Financial loss',
    5:  'Trouble and unrest',
    6:  'Auspicious segment',
    7:  'Fear of enemies',
    8:  'Fear of illness',
    9:  'Wealth and prosperity — auspicious',
    10: 'Danger to sisters',
  };

  final isAuspicious = segment == 6 || segment == 9;
  if (isAuspicious) return; // Don't flag auspicious segments

  doshas.add(DoshaResult(
    id: 'jyeshthaSegment',
    nameKn: 'ಜ್ಯೇಷ್ಠಾ ನಕ್ಷತ್ರ (10 ಭಾಗಗಳು)',
    nameEn: 'Jyeshtha Nakshatra (10 Segments)',
    severity: segment <= 5 ? DoshaSeverity.madhyama : DoshaSeverity.saumya,
    descriptionKn: 'ಜ್ಯೇಷ್ಠಾ, 10 ಭಾಗಗಳಾಗಿ ವಿಂಗಡಿಸಲಾಗಿದೆ. ಭಾಗ $segment: ${segDescKn[segment]}.',
    descriptionEn: 'Jyeshtha divided into 10 segments. Segment $segment: ${segDescEn[segment]}.',
    remedyKn: 'ಜ್ಯೇಷ್ಠ ನಕ್ಷತ್ರ ಶಾಂತಿ, ಇಂದ್ರ ಪೂಜೆ, ನಕ್ಷತ್ರ ಅಧಿದೇವತೆ ಅರ್ಚನೆ ಮಾಡಬೇಕು.',
    remedyEn: 'Jyeshtha Nakshatra Shanti, Indra Puja, and nakshatra deity worship.',
    details: {'segment': '$segment', 'effect': segDescEn[segment] ?? ''},
  ));
}

// ═══════════════════════════════════════════════════════════
// 11. KRISHNA CHATURDASHI DOSHA (ಕೃಷ್ಣ ಚತುರ್ದಶಿ ದೋಷ)
// Birth on Krishna Chaturdashi (tithiIndex=28), especially
// in first 6 of 8 bhagas (first 75% of the tithi)
// ═══════════════════════════════════════════════════════════
void _checkKrishnaChaturdashi(DoshaInput input, List<DoshaResult> doshas) {
  if (input.tithiIndex != 28) return;

  // 6 bhagas = 6/8 = 75% of tithi
  final inSixBhagas = input.tithiPercent < 0.75;
  doshas.add(DoshaResult(
    id: 'krishnaChaturdashi',
    nameKn: 'ಕೃಷ್ಣ ಚತುರ್ದಶಿ ದೋಷ',
    nameEn: 'Krishna Chaturdashi Dosha',
    severity: inSixBhagas ? DoshaSeverity.tivra : DoshaSeverity.madhyama,
    descriptionKn: 'ಕೃಷ್ಣ ಪಕ್ಷ ಚತುರ್ದಶಿ, 6 ಭಾಗಗಳಾಗಿ ವಿಂಗಡಿಸಲಾಗಿದೆ.${inSixBhagas ? " ಮೊದಲ 6 ಭಾಗಗಳಲ್ಲಿ ಜನನ — ತೀವ್ರ." : " ಕೊನೆ 2 ಭಾಗ."}',
    descriptionEn: 'Birth on Krishna Chaturdashi.${inSixBhagas ? " Born in first 6 of 8 bhagas — more severe." : " Born in last 2 bhagas."}',
    remedyKn: 'ಕೃಷ್ಣ ಚತುರ್ದಶಿ ಶಾಂತಿ, ಶಿವ ಅಭಿಷೇಕ, ಮೃತ್ಯುಂಜಯ ಜಪ ಮಾಡಬೇಕು.',
    remedyEn: 'Krishna Chaturdashi Shanti, Shiva Abhisheka, and Mrityunjaya Japa.',
  ));
}

// ═══════════════════════════════════════════════════════════
// 12. AMAVASYA VARIANTS (ಅಮಾವಾಸ್ಯೆ ಉಪಪ್ರಕಾರ)
// Sinivali: Birth just before Amavasya (K.Chaturdashi late)
// Darsha/Kuhu: Birth on Amavasya itself
// ═══════════════════════════════════════════════════════════
void _checkAmavasya(DoshaInput input, List<DoshaResult> doshas) {
  if (input.tithiIndex == 29) {
    // Amavasya — Darsha or Kuhu
    doshas.add(DoshaResult(
      id: 'amavasya',
      nameKn: 'ಅಮಾವಾಸ್ಯೆ ಉಪಪ್ರಕಾರ (ದರ್ಶ/ಕುಹೂ)',
      nameEn: 'Amavasya Variant (Darsha/Kuhu)',
      severity: DoshaSeverity.tivra,
      descriptionKn: 'ಅಮಾವಾಸ್ಯೆ ದಿನ ಜನನ. ದರ್ಶ ಅಥವಾ ಕುಹೂ, ಅಮಾವಾಸ್ಯೆ ಎಂಟನೇ ಭಾಗದ ಪ್ರಕಾರ.',
      descriptionEn: 'Birth on Amavasya (New Moon). Darsha or Kuhu variant based on Amavasya bhaga.',
      remedyKn: 'ಅಮಾವಾಸ್ಯೆ ಶಾಂತಿ, ಪಿತೃ ಪೂಜೆ, ತರ್ಪಣ, ನವಗ್ರಹ ಶಾಂತಿ ಮಾಡಬೇಕು.',
      remedyEn: 'Amavasya Shanti, Pitru Puja, Tarpana, and Navagraha Shanti.',
    ));
  } else if (input.tithiIndex == 28 && input.tithiPercent > 0.875) {
    // Sinivali: Moon near end of Chaturdashi approaching Amavasya
    doshas.add(DoshaResult(
      id: 'sinivali',
      nameKn: 'ಸಿನೀವಾಲಿ (ಅಮಾವಾಸ್ಯೆ ಉಪಪ್ರಕಾರ)',
      nameEn: 'Sinivali (Amavasya Variant)',
      severity: DoshaSeverity.madhyama,
      descriptionKn: 'ಸಿನೀವಾಲಿ — ಕೃಷ್ಣ ಪಕ್ಷ ಚತುರ್ದಶಿ ಕೊನೆಯ ಭಾಗ, ಅಮಾವಾಸ್ಯೆ ಎಂಟನೇ ಭಾಗದ ಪ್ರಕಾರ.',
      descriptionEn: 'Sinivali — birth near end of Krishna Chaturdashi approaching Amavasya.',
      remedyKn: 'ಅಮಾವಾಸ್ಯೆ ಶಾಂತಿ, ಚಂದ್ರ ಗ್ರಹ ಶಾಂತಿ ಮಾಡಬೇಕು.',
      remedyEn: 'Amavasya Shanti and Chandra Graha Shanti recommended.',
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 13. DAGDHA TITHI (ದಗ್ಧ ತಿಥಿ — Burned Tithi)
// Vara+Tithi combinations:
//   Sun:Dvadashi(11), Mon:Ekadashi(10), Tue:Panchami(4),
//   Wed:Tritiya(2), Thu:Shashthi(5), Fri:Ashtami(7), Sat:Navami(8)
// ═══════════════════════════════════════════════════════════
void _checkDagdhaTithi(DoshaInput input, List<DoshaResult> doshas) {
  final baseTithi = input.tithiIndex % 15;

  const dagdhaMap = <int, int>{
    0: 11, 1: 10, 2: 4, 3: 2, 4: 5, 5: 7, 6: 8,
  };

  if (dagdhaMap[input.varaIndex] == baseTithi) {
    doshas.add(DoshaResult(
      id: 'dagdhaTithi',
      nameKn: 'ದಗ್ಧ ತಿಥಿ ದೋಷ',
      nameEn: 'Dagdha Tithi Dosha (Burned Tithi)',
      severity: DoshaSeverity.madhyama,
      descriptionKn: 'ವಾರ-ತಿಥಿ ಸಂಯೋಗ ದಗ್ಧವಾಗಿದೆ. ${knVara[input.varaIndex]} + ${knTithi[input.tithiIndex]} = ದಗ್ಧ.',
      descriptionEn: 'Vara-Tithi combination is burned (dagdha). ${knVara[input.varaIndex]} + ${knTithi[input.tithiIndex]}.',
      remedyKn: 'ದಗ್ಧ ತಿಥಿ ಶಾಂತಿ, ಸೂರ್ಯ ನಮಸ್ಕಾರ, ಹೋಮ ಮಾಡಬೇಕು.',
      remedyEn: 'Dagdha Tithi Shanti, Surya Namaskara, and Homa.',
      details: {'vara': knVara[input.varaIndex], 'tithi': knTithi[input.tithiIndex]},
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 14. MRITYU YOGA (ಮೃತ್ಯು ಯೋಗ — Vara + Nakshatra)
// From Muhurta Chintamani:
//   Sun:Anuradha(16), Mon:Uttarashadha(20), Tue:Satabhisha(23),
//   Wed:Dhanishta(22), Thu:Mrigashira(4), Fri:Ashlesha(8), Sat:Rohini(3)
// ═══════════════════════════════════════════════════════════
void _checkMrityuYoga(DoshaInput input, List<DoshaResult> doshas) {
  const mrityuMap = <int, int>{
    0: 16, 1: 20, 2: 23, 3: 22, 4: 4, 5: 8, 6: 3,
  };

  if (mrityuMap[input.varaIndex] == input.nakshatraIndex) {
    doshas.add(DoshaResult(
      id: 'mrityuYoga',
      nameKn: 'ಮೃತ್ಯು ಯೋಗ ದೋಷ',
      nameEn: 'Mrityu Yoga Dosha',
      severity: DoshaSeverity.tivra,
      descriptionKn: '${knVara[input.varaIndex]} + ${knNak[input.nakshatraIndex]} = ಮೃತ್ಯು ಯೋಗ.',
      descriptionEn: '${knVara[input.varaIndex]} + ${knNak[input.nakshatraIndex]} forms Mrityu Yoga.',
      remedyKn: 'ಮೃತ್ಯುಂಜಯ ಜಪ 1,25,000, ರುದ್ರಾಭಿಷೇಕ, ನವಗ್ರಹ ಶಾಂತಿ ಮಾಡಬೇಕು.',
      remedyEn: 'Mrityunjaya Japa 1,25,000 times, Rudrabhisheka, Navagraha Shanti.',
      details: {'vara': knVara[input.varaIndex], 'nakshatra': knNak[input.nakshatraIndex]},
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 15. INAUSPICIOUS YOGA (ವೈಧೃತಿ / ವ್ಯತೀಪಾತ ಯೋಗ)
// Vishkambha(0), Vaidhrti(26) — most severe
// Vyatipata(16), Parigha(18), Vajra(14), Shoola(8), Ganda(9)
// ═══════════════════════════════════════════════════════════
void _checkInauspiciousYoga(DoshaInput input, List<DoshaResult> doshas) {
  const badYogas = <int, DoshaSeverity>{
    0:  DoshaSeverity.tivra,     // Vishkambha
    26: DoshaSeverity.tivra,     // Vaidhrti
    16: DoshaSeverity.madhyama,  // Vyatipata
    18: DoshaSeverity.saumya,    // Parigha
    14: DoshaSeverity.saumya,    // Vajra
    8:  DoshaSeverity.saumya,    // Shoola
    9:  DoshaSeverity.saumya,    // Ganda
  };

  if (badYogas.containsKey(input.yogaIndex)) {
    final yogaName = knYoga[input.yogaIndex];
    final severity = badYogas[input.yogaIndex]!;
    doshas.add(DoshaResult(
      id: 'inauspiciousYoga',
      nameKn: 'ವೈಧೃತಿ/ವ್ಯತೀಪಾತ ಯೋಗ ದೋಷ',
      nameEn: 'Vaidhrti/Vyatipata Yoga Dosha',
      severity: severity,
      descriptionKn: 'ಜನ ಯೋಗವು ಅಶುಭ. ಜನ್ಮ ಯೋಗ: $yogaName.',
      descriptionEn: 'Birth yoga is inauspicious. Birth yoga: $yogaName.',
      remedyKn: 'ಯೋಗ ಶಾಂತಿ ಪೂಜೆ, ನವಗ್ರಹ ಹೋಮ ಮಾಡಬೇಕು.',
      remedyEn: 'Yoga Shanti Puja and Navagraha Homa.',
      details: {'yoga': yogaName},
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 16. VISHTI (BHADRA) KARANA (ವಿಷ್ಟಿ ಭದ್ರಾ ಕರಣ)
// Birth when karana is Vishti/Bhadra
// In calculator.dart: kArr[6] = 'ಭದ್ರಾ (ವಿಷ್ಟಿ)'
// ═══════════════════════════════════════════════════════════
void _checkVishtiKarana(DoshaInput input, List<DoshaResult> doshas) {
  final k = input.karanaString.toLowerCase();
  if (k.contains('ಭದ್ರ') || k.contains('ವಿಷ್ಟಿ') || k.contains('bhadra') || k.contains('vishti')) {
    doshas.add(DoshaResult(
      id: 'vishtiKarana',
      nameKn: 'ವಿಷ್ಟಿ (ಭದ್ರಾ) ಕರಣ ದೋಷ',
      nameEn: 'Vishti (Bhadra) Karana Dosha',
      severity: DoshaSeverity.madhyama,
      descriptionKn: 'ಜನನ ಕರಣವು ವಿಷ್ಟಿಯಾಗಿದೆ. ವಿಷ್ಟಿ/ಭದ್ರಾ ಕರಣ ಅಶುಭ ಕಾಲ.',
      descriptionEn: 'Birth karana is Vishti (Bhadra) — considered an inauspicious period.',
      remedyKn: 'ವಿಷ್ಟಿ ಕರಣ ಶಾಂತಿ, ರಾಹು ಗ್ರಹ ಶಾಂತಿ, ಶ್ರೀ ಸೂಕ್ತ ಪಾರಾಯಣ ಮಾಡಬೇಕು.',
      remedyEn: 'Vishti Karana Shanti, Rahu Graha Shanti, and Sri Sukta recitation.',
      details: {'karana': input.karanaString},
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 17. TRIPADA DOSHA (ತ್ರಿಪದ ದೋಷ)
// Counts inauspicious Tithi + Nakshatra + Vara at birth
// ═══════════════════════════════════════════════════════════
void _checkTripadaDosha(DoshaInput input, List<DoshaResult> doshas) {
  const badTithiBase = {0, 1, 5, 7, 10, 11, 12, 13};
  final baseTithi = input.tithiIndex % 15;
  final isBadTithi = badTithiBase.contains(baseTithi) || input.tithiIndex == 29;

  const badNak = {3, 4, 6, 9, 11, 13, 15, 20, 22, 23, 24, 26};
  final isBadNak = badNak.contains(input.nakshatraIndex);

  const badVara = {0, 2, 5, 6};
  final isBadVara = badVara.contains(input.varaIndex);

  int count = 0;
  final badElements = <String>[];

  if (isBadTithi) { count++; badElements.add(knTithi[input.tithiIndex]); }
  if (isBadNak)   { count++; badElements.add(knNak[input.nakshatraIndex]); }
  if (isBadVara)  { count++; badElements.add(knVara[input.varaIndex]); }

  if (count >= 2) { // Only flag if 2 or more are inauspicious
    String typeKn, typeEn;
    DoshaSeverity severity;
    if (count == 3) {
      typeKn = 'ತ್ರಿಪದ ದೋಷ (ಮೂರೂ ಅಶುಭ)';
      typeEn = 'Tripada Dosha (all 3 inauspicious)';
      severity = DoshaSeverity.tivra;
    } else {
      typeKn = 'ದ್ವಿಪದ ದೋಷ (ಎರಡು ಅಶುಭ)';
      typeEn = 'Dwipada Dosha (2 inauspicious)';
      severity = DoshaSeverity.madhyama;
    }

    doshas.add(DoshaResult(
      id: 'tripadaDosha',
      nameKn: typeKn,
      nameEn: typeEn,
      severity: severity,
      descriptionKn: '$count ಅಂಶ(ಗಳು) ಅಶುಭ: ${badElements.join(", ")}.',
      descriptionEn: '$count panchanga element(s) are inauspicious: ${badElements.join(", ")}.',
      remedyKn: count == 3
          ? 'ತ್ರಿಪದ ದೋಷ ಶಾಂತಿ, ನವಗ್ರಹ ಹೋಮ, ಗೋದಾನ, ಮೃತ್ಯುಂಜಯ ಜಪ ಅವಶ್ಯ.'
          : 'ದೋಷ ಶಾಂತಿ ಪೂಜೆ, ಸಂಬಂಧಿಸಿದ ಗ್ರಹ ಶಾಂತಿ ಮಾಡಬೇಕು.',
      remedyEn: count == 3
          ? 'Tripada Dosha Shanti, Navagraha Homa, Godana, and Mrityunjaya Japa required.'
          : 'Dosha Shanti Puja and related Graha Shanti recommended.',
      details: {'count': '$count', 'elements': badElements.join(', ')},
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// MARANA DOSHAS
// ═══════════════════════════════════════════════════════════

// ── M1. PANCHAKA DOSHA (ಧನಿಷ್ಠಾದಿ ಪಂಚಕ ದೋಷ)
// Moon in 5 nakshatras: Dhanishtha(22) 2nd half,
// Satabhisha(23), Purvabhadra(24), Uttarabhadra(25), Revati(26)
// ─────────────────────────────────────────────────────────
void _checkPanchakaDosha(DoshaInput input, List<DoshaResult> doshas) {
  bool found = false;
  String nakName = '';

  // Dhanishtha 2nd half: padas 3-4
  if (input.nakshatraIndex == 22 && input.pada >= 3) {
    found = true;
    nakName = '${knNak[22]} (3-4 ಪಾದ)';
  } else if (input.nakshatraIndex >= 23 && input.nakshatraIndex <= 26) {
    found = true;
    nakName = knNak[input.nakshatraIndex];
  }

  if (found) {
    // Severity based on nakshatra within Panchaka
    final severity = input.nakshatraIndex == 23   // Satabhisha: Roga Panchaka
        ? DoshaSeverity.tivra
        : input.nakshatraIndex == 24              // Purvabhadra: Agni Panchaka
            ? DoshaSeverity.tivra
            : DoshaSeverity.madhyama;

    doshas.add(DoshaResult(
      id: 'panchakaDosha',
      nameKn: 'ಧನಿಷ್ಠಾದಿ ಪಂಚಕ ದೋಷ',
      nameEn: 'Dhanishthadi Panchaka Dosha',
      severity: severity,
      descriptionKn: 'ಧನಿಷ್ಠಾದ ಉತ್ತರಾರ್ಧದಿಂದ ರೇವತಿಯ ಅಂತ್ಯದವರೆಗೆ. ಜನ್ಮ ನಕ್ಷತ್ರ: $nakName.',
      descriptionEn: 'Moon in Panchaka zone (Dhanishtha 2nd half to end of Revati). Star: $nakName.',
      remedyKn: 'ಪಂಚಕ ಶಾಂತಿ ಪೂಜೆ, ಪಂಚಕ ನಕ್ಷತ್ರ ಅಧಿದೇವತೆ ಅರ್ಚನೆ ಮಾಡಬೇಕು.',
      remedyEn: 'Panchaka Shanti Puja and worship of Panchaka nakshatra deities.',
      details: {'nakshatra': nakName},
      type: DoshaType.marana,
    ));
  }
}

// ── M2. TRIPADA NAKSHATRA DOSHA (ತ್ರಿಪಾದ ನಕ್ಷತ್ರ ದೋಷ)
// Moon in a Tripada nakshatra AND on the 3-pada side
// Tripada nakshatras (3 padas in one sign, 1 in the next):
//   Kritika(2): padas 2-4 in Taurus (3-pada side)
//   Punarvasu(6): padas 1-3 in Gemini (3-pada side)
//   Uttara Phalguni(11): padas 2-4 in Virgo (3-pada side)
//   Vishakha(15): padas 1-3 in Libra (3-pada side)
//   Uttarashadha(20): padas 2-4 in Capricorn (3-pada side)
//   Purva Bhadrapada(24): padas 1-3 in Aquarius (3-pada side)
// ─────────────────────────────────────────────────────────
void _checkTripadaNakshatra(DoshaInput input, List<DoshaResult> doshas) {
  // Map: nakshatra index → list of padas that are the "3-pada side"
  const tripadaMap = <int, List<int>>{
    2:  [2, 3, 4],  // Kritika: 3 padas in Taurus
    6:  [1, 2, 3],  // Punarvasu: 3 padas in Gemini
    11: [2, 3, 4],  // Uttara Phalguni: 3 padas in Virgo
    15: [1, 2, 3],  // Vishakha: 3 padas in Libra
    20: [2, 3, 4],  // Uttarashadha: 3 padas in Capricorn
    24: [1, 2, 3],  // Purva Bhadrapada: 3 padas in Aquarius
  };

  if (!tripadaMap.containsKey(input.nakshatraIndex)) return;
  if (!tripadaMap[input.nakshatraIndex]!.contains(input.pada)) return;

  final nakName = knNak[input.nakshatraIndex];
  doshas.add(DoshaResult(
    id: 'tripadaNakshatra',
    nameKn: 'ತ್ರಿಪಾದ ನಕ್ಷತ್ರ ದೋಷ',
    nameEn: 'Tripada Nakshatra Dosha',
    severity: DoshaSeverity.madhyama,
    descriptionKn: 'ಚಂದ್ರನ ಪಾದವು ತ್ರಿಪಾದ ನಕ್ಷತ್ರ $nakName ದ 3-ಪಾದದ ಬದಿಯಲ್ಲಿದೆ. ಪಾದ ${input.pada}.',
    descriptionEn: 'Moon\'s pada is on the 3-pada side of Tripada nakshatra $nakName. Pada ${input.pada}.',
    remedyKn: 'ತ್ರಿಪಾದ ನಕ್ಷತ್ರ ಶಾಂತಿ, ನಕ್ಷತ್ರ ಅಧಿದೇವತೆ ಅರ್ಚನೆ ಮಾಡಬೇಕು.',
    remedyEn: 'Tripada Nakshatra Shanti and worship of nakshatra deity.',
    details: {'nakshatra': nakName, 'pada': '${input.pada}'},
      type: DoshaType.marana,
    ));
}

// ── M3. DWIPADA NAKSHATRA (ದ್ವಿಪಾದ ನಕ್ಷತ್ರ)
// Moon in nakshatras split equally 2-2 across rashi boundary:
//   Mrigashira(4): 2 padas in Taurus, 2 in Gemini
//   Chitra(13): 2 padas in Virgo, 2 in Libra
//   Dhanishtha(22): 2 padas in Capricorn, 2 in Aquarius
// ─────────────────────────────────────────────────────────
void _checkDwipadaNakshatra(DoshaInput input, List<DoshaResult> doshas) {
  const dwipadaNaks = {4, 13, 22};

  if (!dwipadaNaks.contains(input.nakshatraIndex)) return;

  final nakName = knNak[input.nakshatraIndex];
  doshas.add(DoshaResult(
    id: 'dwipadaNakshatra',
    nameKn: 'ದ್ವಿಪಾದ ನಕ್ಷತ್ರ ದೋಷ',
    nameEn: 'Dwipada Nakshatra Dosha',
    severity: DoshaSeverity.saumya,
    descriptionKn: 'ಚಂದ್ರನ ನಕ್ಷತ್ರ $nakName ರಾಶಿ ಗಡಿಯಲ್ಲಿ ಸಮಾನವಾಗಿ (2-2) ವಿಭಜನೆಯಾಗುತ್ತದೆ.',
    descriptionEn: 'Moon\'s nakshatra $nakName is equally split (2-2) at rashi boundary.',
    remedyKn: 'ದ್ವಿಪಾದ ನಕ್ಷತ್ರ ಶಾಂತಿ ಮಾಡಬೇಕು.',
    remedyEn: 'Dwipada Nakshatra Shanti recommended.',
    details: {'nakshatra': nakName},
      type: DoshaType.marana,
    ));
}

// ── M4. TITHI DOSHA (ತಿಥಿ ದೋಷ — Marana specific)
// Dwitiya(1,16), Saptami(6,21), Dwadashi(11,26)
// ─────────────────────────────────────────────────────────
void _checkTithiDoshaMarana(DoshaInput input, List<DoshaResult> doshas) {
  const doshaBaseTithis = {1, 6, 11}; // Dwitiya, Saptami, Dwadashi (base index within 15)
  final baseTithi = input.tithiIndex % 15;

  if (!doshaBaseTithis.contains(baseTithi)) return;

  final tithiName = knTithi[input.tithiIndex];
  doshas.add(DoshaResult(
    id: 'tithiDoshaMarana',
    nameKn: 'ತಿಥಿ ದೋಷ',
    nameEn: 'Tithi Dosha (Marana)',
    severity: DoshaSeverity.madhyama,
    descriptionKn: 'ದ್ವಿತೀಯಾ, ಸಪ್ತಮಿ ಅಥವಾ ದ್ವಾದಶಿ ತಿಥಿ. ಜನ್ಮ ತಿಥಿ: $tithiName.',
    descriptionEn: 'Birth on Dwitiya, Saptami, or Dwadashi tithi. Birth tithi: $tithiName.',
    remedyKn: 'ತಿಥಿ ಶಾಂತಿ ಪೂಜೆ, ತಿಥಿ ಅಧಿದೇವತೆ ಅರ್ಚನೆ ಮಾಡಬೇಕು.',
    remedyEn: 'Tithi Shanti Puja and worship of tithi deity.',
    details: {'tithi': tithiName},
      type: DoshaType.marana,
    ));
}

// ── M5. VARA DOSHA (ವಾರ ದೋಷ — Marana specific)
// Sunday(0), Tuesday(2), Saturday(6)
// ─────────────────────────────────────────────────────────
void _checkVaraDoshaMarana(DoshaInput input, List<DoshaResult> doshas) {
  const doshaVaras = {0, 2, 6}; // Sun, Tue, Sat

  if (!doshaVaras.contains(input.varaIndex)) return;

  final varaName = knVara[input.varaIndex];
  doshas.add(DoshaResult(
    id: 'varaDoshaMarana',
    nameKn: 'ವಾರ ದೋಷ',
    nameEn: 'Vara Dosha (Marana)',
    severity: DoshaSeverity.madhyama,
    descriptionKn: 'ಭಾನುವಾರ, ಮಂಗಳವಾರ ಅಥವಾ ಶನಿವಾರ ವಾರ. ಜನ್ಮ ವಾರ: $varaName.',
    descriptionEn: 'Birth on Sunday, Tuesday, or Saturday. Birth vara: $varaName.',
    remedyKn: 'ವಾರ ಶಾಂತಿ, ವಾರ ಅಧಿಪತಿ ಗ್ರಹ ಶಾಂತಿ ಮಾಡಬೇಕು.',
    remedyEn: 'Vara Shanti and worship of vara lord recommended.',
    details: {'vara': varaName},
      type: DoshaType.marana,
    ));
}

// ── M6. DWIPUSHKARA YOGA (ದ್ವಿಪುಷ್ಕರ ಯೋಗ)
// Tithi dosha + Vara dosha + Dwipada nakshatra (all 3 together)
// Doubles misfortune — events repeat twice
// ─────────────────────────────────────────────────────────
void _checkDwipushkaraYoga(DoshaInput input, List<DoshaResult> doshas) {
  const doshaBaseTithis = {1, 6, 11};
  const doshaVaras = {0, 2, 6};
  const dwipadaNaks = {4, 13, 22};

  final baseTithi = input.tithiIndex % 15;
  final hasTithiDosha = doshaBaseTithis.contains(baseTithi);
  final hasVaraDosha = doshaVaras.contains(input.varaIndex);
  final hasDwipadaNak = dwipadaNaks.contains(input.nakshatraIndex);

  if (!(hasTithiDosha && hasVaraDosha && hasDwipadaNak)) return;

  doshas.add(DoshaResult(
    id: 'dwipushkaraYoga',
    nameKn: 'ದ್ವಿಪುಷ್ಕರ ಯೋಗ',
    nameEn: 'Dwipushkara Yoga',
    severity: DoshaSeverity.tivra,
    descriptionKn: 'ತಿಥಿ/ವಾರ ದೋಷದೊಂದಿಗೆ ದ್ವಿಪಾದ ನಕ್ಷತ್ರ. ${knTithi[input.tithiIndex]} + ${knVara[input.varaIndex]} + ${knNak[input.nakshatraIndex]}. ದುರ್ಘಟನೆ ಎರಡು ಬಾರಿ ಪುನರಾವರ್ತನೆ.',
    descriptionEn: 'Tithi dosha + Vara dosha + Dwipada nakshatra together. ${knTithi[input.tithiIndex]} + ${knVara[input.varaIndex]} + ${knNak[input.nakshatraIndex]}. Misfortune doubles.',
    remedyKn: 'ದ್ವಿಪುಷ್ಕರ ಶಾಂತಿ, ನವಗ್ರಹ ಹೋಮ, ಮೃತ್ಯುಂಜಯ ಜಪ 11,000 ಬಾರಿ ಮಾಡಬೇಕು.',
    remedyEn: 'Dwipushkara Shanti, Navagraha Homa, and Mrityunjaya Japa 11,000 times.',
    details: {'tithi': knTithi[input.tithiIndex], 'vara': knVara[input.varaIndex], 'nakshatra': knNak[input.nakshatraIndex]},
      type: DoshaType.marana,
    ));
}

// ── M7. TRIPUSHKARA YOGA (ತ್ರಿಪುಷ್ಕರ ಯೋಗ)
// Tithi dosha + Vara dosha + Tripada nakshatra (3-pada side)
// Triples misfortune — events repeat three times
// ─────────────────────────────────────────────────────────
void _checkTripushkaraYoga(DoshaInput input, List<DoshaResult> doshas) {
  const doshaBaseTithis = {1, 6, 11};
  const doshaVaras = {0, 2, 6};
  const tripadaMap = <int, List<int>>{
    2:  [2, 3, 4],
    6:  [1, 2, 3],
    11: [2, 3, 4],
    15: [1, 2, 3],
    20: [2, 3, 4],
    24: [1, 2, 3],
  };

  final baseTithi = input.tithiIndex % 15;
  final hasTithiDosha = doshaBaseTithis.contains(baseTithi);
  final hasVaraDosha = doshaVaras.contains(input.varaIndex);
  final isTripadaNak = tripadaMap.containsKey(input.nakshatraIndex) &&
      tripadaMap[input.nakshatraIndex]!.contains(input.pada);

  if (!(hasTithiDosha && hasVaraDosha && isTripadaNak)) return;

  doshas.add(DoshaResult(
    id: 'tripushkaraYoga',
    nameKn: 'ತ್ರಿಪುಷ್ಕರ ಯೋಗ',
    nameEn: 'Tripushkara Yoga',
    severity: DoshaSeverity.tivra,
    descriptionKn: 'ತಿಥಿ ದೋಷ, ವಾರ ದೋಷ ಮತ್ತು ತ್ರಿಪಾದ ನಕ್ಷತ್ರ ಒಟ್ಟಿಗೆ. ${knTithi[input.tithiIndex]} + ${knVara[input.varaIndex]} + ${knNak[input.nakshatraIndex]} ಪಾದ ${input.pada}. ದುರ್ಘಟನೆ ಮೂರು ಬಾರಿ.',
    descriptionEn: 'Tithi dosha + Vara dosha + Tripada nakshatra (3-pada side). ${knTithi[input.tithiIndex]} + ${knVara[input.varaIndex]} + ${knNak[input.nakshatraIndex]} pada ${input.pada}. Misfortune triples.',
    remedyKn: 'ತ್ರಿಪುಷ್ಕರ ಶಾಂತಿ ಅತ್ಯಗತ್ಯ, ನವಗ್ರಹ ಹೋಮ, ಮೃತ್ಯುಂಜಯ ಜಪ 21,000 ಬಾರಿ ಮಾಡಬೇಕು.',
    remedyEn: 'Tripushkara Shanti essential, Navagraha Homa, and Mrityunjaya Japa 21,000 times.',
    details: {'tithi': knTithi[input.tithiIndex], 'vara': knVara[input.varaIndex], 'nakshatra': knNak[input.nakshatraIndex], 'pada': '${input.pada}'},
      type: DoshaType.marana,
    ));
}

// ── M8. KALA DOSHA / KALA MRITYU (ಕಾಲ ದೋಷ)
// Count from Sun's nakshatra to Moon's nakshatra.
// Certain counts are Kala Mrityu positions:
// From classical texts: count = 5, 14, 19, 22 (Kala Mrityu zone)
// ─────────────────────────────────────────────────────────
void _checkKalaDosha(DoshaInput input, List<DoshaResult> doshas) {
  // Count: 1-indexed, from Sun nak to Moon nak inclusive
  final count = ((input.nakshatraIndex - input.sunNakshatraIndex + 27) % 27) + 1;

  // Classical Kala Mrityu positions (nakshatra distance from Sun to Moon)
  const kalaMrityuCounts = {5, 14, 19, 22};

  if (!kalaMrityuCounts.contains(count)) return;

  final sunNakName = knNak[input.sunNakshatraIndex];
  final moonNakName = knNak[input.nakshatraIndex];

  doshas.add(DoshaResult(
    id: 'kalaDosha',
    nameKn: 'ಕಾಲ ದೋಷ (ಕಾಲ ಮೃತ್ಯು ಪ್ರವೇಶ)',
    nameEn: 'Kala Dosha (Kala Mrityu)',
    severity: count == 22 || count == 5 ? DoshaSeverity.tivra : DoshaSeverity.madhyama,
    descriptionKn: 'ಸೂರ್ಯನ ನಕ್ಷತ್ರ ($sunNakName) ದಿಂದ ಚಂದ್ರನ ನಕ್ಷತ್ರ ($moonNakName) ದವರೆಗೆ ಎಣಿಸಿ = $count/27, ಕಾಲ ಮೃತ್ಯು ಸ್ಥಾನ.',
    descriptionEn: 'Count from Sun\'s nakshatra ($sunNakName) to Moon\'s nakshatra ($moonNakName) = $count/27. Kala Mrityu position.',
    remedyKn: 'ಕಾಲ ಮೃತ್ಯು ಶಾಂತಿ, ಮಹಾ ಮೃತ್ಯುಂಜಯ ಹೋಮ, ಅಯುಷ್ಯ ಸೂಕ್ತ ಪಾರಾಯಣ ಮಾಡಬೇಕು.',
    remedyEn: 'Kala Mrityu Shanti, Maha Mrityunjaya Homa, and Ayushya Sukta recitation.',
    details: {'sunNak': sunNakName, 'moonNak': moonNakName, 'count': '$count/27'},
      type: DoshaType.marana,
    ));
}
