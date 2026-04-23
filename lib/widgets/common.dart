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
