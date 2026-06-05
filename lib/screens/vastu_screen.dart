import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';

// ─── Vastu Aaya Types (8) ───
// Remainder 1-8 from (Perimeter_hasta × 9) % 8
const List<String> _aayaNames = [
  'ಧ್ವಜ',      // 1 - Dhwaja  (Flag)       ✅ Excellent
  'ಧೂಮ್ರ',     // 2 - Dhumra  (Smoke)      ❌ Bad
  'ಸಿಂಹ',      // 3 - Simha   (Lion)       ✅ Good
  'ಶ್ವಾನ',     // 4 - Shwana  (Dog)        ❌ Bad
  'ವೃಷಭ',     // 5 - Vrushabha (Bull)     ✅ Good
  'ಖರ',        // 6 - Khara   (Donkey)     ❌ Bad
  'ಗಜ',        // 7 - Gaja    (Elephant)   ✅ Excellent
  'ಧ್ವಾಂಕ್ಷ',   // 8 - Dhwanksha (Crow)    ❌ Bad
];

const List<String> _aayaEnglish = [
  'Dhwaja (Flag)', 'Dhumra (Smoke)', 'Simha (Lion)', 'Shwana (Dog)',
  'Vrushabha (Bull)', 'Khara (Donkey)', 'Gaja (Elephant)', 'Dhwanksha (Crow)',
];

const Set<int> _goodAaya = {0, 2, 4, 6}; // Dhwaja, Simha, Vrushabha, Gaja

// ─── Tara Names (9 types) ───
const List<String> _taraNames = [
  'ಜನ್ಮ ತಾರೆ',        // 1
  'ಸಂಪತ್ ತಾರೆ',       // 2 ✅
  'ವಿಪತ್ ತಾರೆ',       // 3 ❌
  'ಕ್ಷೇಮ ತಾರೆ',       // 4 ✅
  'ಪ್ರತ್ಯಕ್ ತಾರೆ',    // 5 ❌
  'ಸಾಧನ ತಾರೆ',       // 6 ✅
  'ನೈಧನ ತಾರೆ',       // 7 ❌
  'ಮಿತ್ರ ತಾರೆ',       // 8 ✅
  'ಪರಮ ಮಿತ್ರ ತಾರೆ',  // 9 ✅
];

const List<String> _taraEnglish = [
  'Janma', 'Sampat', 'Vipat', 'Kshema',
  'Pratyak', 'Sadhana', 'Naidhana', 'Mitra', 'Parama Mitra',
];

const List<String> _taraQuality = [
  'ಸಾಮಾನ್ಯ', 'ಅತಿ ಉತ್ತಮ', 'ಕೆಟ್ಟದು', 'ಉತ್ತಮ',
  'ಕೆಟ್ಟದು', 'ಉತ್ತಮ', 'ಕೆಟ್ಟದು', 'ಉತ್ತಮ', 'ಅತಿ ಉತ್ತಮ',
];

const Set<int> _goodTara = {1, 3, 5, 7, 8};

// ─── 1 Hasta = 1.5 feet ───
const double _feetPerHasta = 1.5;

class _VastuResult {
  final int length;      // feet
  final int breadth;     // feet
  final int area;        // sq ft
  final int perimeterFt; // feet
  final int hasta;       // perimeter in hasta (rounded)
  final int aayaIndex;   // 0-7
  final int aayaValue;   // 1-8
  final int vyayaValue;  // 1-8
  final bool aayaGtVyaya;
  final int nakIndex;    // 0-26
  final int taraIndex;   // 0-8

  _VastuResult({
    required this.length,
    required this.breadth,
    required this.area,
    required this.perimeterFt,
    required this.hasta,
    required this.aayaIndex,
    required this.aayaValue,
    required this.vyayaValue,
    required this.aayaGtVyaya,
    required this.nakIndex,
    required this.taraIndex,
  });

  bool get isGoodAaya => _goodAaya.contains(aayaIndex);
  bool get isGoodTara => _goodTara.contains(taraIndex);
  bool get isExcellent => isGoodAaya && isGoodTara && aayaGtVyaya;
}

class VastuScreen extends StatefulWidget {
  const VastuScreen({super.key});

  @override
  State<VastuScreen> createState() => _VastuScreenState();
}

class _VastuScreenState extends State<VastuScreen> {
  int? _ownerNakIndex;
  final _minLenCtrl = TextEditingController(text: '30');
  final _maxLenCtrl = TextEditingController(text: '40');
  final _minBreadthCtrl = TextEditingController(text: '40');
  final _maxBreadthCtrl = TextEditingController(text: '50');
  List<_VastuResult> _results = [];
  bool _searched = false;
  bool _showOnlyGood = true;

  @override
  void dispose() {
    _minLenCtrl.dispose();
    _maxLenCtrl.dispose();
    _minBreadthCtrl.dispose();
    _maxBreadthCtrl.dispose();
    super.dispose();
  }

  void _search() {
    if (_ownerNakIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ಯಜಮಾನನ ನಕ್ಷತ್ರ ಆಯ್ಕೆ ಮಾಡಿ (Select Owner\'s Nakshatra)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final minL = int.tryParse(_minLenCtrl.text) ?? 10;
    final maxL = int.tryParse(_maxLenCtrl.text) ?? 50;
    final minB = int.tryParse(_minBreadthCtrl.text) ?? 10;
    final maxB = int.tryParse(_maxBreadthCtrl.text) ?? 50;

    if (minL > maxL || minB > maxB) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Min must be ≤ Max'), backgroundColor: Colors.red),
      );
      return;
    }

    final totalCombos = (maxL - minL + 1) * (maxB - minB + 1);
    if (totalCombos > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Range too large. Reduce the range.'), backgroundColor: Colors.red),
      );
      return;
    }

    final results = <_VastuResult>[];

    for (int l = minL; l <= maxL; l++) {
      for (int b = minB; b <= maxB; b++) {
        final area = l * b;
        final perimeterFt = 2 * (l + b);

        // Convert to Hasta (1 hasta = 1.5 feet), round to nearest integer
        final hasta = (perimeterFt / _feetPerHasta).round();

        // Shastra formulas:
        // Aaya = (hasta × 9) % 8, remainder 1-8
        final aayaRem = (hasta * 9) % 8;
        final aayaValue = aayaRem == 0 ? 8 : aayaRem;
        final aayaIndex = aayaValue - 1; // 0-based

        // Vyaya = (hasta × 10) % 8, remainder 1-8
        final vyayaRem = (hasta * 10) % 8;
        final vyayaValue = vyayaRem == 0 ? 8 : vyayaRem;

        // Aaya must be > Vyaya for good result
        final aayaGtVyaya = aayaValue > vyayaValue;

        // Building Nakshatra = (hasta × 8) % 27, remainder 1-27
        final nakRem = (hasta * 8) % 27;
        final nakValue = nakRem == 0 ? 27 : nakRem;
        final nakIndex = nakValue - 1; // 0-based

        // Tarabala: count from owner's nak to building's nak
        final diff = (nakIndex - _ownerNakIndex! + 27) % 27;
        final taraIndex = diff % 9; // 0-8

        results.add(_VastuResult(
          length: l,
          breadth: b,
          area: area,
          perimeterFt: perimeterFt,
          hasta: hasta,
          aayaIndex: aayaIndex,
          aayaValue: aayaValue,
          vyayaValue: vyayaValue,
          aayaGtVyaya: aayaGtVyaya,
          nakIndex: nakIndex,
          taraIndex: taraIndex,
        ));
      }
    }

    // Sort: excellent first, then by area
    results.sort((a, b) {
      if (a.isExcellent && !b.isExcellent) return -1;
      if (!a.isExcellent && b.isExcellent) return 1;
      return a.area.compareTo(b.area);
    });

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
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
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
                              hintText: 'ನಕ್ಷತ್ರ ಆಯ್ಕೆ ಮಾಡಿ',
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

                          // Length range
                          Text('ಉದ್ದ / Length (Feet)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPurple2)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(_minLenCtrl, 'Min')),
                              _rangeSeparator(),
                              Expanded(child: _buildTextField(_maxLenCtrl, 'Max')),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Breadth range
                          Text('ಅಗಲ / Breadth (Feet)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPurple2)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(_minBreadthCtrl, 'Min')),
                              _rangeSeparator(),
                              Expanded(child: _buildTextField(_maxBreadthCtrl, 'Max')),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Formula info
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kPurple2.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kPurple2.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ಶಾಸ್ತ್ರ ಸೂತ್ರ (Shastra Formula):', style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w800, color: kPurple2)),
                                const SizedBox(height: 4),
                                Text('• ಪರಿಧಿ = 2 × (ಉದ್ದ + ಅಗಲ)  →  ಹಸ್ತ = ಪರಿಧಿ ÷ 1.5', style: TextStyle(fontSize: 10, color: kMuted)),
                                Text('• ಆಯ = (ಹಸ್ತ × 9) % 8', style: TextStyle(fontSize: 10, color: kMuted)),
                                Text('• ವ್ಯಯ = (ಹಸ್ತ × 10) % 8  |  ಆಯ > ವ್ಯಯ ಆಗಬೇಕು', style: TextStyle(fontSize: 10, color: kMuted)),
                                Text('• ನಕ್ಷತ್ರ = (ಹಸ್ತ × 8) % 27', style: TextStyle(fontSize: 10, color: kMuted)),
                              ],
                            ),
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
                  ),

                  // ── Filter toggle ──
                  if (_searched)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Icon(_showOnlyGood ? Icons.filter_alt : Icons.filter_alt_off,
                                size: 16, color: _showOnlyGood ? kGreen : kMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _showOnlyGood
                                    ? 'ಶುಭ ಫಲಿತಾಂಶ (Good: ಆಯ ✓ ತಾರಾ ✓ ಆಯ>ವ್ಯಯ ✓)'
                                    : 'ಎಲ್ಲಾ ಫಲಿತಾಂಶ (All results)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted),
                              ),
                            ),
                            Text('${_filteredResults.length}/${_results.length}',
                              style: TextStyle(fontSize: 12, color: kPurple2, fontWeight: FontWeight.w800)),
                            Switch(
                              value: _showOnlyGood,
                              activeColor: kGreen,
                              onChanged: (v) => setState(() => _showOnlyGood = v),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Results ──
                  if (!_searched)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home_work_rounded, size: 64, color: kPurple2.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text('ಉದ್ದ ಮತ್ತು ಅಗಲ ನಮೂದಿಸಿ', style: TextStyle(color: kMuted, fontSize: 14)),
                            Text('Enter length & breadth range', style: TextStyle(color: kMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  else if (_filteredResults.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.red.withOpacity(0.4)),
                            const SizedBox(height: 8),
                            Text('ಯಾವುದೇ ಶುಭ ಫಲಿತಾಂಶ ಸಿಗಲಿಲ್ಲ', style: TextStyle(color: kMuted, fontSize: 14)),
                            Text('No favorable results found.', style: TextStyle(color: kMuted, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text('Try turning off the filter ↗', style: TextStyle(color: kPurple2, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _filteredResults.length) return null;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _buildResultCard(_filteredResults[index]),
                          );
                        },
                        childCount: _filteredResults.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kMuted, fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      style: TextStyle(fontSize: 14, color: kText),
    );
  }

  Widget _rangeSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text('–', style: TextStyle(fontSize: 20, color: kMuted)),
    );
  }

  Widget _buildResultCard(_VastuResult r) {
    final naks = appNak;
    final isExcellent = r.isExcellent;
    final borderColor = isExcellent ? Colors.green.withOpacity(0.5) : kBorder;

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
          // ── Header: Dimensions + Area ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isExcellent
                        ? [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)]
                        : [kPurple2.withOpacity(0.1), kPurple2.withOpacity(0.03)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${r.length} × ${r.breadth} ft',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isExcellent ? Colors.green.shade700 : kPurple2),
                ),
              ),
              const SizedBox(width: 8),
              Text('${r.area} Sq Ft', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
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
                      const SizedBox(width: 3),
                      Text('ಶುಭ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Perimeter / Hasta ──
          Text(
            'ಪರಿಧಿ: ${r.perimeterFt} ft  |  ಹಸ್ತ: ${r.hasta}',
            style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // ── Aaya + Vyaya ──
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 14, color: _aayaColor(r.aayaIndex)),
              const SizedBox(width: 4),
              Text('ಆಯ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
              Flexible(
                child: Text(
                  '${_aayaNames[r.aayaIndex]} (${_aayaEnglish[r.aayaIndex]}) [${r.aayaValue}]',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _aayaColor(r.aayaIndex)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.money_off, size: 14, color: kMuted),
              const SizedBox(width: 4),
              Text('ವ್ಯಯ: ${r.vyayaValue}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: r.aayaGtVyaya ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  r.aayaGtVyaya ? 'ಆಯ > ವ್ಯಯ ✓' : 'ಆಯ ≤ ವ್ಯಯ ✗',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: r.aayaGtVyaya ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Building Nakshatra ──
          Row(
            children: [
              Icon(Icons.star, size: 14, color: kOrange),
              const SizedBox(width: 4),
              Text('ಕಟ್ಟಡದ ನಕ್ಷತ್ರ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
              Flexible(
                child: Text(
                  naks[r.nakIndex],
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Tarabala ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _taraColor(r.taraIndex).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.shield, size: 14, color: _taraColor(r.taraIndex)),
                const SizedBox(width: 6),
                Text('ತಾರಾಬಲ: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted)),
                Flexible(
                  child: Text(
                    '${_taraNames[r.taraIndex]} (${_taraEnglish[r.taraIndex]}) - ${_taraQuality[r.taraIndex]}',
                    style: TextStyle(
                      fontSize: 11,
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
