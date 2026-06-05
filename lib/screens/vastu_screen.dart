import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';

// ─── Vastu Aaya Types ───
// 8 types: remainder of sqft % 8 (1-based)
const List<String> _aayaNames = [
  'ಧ್ವಜ',    // 1 - Dhwaja  (Flag)      ✅ Excellent
  'ಧೂಮ್ರ',   // 2 - Dhumra  (Smoke)     ❌ Bad
  'ಸಿಂಹ',    // 3 - Simha   (Lion)      ✅ Good
  'ಶ್ವಾನ',   // 4 - Shwana  (Dog)       ❌ Bad
  'ವೃಷಭ',   // 5 - Vrushabha (Bull)    ✅ Good
  'ಖರ',      // 6 - Khara   (Donkey)    ❌ Bad
  'ಗಜ',      // 7 - Gaja    (Elephant)  ✅ Excellent
  'ಧ್ವಾಂಕ್ಷ', // 8 - Dhwanksha (Crow)   ❌ Bad
];

const List<String> _aayaEnglish = [
  'Dhwaja', 'Dhumra', 'Simha', 'Shwana',
  'Vrushabha', 'Khara', 'Gaja', 'Dhwanksha',
];

// Good Aaya indices (0-based): 0=Dhwaja, 2=Simha, 4=Vrushabha, 6=Gaja
const Set<int> _goodAaya = {0, 2, 4, 6};

// ─── Tara Names (9 types) ───
const List<String> _taraNames = [
  'ಜನ್ಮ ತಾರೆ',        // 1 - Janma        Neutral
  'ಸಂಪತ್ ತಾರೆ',       // 2 - Sampat       ✅ Excellent
  'ವಿಪತ್ ತಾರೆ',       // 3 - Vipat        ❌ Bad
  'ಕ್ಷೇಮ ತಾರೆ',       // 4 - Kshema       ✅ Good
  'ಪ್ರತ್ಯಕ್ ತಾರೆ',    // 5 - Pratyak      ❌ Bad
  'ಸಾಧನ ತಾರೆ',       // 6 - Sadhana      ✅ Good
  'ನೈಧನ ತಾರೆ',       // 7 - Naidhana     ❌ Bad
  'ಮಿತ್ರ ತಾರೆ',       // 8 - Mitra        ✅ Good
  'ಪರಮ ಮಿತ್ರ ತಾರೆ',  // 9 - Parama Mitra ✅ Excellent
];

const List<String> _taraEnglish = [
  'Janma Tara', 'Sampat Tara', 'Vipat Tara', 'Kshema Tara',
  'Pratyak Tara', 'Sadhana Tara', 'Naidhana Tara', 'Mitra Tara',
  'Parama Mitra Tara',
];

const List<String> _taraQuality = [
  'ಸಾಮಾನ್ಯ',    // Neutral
  'ಅತಿ ಉತ್ತಮ',  // Excellent
  'ಕೆಟ್ಟದು',     // Bad
  'ಉತ್ತಮ',       // Good
  'ಕೆಟ್ಟದು',     // Bad
  'ಉತ್ತಮ',       // Good
  'ಕೆಟ್ಟದು',     // Bad
  'ಉತ್ತಮ',       // Good
  'ಅತಿ ಉತ್ತಮ',  // Excellent
];

// Good Tara indices (0-based): 1=Sampat, 3=Kshema, 5=Sadhana, 7=Mitra, 8=Parama Mitra
const Set<int> _goodTara = {1, 3, 5, 7, 8};

class _VastuResult {
  final int sqft;
  final int aayaIndex;   // 0-7
  final int nakIndex;    // 0-26 (building nakshatra)
  final int taraIndex;   // 0-8
  final bool isGoodAaya;
  final bool isGoodTara;

  _VastuResult({
    required this.sqft,
    required this.aayaIndex,
    required this.nakIndex,
    required this.taraIndex,
    required this.isGoodAaya,
    required this.isGoodTara,
  });

  bool get isExcellent => isGoodAaya && isGoodTara;
}

class VastuScreen extends StatefulWidget {
  const VastuScreen({super.key});

  @override
  State<VastuScreen> createState() => _VastuScreenState();
}

class _VastuScreenState extends State<VastuScreen> {
  int? _ownerNakIndex; // 0-26
  final _minCtrl = TextEditingController(text: '1000');
  final _maxCtrl = TextEditingController(text: '1200');
  List<_VastuResult> _results = [];
  bool _searched = false;
  bool _showOnlyGood = true;

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _search() {
    if (_ownerNakIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ಯಜಮಾನನ ನಕ್ಷತ್ರ ಆಯ್ಕೆ ಮಾಡಿ (Select Owner\'s Nakshatra)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final minSqft = int.tryParse(_minCtrl.text) ?? 500;
    final maxSqft = int.tryParse(_maxCtrl.text) ?? 2000;

    if (minSqft > maxSqft || maxSqft - minSqft > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid range. Max range is 5000 sq ft.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final results = <_VastuResult>[];

    for (int sqft = minSqft; sqft <= maxSqft; sqft++) {
      // Aaya: sqft % 8 → 0-7 (0-based index)
      final aayaRemainder = sqft % 8;
      final aayaIndex = aayaRemainder == 0 ? 7 : aayaRemainder - 1;

      // Building Nakshatra: sqft % 27 → 0-26 (0-based index)
      final nakRemainder = sqft % 27;
      final nakIndex = nakRemainder == 0 ? 26 : nakRemainder - 1;

      // Tarabala: count from owner's nak to building's nak
      final diff = (nakIndex - _ownerNakIndex! + 27) % 27;
      final taraIndex = diff % 9; // 0-8

      final isGoodAaya = _goodAaya.contains(aayaIndex);
      final isGoodTara = _goodTara.contains(taraIndex);

      results.add(_VastuResult(
        sqft: sqft,
        aayaIndex: aayaIndex,
        nakIndex: nakIndex,
        taraIndex: taraIndex,
        isGoodAaya: isGoodAaya,
        isGoodTara: isGoodTara,
      ));
    }

    setState(() {
      _results = results;
      _searched = true;
    });
  }

  List<_VastuResult> get _filteredResults =>
      _showOnlyGood ? _results.where((r) => r.isExcellent).toList() : _results;

  Color _aayaColor(int index) => _goodAaya.contains(index) ? Colors.green : Colors.red;
  Color _taraColor(int index) => _goodTara.contains(index)
      ? (index == 1 || index == 8 ? Colors.green : Colors.teal)
      : (index == 0 ? Colors.orange : Colors.red);

  @override
  Widget build(BuildContext context) {
    final naks = appNak;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ವಾಸ್ತು ಅಳತೆಗಳು', style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w900)),
            Text('Vastu Measurements', style: TextStyle(color: kMuted, fontSize: 11)),
          ],
        ),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Input Section ──
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
                boxShadow: [
                  BoxShadow(color: kPurple2.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nakshatra dropdown
                  Text('ಯಜಮಾನನ ನಕ್ಷತ್ರ (Owner\'s Nakshatra)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPurple2)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _ownerNakIndex,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: 'ನಕ್ಷತ್ರ ಆಯ್ಕೆ ಮಾಡಿ (Select Nakshatra)',
                      hintStyle: TextStyle(color: kMuted, fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: List.generate(27, (i) => DropdownMenuItem(
                      value: i,
                      child: Text('${i + 1}. ${naks[i]}', style: TextStyle(fontSize: 14, color: kText)),
                    )),
                    onChanged: (v) => setState(() => _ownerNakIndex = v),
                  ),
                  const SizedBox(height: 14),

                  // Min/Max Sq Ft
                  Text('ವಿಸ್ತೀರ್ಣ (Area in Sq Ft)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPurple2)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Min Sq Ft',
                            labelStyle: TextStyle(color: kMuted, fontSize: 12),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          style: TextStyle(fontSize: 14, color: kText),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('–', style: TextStyle(fontSize: 20, color: kMuted)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _maxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Max Sq Ft',
                            labelStyle: TextStyle(color: kMuted, fontSize: 12),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          style: TextStyle(fontSize: 14, color: kText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _search,
                      icon: const Icon(Icons.search, size: 20),
                      label: const Text('ಹುಡುಕಿ (Search)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurple2,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Filter toggle ──
            if (_searched)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      _showOnlyGood
                          ? 'ಉತ್ತಮ ಫಲಿತಾಂಶ ಮಾತ್ರ (Good results only)'
                          : 'ಎಲ್ಲಾ ಫಲಿತಾಂಶ (All results)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted),
                    ),
                    const Spacer(),
                    Text('${_filteredResults.length} / ${_results.length}',
                      style: TextStyle(fontSize: 12, color: kPurple2, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Switch(
                      value: _showOnlyGood,
                      activeColor: kGreen,
                      onChanged: (v) => setState(() => _showOnlyGood = v),
                    ),
                  ],
                ),
              ),

            // ── Results ──
            Expanded(
              child: !_searched
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home_work_rounded, size: 64, color: kPurple2.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text('ನಕ್ಷತ್ರ ಮತ್ತು ವಿಸ್ತೀರ್ಣ ನಮೂದಿಸಿ',
                            style: TextStyle(color: kMuted, fontSize: 14)),
                          Text('Enter nakshatra and area range',
                            style: TextStyle(color: kMuted, fontSize: 12)),
                        ],
                      ),
                    )
                  : _filteredResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.red.withOpacity(0.4)),
                              const SizedBox(height: 8),
                              Text('ಯಾವುದೇ ಉತ್ತಮ ಫಲಿತಾಂಶ ಸಿಗಲಿಲ್ಲ',
                                style: TextStyle(color: kMuted, fontSize: 14)),
                              Text('No favorable results found in this range.',
                                style: TextStyle(color: kMuted, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: _filteredResults.length,
                          itemBuilder: (context, index) {
                            final r = _filteredResults[index];
                            return _buildResultCard(r);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(_VastuResult r) {
    final naks = appNak;
    final isExcellent = r.isGoodAaya && r.isGoodTara;
    final borderColor = isExcellent ? Colors.green.withOpacity(0.5) : kBorder;
    final accentColor = isExcellent ? Colors.green : kMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isExcellent ? 1.5 : 1),
        boxShadow: [
          if (isExcellent)
            BoxShadow(color: Colors.green.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sq ft header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${r.sqft} Sq Ft',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accentColor),
                ),
              ),
              const Spacer(),
              if (isExcellent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text('ಶುಭ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Aaya + Building Nakshatra
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 15, color: _aayaColor(r.aayaIndex)),
              const SizedBox(width: 4),
              Text('ಆಯ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
              Text(
                '${_aayaNames[r.aayaIndex]} (${_aayaEnglish[r.aayaIndex]})',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _aayaColor(r.aayaIndex)),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              Icon(Icons.star, size: 15, color: kOrange),
              const SizedBox(width: 4),
              Text('ಕಟ್ಟಡದ ನಕ್ಷತ್ರ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
              Flexible(
                child: Text(
                  '${naks[r.nakIndex]} (${knNak[r.nakIndex]})',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Tarabala
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _taraColor(r.taraIndex).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.shield, size: 15, color: _taraColor(r.taraIndex)),
                const SizedBox(width: 6),
                Text('ತಾರಾಬಲ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
                Flexible(
                  child: Text(
                    '${_taraNames[r.taraIndex]} (${_taraEnglish[r.taraIndex]}) - ${_taraQuality[r.taraIndex]}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _taraColor(r.taraIndex),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
