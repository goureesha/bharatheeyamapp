/// Baby name suggestions for each nakshatra pada syllable.
/// Maps each syllable to a list of boy names and girl names.
/// Names are traditional Kannada/Sanskrit names.

class BabyNameEntry {
  final List<String> boyNames;
  final List<String> girlNames;
  const BabyNameEntry({required this.boyNames, required this.girlNames});
}

const Map<String, BabyNameEntry> babyNameSuggestions = {
  // ── 0. Ashwini ──
  'ಚು': BabyNameEntry(
    boyNames: ['ಚುಂಬಕ', 'ಚುತೇಶ', 'ಚುಂದ', 'ಚುಟ್ಟು'],
    girlNames: ['ಚುಕ್ಕಿ', 'ಚುಂಬಿನಿ', 'ಚುಳುಕಿ'],
  ),
  'ಚೇ': BabyNameEntry(
    boyNames: ['ಚೇತನ', 'ಚೇತಸ್', 'ಚೇಳ', 'ಚೇಕಿತಾನ'],
    girlNames: ['ಚೇತನಾ', 'ಚೇತಸ್ವಿನಿ', 'ಚೇಳಮ್ಮ', 'ಚೇಕಿತಾ'],
  ),
  'ಚೋ': BabyNameEntry(
    boyNames: ['ಚೋಳ', 'ಚೋಳೇಶ', 'ಚೋಳನಾಥ'],
    girlNames: ['ಚೋಳಮ್ಮ', 'ಚೋಳಾಂಬಿಕಾ'],
  ),
  'ಲಾ': BabyNameEntry(
    boyNames: ['ಲಾವಣ್ಯ', 'ಲಾಲ', 'ಲಾಲಿತ', 'ಲಾಲಕೇಶ'],
    girlNames: ['ಲಾವಣ್ಯ', 'ಲಾಲಿತಾ', 'ಲಾಕ್ಷಿ', 'ಲಾಲಸಾ', 'ಲಾಸ್ಯ'],
  ),

  // ── 1. Bharani ──
  'ಲೀ': BabyNameEntry(
    boyNames: ['ಲೀಲಾಧರ', 'ಲೀಲಾಕರ', 'ಲೀಲೇಶ'],
    girlNames: ['ಲೀಲಾ', 'ಲೀಲಾವತಿ', 'ಲೀನಾ', 'ಲೀಮಾ'],
  ),
  'ಲೂ': BabyNameEntry(
    boyNames: ['ಲೂಥರ್', 'ಲೂಕಸ್'],
    girlNames: ['ಲೂನಾ', 'ಲೂಸಿ'],
  ),
  'ಲೇ': BabyNameEntry(
    boyNames: ['ಲೇಖನ', 'ಲೇಖಕ'],
    girlNames: ['ಲೇಖಾ', 'ಲೇಖನಾ', 'ಲೇಕಿನಿ'],
  ),
  'ಲೋ': BabyNameEntry(
    boyNames: ['ಲೋಕೇಶ', 'ಲೋಕನಾಥ', 'ಲೋಹಿತ', 'ಲೋಕಪಾಲ'],
    girlNames: ['ಲೋಕಮಾತಾ', 'ಲೋಹಿನಿ', 'ಲೋಚನಾ', 'ಲೋಕಸುಂದರಿ'],
  ),

  // ── 2. Krittika ──
  'ಅ': BabyNameEntry(
    boyNames: ['ಅಭಿಷೇಕ', 'ಅನಿಲ', 'ಅಮಿತ', 'ಅಶೋಕ', 'ಅರುಣ', 'ಅಜಯ', 'ಅಕ್ಷಯ', 'ಅಮರ', 'ಅನಂತ', 'ಅಭಿಜಿತ್'],
    girlNames: ['ಅನಿತಾ', 'ಅಮೃತಾ', 'ಅಕ್ಷತಾ', 'ಅಂಜಲಿ', 'ಅನುಷಾ', 'ಅಶ್ವಿನಿ', 'ಅಪರ್ಣಾ', 'ಅಮಿತಾ', 'ಅನುಪಮಾ', 'ಅರ್ಚನಾ'],
  ),
  'ಈ': BabyNameEntry(
    boyNames: ['ಈಶ್ವರ', 'ಈಶಾನ', 'ಈಶ'],
    girlNames: ['ಈಶ್ವರಿ', 'ಈಪ್ಸಿತಾ', 'ಈಶಾನಿ', 'ಈರಮ್ಮ'],
  ),
  'ಉ': BabyNameEntry(
    boyNames: ['ಉದಯ', 'ಉಮೇಶ', 'ಉತ್ತಮ', 'ಉಪೇಂದ್ರ', 'ಉದ್ಧವ', 'ಉಮಾಕಾಂತ'],
    girlNames: ['ಉಮಾ', 'ಉಷಾ', 'ಉರ್ವಶಿ', 'ಉತ್ತರಾ', 'ಉಜ್ವಲಾ', 'ಉರ್ಮಿಲಾ'],
  ),
  'ಏ': BabyNameEntry(
    boyNames: ['ಏಕನಾಥ', 'ಏಕಾಂಬರ', 'ಏಕಲಿಂಗ'],
    girlNames: ['ಏಕತಾ', 'ಏಕಾಂಬರಿ', 'ಏಳಮ್ಮ'],
  ),

  // ── 3. Rohini ──
  'ಓ': BabyNameEntry(
    boyNames: ['ಓಂಕಾರ', 'ಓಂಕಾರೇಶ', 'ಓಜಸ್', 'ಓಂಪ್ರಕಾಶ'],
    girlNames: ['ಓಜಸ್ವಿನಿ', 'ಓಂಕಾರಿ', 'ಓವಿಯಾ'],
  ),
  'ವಾ': BabyNameEntry(
    boyNames: ['ವಾಸುದೇವ', 'ವಾಮನ', 'ವಾಸು', 'ವಾಗೀಶ', 'ವಾಲ್ಮೀಕಿ'],
    girlNames: ['ವಾಣಿ', 'ವಾಸಂತಿ', 'ವಾಗ್ದೇವಿ', 'ವಾತ್ಸಲ್ಯ'],
  ),
  'ವೀ': BabyNameEntry(
    boyNames: ['ವೀರೇಶ', 'ವೀರಭದ್ರ', 'ವೀರೇಂದ್ರ', 'ವೀರಪ್ಪ', 'ವೀನಾಯಕ'],
    girlNames: ['ವೀಣಾ', 'ವೀರಮ್ಮ', 'ವೀರಲಕ್ಷ್ಮಿ'],
  ),
  'ವೂ': BabyNameEntry(
    boyNames: ['ವೂಜಿತ', 'ವೂರ್ಜಿತ'],
    girlNames: ['ವೂರ್ಮಿ', 'ವೂಲಿ'],
  ),

  // ── 4. Mrigashira ──
  'ವೇ': BabyNameEntry(
    boyNames: ['ವೇಣು', 'ವೇಣುಗೋಪಾಲ', 'ವೇದ', 'ವೇದಾಂತ', 'ವೇಂಕಟೇಶ', 'ವೇಂಕಟರಮಣ'],
    girlNames: ['ವೇದಾ', 'ವೇದಾವತಿ', 'ವೇಣಿ', 'ವೇಳಾಂಬಿಕಾ'],
  ),
  'ವೋ': BabyNameEntry(
    boyNames: ['ವೋಡೇಯರ್'],
    girlNames: ['ವೋಡಮ್ಮ'],
  ),
  'ಕಾ': BabyNameEntry(
    boyNames: ['ಕಾರ್ತಿಕ', 'ಕಾಶೀನಾಥ', 'ಕಾಮೇಶ', 'ಕಾಳಿದಾಸ', 'ಕಾಂತರಾಜ', 'ಕಾಮದೇವ'],
    girlNames: ['ಕಾವ್ಯ', 'ಕಾಂಚನ', 'ಕಾಮಾಕ್ಷಿ', 'ಕಾಮಿನಿ', 'ಕಾಳಿ', 'ಕಾತ್ಯಾಯಿನಿ'],
  ),
  'ಕೀ': BabyNameEntry(
    boyNames: ['ಕೀರ್ತಿ', 'ಕೀರ್ತನ', 'ಕೀರ್ತಿಕುಮಾರ'],
    girlNames: ['ಕೀರ್ತಿ', 'ಕೀರ್ತನಾ', 'ಕೀರ್ತಿಲಕ್ಷ್ಮಿ'],
  ),

  // ── 5. Ardra ──
  'ಕೂ': BabyNameEntry(
    boyNames: ['ಕೂರ್ಮ', 'ಕೂಲ'],
    girlNames: ['ಕೂಜಿತಾ', 'ಕೂರ್ಮಿ'],
  ),
  'ಘ': BabyNameEntry(
    boyNames: ['ಘನಶ್ಯಾಮ', 'ಘಟೋತ್ಕಚ', 'ಘನೇಶ'],
    girlNames: ['ಘನಲಕ್ಷ್ಮಿ', 'ಘಟಾಂಬರಿ'],
  ),
  'ಙ': BabyNameEntry(
    boyNames: ['ಙಕಾರೇಶ'],
    girlNames: ['ಙಕಾರಿಣಿ'],
  ),
  'ಛ': BabyNameEntry(
    boyNames: ['ಛತ್ರಪತಿ', 'ಛಂದಸ್'],
    girlNames: ['ಛವಿ', 'ಛಾಯಾ', 'ಛಂದಿನಿ'],
  ),

  // ── 6. Punarvasu ──
  'ಕೇ': BabyNameEntry(
    boyNames: ['ಕೇಶವ', 'ಕೇದಾರ', 'ಕೇಶವಮೂರ್ತಿ', 'ಕೇವಲ'],
    girlNames: ['ಕೇತಕಿ', 'ಕೇಸರಿ'],
  ),
  'ಕೋ': BabyNameEntry(
    boyNames: ['ಕೋಮಲ', 'ಕೋವಿದ', 'ಕೋಶಲ'],
    girlNames: ['ಕೋಮಲ', 'ಕೋಕಿಲಾ', 'ಕೋಶಲ್ಯ'],
  ),
  'ಹಾ': BabyNameEntry(
    boyNames: ['ಹಾರಿತ', 'ಹಾಲೇಶ'],
    girlNames: ['ಹಾಸಿನಿ', 'ಹಾರಿಣಿ', 'ಹಾಸ್ಯಲಕ್ಷ್ಮಿ'],
  ),
  'ಹೀ': BabyNameEntry(
    boyNames: ['ಹೀರೇಶ', 'ಹೀರಾಲಾಲ'],
    girlNames: ['ಹೀರಾ', 'ಹೀಮಾ', 'ಹೀರಾಂಬಿಕಾ'],
  ),

  // ── 7. Pushya ──
  'ಹೂ': BabyNameEntry(
    boyNames: ['ಹೂವಣ್ಣ', 'ಹೂಗಾರ'],
    girlNames: ['ಹೂವಮ್ಮ', 'ಹೂವರಸಿ', 'ಹೂಮಾಲಿನಿ'],
  ),
  'ಹೇ': BabyNameEntry(
    boyNames: ['ಹೇಮಂತ', 'ಹೇಮಚಂದ್ರ', 'ಹೇಮರಾಜ', 'ಹೇಮಂತಕುಮಾರ'],
    girlNames: ['ಹೇಮಾ', 'ಹೇಮಲತಾ', 'ಹೇಮಾವತಿ', 'ಹೇಮಶ್ರೀ'],
  ),
  'ಹೋ': BabyNameEntry(
    boyNames: ['ಹೋಮೇಶ'],
    girlNames: ['ಹೋಮಾವತಿ'],
  ),
  'ಡಾ': BabyNameEntry(
    boyNames: ['ಡಾಮರ'],
    girlNames: ['ಡಾಕಿನಿ'],
  ),

  // ── 8. Ashlesha ──
  'ಡೀ': BabyNameEntry(
    boyNames: ['ಡೀಪಕ'],
    girlNames: ['ಡೀಪಾ', 'ಡೀಪಿಕಾ'],
  ),
  'ಡೂ': BabyNameEntry(
    boyNames: ['ಡೂಂಗರ'],
    girlNames: ['ಡೂರ್ವಾ'],
  ),
  'ಡೇ': BabyNameEntry(
    boyNames: ['ಡೇವಿಡ್'],
    girlNames: ['ಡೇಲಿಯಾ'],
  ),
  'ಡೋ': BabyNameEntry(
    boyNames: ['ಡೋಲರ'],
    girlNames: ['ಡೋಲಿ'],
  ),

  // ── 9. Magha ──
  'ಮಾ': BabyNameEntry(
    boyNames: ['ಮಾಧವ', 'ಮಾನಸ', 'ಮಾರುತಿ', 'ಮಾಧವರಾವ್', 'ಮಾಧುಕರ', 'ಮಾಯಣ್ಣ', 'ಮಾಂಡವ್ಯ'],
    girlNames: ['ಮಾನಸ', 'ಮಾಧವಿ', 'ಮಾಧುರಿ', 'ಮಾಲತಿ', 'ಮಾಯಾ', 'ಮಾಲಾ', 'ಮಾನಿನಿ', 'ಮಾಲಶ್ರೀ'],
  ),
  'ಮೀ': BabyNameEntry(
    boyNames: ['ಮೀನೇಶ', 'ಮೀನಾಕ್ಷ', 'ಮೀರಾಸಾಹೇಬ'],
    girlNames: ['ಮೀನಾ', 'ಮೀನಾಕ್ಷಿ', 'ಮೀರಾ', 'ಮೀನಲ'],
  ),
  'ಮೂ': BabyNameEntry(
    boyNames: ['ಮೂರ್ತಿ', 'ಮೂಡಲಗಿರಿ'],
    girlNames: ['ಮೂಕಾಂಬಿಕಾ', 'ಮೂನಲ'],
  ),
  'ಮೇ': BabyNameEntry(
    boyNames: ['ಮೇಘನಾಥ', 'ಮೇಘರಾಜ', 'ಮೇಧಾವಿ', 'ಮೇಘಶ್ಯಾಮ'],
    girlNames: ['ಮೇಘನಾ', 'ಮೇಧಾ', 'ಮೇಘಮಾಲಾ', 'ಮೇನಕಾ'],
  ),

  // ── 10. Purva Phalguni ──
  'ಮೋ': BabyNameEntry(
    boyNames: ['ಮೋಹನ', 'ಮೋಹನದಾಸ', 'ಮೋಹನಕೃಷ್ಣ', 'ಮೋಕ್ಷ'],
    girlNames: ['ಮೋಹಿನಿ', 'ಮೋಕ್ಷಾ', 'ಮೋಹನಶ್ರೀ'],
  ),
  'ಟಾ': BabyNameEntry(
    boyNames: ['ಟಾಕೇಶ'],
    girlNames: ['ಟಾರಿಣಿ'],
  ),
  'ಟೀ': BabyNameEntry(
    boyNames: ['ಟೀಕಾರಾಮ'],
    girlNames: ['ಟೀನಾ'],
  ),
  'ಟೂ': BabyNameEntry(
    boyNames: ['ಟೂಟು'],
    girlNames: ['ಟೂಲಿ'],
  ),

  // ── 11. Uttara Phalguni ──
  'ಟೇ': BabyNameEntry(
    boyNames: ['ಟೇಕಚಂದ'],
    girlNames: ['ಟೇಜಲ'],
  ),
  'ಟೋ': BabyNameEntry(
    boyNames: ['ಟೋನಿ'],
    girlNames: ['ಟೋಳಮ್ಮ'],
  ),
  'ಪಾ': BabyNameEntry(
    boyNames: ['ಪಾರ್ಥ', 'ಪಾಂಡುರಂಗ', 'ಪಾಟೀಲ', 'ಪಾಂಡವ', 'ಪಾವನ', 'ಪಾರಸ'],
    girlNames: ['ಪಾರ್ವತಿ', 'ಪಾವನಿ', 'ಪಾರುಲ', 'ಪಾರಿಜಾತ'],
  ),
  'ಪೀ': BabyNameEntry(
    boyNames: ['ಪೀತಾಂಬರ', 'ಪೀಯೂಷ'],
    girlNames: ['ಪೀಯೂಷಾ'],
  ),

  // ── 12. Hasta ──
  'ಪೂ': BabyNameEntry(
    boyNames: ['ಪೂರ್ಣಚಂದ್ರ', 'ಪೂರ್ಣೇಶ', 'ಪೂಜಿತ', 'ಪೂರ್ಣಾನಂದ'],
    girlNames: ['ಪೂಜಾ', 'ಪೂರ್ಣಿಮಾ', 'ಪೂಜಿತಾ', 'ಪೂರ್ವಿ', 'ಪೂವಮ್ಮ'],
  ),
  'ಷ': BabyNameEntry(
    boyNames: ['ಷಣ್ಮುಖ', 'ಷಡಾನನ', 'ಷಡಕ್ಷರಿ'],
    girlNames: ['ಷಣ್ಮುಖಿ', 'ಷಡಕ್ಷರಮ್ಮ'],
  ),
  'ಣ': BabyNameEntry(
    boyNames: ['ಣವೀನ'],
    girlNames: ['ಣಮಿತಾ'],
  ),
  'ಠ': BabyNameEntry(
    boyNames: ['ಠಾಕೂರ'],
    girlNames: ['ಠಾಕುರಿ'],
  ),

  // ── 13. Chitra ──
  'ಪೇ': BabyNameEntry(
    boyNames: ['ಪೇಶ್ವೆ'],
    girlNames: ['ಪೇರಮ್ಮ'],
  ),
  'ಪೋ': BabyNameEntry(
    boyNames: ['ಪೋತರಾಜ'],
    girlNames: ['ಪೋತಮ್ಮ'],
  ),
  'ರಾ': BabyNameEntry(
    boyNames: ['ರಾಘವ', 'ರಾಮ', 'ರಾಜೇಶ', 'ರಾಜಕುಮಾರ', 'ರಾಜೇಂದ್ರ', 'ರಾಮಕೃಷ್ಣ', 'ರಾಘವೇಂದ್ರ', 'ರಾಮಚಂದ್ರ'],
    girlNames: ['ರಾಧಾ', 'ರಾಜೇಶ್ವರಿ', 'ರಾಧಿಕಾ', 'ರಾಮಾ', 'ರಾಗಿಣಿ', 'ರಾಜಲಕ್ಷ್ಮಿ'],
  ),
  'ರೀ': BabyNameEntry(
    boyNames: ['ರೀತೇಶ', 'ರೀನಕ'],
    girlNames: ['ರೀತಾ', 'ರೀಮಾ', 'ರೀತಿಕಾ'],
  ),

  // ── 14. Swati ──
  'ರೂ': BabyNameEntry(
    boyNames: ['ರೂಪೇಶ', 'ರೂದ್ರ', 'ರೂಪಕ'],
    girlNames: ['ರೂಪಾ', 'ರೂಪಶ್ರೀ', 'ರೂಪಿಣಿ', 'ರೂಚಿತಾ'],
  ),
  'ರೇ': BabyNameEntry(
    boyNames: ['ರೇವಂತ', 'ರೇಣುಕ', 'ರೇಖೇಶ'],
    girlNames: ['ರೇಣುಕಾ', 'ರೇಖಾ', 'ರೇವತಿ', 'ರೇಶ್ಮಾ'],
  ),
  'ರೋ': BabyNameEntry(
    boyNames: ['ರೋಹಿತ', 'ರೋಹನ', 'ರೋಚಿತ', 'ರೋಶನ'],
    girlNames: ['ರೋಹಿಣಿ', 'ರೋಶನಿ', 'ರೋಮಾ'],
  ),
  'ತಾ': BabyNameEntry(
    boyNames: ['ತಾರಕ', 'ತಾರಾನಾಥ', 'ತಾಳೇಶ'],
    girlNames: ['ತಾರಾ', 'ತಾರಿಣಿ', 'ತಾಯಮ್ಮ', 'ತಾಮ್ರ'],
  ),

  // ── 15. Vishakha ──
  'ತೀ': BabyNameEntry(
    boyNames: ['ತೀರ್ಥಕುಮಾರ', 'ತೀರ್ಥನಾರಾಯಣ'],
    girlNames: ['ತೀರ್ಥಾ', 'ತೀರ್ಥಮ್ಮ'],
  ),
  'ತೂ': BabyNameEntry(
    boyNames: ['ತೂಫಾನ', 'ತೂಳಸಿ'],
    girlNames: ['ತೂಳಸಿ', 'ತೂಳಸಮ್ಮ'],
  ),
  'ತೇ': BabyNameEntry(
    boyNames: ['ತೇಜಸ್', 'ತೇಜಸ್ವಿ', 'ತೇಜಾ', 'ತೇಜಕುಮಾರ', 'ತೇಜೋಮಯ'],
    girlNames: ['ತೇಜಸ್ವಿನಿ', 'ತೇಜಾ', 'ತೇಜಶ್ರೀ'],
  ),
  'ತೋ': BabyNameEntry(
    boyNames: ['ತೋಷಣ'],
    girlNames: ['ತೋಷಿಣಿ', 'ತೋಷಾ'],
  ),

  // ── 16. Anuradha ──
  'ನಾ': BabyNameEntry(
    boyNames: ['ನಾಗರಾಜ', 'ನಾರಾಯಣ', 'ನಾಗೇಶ', 'ನಾಗೇಂದ್ರ', 'ನಾಗಪ್ಪ', 'ನಾರಸಿಂಹ'],
    girlNames: ['ನಾಗಮ್ಮ', 'ನಾಗಲಕ್ಷ್ಮಿ', 'ನಾಗವೇಣಿ', 'ನಾಯಕಿ'],
  ),
  'ನೀ': BabyNameEntry(
    boyNames: ['ನೀಲಕಂಠ', 'ನೀಲೇಶ', 'ನೀಲಾಚಲ', 'ನೀತಿನ್'],
    girlNames: ['ನೀಲಾ', 'ನೀಲಮ್', 'ನೀತಾ', 'ನೀರಜಾ', 'ನೀಲಾಂಬರಿ'],
  ),
  'ನೂ': BabyNameEntry(
    boyNames: ['ನೂತನ', 'ನೂರ್'],
    girlNames: ['ನೂತನಾ', 'ನೂಪುರ', 'ನೂರ್ಜಹಾನ್'],
  ),
  'ನೇ': BabyNameEntry(
    boyNames: ['ನೇತ್ರ', 'ನೇಮಿನಾಥ'],
    girlNames: ['ನೇತ್ರಾ', 'ನೇಹಾ', 'ನೇಮಿ'],
  ),

  // ── 17. Jyeshtha ──
  'ನೋ': BabyNameEntry(
    boyNames: ['ನೋಯಲ್'],
    girlNames: ['ನೋಯಲಿನ'],
  ),
  'ಯಾ': BabyNameEntry(
    boyNames: ['ಯಾದವ', 'ಯಾಜ್ಞವಲ್ಕ್ಯ', 'ಯಾಮಿನ'],
    girlNames: ['ಯಾಮಿನಿ', 'ಯಾಸ್ಮಿನ್'],
  ),
  'ಯೀ': BabyNameEntry(
    boyNames: ['ಯೀಶ'],
    girlNames: ['ಯೀಶ್ವರಿ'],
  ),
  'ಯೂ': BabyNameEntry(
    boyNames: ['ಯೂಸುಫ್'],
    girlNames: ['ಯೂಥಿಕಾ'],
  ),

  // ── 18. Moola ──
  'ಯೇ': BabyNameEntry(
    boyNames: ['ಯೇಸ್ವಿ'],
    girlNames: ['ಯೇಳಮ್ಮ'],
  ),
  'ಯೋ': BabyNameEntry(
    boyNames: ['ಯೋಗೇಶ', 'ಯೋಗೇಂದ್ರ', 'ಯೋಗೀಶ', 'ಯೋಗಾನಂದ'],
    girlNames: ['ಯೋಗಿನಿ', 'ಯೋಗಿತಾ', 'ಯೋಗಲಕ್ಷ್ಮಿ'],
  ),
  'ಭಾ': BabyNameEntry(
    boyNames: ['ಭಾಸ್ಕರ', 'ಭಾರತ', 'ಭಾಗೀರಥ', 'ಭಾನುಪ್ರಕಾಶ', 'ಭಾರ್ಗವ'],
    girlNames: ['ಭಾರತಿ', 'ಭಾಗ್ಯ', 'ಭಾಗ್ಯಲಕ್ಷ್ಮಿ', 'ಭಾನುಮತಿ', 'ಭಾಮಾ'],
  ),
  'ಭೀ': BabyNameEntry(
    boyNames: ['ಭೀಮ', 'ಭೀಮೇಶ', 'ಭೀಮರಾಯ', 'ಭೀಮಸೇನ'],
    girlNames: ['ಭೀಮಾಂಬಿಕಾ', 'ಭೀಮಾವತಿ'],
  ),

  // ── 19. Purva Ashadha ──
  'ಭೂ': BabyNameEntry(
    boyNames: ['ಭೂಪತಿ', 'ಭೂಷಣ', 'ಭೂಮಿನಾಥ'],
    girlNames: ['ಭೂಮಿ', 'ಭೂಮಿಕಾ', 'ಭೂವನೇಶ್ವರಿ'],
  ),
  'ಧಾ': BabyNameEntry(
    boyNames: ['ಧಾರೇಶ', 'ಧಾನ್ಯಕುಮಾರ', 'ಧಾತ್ರಿ'],
    girlNames: ['ಧಾರಿಣಿ', 'ಧಾನ್ಯ', 'ಧಾತ್ರಿ', 'ಧಾರಾ'],
  ),
  'ಫಾ': BabyNameEntry(
    boyNames: ['ಫಾಲ್ಗುಣ', 'ಫಾಲಾಕ್ಷ'],
    girlNames: ['ಫಾಲ್ಗುಣಿ'],
  ),
  'ಢಾ': BabyNameEntry(
    boyNames: ['ಢಾಕಣ್ಣ'],
    girlNames: ['ಢಾಕಮ್ಮ'],
  ),

  // ── 20. Uttara Ashadha ──
  'ಭೇ': BabyNameEntry(
    boyNames: ['ಭೇದ', 'ಭೇಷಜ'],
    girlNames: ['ಭೇಲಿ', 'ಭೇರಿ'],
  ),
  'ಭೋ': BabyNameEntry(
    boyNames: ['ಭೋಜರಾಜ', 'ಭೋಲೇನಾಥ', 'ಭೋಜ'],
    girlNames: ['ಭೋಜಮ್ಮ'],
  ),
  'ಜಾ': BabyNameEntry(
    boyNames: ['ಜಾಗೃತ', 'ಜಾನಕೀನಾಥ', 'ಜಾದವ'],
    girlNames: ['ಜಾನಕಿ', 'ಜಾಹ್ನವಿ', 'ಜಾಗೃತಿ', 'ಜಾಸ್ಮಿನ್'],
  ),
  'ಜೀ': BabyNameEntry(
    boyNames: ['ಜೀವನ', 'ಜೀತೇಂದ್ರ', 'ಜೀವಕ'],
    girlNames: ['ಜೀವನಾ', 'ಜೀವಿಕಾ', 'ಜೀವಂತಿ'],
  ),

  // ── 21. Shravana ──
  'ಖೀ': BabyNameEntry(
    boyNames: ['ಖೀಮರಾಜ'],
    girlNames: ['ಖೀರಾಂಬಿಕಾ'],
  ),
  'ಖೂ': BabyNameEntry(
    boyNames: ['ಖೂಷಿ'],
    girlNames: ['ಖೂಷಿ', 'ಖೂಬಿ'],
  ),
  'ಖೇ': BabyNameEntry(
    boyNames: ['ಖೇಚರ', 'ಖೇಮರಾಜ'],
    girlNames: ['ಖೇಮಾ'],
  ),
  'ಖೋ': BabyNameEntry(
    boyNames: ['ಖೋಲಾಪುರ'],
    girlNames: ['ಖೋಲಮ್ಮ'],
  ),

  // ── 22. Dhanishtha ──
  'ಗಾ': BabyNameEntry(
    boyNames: ['ಗಾಣಪತಿ', 'ಗಾಯತ್ರಿಪ್ರಸಾದ', 'ಗಾನೇಶ'],
    girlNames: ['ಗಾಯತ್ರಿ', 'ಗಾನಲಕ್ಷ್ಮಿ', 'ಗಾಂಧಾರಿ'],
  ),
  'ಗೀ': BabyNameEntry(
    boyNames: ['ಗೀತೇಶ', 'ಗೀತಾಚಾರ್ಯ'],
    girlNames: ['ಗೀತಾ', 'ಗೀತಾಂಜಲಿ', 'ಗೀರಿಜಾ'],
  ),
  'ಗೂ': BabyNameEntry(
    boyNames: ['ಗೂಳಪ್ಪ'],
    girlNames: ['ಗೂಳಮ್ಮ'],
  ),
  'ಗೇ': BabyNameEntry(
    boyNames: ['ಗೇಯ'],
    girlNames: ['ಗೇಯಮ್ಮ'],
  ),

  // ── 23. Shatabhisha ──
  'ಗೋ': BabyNameEntry(
    boyNames: ['ಗೋವಿಂದ', 'ಗೋಪಾಲ', 'ಗೋಕುಲ', 'ಗೋಪಿನಾಥ', 'ಗೋಪೀಶ'],
    girlNames: ['ಗೋಮತಿ', 'ಗೋದಾವರಿ', 'ಗೋಕುಲಮ್ಮ'],
  ),
  'ಸಾ': BabyNameEntry(
    boyNames: ['ಸಾಗರ', 'ಸಾಮ್ರಾಟ', 'ಸಾಕೇತ', 'ಸಾಂಬಶಿವ', 'ಸಾತ್ವಿಕ'],
    girlNames: ['ಸಾವಿತ್ರಿ', 'ಸಾಕ್ಷಿ', 'ಸಾಧನಾ', 'ಸಾನ್ವಿ', 'ಸಾನಿಧ್ಯ'],
  ),
  'ಸೀ': BabyNameEntry(
    boyNames: ['ಸೀತಾರಾಮ', 'ಸೀಮಂತ'],
    girlNames: ['ಸೀತಾ', 'ಸೀಮಾ', 'ಸೀಮಂತಿನಿ'],
  ),
  'ಸೂ': BabyNameEntry(
    boyNames: ['ಸೂರ್ಯ', 'ಸೂರಜ', 'ಸೂರ್ಯಕಾಂತ', 'ಸೂರ್ಯಪ್ರಕಾಶ', 'ಸೂರ್ಯನಾರಾಯಣ'],
    girlNames: ['ಸೂರ್ಯಮುಖಿ', 'ಸೂನಂದಾ', 'ಸೂಮ', 'ಸೂಜಾತ'],
  ),

  // ── 24. Purva Bhadrapada ──
  'ಸೇ': BabyNameEntry(
    boyNames: ['ಸೇತುರಾಮ', 'ಸೇತು', 'ಸೇವಕ'],
    girlNames: ['ಸೇವಂತಿ', 'ಸೇತುಲಕ್ಷ್ಮಿ'],
  ),
  'ಸೋ': BabyNameEntry(
    boyNames: ['ಸೋಮಶೇಖರ', 'ಸೋಮನಾಥ', 'ಸೋಮೇಶ', 'ಸೋಹನ'],
    girlNames: ['ಸೋನಿಯಾ', 'ಸೋನಾಲಿ', 'ಸೋಮವಲ್ಲಿ'],
  ),
  'ದಾ': BabyNameEntry(
    boyNames: ['ದಾಮೋದರ', 'ದಾಸಪ್ಪ', 'ದಾನಿಶ', 'ದಾಸರಾಯ'],
    girlNames: ['ದಾಕ್ಷಾಯಣಿ', 'ದಾನಮ್ಮ', 'ದಾಕ್ಷಿ'],
  ),
  'ದೀ': BabyNameEntry(
    boyNames: ['ದೀಪಕ', 'ದೀಪೇಂದ್ರ', 'ದೀನನಾಥ', 'ದೀನದಯಾಳ'],
    girlNames: ['ದೀಪಾ', 'ದೀಪಿಕಾ', 'ದೀಪಶ್ರೀ', 'ದೀಕ್ಷಾ', 'ದೀಪ್ತಿ'],
  ),

  // ── 25. Uttara Bhadrapada ──
  'ದೂ': BabyNameEntry(
    boyNames: ['ದೂರ್ವಾಸ', 'ದೂತ'],
    girlNames: ['ದೂರ್ವಾ', 'ದೂತಿ'],
  ),
  'ಥ': BabyNameEntry(
    boyNames: ['ಥಾಮಸ್'],
    girlNames: ['ಥಮನ್ನ'],
  ),
  'ಝ': BabyNameEntry(
    boyNames: ['ಝಂಕಾರ', 'ಝರಿ'],
    girlNames: ['ಝರಿಣಿ', 'ಝಲಕ್'],
  ),
  'ಞ': BabyNameEntry(
    boyNames: ['ಞಾನೇಶ'],
    girlNames: ['ಞಾನಮ್ಮ'],
  ),

  // ── 26. Revati ──
  'ದೇ': BabyNameEntry(
    boyNames: ['ದೇವರಾಜ', 'ದೇವೇಂದ್ರ', 'ದೇವದಾಸ', 'ದೇವೇಶ', 'ದೇವಪ್ಪ', 'ದೇವಾನಂದ'],
    girlNames: ['ದೇವಿ', 'ದೇವಮ್ಮ', 'ದೇವಯಾನಿ', 'ದೇವಕಿ', 'ದೇವಲಕ್ಷ್ಮಿ'],
  ),
  'ದೋ': BabyNameEntry(
    boyNames: ['ದೋಡ್ಡಣ್ಣ', 'ದೋಡ್ಡಪ್ಪ'],
    girlNames: ['ದೋಡ್ಡಮ್ಮ'],
  ),
  'ಚಾ': BabyNameEntry(
    boyNames: ['ಚಾಣಕ್ಯ', 'ಚಾಮುಂಡೇಶ', 'ಚಾಮರಾಜ', 'ಚಾಂದ್'],
    girlNames: ['ಚಾಮುಂಡಿ', 'ಚಾಂದಿನಿ', 'ಚಾರು', 'ಚಾರುಮತಿ', 'ಚಾರುಲತಾ'],
  ),
  'ಚೀ': BabyNameEntry(
    boyNames: ['ಚೀರಂಜೀವಿ', 'ಚೀನಪ್ಪ'],
    girlNames: ['ಚೀತಾ', 'ಚೀರಮ್ಮ'],
  ),
};
