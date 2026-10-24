import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'panchanga_cache.dart';

/// Downloads pre-computed panchanga .bdat files from cloud storage.
///
/// Storage structure (remote):
///   panchanga/
///     bharatheeyam_panchanga_Bengaluru.bdat
///     bharatheeyam_panchanga_Mysuru.bdat
///     ...
///     manifest.json   ← list of available cities
class PanchangaDownloadService {
  // Base URL for raw file downloads (no branding exposed to UI)
  static const String _baseUrl =
      'https://raw.githubusercontent.com/goureesha/bharatheeyamapp/main/tools/output';

  /// Cached city list
  static List<PanchangaCityInfo>? _cities;

  /// Fetch the list of available cities from manifest.json.
  static Future<List<PanchangaCityInfo>> fetchAvailableCities() async {
    if (_cities != null) return _cities!;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/manifest.json'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('PanchangaDownload: manifest fetch failed: ${response.statusCode}');
        return [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final cities = (json['cities'] as List<dynamic>).map((c) {
        final m = c as Map<String, dynamic>;
        return PanchangaCityInfo(
          name: m['name'] as String,
          nameKn: m['nameKn'] as String? ?? m['name'] as String,
          fileName: m['fileName'] as String,
          sizeKB: (m['sizeKB'] as num?)?.toInt() ?? 270,
          fromYear: m['fromYear'] as int? ?? 2025,
          toYear: m['toYear'] as int? ?? 2045,
        );
      }).toList();

      _cities = cities;
      return cities;
    } catch (e) {
      debugPrint('PanchangaDownload: Failed to fetch manifest: $e');
      return [];
    }
  }

  /// Download a .bdat file and import it into PanchangaCache.
  /// Returns null on success, error message on failure.
  /// [onProgress] is called with 0.0–1.0 progress.
  static Future<String?> downloadAndImport(
    PanchangaCityInfo city, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final url = '$_baseUrl/${city.fileName}';
      final request = http.Request('GET', Uri.parse(url));
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));

      if (streamedResponse.statusCode != 200) {
        return 'ಡೌನ್‌ಲೋಡ್ ವಿಫಲ (${streamedResponse.statusCode})';
      }

      // Download with progress tracking
      final totalBytes = streamedResponse.contentLength ?? (city.sizeKB * 1024);
      final List<int> receivedBytes = [];
      int downloaded = 0;

      await for (final chunk in streamedResponse.stream) {
        receivedBytes.addAll(chunk);
        downloaded += chunk.length;
        if (totalBytes > 0) {
          onProgress?.call(downloaded / totalBytes);
        }
      }
      onProgress?.call(1.0);

      // Write to temp file
      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/${city.fileName}');
      await tempFile.writeAsBytes(receivedBytes);

      // Import into PanchangaCache
      final cache = PanchangaCache.instance;
      final err = await cache.importFromPath(tempFile.path);

      // Clean up temp file
      try { await tempFile.delete(); } catch (_) {}

      return err; // null = success
    } catch (e) {
      debugPrint('PanchangaDownload: Download failed: $e');
      return 'ಡೌನ್‌ಲೋಡ್ ವಿಫಲ: $e';
    }
  }

  /// Clear cached city list (e.g., on refresh)
  static void clearCache() => _cities = null;
}

/// Metadata for an available panchanga city file
class PanchangaCityInfo {
  final String name;      // English name (e.g., "Bengaluru")
  final String nameKn;    // Kannada name (e.g., "ಬೆಂಗಳೂರು")
  final String fileName;  // File name in storage
  final int sizeKB;       // Approx size in KB
  final int fromYear;     // Data start year
  final int toYear;       // Data end year

  const PanchangaCityInfo({
    required this.name,
    required this.nameKn,
    required this.fileName,
    this.sizeKB = 270,
    this.fromYear = 2025,
    this.toYear = 2045,
  });
}
