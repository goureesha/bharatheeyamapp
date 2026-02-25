import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Profile {
  final String name;
  final String date;   // yyyy-MM-dd
  final int hour;      // 12h
  final int minute;
  final String ampm;   // 'AM'/'PM'
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
    'name': name,
    'd': date,
    'h': hour,
    'm': minute,
    'ampm': ampm,
    'lat': lat,
    'lon': lon,
    'p': place,
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

class StorageService {
  static const _key = 'kundli_db_v1';

  static Future<Map<String, Profile>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(raw);
    return decoded.map((k, v) => MapEntry(k, Profile.fromJson(k, v)));
  }

  static Future<void> save(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final Map<String, dynamic> db = raw == null ? {} : jsonDecode(raw);
    db[profile.name] = profile.toJson();
    await prefs.setString(_key, jsonEncode(db));
  }

  static Future<void> delete(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final Map<String, dynamic> db = jsonDecode(raw);
    db.remove(name);
    await prefs.setString(_key, jsonEncode(db));
  }
}
