import 'package:flutter/material.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import '../widgets/common.dart';
import '../widgets/kundali_chart.dart';
import '../widgets/planet_detail_sheet.dart';
import '../widgets/dasha_widget.dart';
import '../widgets/ashtakavarga_widget.dart';

class DashboardScreen extends StatefulWidget {
  final KundaliResult result;
  final String name;
  final String place;
  final DateTime dob;
  final int hour;
  final int minute;
  final String ampm;
  final double lat;
  final double lon;
  final VoidCallback onSave;

  const DashboardScreen({
    super.key,
    required this.result,
    required this.name,
    required this.place,
    required this.dob,
    required this.hour,
    required this.minute,
    required this.ampm,
    required this.lat,
    required this.lon,
    required this.onSave,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _notes = '';
  bool _showSphutas = false;
  int _varga = 1;
  String _chartMode = 'ರಾಶಿ';
  Map<String, int> _aroodhas = {};

  static const _tabs = [
    'ಕುಂಡಲಿ', 'ಗ್ರಹ ಸ್ಫುಟ', 'ಉಪಗ್ರಹ ಸ್ಫುಟ', 'ಆರೂಢ',
    'ದಶ', 'ಪಂಚಾಂಗ', 'ಭಾವ', 'ಅಷ್ಟಕವರ್ಗ',
    'ಟಿಪ್ಪಣಿ', 'ಚಂದಾದಾರಿಕೆ', 'ಬಗ್ಗೆ'
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back/save
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [kPurple1, kPurple2]),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.name.isNotEmpty ? widget.name : 'ಭಾರತೀಯಮ್',
                      style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save, color: Colors.white),
                    onPressed: () {
                      widget.onSave();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('ಉಳಿಸಲಾಗಿದೆ!',
                          style: const TextStyle())));
                    },
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildKundaliTab(),
                  _buildGrahaSphutas(),
                  _buildUpagrahaTab(),
                  _buildAroodhaTab(),
                  _buildDashaTab(),
                  _buildPanchangTab(),
                  _buildBhavaTab(),
                  _buildAshtakavargaTab(),
                  _buildNotesTab(),
                  _buildSubscriptionTab(),
                  _buildAboutTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 1: KUNDALI
  // ─────────────────────────────────────────────
  Widget _buildKundaliTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Varga + chart mode
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _varga,
                    decoration: const InputDecoration(labelText: 'ವರ್ಗ', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('ರಾಶಿ')),
                      DropdownMenuItem(value: 2, child: Text('ಹೋರಾ')),
                      DropdownMenuItem(value: 3, child: Text('ದ್ರೇಕ್ಕಾಣ')),
                      DropdownMenuItem(value: 9, child: Text('ನವಾಂಶ')),
                      DropdownMenuItem(value: 12, child: Text('ದ್ವಾದಶಾಂಶ')),
                      DropdownMenuItem(value: 30, child: Text('ತ್ರಿಂಶಾಂಶ')),
                    ],
                    onChanged: (v) => setState(() { _varga = v!; _chartMode = 'ರಾಶಿ'; }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _chartMode,
                    decoration: const InputDecoration(labelText: 'ಚಾರ್ಟ್ ವಿಧ', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: ['ರಾಶಿ','ಭಾವ','ನವಾಂಶ'].map((m) =>
                      DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() {
                      _chartMode = v!;
                      if (v == 'ಭಾವ') _varga = 1;
                      if (v == 'ನವಾಂಶ') _varga = 9;
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text('ಸ್ಫುಟಗಳನ್ನು ಕುಂಡಲಿಯಲ್ಲಿ ತೋರಿಸಿ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF2B6CB0))),
            value: _showSphutas,
            activeColor: kPurple2,
            onChanged: (v) => setState(() => _showSphutas = v),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          const SizedBox(height: 8),

          // Chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: KundaliChart(
              result: widget.result,
              varga: _chartMode == 'ಭಾವ' ? 1 : (_chartMode == 'ನವಾಂಶ' ? 9 : _varga),
              isBhava: _chartMode == 'ಭಾವ',
              showSphutas: _showSphutas,
            ),
          ),
          const SizedBox(height: 16),

          // Planet buttons
          const SectionTitle('🔍 ಗ್ರಹಗಳ ವಿಸ್ತೃತ ವಿವರ'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: planetOrder.map((p) {
                final info = widget.result.planets[p];
                if (info == null) return const SizedBox.shrink();
                return ElevatedButton(
                  onPressed: () => _showPlanetDetail(p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p == 'ಲಗ್ನ' || p == 'ಮಾಂದಿ'
                        ? kOrange.withOpacity(0.15) : Colors.white,
                    foregroundColor: kText,
                    elevation: 0,
                    side: BorderSide(color: kBorder),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(p, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: p == 'ಲಗ್ನ' || p == 'ಮಾಂದಿ' ? kOrange2 : const Color(0xFF2B6CB0))),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showPlanetDetail(String pName) {
    final info = widget.result.planets[pName];
    if (info == null) return;
    final sun = widget.result.planets['ರವಿ'];
    final detail = AstroCalculator.getPlanetDetail(
      pName, info.longitude, info.speed, sun?.longitude ?? 0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlanetDetailSheet(pName: pName, detail: detail),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 2: GRAHA SPHUTA TABLE
  // ─────────────────────────────────────────────
  Widget _buildGrahaSphutas() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _tableHeader(['ಗ್ರಹ', 'ಸ್ಫುಟ', 'ನಕ್ಷತ್ರ - ಪಾದ']),
            ...planetOrder.map((p) {
              final info = widget.result.planets[p];
              if (info == null) return const SizedBox.shrink();
              return _tableRow([p, formatDeg(info.longitude), '${info.nakshatra} - ${info.pada}'],
                bold0: true);
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 3: UPAGRAHA SPHUTA TABLE
  // ─────────────────────────────────────────────
  Widget _buildUpagrahaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _tableHeader(['ಉಪಗ್ರಹ', 'ರಾಶಿ', 'ಅಂಶ', 'ನಕ್ಷತ್ರ']),
            ...sphutas16Order.map((sp) {
              final deg = widget.result.advSphutas[sp];
              if (deg == null) return const SizedBox.shrink();
              final ri = (deg / 30).floor() % 12;
              final nakIdx = (deg / 13.333333).floor() % 27;
              final pada = ((deg % 13.333333) / 3.333333).floor() + 1;
              return _tableRow([sp, knRashi[ri], formatDeg(deg), '${knNak[nakIdx]}-$pada'],
                bold0: true);
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 4: AROODHA
  // ─────────────────────────────────────────────
  Widget _buildAroodhaTab() {
    String _selAro = 'ಆರೂಢ';
    int _selRashiIdx = 0;
    return StatefulBuilder(builder: (ctx, setS) {
      return SingleChildScrollView(
        child: Column(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('ಆರೂಢ ಚಕ್ರ'),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selAro,
                        items: ['ಆರೂಢ','ಉದಯ','ಲಗ್ನಾಂಶ','ಛತ್ರ','ಸ್ಪೃಷ್ಟಾಂಗ','ಚಂದ್ರ','ತಾಂಬೂಲ']
                          .map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle()))).toList(),
                        onChanged: (v) => setS(() => _selAro = v!),
                        decoration: const InputDecoration(labelText: 'ಆರೂಢ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selRashiIdx,
                        items: List.generate(12, (i) => DropdownMenuItem(
                          value: i, child: Text(knRashi[i], style: const TextStyle()))).toList(),
                        onChanged: (v) => setS(() => _selRashiIdx = v!),
                        decoration: const InputDecoration(labelText: 'ರಾಶಿ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => setS(() => _aroodhas[_selAro] = _selRashiIdx),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10)),
                      child: Text('ಸೇರಿಸಿ', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  if (_aroodhas.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setS(() => _aroodhas.clear()),
                      child: Text('ತೆರವುಗೊಳಿಸಿ', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: KundaliChart(
                result: widget.result,
                varga: 1,
                isBhava: false,
                showSphutas: false,
                aroodhas: _aroodhas,
                centerLabel: 'ಆರೂಢ\nಚಕ್ರ',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  // ─────────────────────────────────────────────
  // TAB 5: DASHA
  // ─────────────────────────────────────────────
  Widget _buildDashaTab() {
    final pan = widget.result.panchang;
    return SingleChildScrollView(
      child: Column(
        children: [
          AppCard(
            child: Text(
              'ಶಿಷ್ಟ ದಶೆ: ${pan.dashaLord}  ಉಳಿಕೆ: ${pan.dashaBalance}',
              style: TextStyle(
                color: kOrange, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
          DashaWidget(dashas: widget.result.dashas),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 6: PANCHANG
  // ─────────────────────────────────────────────
  Widget _buildPanchangTab() {
    final pan = widget.result.panchang;
    final dateStr = '${widget.dob.day.toString().padLeft(2,'0')}-${widget.dob.month.toString().padLeft(2,'0')}-${widget.dob.year}';
    final timeStr = '${widget.hour}:${widget.minute.toString().padLeft(2,'0')} ${widget.ampm}';
    return SingleChildScrollView(
      child: Column(
        children: [
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _kv('ಸ್ಥಳ', widget.place),
            _kv('ದಿನಾಂಕ', dateStr),
            _kv('ಸಮಯ', timeStr),
          ])),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _tableRow(['ವಾರ', pan.vara]),
              _tableRow(['ತಿಥಿ', pan.tithi]),
              _tableRow(['ನಕ್ಷತ್ರ', pan.nakshatra]),
              _tableRow(['ಯೋಗ', pan.yoga]),
              _tableRow(['ಕರಣ', pan.karana]),
              _tableRow(['ಚಂದ್ರ ರಾಶಿ', pan.chandraRashi]),
              _tableRow(['ಉದಯಾದಿ ಘಟಿ', pan.udayadiGhati]),
              _tableRow(['ಗತ ಘಟಿ', pan.gataGhati]),
              _tableRow(['ಪರಮ ಘಟಿ', pan.paramaGhati]),
              _tableRow(['ಶೇಷ ಘಟಿ', pan.shesha]),
            ]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 7: BHAVA
  // ─────────────────────────────────────────────
  Widget _buildBhavaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _tableHeader(['ಭಾವ', 'ಮಧ್ಯ ಸ್ಫುಟ', 'ರಾಶಿ']),
            ...List.generate(12, (i) {
              final deg = widget.result.bhavas[i];
              return _tableRow(
                ['${i+1}', formatDeg(deg), knRashi[(deg/30).floor() % 12]],
                bold0: true,
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 8: ASHTAKAVARGA
  // ─────────────────────────────────────────────
  Widget _buildAshtakavargaTab() {
    return AshtakavargaWidget(
      savBindus: widget.result.savBindus,
      bavBindus: widget.result.bavBindus,
    );
  }

  // ─────────────────────────────────────────────
  // TAB 9: NOTES
  // ─────────────────────────────────────────────
  Widget _buildNotesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        maxLines: null,
        expands: true,
        onChanged: (v) => _notes = v,
        controller: TextEditingController(text: _notes),
        decoration: InputDecoration(
          hintText: 'ನಿಮ್ಮ ಟಿಪ್ಪಣಿಗಳನ್ನು ಇಲ್ಲಿ ಬರೆಯಿರಿ...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF2D3748)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 10: SUBSCRIPTION
  // ─────────────────────────────────────────────
  Widget _buildSubscriptionTab() {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🚫', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text('ಜಾಹೀರಾತು-ಮುಕ್ತ', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('ಜಾಹೀರಾತುಗಳಿಲ್ಲದೆ ನಿರಂತರವಾಗಿ ಆ್ಯಪ್ ಬಳಸಿ.',
              style: TextStyle(color: kMuted), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: Text('ಜಾಹೀರಾತು ತೆಗೆಯಿರಿ (₹99)',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 11: ABOUT
  // ─────────────────────────────────────────────
  Widget _buildAboutTab() {
    return SingleChildScrollView(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ಭಾರತೀಯಮ್', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('ಆವೃತ್ತಿ: 1.0.1', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('ನಿಖರವಾದ ವೈದಿಕ ಜ್ಯೋತಿಷ್ಯ ಲೆಕ್ಕಾಚಾರಗಳಿಗಾಗಿ ವಿನ್ಯಾಸಗೊಳಿಸಲಾಗಿದೆ.',
              style: TextStyle(color: kMuted, height: 1.6)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  Widget _tableHeader(List<String> cols) {
    return Container(
      color: const Color(0xFFEDF2F7),
      child: Row(
        children: cols.asMap().entries.map((e) => Expanded(
          flex: e.key == 1 ? 2 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Text(e.value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _tableRow(List<String> cols, {bool bold0 = false}) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEDF2F7)))),
      child: Row(
        children: cols.asMap().entries.map((e) => Expanded(
          flex: e.key == 1 ? 2 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Text(e.value, style: TextStyle(
              fontSize: 13,
              fontWeight: (e.key == 0 && bold0) ? FontWeight.w700 : FontWeight.normal,
            )),
          ),
        )).toList(),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text('$k: ', style: TextStyle(fontWeight: FontWeight.w800, color: const Color(0xFF2B6CB0))),
        Expanded(child: Text(v, style: const TextStyle())),
      ]),
    );
  }
}
