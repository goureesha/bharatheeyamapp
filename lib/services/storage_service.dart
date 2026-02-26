import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

// Pure dart:io storage — no path_provider, no native dependency
class StorageService {
  static File? _file;

  static Future<File> _getFile() async {
    if (_file != null) return _file!;
    // Use app's temp directory which is always available without path_provider
    final dir = Directory.systemTemp;
    _file = File(p.join(dir.path, 'bharatheeyam_db.json'));
    return _file!;
  }

  static Future<Map<String, Profile>> loadAll() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return {};
      final raw = await file.readAsString();
      final Map<String, dynamic> decoded = jsonDecode(raw);
      return decoded.map((k, v) => MapEntry(k, Profile.fromJson(k, v)));
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(Profile profile) async {
    try {
      final file = await _getFile();
      final Map<String, dynamic> db = {};
      if (await file.exists()) {
        final raw = await file.readAsString();
        db.addAll(jsonDecode(raw));
      }
      db[profile.name] = profile.toJson();
      await file.writeAsString(jsonEncode(db));
    } catch (_) {}
  }

  static Future<void> delete(String name) async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return;
      final Map<String, dynamic> db = jsonDecode(await file.readAsString());
      db.remove(name);
      await file.writeAsString(jsonEncode(db));
    } catch (_) {}
  }
}

class Profile {
  final String name;
  final String date;
  final int hour;
  final int minute;
  final String ampm;
  final double lat;
  final double lon;
  final String place;

  Profile({
    required this.name,
    required this.date,
    required this.hour,
    required this.minute,
    required this.ampm,
    required this.lat,
    required this.lon,
    required this.place,
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'd': date, 'h': hour, 'm': minute,
    'ampm': ampm, 'lat': lat, 'lon': lon, 'p': place,
  };

  factory Profile.fromJson(String name, Map<String, dynamic> j) => Profile(
    name: name,
    date: j['d'] ?? '',
    hour: j['h'] ?? 12,
    minute: j['m'] ?? 0,
    ampm: j['ampm'] ?? 'AM',
    lat: (j['lat'] ?? 14.98).toDouble(),
    lon: (j['lon'] ?? 74.73).toDouble(),
    place: j['p'] ?? '',
  );
}
