import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ─────────────────────────────────────────────
// Shared app-wide decorators / constants
// ─────────────────────────────────────────────

class AppThemes {
  static final ValueNotifier<int> themeNotifier = ValueNotifier(0);

  static const List<Map<String, Color>> palettes = [
    { // Standard Light
      'purple1': Color(0xFF8E2DE2),
      'purple2': Color(0xFF4A00E0),
      'bg': Color(0xFFFFFDF7),
      'card': Color(0xFFFFFFFF),
      'text': Color(0xFF2D3748),
      'border': Color(0xFFE2E8F0),
      'muted': Color(0xFF718096),
    },
    { // Dark Night
      'purple1': Color(0xFF9F7AEA),
      'purple2': Color(0xFF805AD5),
      'bg': Color(0xFF1A202C),
      'card': Color(0xFF2D3748),
      'text': Color(0xFFF7FAFC),
      'border': Color(0xFF4A5568),
      'muted': Color(0xFFA0AEC0),
    },
    { // Golden Sepia
      'purple1': Color(0xFFDD6B20),
      'purple2': Color(0xFFC05621),
      'bg': Color(0xFFFFFBEB),
      'card': Color(0xFFFFFFFF),
      'text': Color(0xFF451A03),
      'border': Color(0xFFFCD34D),
      'muted': Color(0xFF92400E),
    },
    { // Royal Ocean
      'purple1': Color(0xFF2563EB),
      'purple2': Color(0xFF1D4ED8),
      'bg': Color(0xFFF0F9FF),
      'card': Color(0xFFFFFFFF),
      'text': Color(0xFF0F172A),
      'border': Color(0xFFBAE6FD),
      'muted': Color(0xFF475569),
    },
    { // Emerald Forest
      'purple1': Color(0xFF059669),
      'purple2': Color(0xFF047857),
      'bg': Color(0xFFF0FDF4),
      'card': Color(0xFFFFFFFF),
      'text': Color(0xFF064E3B),
      'border': Color(0xFFBBF7D0),
      'muted': Color(0xFF166534),
    }
  ];

  static void setTheme(int i) {
    if (i < 0 || i >= palettes.length) return;
    final p = palettes[i];
    kPurple1 = p['purple1']!;
    kPurple2 = p['purple2']!;
    kBg = p['bg']!;
    kCard = p['card']!;
    kText = p['text']!;
    kBorder = p['border']!;
    kMuted = p['muted']!;
    themeNotifier.value = i;
    // Persist theme choice
    SharedPreferences.getInstance().then((prefs) => prefs.setInt('app_theme', i));
  }

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('app_theme') ?? 0;
    setTheme(idx);
  }
}

// ─────────────────────────────────────────────
// Kundali chart style (South / North Indian)
// ─────────────────────────────────────────────
class ChartStyle {
  static final ValueNotifier<String> styleNotifier = ValueNotifier('south');

  static String get current => styleNotifier.value;
  static bool get isNorth => styleNotifier.value == 'north';

  static void setStyle(String style) {
    if (style != 'south' && style != 'north') return;
    styleNotifier.value = style;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('chart_style', style));
  }

  static Future<void> loadStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('chart_style') ?? 'south';
    styleNotifier.value = s;
  }
}

// ─────────────────────────────────────────────
// App Language / Locale (5 languages)
// ─────────────────────────────────────────────
class AppLocale {
  static final ValueNotifier<String> langNotifier = ValueNotifier('kn');
  static String get current => langNotifier.value;
  static bool get isHindi => current == 'hi';

  static void setLang(String lang) {
    if (!['kn', 'hi', 'ta', 'te', 'ml'].contains(lang)) return;
    langNotifier.value = lang;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('app_lang', lang));
  }

  static Future<void> loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    langNotifier.value = prefs.getString('app_lang') ?? 'kn';
  }

  /// Get localized string by key — falls back to Kannada then key
  static String l(String key) {
    final langStrings = _allStrings[current];
    if (langStrings != null && langStrings.containsKey(key)) return langStrings[key]!;
    final knFallback = _allStrings['kn'];
    if (knFallback != null && knFallback.containsKey(key)) return knFallback[key]!;
    return key;
  }

  static const Map<String, Map<String, String>> _allStrings = {
    'kn': {
      'appName': 'ಭಾರತೀಯಮ್', 'home': 'ಮನೆ', 'kundali': 'ಕುಂಡಲಿ', 'panchanga': 'ಪಂಚಾಂಗ',
      'planets': 'ಗ್ರಹಗಳು', 'appointment': 'ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್', 'vedicClock': 'ವೈದಿಕ ಗಡಿಯಾರ',
      'settings': 'ಸೆಟ್ಟಿಂಗ್ಸ್', 'aboutUs': 'ನಮ್ಮ ಬಗ್ಗೆ', 'language': 'ಭಾಷೆ / Language',
      'name': 'ಹೆಸರು', 'dob': 'ಜನ್ಮ ದಿನಾಂಕ', 'time': 'ಜನ್ಮ ಸಮಯ', 'place': 'ಜನ್ಮ ಸ್ಥಳ',
      'calculate': 'ಲೆಕ್ಕ ಹಾಕಿ', 'selectDate': 'ದಿನಾಂಕ ಆಯ್ಕೆ', 'selectTime': 'ಸಮಯ ಆಯ್ಕೆ',
      'save': 'ಉಳಿಸಿ', 'delete': 'ಅಳಿಸಿ', 'cancel': 'ರದ್ದು', 'confirm': 'ದೃಢಪಡಿಸಿ',
      'share': 'ಹಂಚಿಕೊಳ್ಳಿ', 'yes': 'ಹೌದು', 'no': 'ಇಲ್ಲ',
      'chart': 'ಕುಂಡಲಿ', 'sphuta': 'ಸ್ಫುಟ', 'bhava': 'ಭಾವ', 'varga': 'ವರ್ಗ',
      'dasha': 'ದಶಾ', 'aroodha': 'ಆರೂಢ', 'ashtakavarga': 'ಅಷ್ಟಕವರ್ಗ',
      'taranukoola': 'ತಾರಾನುಕೂಲ', 'matchMaking': 'ಗುಣ ಮಿಲನ', 'notes': 'ಟಿಪ್ಪಣಿ',
      'ashtamangala': 'ಅಷ್ಟಮಂಗಲ',
      'sunrise': 'ಸೂರ್ಯೋದಯ', 'sunset': 'ಸೂರ್ಯಾಸ್ತ', 'searchPlace': 'ಊರು ಹುಡುಕಿ',
      'noResults': 'ಯಾವುದೇ ಫಲಿತಾಂಶ ಕಂಡುಬಂದಿಲ್ಲ.', 'deleteConfirm': 'ಅಳಿಸಬೇಕೇ?',
      'deleteMsg': 'ಜಾತಕವನ್ನು ಅಳಿಸಬೇಕೇ?', 'noBtn': 'ಬೇಡ', 'errorLabel': 'ದೋಷ',
      'retryBtn': 'ಪುನಃಪ್ರಯತ್ನಿಸಿ', 'placeNotFound': 'ಸ್ಥಳ ಕಂಡುಬಂದಿಲ್ಲ.',
      'networkError': 'ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕ ಪರೀಕ್ಷಿಸಿ.', 'unknown': 'ಅಪರಿಚಿತ (Unknown)',
      'savedKundali': 'ಉಳಿಸಿದ ಕುಂಡಲಿ', 'searchHint': 'ಹೆಸರು, ಸ್ಥಳ, ID ಹುಡುಕಿ...',
      'noSavedKundali': 'ಯಾವುದೇ ಜಾತಕ ಉಳಿಸಿಲ್ಲ.', 'openSaved': 'ತೆರೆಯಿರಿ',
      'advancedSettings': 'ಈ ಆಯ್ಕೆಗಳು ಬದಲಾಯಿಸಬೇಡಿ', 'webBlockedTitle': 'ಇಂಟರ್ನೆಟ್ ಅಗತ್ಯ',
      'selectPlace': 'ಸ್ಥಳ ಆಯ್ಕೆಮಾಡಿ', 'multiPlacesFound': 'ಹಲವು ಸ್ಥಳಗಳು ಕಂಡುಬಂದಿವೆ:',
      'lat': 'ಅಕ್ಷಾಂಶ', 'lon': 'ರೇಖಾಂಶ', 'tzOffset': 'TZ',
      'tithi': 'ತಿಥಿ', 'vara': 'ವಾರ', 'nakshatra': 'ನಕ್ಷತ್ರ', 'yoga': 'ಯೋಗ', 'karana': 'ಕರಣ',
      'chandraNak': 'ಚಂದ್ರ ನಕ್ಷತ್ರ', 'suryaNak': 'ಸೂರ್ಯ ನಕ್ಷತ್ರ', 'pada': 'ಪಾದ',
      'chandraRashi': 'ಚಂದ್ರ ರಾಶಿ', 'chandraMasa': 'ಚಂದ್ರ ಮಾಸ',
      'souraMasa': 'ಸೌರ ಮಾಸ', 'souraMasaGataDina': 'ಸೌರ ಮಾಸ ಗತ ದಿನ',
      'samvatsara': 'ಸಂವತ್ಸರ', 'ayana': 'ಅಯನ', 'rutu': 'ಋತು',
      'divamana': 'ಹಗಲಿನ ಪ್ರಮಾಣ', 'ratrimana': 'ರಾತ್ರಿಯ ಪ್ರಮಾಣ',
      'rahuKala': 'ರಾಹು ಕಾಲ', 'gulikaKala': 'ಗುಳಿಕ ಕಾಲ', 'yamaKala': 'ಯಮಗಂಡ ಕಾಲ',
      'surya': 'ಸೂರ್ಯ', 'chandra': 'ಚಂದ್ರ', 'kala': 'ಕಾಲ',
      'selectDateLabel': 'ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ', 'today': 'ಇಂದು', 'sthala': 'ಸ್ಥಳ', 'dinanka': 'ದಿನಾಂಕ',
      'paramaGhati': 'ಪರಮ ಘಟಿ', 'vishaPraghati': 'ವಿಷ ಪ್ರಘಟಿ', 'amrutaPraghati': 'ಅಮೃತ ಪ್ರಘಟಿ',
      'mars': 'ಮಂಗಳ', 'mercury': 'ಬುಧ', 'jupiter': 'ಗುರು', 'venus': 'ಶುಕ್ರ', 'saturn': 'ಶನಿ', 'rahu': 'ರಾಹು', 'ketu': 'ಕೇತು',
      'all': 'ಎಲ್ಲಾ', 'start': 'ಪ್ರಾರಂಭ', 'end': 'ಅಂತ್ಯ', 'continues': 'ಮುಂದಿನ ವರ್ಷದವರೆಗೆ',
      'transits': 'ಸಂಚಾರ', 'vakri': 'ವಕ್ರಿ', 'asta': 'ಅಸ್ತ',
      'ghati': 'ಘಟಿ', 'vighati': 'ವಿಘಟಿ', 'anuVighati': 'ಅನುವಿಘಟಿ',
      'ghatiLabel': 'ಘಟಿ    ವಿಘಟಿ   ಅನುವಿಘಟಿ',
      'udaya': 'ಉದಯ',
      'ayanamsa': 'ಅಯನಾಂಶ', 'nodeType': 'ರಾಹು ವಿಧ',
      'selectAllDetails': 'ದಯವಿಟ್ಟು ಎಲ್ಲಾ ವಿವರಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ', 'selectHint': 'ಆಯ್ಕೆಮಾಡಿ',
      'matchPoor': 'ಹೊಂದಾಣಿಕೆ ಉತ್ತಮವಾಗಿಲ್ಲ', 'matchMedium': 'ಹೊಂದಾಣಿಕೆ ಮಧ್ಯಮವಾಗಿದೆ', 'matchGood': 'ಹೊಂದಾಣಿಕೆ ತುಂಬಾ ಉತ್ತಮವಾಗಿದೆ',
      'matchResult': 'ಅಷ್ಟಕೂಟ ಗುಣ ಮಿಲನ ಫಲಿತಾಂಶ', 'totalGuna': 'ಒಟ್ಟು ಗುಣ', 'result': 'ಫಲಿತಾಂಶ',
      'brideDetails': 'ವಧುವಿನ ವಿವರಗಳು', 'groomDetails': 'ವರನ ವಿವರಗಳು', 'checkMatch': 'ಹೊಂದಾಣಿಕೆ ಪರೀಕ್ಷಿಸಿ',
      'referenceShloka': 'ಆಧಾರ ಶ್ಲೋಕ:', 'rule': 'ನಿಯಮ:', 'source': 'ಆಕರ: ',
      'themeSettings': 'ಥೀಮ್ ಸೆಟ್ಟಿಂಗ್ಸ್', 'defaultLocation': 'ಡೀಫಾಲ್ಟ್ ಸ್ಥಳ',
      'locationHint': 'ಪಂಚಾಂಗ ಮತ್ತು ವೈದಿಕ ಗಡಿಯಾರ ಲೆಕ್ಕಾಚಾರಕ್ಕೆ ಬಳಸಲಾಗುತ್ತದೆ',
      'themeLight': 'ಸ್ಟ್ಯಾಂಡರ್ಡ್ ಲೈಟ್', 'themeDark': 'ಡಾರ್ಕ್ ಮೋಡ್', 'themeGold': 'ಸ್ವರ್ಣ', 'themeOcean': 'ಸಾಗರ', 'themeGreen': 'ಹಸಿರು',
      'chartStyle': 'ಕುಂಡಲಿ ಶೈಲಿ', 'southIndian': 'ದಕ್ಷಿಣ ಭಾರತ', 'northIndian': 'ಉತ್ತರ ಭಾರತ',
      'southDesc': '4×4 ಗ್ರಿಡ್ - ರಾಶಿ ಸ್ಥಿರ, ಗ್ರಹಗಳು ಚಲಿಸುವವು', 'northDesc': 'ವಜ್ರ (Diamond) - ಭಾವ ಸ್ಥಿರ, ರಾಶಿಗಳು ಚಲಿಸುವವು',
      'searchLocation': 'ಸ್ಥಳ ಹುಡುಕಿ', 'onlineSearch': 'ಆನ್‌ಲೈನ್ ಹುಡುಕಿ', 'defaultLocationSet': 'ಡೀಫಾಲ್ಟ್ ಸ್ಥಳ',
      'googleSyncActive': 'Google ಸಿಂಕ್ ಸಕ್ರಿಯವಾಗಿದೆ', 'signInForCloud': 'ಕ್ಲೌಡ್ ಬ್ಯಾಕಪ್‌ಗಾಗಿ Google ಗೆ ಸೈನ್ ಇನ್ ಮಾಡಿ',
      'signInSuccess': 'Google Sign In ಯಶಸ್ವಿ!', 'signInFailed': 'Sign In ವಿಫಲ',
      'migrateDevice': 'ಸಾಧನ ಬದಲಾಯಿಸಿ', 'migrateConfirm': 'ಸಾಧನ ಬದಲಾಯಿಸಿ?',
      'migrateMsg': 'ಈ ಸಾಧನವನ್ನು ನಿಮ್ಮ ಪ್ರಾಥಮಿಕ ಸಾಧನವಾಗಿ ಹೊಂದಿಸಲಾಗುವುದು. ಬೇರೆ ಸಾಧನದಲ್ಲಿ ಈ ಖಾತೆ ಬ್ಲಾಕ್ ಆಗುತ್ತದೆ.',
      'yesChange': 'ಹೌದು, ಬದಲಾಯಿಸಿ', 'migrateSuccess': 'ಸಾಧನ ಯಶಸ್ವಿಯಾಗಿ ಬದಲಾಯಿಸಲಾಗಿದೆ!', 'failed': 'ವಿಫಲವಾಗಿದೆ',
      'backupRestore': 'ಡೇಟಾ ಬ್ಯಾಕಪ್ ಮತ್ತು ಮರುಸ್ಥಾಪನೆ', 'backupDesc': 'ನಿಮ್ಮ ಎಲ್ಲಾ ನಿಯತಕಾಲಿಕ ಡೇಟಾವನ್ನು ಬ್ಯಾಕಪ್ ಮಾಡಿ ಮತ್ತು ಹೊಸ ಸಾಧನಕ್ಕೆ ಮರುಸ್ಥಾಪಿಸಿ.',
      'exportBackup': 'ಬ್ಯಾಕಪ್ ರಫ್ತು ಮಾಡಿ', 'importBackup': 'ಬ್ಯಾಕಪ್ ಆಮದು ಮಾಡಿ',
      'exportChoose': 'ಬ್ಯಾಕಪ್ ಫೈಲ್ ಅನ್ನು ಉಳಿಸಲು ಅಪ್ಲಿಕೇಶನ್ ಆಯ್ಕೆಮಾಡಿ.', 'restoreSuccess': 'ಡೇಟಾ ಯಶಸ್ವಿಯಾಗಿ ಮರುಸ್ಥಾಪನೆಯಾಗಿದೆ!',
      'humanReadable': 'ಮಾನವ ಓದಬಲ್ಲ ಸ್ಪ್ರೆಡ್‌ಶೀಟ್‌ಗಳು', 'exportSpreadsheet': 'ಸ್ಪ್ರೆಡ್‌ಶೀಟ್ ಮತ್ತು ಟಿಪ್ಪಣಿಗಳನ್ನು ರಫ್ತು ಮಾಡಿ',
      'spreadsheetExported': 'ಸ್ಪ್ರೆಡ್‌ಶೀಟ್ ಮತ್ತು ಟಿಪ್ಪಣಿಗಳನ್ನು ರಫ್ತು ಮಾಡಲಾಗಿದೆ!', 'exportFailed': 'ರಫ್ತು ವಿಫಲವಾಗಿದೆ',
      'cloudBackup': 'Google Drive ಬ್ಯಾಕಪ್', 'premiumSub': 'ಪ್ರೀಮಿಯಂ ಚಂದಾದಾರಿಕೆ',
      'taraResults': 'ತಾರಾನುಕೂಲ ಫಲಿತಾಂಶಗಳು',
      'onePerson': '೧ ವ್ಯಕ್ತಿ', 'twoPersons': '೨ ವ್ಯಕ್ತಿಗಳು',
      'excludeBadNak': 'ಅಶುಭ ನಕ್ಷತ್ರ ಹೊರಗಿಡಿ', 'selectNakHint': 'ಜನ್ಮ ನಕ್ಷತ್ರ ಆಯ್ಕೆಮಾಡಿ',
      'yourBirthNak': 'ನಿಮ್ಮ ಜನ್ಮ ನಕ್ಷತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ:', 'person1BirthNak': 'ವ್ಯಕ್ತಿ 1ರ ಜನ್ಮ ನಕ್ಷತ್ರ:', 'person2BirthNak': 'ವ್ಯಕ್ತಿ 2ರ ಜನ್ಮ ನಕ್ಷತ್ರ:',
      'goodDay': 'ಶುಭ ದಿನ', 'badDay': 'ಅಶುಭ ದಿನ', 'goodBoth': 'ಇಬ್ಬರಿಗೂ ಶುಭ', 'badBoth': 'ಇಬ್ಬರಿಗೂ ಅಶುಭ', 'goodOnePerson': 'ಒಬ್ಬರಿಗೆ ಮಾತ್ರ ಶುಭ',
      'selectedDayNak': 'ಆಯ್ಕೆಮಾಡಿದ ದಿನದ ನಕ್ಷತ್ರ', 'excludedNak': 'ಹೊರಗಿಡಲಾದ ನಕ್ಷತ್ರ', 'person1': 'ವ್ಯಕ್ತಿ 1', 'person2': 'ವ್ಯಕ್ತಿ 2',
      'selectBothNak': 'ಫಲಿತಾಂಶವನ್ನು ನೋಡಲು ಎರಡೂ ನಕ್ಷತ್ರಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ.',
      'taraChart': 'ತಾರಾನುಕೂಲ ಚಾರ್ಟ್', 'yourTaraChart': 'ನಿಮ್ಮ ತಾರಾನುಕೂಲ ಚಾರ್ಟ್', 'person1TaraChart': 'ವ್ಯಕ್ತಿ 1ರ ತಾರಾನುಕೂಲ ಚಾರ್ಟ್', 'person2TaraChart': 'ವ್ಯಕ್ತಿ 2ರ ತಾರಾನುಕೂಲ ಚಾರ್ಟ್',
      'dayPanchanga': 'ದಿನದ ಪಂಚಾಂಗ', 'muhurtaRules': 'ಮುಹೂರ್ತ ನಿಯಮಗಳು', 'yourBalas': 'ನಿಮ್ಮ ಬಲಗಳು', 'personBalas': 'ಬಲಗಳು',
      'createAppt': 'ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ರಚಿಸಿ', 'clientName': 'ಗ್ರಾಹಕರ ಹೆಸರು', 'minutes': 'ನಿಮಿಷ', 'create': 'ರಚಿಸಿ',
      'apptAdded': 'Calendar ಗೆ ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ಸೇರಿಸಲಾಗಿದೆ!', 'apptFailed': 'ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ವಿಫಲ',
      'horoscope': 'ಜಾತಕ ವಿಶ್ಲೇಷಣೆ', 'matchMakingTitle': 'ಹೊಂದಾಣಿಕೆ',
      'trialExpired': 'ಉಚಿತ ಪ್ರಯೋಗ ಅವಧಿ ಮುಗಿದಿದೆ', 'subBenefits': 'ಚಂದಾದಾರಿಕೆ ಪ್ರಯೋಜನಗಳು',
      'allKundali': 'ಎಲ್ಲಾ ಕುಂಡಲಿ ವೈಶಿಷ್ಟ್ಯಗಳು', 'panchangaTara': 'ಪಂಚಾಂಗ ಮತ್ತು ತಾರಾನುಕೂಲ',
      'mantraCollection': 'ಮಂತ್ರ ಸಂಗ್ರಹ', 'dataBackup': 'ನಿಮ್ಮ ಡೇಟಾ ಸುರಕ್ಷಿತ ಬ್ಯಾಕಪ್ (Data Backup)',
      'subFailed': 'ಚಂದಾದಾರಿಕೆ ಪ್ರಕ್ರಿಯೆ ವಿಫಲವಾಗಿದೆ.', 'subPrice': '₹700 / ವರ್ಷಕ್ಕೆ ಚಂದಾದಾರರಾಗಿ',
      'restoreDone': 'ಹಿಂದಿನ ಖರೀದಿಗಳನ್ನು ಮರುಸ್ಥಾಪಿಸಲಾಗಿದೆ.', 'restorePurchase': 'ಹಿಂದಿನ ಖರೀದಿಯನ್ನು ಮರುಸ್ಥಾಪಿಸಿ (Restore)',
      'recentKundalis': 'ಇತ್ತೀಚಿನ ಕುಂಡಲಿಗಳು', 'clearHistory': 'ಇತಿಹಾಸ ಅಳಿಸಿ',
      'clearHistoryConfirm': 'ಎಲ್ಲಾ ಇತಿಹಾಸ ನಮೂದುಗಳನ್ನು ಅಳಿಸಬೇಕೇ?',
      'historyEmpty': 'ಇತಿಹಾಸ ಖಾಲಿ', 'historyHint': 'ಕುಂಡಲಿ ರಚಿಸಿದಾಗ ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತದೆ',
      'now': 'ಈಗ', 'ago': 'ಹಿಂದೆ', 'saved': 'ಉಳಿಸಲಾಗಿದೆ',
      'kundaliCount': 'ಕುಂಡಲಿ', 'checkInternet': 'ನಿಮ್ಮ ಚಂದಾದಾರಿಕೆಯನ್ನು ಪರಿಶೀಲಿಸಲು ದಯವಿಟ್ಟು ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕ ಕಲ್ಪಿಸಿ.',
      'addPerson': 'ವ್ಯಕ್ತಿ ಸೇರಿಸಿ', 'addNewPerson': 'ಹೊಸ ವ್ಯಕ್ತಿ ಸೇರಿಸಿ', 'newPersonHint': 'ಹೊಸ ಜಾತಕ ವಿವರ ನಮೂದಿಸಿ',
      'addFromSaved': 'ಉಳಿಸಿದ ಜಾತಕದಿಂದ ಸೇರಿಸಿ', 'savedListHint': 'ಸೇವ್ ಮಾಡಲಾದ / ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ಲಿಸ್ಟ್',
      'close': 'ಮುಚ್ಚಿ', 'selectSavedProfile': 'ಉಳಿಸಿದ ಜಾತಕ ಆಯ್ಕೆಮಾಡಿ', 'noOtherProfiles': 'ಬೇರೆ ಪ್ರೊಫೈಲ್\u200cಗಳಿಲ್ಲ',
      'back': 'ಹಿಂದೆ', 'calcInProgress': 'ಕುಂಡಲಿ ಲೆಕ್ಕಿಸಲಾಗುತ್ತಿದೆ...', 'calcFailed': 'ಕುಂಡಲಿ ಲೆಕ್ಕ ವಿಫಲ',
      'newPerson': 'ಹೊಸ ವ್ಯಕ್ತಿ', 'nameLabel': 'ಹೆಸರು', 'dateLabel': 'ದಿನಾಂಕ', 'timeLabel': 'ಸಮಯ',
      'latLabel': 'ಅಕ್ಷಾಂಶ', 'lonLabel': 'ರೇಖಾಂಶ',
      'enterName': 'ದಯವಿಟ್ಟು ಹೆಸರನ್ನು ನಮೂದಿಸಿ',
      'calcSuccess': 'ಕುಂಡಲಿ ಯಶಸ್ವಿಯಾಗಿ ರಚಿಸಲಾಗಿದೆ ಮತ್ತು ಉಳಿಸಲಾಗಿದೆ', 'editPerson': 'ವ್ಯಕ್ತಿ ಬದಲಾಯಿಸಿ',
      'placeNotFoundDash': 'ಸ್ಥಳ ಕಂಡುಬಂದಿಲ್ಲ.', 'placeError': 'ಸ್ಥಳ ಸಂಪರ್ಕ ದೋಷ.',
      'aroodhaLabel': 'ಆರೂಢ', 'rashiLabel': 'ರಾಶಿ', 'addLabel': 'ಸೇರಿಸಿ', 'clearLabel': 'ತೆರವುಗೊಳಿಸಿ',
      'prastuta': 'ಪ್ರಸ್ತುತ', 'grahaSphuta': 'ಗ್ರಹ ಸ್ಫುಟ',
      'hGraha': 'ಗ್ರಹ', 'hRashi': 'ರಾಶಿ', 'hSphuta': 'ಸ್ಫುಟ', 'hNakPada': 'ನಕ್ಷತ್ರ - ಪಾದ',
      'grahaVishlesha': 'ಗ್ರಹಗಳ ವಿಶ್ಲೇಷಣೆ', 'hBhava': 'ಭಾವ', 'hD3': 'ದಿ/ನೈ', 'hD2': 'ಹೋ', 'hD9': 'ನ', 'hD30': 'ತ್ರಿಂಶ', 'hD12': 'ದ್ವಾದ', 'hKshetra': 'ಕ್ಷೇತ್ರ',
      'pHeading': 'ಪಂಚಾಂಗ', 'varaLabel': 'ವಾರ', 'tithiLabel': 'ತಿಥಿ',
      'chandraNakshatra': 'ಚಂದ್ರ ನಕ್ಷತ್ರ', 'padaLabel': 'ಪಾದ',
      'yogaLabel': 'ಯೋಗ', 'karanaLabel': 'ಕರಣ', 'chandraRashiLabel': 'ಚಂದ್ರ ರಾಶಿ',
      'suryaNakshatraLabel': 'ಸೂರ್ಯ ನಕ್ಷತ್ರ',
      'udayadiGhati': 'ಉದಯಾದಿ ಘಟಿ',
      'gataGhati': 'ಗತ ಘಟಿ', 'sheshaGhati': 'ಶೇಷ ಘಟಿ', 'lagna': 'ಲಗ್ನ',
      'placeLabel': 'ಸ್ಥಳ', 'dashaLord': 'ದಶಾ ನಾಥ', 'dashaBalance': 'ಶೇಷ',
      'shadvarga': 'ಷಡ್ವರ್ಗ', 'bhavaKaksha': 'ಭಾವ ಕಕ್ಷೆ ಗ್ರಹ ವಿಶ್ಲೇಷಣೆ',
      'bhavaRecalc': 'ಭಾವ ಮಧ್ಯ ಲಗ್ನ', 'bhavaRecalcFor': 'ಭಾವ ಮಧ್ಯ ಲಗ್ನ',
      'bhavaSelect': 'ಗ್ರಹ ಆಯ್ಕೆ ಮಾಡಿ', 'bhavaReset': 'ಮೂಲ',
      'hBhavaNo': 'ಭಾವ', 'hBhavaStart': 'ಭಾವ ಆರಂಭ', 'hBhavaMid': 'ಭಾವ ಮಧ್ಯ', 'hBhavaEnd': 'ಭಾವ ಅಂತ್ಯ',
    },
    'hi': {
      'appName': 'भारतीयम्', 'home': 'होम', 'kundali': 'कुंडली', 'panchanga': 'पंचांग',
      'planets': 'ग्रह', 'appointment': 'अपॉइंटमेंट', 'vedicClock': 'वैदिक घड़ी',
      'settings': 'सेटिंग्स', 'aboutUs': 'हमारे बारे में', 'language': 'भाषा / Language',
      'name': 'नाम', 'dob': 'जन्म तिथि', 'time': 'जन्म समय', 'place': 'जन्म स्थान',
      'calculate': 'गणना करें', 'selectDate': 'तिथि चुनें', 'selectTime': 'समय चुनें',
      'save': 'सहेजें', 'delete': 'हटाएं', 'cancel': 'रद्द', 'share': 'शेयर',
      'yes': 'हाँ', 'no': 'नहीं', 'chart': 'कुंडली', 'sphuta': 'स्फुट', 'bhava': 'भाव',
      'dasha': 'दशा', 'aroodha': 'आरूढ़', 'notes': 'टिप्पणी',
      'sunrise': 'सूर्योदय', 'sunset': 'सूर्यास्त', 'searchPlace': 'स्थान खोजें',
      'noResults': 'कोई परिणाम नहीं', 'deleteConfirm': 'हटाना है?', 'noBtn': 'नहीं',
      'errorLabel': 'त्रुटि', 'retryBtn': 'पुनः प्रयास',
      'tithi': 'तिथि', 'vara': 'वार', 'nakshatra': 'नक्षत्र', 'yoga': 'योग', 'karana': 'करण',
      'chandraNak': 'चंद्र नक्षत्र', 'suryaNak': 'सूर्य नक्षत्र', 'pada': 'पाद',
      'chandraRashi': 'चंद्र राशि', 'chandraMasa': 'चंद्र मास',
      'souraMasa': 'सौर मास', 'souraMasaGataDina': 'सौर मास गत दिन',
      'samvatsara': 'संवत्सर', 'ayana': 'अयन', 'rutu': 'ऋतु',
      'divamana': 'दिन का प्रमाण', 'ratrimana': 'रात का प्रमाण',
      'rahuKala': 'राहु काल', 'gulikaKala': 'गुलिक काल', 'yamaKala': 'यमगंड काल',
      'surya': 'सूर्य', 'chandra': 'चंद्र', 'kala': 'काल',
      'selectDateLabel': 'तिथि चुनें', 'today': 'आज', 'sthala': 'स्थान', 'dinanka': 'दिनांक',
      'mars': 'मंगल', 'mercury': 'बुध', 'jupiter': 'गुरु', 'venus': 'शुक्र', 'saturn': 'शनि', 'rahu': 'राहु', 'ketu': 'केतु',
      'all': 'सभी', 'start': 'प्रारंभ', 'end': 'अंत', 'continues': 'अगले वर्ष तक',
      'transits': 'संचार', 'vakri': 'वक्री', 'asta': 'अस्त',
      'ghati': 'घटि', 'vighati': 'विघटि', 'anuVighati': 'अनुविघटि',
      'ghatiLabel': 'घटि    विघटि   अनुविघटि',
      'udaya': 'उदय',
      'ayanamsa': 'अयनांश', 'nodeType': 'राहु प्रकार',
      'selectAllDetails': 'कृपया सभी विवरण चुनें', 'selectHint': 'चुनें',
      'matchPoor': 'मिलान अच्छा नहीं', 'matchMedium': 'मिलान मध्यम', 'matchGood': 'मिलान बहुत अच्छा',
      'matchResult': 'अष्टकूट गुण मिलान फल', 'totalGuna': 'कुल गुण', 'result': 'परिणाम',
      'brideDetails': 'वधू के विवरण', 'groomDetails': 'वर के विवरण', 'checkMatch': 'मिलान जाँचें',
      'referenceShloka': 'आधार श्लोक:', 'rule': 'नियम:', 'source': 'स्रोत: ',
      'themeSettings': 'थीम सेटिंग्स', 'defaultLocation': 'डिफॉल्ट स्थान',
      'locationHint': 'पंचांग और वैदिक घड़ी गणना के लिए उपयोग',
      'themeLight': 'स्टैंडर्ड लाइट', 'themeDark': 'डार्क मोड', 'themeGold': 'स्वर्ण', 'themeOcean': 'सागर', 'themeGreen': 'हरा',
      'chartStyle': 'कुंडली शैली', 'southIndian': 'दक्षिण भारत', 'northIndian': 'उत्तर भारत',
      'southDesc': '4×4 ग्रिड - राशि स्थिर, ग्रह चलते हैं', 'northDesc': 'हीरा (Diamond) - भाव स्थिर, राशियाँ चलती हैं',
      'searchLocation': 'स्थान खोजें', 'onlineSearch': 'ऑनलाइन खोजें', 'defaultLocationSet': 'डिफॉल्ट स्थान',
      'googleSyncActive': 'Google सिंक सक्रिय है', 'signInForCloud': 'क्लाउड बैकअप के लिए Google में साइन इन करें',
      'signInSuccess': 'Google Sign In सफल!', 'signInFailed': 'Sign In विफल',
      'migrateDevice': 'डिवाइस बदलें', 'migrateConfirm': 'डिवाइस बदलें?',
      'migrateMsg': 'इस डिवाइस को आपका प्राथमिक डिवाइस बनाया जाएगा। अन्य डिवाइस पर यह खाता ब्लॉक हो जाएगा।',
      'yesChange': 'हाँ, बदलें', 'migrateSuccess': 'डिवाइस सफलतापूर्वक बदला गया!', 'failed': 'विफल',
      'backupRestore': 'डेटा बैकअप और पुनर्स्थापना', 'backupDesc': 'अपने सभी डेटा का बैकअप लें और नए डिवाइस पर पुनर्स्थापित करें।',
      'exportBackup': 'बैकअप निर्यात करें', 'importBackup': 'बैकअप आयात करें',
      'exportChoose': 'बैकअप फ़ाइल सहेजने के लिए ऐप चुनें।', 'restoreSuccess': 'डेटा सफलतापूर्वक पुनर्स्थापित!',
      'humanReadable': 'पठनीय स्प्रेडशीट', 'exportSpreadsheet': 'स्प्रेडशीट और नोट्स निर्यात करें',
      'spreadsheetExported': 'स्प्रेडशीट और नोट्स निर्यात हो गए!', 'exportFailed': 'निर्यात विफल',
      'cloudBackup': 'Google Drive बैकअप', 'premiumSub': 'प्रीमियम सदस्यता',
      'taranukoola': 'तारानुकूल', 'taraResults': 'तारानुकूल परिणाम',
      'onePerson': '१ व्यक्ति', 'twoPersons': '२ व्यक्ति',
      'excludeBadNak': 'अशुभ नक्षत्र छोड़ें', 'selectNakHint': 'जन्म नक्षत्र चुनें',
      'yourBirthNak': 'अपना जन्म नक्षत्र चुनें:', 'person1BirthNak': 'व्यक्ति 1 का जन्म नक्षत्र:', 'person2BirthNak': 'व्यक्ति 2 का जन्म नक्षत्र:',
      'goodDay': 'शुभ दिन', 'badDay': 'अशुभ दिन', 'goodBoth': 'दोनों के लिए शुभ', 'badBoth': 'दोनों के लिए अशुभ', 'goodOnePerson': 'एक के लिए शुभ',
      'selectedDayNak': 'चयनित दिन का नक्षत्र', 'excludedNak': 'बहिष्कृत नक्षत्र', 'person1': 'व्यक्ति 1', 'person2': 'व्यक्ति 2',
      'selectBothNak': 'परिणाम देखने के लिए दोनों नक्षत्र चुनें।',
      'taraChart': 'तारानुकूल चार्ट', 'yourTaraChart': 'आपका तारानुकूल चार्ट', 'person1TaraChart': 'व्यक्ति 1 का तारानुकूल चार्ट', 'person2TaraChart': 'व्यक्ति 2 का तारानुकूल चार्ट',
      'dayPanchanga': 'दिन का पंचांग', 'muhurtaRules': 'मुहूर्त नियम', 'yourBalas': 'आपके बल', 'personBalas': 'बल',
      'createAppt': 'अपॉइंटमेंट बनाएं', 'clientName': 'ग्राहक का नाम', 'minutes': 'मिनट', 'create': 'बनाएं',
      'apptAdded': 'Calendar में अपॉइंटमेंट जोड़ा गया!', 'apptFailed': 'अपॉइंटमेंट विफल',
      'horoscope': 'जातक विश्लेषण', 'matchMakingTitle': 'गुण मिलान',
      'trialExpired': 'निःशुल्क परीक्षण अवधि समाप्त', 'subBenefits': 'सदस्यता लाभ',
      'allKundali': 'सभी कुंडली विशेषताएं', 'panchangaTara': 'पंचांग और तारानुकूल',
      'mantraCollection': 'मंत्र संग्रह', 'dataBackup': 'आपका डेटा सुरक्षित बैकअप (Data Backup)',
      'subFailed': 'सदस्यता प्रक्रिया विफल.', 'subPrice': '₹700 / वर्ष सदस्यता',
      'restoreDone': 'पिछली खरीद पुनर्स्थापित.', 'restorePurchase': 'पिछली खरीद पुनर्स्थापित करें (Restore)',
      'recentKundalis': 'हाल की कुंडलियाँ', 'clearHistory': 'इतिहास मिटाएं',
      'clearHistoryConfirm': 'सभी इतिहास मिटाना है?',
      'historyEmpty': 'इतिहास खाली', 'historyHint': 'कुंडली बनाने पर यहाँ दिखेगा',
      'now': 'अभी', 'ago': 'पहले', 'saved': 'सहेजा गया',
      'kundaliCount': 'कुंडली', 'checkInternet': 'सदस्यता जाँचने के लिए इंटरनेट कनेक्ट करें.',
      'addPerson': 'व्यक्ति जोड़ें', 'addNewPerson': 'नया व्यक्ति जोड़ें', 'newPersonHint': 'नया जातक विवरण दर्ज करें',
      'addFromSaved': 'सहेजे गए से जोड़ें', 'savedListHint': 'सहेजे गए / अपॉइंटमेंट सूची',
      'close': 'बंद करें', 'selectSavedProfile': 'सहेजा गया जातक चुनें', 'noOtherProfiles': 'कोई अन्य प्रोफ़ाइल नहीं',
      'back': 'पीछे', 'calcInProgress': 'कुंडली गणना हो रही है...', 'calcFailed': 'कुंडली गणना विफल',
      'newPerson': 'नया व्यक्ति', 'nameLabel': 'नाम', 'dateLabel': 'तारीख', 'timeLabel': 'समय',
      'latLabel': 'अक्षांश', 'lonLabel': 'रेखांश',
      'enterName': 'कृपया नाम दर्ज करें',
      'calcSuccess': 'कुंडली सफलतापूर्वक बनाई और सहेजी गई', 'editPerson': 'व्यक्ति बदलें',
      'placeNotFoundDash': 'स्थान नहीं मिला.', 'placeError': 'स्थान कनेक्शन त्रुटि.',
      'aroodhaLabel': 'आरूढ़', 'rashiLabel': 'राशि', 'addLabel': 'जोड़ें', 'clearLabel': 'हटाएं',
      'prastuta': 'वर्तमान', 'grahaSphuta': 'ग्रह स्फुट',
      'hGraha': 'ग्रह', 'hRashi': 'राशि', 'hSphuta': 'स्फुट', 'hNakPada': 'नक्षत्र - पाद',
      'grahaVishlesha': 'ग्रह विश्लेषण', 'hBhava': 'भाव', 'hD3': 'दि/नै', 'hD2': 'हो', 'hD9': 'न', 'hD30': 'त्रिंश', 'hD12': 'द्वाद', 'hKshetra': 'क्षेत्र',
      'pHeading': 'पंचांग', 'varaLabel': 'वार', 'tithiLabel': 'तिथि',
      'chandraNakshatra': 'चंद्र नक्षत्र', 'padaLabel': 'पाद',
      'yogaLabel': 'योग', 'karanaLabel': 'करण', 'chandraRashiLabel': 'चंद्र राशि',
      'suryaNakshatraLabel': 'सूर्य नक्षत्र',
      'udayadiGhati': 'उदयादि घटी',
      'gataGhati': 'गत घटी', 'sheshaGhati': 'शेष घटी', 'lagna': 'लग्न',
      'placeLabel': 'स्थान', 'dashaLord': 'दशा नाथ', 'dashaBalance': 'शेष',
      'shadvarga': 'षड्वर्ग', 'bhavaKaksha': 'भाव कक्षा ग्रह विश्लेषण',
      'bhavaRecalc': 'भाव मध्य लग्न', 'bhavaRecalcFor': 'भाव मध्य लग्न',
      'bhavaSelect': 'ग्रह चुनें', 'bhavaReset': 'मूल',
      'hBhavaNo': 'भाव', 'hBhavaStart': 'भाव आरंभ', 'hBhavaMid': 'भाव मध्य', 'hBhavaEnd': 'भाव अंत',
    },
    'ta': {
      'appName': 'பாரதீயம்', 'home': 'முகப்பு', 'kundali': 'ஜாதகம்', 'panchanga': 'பஞ்சாங்கம்',
      'planets': 'கிரகங்கள்', 'appointment': 'சந்திப்பு', 'vedicClock': 'வேத கடிகாரம்',
      'settings': 'அமைப்புகள்', 'aboutUs': 'எங்களைப் பற்றி', 'language': 'மொழி / Language',
      'name': 'பெயர்', 'dob': 'பிறந்த தேதி', 'time': 'பிறந்த நேரம்', 'place': 'பிறந்த இடம்',
      'calculate': 'கணக்கிடு', 'selectDate': 'தேதி தேர்வு', 'selectTime': 'நேரம் தேர்வு',
      'save': 'சேமி', 'delete': 'நீக்கு', 'cancel': 'ரத்து', 'share': 'பகிர்',
      'yes': 'ஆம்', 'no': 'இல்லை', 'chart': 'ஜாதகம்', 'sphuta': 'ஸ்புடம்', 'bhava': 'பாவம்',
      'dasha': 'தசை', 'aroodha': 'ஆரூடம்', 'notes': 'குறிப்பு',
      'sunrise': 'சூரிய உதயம்', 'sunset': 'சூரிய அஸ்தமனம்', 'searchPlace': 'இடம் தேடு',
      'noResults': 'முடிவுகள் இல்லை', 'deleteConfirm': 'நீக்கவா?', 'noBtn': 'வேண்டாம்',
      'errorLabel': 'பிழை', 'retryBtn': 'மீண்டும் முயற்சி',
      'tithi': 'திதி', 'vara': 'வாரம்', 'nakshatra': 'நட்சத்திரம்', 'yoga': 'யோகம்', 'karana': 'கரணம்',
      'chandraNak': 'சந்திர நட்சத்திரம்', 'suryaNak': 'சூரிய நட்சத்திரம்', 'pada': 'பாதம்',
      'chandraRashi': 'சந்திர ராசி', 'chandraMasa': 'சந்திர மாதம்',
      'souraMasa': 'சௌர மாதம்', 'souraMasaGataDina': 'சௌர மாத கடந்த நாள்',
      'samvatsara': 'சம்வத்சரம்', 'ayana': 'அயனம்', 'rutu': 'ருது',
      'divamana': 'பகல் நேரம்', 'ratrimana': 'இரவு நேரம்',
      'rahuKala': 'ராகு காலம்', 'gulikaKala': 'குளிகை காலம்', 'yamaKala': 'எமகண்டம்',
      'surya': 'சூரியன்', 'chandra': 'சந்திரன்', 'kala': 'காலம்',
      'selectDateLabel': 'தேதி தேர்வு', 'today': 'இன்று', 'sthala': 'இடம்', 'dinanka': 'தேதி',
      'mars': 'செவ்வாய்', 'mercury': 'புதன்', 'jupiter': 'குரு', 'venus': 'சுக்கிரன்', 'saturn': 'சனி', 'rahu': 'ராகு', 'ketu': 'கேது',
      'all': 'அனைத்தும்', 'start': 'தொடக்கம்', 'end': 'முடிவு', 'continues': 'அடுத்த ஆண்டு வரை',
      'transits': 'சங்கமம்', 'vakri': 'வக்கிரம்', 'asta': 'அஸ்தம்',
      'ghati': 'கடி', 'vighati': 'விகடி', 'anuVighati': 'அனுவிகடி',
      'ghatiLabel': 'கடி    விகடி   அனுவிகடி',
      'udaya': 'உதயம்',
      'ayanamsa': 'அயனாம்சம்', 'nodeType': 'ராகு வகை',
      'selectAllDetails': 'அனைத்து விவரங்களையும் தேர்வு செய்க', 'selectHint': 'தேர்வு',
      'matchPoor': 'பொருத்தம் நன்றாக இல்லை', 'matchMedium': 'பொருத்தம் நடுத்தரம்', 'matchGood': 'பொருத்தம் மிகவும் நன்று',
      'matchResult': 'அஷ்டகூட குண மிலனம்', 'totalGuna': 'மொத்த குணம்', 'result': 'முடிவு',
      'brideDetails': 'மணப்பெண் விவரங்கள்', 'groomDetails': 'மணமகன் விவரங்கள்', 'checkMatch': 'பொருத்தம் சோதி',
      'referenceShloka': 'ஆதார ஸ்லோகம்:', 'rule': 'விதி:', 'source': 'மூலம்: ',
      'themeSettings': 'தீம் அமைப்புகள்', 'defaultLocation': 'இயல்பு இடம்',
      'locationHint': 'பஞ்சாங்கம் மற்றும் வைதிக கடிகாரத்திற்கு பயன்படுத்தப்படும்',
      'themeLight': 'ஸ்டாண்டர்ட் லைட்', 'themeDark': 'டார்க் மோட்', 'themeGold': 'ஸ்வர்ண', 'themeOcean': 'சாகர', 'themeGreen': 'பச்சை',
      'chartStyle': 'ஜாதக பாணி', 'southIndian': 'தென் இந்திய', 'northIndian': 'வட இந்திய',
      'southDesc': '4×4 கட்டம் - ராசி நிலையான, கிரகங்கள் நகரும்', 'northDesc': 'வைரம் - பாவம் நிலையான, ராசிகள் நகரும்',
      'searchLocation': 'இடம் தேடு', 'onlineSearch': 'ஆன்லைன் தேடல்', 'defaultLocationSet': 'இயல்பு இடம்',
      'googleSyncActive': 'Google ஒத்திசைவு செயலில்', 'signInForCloud': 'கிளவுட் காப்புக்கு Google இல் உள்நுழையவும்',
      'signInSuccess': 'Google Sign In வெற்றி!', 'signInFailed': 'Sign In தோல்வி',
      'migrateDevice': 'சாதனம் மாற்று', 'migrateConfirm': 'சாதனம் மாற்றவா?',
      'migrateMsg': 'இந்த சாதனத்தை உங்கள் முதன்மை சாதனமாக அமைக்கப்படும். மற்ற சாதனத்தில் இந்த கணக்கு தடுக்கப்படும்.',
      'yesChange': 'ஆம், மாற்று', 'migrateSuccess': 'சாதனம் வெற்றிகரமாக மாற்றப்பட்டது!', 'failed': 'தோல்வி',
      'backupRestore': 'தரவு காப்பு மற்றும் மீட்பு', 'backupDesc': 'உங்கள் எல்லா தரவையும் காப்புப் பிரதி எடுத்து புதிய சாதனத்தில் மீட்டெடுக்கவும்.',
      'exportBackup': 'காப்பு ஏற்றுமதி', 'importBackup': 'காப்பு இறக்குமதி',
      'exportChoose': 'காப்பு கோப்பை சேமிக்க பயன்பாட்டைத் தேர்ந்தெடுக்கவும்.', 'restoreSuccess': 'தரவு வெற்றிகரமாக மீட்டெடுக்கப்பட்டது!',
      'humanReadable': 'படிக்கக்கூடிய விரிதாள்கள்', 'exportSpreadsheet': 'விரிதாள் மற்றும் குறிப்புகளை ஏற்றுமதி செய்',
      'spreadsheetExported': 'விரிதாள் மற்றும் குறிப்புகள் ஏற்றுமதி செய்யப்பட்டன!', 'exportFailed': 'ஏற்றுமதி தோல்வி',
      'cloudBackup': 'Google Drive காப்பு', 'premiumSub': 'பிரீமியம் சந்தா',
      'taranukoola': 'தாரானுகூல', 'taraResults': 'தாரானுகூல முடிவுகள்',
      'onePerson': '1 நபர்', 'twoPersons': '2 நபர்கள்',
      'excludeBadNak': 'அசுப நட்சத்திரம் நீக்கு', 'selectNakHint': 'ஜென்ம நட்சத்திரம் தேர்ந்தெடு',
      'yourBirthNak': 'உங்கள் ஜென்ம நட்சத்திரத்தை தேர்ந்தெடுங்கள்:', 'person1BirthNak': 'நபர் 1 ஜென்ம நட்சத்திரம்:', 'person2BirthNak': 'நபர் 2 ஜென்ம நட்சத்திரம்:',
      'goodDay': 'சுப நாள்', 'badDay': 'அசுப நாள்', 'goodBoth': 'இருவருக்கும் சுபம்', 'badBoth': 'இருவருக்கும் அசுபம்', 'goodOnePerson': 'ஒருவருக்கு மட்டும் சுபம்',
      'selectedDayNak': 'தேர்ந்தெடுத்த நாள் நட்சத்திரம்', 'excludedNak': 'நீக்கப்பட்ட நட்சத்திரம்', 'person1': 'நபர் 1', 'person2': 'நபர் 2',
      'selectBothNak': 'முடிவுகளைக் காண இரண்டு நட்சத்திரங்களையும் தேர்ந்தெடுக்கவும்.',
      'taraChart': 'தாரானுகூல விளக்கப்படம்', 'yourTaraChart': 'உங்கள் தாரானுகூல விளக்கப்படம்', 'person1TaraChart': 'நபர் 1 தாரானுகூல விளக்கப்படம்', 'person2TaraChart': 'நபர் 2 தாரானுகூல விளக்கப்படம்',
      'dayPanchanga': 'நாள் பஞ்சாங்கம்', 'muhurtaRules': 'முகூர்த்த விதிகள்', 'yourBalas': 'உங்கள் பலங்கள்', 'personBalas': 'பலங்கள்',
      'createAppt': 'அப்பாயின்ட்மென்ட் உருவாக்கு', 'clientName': 'வாடிக்கையாளர் பெயர்', 'minutes': 'நிமிடங்கள்', 'create': 'உருவாக்கு',
      'apptAdded': 'Calendar க்கு அப்பாயின்ட்மென்ட் சேர்க்கப்பட்டது!', 'apptFailed': 'அப்பாயின்ட்மென்ட் தோல்வி',
      'horoscope': 'ஜாதக விசாரணை', 'matchMakingTitle': 'பொருத்தம்',
      'trialExpired': 'உசித சோதனை காலம் முடிந்தது', 'subBenefits': 'சந்தா பயன்கள்',
      'allKundali': 'எல்லா ஜாதக சிறப்புகள்', 'panchangaTara': 'பஞ்சாங்கம் மற்றும் தாரானுகூல',
      'mantraCollection': 'மந்திர தொகுப்பு', 'dataBackup': 'உங்கள் தரவு பாதுகாப்பு (Data Backup)',
      'subFailed': 'சந்தா ப்ரக்ரியை தோல்வி.', 'subPrice': '₹700 / வருட சந்தா',
      'restoreDone': 'முந்தைய வாங்கல் மீட்டெடுக்கப்பட்டது.', 'restorePurchase': 'முந்தைய வாங்கல் மீட்டெடு (Restore)',
      'recentKundalis': 'இத்தீசின ஜாதகங்கள்', 'clearHistory': 'வரலாற்றை அழி',
      'clearHistoryConfirm': 'எல்லா வரலாற்றையும் அழிக்கவா?',
      'historyEmpty': 'வரலாற்று காலி', 'historyHint': 'ஜாதகம் உருவாக்கும்போது இங்கே தோன்றும்',
      'now': 'இப்போது', 'ago': 'முன்', 'saved': 'சேமிக்கப்பட்டது',
      'kundaliCount': 'ஜாதகம்', 'checkInternet': 'சந்தாவை சரிபார்க்க இணையத்தை இணைக்கவும்.',
      'addPerson': 'நபரைச் சேர்', 'addNewPerson': 'புதிய நபரைச் சேர்', 'newPersonHint': 'புதிய ஜாதக விவரம் உள்ளிடவும்',
      'addFromSaved': 'சேமித்ததிலிருந்து சேர்', 'savedListHint': 'சேமிக்கப்பட்ட / அப்பாயின்ட்மென்ட் பட்டியல்',
      'close': 'மூடு', 'selectSavedProfile': 'சேமிக்கப்பட்ட ஜாதகம் தேர்ந்தெடு', 'noOtherProfiles': 'வேறு புரொஃபைல் இல்லை',
      'back': 'பின்', 'calcInProgress': 'ஜாதகம் கணக்கிடப்படுகிறது...', 'calcFailed': 'ஜாதக கணக்கீடு தோல்வி',
      'newPerson': 'புதிய நபர்', 'nameLabel': 'பெயர்', 'dateLabel': 'தேதி', 'timeLabel': 'நேரம்',
      'latLabel': 'அட்சரேகை', 'lonLabel': 'தீர்க்கரேகை',
      'enterName': 'பெயரை உள்ளிடவும்',
      'calcSuccess': 'ஜாதகம் வெற்றிகரமாக உருவாக்கப்பட்டது', 'editPerson': 'நபரை மாற்று',
      'placeNotFoundDash': 'இடம் கிடைக்கவில்லை.', 'placeError': 'இட இணைப்பு பிழை.',
      'aroodhaLabel': 'ஆரூடம்', 'rashiLabel': 'ராசி', 'addLabel': 'சேர்', 'clearLabel': 'அழி',
      'prastuta': 'தற்போதைய', 'grahaSphuta': 'கிரக ஸ்புடம்',
      'hGraha': 'கிரகம்', 'hRashi': 'ராசி', 'hSphuta': 'ஸ்புடம்', 'hNakPada': 'நட்சத்திரம் - பாதம்',
      'grahaVishlesha': 'கிரக பகுப்பாய்வு', 'hBhava': 'பாவம்', 'hD3': 'தி/நை', 'hD2': 'ஹோ', 'hD9': 'ந', 'hD30': 'த்ரிம்', 'hD12': 'த்வா', 'hKshetra': 'க்ஷேத்ர',
      'pHeading': 'பஞ்சாங்கம்', 'varaLabel': 'வாரம்', 'tithiLabel': 'திதி',
      'chandraNakshatra': 'சந்திர நட்சத்திரம்', 'padaLabel': 'பாதம்',
      'yogaLabel': 'யோகம்', 'karanaLabel': 'கரணம்', 'chandraRashiLabel': 'சந்திர ராசி',
      'suryaNakshatraLabel': 'சூரிய நட்சத்திரம்',
      'udayadiGhati': 'உதயாதி கடிகை',
      'gataGhati': 'கத கடிகை', 'sheshaGhati': 'சேஷ கடிகை', 'lagna': 'லக்னம்',
      'placeLabel': 'இடம்', 'dashaLord': 'தசா நாதன்', 'dashaBalance': 'சேஷம்',
      'shadvarga': 'ஷட்வர்கம்', 'bhavaKaksha': 'பாவ கக்ஷா கிரக பகுப்பாய்வு',
      'bhavaRecalc': 'பாவ மத்ய லக்னம்', 'bhavaRecalcFor': 'பாவ மத்ய லக்னம்',
      'bhavaSelect': 'கிரகம் தேர்ந்தெடு', 'bhavaReset': 'மூலம்',
      'hBhavaNo': 'பாவம்', 'hBhavaStart': 'பாவ ஆரம்பம்', 'hBhavaMid': 'பாவ மத்யம்', 'hBhavaEnd': 'பாவ முடிவு',
    },
    'te': {
      'appName': 'భారతీయమ్', 'home': 'హోమ్', 'kundali': 'కుండలి', 'panchanga': 'పంచాంగం',
      'planets': 'గ్రహాలు', 'appointment': 'అపాయింట్‌మెంట్', 'vedicClock': 'వేద గడియారం',
      'settings': 'సెట్టింగ్‌లు', 'aboutUs': 'మా గురించి', 'language': 'భాష / Language',
      'name': 'పేరు', 'dob': 'పుట్టిన తేదీ', 'time': 'పుట్టిన సమయం', 'place': 'పుట్టిన ప్రదేశం',
      'calculate': 'లెక్కించు', 'selectDate': 'తేదీ ఎంచుకోండి', 'selectTime': 'సమయం ఎంచుకోండి',
      'save': 'సేవ్', 'delete': 'తొలగించు', 'cancel': 'రద్దు', 'share': 'షేర్',
      'yes': 'అవును', 'no': 'కాదు', 'chart': 'కుండలి', 'sphuta': 'స్ఫుటం', 'bhava': 'భావం',
      'dasha': 'దశ', 'aroodha': 'ఆరూఢం', 'notes': 'గమనికలు',
      'sunrise': 'సూర్యోదయం', 'sunset': 'సూర్యాస్తమయం', 'searchPlace': 'ప్రదేశం వెతుకు',
      'noResults': 'ఫలితాలు లేవు', 'deleteConfirm': 'తొలగించాలా?', 'noBtn': 'వద్దు',
      'errorLabel': 'లోపం', 'retryBtn': 'మళ్ళీ ప్రయత్నించు',
      'tithi': 'తిథి', 'vara': 'వారం', 'nakshatra': 'నక్షత్రం', 'yoga': 'యోగం', 'karana': 'కరణం',
      'chandraNak': 'చంద్ర నక్షత్రం', 'suryaNak': 'సూర్య నక్షత్రం', 'pada': 'పాదం',
      'chandraRashi': 'చంద్ర రాశి', 'chandraMasa': 'చంద్ర మాసం',
      'souraMasa': 'సౌర మాసం', 'souraMasaGataDina': 'సౌర మాస గత దినం',
      'samvatsara': 'సంవత్సరం', 'ayana': 'అయనం', 'rutu': 'ఋతువు',
      'divamana': 'పగటి ప్రమాణం', 'ratrimana': 'రాత్రి ప్రమాణం',
      'rahuKala': 'రాహు కాలం', 'gulikaKala': 'గుళిక కాలం', 'yamaKala': 'యమగండ కాలం',
      'surya': 'సూర్యుడు', 'chandra': 'చంద్రుడు', 'kala': 'కాలం',
      'selectDateLabel': 'తేదీ ఎంచుకోండి', 'today': 'ఈరోజు', 'sthala': 'ప్రదేశం', 'dinanka': 'తేదీ',
      'mars': 'కుజుడు', 'mercury': 'బుధుడు', 'jupiter': 'గురుడు', 'venus': 'శుక్రుడు', 'saturn': 'శని', 'rahu': 'రాహువు', 'ketu': 'కేతువు',
      'all': 'అన్నీ', 'start': 'ప్రారంభం', 'end': 'అంతం', 'continues': 'వచ్చే సంవత్సరం వరకు',
      'transits': 'సంచారం', 'vakri': 'వక్రీ', 'asta': 'అస్తం',
      'ghati': 'ఘటి', 'vighati': 'విఘటి', 'anuVighati': 'అనువిఘటి',
      'ghatiLabel': 'ఘటి    విఘటి   అనువిఘటి',
      'udaya': 'ఉదయం',
      'ayanamsa': 'అయనాంశ', 'nodeType': 'రాహు రకం',
      'selectAllDetails': 'దయచేసి అన్ని వివరాలు ఎంచుకోండి', 'selectHint': 'ఎంచుకోండి',
      'matchPoor': 'పొందిక బాగా లేదు', 'matchMedium': 'పొందిక మధ్యమం', 'matchGood': 'పొందిక చాలా బాగుంది',
      'matchResult': 'అష్టకూట గుణ మిలనం ఫలితం', 'totalGuna': 'మొత్తం గుణాలు', 'result': 'ఫలితం',
      'brideDetails': 'వధూ వివరాలు', 'groomDetails': 'వరుడు వివరాలు', 'checkMatch': 'పొందిక చూడండి',
      'referenceShloka': 'ఆధార శ్లోకం:', 'rule': 'నియమం:', 'source': 'మూలం: ',
      'themeSettings': 'థీమ్ సెట్టింగ్స్', 'defaultLocation': 'డీఫాల్ట్ ప్రదేశం',
      'locationHint': 'పంచాంగ మరియు వైదిక గడియారం లెక్కకు వాడతారు',
      'themeLight': 'స్టాండర్డ్ లైట్', 'themeDark': 'డార్క్ మోడ్', 'themeGold': 'స్వర్ణ', 'themeOcean': 'సాగర', 'themeGreen': 'ఆకుపచ్చ',
      'chartStyle': 'కుండలి శైలి', 'southIndian': 'దక్షిణ భారతం', 'northIndian': 'ఉత్తర భారతం',
      'southDesc': '4×4 గ్రిడ్ - రాశి స్థిరం, గ్రహాలు కదులుతాయి', 'northDesc': 'వజ్రం (Diamond) - భావం స్థిరం, రాశులు కదులుతాయి',
      'searchLocation': 'ప్రదేశం వెతకండి', 'onlineSearch': 'ఆన్‌లైన్ వెతకండి', 'defaultLocationSet': 'డీఫాల్ట్ ప్రదేశం',
      'googleSyncActive': 'Google సింక్ యాక్టివ్', 'signInForCloud': 'క్లౌడ్ బ్యాకప్ కోసం Google లో సైన్ ఇన్ చేయండి',
      'signInSuccess': 'Google Sign In విజయవంతం!', 'signInFailed': 'Sign In విఫలం',
      'migrateDevice': 'పరికరం మార్చండి', 'migrateConfirm': 'పరికరం మార్చాలా?',
      'migrateMsg': 'ఈ పరికరాన్ని మీ ప్రాథమిక పరికరంగా సెట్ చేయబడుతుంది. ఇతర పరికరంలో ఈ ఖాతా బ్లాక్ అవుతుంది.',
      'yesChange': 'అవును, మార్చు', 'migrateSuccess': 'పరికరం విజయవంతంగా మార్చబడింది!', 'failed': 'విఫలం',
      'backupRestore': 'డేటా బ్యాకప్ మరియు పునరుద్ధరణ', 'backupDesc': 'మీ మొత్తం డేటాను బ్యాకప్ చేసి కొత్త పరికరంలో పునరుద్ధరించండి.',
      'exportBackup': 'బ్యాకప్ ఎగుమతి', 'importBackup': 'బ్యాకప్ దిగుమతి',
      'exportChoose': 'బ్యాకప్ ఫైల్ సేవ్ చేయడానికి యాప్ ఎంచుకోండి.', 'restoreSuccess': 'డేటా విజయవంతంగా పునరుద్ధరించబడింది!',
      'humanReadable': 'చదవగల స్ప్రెడ్‌షీట్‌లు', 'exportSpreadsheet': 'స్ప్రెడ్‌షీట్ మరియు నోట్స్ ఎగుమతి చేయి',
      'spreadsheetExported': 'స్ప్రెడ్‌షీట్ మరియు నోట్స్ ఎగుమతి అయ్యాయి!', 'exportFailed': 'ఎగుమతి విఫలం',
      'cloudBackup': 'Google Drive బ్యాకప్', 'premiumSub': 'ప్రీమియం సభ్యత్వం',
      'taranukoola': 'తారానుకూల', 'taraResults': 'తారానుకూల ఫలితాలు',
      'onePerson': '1 వ్యక్తి', 'twoPersons': '2 వ్యక్తులు',
      'excludeBadNak': 'అశుభ నక్షత్రం మినహాయించు', 'selectNakHint': 'జన్మ నక్షత్రం ఎంచుకోండి',
      'yourBirthNak': 'మీ జన్మ నక్షత్రాన్ని ఎంచుకోండి:', 'person1BirthNak': 'వ్యక్తి 1 జన్మ నక్షత్రం:', 'person2BirthNak': 'వ్యక్తి 2 జన్మ నక్షత్రం:',
      'goodDay': 'శుభ దినం', 'badDay': 'అశుభ దినం', 'goodBoth': 'ఇద్దరికీ శుభం', 'badBoth': 'ఇద్దరికీ అశుభం', 'goodOnePerson': 'ఒకరికి మాత్రమే శుభం',
      'selectedDayNak': 'ఎంచుకున్న రోజు నక్షత్రం', 'excludedNak': 'మినహాయించిన నక్షత్రం', 'person1': 'వ్యక్తి 1', 'person2': 'వ్యక్తి 2',
      'selectBothNak': 'ఫలితాలు చూడటానికి రెండు నక్షత్రాలను ఎంచుకోండి.',
      'taraChart': 'తారానుకూల చార్ట్', 'yourTaraChart': 'మీ తారానుకూల చార్ట్', 'person1TaraChart': 'వ్యక్తి 1 తారానుకూల చార్ట్', 'person2TaraChart': 'వ్యక్తి 2 తారానుకూల చార్ట్',
      'dayPanchanga': 'రోజు పంచాంగం', 'muhurtaRules': 'ముహూర్త నియమాలు', 'yourBalas': 'మీ బలాలు', 'personBalas': 'బలాలు',
      'createAppt': 'అపాయింట్‌మెంట్ రూపొందించు', 'clientName': 'గ్రాహకుడి పేరు', 'minutes': 'నిమిషాలు', 'create': 'రూపొందించు',
      'apptAdded': 'Calendar కు అపాయింట్‌మెంట్ చేర్చబడింది!', 'apptFailed': 'అపాయింట్‌మెంట్ విఫలం',
      'horoscope': 'జాతక విశ్లేషణ', 'matchMakingTitle': 'గుణ మిలనం',
      'trialExpired': 'ఉచిత ప్రయోగ అవధి ముగిసింది', 'subBenefits': 'చందాదారికె ప్రయోజనాలు',
      'allKundali': 'అన్ని కుండలి విశేషతలు', 'panchangaTara': 'పంచాంగం మరియు తారానుకూల',
      'mantraCollection': 'మంత్ర సంగ్రహం', 'dataBackup': 'మీ డేటా సురక్షిత బ్యాకప్ (Data Backup)',
      'subFailed': 'చందాదారికె ప్రక్రియ విఫలం.', 'subPrice': '₹700 / సంవత్సరానికి చందా',
      'restoreDone': 'మునుపటి కొనుగోళ్ళు పునరుద్ధరించబడింది.', 'restorePurchase': 'మునుపటి కొనుగోళ్ళు పునరుద్ధరించు (Restore)',
      'recentKundalis': 'ఇటీవల కుండలిలు', 'clearHistory': 'చరిత్ర తొలగించు',
      'clearHistoryConfirm': 'అన్ని చరిత్ర తొలగించాలా?',
      'historyEmpty': 'చరిత్ర ఖాళీ', 'historyHint': 'కుండలి రూపొందించినప్పుడు ఇక్కడ కనిపిస్తుంది',
      'now': 'ఇప్పుడు', 'ago': 'క్రితం', 'saved': 'సేవ్ చేయబడింది',
      'kundaliCount': 'కుండలి', 'checkInternet': 'మీ చందా చెక్ చేయడానికి ఇంటర్నెట్ కనెక్ట్ చేయండి.',
      'addPerson': 'వ్యక్తిని చేర్చు', 'addNewPerson': 'కొత్త వ్యక్తిని చేర్చు', 'newPersonHint': 'కొత్త జాతక వివరాలు నమోదు చేయండి',
      'addFromSaved': 'సేవ్ చేసిన దాని నుండి చేర్చు', 'savedListHint': 'సేవ్ చేసిన / అపాయింట్‌మెంట్ జాబితా',
      'close': 'మూసివేయి', 'selectSavedProfile': 'సేవ్ చేసిన జాతకం ఎంచుకోండి', 'noOtherProfiles': 'ఇతర ప్రొఫైల్‌లు లేవు',
      'back': 'వెనక్కి', 'calcInProgress': 'కుండలి లెక్కించబడుతోంది...', 'calcFailed': 'కుండలి గణన విఫలం',
      'newPerson': 'కొత్త వ్యక్తి', 'nameLabel': 'పేరు', 'dateLabel': 'తేదీ', 'timeLabel': 'సమయం',
      'latLabel': 'అక్షాంశం', 'lonLabel': 'రేఖాంశం',
      'enterName': 'దయచేసి పేరు నమోదు చేయండి',
      'calcSuccess': 'కుండలి విజయవంతంగా రూపొందించబడింది', 'editPerson': 'వ్యక్తిని మార్చు',
      'placeNotFoundDash': 'ప్రదేశం కనుగొనబడలేదు.', 'placeError': 'ప్రదేశ కనెక్షన్ లోపం.',
      'aroodhaLabel': 'ఆరూఢం', 'rashiLabel': 'రాశి', 'addLabel': 'చేర్చు', 'clearLabel': 'తొలగించు',
      'prastuta': 'ప్రస్తుతం', 'grahaSphuta': 'గ్రహ స్ఫుటం',
      'hGraha': 'గ్రహం', 'hRashi': 'రాశి', 'hSphuta': 'స్ఫుటం', 'hNakPada': 'నక్షత్రం - పాదం',
      'grahaVishlesha': 'గ్రహ విశ్లేషణ', 'hBhava': 'భావం', 'hD3': 'ది/నై', 'hD2': 'హో', 'hD9': 'న', 'hD30': 'త్రింశ', 'hD12': 'ద్వాద', 'hKshetra': 'క్షేత్రం',
      'pHeading': 'పంచాంగం', 'varaLabel': 'వారం', 'tithiLabel': 'తిథి',
      'chandraNakshatra': 'చంద్ర నక్షత్రం', 'padaLabel': 'పాదం',
      'yogaLabel': 'యోగం', 'karanaLabel': 'కరణం', 'chandraRashiLabel': 'చంద్ర రాశి',
      'suryaNakshatraLabel': 'సూర్య నక్షత్రం',
      'udayadiGhati': 'ఉదయాది ఘటి',
      'gataGhati': 'గత ఘటి', 'sheshaGhati': 'శేష ఘటి', 'lagna': 'లగ్నం',
      'placeLabel': 'ప్రదేశం', 'dashaLord': 'దశా నాథుడు', 'dashaBalance': 'శేషం',
      'shadvarga': 'షడ్వర్గం', 'bhavaKaksha': 'భావ కక్ష గ్రహ విశ్లేషణ',
      'bhavaRecalc': 'భావ మధ్య లగ్నం', 'bhavaRecalcFor': 'భావ మధ్య లగ్నం',
      'bhavaSelect': 'గ్రహం ఎంచుకోండి', 'bhavaReset': 'మూలం',
      'hBhavaNo': 'భావం', 'hBhavaStart': 'భావ ఆరంభం', 'hBhavaMid': 'భావ మధ్యం', 'hBhavaEnd': 'భావ అంతం',
    },
    'ml': {
      'appName': 'ഭാരതീയം', 'home': 'ഹോം', 'kundali': 'ജാതകം', 'panchanga': 'പഞ്ചാംഗം',
      'planets': 'ഗ്രഹങ്ങൾ', 'appointment': 'അപ്പോയിന്റ്‌മെന്റ്', 'vedicClock': 'വേദ ഘടികാരം',
      'settings': 'ക്രമീകരണം', 'aboutUs': 'ഞങ്ങളെക്കുറിച്ച്', 'language': 'ഭാഷ / Language',
      'name': 'പേര്', 'dob': 'ജനന തീയതി', 'time': 'ജനന സമയം', 'place': 'ജനന സ്ഥലം',
      'calculate': 'കണക്കാക്കുക', 'selectDate': 'തീയതി തിരഞ്ഞെടുക്കുക', 'selectTime': 'സമയം തിരഞ്ഞെടുക്കുക',
      'save': 'സേവ്', 'delete': 'ഇല്ലാതാക്കുക', 'cancel': 'റദ്ദാക്കുക', 'share': 'പങ്കിടുക',
      'yes': 'അതെ', 'no': 'ഇല്ല', 'chart': 'ജാതകം', 'sphuta': 'സ്ഫുടം', 'bhava': 'ഭാവം',
      'dasha': 'ദശ', 'aroodha': 'ആരൂഢം', 'notes': 'കുറിപ്പുകൾ',
      'sunrise': 'സൂര്യോദയം', 'sunset': 'സൂര്യാസ്തമയം', 'searchPlace': 'സ്ഥലം തിരയുക',
      'noResults': 'ഫലങ്ങൾ ഇല്ല', 'deleteConfirm': 'ഇല്ലാതാക്കണോ?', 'noBtn': 'വേണ്ട',
      'errorLabel': 'പിശക്', 'retryBtn': 'വീണ്ടും ശ്രമിക്കുക',
      'tithi': 'തിഥി', 'vara': 'വാരം', 'nakshatra': 'നക്ഷത്രം', 'yoga': 'യോഗം', 'karana': 'കരണം',
      'chandraNak': 'ചന്ദ്ര നക്ഷത്രം', 'suryaNak': 'സൂര്യ നക്ഷത്രം', 'pada': 'പാദം',
      'chandraRashi': 'ചന്ദ്ര രാശി', 'chandraMasa': 'ചന്ദ്ര മാസം',
      'souraMasa': 'സൗര മാസം', 'souraMasaGataDina': 'സൗര മാസ ഗത ദിനം',
      'samvatsara': 'സംവത്സരം', 'ayana': 'അയനം', 'rutu': 'ഋതു',
      'divamana': 'പകൽ സമയം', 'ratrimana': 'രാത്രി സമയം',
      'rahuKala': 'രാഹു കാലം', 'gulikaKala': 'ഗുളിക കാലം', 'yamaKala': 'യമഗണ്ഡ കാലം',
      'surya': 'സൂര്യൻ', 'chandra': 'ചന്ദ്രൻ', 'kala': 'കാലം',
      'selectDateLabel': 'തീയതി തിരഞ്ഞെടുക്കുക', 'today': 'ഇന്ന്', 'sthala': 'സ്ഥലം', 'dinanka': 'തീയതി',
      'mars': 'ചൊവ്വ', 'mercury': 'ബുധൻ', 'jupiter': 'ഗുരു', 'venus': 'ശുക്രൻ', 'saturn': 'ശനി', 'rahu': 'രാഹു', 'ketu': 'കേതു',
      'all': 'എല്ലാം', 'start': 'ആരംഭം', 'end': 'അവസാനം', 'continues': 'അടുത്ത വർഷം വരെ',
      'transits': 'സഞ്ചാരം', 'vakri': 'വക്രം', 'asta': 'അസ്തം',
      'ghati': 'ഘടി', 'vighati': 'വിഘടി', 'anuVighati': 'അനുവിഘടി',
      'ghatiLabel': 'ഘടി    വിഘടി   അനുവിഘടി',
      'udaya': 'ഉദയം',
      'ayanamsa': 'അയനാംശം', 'nodeType': 'രാഹു വിധം',
      'selectAllDetails': 'ദയവായി എല്ലാ വിവരങ്ങളും തിരഞ്ഞെടുക്കുക', 'selectHint': 'തിരഞ്ഞെടുക്കുക',
      'matchPoor': 'പൊരുത്തം നന്നായില്ല', 'matchMedium': 'പൊരുത്തം മധ്യമം', 'matchGood': 'പൊരുത്തം നന്നായിട്ടുണ്ട്',
      'matchResult': 'അഷ്ടകൂട ഗുണ മിലനം ഫലം', 'totalGuna': 'മൊത്തം ഗുണം', 'result': 'ഫലം',
      'brideDetails': 'വധൂ വിവരങ്ങൾ', 'groomDetails': 'വരൻ വിവരങ്ങൾ', 'checkMatch': 'പൊരുത്തം പരിശോധിക്കുക',
      'referenceShloka': 'ആധാര ശ്ലോകം:', 'rule': 'നിയമം:', 'source': 'മൂലം: ',
      'themeSettings': 'തീം സെറ്റിങ്ങ്സ്', 'defaultLocation': 'ഇയൽപ്പു സ്ഥലം',
      'locationHint': 'പഞ്ചാംഗ മറ്റും വൈദിക ഘടികാരത്തിനു ഉപയോഗിക്കുന്നു',
      'themeLight': 'സ്റ്റാൻഡേർഡ് ലൈറ്റ്', 'themeDark': 'ഡാർക്ക് മോഡ്', 'themeGold': 'സ്വർണ', 'themeOcean': 'സാഗർ', 'themeGreen': 'പച്ച',
      'chartStyle': 'ജാതക ശൈലി', 'southIndian': 'ദക്ഷിണ ഭാരതം', 'northIndian': 'ഉത്തര ഭാരതം',
      'southDesc': '4×4 ഗ്രിഡ് - രാശി സ്ഥിരം, ഗ്രഹങ്ങൾ ചലിക്കുന്നു', 'northDesc': 'വജ്രം (Diamond) - ഭാവം സ്ഥിരം, രാശികൾ ചലിക്കുന്നു',
      'searchLocation': 'സ്ഥലം തിരയുക', 'onlineSearch': 'ഓൺലൈൻ തിരയൽ', 'defaultLocationSet': 'ഇയൽപ്പു സ്ഥലം',
      'googleSyncActive': 'Google സിങ്ക് സജീവം', 'signInForCloud': 'ക്ലൗഡ് ബാക്കപ്പിനായി Google ൽ സൈൻ ഇൻ ചെയ്യുക',
      'signInSuccess': 'Google Sign In വിജയം!', 'signInFailed': 'Sign In പരാജയം',
      'migrateDevice': 'ഉപകരണം മാറ്റുക', 'migrateConfirm': 'ഉപകരണം മാറ്റണോ?',
      'migrateMsg': 'ഈ ഉപകരണത്തെ നിങ്ങളുടെ പ്രാഥമിക ഉപകരണമായി സെറ്റ് ചെയ്യും. മറ്റ് ഉപകരണത്തിൽ ഈ അക്കൗണ്ട് ബ്ലോക്ക് ആകും.',
      'yesChange': 'അതെ, മാറ്റുക', 'migrateSuccess': 'ഉപകരണം വിജയകരമായി മാറ്റി!', 'failed': 'പരാജയം',
      'backupRestore': 'ഡാറ്റ ബാക്കപ്പ് & പുനഃസ്ഥാപനം', 'backupDesc': 'നിങ്ങളുടെ എല്ലാ ഡാറ്റയും ബാക്കപ്പ് ചെയ്ത് പുതിയ ഉപകരണത്തിൽ പുനഃസ്ഥാപിക്കുക.',
      'exportBackup': 'ബാക്കപ്പ് എക്സ്പോർട്ട്', 'importBackup': 'ബാക്കപ്പ് ഇമ്പോർട്ട്',
      'exportChoose': 'ബാക്കപ്പ് ഫയൽ സേവ് ചെയ്യാൻ ആപ്പ് തിരഞ്ഞെടുക്കുക.', 'restoreSuccess': 'ഡാറ്റ വിജയകരമായി പുനഃസ്ഥാപിച്ചു!',
      'humanReadable': 'വായിക്കാവുന്ന സ്പ്രെഡ്ഷീറ്റുകൾ', 'exportSpreadsheet': 'സ്പ്രെഡ്ഷീറ്റ് & കുറിപ്പുകൾ എക്സ്പോർട്ട് ചെയ്യുക',
      'spreadsheetExported': 'സ്പ്രെഡ്ഷീറ്റ് & കുറിപ്പുകൾ എക്സ്പോർട്ട് ചെയ്തു!', 'exportFailed': 'എക്സ്പോർട്ട് പരാജയം',
      'cloudBackup': 'Google Drive ബാക്കപ്പ്', 'premiumSub': 'പ്രീമിയം സബ്സ്ക്രിപ്ഷൻ',
      'taranukoola': 'താരാനുകൂല', 'taraResults': 'താരാനുകൂല ഫലങ്ങൾ',
      'onePerson': '1 വ്യക്തി', 'twoPersons': '2 വ്യക്തികൾ',
      'excludeBadNak': 'അശുഭ നക്ഷത്രം ഒഴിവാക്കുക', 'selectNakHint': 'ജന്മ നക്ഷത്രം തിരഞ്ഞെടുക്കുക',
      'yourBirthNak': 'നിങ്ങളുടെ ജന്മ നക്ഷത്രം തിരഞ്ഞെടുക്കുക:', 'person1BirthNak': 'വ്യക്തി 1 ജന്മ നക്ഷത്രം:', 'person2BirthNak': 'വ്യക്തി 2 ജന്മ നക്ഷത്രം:',
      'goodDay': 'ശുഭ ദിനം', 'badDay': 'അശുഭ ദിനം', 'goodBoth': 'ഇരുവർക്കും ശുഭം', 'badBoth': 'ഇരുവർക്കും അശുഭം', 'goodOnePerson': 'ഒരാൾക്ക് മാത്രം ശുഭം',
      'selectedDayNak': 'തിരഞ്ഞെടുത്ത ദിവസത്തിന്റെ നക്ഷത്രം', 'excludedNak': 'ഒഴിവാക്കിയ നക്ഷത്രം', 'person1': 'വ്യക്തി 1', 'person2': 'വ്യക്തി 2',
      'selectBothNak': 'ഫലങ്ങൾ കാണാൻ രണ്ട് നക്ഷത്രങ്ങളും തിരഞ്ഞെടുക്കുക.',
      'taraChart': 'താരാനുകൂല ചാർട്ട്', 'yourTaraChart': 'നിങ്ങളുടെ താരാനുകൂല ചാർട്ട്', 'person1TaraChart': 'വ്യക്തി 1 താരാനുകൂല ചാർട്ട്', 'person2TaraChart': 'വ്യക്തി 2 താരാനുകൂല ചാർട്ട്',
      'dayPanchanga': 'ദിവസ പഞ്ചാംഗം', 'muhurtaRules': 'മുഹൂർത്ത നിയമങ്ങൾ', 'yourBalas': 'നിങ്ങളുടെ ബലങ്ങൾ', 'personBalas': 'ബലങ്ങൾ',
      'createAppt': 'അപ്പോയിന്റ്മെന്റ് സൃഷ്ടിക്കുക', 'clientName': 'വാടിക്കാരന്റെ പേര്', 'minutes': 'മിനിറ്റ്', 'create': 'സൃഷ്ടിക്കുക',
      'apptAdded': 'Calendar ലേക്ക് അപ്പോയിന്റ്മെന്റ് ചേർത്തു!', 'apptFailed': 'അപ്പോയിന്റ്മെന്റ് പരാജയം',
      'horoscope': 'ജാതക വിശ്ലേഷണം', 'matchMakingTitle': 'പൊരുത്തം',
      'trialExpired': 'ഉചിത പരീക്ഷണ കാലാവധി കഴിഞ്ഞു', 'subBenefits': 'സബ്‌സ്‌ക്രിപ്ഷൻ പ്രയോജനങ്ങൾ',
      'allKundali': 'എല്ലാ ജാതക വിശേഷതകൾ', 'panchangaTara': 'പഞ്ചാംഗം മറ്റും താരാനുകൂല',
      'mantraCollection': 'മന്ത്ര സംഗ്രഹം', 'dataBackup': 'നിങ്ങളുടെ ഡാറ്റ സുരക്ഷിത ബാക്കപ്പ് (Data Backup)',
      'subFailed': 'സബ്‌സ്‌ക്രിപ്ഷൻ പ്രക്രിയ പരാജയം.', 'subPrice': '₹700 / വർഷത്തിന് സബ്‌സ്‌ക്രിപ്ഷൻ',
      'restoreDone': 'മുമ്പത്തെ വാങ്ങലുകൾ പുനഃസ്ഥാപിച്ചു.', 'restorePurchase': 'മുമ്പത്തെ വാങ്ങലുകൾ പുനഃസ്ഥാപിക്കുക (Restore)',
      'recentKundalis': 'ഇത്തീഞ്ഞത്തെ ജാതകങ്ങൾ', 'clearHistory': 'ചരിത്രം മായ്ക്കുക',
      'clearHistoryConfirm': 'എല്ലാ ചരിത്രവും മായ്ക്കണോ?',
      'historyEmpty': 'ചരിത്രം ഖാലി', 'historyHint': 'ജാതകം സൃഷ്ടിക്കുമ്പോൾ ഇവിടെ കാണും',
      'now': 'ഇപ്പോൾ', 'ago': 'മുമ്പ്', 'saved': 'സേവ് ചെയ്തു',
      'kundaliCount': 'ജാതകം', 'checkInternet': 'സബ്‌സ്‌ക്രിപ്ഷൻ ചെക്ക് ചെയ്യാൻ ഇന്റർനെറ്റ് കണക്ട് ചെയ്യുക.',
      'addPerson': 'വ്യക്തിയെ ചേർക്കുക', 'addNewPerson': 'പുതിയ വ്യക്തിയെ ചേർക്കുക', 'newPersonHint': 'പുതിയ ജാതക വിവരം നൽകുക',
      'addFromSaved': 'സേവ് ചെയ്തതിൽ നിന്ന് ചേർക്കുക', 'savedListHint': 'സേവ് ചെയ്ത / അപ്പോയിന്റ്മെന്റ് ലിസ്റ്റ്',
      'close': 'അടയ്ക്കുക', 'selectSavedProfile': 'സേവ് ചെയ്ത ജാതകം തിരഞ്ഞെടുക്കുക', 'noOtherProfiles': 'മറ്റ് പ്രൊഫൈലുകൾ ഇല്ല',
      'back': 'പിന്നിലേക്ക്', 'calcInProgress': 'ജാതകം കണക്കാക്കുന്നു...', 'calcFailed': 'ജാതക ഗണന പരാജയം',
      'newPerson': 'പുതിയ വ്യക്തി', 'nameLabel': 'പേര്', 'dateLabel': 'തീയതി', 'timeLabel': 'സമയം',
      'latLabel': 'അക്ഷാംശം', 'lonLabel': 'രേഖാംശം',
      'enterName': 'ദയവായി പേര് നൽകുക',
      'calcSuccess': 'ജാതകം വിജയകരമായി സൃഷ്ടിച്ചു', 'editPerson': 'വ്യക്തിയെ മാറ്റുക',
      'placeNotFoundDash': 'സ്ഥലം കണ്ടെത്തിയില്ല.', 'placeError': 'സ്ഥല കണക്ഷൻ പിശക്.',
      'aroodhaLabel': 'ആരൂഢം', 'rashiLabel': 'രാശി', 'addLabel': 'ചേർക്കുക', 'clearLabel': 'മായ്ക്കുക',
      'prastuta': 'നിലവിലെ', 'grahaSphuta': 'ഗ്രഹ സ്ഫുടം',
      'hGraha': 'ഗ്രഹം', 'hRashi': 'രാശി', 'hSphuta': 'സ്ഫുടം', 'hNakPada': 'നക്ഷത്രം - പാദം',
      'grahaVishlesha': 'ഗ്രഹ വിശകലനം', 'hBhava': 'ഭാവം', 'hD3': 'ദി/നൈ', 'hD2': 'ഹോ', 'hD9': 'ന', 'hD30': 'ത്രിംശ', 'hD12': 'ദ്വാദ', 'hKshetra': 'ക്ഷേത്രം',
      'pHeading': 'പഞ്ചാംഗം', 'varaLabel': 'വാരം', 'tithiLabel': 'തിഥി',
      'chandraNakshatra': 'ചന്ദ്ര നക്ഷത്രം', 'padaLabel': 'പാദം',
      'yogaLabel': 'യോഗം', 'karanaLabel': 'കരണം', 'chandraRashiLabel': 'ചന്ദ്ര രാശി',
      'suryaNakshatraLabel': 'സൂര്യ നക്ഷത്രം',
      'udayadiGhati': 'ഉദയാദി ഘടി',
      'gataGhati': 'ഗത ഘടി', 'sheshaGhati': 'ശേഷ ഘടി', 'lagna': 'ലഗ്നം',
      'placeLabel': 'സ്ഥലം', 'dashaLord': 'ദശാ നാഥൻ', 'dashaBalance': 'ശേഷം',
      'shadvarga': 'ഷഡ്‌വർഗം', 'bhavaKaksha': 'ഭാവ കക്ഷ ഗ്രഹ വിശകലനം',
      'bhavaRecalc': 'ഭാവ മധ്യ ലഗ്നം', 'bhavaRecalcFor': 'ഭാവ മധ്യ ലഗ്നം',
      'bhavaSelect': 'ഗ്രഹം തിരഞ്ഞെടുക്കുക', 'bhavaReset': 'മൂലം',
      'hBhavaNo': 'ഭാവം', 'hBhavaStart': 'ഭാവ ആരംഭം', 'hBhavaMid': 'ഭാവ മധ്യം', 'hBhavaEnd': 'ഭാവ അന്ത്യം',
    },
  };

  /// Pass-through -- no translation
  static String tr(String text) => text;
}

/// Shorthand global function -- just returns text as-is
String tr(String text) => text;


Color kPurple1 = AppThemes.palettes[0]['purple1']!;
Color kPurple2 = AppThemes.palettes[0]['purple2']!;
Color kOrange  = const Color(0xFFDD6B20);
Color kOrange2 = const Color(0xFFC05621);
Color kTeal    = const Color(0xFF319795);
Color kGreen   = const Color(0xFF047857);
Color kBg      = AppThemes.palettes[0]['bg']!;
Color kCard    = AppThemes.palettes[0]['card']!;
Color kBorder  = AppThemes.palettes[0]['border']!;
Color kText    = AppThemes.palettes[0]['text']!;
Color kMuted   = AppThemes.palettes[0]['muted']!;

// ─────────────────────────────────────────────
// Responsive helpers
// ─────────────────────────────────────────────
bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600;

/// Wraps content with a max-width constraint on tablets.
/// On mobile, renders child full-width. On tablets, centers
/// child with maxWidth (default 600px).
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 600});

  @override
  Widget build(BuildContext context) {
    if (!isTablet(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}


// ─────────────────────────────────────────────
// Header widget (purple gradient banner)
// ─────────────────────────────────────────────
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPurple1, kPurple2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPurple2.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
        border: const Border(bottom: BorderSide(color: Color(0xFFF6D365), width: 4)),
      ),
      child: Center(
        child: Text(
          'ಭಾರತೀಯಮ್',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card wrapper
// ─────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const AppCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String text;
  final Color? color;
  SectionTitle(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: color ?? kPurple2,
        ),
      ),
    );
  }
}
