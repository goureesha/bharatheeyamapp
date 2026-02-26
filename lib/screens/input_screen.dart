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
  String _ayanamsa   = 'à²²à²¾à²¹à²¿à²°à²¿';
  String _nodeMode   = 'à²¨à²¿à²œ à²°à²¾à²¹à³';
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
            _geoStatus    = 'ðŸ“ ${data[0]['display_name']}';
          });
        } else {
          setState(() => _geoStatus = 'à²¸à³à²¥à²³ à²•à²‚à²¡à³à²¬à²‚à²¦à²¿à²²à³à²².');
        }
      }
    } catch (_) {
      setState(() => _geoStatus = 'à²¸à³à²¥à²³ à²¸à²‚à²ªà²°à³à²• à²¦à³‹à²·. à²¨à³‡à²°à²µà²¾à²—à²¿ à²…à²•à³à²·à²¾à²‚à²¶/à²°à³‡à²–à²¾à²‚à²¶ à²¨à²®à³‚à²¦à²¿à²¸à²¿.');
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

      final aynMode = _ayanamsa == 'à²°à²¾à²®à²¨à³'
          ? 'raman' : _ayanamsa == 'à²•à³†.à²ªà²¿' ? 'kp' : 'lahiri';
      final trueNode = _nodeMode == 'à²¨à²¿à²œ à²°à²¾à²¹à³';

      final result = await Future.microtask(() => AstroCalculator.calculate(
        year: _dob.year, month: _dob.month, day: _dob.day,
        hourUtcOffset: 5.5,
        hour24: localHour,
        lat: lat, lon: lon,
        ayanamsaMode: aynMode,
        trueNode: trueNode,
      ));

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
        _showError('à²œà²¾à²¤à²• à²²à³†à²•à³à²•à²¾à²šà²¾à²°à²¦à²²à³à²²à²¿ à²µà²¿à²«à²². à²¦à²¿à²¨à²¾à²‚à²•/à²¸à²®à²¯ à²ªà²°à²¿à²¶à³€à²²à²¿à²¸à²¿.');
      }
    } catch (e) {
      _showError('à²¦à³‹à²·: $e');
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
              if (_savedProfiles.isNotEmpty) _buildSavedCard(),
              _buildInputCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ðŸ“‚ à²‰à²³à²¿à²¸à²¿à²¦ à²œà²¾à²¤à²•', style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    )),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selName,
                hint: Text('à²†à²¯à³à²•à³†à²®à²¾à²¡à²¿', style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ),
                items: _savedProfiles.keys.map((n) => DropdownMenuItem(
                  value: n,
                  child: Text(n, style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ),
                )).toList(),
                onChanged: (v) => setState(() => _selName = v),
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _selName == null ? null : () => _loadProfile(_selName!),
              style: ElevatedButton.styleFrom(
                backgroundColor: kTeal,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14)),
              child: Text('à²¤à³†à²—à³†à²¯à²¿à²°à²¿', style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('âœ¨ à²¹à³Šà²¸ à²œà²¾à²¤à²•', style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    )),
          const SizedBox(height: 16),

          // Name
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'à²¹à³†à²¸à²°à³',
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
                  'à²¦à²¿à²¨à²¾à²‚à²•: ${_dob.day.toString().padLeft(2,'0')}-${_dob.month.toString().padLeft(2,'0')}-${_dob.year}',
                  style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ,
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
                decoration: const InputDecoration(labelText: 'à²—à²‚à²Ÿà³† (1-12)'),
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
                decoration: const InputDecoration(labelText: 'à²¨à²¿à²®à²¿à²· (0-59)'),
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
                  value: v, child: Text(v, style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ))).toList(),
                onChanged: (v) => setState(() => _ampm = v!),
                decoration: const InputDecoration(labelText: 'à²¬à³†à²³à²¿à²—à³à²—à³†/à²¸à²‚à²œà³†'),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // Place search
          Row(children: [
            Expanded(
              child: TextField(
                controller: _placeCtrl,
                decoration: const InputDecoration(labelText: 'à²Šà²°à³ à²¹à³à²¡à³à²•à²¿', prefixIcon: Icon(Icons.search)),
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
                  : Text('à²¹à³à²¡à³à²•à²¿', style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ),
            ),
          ]),
          if (_geoStatus.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_geoStatus, style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ),
          ],
          const SizedBox(height: 14),

          // Lat/Lon
          Row(children: [
            Expanded(
              child: TextField(
                controller: _latCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'à²…à²•à³à²·à²¾à²‚à²¶'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _lonCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'à²°à³‡à²–à²¾à²‚à²¶'),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // Advanced options
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text('âš™ï¸ à²¸à³à²§à²¾à²°à²¿à²¤ à²†à²¯à³à²•à³†à²—à²³à³', style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ),
              children: [
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _ayanamsa,
                      decoration: const InputDecoration(labelText: 'à²…à²¯à²¨à²¾à²‚à²¶'),
                      items: ['à²²à²¾à²¹à²¿à²°à²¿','à²°à²¾à²®à²¨à³','à²•à³†.à²ªà²¿'].map((v) => DropdownMenuItem(
                        value: v, child: Text(v, style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ))).toList(),
                      onChanged: (v) => setState(() => _ayanamsa = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _nodeMode,
                      decoration: const InputDecoration(labelText: 'à²°à²¾à²¹à³'),
                      items: ['à²¨à²¿à²œ à²°à²¾à²¹à³','à²¸à²°à²¾à²¸à²°à²¿ à²°à²¾à²¹à³'].map((v) => DropdownMenuItem(
                        value: v, child: Text(v, style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ))).toList(),
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
                      Text('à²²à³†à²•à³à²•à²¾à²šà²¾à²° à²®à²¾à²¡à³à²¤à³à²¤à²¿à²¦à³†...', style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ),
                    ])
                  : Text('à²œà²¾à²¤à²• à²°à²šà²¿à²¸à²¿', style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ),
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
