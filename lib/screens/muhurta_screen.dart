import 'package:flutter/material.dart';
import 'package:sweph/sweph.dart' hide kIsWeb;
import '../widgets/common.dart';
import '../constants/strings.dart';
import '../constants/places.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import '../core/muhurta_rules.dart';
import '../services/location_service.dart';

/// ──────────────────────────────────────────────────────────────
/// Simplified Muhoorta Screen
/// Same as Taranukoola Muhurta Shodhane but much simpler UI
/// Only filters: Tithi, Nakshatra, Tara, Vara, Shuddhi, Abhijit
/// ──────────────────────────────────────────────────────────────
class MuhurtaScreen extends StatefulWidget {
  const MuhurtaScreen({super.key});
  @override
  State<MuhurtaScreen> createState() => _MuhurtaScreenState();
}

class _MuhurtaScreenState extends State<MuhurtaScreen> {
  // Default allowed lagnas: Vrishabha(1), Mithuna(2), Kataka(3), Kanya(5), Tula(6), Dhanu(8), Meena(11)
  // Default allowed lagnas (user can change)
  final Set<int> _allowedLagnas = {1, 2, 3, 5, 6, 8, 11};
  static const _rashiNames = ['ಮೇಷ','ವೃಷಭ','ಮಿಥುನ','ಕರ್ಕ','ಸಿಂಹ','ಕನ್ಯಾ','ತುಲಾ','ವೃಶ್ಚಿಕ','ಧನು','ಮಕರ','ಕುಂಭ','ಮೀನ'];
  static const _rashiEn = ['Mesha','Vrishabha','Mithuna','Kataka','Simha','Kanya','Tula','Vrischika','Dhanu','Makara','Kumbha','Meena'];

  // Minimum score to show
  int _minScore = 40;
  // Inputs
  MuhurtaEvent _event = MuhurtaEvent.vivaha;
  int _nakIdx = 0;
  DateTime _monthFrom = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _monthTo = DateTime(DateTime.now().year, DateTime.now().month + 1);

  // User-overridable rules (loaded from event defaults)
  Set<int> _userTithis = {};
  Set<int> _userNakshatras = {};
  Set<int> _userVaras = {};

  // Lagna shuddhi filters
  bool _filterLagnaShuddhi = true;
  bool _filterSaptamaShuddhi = true;
  bool _filterAshtamaShuddhi = false;
  bool _filterGuruAnukoola = false;

  @override
  void initState() {
    super.initState();
    _loadEventDefaults();
  }

  void _loadEventDefaults() {
    final rules = muhurtaRules[_event];
    _userTithis = Set<int>.from(rules?.allowedTithis ?? List.generate(30, (i) => i));
    _userNakshatras = Set<int>.from(rules?.allowedNakshatras ?? List.generate(27, (i) => i));
    _userVaras = Set<int>.from(rules?.allowedVaras ?? List.generate(7, (i) => i));
  }

  // Location
  double _lat = LocationService.lat;
  double _lon = LocationService.lon;
  double _tz = LocationService.tzOffset;
  String _place = LocationService.place;

  // Results
  bool _searching = false;
  List<Map<String, dynamic>> _results = [];
  final Set<String> _expanded = {};
  int _displayCount = 20;

  // Derive rashi from nakshatra (approximate: nakIdx * 4 ~/ 9)
  int get _rashiIdx => (_nakIdx * 4 ~/ 9);

  // Available months (12 months from now)
  List<DateTime> get _months => List.generate(12, (i) =>
    DateTime(DateTime.now().year, DateTime.now().month + i));

  // ── Search ──
  Future<void> _search() async {
    setState(() { _searching = true; _results = []; _displayCount = 20; _expanded.clear(); });

    try { await Ephemeris.initSweph(); } catch (_) {}

    final startDate = DateTime.utc(_monthFrom.year, _monthFrom.month, 1);
    final endDate = DateTime.utc(_monthTo.year, _monthTo.month + 1, 0);
    final found = <Map<String, dynamic>>[];

    for (var d = startDate; !d.isAfter(endDate); d = d.add(const Duration(days: 1))) {
      try {
        final srSs = Ephemeris.findSunriseSetForDate(
          d.year, d.month, d.day, _lat, _lon, tzOffset: _tz);
        final srFrac = ((srSs[0] + 0.5 + (_tz / 24.0)) % 1.0 + 1.0) % 1.0;
        final srHour = srFrac * 24.0 + (1.0 / 60.0);
        final ssFrac = ((srSs[1] + 0.5 + (_tz / 24.0)) % 1.0 + 1.0) % 1.0;

        final kr = await AstroCalculator.calculate(
          year: d.year, month: d.month, day: d.day,
          hourUtcOffset: _tz, hour24: srHour,
          lat: _lat, lon: _lon,
          ayanamsaMode: 'lahiri', trueNode: true,
        );
        if (kr == null) continue;

        final pan = kr.panchang;
        final varaIdx = knVara.indexOf(pan.vara).clamp(0, 6);
        final moonRashiIdx = (kr.planets['ಚಂದ್ರ']!.longitude / 30).floor() % 12;
        final jupRashiIdx = (kr.planets['ಗುರು']!.longitude / 30).floor() % 12;
        final sunRashiIdx = (kr.planets['ರವಿ']!.longitude / 30).floor() % 12;

        // Abhijit time
        final srMins = srFrac * 24.0 * 60.0;
        final ssMins = ssFrac * 24.0 * 60.0;
        final dayDur = ((ssMins - srMins) + 1440) % 1440;
        final muhDur = dayDur / 15.0;
        final abhStart = srMins + 7 * muhDur;
        final abhEnd = abhStart + muhDur;
        final abhStr = '${_fmtMins(abhStart)} - ${_fmtMins(abhEnd)}';

        // Use the existing engine!
        final mResult = evaluateMuhurta(
          event: _event,
          tithiIndex: pan.tithiIndex,
          tithiName: pan.tithi,
          nakshatraIndex: pan.nakshatraIndex,
          nakshatraName: pan.nakshatra,
          varaIndex: varaIdx,
          varaName: pan.vara,
          yogaIndex: (kr.planets['ಚಂದ್ರ'] != null && kr.planets['ರವಿ'] != null)
            ? (((kr.planets['ಚಂದ್ರ']!.longitude + kr.planets['ರವಿ']!.longitude) % 360) / 13.333333).floor() % 27
            : 0,
          yogaName: pan.yoga,
          karanaName: pan.karana,
          moonRashiIndex: moonRashiIdx,
          jupiterRashiIndex: jupRashiIdx,
          sunRashiIndex: sunRashiIdx,
          janmaNakIdx1: _nakIdx,
          janmaRashiIdx1: _rashiIdx,
          abhijitTimeWindow: abhStr,
          overrideRules: MuhurtaEventRules(
            allowedTithis: _userTithis.toList(),
            allowedNakshatras: _userNakshatras.toList(),
            allowedVaras: _userVaras.toList(),
          ),
        );

        // Only show days with score >= 40
        if (mResult.score >= _minScore) {
          // Compute lagna windows for this day
          final allLagnaWindows = _scanLagnas(srSs[0], srSs[1]);
          // Filter by user shuddhi settings
          final lagnaWindows = allLagnaWindows.where((w) {
            if (_filterLagnaShuddhi && w['lagnaShuddhi'] != true) return false;
            if (_filterSaptamaShuddhi && w['saptamaShuddhi'] != true) return false;
            if (_filterAshtamaShuddhi && w['ashtamaShuddhi'] != true) return false;
            if (_filterGuruAnukoola && w['guruAnukoola'] != true) return false;
            return true;
          }).toList();

          found.add({
            'date': d,
            'score': mResult.score,
            'verdict': mResult.verdict,
            'vara': pan.vara,
            'tithi': pan.tithi,
            'nakshatra': pan.nakshatra,
            'yoga': pan.yoga,
            'karana': pan.karana,
            'checks': mResult.checks,
            'doshas': mResult.doshas,
            'doshaBhangas': mResult.doshaBhangas,
            'hasAbhijit': mResult.hasAbhijit,
            'abhijitTime': abhStr,
            'sunrise': pan.sunrise,
            'sunset': pan.sunset,
            'tara': mResult.personResults.isNotEmpty ? mResult.personResults[0].taraBala : null,
            'isPerfect': mResult.score >= 80,
            'isCandidate': mResult.score >= _minScore && mResult.score < 80,
            'lagnaWindows': lagnaWindows,
          });
        }
      } catch (_) {}
    }

    // Sort by score descending
    found.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    if (mounted) setState(() { _results = found; _searching = false; });
  }

  String _fmtMins(double mins) {
    final t = mins.round() % 1440;
    final h = t ~/ 60;
    final m = t % 60;
    final ap = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ap';
  }

  /// Scan ascendant from sunrise to sunset, check lagna shuddhi
  List<Map<String, dynamic>> _scanLagnas(double srJd, double ssJd) {
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
    final ayn = Sweph.swe_get_ayanamsa(srJd);
    final double step = 10.0 / (24.0 * 60.0); // 10-minute steps
    final windows = <Map<String, dynamic>>[];

    // Collect samples
    final samples = <_AscSample>[];
    double jd = srJd;
    while (jd <= ssJd + step) {
      final houses = Ephemeris.placidusHousesFull(jd, _lat, _lon);
      if (houses != null && houses.ascmc.length >= 1) {
        final sidAsc = ((houses.ascmc[0] as double) - ayn) % 360.0;
        final rashiIdx = (sidAsc / 30.0).floor() % 12;
        final localFrac = ((jd + 0.5 + (_tz / 24.0)) % 1.0 + 1.0) % 1.0;
        samples.add(_AscSample(jd: jd, rashiIdx: rashiIdx, localMins: localFrac * 24.0 * 60.0));
      }
      jd += step;
    }
    if (samples.isEmpty) return [];

    const engToKn = {
      'Sun': 'ರವಿ', 'Moon': 'ಚಂದ್ರ', 'Mercury': 'ಬುಧ', 'Venus': 'ಶುಕ್ರ',
      'Mars': 'ಕುಜ', 'Jupiter': 'ಗುರು', 'Saturn': 'ಶನಿ',
      'Rahu': 'ರಾಹು', 'Ketu': 'ಕೇತು',
    };

    int curRashi = samples.first.rashiIdx;
    double startMins = samples.first.localMins;
    double windowStartJd = samples.first.jd;

    for (int i = 1; i < samples.length; i++) {
      if (samples[i].rashiIdx != curRashi || i == samples.length - 1) {
        final endMins = samples[i].localMins;
        final windowEndJd = samples[i].jd;

        if (_allowedLagnas.contains(curRashi)) {
          // Get planet positions at window midpoint
          final midJd = (windowStartJd + windowEndJd) / 2.0;
          final positions = Ephemeris.calcAll(midJd, 'lahiri', true);
          final Map<String, int> planetRashis = {};
          for (final e in positions.entries) {
            final kn = engToKn[e.key];
            if (kn != null) planetRashis[kn] = (e.value[0] / 30.0).floor() % 12;
          }

          final saptamaRashi = (curRashi + 6) % 12;
          final ashtamaRashi = (curRashi + 7) % 12;

          final lagnaGrahas = findMaleficsInRashi(curRashi, planetRashis);
          final saptamaGrahas = findMaleficsInRashi(saptamaRashi, planetRashis);
          final ashtamaGrahas = findAllPlanetsInRashi(ashtamaRashi, planetRashis);

          final lagnaShuddhi = lagnaGrahas.isEmpty;
          final saptamaShuddhi = saptamaGrahas.isEmpty;
          final ashtamaShuddhi = ashtamaGrahas.isEmpty;
          final isShubha = lagnaShuddhi && saptamaShuddhi;

          // Check Guru anukoola
          final guruRashi = planetRashis['ಗುರು'] ?? -1;
          final guruAnukoola = guruRashi >= 0 && isGuruAnukoolaForLagna(curRashi, guruRashi);

          windows.add({
            'rashi': trAll(_rashiNames[curRashi]),
            'rashiIdx': curRashi,
            'start': _fmtMins(startMins),
            'end': _fmtMins(endMins),
            'lagnaShuddhi': lagnaShuddhi,
            'saptamaShuddhi': saptamaShuddhi,
            'ashtamaShuddhi': ashtamaShuddhi,
            'isShubha': isShubha,
            'lagnaGrahas': lagnaGrahas,
            'saptamaGrahas': saptamaGrahas,
            'ashtamaGrahas': ashtamaGrahas,
            'guruAnukoola': guruAnukoola,
          });
        }
        curRashi = samples[i].rashiIdx;
        startMins = samples[i].localMins;
        windowStartJd = samples[i].jd;
      }
    }
    return windows;
  }

  // ── Settings dialog ──
  void _showSettings() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final eventInfo = muhurtaEventNames[_event]!;
          return AlertDialog(
            title: Row(children: [
              Icon(Icons.tune, color: kPurple1, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text('ನಿಯಮ ಬದಲಾಯಿಸಿ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
            ]),
            content: SizedBox(
              width: 340, height: 500,
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      labelColor: kPurple1,
                      unselectedLabelColor: kMuted,
                      labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                      indicatorColor: kPurple1,
                      tabs: const [
                        Tab(text: 'ತಿಥಿ'),
                        Tab(text: 'ನಕ್ಷತ್ರ'),
                        Tab(text: 'ವಾರ'),
                        Tab(text: 'ಲಗ್ನ'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // ── TAB 1: TITHI ──
                          ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(children: [
                                  Text('${_userTithis.length}/30', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kTeal)),
                                  const Spacer(),
                                  TextButton(onPressed: () => setDlgState(() => _userTithis = Set.from(List.generate(30, (i) => i))), child: Text('ಎಲ್ಲಾ', style: TextStyle(fontSize: 11))),
                                  TextButton(onPressed: () => setDlgState(() => _userTithis.clear()), child: Text('ಯಾವುದೂ ಇಲ್ಲ', style: TextStyle(fontSize: 11))),
                                ]),
                              ),
                              ...List.generate(30, (i) => CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _userTithis.contains(i),
                                activeColor: kTeal,
                                title: Text(knTithi[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText)),
                                onChanged: (v) => setDlgState(() { if (v == true) _userTithis.add(i); else _userTithis.remove(i); }),
                              )),
                            ],
                          ),

                          // ── TAB 2: NAKSHATRA ──
                          ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(children: [
                                  Text('${_userNakshatras.length}/27', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kTeal)),
                                  const Spacer(),
                                  TextButton(onPressed: () => setDlgState(() => _userNakshatras = Set.from(List.generate(27, (i) => i))), child: Text('ಎಲ್ಲಾ', style: TextStyle(fontSize: 11))),
                                  TextButton(onPressed: () => setDlgState(() => _userNakshatras.clear()), child: Text('ಯಾವುದೂ ಇಲ್ಲ', style: TextStyle(fontSize: 11))),
                                ]),
                              ),
                              ...List.generate(27, (i) => CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _userNakshatras.contains(i),
                                activeColor: kTeal,
                                title: Text('${i + 1}. ${knNak[i]}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText)),
                                onChanged: (v) => setDlgState(() { if (v == true) _userNakshatras.add(i); else _userNakshatras.remove(i); }),
                              )),
                            ],
                          ),

                          // ── TAB 3: VARA ──
                          ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text('${_userVaras.length}/7 ವಾರ ಆಯ್ಕೆ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kTeal)),
                              ),
                              ...List.generate(7, (i) => CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _userVaras.contains(i),
                                activeColor: kTeal,
                                title: Text(knVara[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
                                onChanged: (v) => setDlgState(() { if (v == true) _userVaras.add(i); else _userVaras.remove(i); }),
                              )),
                            ],
                          ),

                          // ── TAB 4: LAGNA ──
                          ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(children: [
                                  Text('${_allowedLagnas.length}/12 ಲಗ್ನ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kTeal)),
                                  const Spacer(),
                                  TextButton(onPressed: () => setDlgState(() => _allowedLagnas.addAll(List.generate(12, (i) => i))), child: Text('ಎಲ್ಲಾ', style: TextStyle(fontSize: 11))),
                                  TextButton(onPressed: () => setDlgState(() => _allowedLagnas.clear()), child: Text('ಯಾವುದೂ ಇಲ್ಲ', style: TextStyle(fontSize: 11))),
                                ]),
                              ),
                              ...List.generate(12, (i) => CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _allowedLagnas.contains(i),
                                activeColor: kTeal,
                                title: Text('${_rashiNames[i]} (${_rashiEn[i]})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
                                onChanged: (v) => setDlgState(() { if (v == true) _allowedLagnas.add(i); else _allowedLagnas.remove(i); }),
                              )),
                              const Divider(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('🛡 ಲಗ್ನ ಶುದ್ಧಿ ನಿಯಮ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kPurple1)),
                              ),
                              const SizedBox(height: 4),
                              SwitchListTile(
                                dense: true, activeColor: kTeal,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _filterLagnaShuddhi,
                                title: Text('ಲಗ್ನ ಶುದ್ಧಿ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
                                subtitle: Text('ಲಗ್ನದಲ್ಲಿ ಪಾಪ ಗ್ರಹ ಇಲ್ಲ', style: TextStyle(fontSize: 10, color: kMuted)),
                                onChanged: (v) => setDlgState(() => _filterLagnaShuddhi = v),
                              ),
                              SwitchListTile(
                                dense: true, activeColor: kTeal,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _filterSaptamaShuddhi,
                                title: Text('ಸಪ್ತಮ ಶುದ್ಧಿ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
                                subtitle: Text('೭ನೇ ಮನೆಯಲ್ಲಿ ಪಾಪ ಗ್ರಹ ಇಲ್ಲ', style: TextStyle(fontSize: 10, color: kMuted)),
                                onChanged: (v) => setDlgState(() => _filterSaptamaShuddhi = v),
                              ),
                              SwitchListTile(
                                dense: true, activeColor: kTeal,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _filterAshtamaShuddhi,
                                title: Text('ಅಷ್ಟಮ ಶುದ್ಧಿ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
                                subtitle: Text('೮ನೇ ಮನೆಯಲ್ಲಿ ಗ್ರಹ ಇಲ್ಲ', style: TextStyle(fontSize: 10, color: kMuted)),
                                onChanged: (v) => setDlgState(() => _filterAshtamaShuddhi = v),
                              ),
                              SwitchListTile(
                                dense: true, activeColor: kTeal,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _filterGuruAnukoola,
                                title: Text('ಗುರು ಅನುಕೂಲ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
                                subtitle: Text('ಗುರು ಕೇಂದ್ರ/ತ್ರಿಕೋಣದಲ್ಲಿ', style: TextStyle(fontSize: 10, color: kMuted)),
                                onChanged: (v) => setDlgState(() => _filterGuruAnukoola = v),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => setDlgState(() => _loadEventDefaults()),
                child: Text('ಡೀಫಾಲ್ಟ್', style: TextStyle(color: kMuted)),
              ),
              ElevatedButton(
                onPressed: () { Navigator.pop(ctx); setState(() {}); },
                style: ElevatedButton.styleFrom(backgroundColor: kPurple1, foregroundColor: Colors.white),
                child: const Text('ಉಳಿಸಿ', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Location picker ──
  Future<void> _pickLocation() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          List<Map<String, dynamic>> results = [];
          return AlertDialog(
            title: Text(AppLocale.l('selectPlace')),
            content: SizedBox(
              width: 300, height: 400,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(hintText: AppLocale.l('searchPlace'), prefixIcon: const Icon(Icons.search)),
                    onChanged: (v) {
                      if (v.length < 2) { setDlgState(() => results = []); return; }
                      final r = searchWorldCities(v, limit: 20);
                      setDlgState(() => results = r);
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final r = results[i];
                        return ListTile(
                          title: Text('${r['n']} (${r['c']})', style: const TextStyle(fontSize: 13)),
                          subtitle: Text('${(r['la'] as double).toStringAsFixed(2)}°, ${(r['lo'] as double).toStringAsFixed(2)}°', style: const TextStyle(fontSize: 11)),
                          onTap: () => Navigator.pop(ctx, r),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (result != null) {
      setState(() {
        _lat = (result['la'] as num).toDouble();
        _lon = (result['lo'] as num).toDouble();
        _tz = (result['tz'] as num).toDouble();
        _place = '${result['n']}, ${result['c']}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nakNames = List.generate(27, (i) => trAll(knNak[i]));
    final mNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(AppLocale.l('muhurtaLabel'), style: TextStyle(fontWeight: FontWeight.w900, color: kText)),
        backgroundColor: kCard,
        elevation: 0,
        iconTheme: IconThemeData(color: kText),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: kPurple2),
            tooltip: 'ನಿಯಮ ಬದಲಾಯಿಸಿ',
            onPressed: _showSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ResponsiveCenter(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── INPUT CARD ──
            AppCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppLocale.l('muhurtaLabel'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPurple1)),
                const SizedBox(height: 12),

                // Location
                Text('📍 ${AppLocale.l('selectPlace')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _pickLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                    child: Row(children: [
                      Icon(Icons.location_on, size: 16, color: kPurple2),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_place, style: TextStyle(fontSize: 13, color: kText), overflow: TextOverflow.ellipsis)),
                      Icon(Icons.edit, size: 14, color: kMuted),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),

                // Event type
                Text('🪔 ${AppLocale.l('selectEvent')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                  child: DropdownButtonHideUnderline(child: DropdownButton<MuhurtaEvent>(
                    isExpanded: true, value: _event, dropdownColor: kCard,
                    style: TextStyle(color: kText, fontSize: 14),
                    items: MuhurtaEvent.values.map((e) {
                      final info = muhurtaEventNames[e]!;
                      return DropdownMenuItem(value: e, child: Text('${AppLocale.l(info.localeKey)} (${info.englishName})', overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (v) => setState(() { _event = v!; _loadEventDefaults(); }),
                  )),
                ),
                const SizedBox(height: 10),

                // Birth Nakshatra
                Text('⭐ ಜನ್ಮ ನಕ್ಷತ್ರ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                  child: DropdownButtonHideUnderline(child: DropdownButton<int>(
                    isExpanded: true, value: _nakIdx, dropdownColor: kCard,
                    style: TextStyle(color: kText, fontSize: 14),
                    items: List.generate(27, (i) => DropdownMenuItem(value: i, child: Text(nakNames[i]))),
                    onChanged: (v) => setState(() => _nakIdx = v!),
                  )),
                ),
                const SizedBox(height: 10),

                // Month range
                Text('📅 ${AppLocale.l('selectMonth')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                    child: DropdownButtonHideUnderline(child: DropdownButton<DateTime>(
                      isExpanded: true, value: _monthFrom, dropdownColor: kCard,
                      style: TextStyle(color: kText, fontSize: 13),
                      items: _months.map((m) => DropdownMenuItem(value: m, child: Text('${mNames[m.month]} ${m.year}'))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() {
                          _monthFrom = v;
                          if (_monthTo.isBefore(v)) _monthTo = v;
                        });
                      },
                    )),
                  )),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('→', style: TextStyle(fontSize: 18, color: kMuted))),
                  Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                    child: DropdownButtonHideUnderline(child: DropdownButton<DateTime>(
                      isExpanded: true, value: _monthTo, dropdownColor: kCard,
                      style: TextStyle(color: kText, fontSize: 13),
                      items: _months.where((m) => !m.isBefore(_monthFrom)).map((m) => DropdownMenuItem(value: m, child: Text('${mNames[m.month]} ${m.year}'))).toList(),
                      onChanged: (v) => setState(() => _monthTo = v!),
                    )),
                  )),
                ]),
                const SizedBox(height: 14),

                // Search button
                ElevatedButton.icon(
                  onPressed: _searching ? null : _search,
                  icon: _searching
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search),
                  label: Text(
                    _searching ? '...' : AppLocale.l('searchMuhurta'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurple1, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            )),
            const SizedBox(height: 12),

            // ── RESULTS ──
            if (_searching)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (!_searching && _results.isNotEmpty) ...[
              Row(children: [
                Text('${_results.length} ${AppLocale.l('mDaysFound')}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTeal)),
                const SizedBox(width: 8),
                Text(
                  '(${_results.where((r) => r['isPerfect'] == true).length} ${AppLocale.l('mPerfect')}, ${_results.where((r) => r['isCandidate'] == true).length} ${AppLocale.l('mConditional')})',
                  style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600),
                ),
              ]),
              const SizedBox(height: 8),
              ...List.generate(
                _results.length < _displayCount ? _results.length : _displayCount,
                (i) => _buildResultCard(_results[i]),
              ),
              if (_displayCount < _results.length)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextButton.icon(
                    onPressed: () => setState(() { _displayCount += 20; }),
                    icon: Icon(Icons.expand_more, color: kPurple2),
                    label: Text('${AppLocale.l('mShowMore')} (${_results.length - _displayCount} ${AppLocale.l('mRemaining')})',
                      style: TextStyle(color: kPurple2, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],

            if (!_searching && _results.isEmpty && _expanded.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('ಯಾವ ಮುಹೂರ್ತ ಸಿಗಲಿಲ್ಲ', style: TextStyle(fontSize: 14, color: kMuted))),
              ),
          ],
        )),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> r) {
    final date = r['date'] as DateTime;
    final score = r['score'] as int;
    final isPerfect = r['isPerfect'] == true;
    final isCandidate = r['isCandidate'] == true;
    final Color scoreColor = isPerfect ? Colors.green : (isCandidate ? Colors.amber.shade800 : Colors.red);
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final dateKey = dateStr;
    final isExpanded = _expanded.contains(dateKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header (tappable) ──
          GestureDetector(
            onTap: () => setState(() {
              if (isExpanded) _expanded.remove(dateKey);
              else _expanded.add(dateKey);
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.08),
                borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(11))
                  : BorderRadius.circular(11),
              ),
              child: Row(children: [
                Icon(isPerfect ? Icons.stars : (isCandidate ? Icons.warning_amber_rounded : Icons.calendar_today), size: 16, color: scoreColor),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$dateStr  ${trAll(r['vara'])}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kText)),
                    Text('${trAll(r['tithi'])} • ${trAll(r['nakshatra'])}', style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: scoreColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text('$score', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: scoreColor)),
                ),
                const SizedBox(width: 6),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: kMuted),
              ]),
            ),
          ),

          // ── Details (expandable) ──
          if (isExpanded) ...[
            // Sunrise/Sunset & Abhijit
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: kBg.withOpacity(0.5),
              child: Row(children: [
                Text('☀ ${r['sunrise']}', style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Text('🌙 ${r['sunset']}', style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (r['hasAbhijit'] == true)
                  Text('⏰ ಅಭಿಜಿತ್: ${r['abhijitTime']}', style: TextStyle(fontSize: 11, color: kTeal, fontWeight: FontWeight.w700)),
              ]),
            ),

            // Tara bala
            if (r['tara'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: (r['tara'] as TaraResult).isGood ? kGreen.withOpacity(0.06) : Colors.red.withOpacity(0.06),
                child: Row(children: [
                  Icon((r['tara'] as TaraResult).isGood ? Icons.check_circle : Icons.cancel,
                    size: 14, color: (r['tara'] as TaraResult).isGood ? kGreen : Colors.red),
                  const SizedBox(width: 6),
                  Text('ತಾರಾ ಬಲ: ${(r['tara'] as TaraResult).taraName}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                      color: (r['tara'] as TaraResult).isGood ? kGreen : Colors.red)),
                ]),
              ),

            // Dosha Bhangas
            if ((r['doshaBhangas'] as List).isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: kGreen.withOpacity(0.06),
                child: Row(children: [
                  Icon(Icons.healing, size: 14, color: kGreen),
                  const SizedBox(width: 6),
                  Expanded(child: Text((r['doshaBhangas'] as List).join(' • '),
                    style: TextStyle(fontSize: 11, color: kGreen, fontWeight: FontWeight.w700))),
                ]),
              ),

            // Panchanga Shuddhi table
            if (r['checks'] != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: kPurple1.withOpacity(0.08),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      ),
                      child: Text(AppLocale.l('panchaShuddhi'), style: TextStyle(fontWeight: FontWeight.w800, color: kPurple1, fontSize: 13)),
                    ),
                    ...(r['checks'] as List<MuhurtaCheckItem>).map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.5)))),
                      child: Row(children: [
                        Icon(c.passed ? Icons.check_circle : Icons.cancel,
                          color: c.passed ? Colors.green : Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(c.label, style: TextStyle(fontWeight: FontWeight.w700, color: kText, fontSize: 12)),
                        const Spacer(),
                        Flexible(child: Text(c.value, style: TextStyle(color: kMuted, fontSize: 12), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
                      ]),
                    )),
                  ]),
                ),
              ),

            // Doshas
            if ((r['doshas'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠ ದೋಷಗಳು:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red)),
                    ...(r['doshas'] as List).map((d) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text('• $d', style: TextStyle(fontSize: 11, color: Colors.red.withOpacity(0.8))),
                    )),
                  ],
                ),
              ),

            // Lagna Windows
            if ((r['lagnaWindows'] as List?)?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: kTeal.withOpacity(0.08),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      ),
                      child: Text('🏠 ಲಗ್ನ ಶುದ್ಧಿ', style: TextStyle(fontWeight: FontWeight.w800, color: kTeal, fontSize: 13)),
                    ),
                    ...(r['lagnaWindows'] as List).map((w) {
                      final wMap = w as Map<String, dynamic>;
                      final isShubha = wMap['isShubha'] == true;
                      final lShuddhi = wMap['lagnaShuddhi'] == true;
                      final sShuddhi = wMap['saptamaShuddhi'] == true;
                      final aShuddhi = wMap['ashtamaShuddhi'] == true;
                      final guruOk = wMap['guruAnukoola'] == true;
                      final lG = (wMap['lagnaGrahas'] as List?)?.join(', ') ?? '';
                      final sG = (wMap['saptamaGrahas'] as List?)?.join(', ') ?? '';
                      final aG = (wMap['ashtamaGrahas'] as List?)?.join(', ') ?? '';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isShubha ? Colors.green.withOpacity(0.04) : Colors.red.withOpacity(0.04),
                          border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.5))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(isShubha ? Icons.check_circle : Icons.warning_amber_rounded, size: 16, color: isShubha ? Colors.green : Colors.orange),
                              const SizedBox(width: 6),
                              Text(wMap['rashi'] as String, style: TextStyle(fontWeight: FontWeight.w800, color: kText, fontSize: 13)),
                              const Spacer(),
                              Text('${wMap['start']} - ${wMap['end']}', style: TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w700)),
                            ]),
                            const SizedBox(height: 4),
                            Wrap(spacing: 10, runSpacing: 2, children: [
                              _shuddhiChip('ಲಗ್ನ', lShuddhi, lG),
                              _shuddhiChip('೭ ಮ', sShuddhi, sG),
                              _shuddhiChip('೮ ಮ', aShuddhi, aG),
                              if (guruOk) Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.star, size: 12, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text('ಗುರು✓', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
                              ]),
                            ]),
                          ],
                        ),
                      );
                    }),
                  ]),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _shuddhiChip(String label, bool ok, String grahas) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(ok ? Icons.check_circle : Icons.cancel, size: 12, color: ok ? Colors.green : Colors.red),
      const SizedBox(width: 2),
      Text('$label${ok ? '' : ' ($grahas)'}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ok ? Colors.green : Colors.red)),
    ]);
  }
}

class _AscSample {
  final double jd;
  final int rashiIdx;
  final double localMins;
  const _AscSample({required this.jd, required this.rashiIdx, required this.localMins});
}
