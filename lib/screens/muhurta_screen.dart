import 'package:flutter/material.dart';
import 'package:sweph/sweph.dart' hide kIsWeb;
import '../widgets/common.dart';
import '../constants/strings.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import '../core/muhurta_rules.dart';
import '../services/location_service.dart';
import '../services/panchanga_cache.dart';
import '../services/panchanga_download_service.dart';

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
    // Preload imported/saved panchanga .bdat cache (same as Taranukoola tab)
    PanchangaCache.instance.loadFromStorage();
  }

  void _loadEventDefaults() {
    final rules = muhurtaRules[_event];
    // Only Shukla Paksha tithis (0-14)
    final allTithis = rules?.allowedTithis ?? List.generate(15, (i) => i);
    _userTithis = Set<int>.from(allTithis.where((t) => t < 15));
    _userNakshatras = Set<int>.from(rules?.allowedNakshatras ?? List.generate(27, (i) => i));
    _userVaras = Set<int>.from(rules?.allowedVaras ?? List.generate(7, (i) => i));
  }

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

  // ── Search (using cached panchanga data) ──
  Future<void> _search() async {
    setState(() { _searching = true; _results = []; _displayCount = 20; _expanded.clear(); });

    try { await Ephemeris.initSweph(); } catch (_) {}

    final cache = PanchangaCache.instance;
    final startDate = DateTime(_monthFrom.year, _monthFrom.month, 1);
    final endDate = DateTime(_monthTo.year, _monthTo.month + 1, 0);

    // Load saved/imported .bdat cache first (fast path)
    if (!cache.isLoaded) {
      try { await cache.loadFromStorage(); } catch (_) {}
    }

    // Generate only if no cache at all; if an imported cache exists but
    // doesn't cover the range, don't overwrite it — use the slow path instead.
    final covers = cache.isLoaded &&
        cache.startDate != null && cache.endDate != null &&
        !cache.startDate!.isAfter(startDate) && !cache.endDate!.isBefore(endDate);
    if (cache.isLoaded && !covers) {
      return _searchNonCached();
    }
    if (!cache.isLoaded) {
      try {
        await cache.generate(
          startDate: startDate,
          endDate: endDate,
          lat: LocationService.lat,
          lon: LocationService.lon,
          tzOffset: LocationService.tzOffset,
          zoneName: LocationService.place,
        );
      } catch (_) {
        // Fallback to non-cached
        return _searchNonCached();
      }
    }

    final found = <Map<String, dynamic>>[];
    final days = cache.getDaysInRange(startDate, endDate);

    for (final day in days) {
      // Shukla Paksha only
      if (day.tithiIndex >= 15) continue;

      // Hard filters
      if (!_userTithis.contains(day.tithiIndex)) continue;
      if (!_userNakshatras.contains(day.nakshatraIndex)) continue;
      if (!_userVaras.contains(day.varaIndex)) continue;

      // Abhijit time from sunrise/sunset (computed once per day, reused for lagnas)
      String abhStr = '';
      List<double>? srSs;
      try {
        srSs = Ephemeris.findSunriseSetForDate(
          day.date.year, day.date.month, day.date.day, LocationService.lat, LocationService.lon, tzOffset: LocationService.tzOffset);
        final srFrac = ((srSs[0] + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
        final ssFrac = ((srSs[1] + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
        final srMins = srFrac * 24.0 * 60.0;
        final ssMins = ssFrac * 24.0 * 60.0;
        final dayDur = ((ssMins - srMins) + 1440) % 1440;
        final muhDur = dayDur / 15.0;
        final abhStart = srMins + 7 * muhDur;
        final abhEnd = abhStart + muhDur;
        abhStr = '${_fmtMins(abhStart)} - ${_fmtMins(abhEnd)}';
      } catch (_) {}

      final mResult = evaluateMuhurta(
        event: _event,
        tithiIndex: day.tithiIndex,
        tithiName: day.tithiName,
        nakshatraIndex: day.nakshatraIndex,
        nakshatraName: day.nakshatraName,
        varaIndex: day.varaIndex,
        varaName: day.varaName,
        yogaIndex: day.yogaIndex,
        yogaName: day.yogaName,
        karanaName: day.karanaName,
        moonRashiIndex: day.moonRashiIndex,
        jupiterRashiIndex: day.jupiterRashiIndex,
        sunRashiIndex: day.sunRashiIndex,
        janmaNakIdx1: _nakIdx,
        janmaRashiIdx1: _rashiIdx,
        abhijitTimeWindow: abhStr,
        overrideRules: MuhurtaEventRules(
          allowedTithis: _userTithis.toList(),
          allowedNakshatras: _userNakshatras.toList(),
          allowedVaras: _userVaras.toList(),
        ),
      );

      // Compute lagna windows
      List<Map<String, dynamic>> lagnaWindows = [];
      try {
        if (srSs == null) throw Exception('no sunrise');
        final allLagnaWindows = _scanLagnas(srSs[0], srSs[1]);
        lagnaWindows = allLagnaWindows.where((w) {
          if (_filterLagnaShuddhi && w['lagnaShuddhi'] != true) return false;
          if (_filterSaptamaShuddhi && w['saptamaShuddhi'] != true) return false;
          if (_filterAshtamaShuddhi && w['ashtamaShuddhi'] != true) return false;
          if (_filterGuruAnukoola && w['guruAnukoola'] != true) return false;
          return true;
        }).toList();
      } catch (_) {}

      found.add({
        'date': day.date,
        'vara': day.varaName,
        'tithi': day.tithiName,
        'nakshatra': day.nakshatraName,
        'yoga': day.yogaName,
        'karana': day.karanaName,
        'checks': mResult.checks,
        'doshas': mResult.doshas,
        'doshaBhangas': mResult.doshaBhangas,
        'hasAbhijit': mResult.hasAbhijit,
        'abhijitTime': abhStr,
        'sunrise': day.sunrise,
        'sunset': day.sunset,
        'tara': mResult.personResults.isNotEmpty ? mResult.personResults[0].taraBala : null,
        'lagnaWindows': lagnaWindows,
      });
    }

    found.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    if (mounted) setState(() { _results = found; _searching = false; });
  }

  /// Fallback non-cached search
  Future<void> _searchNonCached() async {
    final startDate = DateTime.utc(_monthFrom.year, _monthFrom.month, 1);
    final endDate = DateTime.utc(_monthTo.year, _monthTo.month + 1, 0);
    final found = <Map<String, dynamic>>[];

    for (var d = startDate; !d.isAfter(endDate); d = d.add(const Duration(days: 1))) {
      try {
        final srSs = Ephemeris.findSunriseSetForDate(d.year, d.month, d.day, LocationService.lat, LocationService.lon, tzOffset: LocationService.tzOffset);
        final srFrac = ((srSs[0] + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
        final srHour = srFrac * 24.0 + (1.0 / 60.0);
        final ssFrac = ((srSs[1] + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;

        final kr = await AstroCalculator.calculate(
          year: d.year, month: d.month, day: d.day,
          hourUtcOffset: LocationService.tzOffset, hour24: srHour,
          lat: LocationService.lat, lon: LocationService.lon,
          ayanamsaMode: 'lahiri', trueNode: true,
        );
        if (kr == null) continue;

        final pan = kr.panchang;
        if (pan.tithiIndex >= 15) continue;
        final varaIdx = knVara.indexOf(pan.vara).clamp(0, 6);
        if (!_userTithis.contains(pan.tithiIndex)) continue;
        if (!_userNakshatras.contains(pan.nakshatraIndex)) continue;
        if (!_userVaras.contains(varaIdx)) continue;

        final srMins = srFrac * 24.0 * 60.0;
        final ssMins = ssFrac * 24.0 * 60.0;
        final dayDur = ((ssMins - srMins) + 1440) % 1440;
        final muhDur = dayDur / 15.0;
        final abhStart = srMins + 7 * muhDur;
        final abhEnd = abhStart + muhDur;
        final abhStr = '${_fmtMins(abhStart)} - ${_fmtMins(abhEnd)}';

        final moonRashiIdx = (kr.planets['ಚಂದ್ರ']!.longitude / 30).floor() % 12;
        final jupRashiIdx = (kr.planets['ಗುರು']!.longitude / 30).floor() % 12;
        final sunRashiIdx = (kr.planets['ರವಿ']!.longitude / 30).floor() % 12;

        final mResult = evaluateMuhurta(
          event: _event,
          tithiIndex: pan.tithiIndex, tithiName: pan.tithi,
          nakshatraIndex: pan.nakshatraIndex, nakshatraName: pan.nakshatra,
          varaIndex: varaIdx, varaName: pan.vara,
          yogaIndex: (kr.planets['ಚಂದ್ರ'] != null && kr.planets['ರವಿ'] != null)
            ? (((kr.planets['ಚಂದ್ರ']!.longitude + kr.planets['ರವಿ']!.longitude) % 360) / 13.333333).floor() % 27 : 0,
          yogaName: pan.yoga, karanaName: pan.karana,
          moonRashiIndex: moonRashiIdx, jupiterRashiIndex: jupRashiIdx, sunRashiIndex: sunRashiIdx,
          janmaNakIdx1: _nakIdx, janmaRashiIdx1: _rashiIdx,
          abhijitTimeWindow: abhStr,
          overrideRules: MuhurtaEventRules(
            allowedTithis: _userTithis.toList(),
            allowedNakshatras: _userNakshatras.toList(),
            allowedVaras: _userVaras.toList(),
          ),
        );

        final allLagnaWindows = _scanLagnas(srSs[0], srSs[1]);
        final lagnaWindows = allLagnaWindows.where((w) {
          if (_filterLagnaShuddhi && w['lagnaShuddhi'] != true) return false;
          if (_filterSaptamaShuddhi && w['saptamaShuddhi'] != true) return false;
          if (_filterAshtamaShuddhi && w['ashtamaShuddhi'] != true) return false;
          if (_filterGuruAnukoola && w['guruAnukoola'] != true) return false;
          return true;
        }).toList();

        found.add({
          'date': d, 'vara': pan.vara, 'tithi': pan.tithi,
          'nakshatra': pan.nakshatra, 'yoga': pan.yoga, 'karana': pan.karana,
          'checks': mResult.checks, 'doshas': mResult.doshas,
          'doshaBhangas': mResult.doshaBhangas,
          'hasAbhijit': mResult.hasAbhijit, 'abhijitTime': abhStr,
          'sunrise': pan.sunrise, 'sunset': pan.sunset,
          'tara': mResult.personResults.isNotEmpty ? mResult.personResults[0].taraBala : null,
          'lagnaWindows': lagnaWindows,
        });
      } catch (_) {}
    }

    found.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
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
      final houses = Ephemeris.placidusHousesFull(jd, LocationService.lat, LocationService.lon);
      if (houses != null && houses.ascmc.length >= 1) {
        final sidAsc = ((houses.ascmc[0] as double) - ayn) % 360.0;
        final rashiIdx = (sidAsc / 30.0).floor() % 12;
        final localFrac = ((jd + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
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
            'rashi': appRashi[curRashi],
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
              Expanded(child: Text(AppLocale.l('mEditRules'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
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
                      tabs: [
                        Tab(text: AppLocale.l('mTithi')),
                        Tab(text: AppLocale.l('mNakshatra')),
                        Tab(text: AppLocale.l('mVara')),
                        Tab(text: AppLocale.l('mLagna')),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // ── TAB 1: TITHI (Shukla Paksha only) ──
                          ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(children: [
                                  Text('${_userTithis.where((t) => t < 15).length}/15 ${AppLocale.l('mShuklaCount')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kTeal)),
                                  const Spacer(),
                                  TextButton(onPressed: () => setDlgState(() => _userTithis.addAll(List.generate(15, (i) => i))), child: Text(AppLocale.l('mAll'), style: TextStyle(fontSize: 11))),
                                  TextButton(onPressed: () => setDlgState(() => _userTithis.removeWhere((t) => t < 15)), child: Text(AppLocale.l('mNone'), style: TextStyle(fontSize: 11))),
                                ]),
                              ),
                              ...List.generate(15, (i) => CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _userTithis.contains(i),
                                activeColor: kTeal,
                                title: Text(appTithi[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText)),
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
                                  TextButton(onPressed: () => setDlgState(() => _userNakshatras = Set.from(List.generate(27, (i) => i))), child: Text(AppLocale.l('mAll'), style: TextStyle(fontSize: 11))),
                                  TextButton(onPressed: () => setDlgState(() => _userNakshatras.clear()), child: Text(AppLocale.l('mNone'), style: TextStyle(fontSize: 11))),
                                ]),
                              ),
                              ...List.generate(27, (i) => CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _userNakshatras.contains(i),
                                activeColor: kTeal,
                                title: Text('${i + 1}. ${appNak[i]}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText)),
                                onChanged: (v) => setDlgState(() { if (v == true) _userNakshatras.add(i); else _userNakshatras.remove(i); }),
                              )),
                            ],
                          ),

                          // ── TAB 3: VARA ──
                          ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text('${_userVaras.length}/7 ${AppLocale.l('mVaraSelect')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kTeal)),
                              ),
                              ...List.generate(7, (i) => CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _userVaras.contains(i),
                                activeColor: kTeal,
                                title: Text(appVara[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
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
                                  Text('${_allowedLagnas.length}/12 ${AppLocale.l('mLagnaCount')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kTeal)),
                                  const Spacer(),
                                  TextButton(onPressed: () => setDlgState(() => _allowedLagnas.addAll(List.generate(12, (i) => i))), child: Text(AppLocale.l('mAll'), style: TextStyle(fontSize: 11))),
                                  TextButton(onPressed: () => setDlgState(() => _allowedLagnas.clear()), child: Text(AppLocale.l('mNone'), style: TextStyle(fontSize: 11))),
                                ]),
                              ),
                              ...List.generate(12, (i) => CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _allowedLagnas.contains(i),
                                activeColor: kTeal,
                                title: Text(appRashi[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
                                onChanged: (v) => setDlgState(() { if (v == true) _allowedLagnas.add(i); else _allowedLagnas.remove(i); }),
                              )),
                              const Divider(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(AppLocale.l('mLagnaShuddhiRules'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kPurple1)),
                              ),
                              const SizedBox(height: 4),
                              SwitchListTile(
                                dense: true, activeColor: kTeal,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _filterLagnaShuddhi,
                                title: Text(AppLocale.l('mLagnaShuddhiTitle'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
                                subtitle: Text(AppLocale.l('mLagnaShuddhiSub'), style: TextStyle(fontSize: 10, color: kMuted)),
                                onChanged: (v) => setDlgState(() => _filterLagnaShuddhi = v),
                              ),
                              SwitchListTile(
                                dense: true, activeColor: kTeal,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _filterSaptamaShuddhi,
                                title: Text(AppLocale.l('mSaptamaShuddhiTitle'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
                                subtitle: Text(AppLocale.l('mSaptamaShuddhiSub'), style: TextStyle(fontSize: 10, color: kMuted)),
                                onChanged: (v) => setDlgState(() => _filterSaptamaShuddhi = v),
                              ),
                              SwitchListTile(
                                dense: true, activeColor: kTeal,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _filterAshtamaShuddhi,
                                title: Text(AppLocale.l('mAshtamaShuddhiTitle'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
                                subtitle: Text(AppLocale.l('mAshtamaShuddhiSub'), style: TextStyle(fontSize: 10, color: kMuted)),
                                onChanged: (v) => setDlgState(() => _filterAshtamaShuddhi = v),
                              ),
                              SwitchListTile(
                                dense: true, activeColor: kTeal,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                value: _filterGuruAnukoola,
                                title: Text(AppLocale.l('mGuruAnukoolaTitle'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
                                subtitle: Text(AppLocale.l('mGuruAnukoolaSub'), style: TextStyle(fontSize: 10, color: kMuted)),
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
                child: Text(AppLocale.l('mDefault'), style: TextStyle(color: kMuted)),
              ),
              ElevatedButton(
                onPressed: () { Navigator.pop(ctx); setState(() {}); },
                style: ElevatedButton.styleFrom(backgroundColor: kPurple1, foregroundColor: Colors.white),
                child: Text(AppLocale.l('mSave'), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
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
            tooltip: AppLocale.l('mEditRules'),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
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
                Text(AppLocale.l('mBirthNak'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
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

                // ── Panchanga Data Status ──
                Builder(builder: (_) {
                  final cache = PanchangaCache.instance;
                  if (cache.isLoaded) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x104CAF50),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x404CAF50)),
                      ),
                      child: Row(children: [
                        Icon(Icons.check_circle, color: kTeal, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(
                          '⚡ ${cache.statusSummary}',
                          style: TextStyle(fontSize: 11, color: kTeal, fontWeight: FontWeight.w600),
                        )),
                      ]),
                    );
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kOrange.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline, color: kOrange, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(
                        AppLocale.l('mCacheNotLoaded'),
                        style: TextStyle(fontSize: 11, color: kOrange, fontWeight: FontWeight.w600),
                      )),
                    ]),
                  );
                }),

                // ── Download Location Data ──
                OutlinedButton.icon(
                  onPressed: () => _showCityDownloadSheet(),
                  icon: const Icon(Icons.cloud_download_outlined, size: 18),
                  label: Text('⬇️ ಪಂಚಾಂಗ ಡೇಟಾ ಡೌನ್‌ಲೋಡ್ / Download City Data', style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kTeal,
                    side: BorderSide(color: kTeal),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                // Search button
                ElevatedButton.icon(
                  onPressed: _searching ? null : _search,
                  icon: _searching
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search),
                  label: Text(
                    _searching ? '...' : (PanchangaCache.instance.isLoaded ? '⚡ ${AppLocale.l('searchMuhurta')}' : AppLocale.l('searchMuhurta')),
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

            // ── City Coverage Info ──
            _buildCoverageInfoTile(),
            // ── RESULTS ──
            if (_searching)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (!_searching && _results.isNotEmpty) ...[
              Row(children: [
                Text('${_results.length} ${AppLocale.l('mDaysFound')}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTeal)),
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
                child: Center(child: Text(AppLocale.l('mNoMuhurtaMsg'), style: TextStyle(fontSize: 14, color: kMuted))),
              ),
          ],
        )),
      ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> r) {
    final date = r['date'] as DateTime;
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final dateKey = dateStr;
    final isExpanded = _expanded.contains(dateKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kTeal.withOpacity(0.4), width: 1.5),
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
                color: kTeal.withOpacity(0.08),
                borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(11))
                  : BorderRadius.circular(11),
              ),
              child: Row(children: [
                Icon(Icons.event_available, size: 16, color: kTeal),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$dateStr  ${trAll(r['vara'])}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kText)),
                    Text('${trAll(r['tithi'])} • ${trAll(r['nakshatra'])}', style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
                  ],
                )),
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
                  Text('⏰ ${AppLocale.l('abhijitLabel')}: ${r['abhijitTime']}', style: TextStyle(fontSize: 11, color: kTeal, fontWeight: FontWeight.w700)),
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
                  Text('${AppLocale.l('mTaraBala')}: ${(r['tara'] as TaraResult).taraName}',
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
                    Text('⚠ ${AppLocale.l('mDoshasLabel')}:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red)),
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
                      child: Text(AppLocale.l('mLagnaShuddhiHeader'), style: TextStyle(fontWeight: FontWeight.w800, color: kTeal, fontSize: 13)),
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
                              _shuddhiChip(AppLocale.l('mLagna'), lShuddhi, lG),
                              _shuddhiChip(AppLocale.l('mSaptamaShort'), sShuddhi, sG),
                              _shuddhiChip(AppLocale.l('mAshtamaShort'), aShuddhi, aG),
                              if (guruOk) Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.star, size: 12, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(AppLocale.l('mGuruOk'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
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
  // ─────────────────────────────────────────────────────────────────
  // Download Sheet
  // ─────────────────────────────────────────────────────────────────
  Future<void> _showCityDownloadSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MuhurtaCityDownloadSheet(onDone: () {
        if (mounted) setState(() {});
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // City Coverage Data
  // ─────────────────────────────────────────────────────────────────
  static const _cityCoverage = <String, Map<String, String>>{
    'Bengaluru':          {'icon':'🏙️','kn':'ಬೆಂಗಳೂರು','covers':'ಬೆಂಗಳೂರು ನಗರ, ಬೆಂಗಳೂರು ಗ್ರಾಮಾಂತರ, ರಾಮನಗರ, ಚಿಕ್ಕಬಳ್ಳಾಪುರ, ತುಮಕೂರು (ಭಾಗ)'},
    'Mysuru':             {'icon':'🏰','kn':'ಮೈಸೂರು','covers':'ಮೈಸೂರು, ಮಂಡ್ಯ, ಹಾಸನ, ಚಾಮರಾಜನಗರ, ಕೊಡಗು'},
    'Mangaluru':          {'icon':'⛵','kn':'ಮಂಗಳೂರು','covers':'ದಕ್ಷಿಣ ಕನ್ನಡ, ಉಡುಪಿ, ಕಾಸರಗೋಡು (ಭಾಗ)'},
    'Shivamogga':         {'icon':'🌲','kn':'ಶಿವಮೊಗ್ಗ','covers':'ಶಿವಮೊಗ್ಗ, ದಾವಣಗೆರೆ, ಚಿಕ್ಕಮಗಳೂರು, ಉತ್ತರ ಕನ್ನಡ (ಭಾಗ)'},
    'Kalaburagi':         {'icon':'🏜️','kn':'ಕಲಬುರಗಿ','covers':'ಕಲಬುರಗಿ, ಯಾದಗಿರಿ, ವಿಜಯಪುರ, ರಾಯಚೂರು, ಬೀದರ್'},
    'Kochi':              {'icon':'🌊','kn':'ಕೊಚ್ಚಿ','covers':'ಎರ್ನಾಕುಳಂ, ತ್ರಿಶ್ಶೂರ್, ಇಡುಕ್ಕಿ, ಆಲಪ್ಪುಳ (ಭಾಗ)'},
    'Kannur':             {'icon':'🌿','kn':'ಕಣ್ಣೂರು','covers':'ಕಣ್ಣೂರು, ವಯನಾಡ್, ಕೋಝಿಕ್ಕೋಡ್, ಮಲಪ್ಪುರಂ (ಭಾಗ)'},
    'Thiruvananthapuram': {'icon':'🏛️','kn':'ತಿರುವನಂತಪುರಂ','covers':'ತಿರುವನಂತಪುರಂ, ಕೊಲ್ಲಂ, ಪತ್ತನಂತಿಟ್ಟ'},
    'Chennai':            {'icon':'🌆','kn':'ಚೆನ್ನೈ','covers':'ಚೆನ್ನೈ, ತಿರುವಳ್ಳೂರು, ಕಾಂಚೀಪುರಂ, ವೆಲ್ಲೂರು (ಭಾಗ)'},
    'Coimbatore':         {'icon':'⛰️','kn':'ಕೊಯಮತ್ತೂರು','covers':'ಕೊಯಮತ್ತೂರು, ತಿರುಪ್ಪೂರ್, ಈರೋಡ್, ನೀಲಗಿರಿ'},
    'Madurai':            {'icon':'🏯','kn':'ಮಧುರೈ','covers':'ಮಧುರೈ, ಡಿಂಡಿಗಲ್, ವಿರುಧುನಗರ, ಸಿವಗಂಗೈ'},
    'Hyderabad':          {'icon':'🕌','kn':'ಹೈದರಾಬಾದ್','covers':'ಹೈದರಾಬಾದ್, ರಂಗಾರೆಡ್ಡಿ, ಮೆಡಕ್, ನಲ್ಗೊಂಡ (ಭಾಗ)'},
    'Khammam':            {'icon':'🌾','kn':'ಖಮ್ಮಂ','covers':'ಖಮ್ಮಂ, ಭದ್ರಾದ್ರಿ ಕೊತ್ತಗೂಡೆಂ, ಸೂರ್ಯಾಪೇಟ'},
    'Vijayawada':         {'icon':'🌉','kn':'ವಿಜಯವಾಡ','covers':'ಕೃಷ್ಣ, ಎನ್‌ಟಿಆರ್ ಜಿಲ್ಲೆ, ಗುಂಟೂರು, ಪಲ್ನಾಡು'},
    'Visakhapatnam':      {'icon':'⚓','kn':'ವಿಶಾಖಪಟ್ಟಣಂ','covers':'ವಿಶಾಖಪಟ್ಟಣಂ, ಅನಕಾಪಲ್ಲಿ, ಶ್ರೀಕಾಕುಳಂ, ಅಲ್ಲೂರಿ (ಭಾಗ)'},
    'Anantapur':          {'icon':'🌞','kn':'ಅನಂತಪುರ','covers':'ಅನಂತಪುರ, ಕರ್ನೂಲು, ನಂದ್ಯಾಲ, ಶ್ರೀ ಸತ್ಯಸಾಯಿ'},
    'Panaji':             {'icon':'🏖️','kn':'ಪಣಜಿ','covers':'ಉತ್ತರ ಗೋವಾ, ದಕ್ಷಿಣ ಗೋವಾ (ಸಂಪೂರ್ಣ ಗೋವಾ)'},
  };

  Widget _buildCoverageInfoTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder.withOpacity(0.4)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Icon(Icons.map_outlined, color: kTeal, size: 22),
          title: Text(
            '📍 ಲಭ್ಯ ನಗರಗಳು ಮತ್ತು ಪ್ರದೇಶ ವ್ಯಾಪ್ತಿ',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText),
          ),
          subtitle: Text(
            '17 cities • tap to view coverage',
            style: TextStyle(fontSize: 11, color: kMuted),
          ),
          children: _cityCoverage.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.value['icon']!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '${e.value['kn']} (${e.key})',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kText),
                ),
                Text(
                  e.value['covers']!,
                  style: TextStyle(fontSize: 11, color: kMuted, height: 1.4),
                ),
              ])),
            ]),
          )).toList(),
        ),
      ),
    );
  }

}


class _MuhurtaCityDownloadSheet extends StatefulWidget {
  final VoidCallback onDone;
  const _MuhurtaCityDownloadSheet({required this.onDone});
  @override
  State<_MuhurtaCityDownloadSheet> createState() => _MuhurtaCityDownloadSheetState();
}

class _MuhurtaCityDownloadSheetState extends State<_MuhurtaCityDownloadSheet> {
  List<PanchangaCityInfo>? _cities;
  bool _loading = true;
  String? _error;
  String? _downloadingCity;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await PanchangaDownloadService.fetchAvailableCities();
      if (mounted) setState(() { _cities = cities; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _download(PanchangaCityInfo city) async {
    setState(() { _downloadingCity = city.nameKn; _progress = 0; });
    final err = await PanchangaDownloadService.downloadAndImport(
      city,
      onProgress: (p) { if (mounted) setState(() => _progress = p); },
    );
    if (mounted) {
      setState(() { _downloadingCity = null; });
      if (err == null) {
        widget.onDone();
        if (mounted) Navigator.pop(context);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ${city.nameKn} ಡೇಟಾ ಡೌನ್‌ಲೋಡ್ ಆಯಿತು'),
          backgroundColor: Colors.green,
        ));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ $err'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      expand: false,
      builder: (ctx, scrollController) => Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Icon(Icons.cloud_download_outlined, color: kTeal, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ಪಂಚಾಂಗ ಡೇಟಾ ಡೌನ್‌ಲೋಡ್', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
              Text('ನಿಮ್ಮ ನಗರ ಆಯ್ಕೆ ಮಾಡಿ • Select your city', style: TextStyle(fontSize: 12, color: kMuted)),
            ])),
          ]),
        ),
        const Divider(),
        if (_downloadingCity != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(children: [
              Text('⬇️ $_downloadingCity ಡೌನ್‌ಲೋಡ್ ಆಗುತ್ತಿದೆ...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress, minHeight: 8,
                  backgroundColor: kBorder.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation(kTeal),
                ),
              ),
              const SizedBox(height: 4),
              Text('${(_progress * 100).toInt()}%', style: TextStyle(fontSize: 12, color: kMuted)),
            ]),
          ),
        ] else if (_loading) ...[
          const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
        ] else if (_error != null) ...[
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () { setState(() { _loading = true; _error = null; }); _loadCities(); },
                child: const Text('ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ'),
              ),
            ]),
          ),
        ] else if (_cities == null || _cities!.isEmpty) ...[
          Padding(padding: const EdgeInsets.all(40), child: Text('ನಗರಗಳು ಲಭ್ಯವಿಲ್ಲ', style: TextStyle(color: kMuted, fontSize: 16))),
        ] else ...[
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _cities!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final city = _cities![i];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _downloadingCity != null ? null : () => _download(city),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: kBorder.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        Icon(Icons.location_city, color: kTeal, size: 28),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(city.nameKn, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
                          Text('${city.name} • ${city.fromYear}–${city.toYear} • ~${city.sizeKB} KB',
                            style: TextStyle(fontSize: 11, color: kMuted)),
                        ])),
                        Icon(Icons.download_rounded, color: kTeal, size: 24),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ]),
    );
  }
}

class _AscSample {
  final double jd;
  final int rashiIdx;
  final double localMins;
  const _AscSample({required this.jd, required this.rashiIdx, required this.localMins});
}
