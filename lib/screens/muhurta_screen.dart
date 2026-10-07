import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';
import '../constants/places.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import '../core/muhurta_rules.dart';
import '../services/location_service.dart';

/// ──────────────────────────────────────────────────────────────
/// Simplified Muhoorta Screen
/// Filters: Tithi, Nakshatra, Tara Anukoola, Vara, Shuddhi, Abhijit
/// ──────────────────────────────────────────────────────────────
class MuhurtaScreen extends StatefulWidget {
  const MuhurtaScreen({super.key});
  @override
  State<MuhurtaScreen> createState() => _MuhurtaScreenState();
}

class _MuhurtaScreenState extends State<MuhurtaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Birth nakshatra for Tara Anukoola
  int _janmaNakIdx = -1; // -1 = not set

  // Location
  double _lat = LocationService.lat;
  double _lon = LocationService.lon;
  double _tz = LocationService.tzOffset;
  String _placeName = LocationService.placeName;

  // Cached day results for the displayed month
  final Map<DateTime, _SimpleMuhurtaDay> _cache = {};
  bool _isLoading = false;

  // Selected day detail
  _SimpleMuhurtaDay? _selectedDayDetail;

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedDay);
  }

  // ── Location picker ──
  Future<void> _pickLocation() async {
    String query = '';
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
                      query = v;
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
                          subtitle: Text('${(r['la'] as double).toStringAsFixed(2)}°N, ${(r['lo'] as double).toStringAsFixed(2)}°E', style: const TextStyle(fontSize: 11)),
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
        _placeName = '${result['n']}, ${result['c']}';
        _cache.clear();
      });
      _loadMonth(_focusedDay);
    }
  }

  // ── Birth nakshatra picker ──
  void _pickJanmaNakshatra() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ಜನ್ಮ ನಕ್ಷತ್ರ ಆಯ್ಕೆ'),
        content: SizedBox(
          width: 280, height: 400,
          child: ListView.builder(
            itemCount: 27,
            itemBuilder: (_, i) {
              final name = knNak[i];
              final isSelected = i == _janmaNakIdx;
              return ListTile(
                title: Text('${i + 1}. $name', style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                  color: isSelected ? kTeal : kText,
                )),
                trailing: isSelected ? Icon(Icons.check_circle, color: kTeal) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _janmaNakIdx = i;
                    _cache.clear();
                  });
                  _loadMonth(_focusedDay);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Compute month ──
  Future<void> _loadMonth(DateTime month) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final first = DateTime.utc(month.year, month.month, 1);
    final last = DateTime.utc(month.year, month.month + 1, 0);

    try {
      await Ephemeris.initSweph();
    } catch (_) {}

    for (var d = first; !d.isAfter(last); d = d.add(const Duration(days: 1))) {
      if (_cache.containsKey(d)) continue;
      try {
        // Compute sunrise first to determine correct vara
        final srSs = Ephemeris.findSunriseSetForDate(
          d.year, d.month, d.day, _lat, _lon, tzOffset: _tz);
        final srFrac = ((srSs[0] + 0.5 + (_tz / 24.0)) % 1.0 + 1.0) % 1.0;
        final srHour = srFrac * 24.0 + (1.0 / 60.0); // just after sunrise
        final ssFrac = ((srSs[1] + 0.5 + (_tz / 24.0)) % 1.0 + 1.0) % 1.0;

        final kr = await AstroCalculator.calculate(
          year: d.year, month: d.month, day: d.day,
          hourUtcOffset: _tz, hour24: srHour,
          lat: _lat, lon: _lon,
          ayanamsaMode: 'lahiri', trueNode: true,
        );
        if (kr != null) {
          final pan = kr.panchang;
          final tIdx = pan.tithiIndex;
          final nIdx = pan.nakshatraIndex;
          final varaIdx = knVara.indexOf(pan.vara).clamp(0, 6);

          // ── Evaluate simplified muhoorta ──
          _cache[d] = _evaluateDay(
            date: d,
            tithiIndex: tIdx,
            tithiName: pan.tithi,
            nakshatraIndex: nIdx,
            nakshatraName: pan.nakshatra,
            varaIndex: varaIdx,
            varaName: pan.vara,
            yogaIndex: (kr.planets['ಚಂದ್ರ'] != null && kr.planets['ರವಿ'] != null)
              ? (((kr.planets['ಚಂದ್ರ']!.longitude + kr.planets['ರವಿ']!.longitude) % 360) / 13.333333).floor() % 27
              : 0,
            yogaName: pan.yoga,
            karanaName: pan.karana,
            sunrise: pan.sunrise,
            sunset: pan.sunset,
            srFrac: srFrac,
            ssFrac: ssFrac,
          );
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Simplified day evaluation ──
  _SimpleMuhurtaDay _evaluateDay({
    required DateTime date,
    required int tithiIndex,
    required String tithiName,
    required int nakshatraIndex,
    required String nakshatraName,
    required int varaIndex,
    required String varaName,
    required int yogaIndex,
    required String yogaName,
    required String karanaName,
    required String sunrise,
    required String sunset,
    required double srFrac,
    required double ssFrac,
  }) {
    int score = 0;
    int maxScore = 0;
    final checks = <_CheckItem>[];

    // ── 1. TITHI (20 pts) ──
    maxScore += 20;
    final pakshaRel = tithiIndex % 15;
    // Rikta tithis: 4, 9, 14 (Chaturthi, Navami, Chaturdashi)
    final rikta = (pakshaRel == 3 || pakshaRel == 8 || pakshaRel == 13);
    final amavasya = tithiIndex == 29;
    final tithiGood = !rikta && !amavasya;
    if (tithiGood) score += 20;
    checks.add(_CheckItem(
      label: 'ತಿಥಿ',
      value: tithiName,
      passed: tithiGood,
      note: rikta ? 'ರಿಕ್ತ ತಿಥಿ — ಅಶುಭ' : (amavasya ? 'ಅಮಾವಾಸ್ಯೆ — ಅಶುಭ' : null),
    ));

    // ── 2. NAKSHATRA (20 pts) ──
    maxScore += 20;
    // Generally auspicious nakshatras (Dhruva/Sthira, Mridu, Kshipra/Laghu, Chara)
    const goodNak = {0,2,3,5,6,7,10,12,13,14,16,19,20,21,24,25,26}; // Ashwini,Krittika,Rohini,Mrigashira,Punarvasu,Pushya,Magha,UPhalguni,Hasta,Chitra,Anuradha,PAshadha,UAshadha,Shravana,PBhadra,UBhadra,Revati
    final nakGood = goodNak.contains(nakshatraIndex);
    if (nakGood) score += 20;
    checks.add(_CheckItem(
      label: 'ನಕ್ಷತ್ರ',
      value: nakshatraName,
      passed: nakGood,
      note: nakGood ? null : 'ಈ ನಕ್ಷತ್ರ ಸಾಮಾನ್ಯವಾಗಿ ಅಶುಭ',
    ));

    // ── 3. TARA ANUKOOLA (20 pts) ──
    maxScore += 20;
    bool taraGood = true;
    String? taraNote;
    if (_janmaNakIdx >= 0) {
      final tara = calculateTaraBala(_janmaNakIdx, nakshatraIndex);
      taraGood = tara.isGood;
      if (taraGood) score += 20;
      taraNote = tara.taraName;
      checks.add(_CheckItem(
        label: 'ತಾರಾ ಅನುಕೂಲ',
        value: tara.taraName,
        passed: taraGood,
        note: taraGood ? 'ಅನುಕೂಲ' : 'ಪ್ರತಿಕೂಲ',
      ));
    } else {
      score += 20; // No birth nakshatra set, skip this check
    }

    // ── 4. VARA (15 pts) ──
    maxScore += 15;
    // Mon(1)=good, Wed(3)=good, Thu(4)=best, Fri(5)=good, Sun(0)=neutral, Tue(2)=caution, Sat(6)=caution
    final varaGood = (varaIndex == 1 || varaIndex == 3 || varaIndex == 4 || varaIndex == 5);
    final varaNeutral = (varaIndex == 0);
    if (varaGood) {
      score += 15;
    } else if (varaNeutral) {
      score += 10;
    }
    checks.add(_CheckItem(
      label: 'ವಾರ',
      value: varaName,
      passed: varaGood || varaNeutral,
      note: varaGood ? 'ಶುಭ ವಾರ' : (varaNeutral ? 'ಸಾಮಾನ್ಯ' : 'ಮಂಗಳ/ಶನಿ — ಎಚ್ಚರಿಕೆ'),
    ));

    // ── 5. SHUDDHI: Dagdha Yoga check (15 pts) ──
    maxScore += 15;
    final dagdhaList = dagdhaYogaTable[varaIndex];
    final hasDagdha = dagdhaList != null && dagdhaList.contains(nakshatraIndex);
    if (!hasDagdha) score += 15;
    checks.add(_CheckItem(
      label: 'ದಗ್ಧ ಯೋಗ',
      value: hasDagdha ? 'ಇದೆ — ಅಶುಭ' : 'ಇಲ್ಲ — ಶುಭ',
      passed: !hasDagdha,
      note: hasDagdha ? 'ವಾರ-ನಕ್ಷತ್ರ ದಗ್ಧ ಸಂಯೋಗ' : null,
    ));

    // ── 6. SHUDDHI: Siddha Yoga bonus (10 pts) ──
    maxScore += 10;
    final siddhaList = siddhaYogaTable[varaIndex];
    final hasSiddha = siddhaList != null && siddhaList.contains(pakshaRel);
    if (hasSiddha) score += 10;
    checks.add(_CheckItem(
      label: 'ಸಿದ್ಧ ಯೋಗ',
      value: hasSiddha ? 'ಇದೆ — ಶುಭ' : 'ಇಲ್ಲ',
      passed: hasSiddha,
      note: hasSiddha ? 'ವಾರ-ತಿಥಿ ಸಿದ್ಧ ಯೋಗ — ದೋಷ ಭಂಗ' : null,
    ));

    // ── 7. ABHIJIT MUHURTA ──
    // 8th of 15 daytime muhurtas (midday)
    final srMins = srFrac * 24.0 * 60.0;
    final ssMins = ssFrac * 24.0 * 60.0;
    final dayDur = ((ssMins - srMins) + 1440) % 1440;
    final muhDur = dayDur / 15.0;
    final abhijitStart = srMins + 7 * muhDur;
    final abhijitEnd = abhijitStart + muhDur;
    final abhijitStr = '${_formatMins(abhijitStart)} - ${_formatMins(abhijitEnd)}';
    checks.add(_CheckItem(
      label: 'ಅಭಿಜಿತ್ ಮುಹೂರ್ತ',
      value: abhijitStr,
      passed: true,
      note: 'ಮಧ್ಯಾಹ್ನದ ಶ್ರೇಷ್ಠ ಮುಹೂರ್ತ',
    ));

    // ── Amrita Siddhi Yoga bonus ──
    final amritaList = amritaSiddhiTable[varaIndex];
    final hasAmrita = amritaList != null && amritaList.contains(nakshatraIndex);
    if (hasAmrita) {
      score += 5; // bonus
      checks.add(_CheckItem(
        label: 'ಅಮೃತ ಸಿದ್ಧಿ ಯೋಗ',
        value: 'ಇದೆ — ಅತಿಶ್ರೇಷ್ಠ',
        passed: true,
        note: 'ವಾರ-ನಕ್ಷತ್ರ ಅಮೃತ ಸಿದ್ಧಿ ಸಂಯೋಗ',
      ));
    }

    // ── Compute verdict ──
    final pct = maxScore > 0 ? (score * 100 / maxScore).round() : 0;
    String verdict;
    int quality; // 2=shubha, 1=madhyama, 0=ashubha
    if (hasDagdha) {
      verdict = 'ಅಶುಭ';
      quality = 0;
    } else if (pct >= 75) {
      verdict = 'ಶುಭ';
      quality = 2;
    } else if (pct >= 45) {
      verdict = 'ಮಧ್ಯಮ';
      quality = 1;
    } else {
      verdict = 'ಅಶುಭ';
      quality = 0;
    }

    return _SimpleMuhurtaDay(
      date: date,
      tithiName: tithiName,
      nakshatraName: nakshatraName,
      varaName: varaName,
      score: pct,
      quality: quality,
      verdict: verdict,
      checks: checks,
      abhijitTime: abhijitStr,
      sunrise: sunrise,
      sunset: sunset,
    );
  }

  String _formatMins(double mins) {
    final totalMins = mins.round() % 1440;
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    final amPm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $amPm';
  }

  void _showDayDetail(_SimpleMuhurtaDay day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            // Handle bar
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kMuted.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            // Date header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _qualityColor(day.quality).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    day.quality == 2 ? Icons.check_circle : (day.quality == 1 ? Icons.info : Icons.cancel),
                    color: _qualityColor(day.quality), size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${day.date.day}/${day.date.month}/${day.date.year}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText)),
                      Text('${day.varaName} • ${day.verdict} (${day.score}%)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _qualityColor(day.quality))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Sunrise/Sunset row
            Row(
              children: [
                Icon(Icons.wb_sunny, size: 16, color: kOrange),
                const SizedBox(width: 4),
                Text('☀ ${day.sunrise}', style: TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(width: 16),
                Icon(Icons.nightlight_round, size: 16, color: kPurple2),
                const SizedBox(width: 4),
                Text('🌙 ${day.sunset}', style: TextStyle(fontSize: 12, color: kMuted)),
              ],
            ),
            const SizedBox(height: 16),
            // Checks
            ...day.checks.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.passed ? kGreen.withOpacity(0.06) : Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.passed ? kGreen.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(c.passed ? Icons.check_circle : Icons.cancel, color: c.passed ? kGreen : Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kText)),
                        Text(c.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText.withOpacity(0.8))),
                        if (c.note != null) Text(c.note!, style: TextStyle(fontSize: 11, color: kMuted, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _qualityColor(int q) => q == 2 ? kGreen : (q == 1 ? kOrange : Colors.red);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text('ಮುಹೂರ್ತ', style: TextStyle(fontWeight: FontWeight.w900, color: kText)),
        backgroundColor: kCard,
        elevation: 0,
        iconTheme: IconThemeData(color: kText),
        actions: [
          if (_isLoading) Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kTeal)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Location & Birth Nakshatra bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: kCard,
            child: Row(
              children: [
                // Location chip
                Expanded(
                  child: InkWell(
                    onTap: _pickLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: kPurple2.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: kPurple2),
                          const SizedBox(width: 4),
                          Expanded(child: Text(_placeName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPurple2), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Birth nakshatra chip
                InkWell(
                  onTap: _pickJanmaNakshatra,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: kTeal.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 16, color: kTeal),
                        const SizedBox(width: 4),
                        Text(
                          _janmaNakIdx >= 0 ? knNak[_janmaNakIdx] : 'ಜನ್ಮ ನಕ್ಷತ್ರ',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTeal),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Calendar ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2040, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) => _selectedDay != null && isSameDay(d, _selectedDay),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                      final key = DateTime.utc(selected.year, selected.month, selected.day);
                      final day = _cache[key];
                      if (day != null) _showDayDetail(day);
                    },
                    onPageChanged: (focused) {
                      _focusedDay = focused;
                      _loadMonth(focused);
                    },
                    calendarFormat: CalendarFormat.month,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kText),
                      leftChevronIcon: Icon(Icons.chevron_left, color: kPurple2),
                      rightChevronIcon: Icon(Icons.chevron_right, color: kPurple2),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kMuted),
                      weekendStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.red.withOpacity(0.6)),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (ctx, day, focused) => _buildDayCell(day, false),
                      todayBuilder: (ctx, day, focused) => _buildDayCell(day, true),
                      selectedBuilder: (ctx, day, focused) => _buildDayCell(day, false, selected: true),
                    ),
                  ),

                  // ── Legend ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legendDot(kGreen, 'ಶುಭ'),
                        const SizedBox(width: 16),
                        _legendDot(kOrange, 'ಮಧ್ಯಮ'),
                        const SizedBox(width: 16),
                        _legendDot(Colors.red, 'ಅಶುಭ'),
                      ],
                    ),
                  ),

                  // ── Good days summary for the month ──
                  _buildMonthSummary(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label) => Row(
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted)),
    ],
  );

  Widget _buildDayCell(DateTime day, bool isToday, {bool selected = false}) {
    final key = DateTime.utc(day.year, day.month, day.day);
    final data = _cache[key];

    Color bgColor = Colors.transparent;
    Color textColor = kText;
    Color? dotColor;

    if (data != null) {
      dotColor = _qualityColor(data.quality);
      if (selected) {
        bgColor = kPurple2.withOpacity(0.15);
      }
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: kPurple2, width: 2) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${day.day}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
          if (data != null) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              ],
            ),
            Text(
              data.nakshatraName.length > 4 ? data.nakshatraName.substring(0, 4) : data.nakshatraName,
              style: TextStyle(fontSize: 7, color: kMuted, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthSummary() {
    final monthDays = _cache.entries
      .where((e) => e.key.month == _focusedDay.month && e.key.year == _focusedDay.year)
      .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final shubhaDays = monthDays.where((e) => e.value.quality == 2).toList();

    if (shubhaDays.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('ಶುಭ ದಿನಗಳು — Good Days', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kGreen)),
          const SizedBox(height: 8),
          ...shubhaDays.map((e) {
            final d = e.value;
            return InkWell(
              onTap: () => _showDayDetail(d),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kGreen.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: kGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text('${d.date.day}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kGreen))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${d.varaName} • ${d.tithiName}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
                          Text('${d.nakshatraName} • ಅಭಿಜಿತ್: ${d.abhijitTime}', style: TextStyle(fontSize: 11, color: kMuted)),
                        ],
                      ),
                    ),
                    Text('${d.score}%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kGreen)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Data Models ──

class _SimpleMuhurtaDay {
  final DateTime date;
  final String tithiName;
  final String nakshatraName;
  final String varaName;
  final int score;       // 0-100
  final int quality;     // 0=ashubha, 1=madhyama, 2=shubha
  final String verdict;
  final List<_CheckItem> checks;
  final String abhijitTime;
  final String sunrise;
  final String sunset;

  _SimpleMuhurtaDay({
    required this.date,
    required this.tithiName,
    required this.nakshatraName,
    required this.varaName,
    required this.score,
    required this.quality,
    required this.verdict,
    required this.checks,
    required this.abhijitTime,
    required this.sunrise,
    required this.sunset,
  });
}

class _CheckItem {
  final String label;
  final String value;
  final bool passed;
  final String? note;

  _CheckItem({required this.label, required this.value, required this.passed, this.note});
}
