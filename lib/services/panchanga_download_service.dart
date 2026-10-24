import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'panchanga_cache.dart';

/// Downloads pre-computed panchanga .bdat files from Firebase Storage.
///
/// Firebase Storage structure:
///   panchanga/
///     bharatheeyam_panchanga_Bengaluru.bdat
///     bharatheeyam_panchanga_Mysuru.bdat
///     ...
///     manifest.json   ← list of available cities
class PanchangaDownloadService {
  static const String _storagePath = 'panchanga';
  static const String _manifestFile = 'manifest.json';

  /// Cached city list
  static List<PanchangaCityInfo>? _cities;

  /// Fetch the list of available cities from Firebase Storage manifest.
  /// The manifest.json file contains city metadata.
  static Future<List<PanchangaCityInfo>> fetchAvailableCities() async {
    if (_cities != null) return _cities!;

    try {
      final ref = FirebaseStorage.instance.ref('$_storagePath/$_manifestFile');
      final data = await ref.getData(1024 * 1024); // max 1MB
      if (data == null) return [];

      final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
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
      // Fallback: list files directly from storage
      return _fetchCitiesFromStorage();
    }
  }

  /// Fallback: list .bdat files directly from Firebase Storage folder
  static Future<List<PanchangaCityInfo>> _fetchCitiesFromStorage() async {
    try {
      final ref = FirebaseStorage.instance.ref(_storagePath);
      final result = await ref.listAll();

      final cities = <PanchangaCityInfo>[];
      for (final item in result.items) {
        if (!item.name.endsWith('.bdat')) continue;
        // Extract city name from filename: bharatheeyam_panchanga_Bengaluru.bdat → Bengaluru
        final match = RegExp(r'bharatheeyam_panchanga_(.+)\.bdat').firstMatch(item.name);
        if (match == null) continue;
        final cityName = match.group(1)!;
        cities.add(PanchangaCityInfo(
          name: cityName,
          nameKn: cityName,
          fileName: item.name,
        ));
      }
      cities.sort((a, b) => a.name.compareTo(b.name));
      _cities = cities;
      return cities;
    } catch (e) {
      debugPrint('PanchangaDownload: Failed to list storage: $e');
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
      final ref = FirebaseStorage.instance.ref('$_storagePath/${city.fileName}');

      // Download to temp file
      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/${city.fileName}');

      final downloadTask = ref.writeToFile(tempFile);

      // Track progress
      downloadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          final progress = event.bytesTransferred / event.totalBytes;
          onProgress?.call(progress);
        }
      });

      await downloadTask;
      onProgress?.call(1.0);

      // Import into PanchangaCache
      final cache = PanchangaCache.instance;
      final err = await cache.importFromPath(tempFile.path);

      // Clean up temp file
      try { await tempFile.delete(); } catch (_) {}

      return err; // null = success
    } catch (e) {
      debugPrint('PanchangaDownload: Download failed: $e');
      if (e is FirebaseException) {
        if (e.code == 'object-not-found') {
          return 'ಈ ನಗರದ ಫೈಲ್ ಲಭ್ಯವಿಲ್ಲ'; // File not available for this city
        }
        return 'ಡೌನ್‌ಲೋಡ್ ವಿಫಲ: ${e.message}';
      }
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
