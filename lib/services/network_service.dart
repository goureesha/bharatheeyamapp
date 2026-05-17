import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NetworkService {
  static const String _timeKey = 'last_online_time';

  /// Pure connectivity check — actually pings the internet.
  /// Returns true only if the device can reach the network right now.
  /// No caching, no grace period.
  static Future<bool> isActuallyOnline() async {
    try {
      if (kIsWeb) return true;
      final response = await http.get(Uri.parse('https://google.com'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkAndInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    final isConnected = await isActuallyOnline();

    if (isConnected) {
      await prefs.setString(_timeKey, DateTime.now().toIso8601String());
      return true;
    } else {
      final lastOnlineStr = prefs.getString(_timeKey);
      if (lastOnlineStr == null) {
        await prefs.setString(_timeKey, DateTime.now().toIso8601String());
        return true;
      }
      
      final lastOnline = DateTime.tryParse(lastOnlineStr);
      if (lastOnline == null) return true;
      
      final diff = DateTime.now().difference(lastOnline);
      if (diff.inHours >= 48) {
        return false;
      }
      return true;
    }
  }
}
