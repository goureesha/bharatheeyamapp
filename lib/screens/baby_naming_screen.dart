import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';

/// ──────────────────────────────────────────────────────────────
/// Baby Naming (ನಾಮಕರಣ) Screen
/// Shows all 108 Kannada syllables mapped to 27 nakshatras × 4 padas.
/// User taps a letter to see its nakshatra, pada, rashi, and
/// dasha lord details.
/// ──────────────────────────────────────────────────────────────
class BabyNamingScreen extends StatefulWidget {
  const BabyNamingScreen({super.key});
  @override
  State<BabyNamingScreen> createState() => _BabyNamingScreenState();
}

class _BabyNamingScreenState extends State<BabyNamingScreen> {
  // Selected nakshatra + pada
  int? _selectedNak;
  int? _selectedPada;

  // Search / filter
  String _searchText = '';

  // Nakshatra pada syllables (27 nakshatras × 4 padas each)
  static const List<List<String>> _nakSyllables = [
    ['ಚು', 'ಚೇ', 'ಚೋ', 'ಲಾ'],       // 0  Ashwini
    ['ಲೀ', 'ಲೂ', 'ಲೇ', 'ಲೋ'],       // 1  Bharani
    ['ಅ', 'ಈ', 'ಉ', 'ಏ'],           // 2  Krittika
    ['ಓ', 'ವಾ', 'ವೀ', 'ವೂ'],       // 3  Rohini
    ['ವೇ', 'ವೋ', 'ಕಾ', 'ಕೀ'],       // 4  Mrigashira
    ['ಕೂ', 'ಘ', 'ಙ', 'ಛ'],           // 5  Ardra
    ['ಕೇ', 'ಕೋ', 'ಹಾ', 'ಹೀ'],       // 6  Punarvasu
    ['ಹೂ', 'ಹೇ', 'ಹೋ', 'ಡಾ'],       // 7  Pushya
    ['ಡೀ', 'ಡೂ', 'ಡೇ', 'ಡೋ'],       // 8  Ashlesha
    ['ಮಾ', 'ಮೀ', 'ಮೂ', 'ಮೇ'],       // 9  Magha
    ['ಮೋ', 'ಟಾ', 'ಟೀ', 'ಟೂ'],       // 10 Purva Phalguni
    ['ಟೇ', 'ಟೋ', 'ಪಾ', 'ಪೀ'],       // 11 Uttara Phalguni
    ['ಪೂ', 'ಷ', 'ಣ', 'ಠ'],           // 12 Hasta
    ['ಪೇ', 'ಪೋ', 'ರಾ', 'ರೀ'],       // 13 Chitra
    ['ರೂ', 'ರೇ', 'ರೋ', 'ತಾ'],       // 14 Swati
    ['ತೀ', 'ತೂ', 'ತೇ', 'ತೋ'],       // 15 Vishakha
    ['ನಾ', 'ನೀ', 'ನೂ', 'ನೇ'],       // 16 Anuradha
    ['ನೋ', 'ಯಾ', 'ಯೀ', 'ಯೂ'],       // 17 Jyeshtha
    ['ಯೇ', 'ಯೋ', 'ಭಾ', 'ಭೀ'],       // 18 Moola
    ['ಭೂ', 'ಧಾ', 'ಫಾ', 'ಢಾ'],       // 19 Purva Ashadha
    ['ಭೇ', 'ಭೋ', 'ಜಾ', 'ಜೀ'],       // 20 Uttara Ashadha
    ['ಖೀ', 'ಖೂ', 'ಖೇ', 'ಖೋ'],       // 21 Shravana
    ['ಗಾ', 'ಗೀ', 'ಗೂ', 'ಗೇ'],       // 22 Dhanishtha
    ['ಗೋ', 'ಸಾ', 'ಸೀ', 'ಸೂ'],       // 23 Shatabhisha
    ['ಸೇ', 'ಸೋ', 'ದಾ', 'ದೀ'],       // 24 Purva Bhadrapada
    ['ದೂ', 'ಥ', 'ಝ', 'ಞ'],           // 25 Uttara Bhadrapada
    ['ದೇ', 'ದೋ', 'ಚಾ', 'ಚೀ'],       // 26 Revati
  ];

  // Dasha lord for each nakshatra (index 0-26)
  static const List<String> _nakDashaLords = [
    'ಕೇತು', 'ಶುಕ್ರ', 'ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ರಾಹು',
    'ಗುರು', 'ಶನಿ', 'ಬುಧ', 'ಕೇತು', 'ಶುಕ್ರ', 'ರವಿ',
    'ಚಂದ್ರ', 'ಕುಜ', 'ರಾಹು', 'ಗುರು', 'ಶನಿ', 'ಬುಧ',
    'ಕೇತು', 'ಶುಕ್ರ', 'ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ರಾಹು',
    'ಗುರು', 'ಶನಿ', 'ಬುಧ',
  ];

  // Nakshatra devata
  static const List<String> _nakDevata = [
    'ಅಶ್ವಿನೀ ಕುಮಾರರು', 'ಯಮ', 'ಅಗ್ನಿ', 'ಬ್ರಹ್ಮ', 'ಚಂದ್ರ', 'ರುದ್ರ',
    'ಅದಿತಿ', 'ಬೃಹಸ್ಪತಿ', 'ಸರ್ಪ', 'ಪಿತೃ', 'ಭಗ', 'ಅರ್ಯಮ',
    'ಸವಿತೃ', 'ತ್ವಷ್ಟೃ', 'ವಾಯು', 'ಇಂದ್ರಾಗ್ನಿ', 'ಮಿತ್ರ', 'ಇಂದ್ರ',
    'ನಿರ್ಋತಿ', 'ಅಪ (ಜಲ)', 'ವಿಶ್ವೇದೇವ', 'ವಿಷ್ಣು', 'ವಸು', 'ವರುಣ',
    'ಅಜೈಕಪಾದ', 'ಅಹಿರ್ಬುಧ್ನ್ಯ', 'ಪೂಷ',
  ];

  // Nakshatra gana
  static const List<String> _nakGana = [
    'ದೇವ', 'ಮನುಷ್ಯ', 'ರಾಕ್ಷಸ', 'ಮನುಷ್ಯ', 'ದೇವ', 'ಮನುಷ್ಯ',
    'ದೇವ', 'ದೇವ', 'ರಾಕ್ಷಸ', 'ರಾಕ್ಷಸ', 'ಮನುಷ್ಯ', 'ಮನುಷ್ಯ',
    'ದೇವ', 'ರಾಕ್ಷಸ', 'ದೇವ', 'ರಾಕ್ಷಸ', 'ದೇವ', 'ರಾಕ್ಷಸ',
    'ರಾಕ್ಷಸ', 'ಮನುಷ್ಯ', 'ಮನುಷ್ಯ', 'ದೇವ', 'ರಾಕ್ಷಸ', 'ರಾಕ್ಷಸ',
    'ಮನುಷ್ಯ', 'ಮನುಷ್ಯ', 'ದೇವ',
  ];

  /// Get rashi index from nakshatra + pada
  int _rashiFromNakPada(int nakIdx, int padaIdx) => (nakIdx * 4 + padaIdx) ~/ 9;

  // Rashi colors for visual grouping
  static const List<Color> _rashiColors = [
    Color(0xFFE53E3E), // Mesha - Red
    Color(0xFF38A169), // Vrishabha - Green
    Color(0xFFF6AD55), // Mithuna - Orange
    Color(0xFF4299E1), // Karka - Blue
    Color(0xFFDD6B20), // Simha - Deep Orange
    Color(0xFF48BB78), // Kanya - Green
    Color(0xFFED64A6), // Tula - Pink
    Color(0xFF9F7AEA), // Vrischika - Purple
    Color(0xFFECC94B), // Dhanu - Yellow
    Color(0xFF667EEA), // Makara - Indigo
    Color(0xFF4FD1C5), // Kumbha - Teal
    Color(0xFF63B3ED), // Meena - Light Blue
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.langNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kCard,
          title: Text('${AppLocale.l('babyNaming')} / Baby Naming',
              style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
          iconTheme: IconThemeData(color: kText),
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: ResponsiveCenter(
              maxWidth: 700,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header info ──
                    AppCard(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.child_care, color: kOrange, size: 22),
                          const SizedBox(width: 8),
                          Expanded(child: Text(AppLocale.l('babyNaming'),
                            style: TextStyle(color: kOrange, fontWeight: FontWeight.w900, fontSize: 18))),
                        ]),
                        const SizedBox(height: 8),
                        Text(AppLocale.l('babyNamingDesc'),
                          style: TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    )),
                    const SizedBox(height: 12),

                    // ── Search / Filter ──
                    TextField(
                      decoration: InputDecoration(
                        labelText: AppLocale.l('babyNamingSearch'),
                        hintText: AppLocale.l('babyNamingHint'),
                        prefixIcon: Icon(Icons.search, color: kOrange),
                        isDense: true,
                        filled: true,
                        fillColor: kCard,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kOrange, width: 2)),
                      ),
                      onChanged: (v) => setState(() { _searchText = v; }),
                    ),
                    const SizedBox(height: 16),

                    // ── Selected letter details ──
                    if (_selectedNak != null && _selectedPada != null) ...[
                      _buildDetailCard(),
                      const SizedBox(height: 16),
                    ],

                    // ── All 108 syllables grid grouped by rashi ──
                    ..._buildRashiGroupedGrid(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the detail card for selected syllable
  Widget _buildDetailCard() {
    final nakIdx = _selectedNak!;
    final padaIdx = _selectedPada!;
    final syllable = _nakSyllables[nakIdx][padaIdx];
    final rashiIdx = _rashiFromNakPada(nakIdx, padaIdx);
    final rashiColor = _rashiColors[rashiIdx];

    return AppCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with large syllable
        Row(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: rashiColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: rashiColor.withOpacity(0.4), width: 2),
            ),
            child: Text(syllable, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: rashiColor)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocale.l('babyNamingSelected'),
                style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('"$syllable" ${AppLocale.l('babyNamingLetterSuffix')}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
            ],
          )),
          IconButton(
            onPressed: () => setState(() { _selectedNak = null; _selectedPada = null; }),
            icon: Icon(Icons.close, color: kMuted, size: 20),
          ),
        ]),
        const Divider(height: 24),

        // Info rows
        _infoRow(Icons.stars_rounded, AppLocale.l('nakshatraLabel'), trAll(knNak[nakIdx]), kOrange),
        _infoRow(Icons.looks_4_rounded, AppLocale.l('padaLabel'), '${padaIdx + 1}', kPurple2),
        _infoRow(Icons.circle_outlined, AppLocale.l('rashiLabel'), trAll(knRashi[rashiIdx]), rashiColor),
        _infoRow(Icons.auto_awesome, AppLocale.l('dashaLord'), trAll(_nakDashaLords[nakIdx]), kTeal),
        _infoRow(Icons.temple_hindu, AppLocale.l('devata'), trAll(_nakDevata[nakIdx]), const Color(0xFFE67E22)),
        _infoRow(Icons.people, AppLocale.l('gana'), trAll(_nakGana[nakIdx]), kGreen),

        const SizedBox(height: 12),
        // Show all 4 padas of this nakshatra
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${trAll(knNak[nakIdx])} — ${AppLocale.l('allPadas')}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kMuted)),
              const SizedBox(height: 8),
              Row(children: List.generate(4, (p) {
                final isThis = p == padaIdx;
                final pRashi = _rashiFromNakPada(nakIdx, p);
                return Expanded(child: Container(
                  margin: EdgeInsets.only(right: p < 3 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isThis ? _rashiColors[pRashi].withOpacity(0.15) : kCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isThis ? _rashiColors[pRashi] : kBorder, width: isThis ? 2 : 1),
                  ),
                  child: Column(children: [
                    Text(_nakSyllables[nakIdx][p],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                        color: isThis ? _rashiColors[pRashi] : kText)),
                    Text('ಪಾದ ${p + 1}', style: TextStyle(fontSize: 9, color: kMuted)),
                    Text(trAll(knRashi[pRashi]), style: TextStyle(fontSize: 9, color: _rashiColors[pRashi], fontWeight: FontWeight.w700)),
                  ]),
                ));
              })),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: kText, fontWeight: FontWeight.w800))),
      ]),
    );
  }

  /// Build syllable grid grouped by rashi (12 groups)
  List<Widget> _buildRashiGroupedGrid() {
    final widgets = <Widget>[];

    for (int rashiIdx = 0; rashiIdx < 12; rashiIdx++) {
      // Collect all syllables belonging to this rashi
      final syllablesInRashi = <Map<String, dynamic>>[];
      for (int n = 0; n < 27; n++) {
        for (int p = 0; p < 4; p++) {
          if (_rashiFromNakPada(n, p) == rashiIdx) {
            final syl = _nakSyllables[n][p];
            // Apply search filter
            if (_searchText.isNotEmpty && !syl.startsWith(_searchText)) continue;
            syllablesInRashi.add({'nakIdx': n, 'padaIdx': p, 'syllable': syl});
          }
        }
      }

      if (syllablesInRashi.isEmpty) continue;

      final rColor = _rashiColors[rashiIdx];

      widgets.add(Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: rColor.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rashi header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: rColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: Row(children: [
                Icon(Icons.circle, size: 10, color: rColor),
                const SizedBox(width: 8),
                Text(trAll(knRashi[rashiIdx]),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: rColor)),
                const SizedBox(width: 6),
                Text('(${knRashi[rashiIdx]})',
                  style: TextStyle(fontSize: 11, color: rColor.withOpacity(0.7), fontWeight: FontWeight.w600)),
              ]),
            ),

            // Syllable chips
            Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: syllablesInRashi.map((m) {
                  final nakIdx = m['nakIdx'] as int;
                  final padaIdx = m['padaIdx'] as int;
                  final syl = m['syllable'] as String;
                  final isSelected = _selectedNak == nakIdx && _selectedPada == padaIdx;

                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedNak = nakIdx;
                      _selectedPada = padaIdx;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? rColor : kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? rColor : kBorder,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(color: rColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                        ] : null,
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(syl, style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : kText,
                        )),
                        const SizedBox(height: 2),
                        Text(trAll(knNak[nakIdx]),
                          style: TextStyle(fontSize: 8,
                            color: isSelected ? Colors.white70 : kMuted,
                            fontWeight: FontWeight.w600)),
                        Text('ಪಾದ ${padaIdx + 1}',
                          style: TextStyle(fontSize: 8,
                            color: isSelected ? Colors.white60 : kMuted.withOpacity(0.6))),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ));
    }

    if (widgets.isEmpty && _searchText.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text(AppLocale.l('babyNamingNoMatch'),
          style: TextStyle(fontSize: 14, color: kMuted))),
      ));
    }

    return widgets;
  }
}
