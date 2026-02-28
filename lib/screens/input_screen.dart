import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/common.dart';
import '../services/storage_service.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import 'dashboard_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});
  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _nameCtrl    = TextEditingController();
  final _placeCtrl   = TextEditingController(text: 'Yellapur');
  final _latCtrl     = TextEditingController(text: '14.9800');
  final _lonCtrl     = TextEditingController(text: '74.7300');

  DateTime _dob      = DateTime.now();
  int _hour          = DateTime.now().hour % 12 == 0 ? 12 : DateTime.now().hour % 12;
  int _minute        = DateTime.now().minute;
  String _ampm       = DateTime.now().hour < 12 ? 'AM' : 'PM';
  String _ayanamsa   = 'ಲಾಹಿರಿ';
  String _nodeMode   = 'ನಿಜ ರಾಹು';
  bool _loading      = false;
  bool _geoLoading   = false;
  String _geoStatus  = '';

  Map<String, Profile> _savedProfiles = {};
  String? _selName;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final p = await StorageService.loadAll();
    if (mounted) setState(() => _savedProfiles = p);
  }

  void _loadProfile(String name) {
    final p = _savedProfiles[name]!;
    setState(() {
      _nameCtrl.text  = name;
      _placeCtrl.text = p.place;
      _latCtrl.text   = p.lat.toStringAsFixed(4);
      _lonCtrl.text   = p.lon.toStringAsFixed(4);
      _hour   = p.hour;
      _minute = p.minute;
      _ampm   = p.ampm;
      final parts = p.date.split('-');
      _dob = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    });
  }

  Future<void> _geocode() async {
    if (_placeCtrl.text.trim().isEmpty) return;
    setState(() { _geoLoading = true; _geoStatus = ''; });
    try {
      final q = Uri.encodeComponent(_placeCtrl.text.trim());
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=1');
      final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          setState(() {
            _latCtrl.text = lat.toStringAsFixed(4);
            _lonCtrl.text = lon.toStringAsFixed(4);
            _geoStatus    = '📍 ${data[0]['display_name']}';
          });
        } else {
          setState(() => _geoStatus = 'ಸ್ಥಳ ಕಂಡುಬಂದಿಲ್ಲ.');
        }
      }
    } catch (_) {
      setState(() => _geoStatus = 'ಸ್ಥಳ ಸಂಪರ್ಕ ದೋಷ. ನೇರವಾಗಿ ಅಕ್ಷಾಂಶ/ರೇಖಾಂಶ ನಮೂದಿಸಿ.');
    }
    setState(() => _geoLoading = false);
  }

  Future<void> _calculate() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 50)); // let UI rebuild

    try {
      final lat = double.parse(_latCtrl.text);
      final lon = double.parse(_lonCtrl.text);

      int h24 = _hour + (_ampm == 'PM' && _hour != 12 ? 12 : 0);
      if (_ampm == 'AM' && _hour == 12) h24 = 0;
      final localHour = h24 + _minute / 60.0;

      final aynMode = _ayanamsa == 'ರಾಮನ್'
          ? 'raman' : _ayanamsa == 'ಕೆ.ಪಿ' ? 'kp' : 'lahiri';
      final trueNode = _nodeMode == 'ನಿಜ ರಾಹು';

      final result = await AstroCalculator.calculate(
        year: _dob.year, month: _dob.month, day: _dob.day,
        hourUtcOffset: 5.5,
        hour24: localHour,
        lat: lat, lon: lon,
        ayanamsaMode: aynMode,
        trueNode: trueNode,
      );

      if (result != null && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DashboardScreen(
            result: result,
            name: _nameCtrl.text,
            place: _placeCtrl.text,
            dob: _dob,
            hour: _hour,
            minute: _minute,
            ampm: _ampm,
            lat: lat,
            lon: lon,
            onSave: _saveProfile,
          ),
        ));
      } else {
        _showError('ಜಾತಕ ಲೆಕ್ಕಾಚಾರದಲ್ಲಿ ವಿಫಲ. ದಿನಾಂಕ/ಸಮಯ ಪರಿಶೀಲಿಸಿ.');
      }
    } catch (e) {
      _showError('ದೋಷ: $e');
    }
    setState(() => _loading = false);
  }

  void _saveProfile() async {
    String name = _nameCtrl.text.trim();
    if (name.isEmpty) name = 'Unknown_${_dob.toIso8601String().substring(0, 10)}';
    final p = Profile(
      name: name,
      date: '${_dob.year}-${_dob.month.toString().padLeft(2,'0')}-${_dob.day.toString().padLeft(2,'0')}',
      hour: _hour, minute: _minute, ampm: _ampm,
      lat: double.parse(_latCtrl.text),
      lon: double.parse(_lonCtrl.text),
      place: _placeCtrl.text,
    );
    await StorageService.save(p);
    await _loadProfiles();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppHeader(),
              _buildSavedCard(),
              _buildInputCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.folder_open, color: Colors.white),
        label: const Text('ಉಳಿಸಿದ ಜಾತಕ (Saved Profiles)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2B6CB0),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => _buildProfileListSheet(),
          );
        },
      ),
    );
  }

  Widget _buildProfileListSheet() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('ಉಳಿಸಿದ ಜಾತಕಗಳು (Saved Profiles)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2B6CB0))),
          ),
          if (_savedProfiles.isEmpty)
            const Padding(padding: EdgeInsets.all(32), child: Text('ಯಾವುದೇ ಜಾತಕ ಉಳಿಸಿಲ್ಲ.'))
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _savedProfiles.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final name = _savedProfiles.keys.elementAt(i);
                  return ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFEDF2F7), child: Icon(Icons.person, color: Color(0xFF2B6CB0))),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${_savedProfiles[name]!.date} | ${_savedProfiles[name]!.place}'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(ctx);
                      _loadProfile(name);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✨ ಹೊಸ ಜಾತಕ', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF2B6CB0))),
          const SizedBox(height: 16),

          // Name
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'ಹೆಸರು',
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),

          // Date picker
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today, color: kMuted),
                const SizedBox(width: 10),
                Text(
                  'ದಿನಾಂಕ: ${_dob.day.toString().padLeft(2,'0')}-${_dob.month.toString().padLeft(2,'0')}-${_dob.year}',
                  style: TextStyle(fontSize: 14, color: kText),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // Time
          Row(children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'ಗಂಟೆ (1-12)'),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n >= 1 && n <= 12) setState(() => _hour = n);
                },
                controller: TextEditingController(text: _hour.toString())..selection = TextSelection.collapsed(offset: _hour.toString().length),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'ನಿಮಿಷ (0-59)'),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n >= 0 && n <= 59) setState(() => _minute = n);
                },
                controller: TextEditingController(text: _minute.toString().padLeft(2,'0')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _ampm,
                items: ['AM','PM'].map((v) => DropdownMenuItem(
                  value: v, child: Text(v, style: TextStyle(fontWeight: FontWeight.w700)))).toList(),
                onChanged: (v) => setState(() => _ampm = v!),
                decoration: const InputDecoration(labelText: 'ಬೆಳಿಗ್ಗೆ/ಸಂಜೆ'),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // Place search
          Row(children: [
            Expanded(
              child: TextField(
                controller: _placeCtrl,
                decoration: const InputDecoration(labelText: 'ಊರು ಹುಡುಕಿ', prefixIcon: Icon(Icons.search)),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _geoLoading ? null : _geocode,
              style: ElevatedButton.styleFrom(
                backgroundColor: kTeal,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14)),
              child: _geoLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('ಹುಡುಕಿ', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
          if (_geoStatus.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_geoStatus, style: TextStyle(fontSize: 12, color: kGreen)),
          ],
          const SizedBox(height: 14),

          // Lat/Lon
          Row(children: [
            Expanded(
              child: TextField(
                controller: _latCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'ಅಕ್ಷಾಂಶ'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _lonCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'ರೇಖಾಂಶ'),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // Advanced options
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text('⚙️ ಸುಧಾರಿತ ಆಯ್ಕೆಗಳು', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              children: [
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _ayanamsa,
                      decoration: const InputDecoration(labelText: 'ಅಯನಾಂಶ'),
                      items: ['ಲಾಹಿರಿ','ರಾಮನ್','ಕೆ.ಪಿ'].map((v) => DropdownMenuItem(
                        value: v, child: Text(v, style: const TextStyle()))).toList(),
                      onChanged: (v) => setState(() => _ayanamsa = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _nodeMode,
                      decoration: const InputDecoration(labelText: 'ರಾಹು'),
                      items: ['ನಿಜ ರಾಹು','ಸರಾಸರಿ ರಾಹು'].map((v) => DropdownMenuItem(
                        value: v, child: Text(v, style: const TextStyle()))).toList(),
                      onChanged: (v) => setState(() => _nodeMode = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Calculate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _calculate,
              child: _loading
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text('ಲೆಕ್ಕಾಚಾರ ಮಾಡುತ್ತಿದೆ...', style: TextStyle(fontWeight: FontWeight.w800)),
                    ])
                  : Text('ಜಾತಕ ರಚಿಸಿ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1800),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: kPurple2),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }
}
