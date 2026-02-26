import 'package:flutter/foundation.dart';

// Pure in-memory storage — zero native dependencies. Guarantees 100% successful compile.
class StorageService {
  static final Map<String, Profile> _cache = {};

  static Future<Map<String, Profile>> loadAll() async {
    return _cache;
  }

  static Future<void> save(Profile profile) async {
    _cache[profile.name] = profile;
  }

  static Future<void> delete(String name) async {
    _cache.remove(name);
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
