import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/common.dart';
import '../widgets/date_time_input.dart';
import '../core/calculator.dart';
import '../core/janana_marana_dosha.dart';
import '../constants/strings.dart';
import '../constants/places.dart';
import '../services/timezone_service.dart';
import '../services/location_service.dart';

class JananaMaranaScreen extends StatefulWidget {
  const JananaMaranaScreen({super.key});
  @override
  State<JananaMaranaScreen> createState() => _JananaMaranaScreenState();
}

class _JananaMaranaScreenState extends State<JananaMaranaScreen> {
  // ── Input state ──
  DateTime _dob = DateTime.now();
  int _hour = DateTime.now().hour % 12 == 0 ? 12 : DateTime.now().hour % 12;
  int _minute = DateTime.now().minute;
  String _ampm = DateTime.now().hour < 12 ? 'AM' : 'PM';

  late final TextEditingController _placeCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;
  late final TextEditingController _tzCtrl;

  bool _loading = false;
  bool _geoLoading = false;
  String _geoStatus = '';

  // ── Filter state ──
  DoshaType _selectedType = DoshaType.janana;

  // ── Result state ──
  KundaliResult? _result;
  List<DoshaResult>? _doshas;
  PanchangaSummary? _summary;

  @override
  void initState() {
    super.initState();
    _placeCtrl = TextEditingController(text: LocationService.place);
    _latCtrl = TextEditingController(text: LocationService.lat.toStringAsFixed(4));
    _lonCtrl = TextEditingController(text: LocationService.lon.toStringAsFixed(4));
    _tzCtrl = TextEditingController(text: '${LocationService.tzOffset >= 0 ? '+' : ''}${LocationService.tzOffset}');
  }

  @override
  void dispose() {
    _placeCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _tzCtrl.dispose();
    super.dispose();
  }

  // ── Geocode ──
  Future<void> _geocode(String placeName) async {
    if (placeName.trim().isEmpty) return;
    setState(() { _geoLoading = true; _geoStatus = ''; });
    try {
      final q = Uri.encodeComponent(placeName.trim());
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=5');
      final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isEmpty) {
          setState(() => _geoStatus = _ls('placeNotFound'));
        } else if (data.length == 1) {
          _applyGeo(data[0]);
        } else {
          if (mounted) _showPlaceDisambiguation(data);
        }
      }
    } catch (_) {
      setState(() => _geoStatus = _ls('networkError'));
    }
    setState(() => _geoLoading = false);
  }

  void _applyGeo(Map<String, dynamic> place) async {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final displayName = place['display_name'] as String;
    final autoTz = await getTimezoneForPlace(displayName, lat, lon, birthDate: _dob);
    setState(() {
      _latCtrl.text = lat.toStringAsFixed(4);
      _lonCtrl.text = lon.toStringAsFixed(4);
      _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
      _geoStatus = '📍 $displayName (TZ: ${autoTz >= 0 ? "+" : ""}$autoTz)';
    });
  }

  void _showPlaceDisambiguation(List<dynamic> results) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_ls('selectPlace'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple1)),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => Divider(height: 1),
                itemBuilder: (_, i) {
                  final place = results[i];
                  final displayName = place['display_name'] ?? '';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPurple1.withOpacity(0.1),
                      child: Icon(Icons.location_on, color: kPurple1, size: 20),
                    ),
                    title: Text(displayName, style: TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.pop(ctx);
                      _applyGeo(place);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Calculate ──
  Future<void> _calculate() async {
    setState(() { _loading = true; _result = null; _doshas = null; _summary = null; });
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final lat = double.tryParse(_latCtrl.text) ?? 14.98;
      final lon = double.tryParse(_lonCtrl.text) ?? 74.73;
      int h24 = _hour + (_ampm == 'PM' && _hour != 12 ? 12 : 0);
      if (_ampm == 'AM' && _hour == 12) h24 = 0;
      final localHour = h24 + _minute / 60.0;
      final tzOffset = double.tryParse(_tzCtrl.text) ?? LocationService.tzOffset;

      final result = await AstroCalculator.calculate(
        year: _dob.year, month: _dob.month, day: _dob.day,
        hourUtcOffset: tzOffset, hour24: localHour,
        lat: lat, lon: lon, ayanamsaMode: 'lahiri', trueNode: true,
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_ls('calcFailed')), backgroundColor: Colors.red),
          );
        }
        setState(() => _loading = false);
        return;
      }

      // Extract panchanga data
      final p = result.panchang;
      final varaIdx = knVara.indexOf(p.vara);
      final moonInfo = result.planets['ಚಂದ್ರ'];
      final lagnaInfo = result.planets['ಲಗ್ನ'];

      // Sun and Moon longitudes for tithi percent calculation
      final moonLon = moonInfo?.longitude ?? 0.0;
      final lagnaLon = lagnaInfo?.longitude ?? 0.0;
      final sunInfo = result.planets['ರವಿ'];
      final sunLon = sunInfo?.longitude ?? 0.0;
      // Tithi percent: fraction elapsed within current 12° Moon-Sun block
      final moonSunDiff = (moonLon - sunLon + 360.0) % 360.0;
      final moonSunApprox = (moonSunDiff % 12.0) / 12.0;

      // Sun nakshatra index for Kala Dosha calculation
      final sunNakIdx = knNak.indexOf(p.suryaNakshatra).clamp(0, 26);

      final input = DoshaInput(
        nakshatraIndex: p.nakshatraIndex,
        pada: moonInfo?.pada ?? 1,
        nakPercent: p.nakPercent,
        tithiIndex: p.tithiIndex,
        tithiPercent: moonSunApprox,
        varaIndex: varaIdx >= 0 ? varaIdx : 0,
        moonRashiIndex: moonInfo?.rashiIndex ?? 0,
        moonLongitude: moonLon,
        lagnaRashiIndex: lagnaInfo?.rashiIndex ?? 0,
        lagnaLongitude: lagnaLon,
        yogaIndex: knYoga.indexOf(p.yoga).clamp(0, 26),
        karanaString: p.karana,
        sunNakshatraIndex: sunNakIdx,
      );

      final doshas = analyzeJananaMaranaDosha(input);

      final summary = PanchangaSummary(
        tithi: p.tithi,
        nakshatra: p.nakshatra,
        pada: '${moonInfo?.pada ?? "-"}',
        vara: p.vara,
        yoga: p.yoga,
        karana: p.karana,
        chandraRashi: p.chandraRashi,
        lagnaRashi: lagnaInfo?.rashi ?? '-',
      );

      setState(() {
        _result = result;
        _doshas = doshas;
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Multilingual helper ──
  static String _ls(String key) {
    const m = <String, Map<String, String>>{
      'title': {'kn': 'ಜನನ/ಮರಣ ದೋಷ', 'hi': 'जनन/मरण दोष', 'ta': 'ஜனன/மரண தோஷம்', 'te': 'జనన/మరణ దోషం', 'ml': 'ജനന/മരണ ദോഷം', 'en': 'Janana/Marana Dosha'},
      'subtitle': {'kn': 'ಜನ್ಮ ಪಂಚಾಂಗ ದೋಷ ವಿಶ್ಲೇಷಣೆ', 'hi': 'जन्म पंचांग दोष विश्लेषण', 'en': 'Birth Panchanga Dosha Analysis'},
      'selectPlace': {'kn': 'ಸ್ಥಳ ಆಯ್ಕೆ', 'hi': 'स्थान चुनें', 'en': 'Select Place'},
      'placeNotFound': {'kn': 'ಸ್ಥಳ ಸಿಗಲಿಲ್ಲ', 'hi': 'स्थान नहीं मिला', 'en': 'Place not found'},
      'networkError': {'kn': 'ನೆಟ್‌ವರ್ಕ್ ದೋಷ', 'hi': 'नेटवर्क त्रुटि', 'en': 'Network error'},
      'calculate': {'kn': 'ದೋಷ ವಿಶ್ಲೇಷಿಸಿ', 'hi': 'दोष विश्लेषण करें', 'en': 'Analyze Doshas'},
      'calcFailed': {'kn': 'ಲೆಕ್ಕ ವಿಫಲ', 'hi': 'गणना विफल', 'en': 'Calculation failed'},
      'birthPanchanga': {'kn': 'ಜನ್ಮ ಪಂಚಾಂಗ', 'hi': 'जन्म पंचांग', 'en': 'Birth Panchanga'},
      'doshasFound': {'kn': 'ದೋಷಗಳು ಕಂಡುಬಂದಿವೆ', 'hi': 'दोष पाए गए', 'en': 'Doshas Found'},
      'noDoshas': {'kn': 'ಯಾವುದೇ ದೋಷ ಕಂಡುಬಂದಿಲ್ಲ', 'hi': 'कोई दोष नहीं मिला', 'en': 'No doshas found'},
      'severity': {'kn': 'ತೀವ್ರತೆ', 'hi': 'तीव्रता', 'en': 'Severity'},
      'remedy': {'kn': 'ಪರಿಹಾರ', 'hi': 'उपाय', 'en': 'Remedy'},
      'tivra': {'kn': 'ತೀವ್ರ', 'hi': 'तीव्र', 'en': 'Severe'},
      'madhyama': {'kn': 'ಮಧ್ಯಮ', 'hi': 'मध्यम', 'en': 'Moderate'},
      'saumya': {'kn': 'ಸೌಮ್ಯ', 'hi': 'सौम्य', 'en': 'Mild'},
      'place': {'kn': 'ಸ್ಥಳ', 'hi': 'स्थान', 'en': 'Place'},
      'date': {'kn': 'ದಿನಾಂಕ', 'hi': 'तिथि', 'en': 'Date'},
      'time': {'kn': 'ಸಮಯ', 'hi': 'समय', 'en': 'Time'},
      'tithi': {'kn': 'ತಿಥಿ', 'hi': 'तिथि', 'en': 'Tithi'},
      'nakshatra': {'kn': 'ನಕ್ಷತ್ರ', 'hi': 'नक्षत्र', 'en': 'Nakshatra'},
      'pada': {'kn': 'ಪಾದ', 'hi': 'पाद', 'en': 'Pada'},
      'vara': {'kn': 'ವಾರ', 'hi': 'वार', 'en': 'Vara'},
      'yoga': {'kn': 'ಯೋಗ', 'hi': 'ಯೋಗ', 'en': 'Yoga'},
      'chandraRashi': {'kn': 'ಚಂದ್ರ ರಾಶಿ', 'hi': 'चंद्र राशि', 'en': 'Moon Sign'},
      'lagna': {'kn': 'ಲಗ್ನ', 'hi': 'लग्न', 'en': 'Lagna'},
      'karana': {'kn': 'ಕರಣ', 'hi': 'करण', 'en': 'Karana'},
      'janana': {'kn': 'ಜನನ ದೋಷ', 'hi': 'जनन दोष', 'ta': 'ஜனன தோஷம்', 'te': 'జనన దోషం', 'ml': 'ജനന ദോഷം', 'en': 'Janana Dosha'},
      'marana': {'kn': 'ಮರಣ ದೋಷ', 'hi': 'मरण दोष', 'ta': 'மரண தோஷம்', 'te': 'మరణ దోషం', 'ml': 'മരണ ദോഷം', 'en': 'Marana Dosha'},
      'allDoshas': {'kn': 'ಎಲ್ಲಾ ದೋಷಗಳು', 'hi': 'सभी दोष', 'ta': 'அனைத்து தோஷம்', 'te': 'అన్ని దోషాలు', 'ml': 'എല്ലാ ദോഷങ്ങളും', 'en': 'All Doshas'},
      'jananaCount': {'kn': 'ಜನನ', 'hi': 'जनन', 'ta': 'ஜனன', 'te': 'జనన', 'ml': 'ജനന', 'en': 'Janana'},
      'maranaCount': {'kn': 'ಮರಣ', 'hi': 'मरण', 'ta': 'மரண', 'te': 'మరణ', 'ml': 'മരണ', 'en': 'Marana'},
    };
    final lang = AppLocale.current;
    final entry = m[key];
    if (entry == null) return key;
    return entry[lang] ?? entry['kn'] ?? entry['en'] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.langNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          foregroundColor: kText,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_ls('title'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple1)),
              Text(_ls('subtitle'), style: TextStyle(fontSize: 11, color: kMuted)),
            ],
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ResponsiveCenter(
              maxWidth: 600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputCard(),
                  const SizedBox(height: 16),
                  _buildCalculateButton(),
                  if (_loading) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (_doshas != null && _summary != null) ...[
                    const SizedBox(height: 24),
                    _buildPanchangaSummaryCard(),
                    const SizedBox(height: 16),
                    _buildTypeToggle(),
                    const SizedBox(height: 16),
                    _buildDoshaResults(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_ls('date'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
            const SizedBox(height: 6),
            DateInputRow(
              date: _dob,
              color: kPurple2,
              onChanged: (d) => setState(() => _dob = d),
            ),
            const SizedBox(height: 14),
            Text(_ls('time'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
            const SizedBox(height: 6),
            TimeInputRow(
              hour: _hour,
              minute: _minute,
              ampm: _ampm,
              color: kPurple2,
              onChanged: (h, m, a) => setState(() { _hour = h; _minute = m; _ampm = a; }),
            ),
            const SizedBox(height: 14),
            Text(_ls('place'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
            const SizedBox(height: 6),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _placeCtrl.text),
              optionsBuilder: (v) {
                if (v.text.length < 2) return const Iterable<String>.empty();
                final q = v.text.toLowerCase();
                return offlinePlaces.keys.where((p) => p.toLowerCase().contains(q)).take(10);
              },
              onSelected: (val) {
                _placeCtrl.text = val;
                _geocode(val);
              },
              fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
                return TextField(
                  controller: ctrl,
                  focusNode: focus,
                  style: TextStyle(fontSize: 14, color: kText),
                  decoration: InputDecoration(
                    hintText: _ls('place'),
                    hintStyle: TextStyle(color: kMuted.withOpacity(0.5)),
                    prefixIcon: _geoLoading
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                        : Icon(Icons.location_on_outlined, color: kMuted, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPurple2, width: 2)),
                  ),
                  onSubmitted: (_) {
                    onSubmit();
                    _geocode(ctrl.text);
                  },
                );
              },
            ),
            if (_geoStatus.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(_geoStatus, style: TextStyle(fontSize: 11, color: kGreen)),
            ],
            const SizedBox(height: 10),
            // Lat / Lon / TZ row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                    style: TextStyle(fontSize: 12, color: kText),
                    decoration: InputDecoration(
                      labelText: 'Lat',
                      labelStyle: TextStyle(fontSize: 11, color: kMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lonCtrl,
                    keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                    style: TextStyle(fontSize: 12, color: kText),
                    decoration: InputDecoration(
                      labelText: 'Lon',
                      labelStyle: TextStyle(fontSize: 11, color: kMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _tzCtrl,
                    keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                    style: TextStyle(fontSize: 12, color: kText),
                    decoration: InputDecoration(
                      labelText: 'TZ',
                      labelStyle: TextStyle(fontSize: 11, color: kMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _calculate,
        icon: const Icon(Icons.search, size: 20),
        label: Text(_ls('calculate'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPurple2,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildPanchangaSummaryCard() {
    final s = _summary!;
    final rows = [
      [_ls('tithi'), translateKn(s.tithi)],
      [_ls('nakshatra'), '${translateKn(s.nakshatra)} (${_ls("pada")} ${s.pada})'],
      [_ls('vara'), translateKn(s.vara)],
      [_ls('yoga'), translateKn(s.yoga)],
      [_ls('karana'), translateKn(s.karana)],
      [_ls('chandraRashi'), translateKn(s.chandraRashi)],
      [_ls('lagna'), translateKn(s.lagnaRashi)],
    ];

    return AppCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: kPurple2, size: 20),
                const SizedBox(width: 8),
                Text(_ls('birthPanchanga'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPurple1)),
              ],
            ),
            const SizedBox(height: 12),
            ...rows.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(r[0], style: TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Text(r[1], style: TextStyle(fontSize: 14, color: kText, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    final doshas = _doshas!;
    final jCount = doshas.where((d) => d.type == DoshaType.janana).length;
    final mCount = doshas.where((d) => d.type == DoshaType.marana).length;

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _toggleBtn(
            label: _ls('jananaCount'),
            count: jCount,
            icon: Icons.child_care,
            color: const Color(0xFF7C3AED),
            selected: _selectedType == DoshaType.janana,
            onTap: () => setState(() => _selectedType = DoshaType.janana),
          ),
          _toggleBtn(
            label: _ls('maranaCount'),
            count: mCount,
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFDC2626),
            selected: _selectedType == DoshaType.marana,
            onTap: () => setState(() => _selectedType = DoshaType.marana),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800,
                color: selected ? Colors.white : color,
              )),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.25) : color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : color,
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoshaResults() {
    final doshas = _doshas!;

    // Filter by selected type
    final filtered = doshas.where((d) => d.type == _selectedType).toList();

    if (filtered.isEmpty) {
      return AppCard(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, color: kGreen, size: 48),
              const SizedBox(height: 12),
              Text(_ls('noDoshas'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kGreen)),
            ],
          ),
        ),
      );
    }

    // Sort: tivra first, then madhyama, then saumya
    final sorted = List<DoshaResult>.from(filtered)..sort((a, b) => a.severity.index.compareTo(b.severity.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kOrange, size: 22),
            const SizedBox(width: 8),
            Text('${_ls('doshasFound')} (${filtered.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kOrange)),
          ],
        ),
        const SizedBox(height: 12),
        ...sorted.map((d) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDoshaCard(d),
        )),
      ],
    );
  }

  Widget _buildDoshaCard(DoshaResult d) {
    Color severityColor;
    String severityLabel;
    IconData severityIcon;

    switch (d.severity) {
      case DoshaSeverity.tivra:
        severityColor = const Color(0xFFDC2626);
        severityLabel = _ls('tivra');
        severityIcon = Icons.error;
        break;
      case DoshaSeverity.madhyama:
        severityColor = kOrange;
        severityLabel = _ls('madhyama');
        severityIcon = Icons.warning_amber_rounded;
        break;
      case DoshaSeverity.saumya:
        severityColor = const Color(0xFF2196F3);
        severityLabel = _ls('saumya');
        severityIcon = Icons.info_outline;
        break;
    }

    final isKn = AppLocale.current == 'kn' || AppLocale.current == 'hi' || AppLocale.current == 'ta' || AppLocale.current == 'te' || AppLocale.current == 'ml';
    final name = isKn ? d.nameKn : d.nameEn;
    final desc = isKn ? d.descriptionKn : d.descriptionEn;
    final remedy = isKn ? d.remedyKn : d.remedyEn;

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with severity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(severityIcon, color: severityColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: severityColor)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(severityLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: severityColor)),
                ),
              ],
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(desc, style: TextStyle(fontSize: 13, color: kText, height: 1.5)),
          ),
          // Remedy
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kGreen.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.healing, color: kGreen, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_ls('remedy'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kGreen)),
                      const SizedBox(height: 4),
                      Text(remedy, style: TextStyle(fontSize: 12, color: kText, height: 1.4)),
                    ],
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
