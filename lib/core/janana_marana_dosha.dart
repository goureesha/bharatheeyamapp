// Janana / Marana Dosha Engine
// Checks birth panchanga for classical inauspicious combinations.
// References: Muhurta Chintamani, Brihat Jataka, Jataka Parijata,
// Surya Siddhanta, Prasna Marga, Hora Sara.

import '../constants/strings.dart';

/// Severity levels for doshas
enum DoshaSeverity { tivra, madhyama, saumya }

/// A single detected dosha
class DoshaResult {
  final String id;              // machine key (e.g. 'nakshatraGandanta')
  final String nameKn;          // Kannada name
  final String nameEn;          // English name
  final DoshaSeverity severity;
  final String descriptionKn;   // Kannada description
  final String descriptionEn;   // English description
  final String remedyKn;        // Kannada remedy text
  final String remedyEn;        // English remedy text
  final Map<String, String> details; // extra key-value pairs

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
  });
}

/// Input data for dosha analysis
class DoshaInput {
  final int nakshatraIndex;   // 0-26 (0=Ashwini, 26=Revati)
  final int pada;             // 1-4
  final double nakPercent;    // fraction of nakshatra elapsed (0.0-1.0)
  final int tithiIndex;       // 0-29
  final int varaIndex;        // 0=Sun, 1=Mon, ... 6=Sat
  final int moonRashiIndex;   // 0-11 (0=Mesha, 11=Meena)
  final double moonLongitude; // sidereal degrees (0-360)
  final int lagnaRashiIndex;  // 0-11
  final int yogaIndex;        // 0-26

  const DoshaInput({
    required this.nakshatraIndex,
    required this.pada,
    required this.nakPercent,
    required this.tithiIndex,
    required this.varaIndex,
    required this.moonRashiIndex,
    required this.moonLongitude,
    required this.lagnaRashiIndex,
    required this.yogaIndex,
  });
}

/// Panchanga summary for display
class PanchangaSummary {
  final String tithi;
  final String nakshatra;
  final String pada;
  final String vara;
  final String yoga;
  final String chandraRashi;
  final String lagnaRashi;

  const PanchangaSummary({
    required this.tithi,
    required this.nakshatra,
    required this.pada,
    required this.vara,
    required this.yoga,
    required this.chandraRashi,
    required this.lagnaRashi,
  });
}

/// Main analysis function — returns all found doshas
List<DoshaResult> analyzeJananaMaranaDosha(DoshaInput input) {
  final doshas = <DoshaResult>[];

  // 1. Nakshatra Gandanta
  _checkNakshatraGandanta(input, doshas);

  // 2. Rashi Gandanta
  _checkRashiGandanta(input, doshas);

  // 3. Tithi Gandanta
  _checkTithiGandanta(input, doshas);

  // 4. Abhukta Moola Nakshatra
  _checkAbhuktaMoola(input, doshas);

  // 5. Dagdha Tithi (Burned Tithi)
  _checkDagdhaTithi(input, doshas);

  // 6. Mrityu Yoga (Vara + Nakshatra)
  _checkMrityuYoga(input, doshas);

  // 7. Vishkambha / Vaidhrti Yoga
  _checkInauspiciousYoga(input, doshas);

  // 8. Tripada Dosha analysis
  _checkTripadaDosha(input, doshas);

  return doshas;
}

// ═══════════════════════════════════════════════════════════
// 1. NAKSHATRA GANDANTA
// Junction between last quarter of water sign nakshatras
// and first quarter of fire sign nakshatras.
// Water→Fire transitions:
//   Ashlesha(8) → Magha(9)     [Cancer → Leo]
//   Jyeshtha(17) → Moola(18)   [Scorpio → Sagittarius]
//   Revati(26) → Ashwini(0)    [Pisces → Aries]
// ═══════════════════════════════════════════════════════════
void _checkNakshatraGandanta(DoshaInput input, List<DoshaResult> doshas) {
  // Gandanta zone: last 2 ghatis (~48 min) of ending nakshatra,
  // first 2 ghatis of starting nakshatra.
  // Using nakPercent: last quarter (pada 4) of ending nak,
  // first quarter (pada 1) of starting nak.

  bool isGandanta = false;
  String zone = '';

  // Ashlesha (8) pada 4 — most severe (Jala-Agni sandhi)
  if (input.nakshatraIndex == 8 && input.pada == 4) {
    isGandanta = true;
    zone = 'ಆಶ್ಲೇಷ 4ನೇ ಪಾದ → ಮಘ / Ashlesha 4th pada → Magha';
  }
  // Magha (9) pada 1
  else if (input.nakshatraIndex == 9 && input.pada == 1) {
    isGandanta = true;
    zone = 'ಮಘ 1ನೇ ಪಾದ ← ಆಶ್ಲೇಷ / Magha 1st pada ← Ashlesha';
  }
  // Jyeshtha (17) pada 4
  else if (input.nakshatraIndex == 17 && input.pada == 4) {
    isGandanta = true;
    zone = 'ಜ್ಯೇಷ್ಠ 4ನೇ ಪಾದ → ಮೂಲ / Jyeshtha 4th pada → Moola';
  }
  // Moola (18) pada 1 — most dangerous
  else if (input.nakshatraIndex == 18 && input.pada == 1) {
    isGandanta = true;
    zone = 'ಮೂಲ 1ನೇ ಪಾದ ← ಜ್ಯೇಷ್ಠ / Moola 1st pada ← Jyeshtha';
  }
  // Revati (26) pada 4
  else if (input.nakshatraIndex == 26 && input.pada == 4) {
    isGandanta = true;
    zone = 'ರೇವತಿ 4ನೇ ಪಾದ → ಅಶ್ವಿನಿ / Revati 4th pada → Ashwini';
  }
  // Ashwini (0) pada 1
  else if (input.nakshatraIndex == 0 && input.pada == 1) {
    isGandanta = true;
    zone = 'ಅಶ್ವಿನಿ 1ನೇ ಪಾದ ← ರೇವತಿ / Ashwini 1st pada ← Revati';
  }

  if (isGandanta) {
    // Moola & Jyeshtha junction is most severe
    final isMoolaJyeshtha = input.nakshatraIndex == 17 || input.nakshatraIndex == 18;
    doshas.add(DoshaResult(
      id: 'nakshatraGandanta',
      nameKn: 'ನಕ್ಷತ್ರ ಗಂಡಾಂತ ದೋಷ',
      nameEn: 'Nakshatra Gandanta Dosha',
      severity: isMoolaJyeshtha ? DoshaSeverity.tivra : DoshaSeverity.madhyama,
      descriptionKn: 'ಜಲ ರಾಶಿಯ ಕೊನೆ ಮತ್ತು ಅಗ್ನಿ ರಾಶಿಯ ಆರಂಭದ ಸಂಧಿಯಲ್ಲಿ ಜನನ. ಸ್ಥಾನ: $zone',
      descriptionEn: 'Birth at junction of water and fire sign nakshatras. Zone: $zone',
      remedyKn: 'ಗಂಡಾಂತ ಶಾಂತಿ ಪೂಜೆ, ಮೃತ್ಯುಂಜಯ ಜಪ, ದಾನ-ಧರ್ಮ ಮಾಡಬೇಕು.',
      remedyEn: 'Gandanta Shanti Puja, Mrityunjaya Japa, and charitable donations recommended.',
      details: {'zone': zone},
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 2. RASHI GANDANTA
// Moon at junction of water → fire signs:
//   Cancer(3) → Leo(4), Scorpio(7) → Sagittarius(8),
//   Pisces(11) → Aries(0)
// Critical: last 3°20' of water sign or first 3°20' of fire sign
// ═══════════════════════════════════════════════════════════
void _checkRashiGandanta(DoshaInput input, List<DoshaResult> doshas) {
  final moonDeg = input.moonLongitude % 30.0; // degree within the sign

  bool isGandanta = false;
  String zone = '';

  // Water signs: Cancer=3, Scorpio=7, Pisces=11
  // Fire signs: Leo=4, Sagittarius=8, Aries=0
  const waterSigns = {3, 7, 11};
  const fireSigns = {0, 4, 8};

  if (waterSigns.contains(input.moonRashiIndex) && moonDeg >= 26.67) {
    isGandanta = true;
    zone = '${knRashi[input.moonRashiIndex]} ಕೊನೆ / End of ${knRashi[input.moonRashiIndex]}';
  } else if (fireSigns.contains(input.moonRashiIndex) && moonDeg <= 3.33) {
    isGandanta = true;
    zone = '${knRashi[input.moonRashiIndex]} ಆರಂಭ / Start of ${knRashi[input.moonRashiIndex]}';
  }

  if (isGandanta) {
    doshas.add(DoshaResult(
      id: 'rashiGandanta',
      nameKn: 'ರಾಶಿ ಗಂಡಾಂತ ದೋಷ',
      nameEn: 'Rashi Gandanta Dosha',
      severity: DoshaSeverity.madhyama,
      descriptionKn: 'ಚಂದ್ರನು ಜಲ ಮತ್ತು ಅಗ್ನಿ ರಾಶಿ ಸಂಧಿಯಲ್ಲಿ. ಸ್ಥಾನ: $zone. ಚಂದ್ರ ${moonDeg.toStringAsFixed(1)}° ರಾಶಿಯಲ್ಲಿ.',
      descriptionEn: 'Moon at water-fire sign junction. Position: $zone. Moon at ${moonDeg.toStringAsFixed(1)}° in sign.',
      remedyKn: 'ರಾಶಿ ಗಂಡಾಂತ ಶಾಂತಿ, ಚಂದ್ರ ಗ್ರಹ ಶಾಂತಿ ಮಾಡಬೇಕು.',
      remedyEn: 'Rashi Gandanta Shanti and Chandra Graha Shanti recommended.',
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 3. TITHI GANDANTA
// Junction tithis:
//   Poornima(14) → Krishna Padyami(15)
//   Amavasya(29) → Shukla Padyami(0)
//   Shukla Panchami(4) → Shukla Shashthi(5)
//   Krishna Panchami(19) → Krishna Shashthi(20)
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
      descriptionKn: 'ತಿಥಿ ಸಂಧಿಯಲ್ಲಿ ಜನನ. ಜನ್ಮ ತಿಥಿ: $tithiName',
      descriptionEn: 'Birth at tithi junction. Birth tithi: $tithiName',
      remedyKn: 'ತಿಥಿ ಶಾಂತಿ ಪೂಜೆ, ತಿಥಿ ಅಧಿದೇವತೆಗೆ ಪ್ರಾರ್ಥನೆ.',
      remedyEn: 'Tithi Shanti Puja and prayer to tithi deity.',
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 4. ABHUKTA MOOLA NAKSHATRA
// Six root nakshatras with specific dangerous padas:
//   Ashwini(0)   — pada 1 (start of Mesha)
//   Ashlesha(8)  — pada 4 (end of Karkataka)
//   Magha(9)     — pada 1 (start of Simha)
//   Jyeshtha(17) — pada 4 (end of Vrischika)
//   Moola(18)    — pada 1 (start of Dhanu) — most dangerous
//   Revati(26)   — pada 4 (end of Meena)
// ═══════════════════════════════════════════════════════════
void _checkAbhuktaMoola(DoshaInput input, List<DoshaResult> doshas) {
  // Map of nakshatra index → dangerous pada(s)
  const moolaNakshatras = <int, List<int>>{
    0:  [1],        // Ashwini — pada 1
    8:  [4],        // Ashlesha — pada 4
    9:  [1],        // Magha — pada 1
    17: [4],        // Jyeshtha — pada 4
    18: [1, 2],     // Moola — pada 1 (most severe), pada 2
    26: [4],        // Revati — pada 4
  };

  if (moolaNakshatras.containsKey(input.nakshatraIndex)) {
    final dangerousPadas = moolaNakshatras[input.nakshatraIndex]!;
    if (dangerousPadas.contains(input.pada)) {
      final nakName = knNak[input.nakshatraIndex];
      final isMoola = input.nakshatraIndex == 18 && input.pada == 1;

      doshas.add(DoshaResult(
        id: 'abhuktaMoola',
        nameKn: 'ಅಭುಕ್ತ ಮೂಲ ನಕ್ಷತ್ರ ದೋಷ',
        nameEn: 'Abhukta Moola Nakshatra Dosha',
        severity: isMoola ? DoshaSeverity.tivra : DoshaSeverity.madhyama,
        descriptionKn: 'ಮೂಲ ನಕ್ಷತ್ರದಲ್ಲಿ ಜನನ. ಜನ್ಮ ನಕ್ಷತ್ರ: $nakName, ಪಾದ: ${input.pada}',
        descriptionEn: 'Birth in Moola nakshatra. Birth star: $nakName, Pada: ${input.pada}',
        remedyKn: 'ಮೂಲ ನಕ್ಷತ್ರ ಶಾಂತಿ ಪೂಜೆ, 27ನೇ ದಿನದ ನಂತರ ಮಗುವನ್ನು ತಂದೆಗೆ ತೋರಿಸಬೇಕು (ಪ್ರಾಚೀನ ಸಂಪ್ರದಾಯ).',
        remedyEn: 'Moola Nakshatra Shanti Puja. Per ancient tradition, child shown to father after 27th day.',
        details: {'nakshatra': nakName, 'pada': '${input.pada}'},
      ));
    }
  }
}

// ═══════════════════════════════════════════════════════════
// 5. DAGDHA TITHI (Burned Tithi)
// Certain Vara+Tithi combinations are considered "burned":
//   Sunday     : Dvadashi (index 11, 26)
//   Monday     : Ekadashi (index 10, 25)
//   Tuesday    : Panchami (index 4, 19)
//   Wednesday  : Tritiya  (index 2, 17)
//   Thursday   : Shashthi (index 5, 20)
//   Friday     : Ashtami  (index 7, 22)
//   Saturday   : Navami   (index 8, 23)
// ═══════════════════════════════════════════════════════════
void _checkDagdhaTithi(DoshaInput input, List<DoshaResult> doshas) {
  // Base tithi index (0-14 range, repeats for Shukla and Krishna)
  final baseTithi = input.tithiIndex % 15;

  const dagdhaMap = <int, int>{
    0: 11,   // Sun: Dvadashi
    1: 10,   // Mon: Ekadashi
    2: 4,    // Tue: Panchami
    3: 2,    // Wed: Tritiya
    4: 5,    // Thu: Shashthi
    5: 7,    // Fri: Ashtami
    6: 8,    // Sat: Navami
  };

  if (dagdhaMap[input.varaIndex] == baseTithi) {
    final varaName = knVara[input.varaIndex];
    final tithiName = knTithi[input.tithiIndex];

    doshas.add(DoshaResult(
      id: 'dagdhaTithi',
      nameKn: 'ದಗ್ಧ ತಿಥಿ ದೋಷ',
      nameEn: 'Dagdha Tithi Dosha (Burned Tithi)',
      severity: DoshaSeverity.madhyama,
      descriptionKn: 'ವಾರ-ತಿಥಿ ಸಂಯೋಗ ದಗ್ಧವಾಗಿದೆ. $varaName + $tithiName = ದಗ್ಧ.',
      descriptionEn: 'Vara-Tithi combination is burned (dagdha). $varaName + $tithiName = Dagdha.',
      remedyKn: 'ದಗ್ಧ ತಿಥಿ ಶಾಂತಿ, ಸೂರ್ಯ ನಮಸ್ಕಾರ, ಹೋಮ ಮಾಡಬೇಕು.',
      remedyEn: 'Dagdha Tithi Shanti, Surya Namaskara, and Homa recommended.',
      details: {'vara': varaName, 'tithi': tithiName},
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 6. MRITYU YOGA (Death Yoga — Vara + Nakshatra)
// Specific Vara-Nakshatra combinations considered deadly:
//   Sunday(0)    : Anuradha(16)
//   Monday(1)    : Uttarashadha(20)
//   Tuesday(2)   : Satabhisha(23)
//   Wednesday(3) : Dhanishta(22)
//   Thursday(4)  : Mrigashira(4)
//   Friday(5)    : Ashlesha(8)
//   Saturday(6)  : Rohini(3)
// (From Muhurta Chintamani)
// ═══════════════════════════════════════════════════════════
void _checkMrityuYoga(DoshaInput input, List<DoshaResult> doshas) {
  const mrityuMap = <int, int>{
    0: 16,   // Sun: Anuradha
    1: 20,   // Mon: Uttarashadha
    2: 23,   // Tue: Satabhisha
    3: 22,   // Wed: Dhanishta
    4: 4,    // Thu: Mrigashira
    5: 8,    // Fri: Ashlesha
    6: 3,    // Sat: Rohini
  };

  if (mrityuMap[input.varaIndex] == input.nakshatraIndex) {
    final varaName = knVara[input.varaIndex];
    final nakName = knNak[input.nakshatraIndex];

    doshas.add(DoshaResult(
      id: 'mrityuYoga',
      nameKn: 'ಮೃತ್ಯು ಯೋಗ ದೋಷ',
      nameEn: 'Mrityu Yoga Dosha',
      severity: DoshaSeverity.tivra,
      descriptionKn: 'ವಾರ-ನಕ್ಷತ್ರ ಸಂಯೋಗ ಮೃತ್ಯು ಯೋಗವಾಗಿದೆ. $varaName + $nakName = ಮೃತ್ಯು ಯೋಗ.',
      descriptionEn: 'Vara-Nakshatra combination forms Mrityu Yoga. $varaName + $nakName = Mrityu Yoga.',
      remedyKn: 'ಮೃತ್ಯುಂಜಯ ಜಪ (1,25,000), ರುದ್ರಾಭಿಷೇಕ, ನವಗ್ರಹ ಶಾಂತಿ ಮಾಡಬೇಕು.',
      remedyEn: 'Mrityunjaya Japa (1,25,000 times), Rudrabhisheka, and Navagraha Shanti recommended.',
      details: {'vara': varaName, 'nakshatra': nakName},
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 7. INAUSPICIOUS YOGAS
// Vishkambha(0) and Vaidhrti(26) are most inauspicious.
// Vyatipata(16), Parigha(18), Vajra(14) are also bad.
// ═══════════════════════════════════════════════════════════
void _checkInauspiciousYoga(DoshaInput input, List<DoshaResult> doshas) {
  const badYogas = <int, DoshaSeverity>{
    0:  DoshaSeverity.tivra,     // Vishkambha
    26: DoshaSeverity.tivra,     // Vaidhrti
    16: DoshaSeverity.madhyama,  // Vyatipata
    18: DoshaSeverity.saumya,    // Parigha
    14: DoshaSeverity.saumya,    // Vajra
  };

  if (badYogas.containsKey(input.yogaIndex)) {
    final yogaName = knYoga[input.yogaIndex];
    final severity = badYogas[input.yogaIndex]!;
    final isSevere = severity == DoshaSeverity.tivra;

    doshas.add(DoshaResult(
      id: 'inauspiciousYoga',
      nameKn: 'ಅಶುಭ ಯೋಗ ದೋಷ',
      nameEn: 'Inauspicious Yoga Dosha',
      severity: severity,
      descriptionKn: 'ಜನ್ಮ ಯೋಗ $yogaName ಅಶುಭವಾಗಿದೆ.${isSevere ? " ಇದು ಅತ್ಯಂತ ಅಶುಭ ಯೋಗ." : ""}',
      descriptionEn: 'Birth yoga $yogaName is inauspicious.${isSevere ? " This is a highly inauspicious yoga." : ""}',
      remedyKn: 'ಯೋಗ ಶಾಂತಿ ಪೂಜೆ, ನವಗ್ರಹ ಹೋಮ ಮಾಡಬೇಕು.',
      remedyEn: 'Yoga Shanti Puja and Navagraha Homa recommended.',
      details: {'yoga': yogaName},
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 8. TRIPADA DOSHA
// Counts how many of the 3 panchanga elements (Tithi, Nakshatra, Vara)
// are inauspicious at birth.
//
// Inauspicious Tithis: Pratipada(0,15), Dwitiya(1,16), Shashthi(5,20),
//   Ashtami(7,22), Ekadashi(10,25), Dvadashi(11,26),
//   Trayodashi(12,27), Chaturdashi(13,28), Amavasya(29)
//
// Inauspicious Nakshatras: Rohini(3), Mrigasira(4), Punarvasu(6),
//   Magha(9), Uttara Phalguni(11), Chitra(13), Visakha(15),
//   Uttarashadha(20), Dhanishta(22), Satabhisha(23),
//   Purvabhadra(24), Revati(26)
//
// Inauspicious Varas: Sunday(0), Tuesday(2), Friday(5), Saturday(6)
// ═══════════════════════════════════════════════════════════
void _checkTripadaDosha(DoshaInput input, List<DoshaResult> doshas) {
  // Inauspicious tithis (base index 0-14)
  const badTithiBase = {0, 1, 5, 7, 10, 11, 12, 13};
  // Amavasya (index 29) is also inauspicious
  final baseTithi = input.tithiIndex % 15;
  final isBadTithi = badTithiBase.contains(baseTithi) || input.tithiIndex == 29;

  // Inauspicious nakshatras
  const badNak = {3, 4, 6, 9, 11, 13, 15, 20, 22, 23, 24, 26};
  final isBadNak = badNak.contains(input.nakshatraIndex);

  // Inauspicious varas
  const badVara = {0, 2, 5, 6};
  final isBadVara = badVara.contains(input.varaIndex);

  int count = 0;
  final badElements = <String>[];

  if (isBadTithi) {
    count++;
    badElements.add(knTithi[input.tithiIndex]);
  }
  if (isBadNak) {
    count++;
    badElements.add(knNak[input.nakshatraIndex]);
  }
  if (isBadVara) {
    count++;
    badElements.add(knVara[input.varaIndex]);
  }

  if (count >= 1) {
    String typeKn, typeEn;
    DoshaSeverity severity;
    if (count == 3) {
      typeKn = 'ತ್ರಿಪದ ದೋಷ (ಮೂರೂ ಅಶುಭ)';
      typeEn = 'Tripada Dosha (all 3 inauspicious)';
      severity = DoshaSeverity.tivra;
    } else if (count == 2) {
      typeKn = 'ದ್ವಿಪದ ದೋಷ (ಎರಡು ಅಶುಭ)';
      typeEn = 'Dwipada Dosha (2 inauspicious)';
      severity = DoshaSeverity.madhyama;
    } else {
      typeKn = 'ಏಕಪದ ದೋಷ (ಒಂದು ಅಶುಭ)';
      typeEn = 'Ekapada Dosha (1 inauspicious)';
      severity = DoshaSeverity.saumya;
    }

    final elementsStr = badElements.join(', ');

    doshas.add(DoshaResult(
      id: 'tripadaDosha',
      nameKn: typeKn,
      nameEn: typeEn,
      severity: severity,
      descriptionKn: 'ಜನ್ಮ ಪಂಚಾಂಗದಲ್ಲಿ $count ಅಂಶ(ಗಳು) ಅಶುಭ: $elementsStr',
      descriptionEn: '$count element(s) of birth panchanga are inauspicious: $elementsStr',
      remedyKn: count == 3
          ? 'ತ್ರಿಪದ ದೋಷ ಶಾಂತಿ, ನವಗ್ರಹ ಹೋಮ, ಗೋದಾನ, ಮೃತ್ಯುಂಜಯ ಜಪ ಅವಶ್ಯ.'
          : 'ದೋಷ ಶಾಂತಿ ಪೂಜೆ, ಸಂಬಂಧಿಸಿದ ಗ್ರಹ ಶಾಂತಿ ಮಾಡಬೇಕು.',
      remedyEn: count == 3
          ? 'Tripada Dosha Shanti, Navagraha Homa, Godana, and Mrityunjaya Japa required.'
          : 'Dosha Shanti Puja and related Graha Shanti recommended.',
      details: {'count': '$count', 'elements': elementsStr},
    ));
  }
}
