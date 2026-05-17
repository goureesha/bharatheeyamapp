import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NetworkService {
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
}
