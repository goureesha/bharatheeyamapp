import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sweph/sweph.dart';
import '../core/ephemeris.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import '../constants/places.dart';
import '../services/timezone_service.dart';
import '../widgets/common.dart';

// ─────────────────────────────────────────────
// Reverse Kundali — find date/time from graha rashis
// Algorithm:  ಶನಿ+ಗುರು → year
//             ರಾಹು+ಕೇತು → confirm year
//             ರವಿ → month
//             ಚಂದ್ರ → date
//             ಲಗ್ನ → time
//             verify ಕುಜ,ಬುಧ,ಶುಕ್ರ
// ─────────────────────────────────────────────

class ReverseKundaliScreen extends StatefulWidget {
  const ReverseKundaliScreen({super.key});

  @override
  State<ReverseKundaliScreen> createState() => _ReverseKundaliScreenState();
}

class _ReverseKundaliScreenState extends State<ReverseKundaliScreen> {
  // Planet order for input: Shani, Guru, Rahu, Ketu, Ravi, Chandra, Kuja, Budha, Shukra
  static const _planets = ['ಶನಿ', 'ಗುರು', 'ರಾಹು', 'ಕೇತು', 'ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಶುಕ್ರ'];
  static const _engPlanets = ['Saturn', 'Jupiter', 'Rahu', 'Ketu', 'Sun', 'Moon', 'Mars', 'Mercury', 'Venus'];

  // Rashi selected for each planet (-1 = not set)
  final List<int> _selectedRashi = List.filled(9, -1);

  // Navamsha selected (0 = not set, 1-9 = navamsha pada)
  final List<int> _selectedNavamsha = List.filled(9, -1); // -1 = not set, 0-11 = navamsha rashi index

  // Lagna rashi
  int _lagnaRashi = -1;

  // Year range
  int _fromYear = 1960;
  int _toYear = 2010;

  // Location for lagna
  double _lat = 12.9716; // Bangalore default
  double _lon = 77.5946;
  double _tzOffset = 5.5; // IST
  String _locationName = 'Bengaluru';

  // Results
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  String _statusMessage = '';
  double _progress = 0.0;
  int _totalSteps = 0;
  int _currentStep = 0;

  // Location search
  bool _geoLoading = false;
  String _geoStatus = '';

  @override
  Widget build(BuildContext context) {
    final rashi = appRashi;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(
          kn: 'ರಿವರ್ಸ್ ಕುಂಡಲಿ',
          hi: 'रिवर्स कुंडली',
          ta: 'ரிவர்ஸ் குண்டலி',
          te: 'రివర్స్ కుండలి',
          ml: 'റിവേഴ്സ് കുണ്ഡലി',
          en: 'Reverse Kundali',
        )),
        backgroundColor: kPurple2,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Description ──
              Card(
                color: kPurple2.withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _t(
                      kn: 'ಗ್ರಹಗಳ ರಾಶಿ ಸ್ಥಾನ ನೀಡಿ, ಜನ್ಮ ದಿನಾಂಕ ಮತ್ತು ಸಮಯವನ್ನು ಹುಡುಕಿ.',
                      hi: 'ग्रहों की राशि स्थिति दें, जन्म तिथि और समय खोजें.',
                      ta: 'கிரகங்களின் ராசி நிலையை கொடுங்கள், பிறந்த தேதி மற்றும் நேரத்தை கண்டறியுங்கள்.',
                      te: 'గ్రహాల రాశి స్థానం ఇవ్వండి, జన్మ తేదీ మరియు సమయాన్ని కనుగొనండి.',
                      ml: 'ഗ്രഹങ്ങളുടെ രാശി സ്ഥാനം നൽകുക, ജനന തീയതിയും സമയവും കണ്ടെത്തുക.',
                      en: 'Enter planetary rashi positions to find the birth date and time. For D9 (navamsha): use the rashi number written in old kundali papers (e.g. Ravi 5 = Simha navamsha, Chandra 1 = Mesha navamsha).',
                    ),
                    style: const TextStyle(fontSize: 13, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Year Range ──
              _buildYearRange(),
              const SizedBox(height: 12),

              // ── Location ──
              _buildLocationRow(),
              const SizedBox(height: 12),

              // ── Graha Rashi Selection ──
              Text(
                _t(kn: '🪐 ಗ್ರಹ ರಾಶಿ ಸ್ಥಾನ', hi: '🪐 ग्रह राशि स्थिति', ta: '🪐 கிரக ராசி நிலை',
                    te: '🪐 గ్రహ రాశి స్థానం', ml: '🪐 ഗ്രഹ രാശി സ്ഥാനം', en: '🪐 Planet Rashi Positions'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              ...List.generate(_planets.length, (i) => _buildPlanetRow(i, rashi)),
              const SizedBox(height: 8),

              // ── Lagna ──
              _buildLagnaRow(rashi),
              const SizedBox(height: 16),

              // ── Search Button ──
              ElevatedButton.icon(
                onPressed: _isSearching ? null : _startSearch,
                icon: _isSearching
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search),
                label: Text(_isSearching
                    ? _t(kn: 'ಹುಡುಕುತ್ತಿದೆ...', hi: 'खोज रहा है...', ta: 'தேடுகிறது...', te: 'వెతుకుతోంది...', ml: 'തിരയുന്നു...', en: 'Searching...')
                    : _t(kn: 'ಹುಡುಕಿ', hi: 'खोजें', ta: 'தேடு', te: 'వెతుకు', ml: 'തിരയുക', en: 'Search')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple2,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // ── Progress ──
              if (_isSearching) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _progress, backgroundColor: Colors.grey.shade200, color: kPurple2),
                const SizedBox(height: 4),
                Text(_statusMessage, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
              ],

              // ── Results ──
              if (_results.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '${_t(kn: 'ಫಲಿತಾಂಶ', hi: 'परिणाम', ta: 'முடிவுகள்', te: 'ఫలితాలు', ml: 'ഫലങ്ങൾ', en: 'Results')}: ${_results.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ..._results.map(_buildResultCard),
              ],

              if (!_isSearching && _results.isEmpty && _statusMessage.contains('✅'))
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _t(kn: 'ಯಾವ ಹೊಂದಾಣಿಕೆ ಸಿಕ್ಕಿಲ್ಲ', hi: 'कोई मिलान नहीं मिला', ta: 'பொருத்தம் கிடைக்கவில்லை',
                        te: 'సరిపోలిక దొరకలేదు', ml: 'പൊരുത്തം ലഭിച്ചില്ല', en: 'No match found'),
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // UI Builders
  // ─────────────────────────────────────────────

  Widget _buildYearRange() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text('📅 ${_t(kn: 'ವರ್ಷ ವ್ಯಾಪ್ತಿ', hi: 'वर्ष सीमा', ta: 'ஆண்டு வரம்பு', te: 'సంవత్సర పరిధి', ml: 'വർഷ പരിധി', en: 'Year Range')}: ',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: '$_fromYear',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8)),
                onChanged: (v) => _fromYear = int.tryParse(v) ?? _fromYear,
              ),
            ),
            const Text(' — ', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: '$_toYear',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8)),
                onChanged: (v) => _toYear = int.tryParse(v) ?? _toYear,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.length < 2) return const Iterable.empty();
                final query = textEditingValue.text.toLowerCase();
                final offline = offlinePlaces.keys.where((p) => p.toLowerCase().contains(query)).toList();
                final worldResults = searchWorldCities(textEditingValue.text, limit: 15);
                for (final w in worldResults) {
                  final label = worldCityLabel(w);
                  if (!offline.any((o) => o.toLowerCase() == label.toLowerCase())) offline.add(label);
                }
                return offline.take(20);
              },
              fieldViewBuilder: (context, textCtrl, focusNode, onFieldSubmitted) {
                if (textCtrl.text.isEmpty && _locationName.isNotEmpty) textCtrl.text = _locationName;
                return TextField(
                  controller: textCtrl, focusNode: focusNode,
                  style: TextStyle(color: kText),
                  decoration: InputDecoration(
                    labelText: _t(kn: '📍 ಸ್ಥಳ ಹುಡುಕಿ', hi: '📍 स्थान खोजें', ta: '📍 இடம் தேடுங்கள்', te: '📍 స్థలం వెతకండి', ml: '📍 സ്ഥലം തിരയുക', en: '📍 Search Place'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _geoLoading
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                        : IconButton(icon: Icon(Icons.my_location, color: kTeal), onPressed: () => _geocodeOnline(textCtrl.text)),
                  ),
                  onSubmitted: (_) => _geocodeOnline(textCtrl.text),
                );
              },
              onSelected: (String selection) => _onPlaceSelected(selection),
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0, borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250, maxWidth: 350),
                      child: ListView.builder(
                        padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length,
                        itemBuilder: (_, i) {
                          final option = options.elementAt(i);
                          return ListTile(dense: true, leading: Icon(Icons.location_on, color: kPurple2, size: 18),
                              title: Text(option, style: const TextStyle(fontSize: 13)), onTap: () => onSelected(option));
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_geoStatus.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_geoStatus, style: TextStyle(fontSize: 11, color: Colors.green.shade700))),
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('${_lat.toStringAsFixed(4)}, ${_lon.toStringAsFixed(4)}  •  UTC${_tzOffset >= 0 ? '+' : ''}$_tzOffset', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanetRow(int index, List<String> rashiNames) {
    final planetName = trAll(_planets[index]);
    final engName = _engPlanets[index];
    // Color coding based on funnel stage
    final Color dotColor;
    if (index <= 1) dotColor = Colors.red; // Shani, Guru = year
    else if (index <= 3) dotColor = Colors.orange; // Rahu, Ketu = confirm year
    else if (index == 4) dotColor = Colors.blue; // Ravi = month
    else if (index == 5) dotColor = Colors.green; // Chandra = date
    else dotColor = Colors.grey; // Kuja, Budha, Shukra = verify

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 70,
            child: Text('$planetName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: _selectedRashi[index] >= 0 ? dotColor.withOpacity(0.5) : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: _selectedRashi[index] >= 0 ? dotColor.withOpacity(0.05) : null,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedRashi[index] >= 0 ? _selectedRashi[index] : null,
                  isExpanded: true,
                  hint: Text(_t(kn: 'ರಾಶಿ ಆಯ್ಕೆ', hi: 'राशि चुनें', ta: 'ராசி தேர்வு', te: 'రాశి ఎంపిక', ml: 'രാശി തിരഞ്ഞെടുക്കുക', en: 'Select Rashi'),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  items: List.generate(12, (r) => DropdownMenuItem(value: r, child: Text(rashiNames[r]))),
                  onChanged: (v) => setState(() => _selectedRashi[index] = v ?? -1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Navamsha dropdown - shows rashi number+name matching old paper format
          // e.g. ''Ravi 5'' in old kundali = Ravi navamsha rashi #5 = Simha
          SizedBox(
            width: 90,
            height: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedNavamsha[index] >= 0 ? _selectedNavamsha[index] : null,
                  isExpanded: true,
                  hint: const Text('D9 #', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                  items: List.generate(12, (r) => DropdownMenuItem(
                    value: r,
                    child: Text('${r + 1}. ${appRashi[r]}', style: const TextStyle(fontSize: 11)),
                  )),
                  onChanged: (v) => setState(() => _selectedNavamsha[index] = v ?? -1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLagnaRow(List<String> rashiNames) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text('🏠 ${_t(kn: 'ಲಗ್ನ', hi: 'लग्न', ta: 'லக்னம்', te: 'లగ్నం', ml: 'ലഗ്നം', en: 'Lagna')}: ',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _lagnaRashi >= 0 ? _lagnaRashi : null,
                    isExpanded: true,
                    hint: Text(_t(kn: 'ರಾಶಿ ಆಯ್ಕೆ (ಐಚ್ಛಿಕ)', hi: 'राशि चुनें (वैकल्पिक)', ta: 'ராசி தேர்வு (விருப்பம்)',
                        te: 'రాశి ఎంపిక (ఐచ్ఛికం)', ml: 'രാശി തിരഞ്ഞെടുക്കുക (ഐച്ഛികം)', en: 'Select Rashi (optional)'),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    items: List.generate(12, (r) => DropdownMenuItem(value: r, child: Text(rashiNames[r]))),
                    onChanged: (v) => setState(() => _lagnaRashi = v ?? -1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> r) {
    final date = r['date'] as DateTime;
    final timeStr = r['time'] as String;
    final matchPercent = r['matchPercent'] as int;
    final planetMatches = r['planetMatches'] as Map<String, bool>;

    final dateStr = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final varaStr = r['vara'] as String? ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(matchPercent == 100 ? Icons.check_circle : Icons.info_outline,
                    color: matchPercent == 100 ? Colors.green : Colors.orange, size: 22),
                const SizedBox(width: 8),
                Text('$dateStr  $timeStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: matchPercent == 100 ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$matchPercent%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            if (varaStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(varaStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
            const Divider(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: planetMatches.entries.map((e) {
                final matched = e.value;
                return Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(trAll(e.key), style: TextStyle(fontSize: 10, color: matched ? Colors.green.shade800 : Colors.red.shade800)),
                  backgroundColor: matched ? Colors.green.shade50 : Colors.red.shade50,
                  side: BorderSide(color: matched ? Colors.green.shade200 : Colors.red.shade200),
                  avatar: Icon(matched ? Icons.check : Icons.close, size: 14, color: matched ? Colors.green : Colors.red),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Location Geocoding
  // ─────────────────────────────────────────────
  void _onPlaceSelected(String selection) {
    if (offlinePlaces.containsKey(selection)) {
      final coords = offlinePlaces[selection]!;
      setState(() {
        _locationName = selection;
        _lat = coords[0]; _lon = coords[1]; _tzOffset = coords[2];
        _geoStatus = '📍 $selection (TZ: ${coords[2] >= 0 ? '+' : ''}${coords[2]})';
      });
    } else {
      final worldResults = searchWorldCities(selection.split(', ').first, limit: 1);
      if (worldResults.isNotEmpty) {
        final w = worldResults.first;
        final lat = (w['la'] as num).toDouble();
        final lon = (w['lo'] as num).toDouble();
        final cc = w['c'] as String? ?? '';
        final tz = cc.isNotEmpty ? getDstAwareOffset(cc, lat, lon, DateTime.now()) : (w['tz'] as num).toDouble();
        setState(() {
          _locationName = selection; _lat = lat; _lon = lon; _tzOffset = tz;
          _geoStatus = '📍 $selection (TZ: ${tz >= 0 ? '+' : ''}$tz)';
        });
      } else {
        _geocodeOnline(selection);
      }
    }
  }

  Future<void> _geocodeOnline(String placeName) async {
    if (placeName.trim().isEmpty) return;
    setState(() { _geoLoading = true; _geoStatus = ''; });
    try {
      final q = Uri.encodeComponent(placeName.trim());
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=5');
      final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isEmpty) {
          setState(() => _geoStatus = _t(kn: 'ಸ್ಥಳ ಸಿಕ್ಕಿಲ್ಲ', hi: 'स्थान नहीं मिला', ta: 'இடம் கிடைக்கவில்லை', te: 'స్థలం దొరకలేదు', ml: 'സ്ഥലം ലഭിച്ചില്ല', en: 'Place not found'));
        } else if (data.length == 1) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final displayName = data[0]['display_name'] as String;
          final autoTz = await getTimezoneForPlace(displayName, lat, lon);
          setState(() {
            _locationName = placeName.trim(); _lat = lat; _lon = lon; _tzOffset = autoTz;
            _geoStatus = '📍 $displayName (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
          });
        } else {
          if (mounted) _showPlaceDisambiguation(data);
        }
      }
    } catch (_) {
      setState(() => _geoStatus = _t(kn: 'ನೆಟ್‌ವರ್ಕ್ ದೋಷ', hi: 'नेटवर्क त्रुटि', ta: 'பிணைய பிழை', te: 'నెట్‌వర్క్ లోపం', ml: 'നെറ്റ്‌വർക്ക് പിശക്', en: 'Network error'));
    }
    setState(() => _geoLoading = false);
  }

  void _showPlaceDisambiguation(List<dynamic> results) {
    showModalBottomSheet(
      context: context, backgroundColor: kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16),
            child: Text(_t(kn: 'ಸ್ಥಳ ಆಯ್ಕೆ ಮಾಡಿ', hi: 'स्थान चुनें', ta: 'இடம் தேர்வு', te: 'స్థలం ఎంచుకోండి', ml: 'സ്ഥലം തിരഞ്ഞെടുക്കുക', en: 'Select Place'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple1))),
          Flexible(child: ListView.separated(
            shrinkWrap: true, itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final place = results[i];
              final displayName = place['display_name'] ?? '';
              return ListTile(
                leading: CircleAvatar(backgroundColor: kPurple1.withOpacity(0.1), child: Icon(Icons.location_on, color: kPurple1, size: 20)),
                title: Text(displayName, style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () async {
                  Navigator.pop(ctx);
                  final lat = double.parse(place['lat']);
                  final lon = double.parse(place['lon']);
                  final autoTz = await getTimezoneForPlace(displayName, lat, lon);
                  setState(() {
                    _locationName = displayName.split(',').first; _lat = lat; _lon = lon; _tzOffset = autoTz;
                    _geoStatus = '📍 $displayName (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
                  });
                },
              );
            },
          )),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SEARCH ALGORITHM
  // ─────────────────────────────────────────────

  Future<void> _startSearch() async {
    // Validate: at least Shani and Guru must be set
    if (_selectedRashi[0] < 0 || _selectedRashi[1] < 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t(
          kn: 'ಕನಿಷ್ಠ ಶನಿ ಮತ್ತು ಗುರು ರಾಶಿ ಆಯ್ಕೆ ಮಾಡಿ',
          hi: 'कम से कम शनि और गुरु की राशि चुनें',
          ta: 'குறைந்தபட்சம் சனி மற்றும் குரு ராசி தேர்ந்தெடுக்கவும்',
          te: 'కనీసం శని మరియు గురు రాశి ఎంపిక చేయండి',
          ml: 'ശനിയും ഗുരുവും രാശി തിരഞ്ഞെടുക്കുക',
          en: 'Select at least Saturn and Jupiter rashi',
        )),
      ));
      return;
    }

    setState(() {
      _isSearching = true;
      _results = [];
      _statusMessage = '';
      _progress = 0;
    });

    try {
      await Ephemeris.initSweph();
      final results = await _searchDates();
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
          _statusMessage = '✅ ${_t(kn: 'ಹುಡುಕಾಟ ಮುಗಿಯಿತು', hi: 'खोज पूरी हुई', ta: 'தேடல் முடிந்தது', te: 'వెతుకుడు పూర్తయింది', ml: 'തിരച്ചിൽ പൂർത്തിയായി', en: 'Search complete')}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _statusMessage = '❌ Error: $e';
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _searchDates() async {
    final results = <Map<String, dynamic>>[];
    final ayanamsa = 'lahiri';
    const trueNode = true;

    // Map: index in _planets → key in Ephemeris.calcAll result
    const ephKeys = ['Saturn', 'Jupiter', 'Rahu', 'Ketu', 'Sun', 'Moon', 'Mars', 'Mercury', 'Venus'];

    // ── STEP 1: Scan years — check Shani & Guru on 1st of each month ──
    _updateStatus(_t(
      kn: 'ಹಂತ 1: ಶನಿ+ಗುರು ಸ್ಥಿತಿಯಿಂದ ವರ್ಷ ಹುಡುಕುತ್ತಿದೆ...',
      hi: 'चरण 1: शनि+गुरु स्थिति से वर्ष खोज रहा है...',
      ta: 'நிலை 1: சனி+குரு நிலையில் இருந்து ஆண்டு தேடுகிறது...',
      te: 'దశ 1: శని+గురు స్థితి నుండి సంవత్సరం వెతుకుతోంది...',
      ml: 'ഘട്ടം 1: ശനി+ഗുരു സ്ഥിതിയിൽ നിന്ന് വർഷം തിരയുന്നു...',
      en: 'Step 1: Finding year from Saturn+Jupiter...',
    ));

    final candidateMonths = <DateTime>[];
    final totalMonths = (_toYear - _fromYear + 1) * 12;
    _totalSteps = totalMonths;
    _currentStep = 0;

    for (int y = _fromYear; y <= _toYear; y++) {
      for (int m = 1; m <= 12; m++) {
        _currentStep++;
        if (_currentStep % 12 == 0) {
          _updateProgress(_currentStep / _totalSteps * 0.3);
          await Future.delayed(Duration.zero); // yield to UI
        }

        final jd = Sweph.swe_julday(y, m, 15, 12.0 - _tzOffset, CalendarType.SE_GREG_CAL);
        final positions = Ephemeris.calcAll(jd, ayanamsa, trueNode);

        // Check Saturn rashi
        final saturnRashi = _degToRashi(positions['Saturn']![0]);
        if (saturnRashi != _selectedRashi[0]) continue;

        // Check Jupiter rashi
        final jupiterRashi = _degToRashi(positions['Jupiter']![0]);
        if (jupiterRashi != _selectedRashi[1]) continue;

        // Check Rahu if provided
        if (_selectedRashi[2] >= 0) {
          final rahuRashi = _degToRashi(positions['Rahu']![0]);
          if (rahuRashi != _selectedRashi[2]) continue;
        }

        // Check Ketu if provided
        if (_selectedRashi[3] >= 0) {
          final ketuRashi = _degToRashi(positions['Ketu']![0]);
          if (ketuRashi != _selectedRashi[3]) continue;
        }

        candidateMonths.add(DateTime(y, m, 1));
      }
    }

    if (candidateMonths.isEmpty) return results;

    // ── STEP 2: Within candidate months, scan day-by-day for Sun match ──
    _updateStatus(_t(
      kn: 'ಹಂತ 2: ರವಿ ಸ್ಥಿತಿಯಿಂದ ತಿಂಗಳು ಹುಡುಕುತ್ತಿದೆ...',
      hi: 'चरण 2: सूर्य स्थिति से महीना खोज रहा है...',
      ta: 'நிலை 2: சூரிய நிலையில் இருந்து மாதம் தேடுகிறது...',
      te: 'దశ 2: రవి స్థితి నుండి నెల వెతుకుతోంది...',
      ml: 'ഘട്ടം 2: രവി സ്ഥിതിയിൽ നിന്ന് മാസം തിരയുന്നു...',
      en: 'Step 2: Finding month from Sun...',
    ));

    final candidateDays = <DateTime>[];
    final totalDays = candidateMonths.length * 31;
    _totalSteps = totalDays;
    _currentStep = 0;

    for (final cm in candidateMonths) {
      final daysInMonth = DateTime(cm.year, cm.month + 1, 0).day;
      for (int d = 1; d <= daysInMonth; d++) {
        _currentStep++;
        if (_currentStep % 10 == 0) {
          _updateProgress(0.3 + (_currentStep / _totalSteps * 0.3));
          await Future.delayed(Duration.zero);
        }

        final jd = Sweph.swe_julday(cm.year, cm.month, d, 12.0 - _tzOffset, CalendarType.SE_GREG_CAL);
        final positions = Ephemeris.calcAll(jd, ayanamsa, trueNode);

        // Re-verify Saturn+Jupiter (they might shift at month boundaries)
        if (_degToRashi(positions['Saturn']![0]) != _selectedRashi[0]) continue;
        if (_degToRashi(positions['Jupiter']![0]) != _selectedRashi[1]) continue;

        // Check Sun if provided
        if (_selectedRashi[4] >= 0) {
          final sunRashi = _degToRashi(positions['Sun']![0]);
          if (sunRashi != _selectedRashi[4]) continue;
        }

        // Check Moon if provided
        if (_selectedRashi[5] >= 0) {
          final moonRashi = _degToRashi(positions['Moon']![0]);
          if (moonRashi != _selectedRashi[5]) continue;
        }

        // Check navamsha rashi if provided for Sun
        if (_selectedNavamsha[4] >= 0) {
          final sunNavRashi = _degToNavamshaRashi(positions['Sun']![0]);
          if (sunNavRashi != _selectedNavamsha[4]) continue;
        }

        // Check remaining planets (Kuja, Budha, Shukra)
        bool allMatch = true;
        for (int i = 6; i < 9; i++) {
          if (_selectedRashi[i] < 0) continue;
          final pRashi = _degToRashi(positions[ephKeys[i]]![0]);
          if (pRashi != _selectedRashi[i]) {
            allMatch = false;
            break;
          }
        }
        if (!allMatch) continue;

        candidateDays.add(DateTime(cm.year, cm.month, d));
      }
    }

    if (candidateDays.isEmpty) return results;

    // ── STEP 3: For each candidate day, find Lagna time ──
    _updateStatus(_t(
      kn: 'ಹಂತ 3: ಲಗ್ನದಿಂದ ಸಮಯ ಹುಡುಕುತ್ತಿದೆ...',
      hi: 'चरण 3: लग्न से समय खोज रहा है...',
      ta: 'நிலை 3: லக்னத்தில் இருந்து நேரம் தேடுகிறது...',
      te: 'దశ 3: లగ్నం నుండి సమయం వెతుకుతోంది...',
      ml: 'ഘട്ടം 3: ലഗ്നത്തിൽ നിന്ന് സമയം തിരയുന്നു...',
      en: 'Step 3: Finding time from Lagna...',
    ));

    _totalSteps = candidateDays.length;
    _currentStep = 0;

    for (final cd in candidateDays) {
      _currentStep++;
      _updateProgress(0.6 + (_currentStep / _totalSteps * 0.4));
      await Future.delayed(Duration.zero);

      if (_lagnaRashi >= 0) {
        // Scan every 5 minutes of the day for lagna match
        for (int mins = 0; mins < 1440; mins += 5) {
          final hour24 = mins / 60.0;
          final jd = Sweph.swe_julday(cd.year, cd.month, cd.day, hour24 - _tzOffset, CalendarType.SE_GREG_CAL);

          // Get lagna
          final ayn = Ephemeris.ayanamsaLahiri(jd);
          final housesRes = Ephemeris.placidusHousesFull(jd, _lat, _lon);
          if (housesRes == null || housesRes.ascmc.length < 2) continue;

          final lagnaLon = ((housesRes.ascmc[0] - ayn) % 360 + 360) % 360;
          final lagnaR = (lagnaLon / 30).floor() % 12;

          if (lagnaR != _lagnaRashi) continue;

          // Lagna matches! Verify all planets at this exact time
          final positions = Ephemeris.calcAll(jd, ayanamsa, trueNode);
          final matchResult = _buildMatchResult(cd, hour24, positions, lagnaR);
          if (matchResult != null) {
            results.add(matchResult);
          }

          // Skip ahead to avoid duplicate lagna hits in same ~2hr window
          mins += 115; // jump ~2 hours
        }
      } else {
        // No lagna specified — just add the day with noon time
        final jd = Sweph.swe_julday(cd.year, cd.month, cd.day, 12.0 - _tzOffset, CalendarType.SE_GREG_CAL);
        final positions = Ephemeris.calcAll(jd, ayanamsa, trueNode);
        final matchResult = _buildMatchResult(cd, 12.0, positions, null);
        if (matchResult != null) {
          results.add(matchResult);
        }
      }

      // Limit results
      if (results.length >= 50) break;
    }

    return results;
  }

  Map<String, dynamic>? _buildMatchResult(DateTime date, double hour24, Map<String, List<double>> positions, int? lagnaRashi) {
    const ephKeys = ['Saturn', 'Jupiter', 'Rahu', 'Ketu', 'Sun', 'Moon', 'Mars', 'Mercury', 'Venus'];
    final planetMatches = <String, bool>{};
    int matched = 0;
    int total = 0;

    for (int i = 0; i < 9; i++) {
      if (_selectedRashi[i] < 0) continue;
      total++;
      final pRashi = _degToRashi(positions[ephKeys[i]]![0]);
      final isMatch = pRashi == _selectedRashi[i];
      // Also check navamsha if provided
      if (isMatch && _selectedNavamsha[i] >= 0) {
        final pNav = _degToNavamshaRashi(positions[ephKeys[i]]![0]);
        final navMatch = pNav == _selectedNavamsha[i];
        planetMatches[_planets[i]] = navMatch;
        if (navMatch) matched++;
      } else {
        planetMatches[_planets[i]] = isMatch;
        if (isMatch) matched++;
      }
    }

    // Lagna match
    if (_lagnaRashi >= 0 && lagnaRashi != null) {
      total++;
      final lagMatch = lagnaRashi == _lagnaRashi;
      planetMatches['ಲಗ್ನ'] = lagMatch;
      if (lagMatch) matched++;
    }

    final matchPercent = total > 0 ? (matched * 100 / total).round() : 0;

    // Only return if at least core planets match
    if (matchPercent < 70) return null;

    // Format time
    final h = hour24.floor();
    final m = ((hour24 - h) * 60).round();
    final amPm = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final timeStr = _lagnaRashi >= 0
        ? '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $amPm'
        : _t(kn: '(ಲಗ್ನ ನೀಡಿಲ್ಲ)', hi: '(लग्न नहीं दिया)', ta: '(லக்னம் தரவில்லை)', te: '(లగ్నం ఇవ్వలేదు)', ml: '(ലഗ്നം നൽകിയില്ല)', en: '(No lagna given)');

    // Day of week: DateTime.weekday: 1=Mon...7=Sun; knVara: 0=Sun,1=Mon...6=Sat
    final varaIndex = date.weekday % 7;

    return {
      'date': date,
      'time': timeStr,
      'matchPercent': matchPercent,
      'planetMatches': planetMatches,
      'vara': appVara[varaIndex],
    };
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  int _degToRashi(double deg) => ((deg % 360) / 30).floor() % 12;

  /// Returns the navamsha rashi index (0-11) for a given longitude.
  /// Traditional rule:
  ///   Chara  (Mesha/0, Karka/3, Tula/6, Makara/9)   â†’ starts from own sign
  ///   Sthira (Vrisha/1, Simha/4, Vrischika/7, Kumbha/10) â†’ starts from 9th (Makara/Mesha/Karka/Tula)
  ///   Dwiswa (Mithuna/2, Kanya/5, Dhanu/8, Meena/11)    â†’ starts from 5th (Tula/Makara/Mesha/Karka)
  int _degToNavamshaRashi(double deg) {
    final normDeg = (deg % 360 + 360) % 360;
    final rashiIdx = (normDeg / 30).floor() % 12;
    final inRashi = normDeg % 30;
    final pada = (inRashi / 3.333333333).floor(); // 0-8
    // Navamsha start rashi for each of the 12 rashis
    const navStart = [0, 9, 6, 3, 0, 9, 6, 3, 0, 9, 6, 3];
    return (navStart[rashiIdx] + pada) % 12;
  }

  /// Legacy: returns pada number 1-9 within the rashi (used only for raw degree display)
  int _degToNavamsha(double deg) {
    final inRashi = (deg % 360) % 30;
    return (inRashi / 3.333333333).floor() + 1;
  }

  void _updateStatus(String msg) {
    if (mounted) setState(() => _statusMessage = msg);
  }

  void _updateProgress(double p) {
    if (mounted) setState(() => _progress = p.clamp(0, 1));
  }

  String _t({required String kn, required String hi, required String ta, required String te, required String ml, required String en}) {
    switch (AppLocale.current) {
      case 'hi': return hi;
      case 'ta': return ta;
      case 'te': return te;
      case 'ml': return ml;
      case 'en': return en;
      default: return kn;
    }
  }
}
