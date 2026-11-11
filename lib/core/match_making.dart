class MatchMakingLogic {
  static const Map<int, List<int>> _rashiNakMap = {
    0: [0, 1, 2],       // Mesha
    1: [2, 3, 4],       // Vrishabha
    2: [4, 5, 6],       // Mithuna
    3: [6, 7, 8],       // Karka
    4: [9, 10, 11],     // Simha
    5: [11, 12, 13],    // Kanya
    6: [13, 14, 15],    // Tula
    7: [15, 16, 17],    // Vrischika
    8: [18, 19, 20],    // Dhanu
    9: [20, 21, 22],    // Makara
    10: [22, 23, 24],   // Kumbha
    11: [24, 25, 26],   // Meena
  };

  // 1. Varna (1 Point) Based on Moon Sign
  static double getVarnaScore(int brideRashi, int groomRashi) {
    int getVarna(int rashi) {
      if ([3, 7, 11].contains(rashi)) return 0; // Brahmin
      if ([0, 4, 8].contains(rashi)) return 1;  // Kshatriya
      if ([1, 5, 9].contains(rashi)) return 2;  // Vaishya
      return 3; // Shudra
    }
    const points = [
      [1.0, 0.0, 0.0, 0.0],
      [1.0, 1.0, 0.0, 0.0],
      [1.0, 1.0, 1.0, 0.0],
      [1.0, 1.0, 1.0, 1.0],
    ];
    return points[getVarna(brideRashi)][getVarna(groomRashi)];
  }

  // 2. Vashya (2 Points)
  static double getVashyaScore(int brideRashi, int groomRashi) {
    int getGroup(int rashi) {
      if ([2, 5, 6, 8, 10].contains(rashi)) return 0; // Manav
      if (rashi == 4) return 1; // Vanchar
      if ([0, 1, 9].contains(rashi)) return 2; // Chatushpad
      if ([3, 9, 11].contains(rashi)) return 3; // Jalchar
      return 4; // Keet
    }
    const points = [
      [2.0, 0.5, 1.0, 0.0, 2.0],
      [0.5, 2.0, 0.0, 0.0, 0.0],
      [1.0, 0.0, 2.0, 2.0, 2.0],
      [0.0, 0.0, 2.0, 2.0, 0.0],
      [1.0, 0.0, 1.0, 0.0, 2.0],
    ];
    return points[getGroup(brideRashi)][getGroup(groomRashi)];
  }

  // 3. Tara (3 Points)
  static double getTaraScore(int brideNak, int groomNak) {
    int getTaraGroup(int nak) => nak % 9;
    const points = [
      [3.0, 3.0, 1.5, 3.0, 1.5, 3.0, 1.5, 3.0, 3.0],
      [3.0, 3.0, 1.5, 3.0, 1.5, 3.0, 1.5, 3.0, 3.0],
      [1.5, 1.5, 0.0, 1.5, 0.0, 1.5, 0.0, 1.5, 1.5],
      [3.0, 3.0, 1.5, 3.0, 1.5, 3.0, 1.5, 3.0, 3.0],
      [1.5, 1.5, 0.0, 1.5, 0.0, 1.5, 0.0, 1.5, 1.5],
      [3.0, 3.0, 1.5, 3.0, 1.5, 3.0, 1.5, 3.0, 3.0],
      [1.5, 1.5, 0.0, 1.5, 0.0, 1.5, 0.0, 1.0, 1.0],
      [3.0, 3.0, 1.5, 3.0, 1.5, 3.0, 1.5, 3.0, 3.0],
      [3.0, 3.0, 1.5, 3.0, 1.5, 3.0, 1.5, 3.0, 3.0],
    ];
    return points[getTaraGroup(brideNak)][getTaraGroup(groomNak)];
  }

  // 4. Yoni (4 Points)
  static double getYoniScore(int brideNak, int groomNak) {
    const animalMap = [0, 1, 2, 3, 3, 4, 5, 2, 5, 6, 6, 7, 8, 9, 8, 9, 11, 10, 4, 11, 12, 11, 13, 0, 13, 7, 1];
    const points = [
      [4, 2, 2, 3, 2, 2, 2, 1, 0, 1, 1, 3, 2, 1],
      [2, 4, 3, 3, 2, 2, 2, 2, 3, 1, 2, 3, 2, 0],
      [2, 3, 4, 3, 2, 2, 2, 2, 3, 1, 2, 3, 2, 0],
      [3, 3, 2, 4, 2, 1, 1, 1, 1, 2, 2, 2, 0, 2],
      [2, 2, 1, 2, 4, 2, 1, 2, 2, 1, 0, 2, 1, 1],
      [2, 2, 2, 1, 2, 4, 0, 2, 2, 1, 3, 3, 2, 1],
      [2, 2, 1, 1, 1, 0, 4, 2, 2, 2, 2, 2, 1, 2],
      [1, 2, 3, 1, 2, 2, 2, 4, 3, 0, 3, 2, 2, 1],
      [0, 3, 3, 1, 2, 2, 2, 3, 4, 1, 2, 2, 2, 2],
      [1, 1, 1, 2, 1, 1, 2, 0, 1, 4, 1, 1, 2, 1],
      [1, 2, 2, 2, 0, 3, 2, 3, 2, 1, 4, 2, 2, 1],
      [3, 3, 0, 2, 2, 3, 2, 2, 2, 1, 2, 4, 3, 2],
      [2, 2, 3, 0, 1, 2, 1, 2, 2, 2, 2, 3, 4, 2],
      [1, 0, 1, 2, 1, 1, 2, 1, 2, 1, 1, 2, 2, 4]
    ];
    return points[animalMap[brideNak]][animalMap[groomNak]].toDouble();
  }

  // 5. Graha Maitri (5 Points)
  static double getGrahaMaitriScore(int brideRashi, int groomRashi) {
    int getLord(int rashi) {
      if (rashi == 4) return 0; // Sun
      if (rashi == 3) return 1; // Moon
      if (rashi == 0 || rashi == 7) return 2; // Mars
      if (rashi == 2 || rashi == 5) return 3; // Merc
      if (rashi == 8 || rashi == 11) return 4; // Jup
      if (rashi == 1 || rashi == 6) return 5; // Ven
      return 6; // Sat
    }
    const points = [
      [5.0, 5.0, 5.0, 4.0, 5.0, 0.0, 0.0],
      [5.0, 5.0, 4.0, 1.0, 4.0, 0.5, 0.5],
      [5.0, 4.0, 5.0, 0.5, 5.0, 3.0, 0.5],
      [4.0, 1.0, 0.5, 5.0, 0.5, 5.0, 4.0],
      [5.0, 4.0, 5.0, 0.5, 5.0, 0.5, 4.0],
      [0.0, 0.5, 3.0, 5.0, 0.5, 5.0, 5.0],
      [0.0, 0.5, 0.5, 4.0, 4.0, 5.0, 5.0]
    ];
    return points[getLord(brideRashi)][getLord(groomRashi)];
  }

  // 6. Gana (6 Points)
  static double getGanaScore(int brideNak, int groomNak) {
    int getTemperament(int nak) {
      if ([0, 4, 6, 7, 12, 14, 16, 21, 26].contains(nak)) return 0; // Deva
      if ([1, 3, 5, 10, 11, 19, 20, 24, 25].contains(nak)) return 1; // Manushya
      return 2; // Rakshasa
    }
    const points = [
      [6.0, 3.0, 1.0],
      [5.0, 6.0, 3.0],
      [0.0, 0.0, 6.0],
    ];
    return points[getTemperament(brideNak)][getTemperament(groomNak)];
  }

  // 7. Bhakoot (7 Points) 12x12 Precise Matrix
  static double getBhakootScore(int brideRashi, int groomRashi) {
    const points = [
      [7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 0.0, 0.0, 7.0, 7.0, 0.0],
      [0.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 0.0, 0.0, 7.0, 7.0],
      [7.0, 0.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 0.0, 0.0, 7.0],
      [7.0, 7.0, 0.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 0.0, 0.0],
      [0.0, 7.0, 7.0, 0.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 0.0],
      [0.0, 0.0, 7.0, 7.0, 0.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0],
      [7.0, 0.0, 0.0, 7.0, 7.0, 0.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0],
      [0.0, 7.0, 0.0, 0.0, 7.0, 7.0, 0.0, 7.0, 0.0, 7.0, 7.0, 0.0],
      [0.0, 0.0, 7.0, 0.0, 0.0, 7.0, 7.0, 0.0, 7.0, 0.0, 7.0, 7.0],
      [7.0, 0.0, 0.0, 7.0, 0.0, 0.0, 7.0, 7.0, 0.0, 7.0, 0.0, 7.0],
      [7.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 7.0, 0.0, 7.0, 0.0],
      [0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 0.0, 0.0, 7.0, 7.0, 0.0, 7.0],
    ];
    return points[brideRashi][groomRashi];
  }

  // 8. Nadi (8 Points)
  static double getNadiScore(int brideNak, int groomNak) {
    int getNadi(int nak) {
      if ([0, 5, 6, 11, 12, 17, 18, 23, 24].contains(nak)) return 0; // Adi
      if ([1, 4, 7, 10, 13, 16, 19, 22, 25].contains(nak)) return 1; // Madhya
      return 2; // Antya
    }
    const points = [
      [0.0, 8.0, 8.0],
      [8.0, 0.0, 8.0],
      [8.0, 8.0, 0.0],
    ];
    return points[getNadi(brideNak)][getNadi(groomNak)];
  }

  // ── DVADASHA KOOTA: 4 additional kootas ──

  // 9. Mahendra (1 Point)
  // Count nakshatras from bride to groom. If (count-1) % 9 ∈ {0,3,6} → 1 pt
  static double getMahendraScore(int brideNak, int groomNak) {
    final count = ((groomNak - brideNak + 27) % 27);
    final mod = count % 9;
    return (mod == 0 || mod == 3 || mod == 6) ? 1.0 : 0.0;
  }

  // 10. Stree Deergha (1 Point)
  // If groom nakshatra is >= 13 nakshatras away from bride → 1 pt
  static double getStreeDeerghaScore(int brideNak, int groomNak) {
    final diff = ((groomNak - brideNak + 27) % 27);
    return diff >= 13 ? 1.0 : 0.0;
  }

  // 11. Rajju (1 Point)
  // Body part mapping. Same rajju group = 0 (bad), different = 1 (good)
  static double getRajjuScore(int brideNak, int groomNak) {
    // Rajju groups: 0=Paada(feet), 1=Kati(hip), 2=Nabhi(navel), 3=Kantha(neck), 4=Shira(head)
    int getRajju(int nak) {
      const map = [
        4, 3, 2, 1, 0, // Ashwini..Mrigashira (ascending)
        1, 2, 3, 4,     // Ardra..Pushya (descending)
        4, 3, 2, 1, 0, // Ashlesha..Hasta (ascending)
        1, 2, 3, 4,     // Chitra..Anuradha (descending)
        4, 3, 2, 1, 0, // Jyeshtha..Shravana (ascending)
        1, 2, 3, 4,     // Dhanishtha..Revati (descending)
      ];
      return map[nak % 27];
    }
    return getRajju(brideNak) == getRajju(groomNak) ? 0.0 : 1.0;
  }

  // 12. Vedha (1 Point)
  // Specific nakshatra pairs cause vedha. No vedha = 1 pt
  static double getVedhaScore(int brideNak, int groomNak) {
    // Vedha pairs (0-indexed nakshatras)
    const vedhaPairs = <List<int>>[
      [0, 17],  // Ashwini - Jyeshtha
      [1, 16],  // Bharani - Anuradha
      [2, 18],  // Krittika - Moola (based on some texts: Dhanishtha)
      [3, 19],  // Rohini - Shravana → Swati
      [4, 22],  // Mrigashira - Dhanishtha
      [5, 21],  // Ardra - Shravana
      [6, 20],  // Punarvasu - Purvashadha
      [7, 19],  // Pushya - Uttarashadha
      [8, 18],  // Ashlesha - Moola
      [9, 26],  // Magha - Revati
      [10, 25], // P.Phalguni - U.Bhadrapada
      [11, 24], // U.Phalguni - P.Bhadrapada
      [12, 23], // Hasta - Shatabhisha
      [13, 22], // Chitra - Dhanishtha  (duplicate intentional for reverse)
      [14, 21], // Swati - Shravana
      [15, 20], // Vishakha - Purvashadha
    ];
    for (final pair in vedhaPairs) {
      if ((brideNak == pair[0] && groomNak == pair[1]) ||
          (brideNak == pair[1] && groomNak == pair[0])) {
        return 0.0; // Vedha present
      }
    }
    return 1.0; // No vedha
  }

  static Map<String, dynamic> calculateCompatibility(int bRashi, int bNak, int gRashi, int gNak) {
    double varna = getVarnaScore(bRashi, gRashi);
    double vashya = getVashyaScore(bRashi, gRashi);
    double tara = getTaraScore(bNak, gNak);
    double yoni = getYoniScore(bNak, gNak);
    double graha = getGrahaMaitriScore(bRashi, gRashi);
    double gana = getGanaScore(bNak, gNak);
    double bhakoot = getBhakootScore(bRashi, gRashi);
    double nadi = getNadiScore(bNak, gNak);

    double total = varna + vashya + tara + yoni + graha + gana + bhakoot + nadi;

    return {
      'varna': varna,
      'vashya': vashya,
      'tara': tara,
      'yoni': yoni,
      'graha': graha,
      'gana': gana,
      'bhakoot': bhakoot,
      'nadi': nadi,
      'total': total,
    };
  }

  /// Ashta Koota with Rajju instead of Varna (used by some panchangas)
  /// Kootas: Dina(3), Gana(6), Yoni(4), Rashi(7), Rashyadhipati(5), Vashya(2), Rajju(1), Nadi(8) = 36
  static Map<String, dynamic> calculateCompatibilityRajju(int bRashi, int bNak, int gRashi, int gNak) {
    double dina = getTaraScore(bNak, gNak);           // same as Tara
    double gana = getGanaScore(bNak, gNak);
    double yoni = getYoniScore(bNak, gNak);
    double rashi = getBhakootScore(bRashi, gRashi);    // same as Bhakoot
    double rashyadhipati = getGrahaMaitriScore(bRashi, gRashi);
    double vashya = getVashyaScore(bRashi, gRashi);
    double rajju = getRajjuScore(bNak, gNak);
    double nadi = getNadiScore(bNak, gNak);

    double total = dina + gana + yoni + rashi + rashyadhipati + vashya + rajju + nadi;

    return {
      'dina': dina,
      'gana': gana,
      'yoni': yoni,
      'rashi': rashi,
      'rashyadhipati': rashyadhipati,
      'vashya': vashya,
      'rajju': rajju,
      'nadi': nadi,
      'total': total,
      'isLookup': true,
    };
  }


  /// Dvadasha Koota: 12 kootas, max 40 points
  static Map<String, dynamic> calculateDvadashaKoota(int bRashi, int bNak, int gRashi, int gNak) {
    double varna = getVarnaScore(bRashi, gRashi);
    double vashya = getVashyaScore(bRashi, gRashi);
    double tara = getTaraScore(bNak, gNak);
    double yoni = getYoniScore(bNak, gNak);
    double graha = getGrahaMaitriScore(bRashi, gRashi);
    double gana = getGanaScore(bNak, gNak);
    double bhakoot = getBhakootScore(bRashi, gRashi);
    double nadi = getNadiScore(bNak, gNak);
    double mahendra = getMahendraScore(bNak, gNak);
    double streeDeergha = getStreeDeerghaScore(bNak, gNak);
    double rajju = getRajjuScore(bNak, gNak);
    double vedha = getVedhaScore(bNak, gNak);

    double total = varna + vashya + tara + yoni + graha + gana + bhakoot + nadi +
        mahendra + streeDeergha + rajju + vedha;

    return {
      'varna': varna,
      'vashya': vashya,
      'tara': tara,
      'yoni': yoni,
      'graha': graha,
      'gana': gana,
      'bhakoot': bhakoot,
      'nadi': nadi,
      'mahendra': mahendra,
      'streeDeergha': streeDeergha,
      'rajju': rajju,
      'vedha': vedha,
      'total': total,
    };
  }

  /// Check Kuja Dosha from a reference point (bhava-based)
  static int _kujaHouseCheck(int bhavaHouse) {
    return const [1, 2, 4, 7, 8, 12].contains(bhavaHouse) ? bhavaHouse : 0;
  }

  /// Calculate Kuja Dosha using proper bhava recalculation for each reference
  /// bhavaFromLagna: planet -> bhava house (1-12) from Lagna
  /// bhavaFromChandra: planet -> bhava house (1-12) from Chandra
  /// bhavaFromShukra: planet -> bhava house (1-12) from Shukra
  static Map<String, dynamic> calculateKujaDosha(
    Map<String, int> bhavaFromLagna, {
    Map<String, int>? bhavaFromChandra,
    Map<String, int>? bhavaFromShukra,
  }) {
    // Kuja's bhava house from Lagna
    final fromLagna = _kujaHouseCheck(bhavaFromLagna['ಕುಜ'] ?? 0);
    // Kuja's bhava house from Chandra (proper bhava recalc)
    final fromChandra = _kujaHouseCheck(
      (bhavaFromChandra ?? bhavaFromLagna)['ಕುಜ'] ?? 0);
    // Kuja's bhava house from Shukra (proper bhava recalc)
    final fromShukra = _kujaHouseCheck(
      (bhavaFromShukra ?? bhavaFromLagna)['ಕುಜ'] ?? 0);

    return {
      'fromLagna': fromLagna,
      'fromChandra': fromChandra,
      'fromShukra': fromShukra,
      'hasDosha': fromLagna > 0 || fromChandra > 0 || fromShukra > 0,
    };
  }

  static const List<String> _papaGrahas = ['ರವಿ', 'ಕುಜ', 'ಶನಿ', 'ರಾಹು', 'ಕೇತು'];

  /// Count papa grahas in dosha houses (1,2,4,7,8,12)
  /// Each papa graha counted individually — 2 papas in same house = count 2
  static int _countPapaInDoshaHouses(Map<String, int> bhavaHouses) {
    int count = 0;
    for (final graha in _papaGrahas) {
      final house = bhavaHouses[graha];
      if (house == null) continue;
      if (const [1, 2, 4, 7, 8, 12].contains(house)) count++;
    }
    return count;
  }

  /// Calculate Papa Dosha using proper bhava recalculation for each reference
  static Map<String, dynamic> calculatePapaDosha(
    Map<String, int> bhavaFromLagna, {
    Map<String, int>? bhavaFromChandra,
    Map<String, int>? bhavaFromShukra,
  }) {
    final fromLagna = _countPapaInDoshaHouses(bhavaFromLagna);
    final fromChandra = _countPapaInDoshaHouses(bhavaFromChandra ?? bhavaFromLagna);
    final fromShukra = _countPapaInDoshaHouses(bhavaFromShukra ?? bhavaFromLagna);
    return {
      'fromLagna': fromLagna,
      'fromChandra': fromChandra,
      'fromShukra': fromShukra,
      'total': fromLagna + fromChandra + fromShukra,
    };
  }

  /// Check Papa Samya (balance) between bride and groom
  static Map<String, dynamic> checkPapaSamya(
    Map<String, dynamic> bridePapa,
    Map<String, dynamic> groomPapa,
  ) {
    final bTotal = bridePapa['total'] as int;
    final gTotal = groomPapa['total'] as int;
    final diff = (bTotal - gTotal).abs();
    return {
      'bridePapaTotal': bTotal,
      'groomPapaTotal': gTotal,
      'difference': diff,
      'isSamya': diff <= 1,
    };
  }

  /// Naisargika (Natural) Maitri table per Brihad Jataka
  /// 0=Sun, 1=Moon, 2=Mars, 3=Mercury, 4=Jupiter, 5=Venus, 6=Saturn
  /// Values: 1=Mitra, 0=Sama, -1=Shatru
  static const List<List<int>> _naisargikaMaitri = [
    //        Sun  Moon Mars Merc Jup  Ven  Sat
    /* Sun */  [ 0,  1,  1,  0,  1, -1, -1],
    /* Moon */ [ 1,  0,  0,  1,  0,  0,  0],
    /* Mars */ [ 1,  1,  0, -1,  1,  0,  0],
    /* Merc */ [ 1, -1,  0,  0,  0,  1,  0],
    /* Jup */  [ 1,  1,  1, -1,  0, -1,  0],
    /* Ven */  [-1, -1,  0,  1,  0,  0,  1],
    /* Sat */  [-1, -1, -1,  1,  0,  1,  0],
  ];

  /// Get planet lord index (0-6) for a rashi (0-11)
  static int getRashiLord(int rashi) {
    const lords = [2, 5, 3, 1, 0, 3, 5, 2, 4, 6, 6, 4];
    return lords[rashi];
  }

  /// Planet names for lord indices
  static const List<String> lordNames = ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ'];

  /// Get Naisargika Maitri relationship string
  static String getNaisargikaMaitriLabel(int planet1Lord, int planet2Lord) {
    if (planet1Lord == planet2Lord) return 'ಏಕಾಧಿಪತ್ಯ';
    final val = _naisargikaMaitri[planet1Lord][planet2Lord];
    if (val == 1) return 'ಮಿತ್ರ';
    if (val == -1) return 'ಶತ್ರು';
    return 'ಸಮ';
  }

  /// Calculate Graha Maitri (Natural only) for Lagna/Chandra from Rashi and Navamsha
  static Map<String, dynamic> calculateGrahaMaitriComparison({
    required int brideLagnaRashi,
    required int brideMoonRashi,
    required int brideNavLagnaRashi,
    required int brideNavMoonRashi,
    required int groomLagnaRashi,
    required int groomMoonRashi,
    required int groomNavLagnaRashi,
    required int groomNavMoonRashi,
  }) {
    Map<String, dynamic> _check(String label, int bRashi, int gRashi) {
      final bLord = getRashiLord(bRashi);
      final gLord = getRashiLord(gRashi);
      String maitri;
      int relation;
      if (bLord == gLord) {
        maitri = 'ಏಕಾಧಿಪತ್ಯ';
        relation = 2; // Ekadhipatya
      } else {
        relation = _naisargikaMaitri[bLord][gLord];
        if (relation == 1) maitri = 'ಮಿತ್ರ';
        else if (relation == -1) maitri = 'ಶತ್ರು';
        else maitri = 'ಸಮ';
      }
      return {
        'label': label,
        'brideLord': bLord,
        'groomLord': gLord,
        'brideLordName': lordNames[bLord],
        'groomLordName': lordNames[gLord],
        'relation': relation,
        'maitri': maitri,
      };
    }

    return {
      'rows': [
        _check('ಲಗ್ನಾಧಿಪತಿ', brideLagnaRashi, groomLagnaRashi),
        _check('ಚಂದ್ರ ರಾಶ್ಯಾಧಿಪತಿ', brideMoonRashi, groomMoonRashi),
        _check('ನವಾಂಶ ಲಗ್ನಾಧಿಪತಿ', brideNavLagnaRashi, groomNavLagnaRashi),
        _check('ನವಾಂಶ ಚಂದ್ರಾಧಿಪತಿ', brideNavMoonRashi, groomNavMoonRashi),
      ],
    };
  }

  /// Compute Navamsha rashi index from sidereal longitude
  static int navamshaRashi(double deg) {
    final block = (deg / 30).floor() % 4;
    final start = [0, 9, 6, 3][block];
    final steps = ((deg % 30) / 3.33333).floor();
    return (start + steps) % 12;
  }

  /// Helper: check if two rashis are in a given house relationship
  static Map<String, dynamic> _checkHouseRelation(int brideRashi, int groomRashi, List<int> doshaHouses) {
    final brideFromGroom = ((brideRashi - groomRashi + 12) % 12) + 1;
    final groomFromBride = ((groomRashi - brideRashi + 12) % 12) + 1;
    final hasDosha = doshaHouses.contains(brideFromGroom) || doshaHouses.contains(groomFromBride);
    return {
      'hasDosha': hasDosha,
      'brideFromGroom': brideFromGroom,
      'groomFromBride': groomFromBride,
    };
  }

  /// Check Shatha Ashtaka Dosha (6/8 relationship) from Chandra and Lagna
  static Map<String, dynamic> checkShathaAshtaka(int brideMoonRashi, int groomMoonRashi, int brideLagnaRashi, int groomLagnaRashi) {
    final fromChandra = _checkHouseRelation(brideMoonRashi, groomMoonRashi, const [6, 8]);
    final fromLagna = _checkHouseRelation(brideLagnaRashi, groomLagnaRashi, const [6, 8]);
    return {
      'fromChandra': fromChandra,
      'fromLagna': fromLagna,
      'hasDosha': fromChandra['hasDosha'] || fromLagna['hasDosha'],
    };
  }

  /// Check Dvirdvadasha Dosha (2/12 relationship) from Chandra and Lagna
  static Map<String, dynamic> checkDvirdvadasha(int brideMoonRashi, int groomMoonRashi, int brideLagnaRashi, int groomLagnaRashi) {
    final fromChandra = _checkHouseRelation(brideMoonRashi, groomMoonRashi, const [2, 12]);
    final fromLagna = _checkHouseRelation(brideLagnaRashi, groomLagnaRashi, const [2, 12]);
    return {
      'fromChandra': fromChandra,
      'fromLagna': fromLagna,
      'hasDosha': fromChandra['hasDosha'] || fromLagna['hasDosha'],
    };
  }


  /// Baggona (Vishvavsu) Panchanga - Ashta Koota total points lookup table
  /// 27x27 grid: rows = bride nakshatra (0-26), cols = groom nakshatra (0-26)
  /// Source: Pages 87-88 of Baggona/Vishvavsu Panchanga
  static const List<List<int>> _baggonaTable = [

    [28, 33, 27, 17, 23, 22, 25, 16, 17, 22, 30, 27, 20, 24, 14, 9, 10, 12, 22, 28, 22, 18, 24, 13, 12, 24, 23, 25, 26, 20, 19, 14, 15, 14, 23, 26], // 0-Ashvini(Me)

    [33, 27, 28, 18, 26, 14, 7, 25, 25, 30, 22, 24, 19, 17, 24, 19, 18, 13, 13, 28, 21, 18, 17, 19, 19, 17, 25, 27, 26, 10, 9, 19, 23, 22, 16, 25], // 1-Bharani(Me)

    [26, 27, 28, 18, 10, 16, 19, 19, 19, 24, 26, 22, 15, 19, 20, 15, 14, 17, 27, 14, 19, 16, 19, 25, 25, 19, 11, 13, 13, 25, 24, 25, 18, 17, 19, 10], // 2-Krittika(Me)

    [19, 19, 19, 28, 18, 26, 17, 17, 17, 21, 23, 19, 19, 21, 22, 20, 18, 23, 22, 9, 14, 21, 24, 30, 22, 15, 7, 12, 10, 24, 29, 30, 23, 20, 22, 13], // 3-Krittika(Vr)

    [23, 23, 11, 20, 28, 36, 26, 23, 22, 26, 27, 12, 10, 24, 27, 25, 25, 18, 17, 15, 8, 14, 29, 23, 13, 19, 11, 16, 18, 19, 24, 24, 29, 26, 27, 19], // 4-Rohini(Vr)

    [27, 14, 18, 27, 35, 28, 18, 23, 22, 26, 19, 21, 19, 25, 24, 23, 25, 11, 10, 24, 17, 23, 21, 24, 14, 10, 16, 21, 26, 12, 17, 26, 28, 25, 18, 27], // 5-Mrigashira(Vr)

    [26, 17, 21, 19, 26, 19, 28, 33, 31, 18, 11, 13, 22, 18, 27, 32, 34, 20, 13, 27, 19, 13, 13, 14, 23, 19, 25, 19, 24, 10, 12, 21, 22, 24, 17, 26], // 6-Mrigashira(Mi)

    [18, 26, 21, 19, 24, 25, 34, 28, 25, 12, 20, 12, 21, 27, 20, 24, 24, 27, 20, 27, 20, 13, 19, 5, 15, 28, 27, 21, 22, 17, 19, 12, 17, 18, 26, 26], // 7-Ardra(Mi)

    [18, 25, 21, 19, 22, 23, 31, 24, 28, 14, 21, 15, 21, 25, 19, 23, 24, 26, 19, 27, 21, 14, 20, 6, 14, 27, 27, 21, 22, 16, 18, 13, 16, 17, 26, 26], // 8-Punarvasu(Mi)

    [21, 28, 24, 21, 24, 25, 17, 10, 13, 28, 34, 28, 16, 20, 14, 16, 17, 19, 19, 26, 20, 19, 25, 10, 7, 20, 20, 26, 27, 21, 12, 5, 9, 16, 25, 24], // 9-Punarvasu(Ka)

    [29, 20, 26, 23, 25, 18, 10, 18, 24, 34, 28, 29, 18, 14, 12, 15, 25, 11, 11, 25, 20, 19, 17, 20, 17, 12, 20, 26, 27, 13, 4, 13, 17, 26, 18, 26], // 10-Pushya(Ka)

    [25, 23, 21, 18, 11, 19, 11, 11, 12, 27, 28, 28, 15, 15, 17, 19, 19, 24, 24, 11, 16, 14, 19, 25, 22, 15, 7, 13, 13, 26, 17, 18, 11, 17, 20, 12], // 11-Ashlesha(Ka)

    [19, 19, 15, 16, 9, 18, 20, 20, 19, 16, 18, 16, 28, 30, 26, 14, 14, 19, 23, 10, 15, 24, 24, 32, 24, 19, 8, 3, 4, 17, 23, 24, 17, 17, 18, 12], // 12-Magha(Si)

    [25, 17, 19, 20, 23, 15, 18, 26, 25, 22, 16, 16, 30, 28, 34, 24, 20, 5, 9, 24, 17, 23, 22, 24, 20, 17, 24, 19, 18, 5, 9, 19, 23, 23, 16, 24], // 13-P.Phalguni(Si)

    [15, 25, 20, 20, 26, 24, 27, 19, 17, 14, 25, 18, 26, 34, 28, 16, 15, 12, 16, 25, 16, 22, 30, 16, 9, 25, 25, 20, 20, 11, 17, 10, 15, 15, 26, 24], // 14-U.Phalguni(Si)

    [11, 21, 16, 20, 25, 24, 31, 21, 23, 17, 17, 20, 15, 23, 17, 28, 27, 24, 16, 25, 16, 18, 26, 12, 14, 29, 29, 24, 24, 15, 16, 9, 14, 17, 28, 26], // 15-U.Phalguni(Kn)

    [11, 18, 16, 20, 23, 24, 32, 18, 23, 18, 26, 22, 16, 20, 15, 26, 28, 28, 20, 26, 18, 20, 26, 13, 15, 27, 28, 23, 24, 18, 19, 10, 13, 16, 26, 26], // 16-Hasta(Kn)

    [12, 14, 18, 23, 18, 10, 18, 22, 24, 21, 11, 25, 20, 6, 13, 24, 27, 28, 19, 19, 25, 27, 11, 25, 27, 13, 21, 15, 17, 15, 16, 24, 16, 19, 10, 19], // 17-Chitra(Kn)

    [22, 14, 28, 23, 18, 10, 12, 20, 18, 19, 11, 25, 24, 10, 17, 27, 20, 20, 28, 27, 33, 22, 6, 20, 27, 13, 21, 23, 25, 23, 18, 26, 18, 12, 3, 12], // 18-Chitra(Tu)

    [29, 28, 16, 11, 14, 24, 26, 26, 27, 27, 26, 13, 12, 24, 25, 25, 27, 21, 28, 28, 20, 9, 21, 16, 23, 27, 19, 21, 22, 26, 21, 22, 25, 18, 19, 11], // 19-Swati(Tu)

    [21, 22, 20, 15, 9, 17, 18, 20, 20, 20, 20, 17, 16, 19, 17, 17, 18, 26, 33, 19, 28, 16, 16, 21, 27, 21, 13, 25, 15, 29, 24, 26, 20, 13, 12, 4], // 20-Vishakha(Tu)

    [16, 16, 14, 19, 13, 21, 11, 12, 12, 18, 18, 14, 24, 22, 21, 17, 18, 26, 21, 7, 15, 28, 27, 31, 21, 15, 7, 11, 11, 25, 24, 25, 19, 19, 18, 9], // 21-Vishakha(Vs)

    [23, 14, 18, 23, 22, 20, 10, 15, 19, 25, 17, 20, 24, 20, 28, 24, 25, 11, 6, 20, 16, 28, 28, 31, 15, 13, 21, 25, 26, 12, 11, 20, 24, 24, 17, 26], // 22-Anuradha(Vs)

    [10, 17, 23, 28, 22, 29, 12, 2, 4, 9, 19, 25, 31, 23, 15, 11, 11, 24, 19, 14, 19, 31, 30, 28, 14, 16, 16, 20, 20, 25, 24, 17, 10, 9, 20, 20], // 23-Jyeshtha(Vs)

    [11, 19, 25, 19, 12, 12, 20, 14, 12, 7, 17, 23, 24, 18, 9, 13, 13, 26, 26, 21, 26, 22, 16, 16, 28, 28, 15, 13, 14, 19, 28, 21, 14, 16, 24, 26], // 24-Moola(Dh)

    [25, 17, 19, 14, 18, 10, 19, 26, 27, 22, 14, 16, 19, 17, 25, 28, 27, 12, 12, 27, 20, 16, 15, 17, 27, 28, 34, 23, 22, 5, 14, 23, 28, 29, 22, 30], // 25-P.Shadha(Dh)

    [24, 25, 11, 6, 10, 16, 25, 16, 27, 22, 22, 8, 8, 24, 25, 28, 28, 20, 20, 19, 12, 8, 23, 17, 25, 35, 28, 16, 15, 13, 22, 23, 28, 29, 30, 22], // 26-U.Shadha(Dh)

    [27, 28, 14, 12, 16, 22, 19, 24, 21, 28, 28, 14, 4, 20, 21, 24, 24, 15, 22, 21, 14, 12, 27, 21, 14, 24, 27, 28, 27, 25, 15, 16, 21, 29, 30, 22], // 27-U.Shadha(Mk)

    [28, 26, 14, 12, 17, 26, 23, 19, 21, 28, 28, 14, 5, 18, 20, 23, 24, 17, 24, 21, 14, 12, 27, 21, 14, 22, 15, 26, 28, 27, 17, 17, 20, 28, 29, 23], // 28-Shravana(Mk)

    [20, 11, 26, 23, 19, 11, 8, 16, 14, 21, 13, 27, 19, 4, 10, 15, 17, 15, 29, 24, 28, 26, 12, 26, 20, 6, 14, 25, 27, 28, 17, 33, 17, 24, 15, 22], // 29-Dhanishtha(Mk)

    [19, 10, 25, 30, 25, 17, 11, 18, 17, 12, 4, 18, 24, 10, 18, 17, 19, 17, 18, 20, 24, 25, 11, 25, 29, 15, 23, 16, 18, 18, 28, 33, 27, 16, 6, 13], // 30-Dhanishtha(Ku)

    [14, 20, 26, 31, 25, 26, 20, 12, 12, 6, 13, 19, 25, 19, 11, 10, 10, 25, 26, 21, 26, 26, 20, 18, 22, 24, 24, 17, 17, 24, 33, 28, 29, 8, 24, 15], // 31-Shatabhisha(Ku)

    [17, 24, 19, 24, 30, 30, 23, 17, 17, 11, 19, 12, 18, 24, 16, 15, 15, 17, 18, 26, 20, 20, 26, 11, 15, 29, 29, 22, 22, 28, 27, 19, 28, 16, 22, 19], // 32-P.Bhadra(Ku)

    [14, 21, 16, 19, 25, 25, 24, 17, 17, 17, 25, 17, 16, 22, 14, 16, 16, 18, 11, 18, 12, 19, 25, 9, 14, 18, 28, 28, 28, 24, 15, 7, 15, 28, 33, 30], // 33-P.Bhadra(Mn)

    [23, 15, 18, 21, 26, 28, 17, 25, 26, 26, 19, 20, 17, 12, 25, 27, 26, 9, 2, 19, 11, 18, 18, 20, 23, 21, 29, 29, 29, 14, 5, 24, 21, 33, 28, 33], // 34-U.Bhadra(Mn)

    [25, 23, 10, 13, 17, 26, 25, 24, 25, 24, 26, 13, 12, 12, 22, 24, 25, 19, 12, 10, 4, 10, 26, 21, 26, 28, 20, 23, 21, 22, 13, 15, 17, 29, 33, 28], // 35-Revati(Mn)

  ];



  static const List<List<int>> _mogeryTable = [

    [28, 33, 27, 17, 23, 22, 25, 16, 17, 22, 30, 27, 20, 24, 14, 9, 10, 12, 22, 28, 22, 18, 24, 13, 12, 24, 23, 25, 26, 20, 19, 14, 15, 14, 23, 26], // 0-Ashvini(Me)

    [33, 28, 28, 18, 26, 14, 27, 25, 25, 30, 22, 24, 19, 17, 24, 19, 18, 3, 13, 28, 21, 18, 17, 19, 19, 17, 25, 27, 26, 10, 9, 19, 23, 22, 16, 25], // 1-Bharani(Me)

    [26, 28, 28, 18, 10, 16, 19, 19, 19, 24, 26, 22, 15, 19, 20, 15, 14, 17, 27, 14, 19, 16, 19, 25, 25, 19, 11, 13, 13, 25, 24, 25, 18, 17, 19, 10], // 2-Krittika(Me)

    [19, 19, 19, 28, 18, 26, 17, 17, 17, 21, 23, 19, 19, 21, 22, 20, 18, 23, 22, 9, 14, 21, 24, 30, 22, 15, 7, 12, 10, 24, 29, 30, 23, 20, 22, 13], // 3-Krittika(Vr)

    [23, 23, 11, 20, 28, 36, 26, 23, 22, 26, 27, 12, 10, 24, 27, 25, 25, 18, 17, 15, 8, 14, 29, 23, 13, 19, 11, 16, 18, 19, 24, 24, 29, 26, 27, 19], // 4-Rohini(Vr)

    [27, 14, 18, 27, 35, 28, 18, 23, 22, 26, 19, 21, 19, 25, 24, 23, 25, 11, 10, 24, 17, 23, 21, 24, 14, 10, 16, 21, 26, 12, 17, 26, 28, 25, 18, 27], // 5-Mrigashira(Vr)

    [26, 17, 21, 19, 26, 19, 28, 33, 31, 18, 11, 13, 22, 18, 27, 32, 34, 20, 13, 27, 19, 13, 13, 14, 23, 19, 25, 19, 24, 10, 12, 21, 22, 24, 17, 26], // 6-Mrigashira(Mi)

    [18, 26, 21, 19, 24, 25, 34, 28, 25, 12, 20, 12, 21, 27, 20, 24, 24, 27, 20, 27, 20, 13, 19, 5, 15, 28, 27, 21, 22, 17, 19, 12, 17, 18, 26, 26], // 7-Ardra(Mi)

    [18, 25, 21, 19, 22, 23, 31, 24, 28, 14, 21, 15, 21, 25, 19, 23, 24, 26, 19, 27, 21, 14, 20, 6, 14, 27, 27, 21, 22, 16, 18, 13, 16, 17, 26, 26], // 8-Punarvasu(Mi)

    [21, 28, 24, 21, 24, 25, 17, 10, 13, 28, 34, 28, 16, 20, 14, 16, 17, 19, 19, 26, 20, 19, 25, 10, 7, 20, 20, 26, 27, 21, 12, 5, 9, 16, 25, 24], // 9-Punarvasu(Ka)

    [29, 20, 26, 23, 25, 18, 10, 18, 24, 34, 28, 29, 18, 14, 12, 15, 25, 11, 11, 25, 20, 19, 17, 20, 17, 12, 20, 26, 27, 13, 4, 13, 17, 26, 18, 26], // 10-Pushya(Ka)

    [25, 23, 21, 18, 11, 19, 11, 11, 12, 27, 28, 28, 15, 15, 17, 19, 19, 24, 24, 11, 16, 14, 19, 25, 22, 15, 7, 13, 13, 26, 17, 18, 11, 17, 20, 12], // 11-Ashlesha(Ka)

    [19, 19, 15, 16, 9, 18, 20, 20, 19, 16, 18, 16, 28, 30, 26, 14, 14, 19, 23, 10, 15, 24, 24, 32, 24, 19, 8, 3, 4, 17, 23, 24, 17, 17, 18, 12], // 12-Magha(Si)

    [25, 17, 19, 20, 23, 15, 18, 26, 25, 22, 16, 16, 30, 28, 34, 24, 20, 5, 9, 24, 17, 23, 22, 24, 20, 17, 24, 19, 18, 5, 9, 19, 23, 23, 16, 24], // 13-P.Phalguni(Si)

    [15, 25, 20, 21, 26, 24, 27, 19, 17, 14, 25, 18, 26, 34, 28, 16, 15, 12, 16, 25, 16, 22, 30, 16, 9, 25, 25, 20, 20, 11, 17, 10, 15, 15, 26, 24], // 14-U.Phalguni(Si)

    [11, 21, 16, 20, 25, 24, 31, 21, 23, 17, 17, 20, 15, 23, 17, 28, 27, 24, 16, 25, 16, 18, 26, 12, 14, 29, 29, 24, 24, 15, 16, 9, 14, 17, 28, 26], // 15-U.Phalguni(Kn)

    [11, 18, 16, 20, 23, 24, 32, 18, 23, 18, 26, 22, 16, 20, 15, 26, 28, 28, 20, 26, 18, 20, 26, 13, 15, 27, 28, 23, 24, 18, 19, 10, 13, 16, 26, 26], // 16-Hasta(Kn)

    [12, 14, 18, 23, 18, 10, 18, 22, 24, 21, 11, 25, 20, 6, 13, 24, 27, 28, 19, 19, 25, 27, 11, 25, 27, 13, 21, 15, 17, 15, 16, 24, 16, 19, 10, 19], // 17-Chitra(Kn)

    [22, 14, 28, 23, 18, 10, 12, 20, 18, 19, 11, 25, 24, 10, 17, 27, 20, 20, 28, 27, 33, 22, 6, 20, 27, 13, 21, 23, 25, 23, 18, 26, 18, 12, 3, 12], // 18-Chitra(Tu)

    [29, 28, 16, 11, 14, 24, 26, 26, 27, 27, 26, 13, 12, 24, 25, 25, 27, 21, 28, 28, 20, 9, 21, 16, 23, 27, 19, 21, 22, 26, 21, 22, 25, 18, 19, 11], // 19-Swati(Tu)

    [21, 22, 20, 15, 9, 17, 18, 20, 20, 20, 20, 17, 16, 19, 17, 17, 18, 26, 33, 19, 28, 16, 16, 21, 27, 21, 13, 15, 15, 29, 24, 26, 20, 13, 12, 4], // 20-Vishakha(Tu)

    [16, 16, 14, 19, 13, 21, 11, 12, 12, 18, 18, 14, 24, 22, 21, 17, 18, 26, 21, 7, 15, 28, 27, 31, 21, 15, 7, 11, 11, 25, 24, 25, 19, 19, 18, 9], // 21-Vishakha(Vs)

    [22, 14, 18, 23, 22, 20, 10, 15, 19, 25, 17, 20, 24, 20, 28, 24, 25, 11, 6, 20, 16, 28, 28, 31, 15, 13, 21, 15, 26, 12, 11, 20, 24, 24, 17, 26], // 22-Anuradha(Vs)

    [10, 17, 23, 28, 22, 29, 12, 2, 4, 9, 19, 25, 31, 23, 15, 11, 11, 24, 19, 14, 19, 31, 30, 28, 14, 16, 16, 20, 20, 25, 24, 17, 10, 9, 20, 20], // 23-Jyeshtha(Vs)

    [11, 19, 25, 19, 12, 12, 20, 14, 12, 7, 17, 23, 24, 18, 9, 13, 13, 26, 26, 21, 26, 22, 16, 16, 28, 28, 15, 13, 14, 19, 28, 21, 14, 16, 24, 26], // 24-Moola(Dh)

    [25, 17, 19, 14, 18, 10, 19, 26, 27, 22, 14, 16, 19, 17, 25, 28, 27, 12, 12, 27, 20, 16, 15, 17, 27, 28, 34, 23, 22, 5, 14, 23, 28, 29, 22, 30], // 25-P.Shadha(Dh)

    [24, 25, 11, 6, 10, 16, 25, 16, 27, 22, 22, 8, 8, 24, 25, 28, 28, 20, 20, 19, 12, 8, 23, 17, 25, 35, 28, 16, 15, 13, 22, 23, 28, 29, 30, 22], // 26-U.Shadha(Dh)

    [27, 28, 14, 12, 16, 22, 19, 24, 21, 28, 28, 14, 4, 20, 21, 24, 24, 15, 22, 21, 14, 12, 27, 21, 14, 24, 27, 28, 27, 25, 15, 16, 21, 29, 30, 22], // 27-U.Shadha(Mk)

    [28, 26, 14, 12, 17, 26, 23, 19, 21, 28, 28, 14, 5, 18, 20, 23, 24, 17, 24, 21, 14, 12, 27, 21, 14, 22, 15, 26, 28, 27, 17, 17, 20, 28, 29, 23], // 28-Shravana(Mk)

    [20, 11, 26, 23, 19, 11, 8, 16, 14, 21, 13, 27, 19, 4, 10, 15, 17, 15, 29, 24, 28, 26, 12, 26, 20, 6, 14, 25, 27, 28, 17, 33, 17, 24, 15, 22], // 29-Dhanishtha(Mk)

    [19, 10, 25, 30, 25, 17, 11, 18, 17, 12, 4, 18, 24, 10, 18, 17, 19, 17, 18, 20, 24, 25, 11, 25, 29, 15, 23, 16, 18, 18, 28, 33, 27, 16, 6, 13], // 30-Dhanishtha(Ku)

    [14, 20, 26, 31, 25, 26, 20, 12, 12, 6, 13, 19, 25, 19, 11, 10, 10, 25, 26, 21, 26, 26, 20, 18, 22, 24, 24, 17, 17, 24, 33, 28, 29, 8, 24, 15], // 31-Shatabhisha(Ku)

    [17, 24, 19, 24, 30, 30, 23, 17, 17, 11, 19, 12, 18, 24, 16, 15, 15, 17, 18, 26, 20, 20, 26, 11, 15, 29, 29, 22, 22, 28, 27, 19, 28, 16, 22, 19], // 32-P.Bhadra(Ku)

    [14, 21, 16, 19, 25, 25, 24, 17, 17, 17, 25, 17, 16, 22, 14, 16, 16, 18, 11, 18, 12, 19, 25, 9, 14, 18, 28, 28, 28, 24, 15, 7, 15, 28, 33, 30], // 33-P.Bhadra(Mn)

    [23, 15, 18, 21, 26, 28, 17, 25, 26, 26, 19, 20, 17, 12, 25, 27, 26, 9, 2, 19, 11, 18, 18, 20, 23, 21, 29, 29, 29, 14, 5, 24, 21, 33, 28, 33], // 34-U.Bhadra(Mn)

    [25, 23, 10, 13, 17, 26, 25, 24, 25, 24, 26, 13, 12, 12, 22, 24, 25, 19, 12, 10, 4, 10, 26, 21, 26, 28, 20, 23, 21, 22, 13, 15, 17, 29, 33, 28], // 35-Revati(Mn)

  ];



  /// Map (nakshatra 0-26, moonRashi 0-11) -> 36-row table index

  static int _getTableIndex(int nak, int rashi) {

    // Split nakshatras: their rashi determines which row to use.

    // Non-split nakshatras have a fixed index regardless of rashi.

    const splitNaks = {

      2: [0, 2, 1, 3], // Krittika

      4: [1, 5, 2, 6], // Mrigashira

      6: [2, 8, 3, 9], // Punarvasu

      11: [4, 14, 5, 15], // U.Phalguni

      13: [5, 17, 6, 18], // Chitra

      15: [6, 20, 7, 21], // Vishakha

      20: [8, 26, 9, 27], // U.Shadha

      22: [9, 29, 10, 30], // Dhanishtha

      24: [10, 32, 11, 33], // P.Bhadra

    };

    const fixedIdx = {

      0: 0, // Ashvini

      1: 1, // Bharani

      3: 4, // Rohini

      5: 7, // Ardra

      7: 10, // Pushya

      8: 11, // Ashlesha

      9: 12, // Magha

      10: 13, // P.Phalguni

      12: 16, // Hasta

      14: 19, // Swati

      16: 22, // Anuradha

      17: 23, // Jyeshtha

      18: 24, // Moola

      19: 25, // P.Shadha

      21: 28, // Shravana

      23: 31, // Shatabhisha

      25: 34, // U.Bhadra

      26: 35, // Revati

    };

    final n = nak % 27;

    final r = rashi % 12;

    if (splitNaks.containsKey(n)) {

      final s = splitNaks[n]!;

      return r == s[2] ? s[3] : s[1];

    }

    return fixedIdx[n] ?? 0;

  }



  /// Look up Baggona panchanga total koota points

  static Map<String, dynamic> calculateCompatibilityBaggona(int bNak, int gNak, int bRashi, int gRashi) {

    final bIdx = _getTableIndex(bNak, bRashi);

    final gIdx = _getTableIndex(gNak, gRashi);

    final total = _baggonaTable[bIdx][gIdx].toDouble();

    return {

      'total': total,

      'isLookup': true,

    };

  }



  /// Look up Mogery panchanga total koota points

  static Map<String, dynamic> calculateCompatibilityMogery(int bNak, int gNak, int bRashi, int gRashi) {

    final bIdx = _getTableIndex(bNak, bRashi);

    final gIdx = _getTableIndex(gNak, gRashi);

    final total = _mogeryTable[bIdx][gIdx].toDouble();

    return {

      'total': total,

      'isLookup': true,

    };

  }





  /// Full compatibility analysis using KundaliResult data
  static Map<String, dynamic> calculateFullCompatibility({
    required int brideNakIdx,
    required int brideMoonRashi,
    required int brideLagnaRashi,
    required Map<String, int> bridePlanetRashis,
    required int brideNavLagnaRashi,
    required int brideNavMoonRashi,
    required int groomNakIdx,
    required int groomMoonRashi,
    required int groomLagnaRashi,
    required Map<String, int> groomPlanetRashis,
    required int groomNavLagnaRashi,
    required int groomNavMoonRashi,
    Map<String, int>? brideBhavaHouses,
    Map<String, int>? groomBhavaHouses,
    Map<String, int>? brideBhavaFromChandra,
    Map<String, int>? groomBhavaFromChandra,
    Map<String, int>? brideBhavaFromShukra,
    Map<String, int>? groomBhavaFromShukra,
    int panchangaMode = 0,
  }) {
    // Use bhava houses for dosha if available, fallback to rashi-based
    final bBhava = brideBhavaHouses ?? bridePlanetRashis;
    final gBhava = groomBhavaHouses ?? groomPlanetRashis;
    return {
      'ashtaKoota': panchangaMode == 2
          ? calculateCompatibilityBaggona(brideNakIdx, groomNakIdx, brideMoonRashi, groomMoonRashi)
          : panchangaMode == 1
              ? calculateCompatibilityMogery(brideNakIdx, groomNakIdx, brideMoonRashi, groomMoonRashi)
              : calculateCompatibility(brideMoonRashi, brideNakIdx, groomMoonRashi, groomNakIdx),
      'dvadashaKoota': calculateDvadashaKoota(brideMoonRashi, brideNakIdx, groomMoonRashi, groomNakIdx),
      'brideKujaDosha': calculateKujaDosha(bBhava,
        bhavaFromChandra: brideBhavaFromChandra, bhavaFromShukra: brideBhavaFromShukra),
      'groomKujaDosha': calculateKujaDosha(gBhava,
        bhavaFromChandra: groomBhavaFromChandra, bhavaFromShukra: groomBhavaFromShukra),
      'bridePapaDosha': calculatePapaDosha(bBhava,
        bhavaFromChandra: brideBhavaFromChandra, bhavaFromShukra: brideBhavaFromShukra),
      'groomPapaDosha': calculatePapaDosha(gBhava,
        bhavaFromChandra: groomBhavaFromChandra, bhavaFromShukra: groomBhavaFromShukra),
      'papaSamya': checkPapaSamya(
        calculatePapaDosha(bBhava,
          bhavaFromChandra: brideBhavaFromChandra, bhavaFromShukra: brideBhavaFromShukra),
        calculatePapaDosha(gBhava,
          bhavaFromChandra: groomBhavaFromChandra, bhavaFromShukra: groomBhavaFromShukra),
      ),
      'grahaMaitri': calculateGrahaMaitriComparison(
        brideLagnaRashi: brideLagnaRashi, brideMoonRashi: brideMoonRashi,
        brideNavLagnaRashi: brideNavLagnaRashi, brideNavMoonRashi: brideNavMoonRashi,
        groomLagnaRashi: groomLagnaRashi, groomMoonRashi: groomMoonRashi,
        groomNavLagnaRashi: groomNavLagnaRashi, groomNavMoonRashi: groomNavMoonRashi,
      ),
      'shathaAshtaka': checkShathaAshtaka(brideMoonRashi, groomMoonRashi, brideLagnaRashi, groomLagnaRashi),
      'dvirdvadasha': checkDvirdvadasha(brideMoonRashi, groomMoonRashi, brideLagnaRashi, groomLagnaRashi),
    };
  }
}
