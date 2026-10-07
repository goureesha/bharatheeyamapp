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
/// Simplified Muhoorta Screen — Easy to use
/// Just pick birth nakshatra + location → see good days
/// Filters: Tithi, Nakshatra, Tara, Vara, Shuddhi, Abhijit
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
  String _placeName = LocationService.place;

  // Cached day results for the displayed month
  final Map<DateTime, _SimpleMuhurtaDay> _cache = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedDay);
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
        title: const Text('ಜನ್ಮ ನಕ್ಷತ್ರ ಆಯ್ಕೆ'),
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
        if (kr != null) {
          final pan = kr.panchang;
          final tIdx = pan.tithiIndex;
          final nIdx = pan.nakshatraIndex;
          final varaIdx = knVara.indexOf(pan.vara).clamp(0, 6);

          _cache[d] = _evaluateDay(
            date: d,
            tithiIndex: tIdx,
            tithiName: pan.tithi,
            nakshatraIndex: nIdx,
            nakshatraName: pan.nakshatra,
            varaIndex: varaIdx,
            varaName: pan.vara,
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
    required String karanaName,
    required String sunrise,
    required String sunset,
    required double srFrac,
    required double ssFrac,
  }) {
    int score = 0;
    int maxScore = 0;
    final checks = <MuhurtaCheckItem>[];

    // ── 1. TITHI (15 pts) ──
    maxScore += 15;
    final pakshaRel = tithiIndex % 15;
    final rikta = (pakshaRel == 3 || pakshaRel == 8 || pakshaRel == 13);
    final amavasya = tithiIndex == 29;
    final tithiGood = !rikta && !amavasya;
    if (tithiGood) score += 15;
    checks.add(MuhurtaCheckItem(
      label: 'ತಿಥಿ',
      value: tithiName,
      passed: tithiGood,
      note: rikta ? 'ರಿಕ್ತ ತಿಥಿ — ಅಶುಭ' : (amavasya ? 'ಅಮಾವಾಸ್ಯೆ — ಅಶುಭ' : null),
    ));

    // ── 2. NAKSHATRA (15 pts) ──
    maxScore += 15;
    const goodNak = {0,2,3,5,6,7,10,12,13,14,16,19,20,21,24,25,26};
    final nakGood = goodNak.contains(nakshatraIndex);
    if (nakGood) score += 15;
    checks.add(MuhurtaCheckItem(
      label: 'ನಕ್ಷತ್ರ',
      value: nakshatraName,
      passed: nakGood,
      note: nakGood ? null : 'ಈ ನಕ್ಷತ್ರ ಸಾಮಾನ್ಯವಾಗಿ ಅಶುಭ',
    ));

    // ── 3. TARA ANUKOOLA (20 pts) ──
    maxScore += 20;
    bool taraGood = true;
    if (_janmaNakIdx >= 0) {
      final tara = calculateTaraBala(_janmaNakIdx, nakshatraIndex);
      taraGood = tara.isGood;
      if (taraGood) score += 20;
      checks.add(MuhurtaCheckItem(
        label: 'ತಾರಾ ಬಲ',
        value: tara.taraName,
        passed: taraGood,
        note: taraGood ? 'ಅನುಕೂಲ' : 'ಪ್ರತಿಕೂಲ',
      ));
    } else {
      score += 20;
    }

    // ── 4. VARA (15 pts) ──
    maxScore += 15;
    final varaGood = (varaIndex == 1 || varaIndex == 3 || varaIndex == 4 || varaIndex == 5);
    final varaNeutral = (varaIndex == 0);
    if (varaGood) { score += 15; }
    else if (varaNeutral) { score += 10; }
    checks.add(MuhurtaCheckItem(
      label: 'ವಾರ',
      value: varaName,
      passed: varaGood || varaNeutral,
      note: varaGood ? 'ಶುಭ ವಾರ' : (varaNeutral ? 'ಸಾಮಾನ್ಯ' : 'ಮಂಗಳ/ಶನಿ — ಎಚ್ಚರಿಕೆ'),
    ));

    // ── 5. DAGDHA YOGA (15 pts) ──
    maxScore += 15;
    final dagdhaList = dagdhaYogaTable[varaIndex];
    final hasDagdha = dagdhaList != null && dagdhaList.contains(nakshatraIndex);
    if (!hasDagdha) score += 15;
    checks.add(MuhurtaCheckItem(
      label: 'ದಗ್ಧ ಯೋಗ',
      value: hasDagdha ? 'ಇದೆ — ಅಶುಭ' : 'ಇಲ್ಲ — ಶುಭ',
      passed: !hasDagdha,
      note: hasDagdha ? 'ವಾರ-ನಕ್ಷತ್ರ ದಗ್ಧ ಸಂಯೋಗ' : null,
    ));

    // ── 6. SIDDHA YOGA bonus (10 pts) ──
    maxScore += 10;
    final siddhaList = siddhaYogaTable[varaIndex];
    final hasSiddha = siddhaList != null && siddhaList.contains(pakshaRel);
    if (hasSiddha) score += 10;
    checks.add(MuhurtaCheckItem(
      label: 'ಸಿದ್ಧ ಯೋಗ',
      value: hasSiddha ? 'ಇದೆ — ಶುಭ' : 'ಇಲ್ಲ',
      passed: hasSiddha,
      note: hasSiddha ? 'ವಾರ-ತಿಥಿ ಸಿದ್ಧ ಯೋಗ — ದೋಷ ಭಂಗ' : null,
    ));

    // ── 7. VISHTI KARANA (10 pts) ──
    maxScore += 10;
    final hasVishti = karanaName.contains('ಭದ್ರಾ') || karanaName.contains('ವಿಷ್ಟಿ');
    if (!hasVishti) score += 10;
    checks.add(MuhurtaCheckItem(
      label: 'ವಿಷ್ಟಿ ಕರಣ',
      value: hasVishti ? 'ಭದ್ರಾ — ಅಶುಭ' : '$karanaName — ಶುಭ',
      passed: !hasVishti,
      note: hasVishti ? 'ವಿಷ್ಟಿ (ಭದ್ರಾ) ಕರಣ ಟ್ಯಾಜ್ಯ' : null,
    ));

    // ── ABHIJIT MUHURTA time ──
    final srMins = srFrac * 24.0 * 60.0;
    final ssMins = ssFrac * 24.0 * 60.0;
    final dayDur = ((ssMins - srMins) + 1440) % 1440;
    final muhDur = dayDur / 15.0;
    final abhijitStart = srMins + 7 * muhDur;
    final abhijitEnd = abhijitStart + muhDur;
    final abhijitStr = '${_fmtMins(abhijitStart)} - ${_fmtMins(abhijitEnd)}';

    // ── AMRITA SIDDHI YOGA bonus ──
    final amritaList = amritaSiddhiTable[varaIndex];
    final hasAmrita = amritaList != null && amritaList.contains(nakshatraIndex);
    if (hasAmrita) score += 5;

    // ── Compute verdict ──
    final pct = maxScore > 0 ? (score * 100 / maxScore).round() : 0;
    int quality;
    if (hasDagdha) {
      quality = 0;
    } else if (pct >= 75) {
      quality = 2;
    } else if (pct >= 45) {
      quality = 1;
    } else {
      quality = 0;
    }

    return _SimpleMuhurtaDay(
      date: date,
      tithiName: tithiName,
      nakshatraName: nakshatraName,
      varaName: varaName,
      score: pct,
      quality: quality,
      checks: checks,
      abhijitTime: abhijitStr,
      hasAmrita: hasAmrita,
      sunrise: sunrise,
      sunset: sunset,
    );
  }

  String _fmtMins(double mins) {
    final t = mins.round() % 1440;
    final h = t ~/ 60;
    final m = t % 60;
    final ap = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ap';
  }

  Color _qColor(int q) => q == 2 ? kGreen : (q == 1 ? kOrange : Colors.red);
  String _qLabel(int q) => q == 2 ? 'ಶುಭ' : (q == 1 ? 'ಮಧ್ಯಮ' : 'ಅಶುಭ');
  IconData _qIcon(int q) => q == 2 ? Icons.check_circle : (q == 1 ? Icons.warning_amber_rounded : Icons.cancel);

  // ── Build result card (like Taranukoola style) ──
  final Set<String> _expandedCards = {};

  Widget _buildResultCard(_SimpleMuhurtaDay d) {
    final dateStr = '${d.date.day.toString().padLeft(2, '0')}/${d.date.month.toString().padLeft(2, '0')}/${d.date.year}';
    final key = dateStr;
    final isExpanded = _expandedCards.contains(key);
    final scoreColor = _qColor(d.quality);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Tappable header ──
          GestureDetector(
            onTap: () => setState(() {
              if (isExpanded) _expandedCards.remove(key);
              else _expandedCards.add(key);
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
                Icon(_qIcon(d.quality), size: 16, color: scoreColor),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$dateStr  ${d.varaName}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kText)),
                    Text('${d.tithiName} • ${d.nakshatraName}', style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: scoreColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text('${d.score}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: scoreColor)),
                ),
                const SizedBox(width: 6),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: kMuted),
              ]),
            ),
          ),

          // ── Expandable details ──
          if (isExpanded) ...[
            // Sunrise/Sunset & Abhijit
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: kBg.withOpacity(0.5),
              child: Row(children: [
                Text('☀ ${d.sunrise}', style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Text('🌙 ${d.sunset}', style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('⏰ ಅಭಿಜಿತ್: ${d.abhijitTime}', style: TextStyle(fontSize: 11, color: kTeal, fontWeight: FontWeight.w700)),
              ]),
            ),
            if (d.hasAmrita)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: kGreen.withOpacity(0.08),
                child: Row(children: [
                  Icon(Icons.stars, size: 14, color: kGreen),
                  const SizedBox(width: 6),
                  Text('ಅಮೃತ ಸಿದ್ಧಿ ಯೋಗ — ಅತಿಶ್ರೇಷ್ಠ', style: TextStyle(fontSize: 11, color: kGreen, fontWeight: FontWeight.w800)),
                ]),
              ),
            // Panchanga Shuddhi table
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
                    child: Text('ಪಂಚಾಂಗ ಶುದ್ಧಿ', style: TextStyle(fontWeight: FontWeight.w800, color: kPurple1, fontSize: 13)),
                  ),
                  ...d.checks.map((c) => Container(
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
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Settings bar ──
            AppCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Location
                InkWell(
                  onTap: _pickLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: kPurple2.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 18, color: kPurple2),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_placeName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPurple2), overflow: TextOverflow.ellipsis)),
                        Icon(Icons.edit, size: 14, color: kMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Birth Nakshatra
                InkWell(
                  onTap: _pickJanmaNakshatra,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: kTeal.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 18, color: kTeal),
                        const SizedBox(width: 8),
                        Text(
                          _janmaNakIdx >= 0 ? 'ಜನ್ಮ ನಕ್ಷತ್ರ: ${knNak[_janmaNakIdx]}' : 'ಜನ್ಮ ನಕ್ಷತ್ರ ಆಯ್ಕೆ ಮಾಡಿ (ತಾರಾ ಬಲಕ್ಕೆ)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTeal),
                        ),
                        const Spacer(),
                        Icon(Icons.edit, size: 14, color: kMuted),
                      ],
                    ),
                  ),
                ),
              ],
            )),

            // ── Calendar ──
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

            // ── Results list (Taranukoola-style expandable cards) ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._buildResultsList(),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResultsList() {
    final monthDays = _cache.entries
      .where((e) => e.key.month == _focusedDay.month && e.key.year == _focusedDay.year)
      .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (monthDays.isEmpty) return [];

    final shubhaDays = monthDays.where((e) => e.value.quality == 2).toList();
    final madhyamaDays = monthDays.where((e) => e.value.quality == 1).toList();
    final ashubhaDays = monthDays.where((e) => e.value.quality == 0).toList();

    return [
      // Summary
      Row(
        children: [
          _countBadge(shubhaDays.length, 'ಶುಭ', kGreen),
          const SizedBox(width: 8),
          _countBadge(madhyamaDays.length, 'ಮಧ್ಯಮ', kOrange),
          const SizedBox(width: 8),
          _countBadge(ashubhaDays.length, 'ಅಶುಭ', Colors.red),
        ],
      ),
      const SizedBox(height: 12),

      // Shubha days
      if (shubhaDays.isNotEmpty) ...[
        Text('🟢 ಶುಭ ದಿನಗಳು (${shubhaDays.length})', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kGreen)),
        const SizedBox(height: 8),
        ...shubhaDays.map((e) => _buildResultCard(e.value)),
      ],

      // Madhyama days
      if (madhyamaDays.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('🟡 ಮಧ್ಯಮ ದಿನಗಳು (${madhyamaDays.length})', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kOrange)),
        const SizedBox(height: 8),
        ...madhyamaDays.map((e) => _buildResultCard(e.value)),
      ],

      // Ashubha days
      if (ashubhaDays.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('🔴 ಅಶುಭ ದಿನಗಳು (${ashubhaDays.length})', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.red)),
        const SizedBox(height: 8),
        ...ashubhaDays.map((e) => _buildResultCard(e.value)),
      ],
    ];
  }

  Widget _countBadge(int count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
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
    Color? dotColor;

    if (data != null) {
      dotColor = _qColor(data.quality);
      if (selected) bgColor = kPurple2.withOpacity(0.15);
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
          Text('${day.day}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
          if (data != null) ...[
            const SizedBox(height: 2),
            Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          ],
        ],
      ),
    );
  }
}

// ── Data Model ──
class _SimpleMuhurtaDay {
  final DateTime date;
  final String tithiName;
  final String nakshatraName;
  final String varaName;
  final int score;
  final int quality;     // 0=ashubha, 1=madhyama, 2=shubha
  final List<MuhurtaCheckItem> checks;
  final String abhijitTime;
  final bool hasAmrita;
  final String sunrise;
  final String sunset;

  _SimpleMuhurtaDay({
    required this.date,
    required this.tithiName,
    required this.nakshatraName,
    required this.varaName,
    required this.score,
    required this.quality,
    required this.checks,
    required this.abhijitTime,
    required this.hasAmrita,
    required this.sunrise,
    required this.sunset,
  });
}
