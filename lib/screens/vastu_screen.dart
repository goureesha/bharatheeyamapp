import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';

// ─── Vastu Aaya Types (8) ───
const List<String> _aayaNames = [
  'ಧ್ವಜ', 'ಧೂಮ್ರ', 'ಸಿಂಹ', 'ಶ್ವಾನ',
  'ವೃಷಭ', 'ಖರ', 'ಗಜ', 'ಧ್ವಾಂಕ್ಷ',
];

const List<String> _aayaEnglish = [
  'Dhwaja (Flag)', 'Dhumra (Smoke)', 'Simha (Lion)', 'Shwana (Dog)',
  'Vrushabha (Bull)', 'Khara (Donkey)', 'Gaja (Elephant)', 'Dhwanksha (Crow)',
];

const Set<int> _goodAaya = {0, 2, 4, 6};

// ─── Tara Names (9 types) ───
const List<String> _taraNames = [
  'ಜನ್ಮ ತಾರೆ', 'ಸಂಪತ್ ತಾರೆ', 'ವಿಪತ್ ತಾರೆ', 'ಕ್ಷೇಮ ತಾರೆ',
  'ಪ್ರತ್ಯಕ್ ತಾರೆ', 'ಸಾಧನ ತಾರೆ', 'ನೈಧನ ತಾರೆ', 'ಮಿತ್ರ ತಾರೆ',
  'ಪರಮ ಮಿತ್ರ ತಾರೆ',
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

const double _feetPerHasta = 1.5;

// ─── Shared result model ───
class _VastuResult {
  final int length;
  final int breadth;
  final int area;
  final int perimeterFt;
  final int hasta;
  final int aayaIndex;
  final int aayaValue;
  final int vyayaValue;
  final bool aayaGtVyaya;
  final int nakIndex;
  final int taraIndex;

  _VastuResult({
    required this.length, required this.breadth, required this.area,
    required this.perimeterFt, required this.hasta,
    required this.aayaIndex, required this.aayaValue,
    required this.vyayaValue, required this.aayaGtVyaya,
    required this.nakIndex, required this.taraIndex,
  });

  bool get isGoodAaya => _goodAaya.contains(aayaIndex);
  bool get isGoodTara => _goodTara.contains(taraIndex);
  bool get isExcellent => isGoodAaya && isGoodTara && aayaGtVyaya;
}

// ─── Calculation helper ───
_VastuResult _calculate(int l, int b, int ownerNak) {
  final area = l * b;
  final perimeterFt = 2 * (l + b);
  final hasta = (perimeterFt / _feetPerHasta).round();

  final aayaRem = (hasta * 9) % 8;
  final aayaValue = aayaRem == 0 ? 8 : aayaRem;
  final aayaIndex = aayaValue - 1;

  final vyayaRem = (hasta * 10) % 8;
  final vyayaValue = vyayaRem == 0 ? 8 : vyayaRem;

  final nakRem = (hasta * 8) % 27;
  final nakValue = nakRem == 0 ? 27 : nakRem;
  final nakIndex = nakValue - 1;

  final diff = (nakIndex - ownerNak + 27) % 27;
  final taraIndex = diff % 9;

  return _VastuResult(
    length: l, breadth: b, area: area,
    perimeterFt: perimeterFt, hasta: hasta,
    aayaIndex: aayaIndex, aayaValue: aayaValue,
    vyayaValue: vyayaValue, aayaGtVyaya: aayaValue > vyayaValue,
    nakIndex: nakIndex, taraIndex: taraIndex,
  );
}

// ─── Find factor pairs for a given area (min side >= 5 ft) ───
List<List<int>> _factorPairs(int area, {int minSide = 5}) {
  final pairs = <List<int>>[];
  final limit = sqrt(area).floor();
  for (int i = minSide; i <= limit; i++) {
    if (area % i == 0) {
      final j = area ~/ i;
      if (j >= minSide) {
        pairs.add([i, j]); // i <= j
      }
    }
  }
  return pairs;
}

// ═══════════════════════════════════════════
// MAIN SCREEN WITH TABS
// ═══════════════════════════════════════════

class VastuScreen extends StatefulWidget {
  const VastuScreen({super.key});

  @override
  State<VastuScreen> createState() => _VastuScreenState();
}

class _VastuScreenState extends State<VastuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int? _ownerNakIndex;

  // Tab 1: L × B
  final _minLenCtrl = TextEditingController(text: '30');
  final _maxLenCtrl = TextEditingController(text: '40');
  final _minBreadthCtrl = TextEditingController(text: '40');
  final _maxBreadthCtrl = TextEditingController(text: '50');

  // Tab 2: Sq Ft
  final _minSqftCtrl = TextEditingController(text: '1000');
  final _maxSqftCtrl = TextEditingController(text: '1200');

  List<_VastuResult> _results = [];
  bool _searched = false;
  bool _showOnlyGood = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() { _searched = false; _results = []; });
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _minLenCtrl.dispose();
    _maxLenCtrl.dispose();
    _minBreadthCtrl.dispose();
    _maxBreadthCtrl.dispose();
    _minSqftCtrl.dispose();
    _maxSqftCtrl.dispose();
    super.dispose();
  }

  // ─── Validation ───
  bool _validateNak() {
    if (_ownerNakIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ಯಜಮಾನನ ನಕ್ಷತ್ರ ಆಯ್ಕೆ ಮಾಡಿ (Select Owner\'s Nakshatra)'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  // ─── Search: L × B ───
  void _searchLB() {
    if (!_validateNak()) return;

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
    if ((maxL - minL + 1) * (maxB - minB + 1) > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Range too large. Reduce the range.'), backgroundColor: Colors.red),
      );
      return;
    }

    final results = <_VastuResult>[];
    for (int l = minL; l <= maxL; l++) {
      for (int b = minB; b <= maxB; b++) {
        results.add(_calculate(l, b, _ownerNakIndex!));
      }
    }
    _sortAndSet(results);
  }

  // ─── Search: Sq Ft ───
  void _searchSqft() {
    if (!_validateNak()) return;

    final minSq = int.tryParse(_minSqftCtrl.text) ?? 500;
    final maxSq = int.tryParse(_maxSqftCtrl.text) ?? 2000;

    if (minSq > maxSq) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Min must be ≤ Max'), backgroundColor: Colors.red),
      );
      return;
    }
    if (maxSq - minSq > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max range is 5000 sq ft.'), backgroundColor: Colors.red),
      );
      return;
    }

    final results = <_VastuResult>[];
    for (int sq = minSq; sq <= maxSq; sq++) {
      final pairs = _factorPairs(sq);
      if (pairs.isEmpty) continue; // prime or no valid pairs
      for (final pair in pairs) {
        results.add(_calculate(pair[0], pair[1], _ownerNakIndex!));
      }
    }
    _sortAndSet(results);
  }

  void _sortAndSet(List<_VastuResult> results) {
    results.sort((a, b) {
      if (a.isExcellent && !b.isExcellent) return -1;
      if (!a.isExcellent && b.isExcellent) return 1;
      return a.area.compareTo(b.area);
    });
    setState(() { _results = results; _searched = true; });
  }

  List<_VastuResult> get _filteredResults =>
      _showOnlyGood ? _results.where((r) => r.isExcellent).toList() : _results;

  Color _aayaColor(int i) => _goodAaya.contains(i) ? Colors.green : Colors.red;
  Color _taraColor(int i) => _goodTara.contains(i)
      ? (i == 1 || i == 8 ? Colors.green : Colors.teal)
      : (i == 0 ? Colors.orange : Colors.red);

  // ═══════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════

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
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'ಉದ್ದ × ಅಗಲ (L × B)'),
            Tab(text: 'ವಿಸ್ತೀರ್ಣ (Sq Ft)'),
          ],
          labelColor: kPurple2,
          unselectedLabelColor: kMuted,
          indicatorColor: kPurple2,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Shared: Nakshatra dropdown ──
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),

            // ── Tab content (inputs) ──
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ListenableBuilder(
                      listenable: _tabCtrl,
                      builder: (context, _) {
                        return _tabCtrl.index == 0 ? _buildLBInputs() : _buildSqftInputs();
                      },
                    ),
                  ),

                  // Formula info
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
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
                          Text('• ಆಯ = (ಹಸ್ತ × 9) % 8  |  ವ್ಯಯ = (ಹಸ್ತ × 10) % 8', style: TextStyle(fontSize: 10, color: kMuted)),
                          Text('• ಆಯ > ವ್ಯಯ ಆಗಬೇಕು  |  ನಕ್ಷತ್ರ = (ಹಸ್ತ × 8) % 27', style: TextStyle(fontSize: 10, color: kMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Search button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _tabCtrl.index == 0 ? _searchLB : _searchSqft,
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
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // ── Filter toggle ──
                  if (_searched)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Icon(_showOnlyGood ? Icons.filter_alt : Icons.filter_alt_off,
                                size: 16, color: _showOnlyGood ? kGreen : kMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _showOnlyGood
                                    ? 'ಶುಭ ಫಲಿತಾಂಶ ಮಾತ್ರ (Good only)'
                                    : 'ಎಲ್ಲಾ ಫಲಿತಾಂಶ (All)',
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Icons.home_work_rounded, size: 64, color: kPurple2.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text('ವಿವರ ನಮೂದಿಸಿ ಮತ್ತು ಹುಡುಕಿ', style: TextStyle(color: kMuted, fontSize: 14)),
                            Text('Enter details and search', style: TextStyle(color: kMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  else if (_filteredResults.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.red.withOpacity(0.4)),
                            const SizedBox(height: 8),
                            Text('ಯಾವುದೇ ಶುಭ ಫಲಿತಾಂಶ ಸಿಗಲಿಲ್ಲ', style: TextStyle(color: kMuted, fontSize: 14)),
                            Text('No favorable results. Try turning off the filter ↗',
                                style: TextStyle(color: kPurple2, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _buildResultCard(_filteredResults[index]),
                        ),
                        childCount: _filteredResults.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 1: L × B inputs ───
  Widget _buildLBInputs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ಉದ್ದ / Length (Feet)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPurple2)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _field(_minLenCtrl, 'Min')),
            _sep(),
            Expanded(child: _field(_maxLenCtrl, 'Max')),
          ]),
          const SizedBox(height: 12),
          Text('ಅಗಲ / Breadth (Feet)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPurple2)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _field(_minBreadthCtrl, 'Min')),
            _sep(),
            Expanded(child: _field(_maxBreadthCtrl, 'Max')),
          ]),
        ],
      ),
    );
  }

  // ─── Tab 2: Sq Ft inputs ───
  Widget _buildSqftInputs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ವಿಸ್ತೀರ್ಣ / Area (Sq Ft)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPurple2)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _field(_minSqftCtrl, 'From')),
            _sep(),
            Expanded(child: _field(_maxSqftCtrl, 'To')),
          ]),
          const SizedBox(height: 8),
          Text(
            'ಪ್ರತಿ Sq Ft ಗೆ ಸಾಧ್ಯವಿರುವ ಉದ್ದ × ಅಗಲ ಜೋಡಿಗಳನ್ನು ಹುಡುಕುತ್ತೇವೆ (min side: 5 ft)',
            style: TextStyle(fontSize: 10, color: kMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
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

  Widget _sep() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text('–', style: TextStyle(fontSize: 20, color: kMuted)),
  );

  // ─── Result card ───
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
          // Header
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
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900,
                    color: isExcellent ? Colors.green.shade700 : kPurple2),
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
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 3),
                    Text('ಶುಭ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Perimeter / Hasta
          Text('ಪರಿಧಿ: ${r.perimeterFt} ft  |  ಹಸ್ತ: ${r.hasta}',
            style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          // Aaya
          Row(children: [
            Icon(Icons.flag_rounded, size: 14, color: _aayaColor(r.aayaIndex)),
            const SizedBox(width: 4),
            Text('ಆಯ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
            Flexible(child: Text(
              '${_aayaNames[r.aayaIndex]} (${_aayaEnglish[r.aayaIndex]}) [${r.aayaValue}]',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _aayaColor(r.aayaIndex)),
              overflow: TextOverflow.ellipsis,
            )),
          ]),
          const SizedBox(height: 3),

          // Vyaya
          Row(children: [
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
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                  color: r.aayaGtVyaya ? Colors.green.shade700 : Colors.red.shade700),
              ),
            ),
          ]),
          const SizedBox(height: 6),

          // Building Nakshatra
          Row(children: [
            Icon(Icons.star, size: 14, color: kOrange),
            const SizedBox(width: 4),
            Text('ಕಟ್ಟಡದ ನಕ್ಷತ್ರ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
            Flexible(child: Text(naks[r.nakIndex],
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText),
              overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),

          // Tarabala
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _taraColor(r.taraIndex).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(Icons.shield, size: 14, color: _taraColor(r.taraIndex)),
              const SizedBox(width: 6),
              Text('ತಾರಾಬಲ: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted)),
              Flexible(child: Text(
                '${_taraNames[r.taraIndex]} (${_taraEnglish[r.taraIndex]}) - ${_taraQuality[r.taraIndex]}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _taraColor(r.taraIndex)),
                overflow: TextOverflow.ellipsis,
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

