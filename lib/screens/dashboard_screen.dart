import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/export_service.dart';
import '../core/calculator.dart';
import '../core/yoga_engine.dart';
import '../core/prediction_engine.dart';
import '../constants/strings.dart';
import '../widgets/common.dart';
import '../widgets/kundali_chart.dart';
import '../widgets/planet_detail_sheet.dart';
import '../widgets/dasha_widget.dart';
import '../widgets/shadbala_widget.dart';
import '../widgets/ashtakavarga_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart';
import '../services/client_service.dart'; // FIX: Imported missing ClientService
import '../services/history_service.dart';
import '../services/app_access_service.dart';
import '../services/google_auth_service.dart';
import '../services/sheets_service.dart';
import '../services/docs_service.dart';
import '../services/calendar_service.dart';
import '../services/location_service.dart';
import '../services/janma_patrike_service.dart'; // NEW
import '../services/tippani_pdf_service.dart';
import '../services/pdf_theme.dart';
import '../constants/places.dart';
import '../services/timezone_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweph/sweph.dart' hide kIsWeb;
import '../core/ephemeris.dart';
import '../core/transit_cache.dart';
import '../core/transit_calculator.dart';
import '../widgets/date_time_input.dart';

class DashboardScreen extends StatefulWidget {
  final KundaliResult result;
  final String name;
  final String place;
  final DateTime dob;
  final int hour;
  final int minute;
  final String ampm;
  final double lat;
  final double lon;
  final double tz;
  final String initialNotes;
  final Map<String, int> initialAroodhas;
  final int? initialJanmaNakshatraIdx;
  final String? initialPrastutaTime; // ISO8601 — restored from saved profile
  final Map<String, String> extraInfo;
  final List<String> initialGroupMembers;
  final List<PersonEntry> initialExtraPersons;
  final void Function(String notes, Map<String, int> aroodhas, int? janmaNakshatraIdx, {bool isNew}) onSave;

  const DashboardScreen({
    super.key,
    required this.result,
    required this.name,
    required this.place,
    required this.dob,
    required this.hour,
    required this.minute,
    required this.ampm,
    required this.lat,
    required this.lon,
    required this.tz,
    this.initialNotes = '',
    this.initialAroodhas = const {},
    this.initialJanmaNakshatraIdx,
    this.initialPrastutaTime,
    this.extraInfo = const {},
    this.initialGroupMembers = const [],
    this.initialExtraPersons = const [],
    required this.onSave,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class PersonEntry {
  final String name;
  final KundaliResult result;
  final DateTime dob;
  final int hour;
  final int minute;
  final String ampm;
  final double lat;
  final double lon;
  final double tz;
  final String place;
  String notes;

  PersonEntry({
    required this.name,
    required this.result,
    required this.dob,
    required this.hour,
    required this.minute,
    required this.ampm,
    required this.lat,
    required this.lon,
    required this.tz,
    required this.place,
    this.notes = '',
  });
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabCtrl;
  String _notes = '';
  final _newNoteController = TextEditingController();
  int _resumeKey = 0; // Incremented on app resume to force full repaint
  Map<String, int> _aroodhas = {};
  int? _janmaNakshatraIdx;
  int? _dinaNakshatraIdx;
  String? _bhavaPlanet; // planet selected for bhava recalculation
  KundaliResult? _prastutaResult; // For Aroodha tab's Prastuta button
  DateTime? _prastutaTime; // Time used for prastuta chart
  
  // Janma Patrike states
  final _fatherNameCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _gotraCtrl = TextEditingController();
  final _jyotishiNameCtrl = TextEditingController();
  final _jyotishiPhoneCtrl = TextEditingController();
  String _selectedThemeId = 'traditional';
  String _selectedGender = 'male';
  List<bool> _pdfPageSelection = [true, true, true, true, true, true, true]; // 7 pages
  String _patrikeFormat = 'detailed'; // 'detailed' or 'traditional'
  bool _phalaDisclaimerShown = false; // show warning only once per session

  // Tippani PDF fields
  final _tippaniInvocationCtrl = TextEditingController(text: 'ಶ್ರೀ ಗಣೇಶಾಯ ನಮಃ');
  final _tippaniAddressCtrl = TextEditingController();


  // Multi-person support
  final List<PersonEntry> _extraPersons = [];
  Set<int> _selectedPersonIndices = {}; // empty = show all, otherwise show selected indices
  int _selectedChartIdx = 0;  // which chart type is selected (0 = Rashi, 1 = Navamsha, ...)

  // Mutable primary person (editable)
  late String _primaryName;
  late KundaliResult _primaryResult;
  late DateTime _primaryDob;
  late int _primaryHour;
  late int _primaryMinute;
  late String _primaryAmpm;
  late double _primaryLat;
  late double _primaryLon;
  late double _primaryTz;
  late String _primaryPlace;

  bool _syncing = false;
  int _gocharYear = DateTime.now().year;
  bool _dashaHighlightEnabled = true;
  bool _landscapeBarsVisible = true; // Landscape: show/hide tab bar + person selector

  /// Translate dasha balance suffixes (ವ=years, ತಿ=months, ದಿ=days)
  String _trDashaBalance(String bal) {
    if (AppLocale.current == 'kn') return bal;
    const suffixes = {
      'hi': {'ವ': 'व', 'ತಿ': 'म', 'ದಿ': 'दि'},
      'ta': {'ವ': 'வ', 'ತಿ': 'மா', 'ದಿ': 'நா'},
      'te': {'ವ': 'సం', 'ತಿ': 'నె', 'ದಿ': 'రో'},
      'ml': {'ವ': 'വ', 'ತಿ': 'മാ', 'ದಿ': 'ദി'},
      'en': {'ವ': 'y', 'ತಿ': 'm', 'ದಿ': 'd'},
    };
    final map = suffixes[AppLocale.current];
    if (map == null) return bal;
    var result = bal;
    for (final entry in map.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }



  static List<String> get _tabs {
    switch (AppLocale.current) {
      case 'hi': return ['पंचांग', 'कुंडली', 'स्फुट', 'आरूढ', 'दशा', 'भाव', 'ग्रह षड्वर्ग', 'षड्बल', 'अष्टक', 'योग', 'फल', 'गोचर', 'टिप्पणी', 'पत्रिका'];
      case 'ta': return ['பஞ்சாங்கம்', 'ஜாதகம்', 'ஸ்புடம்', 'ஆரூடம்', 'தசை', 'பாவம்', 'ஷட்வர்கம்', 'ஷட்பலம்', 'அஷ்டகம்', 'யோகம்', 'பலன்', 'கோசாரம்', 'குறிப்பு', 'பத்ரிகை'];
      case 'te': return ['పంచాంగం', 'కుండలి', 'స్ఫుటం', 'ఆరూఢం', 'దశ', 'భావం', 'షడ్వర్గం', 'షడ్బలం', 'అష్టకం', 'యోగం', 'ఫలం', 'గోచారం', 'గమనికలు', 'పత్రిక'];
      case 'ml': return ['പഞ്ചാംഗം', 'ജാതകം', 'സ്ഫുടം', 'ആരൂഢം', 'ദശ', 'ഭാവം', 'ഷഡ്വർഗം', 'ഷഡ്ബലം', 'അഷ്ടകം', 'യോഗം', 'ഫലം', 'ഗോചരം', 'കുറിപ്പുകൾ', 'പത്രിക'];
      case 'en': return ['Panchanga', 'Kundali', 'Sphuta', 'Aroodha', 'Dasha', 'Bhava', 'Shadvarga', 'Shadbala', 'Ashtaka', 'Yoga', 'Phala', 'Gochara', 'Notes', 'Patrike'];
      default: return ['ಪಂಚಾಂಗ', 'ಕುಂಡಲಿ', 'ಸ್ಫುಟ', 'ಆರೂಢ', 'ದಶ', 'ಭಾವ', 'ಗ್ರಹ ಷಡ್ವರ್ಗ', 'ಷಡ್ಬಲ', 'ಅಷ್ಟಕ', 'ಯೋಗ', 'ಫಲ', 'ಗೋಚಾರ', 'ಟಿಪ್ಪಣಿ', 'ಪತ್ರಿಕೆ'];
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabCtrl = TabController(length: _tabs.length, vsync: this); // 11 tabs
    _notes = widget.initialNotes;
    _aroodhas = Map.from(widget.initialAroodhas);
    _janmaNakshatraIdx = widget.initialJanmaNakshatraIdx;
    // Restore prastuta time if saved
    if (widget.initialPrastutaTime != null) {
      _prastutaTime = DateTime.tryParse(widget.initialPrastutaTime!);
      if (_prastutaTime != null) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _openPrastutaChart(savedTime: _prastutaTime, silent: true);
        });
      }
    }

    // Initialize mutable primary person from widget
    _primaryName = widget.name;
    _primaryResult = widget.result;
    _primaryDob = widget.dob;
    _primaryHour = widget.hour;
    _primaryMinute = widget.minute;
    _primaryAmpm = widget.ampm;
    _primaryLat = widget.lat;
    _primaryLon = widget.lon;
    _primaryTz = widget.tz;
    _primaryPlace = widget.place;


    final panchangNakName = widget.result.panchang.nakshatra.split(' ')[0];
    int panchangNakIdx = knNak.indexWhere((n) => panchangNakName.startsWith(n));
    _dinaNakshatraIdx = panchangNakIdx != -1 ? panchangNakIdx : 0;

    _loadJanmaNakshatra();

    // Auto-load group members if saved previously
    if (widget.initialGroupMembers.isNotEmpty) {
      _loadGroupMembers();
    }

    // Load pre-computed extra persons (e.g., muhurta start/end time view)
    if (widget.initialExtraPersons.isNotEmpty) {
      _extraPersons.addAll(widget.initialExtraPersons);
    }

    _loadJyotishiDetails();
    _loadDashaHighlightPref();

    // Rebuild charts when chart mode toggles change
    SingleLetterMode.notifier.addListener(_onChartModeChanged);
    SamshakaMode.notifier.addListener(_onChartModeChanged);

    // Show phala disclaimer when user first opens Phala tab
    _tabCtrl.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabCtrl.indexIsChanging && _tabCtrl.index == 10 && !_phalaDisclaimerShown) {
      _phalaDisclaimerShown = true;
      Future.microtask(() => _showPhalaDisclaimer());
    }
  }

  void _showPhalaDisclaimer() {
    if (!mounted) return;
    const _disclaimerText = <String, Map<String, String>>{
      'title': {
        'kn': '⚠️ ಮುಖ್ಯ ಸೂಚನೆ',
        'hi': '⚠️ महत्वपूर्ण सूचना',
        'ta': '⚠️ முக்கிய அறிவிப்பு',
        'te': '⚠️ ముఖ్యమైన గమనిక',
        'ml': '⚠️ പ്രധാന അറിയിപ്പ്',
        'en': '⚠️ Important Notice',
      },
      'body': {
        'kn': 'ಇಲ್ಲಿ ತೋರಿಸಲಾದ ಫಲಗಳು ಶಾಸ್ತ್ರೀಯ ಗ್ರಂಥಗಳ ಆಧಾರದ ಮೇಲೆ ಸಾಮಾನ್ಯ ಮಾಹಿತಿಗಾಗಿ ಮಾತ್ರ ಒದಗಿಸಲಾಗಿದೆ. ಇವು ವೃತ್ತಿಪರ ಜ್ಯೋತಿಷ ಸಲಹೆಯ ಬದಲಿ ಅಲ್ಲ.\n\nಈ ಫಲಗಳನ್ನು ಬಳಸುವಾಗ ದಯವಿಟ್ಟು ನಿಮ್ಮ ಸ್ವಂತ ವಿವೇಚನೆ ಮತ್ತು ತಿಳುವಳಿಕೆಯನ್ನು ಬಳಸಿ. ಯಾವುದೇ ನಿರ್ಧಾರ ತೆಗೆದುಕೊಳ್ಳುವ ಮೊದಲು ಅನುಭವಿ ಜ್ಯೋತಿಷಿಯ ಮಾರ್ಗದರ್ಶನ ಪಡೆಯಿರಿ.\n\nಈ ಅಪ್ಲಿಕೇಶನ್ ಅಥವಾ ಅದರ ರಚನೆಕಾರರು ಈ ಫಲಗಳ ನಿಖರತೆಗೆ ಅಥವಾ ಇವುಗಳ ಆಧಾರದ ಮೇಲೆ ತೆಗೆದುಕೊಂಡ ನಿರ್ಧಾರಗಳಿಗೆ ಯಾವುದೇ ಜವಾಬ್ದಾರಿ ಹೊರುವುದಿಲ್ಲ.',
        'hi': 'यहाँ दिखाए गए फल शास्त्रीय ग्रंथों के आधार पर केवल सामान्य जानकारी के लिए प्रदान किए गए हैं। ये पेशेवर ज्योतिष सलाह का विकल्प नहीं हैं।\n\nइन फलों का उपयोग करते समय कृपया अपने स्वयं के विवेक और ज्ञान का उपयोग करें। कोई भी निर्णय लेने से पहले अनुभवी ज्योतिषी का मार्गदर्शन लें।\n\nयह एप्लिकेशन या इसके निर्माता इन फलों की सटीकता या इनके आधार पर लिए गए निर्णयों की कोई जिम्मेदारी नहीं लेते।',
        'ta': 'இங்கு காட்டப்படும் பலன்கள் சாஸ்திர நூல்களின் அடிப்படையில் பொதுவான தகவலுக்காக மட்டுமே வழங்கப்படுகின்றன. இவை தொழில்முறை ஜோதிட ஆலோசனைக்கு மாற்றாக இல்லை.\n\nஇந்த பலன்களைப் பயன்படுத்தும் போது உங்கள் சொந்த அறிவையும் விவேகத்தையும் பயன்படுத்தவும். எந்த முடிவும் எடுப்பதற்கு முன் அனுபவமுள்ள ஜோதிடரின் வழிகாட்டுதலைப் பெறவும்.\n\nஇந்த செயலி அல்லது அதன் உருவாக்குநர்கள் இந்த பலன்களின் துல்லியத்திற்கோ அல்லது இவற்றின் அடிப்படையில் எடுக்கப்படும் முடிவுகளுக்கோ எந்தப் பொறுப்பும் ஏற்க மாட்டார்கள்.',
        'te': 'ఇక్కడ చూపించబడిన ఫలాలు శాస్త్రీయ గ్రంథాల ఆధారంగా సాధారణ సమాచారం కోసం మాత్రమే అందించబడ్డాయి. ఇవి వృత్తిపరమైన జ్యోతిష సలహాకు ప్రత్యామ్నాయం కాదు.\n\nఈ ఫలాలను ఉపయోగించేటప్పుడు దయచేసి మీ స్వంత విచక్షణ మరియు జ్ఞానాన్ని ఉపయోగించండి. ఏదైనా నిర్ణయం తీసుకునే ముందు అనుభవజ్ఞుడైన జ్యోతిష్కుడి మార్గదర్శకత్వం తీసుకోండి.\n\nఈ అప్లికేషన్ లేదా దాని సృష్టికర్తలు ఈ ఫలాల ఖచ్చితత్వానికి లేదా వీటి ఆధారంగా తీసుకున్న నిర్ణయాలకు ఎటువంటి బాధ్యత వహించరు.',
        'ml': 'ഇവിടെ കാണിക്കുന്ന ഫലങ്ങൾ ശാസ്ത്രീയ ഗ്രന്ഥങ്ങളുടെ അടിസ്ഥാനത്തിൽ പൊതുവായ വിവരത്തിനായി മാത്രം നൽകിയിരിക്കുന്നു. ഇവ പ്രൊഫഷണൽ ജ്യോതിഷ ഉപദേശത്തിന് പകരമല്ല.\n\nഈ ഫലങ്ങൾ ഉപയോഗിക്കുമ്പോൾ ദയവായി നിങ്ങളുടെ സ്വന്തം വിവേകവും അറിവും ഉപയോഗിക്കുക. ഏതെങ്കിലും തീരുമാനം എടുക്കുന്നതിന് മുമ്പ് അനുഭവസമ്പന്നനായ ജ്യോതിഷിയുടെ മാർഗനിർദേശം തേടുക.\n\nഈ ആപ്ലിക്കേഷനോ അതിന്റെ നിർമ്മാതാക്കളോ ഈ ഫലങ്ങളുടെ കൃത്യതയ്ക്കോ ഇവയുടെ അടിസ്ഥാനത്തിൽ എടുക്കുന്ന തീരുമാനങ്ങൾക്കോ ഒരു ഉത്തരവാദിത്തവും വഹിക്കുന്നില്ല.',
        'en': 'The predictions shown here are provided for general informational purposes only, based on classical Jyotish texts. They are not a substitute for professional astrological consultation.\n\nPlease use your own discretion and judgment when interpreting these predictions. Consult an experienced astrologer before making any important decisions based on them.\n\nThis application and its creators do not take any responsibility for the accuracy of these predictions or for any decisions made based on them.',
      },
      'ok': {
        'kn': 'ನಾನು ಅರ್ಥಮಾಡಿಕೊಂಡಿದ್ದೇನೆ',
        'hi': 'मैं समझता/समझती हूँ',
        'ta': 'நான் புரிந்துகொண்டேன்',
        'te': 'నేను అర్థం చేసుకున్నాను',
        'ml': 'ഞാൻ മനസ്സിലാക്കി',
        'en': 'I Understand',
      },
    };
    final lang = AppLocale.current;
    final title = _disclaimerText['title']?[lang] ?? _disclaimerText['title']!['en']!;
    final body = _disclaimerText['body']?[lang] ?? _disclaimerText['body']!['en']!;
    final ok = _disclaimerText['ok']?[lang] ?? _disclaimerText['ok']!['en']!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Text(body, style: const TextStyle(fontSize: 13, height: 1.6)),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(ok, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDashaHighlightPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _dashaHighlightEnabled = prefs.getBool('highlight_dasha_lords') ?? true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    _newNoteController.dispose();
    _fatherNameCtrl.dispose();
    _motherNameCtrl.dispose();
    _gotraCtrl.dispose();
    _jyotishiNameCtrl.dispose();
    _jyotishiPhoneCtrl.dispose();
    _tippaniInvocationCtrl.dispose();
    _tippaniAddressCtrl.dispose();
    SingleLetterMode.notifier.removeListener(_onChartModeChanged);
    SamshakaMode.notifier.removeListener(_onChartModeChanged);
    super.dispose();
  }

  void _onChartModeChanged() {
    if (mounted) {
      final focus = FocusManager.instance.primaryFocus;
      if (focus != null && focus.context != null && focus.context!.widget is EditableText) return;
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lightweight repaint on resume — fixes blank charts without destroying widget tree
    // But skip if a TextField has focus (keyboard is open) to avoid dismissing it
    if (state == AppLifecycleState.resumed && mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          final focus = FocusManager.instance.primaryFocus;
          // Don't rebuild if user is typing in a text field — it would dismiss the keyboard
          if (focus != null && focus.context != null) {
            final ctx = focus.context!;
            final isEditing = ctx.widget is EditableText;
            if (isEditing) return;
          }
          setState(() {});
        }
      });
    }
  }
  Future<void> _loadJyotishiDetails() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      // TextEditingController.text setter already notifies listeners — no setState needed
      _jyotishiNameCtrl.text = prefs.getString('jyotishi_name') ?? prefs.getString('default_jyotishi_name') ?? '';
      _jyotishiPhoneCtrl.text = prefs.getString('jyotishi_phone') ?? prefs.getString('default_jyotishi_phone') ?? '';
      _tippaniInvocationCtrl.text = prefs.getString('tippani_invocation') ?? 'ಶ್ರೀ ಗಣೇಶಾಯ ನಮಃ';
      _tippaniAddressCtrl.text = prefs.getString('tippani_address') ?? prefs.getString('default_jyotishi_address') ?? '';
    }
  }

  Future<void> _saveJyotishiDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jyotishi_name', _jyotishiNameCtrl.text.trim());
    await prefs.setString('jyotishi_phone', _jyotishiPhoneCtrl.text.trim());
    await prefs.setString('tippani_invocation', _tippaniInvocationCtrl.text.trim());
    await prefs.setString('tippani_address', _tippaniAddressCtrl.text.trim());
  }

  /// Show simple 2-option dialog to add a person
  void _showAddPersonDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBg,
        title: Text(AppLocale.l('addPerson'), style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: kTeal.withOpacity(0.15),
                child: Icon(Icons.add, color: kTeal),
              ),
              title: Text(AppLocale.l('addNewPerson'), style: TextStyle(color: kTeal, fontWeight: FontWeight.w800)),
              subtitle: Text(AppLocale.l('newPersonHint'), style: TextStyle(color: kMuted, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showNewPersonForm();
              },
            ),
            Divider(color: kBorder),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: kPurple2.withOpacity(0.15),
                child: Icon(Icons.folder_open, color: kPurple2),
              ),
              title: Text(AppLocale.l('addFromSaved'), style: TextStyle(color: kPurple2, fontWeight: FontWeight.w800)),
              subtitle: Text(AppLocale.l('savedListHint'), style: TextStyle(color: kMuted, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showSavedProfilesListDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocale.l('close'), style: TextStyle(color: kMuted))),
        ],
      ),
    );
  }

  /// Show the combined list of saved profiles (StorageService + ClientService)
  void _showSavedProfilesListDialog() async {
    final storageProfilesResponse = await StorageService.loadAll();
    final allProfiles = storageProfilesResponse.values.toList();
    
    // Merge Appointment Members
    for (var client in ClientService.clients) {
      final members = ClientService.getMembersForClient(client.clientId);
      for (var m in members) {
        if (m.dob.isNotEmpty && m.birthTime.isNotEmpty && m.lat != 0) {
          // Unconditionally sync the Profile inside allProfiles to match the True Appointments Client ID!
          final index = allProfiles.indexWhere((p) => p.name == m.memberName);
          if (index == -1) {
            allProfiles.add(Profile(
              name: m.memberName,
              date: m.dob,
              hour: m.hour12,
              minute: m.minute,
              ampm: m.ampm,
              lat: m.lat,
              lon: m.lon,
              place: m.birthPlace,
              notes: m.notes,
              tzOffset: m.tzOffset,
              clientId: m.clientId,
            ));
          } else {
            final op = allProfiles[index];
            allProfiles[index] = Profile(
               name: op.name, date: op.date, hour: op.hour, minute: op.minute, ampm: op.ampm,
               lat: op.lat, lon: op.lon, tzOffset: op.tzOffset, place: op.place, notes: op.notes,
               aroodhas: op.aroodhas, janmaNakshatraIdx: op.janmaNakshatraIdx,
               clientId: m.clientId, // Force exact sync with Appointment Database
               groupMembers: op.groupMembers, // Preserve multi-person group!
            );
          }
        }
      }
    }

    if (!mounted) return;

    final otherProfiles = allProfiles
        .where((p) => p.name != widget.name)
        .where((p) => !_extraPersons.any((ep) => ep.name == p.name))
        .toList();

    // Sort ascending by Client ID ("BH-2026-0001", "BH-2026-0002" ...) so they display in exact serial order
    otherProfiles.sort((a, b) {
      final aId = a.clientId ?? '';
      final bId = b.clientId ?? '';
      if (aId.isEmpty && bId.isNotEmpty) return 1;
      if (aId.isNotEmpty && bId.isEmpty) return -1;
      return aId.compareTo(bId); // Ascending serial order
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBg,
        title: Text(AppLocale.l('selectSavedProfile'), style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: otherProfiles.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(AppLocale.l('noOtherProfiles'), textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherProfiles.length,
                  itemBuilder: (context, i) {
                    final p = otherProfiles[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kPurple2.withOpacity(0.15),
                        child: Text(p.name.isNotEmpty ? p.name[0] : '?', style: TextStyle(color: kPurple2, fontWeight: FontWeight.w900)),
                      ),
                      title: Text(p.name, style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
                      subtitle: Text('${p.date} | ${p.place}', style: TextStyle(color: kMuted, fontSize: 12)),
                      onTap: () => _addSavedProfile(ctx, p),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocale.l('back'), style: TextStyle(color: kMuted))),
        ],
      ),
    );
  }

  /// Add a saved profile as an extra person
  void _addSavedProfile(BuildContext ctx, Profile p) async {
    Navigator.pop(ctx);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('⏳ ${p.name} ${AppLocale.l('calcInProgress')}')),
    );
    try {
      final dateParts = p.date.split('-');
      final dob = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
      int h24 = p.hour;
      if (p.ampm == 'PM' && h24 != 12) h24 += 12;
      if (p.ampm == 'AM' && h24 == 12) h24 = 0;
      final localHour = h24 + p.minute / 60.0;
      final result = await AstroCalculator.calculate(
        year: dob.year, month: dob.month, day: dob.day,
        hourUtcOffset: p.tzOffset, hour24: localHour,
        lat: p.lat, lon: p.lon, ayanamsaMode: 'lahiri', trueNode: true,
      );
      if (result == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('calcFailed')}'), backgroundColor: Colors.red));
        return;
      }
      if (mounted) {
        setState(() {
          _extraPersons.add(PersonEntry(name: p.name, result: result, dob: dob, hour: p.hour, minute: p.minute, ampm: p.ampm, lat: p.lat, lon: p.lon, tz: p.tzOffset, place: p.place, notes: p.notes));
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
    }
  }

  /// Show form to add a brand new person
  void _showNewPersonForm() {
    final nameCtrl = TextEditingController();
    final placeCtrl = TextEditingController(text: LocationService.place);
    final latCtrl = TextEditingController(text: LocationService.lat.toStringAsFixed(4));
    final lonCtrl = TextEditingController(text: LocationService.lon.toStringAsFixed(4));
    final tzCtrl = TextEditingController(text: '${LocationService.tzOffset >= 0 ? '+' : ''}${LocationService.tzOffset}');
    
    DateTime dob = DateTime.now();
    int hour = dob.hour % 12 == 0 ? 12 : dob.hour % 12;
    int minute = dob.minute;
    String ampm = dob.hour >= 12 ? 'PM' : 'AM';
    
    bool geoLoading = false;
    String geoStatus = '';

    Future<void> performGeocode(String placeName, Function setS) async {
      if (placeName.trim().isEmpty) return;
      setS(() { geoLoading = true; geoStatus = ''; });
      try {
        final q = Uri.encodeComponent(placeName.trim());
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=1');
        final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as List;
          if (data.isEmpty) {
            setS(() => geoStatus = AppLocale.l('placeNotFoundDash'));
          } else {
            final lat = double.parse(data[0]['lat']);
            final lon = double.parse(data[0]['lon']);
            final displayName = data[0]['display_name'] as String;
            final autoTz = await getTimezoneForPlace(displayName, lat, lon, birthDate: dob);
            setS(() {
              placeCtrl.text = placeName.trim();
              latCtrl.text = lat.toStringAsFixed(4);
              lonCtrl.text = lon.toStringAsFixed(4);
              tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
              geoStatus = '📍 ${data[0]['display_name']} (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
            });
          }
        }
      } catch (_) {
        setS(() => geoStatus = AppLocale.l('placeError'));
      }
      setS(() => geoLoading = false);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
        return AlertDialog(
          backgroundColor: kBg,
          title: Text(AppLocale.l('newPerson'), style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocale.l('nameLabel'), prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 14),

                // Date input
                DateInputRow(
                  date: dob,
                  color: kPurple2,
                  onChanged: (d) => setS(() => dob = d),
                ),
                const SizedBox(height: 14),

                // Time input
                TimeInputRow(
                  hour: hour,
                  minute: minute,
                  ampm: ampm,
                  color: kPurple2,
                  onChanged: (h, m, a) => setS(() { hour = h; minute = m; ampm = a; }),
                ),
                const SizedBox(height: 14),

                // Searchable Place Selector
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return offlinePlaces.keys.take(15);
                    }
                    final query = textEditingValue.text.toLowerCase();
                    final offline = offlinePlaces.keys.where((name) => name.toLowerCase().contains(query)).toList();
                    if (worldCitiesLoaded) {
                      final worldResults = searchWorldCities(textEditingValue.text, limit: 15);
                      for (final w in worldResults) {
                        final label = worldCityLabel(w);
                        if (!offline.any((o) => o.toLowerCase() == label.toLowerCase())) {
                          offline.add(label);
                        }
                      }
                    }
                    return offline.take(20);
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    // Start with the Place populated, unlike input_screen which manages it via state
                    if (placeCtrl.text.isNotEmpty && textEditingController.text.isEmpty) {
                      textEditingController.text = placeCtrl.text;
                    }
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: AppLocale.l('searchPlace'),
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: geoLoading
                          ? Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(
                              icon: Icon(Icons.my_location, color: kTeal),
                              onPressed: () {
                                placeCtrl.text = textEditingController.text;
                                performGeocode(textEditingController.text, setS);
                              },
                            ),
                      ),
                      onSubmitted: (_) {
                        placeCtrl.text = textEditingController.text;
                        performGeocode(textEditingController.text, setS);
                      },
                      onChanged: (val) {
                        placeCtrl.text = val;
                      },
                    );
                  },
                  onSelected: (String selection) async {
                    if (offlinePlaces.containsKey(selection)) {
                      final coords = offlinePlaces[selection]!;
                      setS(() {
                        placeCtrl.text = selection;
                        latCtrl.text = coords[0].toStringAsFixed(4);
                        lonCtrl.text = coords[1].toStringAsFixed(4);
                        tzCtrl.text = '${coords[2] >= 0 ? '+' : ''}${coords[2]}';
                        geoStatus = '📍 $selection (TZ: ${coords[2] >= 0 ? '+' : ''}${coords[2]})';
                      });
                    } else {
                      final worldResults = searchWorldCities(selection.split(', ').first, limit: 1);
                      if (worldResults.isNotEmpty) {
                        final w = worldResults.first;
                        final lat = (w['la'] as num).toDouble();
                        final lon = (w['lo'] as num).toDouble();
                        final tz = (w['c'] != null)
                            ? getDstAwareOffset(w['c'] as String, lat, lon, dob)
                            : (w['tz'] as num).toDouble();
                        setS(() {
                          placeCtrl.text = selection;
                          latCtrl.text = lat.toStringAsFixed(4);
                          lonCtrl.text = lon.toStringAsFixed(4);
                          tzCtrl.text = '${tz >= 0 ? '+' : ''}$tz';
                          geoStatus = '📍 $selection (TZ: ${tz >= 0 ? '+' : ''}$tz)';
                        });
                      }
                    }
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 64),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.location_on, size: 18, color: kPurple2),
                                title: Text(option, style: TextStyle(fontSize: 13)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (geoStatus.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(geoStatus, style: TextStyle(fontSize: 12, color: kGreen)),
                ],
                const SizedBox(height: 14),

                Row(children: [
                  Expanded(child: TextField(controller: latCtrl, decoration: InputDecoration(labelText: AppLocale.l('latLabel'), isDense: true), keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: lonCtrl, decoration: InputDecoration(labelText: AppLocale.l('lonLabel'), isDense: true), keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: tzCtrl, decoration: const InputDecoration(labelText: 'TZ', isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocale.l('close'), style: TextStyle(color: kMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPurple2),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.l('enterName')), backgroundColor: Colors.red));
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⏳ $name ${AppLocale.l('calcInProgress')}')));
                try {
                  int h24 = hour;
                  if (ampm == 'PM' && h24 != 12) h24 += 12;
                  if (ampm == 'AM' && h24 == 12) h24 = 0;
                  final localHour = h24 + minute / 60.0;
                  final lat = double.tryParse(latCtrl.text) ?? 14.98;
                  final lon = double.tryParse(lonCtrl.text) ?? 74.73;
                  final tz = double.tryParse(tzCtrl.text) ?? 5.5;
                  
                  final result = await AstroCalculator.calculate(
                    year: dob.year, month: dob.month, day: dob.day,
                    hourUtcOffset: tz, hour24: localHour,
                    lat: lat, lon: lon, ayanamsaMode: 'lahiri', trueNode: true,
                  );
                  
                  if (result == null) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('calcFailed')}'), backgroundColor: Colors.red));
                    return;
                  }
                  
                  if (mounted) {
                    setState(() {
                      _extraPersons.add(PersonEntry(name: name, result: result, dob: dob, hour: hour, minute: minute, ampm: ampm, lat: lat, lon: lon, tz: tz, place: placeCtrl.text));
                    });
                    HistoryService.add(HistoryEntry(
                      name: name,
                      date: '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}',
                      hour: hour, minute: minute, ampm: ampm,
                      lat: lat, lon: lon, tzOffset: tz,
                      place: placeCtrl.text,
                      timestamp: DateTime.now().toIso8601String(),
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $name ${AppLocale.l('calcSuccess')}'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('errorLabel')}: $e'), backgroundColor: Colors.red));
                }
              },
              child: Text(AppLocale.l('calculate'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      }),
    );
  }

  /// Show form to edit an existing extra person's details
  void _showEditPersonDialog(String personName) {
    final idx = _extraPersons.indexWhere((p) => p.name == personName);
    if (idx == -1) return;
    final existing = _extraPersons[idx];

    final nameCtrl = TextEditingController(text: existing.name);
    final placeCtrl = TextEditingController(text: existing.place);
    final latCtrl = TextEditingController(text: existing.lat.toStringAsFixed(4));
    final lonCtrl = TextEditingController(text: existing.lon.toStringAsFixed(4));
    final tzCtrl = TextEditingController(text: '${existing.tz >= 0 ? '+' : ''}${existing.tz}');

    DateTime dob = existing.dob;
    int hour = existing.hour;
    int minute = existing.minute;
    String ampm = existing.ampm;

    bool geoLoading = false;
    String geoStatus = '';

    Future<void> performGeocode(String placeName, Function setS) async {
      if (placeName.trim().isEmpty) return;
      setS(() { geoLoading = true; geoStatus = ''; });
      try {
        final q = Uri.encodeComponent(placeName.trim());
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=1');
        final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as List;
          if (data.isEmpty) {
            setS(() => geoStatus = AppLocale.l('placeNotFoundDash'));
          } else {
            final lat = double.parse(data[0]['lat']);
            final lon = double.parse(data[0]['lon']);
            final displayName = data[0]['display_name'] as String;
            final autoTz = await getTimezoneForPlace(displayName, lat, lon, birthDate: dob);
            setS(() {
              placeCtrl.text = placeName.trim();
              latCtrl.text = lat.toStringAsFixed(4);
              lonCtrl.text = lon.toStringAsFixed(4);
              tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
              geoStatus = '📍 ${data[0]['display_name']} (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
            });
          }
        }
      } catch (_) {
        setS(() => geoStatus = AppLocale.l('placeError'));
      }
      setS(() => geoLoading = false);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
        return AlertDialog(
          backgroundColor: kBg,
          title: Text(AppLocale.l('editPerson'), style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocale.l('nameLabel'), prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 14),
                DateInputRow(
                  date: dob,
                  color: kPurple2,
                  onChanged: (d) => setS(() => dob = d),
                ),
                const SizedBox(height: 14),
                TimeInputRow(
                  hour: hour,
                  minute: minute,
                  ampm: ampm,
                  color: kPurple2,
                  onChanged: (h, m, a) => setS(() { hour = h; minute = m; ampm = a; }),
                ),
                const SizedBox(height: 14),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return offlinePlaces.keys.take(15);
                    final query = textEditingValue.text.toLowerCase();
                    final offline = offlinePlaces.keys.where((name) => name.toLowerCase().contains(query)).toList();
                    if (worldCitiesLoaded) {
                      final worldResults = searchWorldCities(textEditingValue.text, limit: 15);
                      for (final w in worldResults) {
                        final label = worldCityLabel(w);
                        if (!offline.any((o) => o.toLowerCase() == label.toLowerCase())) {
                          offline.add(label);
                        }
                      }
                    }
                    return offline.take(20);
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    if (placeCtrl.text.isNotEmpty && textEditingController.text.isEmpty) {
                      textEditingController.text = placeCtrl.text;
                    }
                    return TextField(
                      controller: textEditingController, focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: AppLocale.l('searchPlace'), prefixIcon: Icon(Icons.search),
                        suffixIcon: geoLoading
                          ? Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(icon: Icon(Icons.my_location, color: kTeal), onPressed: () { placeCtrl.text = textEditingController.text; performGeocode(textEditingController.text, setS); }),
                      ),
                      onSubmitted: (_) { placeCtrl.text = textEditingController.text; performGeocode(textEditingController.text, setS); },
                      onChanged: (val) => placeCtrl.text = val,
                    );
                  },
                  onSelected: (String selection) async {
                    if (offlinePlaces.containsKey(selection)) {
                      final coords = offlinePlaces[selection]!;
                      setS(() {
                        placeCtrl.text = selection;
                        latCtrl.text = coords[0].toStringAsFixed(4);
                        lonCtrl.text = coords[1].toStringAsFixed(4);
                        tzCtrl.text = '${coords[2] >= 0 ? '+' : ''}${coords[2]}';
                        geoStatus = '📍 $selection (TZ: ${coords[2] >= 0 ? '+' : ''}${coords[2]})';
                      });
                    } else {
                      final worldResults = searchWorldCities(selection.split(', ').first, limit: 1);
                      if (worldResults.isNotEmpty) {
                        final w = worldResults.first;
                        final lat = (w['la'] as num).toDouble();
                        final lon = (w['lo'] as num).toDouble();
                        final tz = (w['c'] != null)
                            ? getDstAwareOffset(w['c'] as String, lat, lon, dob)
                            : (w['tz'] as num).toDouble();
                        setS(() {
                          placeCtrl.text = selection;
                          latCtrl.text = lat.toStringAsFixed(4);
                          lonCtrl.text = lon.toStringAsFixed(4);
                          tzCtrl.text = '${tz >= 0 ? '+' : ''}$tz';
                          geoStatus = '📍 $selection (TZ: ${tz >= 0 ? '+' : ''}$tz)';
                        });
                      }
                    }
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0, borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 64),
                          child: ListView.builder(
                            padding: EdgeInsets.zero, itemCount: options.length, shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(dense: true, leading: Icon(Icons.location_on, size: 18, color: kPurple2), title: Text(option, style: TextStyle(fontSize: 13)), onTap: () => onSelected(option));
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (geoStatus.isNotEmpty) ...[const SizedBox(height: 6), Text(geoStatus, style: TextStyle(fontSize: 12, color: kGreen))],
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: TextField(controller: latCtrl, decoration: InputDecoration(labelText: AppLocale.l('latLabel'), isDense: true), keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: lonCtrl, decoration: InputDecoration(labelText: AppLocale.l('lonLabel'), isDense: true), keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: tzCtrl, decoration: const InputDecoration(labelText: 'TZ', isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocale.l('close'), style: TextStyle(color: kMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPurple2),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.l('enterName')), backgroundColor: Colors.red));
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⏳ $name ${AppLocale.l('calcInProgress')}')));
                try {
                  int h24 = hour;
                  if (ampm == 'PM' && h24 != 12) h24 += 12;
                  if (ampm == 'AM' && h24 == 12) h24 = 0;
                  final localHour = h24 + minute / 60.0;
                  final lat = double.tryParse(latCtrl.text) ?? 14.98;
                  final lon = double.tryParse(lonCtrl.text) ?? 74.73;
                  final tz = double.tryParse(tzCtrl.text) ?? 5.5;

                  final result = await AstroCalculator.calculate(
                    year: dob.year, month: dob.month, day: dob.day,
                    hourUtcOffset: tz, hour24: localHour,
                    lat: lat, lon: lon, ayanamsaMode: 'lahiri',
                    trueNode: widget.extraInfo['nodeMode'] == 'true',
                  );

                  if (result == null) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('calcFailed')}'), backgroundColor: Colors.red));
                    return;
                  }

                  if (mounted) {
                    setState(() {
                      _extraPersons[idx] = PersonEntry(name: name, result: result, dob: dob, hour: hour, minute: minute, ampm: ampm, lat: lat, lon: lon, tz: tz, place: placeCtrl.text, notes: existing.notes);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $name ${AppLocale.l('calcSuccess')}'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('errorLabel')}: $e'), backgroundColor: Colors.red));
                }
              },
              child: Text(AppLocale.l('calculate'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      }),
    );
  }

  /// Show form to edit the primary person's details
  void _showEditPrimaryDialog() {
    final nameCtrl = TextEditingController(text: _primaryName);
    final placeCtrl = TextEditingController(text: _primaryPlace);
    final latCtrl = TextEditingController(text: _primaryLat.toStringAsFixed(4));
    final lonCtrl = TextEditingController(text: _primaryLon.toStringAsFixed(4));
    final tzCtrl = TextEditingController(text: '${_primaryTz >= 0 ? '+' : ''}$_primaryTz');

    DateTime dob = _primaryDob;
    int hour = _primaryHour;
    int minute = _primaryMinute;
    String ampm = _primaryAmpm;

    bool geoLoading = false;
    String geoStatus = '';

    Future<void> performGeocode(String placeName, Function setS) async {
      if (placeName.trim().isEmpty) return;
      setS(() { geoLoading = true; geoStatus = ''; });
      try {
        final q = Uri.encodeComponent(placeName.trim());
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=1');
        final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as List;
          if (data.isEmpty) {
            setS(() => geoStatus = AppLocale.l('placeNotFoundDash'));
          } else {
            final lat = double.parse(data[0]['lat']);
            final lon = double.parse(data[0]['lon']);
            final displayName = data[0]['display_name'] as String;
            final autoTz = await getTimezoneForPlace(displayName, lat, lon, birthDate: dob);
            setS(() {
              placeCtrl.text = placeName.trim();
              latCtrl.text = lat.toStringAsFixed(4);
              lonCtrl.text = lon.toStringAsFixed(4);
              tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
              geoStatus = '📍 ${data[0]['display_name']} (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
            });
          }
        }
      } catch (_) {
        setS(() => geoStatus = AppLocale.l('placeError'));
      }
      setS(() => geoLoading = false);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
        return AlertDialog(
          backgroundColor: kBg,
          title: Text(AppLocale.l('editPerson'), style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocale.l('nameLabel'), prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 14),
                DateInputRow(
                  date: dob,
                  color: kPurple2,
                  onChanged: (d) => setS(() => dob = d),
                ),
                const SizedBox(height: 14),
                TimeInputRow(
                  hour: hour,
                  minute: minute,
                  ampm: ampm,
                  color: kPurple2,
                  onChanged: (h, m, a) => setS(() { hour = h; minute = m; ampm = a; }),
                ),
                const SizedBox(height: 14),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return offlinePlaces.keys.take(15);
                    final query = textEditingValue.text.toLowerCase();
                    final offline = offlinePlaces.keys.where((name) => name.toLowerCase().contains(query)).toList();
                    if (worldCitiesLoaded) {
                      final worldResults = searchWorldCities(textEditingValue.text, limit: 15);
                      for (final w in worldResults) {
                        final label = worldCityLabel(w);
                        if (!offline.any((o) => o.toLowerCase() == label.toLowerCase())) {
                          offline.add(label);
                        }
                      }
                    }
                    return offline.take(20);
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    if (placeCtrl.text.isNotEmpty && textEditingController.text.isEmpty) {
                      textEditingController.text = placeCtrl.text;
                    }
                    return TextField(
                      controller: textEditingController, focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: AppLocale.l('searchPlace'), prefixIcon: Icon(Icons.search),
                        suffixIcon: geoLoading
                          ? Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(icon: Icon(Icons.my_location, color: kTeal), onPressed: () { placeCtrl.text = textEditingController.text; performGeocode(textEditingController.text, setS); }),
                      ),
                      onSubmitted: (_) { placeCtrl.text = textEditingController.text; performGeocode(textEditingController.text, setS); },
                      onChanged: (val) => placeCtrl.text = val,
                    );
                  },
                  onSelected: (String selection) async {
                    if (offlinePlaces.containsKey(selection)) {
                      final coords = offlinePlaces[selection]!;
                      setS(() {
                        placeCtrl.text = selection;
                        latCtrl.text = coords[0].toStringAsFixed(4);
                        lonCtrl.text = coords[1].toStringAsFixed(4);
                        tzCtrl.text = '${coords[2] >= 0 ? '+' : ''}${coords[2]}';
                        geoStatus = '📍 $selection (TZ: ${coords[2] >= 0 ? '+' : ''}${coords[2]})';
                      });
                    } else {
                      final worldResults = searchWorldCities(selection.split(', ').first, limit: 1);
                      if (worldResults.isNotEmpty) {
                        final w = worldResults.first;
                        final lat = (w['la'] as num).toDouble();
                        final lon = (w['lo'] as num).toDouble();
                        final tz = (w['c'] != null)
                            ? getDstAwareOffset(w['c'] as String, lat, lon, dob)
                            : (w['tz'] as num).toDouble();
                        setS(() {
                          placeCtrl.text = selection;
                          latCtrl.text = lat.toStringAsFixed(4);
                          lonCtrl.text = lon.toStringAsFixed(4);
                          tzCtrl.text = '${tz >= 0 ? '+' : ''}$tz';
                          geoStatus = '📍 $selection (TZ: ${tz >= 0 ? '+' : ''}$tz)';
                        });
                      }
                    }
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0, borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 64),
                          child: ListView.builder(
                            padding: EdgeInsets.zero, itemCount: options.length, shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(dense: true, leading: Icon(Icons.location_on, size: 18, color: kPurple2), title: Text(option, style: TextStyle(fontSize: 13)), onTap: () => onSelected(option));
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (geoStatus.isNotEmpty) ...[const SizedBox(height: 6), Text(geoStatus, style: TextStyle(fontSize: 12, color: kGreen))],
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: TextField(controller: latCtrl, decoration: InputDecoration(labelText: AppLocale.l('latLabel'), isDense: true), keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: lonCtrl, decoration: InputDecoration(labelText: AppLocale.l('lonLabel'), isDense: true), keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: tzCtrl, decoration: const InputDecoration(labelText: 'TZ', isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocale.l('close'), style: TextStyle(color: kMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPurple2),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.l('enterName')), backgroundColor: Colors.red));
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⏳ $name ${AppLocale.l('recalculating')}')));
                try {
                  int h24 = hour;
                  if (ampm == 'PM' && h24 != 12) h24 += 12;
                  if (ampm == 'AM' && h24 == 12) h24 = 0;
                  final localHour = h24 + minute / 60.0;
                  final lat = double.tryParse(latCtrl.text) ?? 14.98;
                  final lon = double.tryParse(lonCtrl.text) ?? 74.73;
                  final tz = double.tryParse(tzCtrl.text) ?? 5.5;

                  final result = await AstroCalculator.calculate(
                    year: dob.year, month: dob.month, day: dob.day,
                    hourUtcOffset: tz, hour24: localHour,
                    lat: lat, lon: lon, ayanamsaMode: 'lahiri',
                    trueNode: widget.extraInfo['nodeMode'] == 'true',
                  );

                  if (result == null) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('calcFailed')}'), backgroundColor: Colors.red));
                    return;
                  }

                  if (mounted) {
                    setState(() {
                      _primaryName = name;
                      _primaryResult = result;
                      _primaryDob = dob;
                      _primaryHour = hour;
                      _primaryMinute = minute;
                      _primaryAmpm = ampm;
                      _primaryLat = lat;
                      _primaryLon = lon;
                      _primaryTz = tz;
                      _primaryPlace = placeCtrl.text;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $name ${AppLocale.l('calcSuccess')}'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('errorLabel')}: $e'), backgroundColor: Colors.red));
                }
              },
              child: Text(AppLocale.l('recalcBtn'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _loadJanmaNakshatra() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        final val = prefs.getInt('dashboard_janma_nakshatra');
        if (val != null) _janmaNakshatraIdx = val;
      });
    }
  }

  /// Load all group members from saved profiles and calculate their kundalis
  Future<void> _loadGroupMembers() async {
    final profiles = await StorageService.loadAll();
    final newEntries = <PersonEntry>[];

    for (final memberName in widget.initialGroupMembers) {
      // Skip if already loaded or if it's the primary person
      if (memberName == widget.name) continue;
      if (_extraPersons.any((ep) => ep.name == memberName)) continue;

      final p = profiles[memberName];
      if (p == null) continue;

      try {
        final dateParts = p.date.split('-');
        final dob = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
        int h24 = p.hour;
        if (p.ampm == 'PM' && h24 != 12) h24 += 12;
        if (p.ampm == 'AM' && h24 == 12) h24 = 0;
        final localHour = h24 + p.minute / 60.0;
        final result = await AstroCalculator.calculate(
          year: dob.year, month: dob.month, day: dob.day,
          hourUtcOffset: p.tzOffset, hour24: localHour,
          lat: p.lat, lon: p.lon, ayanamsaMode: 'lahiri', trueNode: true,
        );
        if (result != null) {
          newEntries.add(PersonEntry(
            name: p.name, result: result, dob: dob,
            hour: p.hour, minute: p.minute, ampm: p.ampm,
            lat: p.lat, lon: p.lon, tz: p.tzOffset, place: p.place, notes: p.notes,
          ));
        }
      } catch (e) {
        debugPrint('Failed to load group member $memberName: $e');
      }
    }

    // Single setState for all members — avoids N full screen rebuilds
    if (newEntries.isNotEmpty && mounted) {
      setState(() => _extraPersons.addAll(newEntries));
    }
  }

  Future<void> _saveSelectedJanmaNakshatra(int? idx) async {
    if (idx != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dashboard_janma_nakshatra', idx);
    }
  }

  Future<void> _exportAndShareCSV() async {
    try {
      final r = widget.result;
      final pan = r.panchang;
      final dateStr = '${widget.dob.day.toString().padLeft(2,'0')}-${widget.dob.month.toString().padLeft(2,'0')}-${widget.dob.year}';
      final timeStr = '${widget.hour}:${widget.minute.toString().padLeft(2,'0')} ${widget.ampm}';
      final name = widget.name.isNotEmpty ? widget.name : 'Unknown';

      final buf = StringBuffer();
      // BOM for Excel UTF-8
      buf.write('\uFEFF');

      // Personal Info
      buf.writeln('${AppLocale.l('jatakaVivar')},,');
      buf.writeln('${AppLocale.l('nameLabel')},$name,');
      buf.writeln('${AppLocale.l('placeLabel')},${widget.place},');
      buf.writeln('${AppLocale.l('dateLabel')},$dateStr,');
      buf.writeln('${AppLocale.l('timeLabel')},$timeStr,');
      buf.writeln('${AppLocale.l('latLabel')},${widget.lat},');
      buf.writeln('${AppLocale.l('lonLabel')},${widget.lon},');
      buf.writeln(',');

      // Panchanga
      buf.writeln('${AppLocale.l('pHeading')},,');
      buf.writeln('${AppLocale.l('samvatsara')},${pan.samvatsara},');
      buf.writeln('${AppLocale.l('varaLabel')},${pan.vara},');
      buf.writeln('${AppLocale.l('tithiLabel')},${pan.tithi},');
      buf.writeln('${AppLocale.l('nakshatraShort')},${pan.nakshatra},');
      buf.writeln('${AppLocale.l('yogaLabel')},${pan.yoga},');
      buf.writeln('${AppLocale.l('karanaLabel')},${pan.karana},');
      buf.writeln('${AppLocale.l('chandraRashiLabel')},${pan.chandraRashi},');
      buf.writeln('${AppLocale.l('chandraMasa')},${pan.chandraMasa},');
      buf.writeln('${AppLocale.l('souraMasa')},${pan.souraMasa},');
      buf.writeln('${AppLocale.l('sunrise')},${pan.sunrise},');
      buf.writeln('${AppLocale.l('sunset')},${pan.sunset},');
      buf.writeln('${AppLocale.l('dashaLord')},${pan.dashaLord},');
      buf.writeln('${AppLocale.l('dashaBalanceLabel')},${pan.dashaBalance},');
      buf.writeln(',');

      // Graha Sphuta
      buf.writeln('${AppLocale.l('grahaSphuta')},,,');
      buf.writeln('${AppLocale.l('hGraha')},${AppLocale.l('hRashi')},${AppLocale.l('hSphuta')},${AppLocale.l('hNakPada')}');
      for (final p in planetOrder) {
        final info = r.planets[p];
        if (info == null) continue;
        final ri = (info.longitude / 30).floor() % 12;
        buf.writeln('${tr(p)},${appRashi[ri]},${formatDeg(info.longitude)},${trAll(info.nakshatra)} - ${info.pada}');
      }
      buf.writeln(',');

      // Upagraha Sphuta
      buf.writeln('${AppLocale.l('upagrahaTitle')},,,');
      buf.writeln('${AppLocale.l('hUpagraha')},${AppLocale.l('hRashi')},${AppLocale.l('hDegree')},${AppLocale.l('hNakshatraCol')}');
      for (final sp in sphutas16Order) {
        final deg = r.advSphutas[sp];
        if (deg == null) continue;
        final ri = (deg / 30).floor() % 12;
        final nakIdx = (deg / 13.333333).floor() % 27;
        final pada = ((deg % 13.333333) / 3.333333).floor() + 1;
        buf.writeln('$sp,${appRashi[ri]},${formatDeg(deg)},${appNak[nakIdx]}-$pada');
      }

      // Save CSV to temp and share
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocale.l('webShareError'))));
        }
        return;
      }

      final fileName = '${name.replaceAll(' ', '_')}_$dateStr.csv';
      await ExportService.shareCSV(
        csvContent: buf.toString(),
        fileName: fileName,
        shareText: '$name ${AppLocale.l('kundaliLabel')} - $dateStr',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocale.l('errorLabel')}: $e'), backgroundColor: Colors.red));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kBg,
      body: KeyedSubtree(
        key: ValueKey(_resumeKey),
        child: SafeArea(
        child: Column(
          children: [
            // Minimal header with back/save
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: kText),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(children: [
                    IconButton(
                      icon: Icon(Icons.person_add, color: kPurple2),
                      tooltip: AppLocale.l('addPerson'),
                      onPressed: _showAddPersonDialog,
                    ),

                    IconButton(
                      icon: _syncing
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kTeal))
                        : Icon(Icons.save, color: kText),
                      tooltip: 'Save & Sync',
                      onPressed: _syncing ? null : () async {
                            if (!mounted) return;
                            final cId = widget.extraInfo['clientId'] ?? '';
                            
                            // Build the group members list
                            final groupNames = _extraPersons.map((p) => p.name).toList();
                            final dateStr = '${widget.dob.year}-${widget.dob.month.toString().padLeft(2, '0')}-${widget.dob.day.toString().padLeft(2, '0')}';

                            // 1. Resolve Client ID
                            String? resolvedCId = (cId is String && cId.isNotEmpty) ? cId : null;
                            if (resolvedCId == null) {
                              final client = await ClientService.getOrCreateClient(name: widget.name, phone: 'No Phone');
                              if (client != null) resolvedCId = client.clientId;
                            }

                            // 2. Save primary profile WITH groupMembers
                            await StorageService.save(Profile(
                              name: widget.name,
                              date: dateStr,
                              hour: widget.hour, minute: widget.minute, ampm: widget.ampm,
                              lat: widget.lat, lon: widget.lon, place: widget.place,
                              tzOffset: _primaryTz,
                              notes: _notes,
                              aroodhas: _aroodhas,
                              janmaNakshatraIdx: _janmaNakshatraIdx,
                              clientId: resolvedCId,
                              groupMembers: groupNames,
                              prastutaTime: _prastutaTime?.toIso8601String(),
                            ));

                            // 3. Update primary person in ClientService
                            if (resolvedCId != null && resolvedCId.isNotEmpty) {
                              await ClientService.updateFamilyMember(FamilyMember(
                                clientId: resolvedCId,
                                memberName: widget.name,
                                relation: 'Self',
                                dob: dateStr,
                                birthTime: '${widget.hour.toString().padLeft(2,'0')}:${widget.minute.toString().padLeft(2,'0')} ${widget.ampm}',
                                birthPlace: widget.place,
                                lat: widget.lat, lon: widget.lon,
                                tzOffset: _primaryTz,
                                notes: _notes,
                              ));
                            }

                            // 4. Save each extra person individually
                            for (final ep in _extraPersons) {
                              final epDateStr = '${ep.dob.year}-${ep.dob.month.toString().padLeft(2, '0')}-${ep.dob.day.toString().padLeft(2, '0')}';
                              await StorageService.save(Profile(
                                name: ep.name,
                                date: epDateStr,
                                hour: ep.hour, minute: ep.minute, ampm: ep.ampm,
                                lat: ep.lat, lon: ep.lon, place: ep.place,
                                tzOffset: ep.tz,
                                notes: ep.notes,
                                clientId: resolvedCId,
                              ));
                              // Also sync extra person to ClientService
                              if (resolvedCId != null && resolvedCId.isNotEmpty) {
                                await ClientService.updateFamilyMember(FamilyMember(
                                  clientId: resolvedCId,
                                  memberName: ep.name,
                                  relation: 'Group Member',
                                  dob: epDateStr,
                                  birthTime: '${ep.hour.toString().padLeft(2,'0')}:${ep.minute.toString().padLeft(2,'0')} ${ep.ampm}',
                                  birthPlace: ep.place,
                                  lat: ep.lat, lon: ep.lon,
                                  tzOffset: ep.tz,
                                  notes: ep.notes,
                                ));
                              }
                            }

                            final totalCount = 1 + groupNames.length;
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ ${AppLocale.l('savedSuccess')} ($totalCount ${AppLocale.l('kundaliCount')})\nClient ID: ${resolvedCId ?? ''}'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 4),
                              )
                            );
                            if (GoogleAuthService.isSignedIn) {
                              setState(() => _syncing = true);
                              final sheetOk = await SheetsService.syncProfile({}, isNew: false);
                              final docOk = await DocsService.syncNotes(widget.name, _notes);
                              if (mounted) {
                                setState(() => _syncing = false);
                              }
                            }
                      },
                    ),
                  ]),
                ],
              ),
            ),
            // Person selector (multi-person only) — portrait only
            // In landscape, the bottom person selector is used instead.
            if (_extraPersons.isNotEmpty && MediaQuery.of(context).orientation != Orientation.landscape)
              Container(
                color: kCard,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      // "All" chip
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text('ಎಲ್ಲ / All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _selectedPersonIndices.isEmpty ? Colors.white : kText)),
                          selected: _selectedPersonIndices.isEmpty,
                          selectedColor: kPurple2,
                          backgroundColor: kCard,
                          side: BorderSide(color: _selectedPersonIndices.isEmpty ? kPurple2 : kBorder),
                          onSelected: (_) => setState(() => _selectedPersonIndices = {}),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      // Primary person chip
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(_primaryName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _selectedPersonIndices.contains(0) ? Colors.white : kText)),
                          selected: _selectedPersonIndices.contains(0),
                          selectedColor: kPurple2,
                          backgroundColor: kCard,
                          side: BorderSide(color: _selectedPersonIndices.contains(0) ? kPurple2 : kBorder),
                          onSelected: (selected) => setState(() {
                            final s = Set<int>.from(_selectedPersonIndices);
                            if (selected) { s.add(0); } else { s.remove(0); }
                            _selectedPersonIndices = s;
                          }),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      // Extra person chips
                      ...List.generate(_extraPersons.length, (i) {
                        final idx = i + 1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(_extraPersons[i].name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _selectedPersonIndices.contains(idx) ? Colors.white : kText)),
                            selected: _selectedPersonIndices.contains(idx),
                            selectedColor: kTeal,
                            backgroundColor: kCard,
                            side: BorderSide(color: _selectedPersonIndices.contains(idx) ? kTeal : kBorder),
                            onSelected: (selected) => setState(() {
                              final s = Set<int>.from(_selectedPersonIndices);
                              if (selected) { s.add(idx); } else { s.remove(idx); }
                              _selectedPersonIndices = s;
                            }),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            // ── Orientation-aware body ──
            Expanded(
              child: OrientationBuilder(
                builder: (context, orientation) {
                  final isLandscape = orientation == Orientation.landscape;

                  if (!isLandscape) {
                    // ── PORTRAIT: existing layout ──
                    return Column(
                      children: [
                        Container(
                          color: kCard,
                          child: TabBar(
                            controller: _tabCtrl,
                            isScrollable: true,
                            tabs: _tabs.map((t) => Tab(text: t)).toList(),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabCtrl,
                            children: [
                              _buildPanchangTab(),
                              _buildKundaliTab(),
                              _buildSphutas(),
                              _buildAroodhaTab(),
                              _buildDashaTab(),
                              _buildBhavaTab(),
                              _buildGrahaShadvargaTab(),
                              _buildShadbalaTab(),
                              _buildAshtakaTab(),
                              _buildYogaTab(),
                              _buildPredictionTab(),
                              _buildGocharTab(),
                              _buildNotesTab(),
                              _buildJanmaPatrikeTab(),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // ── LANDSCAPE: Bars at BOTTOM, collapsible for tablet users ──
                    return Column(
                      children: [
                        // Main content (top — takes all available space)
                        Expanded(
                          child: Stack(
                            children: [
                              TabBarView(
                                controller: _tabCtrl,
                                children: [
                                  _buildPanchangTab(),
                                  _buildKundaliTab(),
                                  _buildSphutas(),
                                  _buildAroodhaTab(),
                                  _buildDashaTab(),
                                  _buildBhavaTab(),
                                  _buildGrahaShadvargaTab(),
                                  _buildShadbalaTab(),
                                  _buildAshtakaTab(),
                                  _buildYogaTab(),
                                  _buildPredictionTab(),
                                  _buildGocharTab(),
                                  _buildNotesTab(),
                                  _buildJanmaPatrikeTab(),
                                ],
                              ),
                              // Floating expand button when bars are hidden
                              if (!_landscapeBarsVisible)
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Material(
                                    color: kCard.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    elevation: 3,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => setState(() => _landscapeBarsVisible = true),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(Icons.keyboard_arrow_up, size: 22, color: kPurple2),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Collapsible Person selector (bottom)
                        if (_extraPersons.isNotEmpty)
                          AnimatedCrossFade(
                            firstChild: Container(
                              color: kCard,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: SizedBox(
                                height: 36,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: FilterChip(
                                        label: Text('ಎಲ್ಲ / All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _selectedPersonIndices.isEmpty ? Colors.white : kText)),
                                        selected: _selectedPersonIndices.isEmpty,
                                        selectedColor: kPurple2,
                                        backgroundColor: kCard,
                                        side: BorderSide(color: _selectedPersonIndices.isEmpty ? kPurple2 : kBorder),
                                        onSelected: (_) => setState(() => _selectedPersonIndices = {}),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: FilterChip(
                                        label: Text(_primaryName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _selectedPersonIndices.contains(0) ? Colors.white : kText)),
                                        selected: _selectedPersonIndices.contains(0),
                                        selectedColor: kPurple2,
                                        backgroundColor: kCard,
                                        side: BorderSide(color: _selectedPersonIndices.contains(0) ? kPurple2 : kBorder),
                                        onSelected: (selected) => setState(() {
                                          final s = Set<int>.from(_selectedPersonIndices);
                                          if (selected) { s.add(0); } else { s.remove(0); }
                                          _selectedPersonIndices = s;
                                        }),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    ...List.generate(_extraPersons.length, (i) {
                                      final idx = i + 1;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: FilterChip(
                                          label: Text(_extraPersons[i].name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _selectedPersonIndices.contains(idx) ? Colors.white : kText)),
                                          selected: _selectedPersonIndices.contains(idx),
                                          selectedColor: kTeal,
                                          backgroundColor: kCard,
                                          side: BorderSide(color: _selectedPersonIndices.contains(idx) ? kTeal : kBorder),
                                          onSelected: (selected) => setState(() {
                                            final s = Set<int>.from(_selectedPersonIndices);
                                            if (selected) { s.add(idx); } else { s.remove(idx); }
                                            _selectedPersonIndices = s;
                                          }),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            secondChild: const SizedBox.shrink(),
                            crossFadeState: _landscapeBarsVisible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                            duration: const Duration(milliseconds: 200),
                          ),
                        // Collapsible TabBar at bottom
                        AnimatedCrossFade(
                          firstChild: Container(
                            color: kCard,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TabBar(
                                    controller: _tabCtrl,
                                    isScrollable: true,
                                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                                  ),
                                ),
                                // Collapse button
                                InkWell(
                                  onTap: () => setState(() => _landscapeBarsVisible = false),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Icon(Icons.keyboard_arrow_down, size: 20, color: kMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          secondChild: const SizedBox.shrink(),
                          crossFadeState: _landscapeBarsVisible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 200),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),

          ],
        ),
      ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Filter allPersons by selected person index
  // ─────────────────────────────────────────────
  List<Map<String, dynamic>> _filterPersons(List<Map<String, dynamic>> allPersons) {
    if (_selectedPersonIndices.isEmpty) return allPersons;
    return allPersons.asMap().entries
        .where((e) => _selectedPersonIndices.contains(e.key))
        .map((e) => e.value)
        .toList();
  }

  // ─────────────────────────────────────────────
  // TAB 1: KUNDALI (All vargas stacked vertically)
  // ─────────────────────────────────────────────
  Widget _buildKundaliTab() {
    final charts = SamshakaMode.isActive
      ? [
          // Samshaka mode order: Rashi → Bhava → Navamsha → Other Varga
          {'label': AppLocale.l('rashiKundali'), 'varga': 1, 'isBhava': false},
          {'label': AppLocale.l('bhavaKundali'), 'varga': 1, 'isBhava': true},
          {'label': AppLocale.l('navamshaKundali'), 'varga': 9, 'isBhava': false},
          {'label': AppLocale.l('horaKundali'), 'varga': 2, 'isBhava': false},
          {'label': AppLocale.l('drekkanaKundali'), 'varga': 3, 'isBhava': false},
          {'label': 'D4 ಚತುರ್ಥಾಂಶ', 'varga': 4, 'isBhava': false},
          {'label': 'D7 ಸಪ್ತಾಂಶ', 'varga': 7, 'isBhava': false},
          {'label': 'D10 ದಶಾಂಶ', 'varga': 10, 'isBhava': false},
          {'label': AppLocale.l('dvadashamsha'), 'varga': 12, 'isBhava': false},
          {'label': 'D16 ಷೋಡಶಾಂಶ', 'varga': 16, 'isBhava': false},
          {'label': 'D20 ವಿಂಶಾಂಶ', 'varga': 20, 'isBhava': false},
          {'label': 'D24 ಚತುರ್ವಿಂಶಾಂಶ', 'varga': 24, 'isBhava': false},
          {'label': 'D27 ಸಪ್ತವಿಂಶಾಂಶ', 'varga': 27, 'isBhava': false},
          {'label': AppLocale.l('trimshamsha'), 'varga': 30, 'isBhava': false},
          {'label': 'D40 ಖವೇದಾಂಶ', 'varga': 40, 'isBhava': false},
          {'label': 'D45 ಅಕ್ಷವೇದಾಂಶ', 'varga': 45, 'isBhava': false},
          {'label': 'D60 ಷಷ್ಠ್ಯಂಶ', 'varga': 60, 'isBhava': false},
        ]
      : [
          // Default order: Rashi → Navamsha → Bhava → Other Varga
          {'label': AppLocale.l('rashiKundali'), 'varga': 1, 'isBhava': false},
          {'label': AppLocale.l('navamshaKundali'), 'varga': 9, 'isBhava': false},
          {'label': AppLocale.l('bhavaKundali'), 'varga': 1, 'isBhava': true},
          {'label': AppLocale.l('horaKundali'), 'varga': 2, 'isBhava': false},
          {'label': AppLocale.l('drekkanaKundali'), 'varga': 3, 'isBhava': false},
          {'label': 'D4 ಚತುರ್ಥಾಂಶ', 'varga': 4, 'isBhava': false},
          {'label': 'D7 ಸಪ್ತಾಂಶ', 'varga': 7, 'isBhava': false},
          {'label': 'D10 ದಶಾಂಶ', 'varga': 10, 'isBhava': false},
          {'label': AppLocale.l('dvadashamsha'), 'varga': 12, 'isBhava': false},
          {'label': 'D16 ಷೋಡಶಾಂಶ', 'varga': 16, 'isBhava': false},
          {'label': 'D20 ವಿಂಶಾಂಶ', 'varga': 20, 'isBhava': false},
          {'label': 'D24 ಚತುರ್ವಿಂಶಾಂಶ', 'varga': 24, 'isBhava': false},
          {'label': 'D27 ಸಪ್ತವಿಂಶಾಂಶ', 'varga': 27, 'isBhava': false},
          {'label': AppLocale.l('trimshamsha'), 'varga': 30, 'isBhava': false},
          {'label': 'D40 ಖವೇದಾಂಶ', 'varga': 40, 'isBhava': false},
          {'label': 'D45 ಅಕ್ಷವೇದಾಂಶ', 'varga': 45, 'isBhava': false},
          {'label': 'D60 ಷಷ್ಠ್ಯಂಶ', 'varga': 60, 'isBhava': false},
        ];

    // All persons: primary + extras
    var allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult, 'isPrimary': true},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result, 'isPrimary': false}),
    ];
    allPersons = _filterPersons(allPersons);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          ...allPersons.map((person) {
            final personResult = person['result'] as KundaliResult;
            final personName = person['name'] as String;
            final isPrimary = person['isPrimary'] as bool;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Person header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 18, color: isPrimary ? kPurple2 : kTeal),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(personName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isPrimary ? kPurple2 : kTeal)),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, size: 18, color: kPurple2),
                        tooltip: AppLocale.l('editTooltip'),
                        onPressed: () => isPrimary ? _showEditPrimaryDialog() : _showEditPersonDialog(personName),
                      ),
                      if (!isPrimary)
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: Colors.redAccent),
                          onPressed: () => setState(() => _extraPersons.removeWhere((p) => p.name == personName)),
                        ),
                    ],
                  ),
                ),
                // Swipeable chart with dots
                _KundaliPageView(
                  charts: charts,
                  personResult: personResult,
                  bhavaPlanet: _bhavaPlanet,
                  onBhavaPlanetToggle: (pName) => setState(() => _bhavaPlanet = _bhavaPlanet == pName ? null : pName),
                  onPlanetTap: _showPlanetDetail,
                  highlightDashaLords: _dashaHighlightEnabled,
                ),
                if (allPersons.length > 1) Divider(thickness: 1, color: kBorder),
              ],
            );
          }),
          // Add person button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _showAddPersonDialog,
              icon: Icon(Icons.person_add, color: kPurple2),
              label: Text(AppLocale.l('addPerson'), style: TextStyle(color: kPurple2, fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: kPurple2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }


  void _showPlanetDetail(String pName) {
    final info = _primaryResult.planets[pName];
    if (info == null) return;
    final sun = _primaryResult.planets['ರವಿ'];
    final detail = AstroCalculator.getPlanetDetail(
      pName, info.longitude, info.speed, sun?.longitude ?? 0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlanetDetailSheet(pName: pName, detail: detail),
    );
  }

  /// Get current Mahadasha + Bhukti lord names with distinct colors
  Map<String, Color> _currentDashaLords(KundaliResult r) {
    final now = DateTime.now();
    final lords = <String, Color>{};
    for (final md in r.dashas) {
      if (now.isAfter(md.start) && now.isBefore(md.end)) {
        lords[md.lord] = const Color(0xFFFF8C00); // Orange for Dasha
        for (final ad in md.antardashas) {
          if (now.isAfter(ad.start) && now.isBefore(ad.end)) {
            // If same planet is both dasha & bhukti, keep dasha color
            if (!lords.containsKey(ad.lord)) {
              lords[ad.lord] = const Color(0xFF00C853); // Green for Bhukti
            }
            break;
          }
        }
        break;
      }
    }
    return lords;
  }

  // ─────────────────────────────────────────────
  // TAB 2: UPAGRAHA SPHUTA (multi-person)
  // ─────────────────────────────────────────────
  Widget _buildSphutas() {
    var allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];
    allPersons = _filterPersons(allPersons);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: allPersons.map((person) {
          final personResult = person['result'] as KundaliResult;
          final personName = person['name'] as String;
          return Column(
            children: [
              if (allPersons.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(personName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                ),
              // Graha Sphuta added back per user request
              Text(AppLocale.l('grahaSphuta'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _tableHeader([AppLocale.l('hGraha'), AppLocale.l('hRashi'), AppLocale.l('hSphuta'), AppLocale.l('hNakPada')], big: true),
                    ...planetOrder.map((p) {
                      final info = personResult.planets[p];
                      if (info == null) return const SizedBox.shrink();
                      final ri = (info.longitude / 30).floor() % 12;
                      return _tableRow([
                        tr(p),
                        appRashi[ri],
                        formatDeg(info.longitude),
                        '${trAll(info.nakshatra)} - ${info.pada}'
                      ], bold0: true, big: true);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(AppLocale.l('upagrahaTitle'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _tableHeader([AppLocale.l('hUpagraha'), AppLocale.l('hRashi'), AppLocale.l('hDegree'), AppLocale.l('hNakshatraCol')], big: true),
                    ...sphutas16Order.map((sp) {
                      final deg = personResult.advSphutas[sp];
                      if (deg == null) return const SizedBox.shrink();
                      final ri = (deg / 30).floor() % 12;
                      final nakIdx = (deg / 13.333333).floor() % 27;
                      final pada = ((deg % 13.333333) / 3.333333).floor() + 1;
                      return _tableRow([trAll(sp), appRashi[ri], formatDeg(deg), '${appNak[nakIdx]}-$pada'],
                        bold0: true, big: true);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 4: AROODHA
  // ─────────────────────────────────────────────
  Future<void> _openPrastutaChart({DateTime? savedTime, bool silent = false}) async {
    final now = savedTime ?? DateTime.now();
    // Always use default location for aroodha/prastuta
    final useLat = LocationService.lat;
    final useLon = LocationService.lon;
    final useTz = LocationService.tzOffset;
    if (!silent && mounted) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    }
    try {
      final localHour = now.hour + now.minute / 60.0;
      final ayanamsa = widget.extraInfo['ayanamsa'] ?? 'lahiri';
      final trueNode = (widget.extraInfo['nodeMode'] ?? 'mean') == 'true';
      final result = await AstroCalculator.calculate(
        year: now.year, month: now.month, day: now.day,
        hourUtcOffset: useTz,
        hour24: localHour,
        lat: useLat, lon: useLon,
        ayanamsaMode: ayanamsa,
        trueNode: trueNode,
      );
      if (!silent && mounted) Navigator.pop(context);
      if (result != null && mounted) {
        setState(() {
          _prastutaResult = result;
          _prastutaTime = now;
        });
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.l('loadingPrastuta'))));
        }
      }
    } catch (e) {
      if (!silent && mounted) Navigator.pop(context);
      if (!silent && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocale.l('errorLabel')}: $e')));
      debugPrint('⏱️ Prastuta chart error: $e');
    }
  }

  bool _prastutaRestoreAttempted = false;

  Widget _buildAroodhaTab() {
    String _selAro = AppLocale.l('aroodha');
    int _selRashiIdx = 0;

    // Auto-restore: if prastutaTime is saved but chart not yet calculated, trigger it
    if (_prastutaTime != null && _prastutaResult == null && !_prastutaRestoreAttempted) {
      _prastutaRestoreAttempted = true;
      _openPrastutaChart(savedTime: _prastutaTime, silent: true);
    }

    return StatefulBuilder(builder: (ctx, setS) {
      final activeResult = _prastutaResult ?? _primaryResult;

      // Varga charts for horizontal scrolling
      final charts = [
        {'label': AppLocale.l('rashiKundali'), 'varga': 1, 'isBhava': false},
        {'label': AppLocale.l('navamshaKundali'), 'varga': 9, 'isBhava': false},
        {'label': AppLocale.l('bhavaKundali'), 'varga': 1, 'isBhava': true},
        {'label': AppLocale.l('horaKundali'), 'varga': 2, 'isBhava': false},
        {'label': AppLocale.l('drekkanaKundali'), 'varga': 3, 'isBhava': false},
        {'label': AppLocale.l('dvadashamsha'), 'varga': 12, 'isBhava': false},
        {'label': AppLocale.l('trimshamsha'), 'varga': 30, 'isBhava': false},
      ];

      final screenWidth = MediaQuery.of(context).size.width;
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      final isLargeScreen = screenWidth > 600 || isLandscape;
      final chartSize = isLargeScreen ? (screenWidth * 0.45).clamp(350.0, 550.0) : screenWidth * 0.85;
      final textScale = isLargeScreen ? (chartSize / 350.0).clamp(1.1, 1.4) : 1.0;

      // Shadvarga helper
      String getRashiLord(String rashiNameKn) {
        int idx = knRashi.indexOf(rashiNameKn);
        if (idx < 0) return rashiNameKn;
        final lordAbbr = const <String, List<String>>{
          'kn': ['ಕು','ಶು','ಬು','ಚ','ರ','ಬು','ಶು','ಕು','ಗು','ಶ','ಶ','ಗು'],
          'hi': ['मं','शु','बु','चं','सू','बु','शु','मं','गु','श','श','गु'],
          'ta': ['செ','சு','பு','சந்','சூ','பு','சு','செ','கு','ச','ச','கு'],
          'te': ['కు','శు','బు','చం','ర','బు','శు','కు','గు','శ','శ','గు'],
          'ml': ['കു','ശു','ബു','ചം','ര','ബു','ശു','കു','ഗു','ശ','ശ','ഗു'],
          'en': ['Ma','Ve','Me','Mo','Su','Me','Ve','Ma','Ju','Sa','Sa','Ju'],
        };
        return (lordAbbr[AppLocale.current] ?? lordAbbr['kn']!)[idx];
      }

      return SingleChildScrollView(
        child: Column(
          children: [
            // ── Prastuta Location & Time ──
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SectionTitle(AppLocale.l('aroodhaChakra')),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(AppLocale.l('prastuta'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _openPrastutaChart,
                      ),
                    ],
                  ),
                  // ── Default place info ──
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPurple2.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.place, size: 14, color: kPurple2),
                      const SizedBox(width: 4),
                      Expanded(child: Text(
                        LocationService.place,
                        style: TextStyle(fontSize: 11, color: kText, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ]),
                  ),
                  // ── Prastuta time display ──
                  if (_prastutaTime != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.access_time, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '${AppLocale.l('prastuta')}: ${_prastutaTime!.day.toString().padLeft(2,'0')}/${_prastutaTime!.month.toString().padLeft(2,'0')}/${_prastutaTime!.year} ${_prastutaTime!.hour.toString().padLeft(2,'0')}:${_prastutaTime!.minute.toString().padLeft(2,'0')}:${_prastutaTime!.second.toString().padLeft(2,'0')}',
                          style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w700),
                        ),
                      ]),
                    ),
                  ],
                  // ── Aroodha controls ──
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selAro,
                        items: List.generate(7, (i) => AppLocale.l('aroType$i'))
                          .map((a) => DropdownMenuItem(value: a, child: Text(a, style: TextStyle()))).toList(),
                        onChanged: (v) => setS(() => _selAro = v!),
                        decoration: InputDecoration(labelText: AppLocale.l('aroodhaLabel')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selRashiIdx,
                        items: List.generate(12, (i) => DropdownMenuItem(
                          value: i, child: Text(appRashi[i], style: TextStyle()))).toList(),
                        onChanged: (v) => setS(() => _selRashiIdx = v!),
                        decoration: InputDecoration(labelText: AppLocale.l('rashiLabel')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => setS(() => _aroodhas[_selAro] = _selRashiIdx),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10)),
                      child: Text(AppLocale.l('addLabel'), style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  if (_aroodhas.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setS(() => _aroodhas.clear()),
                      child: Text(AppLocale.l('clearLabel'), style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ],
              ),
            ),

            // ── All varga charts (horizontal scroll) ──
            SizedBox(
              height: chartSize + (40 * textScale),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: charts.length,
                  itemBuilder: (context, i) {
                    final chart = charts[i];
                    final isBhavaChart = chart['isBhava'] as bool;
                    final label = chart['label'] as String;
                    return SizedBox(
                      width: chartSize,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Text(label, style: TextStyle(fontSize: 15 * textScale, fontWeight: FontWeight.w800, color: kPurple2)),
                            SizedBox(height: 4 * textScale),
                            Expanded(
                              child: KundaliChart(
                                result: activeResult,
                                varga: chart['varga'] as int,
                                isBhava: isBhavaChart,
                                textScale: textScale,
                                showSphutas: false,
                                aroodhas: _aroodhas,
                                centerLabel: _prastutaResult != null ? '${AppLocale.l('prastuta')}\n$label' : label,
                                onPlanetTap: _showPlanetDetail,
                                highlightPlanets: _dashaHighlightEnabled && ((chart['varga'] as int) == 1 || (chart['varga'] as int) == 9 || isBhavaChart)
                                    ? _currentDashaLords(activeResult)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Graha Sputa Table ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(AppLocale.l('grahaSphuta'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _tableHeader([AppLocale.l('hGraha'), AppLocale.l('hRashi'), AppLocale.l('hSphuta'), AppLocale.l('hNakPada')]),
                        ...planetOrder.map((p) {
                          final info = activeResult.planets[p];
                          if (info == null) return const SizedBox.shrink();
                          final ri = (info.longitude / 30).floor() % 12;
                          return _tableRow([
                            tr(p),
                            appRashi[ri],
                            formatDeg(info.longitude),
                            '${trAll(info.nakshatra)} - ${info.pada}'
                          ], bold0: true);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Upagraha Sputa
                  Text(AppLocale.l('upagrahaTitle'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _tableHeader([AppLocale.l('hUpagraha'), AppLocale.l('hRashi'), AppLocale.l('hDegree'), AppLocale.l('hNakshatraCol')]),
                        ...sphutas16Order.map((sp) {
                          final deg = activeResult.advSphutas[sp];
                          if (deg == null) return const SizedBox.shrink();
                          final ri = (deg / 30).floor() % 12;
                          final nakIdx = (deg / 13.333333).floor() % 27;
                          final pada = ((deg % 13.333333) / 3.333333).floor() + 1;
                          return _tableRow([trAll(sp), appRashi[ri], formatDeg(deg), '${appNak[nakIdx]}-$pada'],
                            bold0: true);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Graha Shadvarga Table ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [kPurple1.withOpacity(0.12), kPurple2.withOpacity(0.06)]),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14), topRight: Radius.circular(14),
                      ),
                      border: Border(bottom: BorderSide(color: kPurple2.withOpacity(0.3), width: 2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grid_view_rounded, size: 18, color: kPurple2),
                        const SizedBox(width: 8),
                        Text(AppLocale.l('shadvarga'), style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16, color: kPurple2,
                        )),
                      ],
                    ),
                  ),
                  Builder(builder: (_) {
                    final hGraha = AppLocale.l('hGraha');
                    final hD3 = AppLocale.l('hD3');
                    final hD2 = AppLocale.l('hD2');
                    final hD9 = AppLocale.l('hD9');
                    final hD30 = AppLocale.l('hD30');
                    final hD12 = AppLocale.l('hD12');
                    final hKshetra = AppLocale.l('hKshetra');
                    int rowIdx = 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
                        ),
                        border: Border.all(color: kBorder),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
                        ),
                        child: Table(
                          border: TableBorder.symmetric(
                            inside: BorderSide(color: kBorder.withOpacity(0.6), width: 0.5),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(1.3),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(1),
                            3: FlexColumnWidth(1),
                            4: FlexColumnWidth(1),
                            5: FlexColumnWidth(1),
                            6: FlexColumnWidth(1),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [kPurple1.withOpacity(0.15), kPurple2.withOpacity(0.08)]),
                              ),
                              children: [hGraha, hD3, hD2, hD9, hD30, hD12, hKshetra].map((h) =>
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Text(h, textAlign: TextAlign.center, style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 14, color: kPurple2,
                                  )),
                                ),
                              ).toList(),
                            ),
                            ...planetOrder.map((pNameKey) {
                              final pInfo = activeResult.planets[pNameKey];
                              if (pInfo == null) return const TableRow(children: [SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox()]);
                              final details = AstroCalculator.getPlanetDetail(pNameKey, pInfo.longitude, pInfo.speed, activeResult.planets['ರವಿ']?.longitude ?? 0.0);
                              final displayName = tr(pNameKey);
                              final isEvenRow = rowIdx++ % 2 == 0;
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isEvenRow ? kBg.withOpacity(0.5) : kCard,
                                ),
                                children: [
                                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(
                                    displayName, textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kTeal),
                                  )),
                                  ...[details['d3'], details['d2'], details['d9'], details['d30'], details['d12'], details['d1']].map((v) =>
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(
                                      getRashiLord(v as String), textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText),
                                    )),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  // ─────────────────────────────────────────────
  // TAB 5: DASHA
  // ─────────────────────────────────────────────
  Widget _buildDashaTab() {
    var allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];
    allPersons = _filterPersons(allPersons);
    return SingleChildScrollView(
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pName = person['name'] as String;
          final pan = r.panchang;

          // ── Sandhi definitions: {dashaLord → {planet1, planet2 per lang}} ──
          const _sandhiDef = <String, Map<String, List<String>>>{
            // key=dasha lord (Kannada), value={lang: [planet1, planet2]}
            'ಕುಜ': {
              'kn': ['ಕುಜ', 'ರಾಹು'], 'hi': ['कुज', 'राहु'], 'ta': ['குஜ', 'ராகு'],
              'te': ['కుజ', 'రాహు'], 'ml': ['കുജ', 'രാഹു'], 'en': ['Mars', 'Rahu'],
            },
            'ಶುಕ್ರ': {
              'kn': ['ಶುಕ್ರ', 'ಆದಿತ್ಯ'], 'hi': ['शुक्र', 'आदित्य'], 'ta': ['சுக்ர', 'ஆதித்ய'],
              'te': ['శుక్ర', 'ఆదిత్య'], 'ml': ['ശുക്ര', 'ആദിത്യ'], 'en': ['Venus', 'Sun'],
            },
            'ರಾಹು': {
              'kn': ['ರಾಹು', 'ಬೃಹಸ್ಪತಿ'], 'hi': ['राहु', 'बृहस्पति'], 'ta': ['ராகு', 'பிருஹஸ்பதி'],
              'te': ['రాహు', 'బృహస్పతి'], 'ml': ['രാഹു', 'ബൃഹസ്പതി'], 'en': ['Rahu', 'Jupiter'],
            },
          };

          // Localized templates
          final _loc = AppLocale.current;
          // {0}=p1, {1}=p2
          String _sandhiTitle(String p1, String p2) => {
            'kn': '$p1 $p2 ಸಂಧಿ ಕಾಲ', 'hi': '$p1 $p2 संधि काल', 'ta': '$p1 $p2 சந்தி காலம்',
            'te': '$p1 $p2 సంధి కాలం', 'ml': '$p1 $p2 സന്ധി കാലം', 'en': '$p1 $p2 Sandhi Period',
          }[_loc] ?? '$p1 $p2 ಸಂಧಿ ಕಾಲ';
          String _dashaEnd(String p1, String dt) => {
            'kn': '$p1 ದಶಾ ಅಂತ್ಯ $dt', 'hi': '$p1 दशा अंत $dt', 'ta': '$p1 தசா முடிவு $dt',
            'te': '$p1 దశా అంతం $dt', 'ml': '$p1 ദശാ അവസാനം $dt', 'en': '$p1 Dasha ends $dt',
          }[_loc] ?? '$p1 ದಶಾ ಅಂತ್ಯ $dt';
          String _sandhiDesc(String p1, String p2) => {
            'kn': 'ಈ ಸಮಯವು $p1 $p2 ದಶ ಸಂಧಿ ಆಗಿರುವುದರಿಂದ ಮೇಲೆ ತಿಳಿಸಿದ ಸಮಯಕ್ಕಿಂತ 6 ತಿಂಗಳ ಪೂರ್ವದಲ್ಲಿ\n$p1 $p2 ಶಾಂತಿ ಅಥವಾ ತತ್ಸಮಾನ ಕರ್ಮಗಳನ್ನು ಆಚರಿಸುವುದು ಉತ್ತಮ.',
            'hi': 'यह समय $p1 $p2 दशा संधि होने के कारण ऊपर बताए गए समय से 6 महीने पहले\n$p1 $p2 शांति अथवा तत्समान कर्म करना उचित है।',
            'ta': 'இது $p1 $p2 தசா சந்தி காலமாக இருப்பதால் மேற்கூறிய நேரத்திற்கு 6 மாதங்களுக்கு முன்\n$p1 $p2 சாந்தி அல்லது அதற்கு இணையான கர்மங்களை செய்வது நல்லது.',
            'te': 'ఈ సమయం $p1 $p2 దశా సంధి అయినందున పై సమయానికి 6 నెలల ముందు\n$p1 $p2 శాంతి లేదా తత్సమాన కర్మలు చేయడం మంచిది.',
            'ml': 'ഈ സമയം $p1 $p2 ദശാ സന്ധി ആയതിനാൽ മേൽ പറഞ്ഞ സമയത്തിന് 6 മാസം മുമ്പ്\n$p1 $p2 ശാന്തി അല്ലെങ്കിൽ തത്തുല്യ കർമ്മങ്ങൾ ആചരിക്കുന്നത് ഉത്തമം.',
            'en': 'This is $p1 $p2 Dasha Sandhi period. It is recommended to perform $p1 $p2 Shanti or equivalent rituals 6 months before the above date.',
          }[_loc] ?? 'ಈ ಸಮಯವು $p1 $p2 ದಶ ಸಂಧಿ ಆಗಿರುವುದರಿಂದ ಮೇಲೆ ತಿಳಿಸಿದ ಸಮಯಕ್ಕಿಂತ 6 ತಿಂಗಳ ಪೂರ್ವದಲ್ಲಿ\n$p1 $p2 ಶಾಂತಿ ಅಥವಾ ತತ್ಸಮಾನ ಕರ್ಮಗಳನ್ನು ಆಚರಿಸುವುದು ಉತ್ತಮ.';

          // ── Collect sandhi notices ──
          final sandhiNotices = <Map<String, dynamic>>[];
          for (final md in r.dashas) {
            final def = _sandhiDef[md.lord];
            if (def == null) continue;
            final names = def[_loc] ?? def['kn']!;
            sandhiNotices.add({
              'p1': names[0], 'p2': names[1],
              'dashaEnd': md.end,
            });
          }
          // Sort by nearest date first
          sandhiNotices.sort((a, b) {
            final now = DateTime.now();
            final diffA = (a['dashaEnd'] as DateTime).difference(now).inDays.abs();
            final diffB = (b['dashaEnd'] as DateTime).difference(now).inDays.abs();
            return diffA.compareTo(diffB);
          });

          return Column(
            children: [
              if (allPersons.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                ),
              AppCard(
                child: Text(
                  '${AppLocale.l('dashaLord')}: ${trAll(pan.dashaLord)}  ${AppLocale.l('dashaBalance')}: ${_trDashaBalance(pan.dashaBalance)}',
                  style: TextStyle(color: kOrange, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              DashaWidget(dashas: r.dashas),

              // ── Sandhi Soochane ──
              if (sandhiNotices.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...sandhiNotices.map((s) {
                  final dashaEnd = s['dashaEnd'] as DateTime;
                  final endStr = '${dashaEnd.day.toString().padLeft(2,"0")}/${dashaEnd.month.toString().padLeft(2,"0")}/${dashaEnd.year}';
                  final p1 = s['p1'] as String;
                  final p2 = s['p2'] as String;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title: ರಾಹು ಬೃಹಸ್ಪತಿ ಸಂಧಿ ಕಾಲ
                        Text(_sandhiTitle(p1, p2), style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900, color: Colors.deepOrange,
                        )),
                        const SizedBox(height: 8),
                        // Date: ರಾಹು ದಶಾ ಅಂತ್ಯ DD/MM/YYYY
                        Text(_dashaEnd(p1, endStr), style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: kText,
                        )),
                        const SizedBox(height: 10),
                        // Description paragraph
                        Text(_sandhiDesc(p1, p2), style: TextStyle(
                          fontSize: 12.5, color: kText, height: 1.5,
                        )),
                      ],
                    ),
                  );
                }),
              ],

              if (allPersons.length > 1) Divider(thickness: 1, color: kBorder),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 6: PANCHANG
  // ─────────────────────────────────────────────
  Widget _buildPanchangTab() {
    var allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult, 'dob': _primaryDob, 'hour': _primaryHour, 'minute': _primaryMinute, 'ampm': _primaryAmpm, 'place': _primaryPlace},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result, 'dob': p.dob, 'hour': p.hour, 'minute': p.minute, 'ampm': p.ampm, 'place': p.place}),
    ];
    allPersons = _filterPersons(allPersons);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pan = r.panchang;
          final pName = person['name'] as String;
          final dob = person['dob'] as DateTime;
          final dateStr = '${dob.day.toString().padLeft(2,"0")}-${dob.month.toString().padLeft(2,"0")}-${dob.year}';
          final timeStr = '${person["hour"]}:${(person["minute"] as int).toString().padLeft(2,"0")} ${person["ampm"]}';

          // Calculate age
          final now = DateTime.now();
          int ageYears = now.year - dob.year;
          int ageMonths = now.month - dob.month;
          int ageDays = now.day - dob.day;
          if (ageDays < 0) {
            ageMonths--;
            final prevMonth = DateTime(now.year, now.month, 0);
            ageDays += prevMonth.day;
          }
          if (ageMonths < 0) {
            ageYears--;
            ageMonths += 12;
          }
          final ageStr = '$ageYears ${AppLocale.l('yearShort')} $ageMonths ${AppLocale.l('monthShort')} $ageDays ${AppLocale.l('dayShort')}';

          // Find current Dasha and Bhukti from existing r.dashas
          String currentDasha = '';
          String dashaEnd = '';
          String currentBhukti = '';
          String bhuktiEnd = '';
          for (final md in r.dashas) {
            if (now.isAfter(md.start) && now.isBefore(md.end)) {
              currentDasha = trAll(md.lord);
              dashaEnd = '${md.end.day.toString().padLeft(2,"0")}-${md.end.month.toString().padLeft(2,"0")}-${md.end.year}';
              for (final ad in md.antardashas) {
                if (now.isAfter(ad.start) && now.isBefore(ad.end)) {
                  currentBhukti = trAll(ad.lord);
                  bhuktiEnd = '${ad.end.day.toString().padLeft(2,"0")}-${ad.end.month.toString().padLeft(2,"0")}-${ad.end.year}';
                  break;
                }
              }
              break;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allPersons.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                ),
              AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (pName.isNotEmpty) _kv(AppLocale.l('nameLabel'), pName, big: true),
                _kv(AppLocale.l('placeLabel'), person['place'] as String, big: true),
                _kv(AppLocale.l('dateLabel'), dateStr, big: true),
                _kv(AppLocale.l('timeLabel'), timeStr, big: true),
                _kv(AppLocale.l('dashaLord'), '${trAll(pan.dashaLord)}  ${AppLocale.l('dashaBalance')}: ${_trDashaBalance(pan.dashaBalance)}', big: true),
                const Divider(height: 16),
                _kv(AppLocale.l('ageLabel'), ageStr, big: true),
                if (currentDasha.isNotEmpty) ...[
                  const Divider(height: 16),
                  _kv('${AppLocale.l('dasha')}', '$currentDasha  (${AppLocale.l('end')}: $dashaEnd)', big: true),
                  if (currentBhukti.isNotEmpty)
                    _kv(AppLocale.l('bhuktiLabel'), '$currentBhukti  (${AppLocale.l('end')}: $bhuktiEnd)', big: true),
                ],
              ])),
              const SizedBox(height: 8),
              // ── 📋 Panchanga (5 Angas) ──
              _sectionLabel('📋 ${AppLocale.l('pHeading')}', kPurple2),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _tableRow([AppLocale.l('varaLabel'), trAll(pan.vara)], big: true),
                  _tableRow([AppLocale.l('tithiLabel'), '${trAll(pan.tithi)}${pan.tithiGata.isNotEmpty || pan.tithiParama.isNotEmpty ? ' (${AppLocale.l('gataGhati')}: ${pan.tithiGata}, ${AppLocale.l('paramaGhati')}: ${pan.tithiParama})' : ''}'], big: true),
                  _tableRow([AppLocale.l('chandraNakshatra'), () { final moonPada = r.planets['ಚಂದ್ರ']?.pada; final fallback = (pan.nakPercent * 4).floor() + 1; final p = moonPada ?? (fallback < 1 ? 1 : fallback > 4 ? 4 : fallback); return '${trAll(pan.nakshatra)} - ${AppLocale.l('padaLabel')} $p'; }()], big: true),
                  _tableRow([AppLocale.l('yogaLabel'), '${trAll(pan.yoga)}${pan.yogaGata.isNotEmpty ? ' (${AppLocale.l('gataGhati')}: ${pan.yogaGata})' : ''}'], big: true),
                  _tableRow([AppLocale.l('karanaLabel'), '${trAll(pan.karana)}${pan.karanaGata.isNotEmpty ? ' (${AppLocale.l('gataGhati')}: ${pan.karanaGata})' : ''}'], big: true),
                ]),
              ),
              const SizedBox(height: 8),

              // ── ☀️ Ravi (Sun) Details ──
              _sectionLabel('☀️ ${AppLocale.l('raviVivar')}', Colors.orange),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _tableRow([AppLocale.l('sunrise'), pan.sunrise], big: true),
                  _tableRow([AppLocale.l('sunset'), pan.sunset], big: true),
                  _tableRow([AppLocale.l('divamana'), pan.divamana], big: true),
                  _tableRow([AppLocale.l('ratrimana'), pan.ratrimana], big: true),
                  _tableRow([AppLocale.l('udayadiGhati'), pan.udayadiGhati], big: true),
                  _tableRow([AppLocale.l('suryaNakshatraLabel'), '${trAll(pan.suryaNakshatra)} - ${AppLocale.l('padaLabel')} ${pan.suryaPada}'], big: true),
                  _tableRow([AppLocale.l('souraMasa'), trAll(pan.souraMasa)], big: true),
                  _tableRow([AppLocale.l('souraMasaGataDina'), pan.souraMasaGataDina], big: true),
                ]),
              ),
              const SizedBox(height: 8),

              // ── 🌙 Chandra (Moon) Details ──
              _sectionLabel('🌙 ${AppLocale.l('chandraVivar')}', Colors.blue),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _tableRow([AppLocale.l('chandraNakshatra'), () { final moonPada = r.planets['ಚಂದ್ರ']?.pada; final fallback = (pan.nakPercent * 4).floor() + 1; final p = moonPada ?? (fallback < 1 ? 1 : fallback > 4 ? 4 : fallback); return '${trAll(pan.nakshatra)} - ${AppLocale.l('padaLabel')} $p (${AppLocale.l('gataGhati')}: ${pan.gataGhati}, ${AppLocale.l('paramaGhati')}: ${pan.paramaGhati})'; }()], big: true),
                  _tableRow([AppLocale.l('chandraRashiLabel'), trAll(pan.chandraRashi)], big: true),
                  _tableRow([AppLocale.l('chandraMasa'), trAll(pan.chandraMasa)], big: true),
                  _tableRow([AppLocale.l('samvatsara'), trAll(pan.samvatsara)], big: true),
                  _tableRow([AppLocale.l('tithiLabel'), '${trAll(pan.tithi)}${pan.tithiGata.isNotEmpty || pan.tithiParama.isNotEmpty ? ' (${AppLocale.l('gataGhati')}: ${pan.tithiGata}, ${AppLocale.l('paramaGhati')}: ${pan.tithiParama})' : ''}'], big: true),
                  _tableRow([AppLocale.l('gataGhati'), pan.gataGhati], big: true),
                  _tableRow([AppLocale.l('paramaGhati'), pan.paramaGhati], big: true),
                  _tableRow([AppLocale.l('sheshaGhati'), pan.shesha], big: true),
                  _tableRow([AppLocale.l('vishaPraghati'), pan.vishaPraghati], big: true),
                  _tableRow([AppLocale.l('amrutaPraghati'), pan.amrutaPraghati], big: true),
                ]),
              ),
              if (allPersons.length > 1) Divider(thickness: 2, color: kBorder),
              const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ),
    );
  }
  // ─────────────────────────────────────────────
  // TAB 7.5: BHAVA DREKKAANA
  // ─────────────────────────────────────────────
  Widget _buildBhavaDrekkaanaTab() {
    var allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];
    allPersons = _filterPersons(allPersons);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pName = person['name'] as String;

          final title = AppLocale.l('grahaVishlesha');

          final hBhava = AppLocale.l('hBhava');
          final hD9 = AppLocale.l('hD9');
          final hD3D1 = AppLocale.l('hD3');
          final hD3D9 = AppLocale.l('hD9');
          final hD3D12 = AppLocale.l('hD12');

          return Column(
            children: [
              if (allPersons.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                ),
              Text(title, style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15,
                color: kPurple2)),
              const SizedBox(height: 12),
              
              AppCard(
                padding: EdgeInsets.zero,
                child: Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(color: kBorder),
                    verticalInside: BorderSide(color: kBorder),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1.4),
                    3: FlexColumnWidth(1.4),
                    4: FlexColumnWidth(1.4),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: kPurple2.withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                      children: [
                        Padding(padding: const EdgeInsets.all(8), child: Text(hBhava, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(hD9, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(hD3D1, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(hD3D9, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(hD3D12, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                      ],
                    ),
                    ...List.generate(12, (i) {
                      final madhya = r.bhavas[i];
                      final details = AstroCalculator.getPlanetDetail('ಲಗ್ನ', madhya, 0, 0);

                      // Helper to translate 'Rashi N' format
                      String formatPart(String raw) {
                        final parts = raw.split(' ');
                        if (parts.length == 2) {
                          return '${parts[0]} ${parts[1]}';
                        }
                        return raw;
                      }

                      return TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text('${i+1}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(details['d9'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(formatPart(details['subDrekD1'] as String), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(formatPart(details['subDrekD9'] as String), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(formatPart(details['subDrekD12'] as String), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(AppLocale.l('shadvargaTitle'), style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15,
                color: kPurple2)),
              const SizedBox(height: 12),
              AppCard(
                padding: EdgeInsets.zero,
                child: Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(color: kBorder),
                    verticalInside: BorderSide(color: kBorder),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(0.8),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1),
                    5: FlexColumnWidth(1),
                    6: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: kPurple2.withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                      children: [
                        Padding(padding: const EdgeInsets.all(6), child: Text(hBhava, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('D1', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('D2', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('D3', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('D9', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('D12', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('D30', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                      ],
                    ),
                    ...List.generate(12, (i) {
                      final madhya = r.bhavas[i];
                      final details = AstroCalculator.getPlanetDetail('ಲಗ್ನ', madhya, 0, 0);

                      return TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(6), child: Text('${i+1}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(details['d1'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(details['d2'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(details['d3'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(details['d9'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(details['d12'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(details['d30'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Dashavarga: Remaining 10 divisional charts ──
              Text('ದಶವರ್ಗ — Additional Divisional Charts', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15,
                color: kPurple2)),
              const SizedBox(height: 4),
              Text('D4, D7, D10, D16, D20, D24, D27, D40, D45, D60', style: TextStyle(fontSize: 11, color: kMuted)),
              const SizedBox(height: 12),
              AppCard(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(color: kBorder),
                      verticalInside: BorderSide(color: kBorder),
                    ),
                    defaultColumnWidth: const FixedColumnWidth(52),
                    columnWidths: const {0: FixedColumnWidth(36)},
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: kTeal.withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                        children: [
                          for (final h in ['#', 'D4', 'D7', 'D10', 'D16', 'D20', 'D24', 'D27', 'D40', 'D45', 'D60'])
                            Padding(padding: const EdgeInsets.all(6), child: Text(h, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10))),
                        ],
                      ),
                      ...List.generate(12, (i) {
                        final madhya = r.bhavas[i];
                        final details = AstroCalculator.getPlanetDetail('ಲಗ್ನ', madhya, 0, 0);
                        final keys = ['d4','d7','d10','d16','d20','d24','d27','d40','d45','d60'];

                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(6), child: Text('${i+1}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
                            ...keys.map((k) => Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(details[k] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                            )),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Varga Kundali Chart Boxes ──
              Text('ವರ್ಗ ಕುಂಡಲಿಗಳು — Varga Kundalis', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15,
                color: kPurple2)),
              const SizedBox(height: 12),
              ...([
                [4, 'D4 ಚತುರ್ಥಾಂಶ'],
                [7, 'D7 ಸಪ್ತಾಂಶ'],
                [10, 'D10 ದಶಾಂಶ'],
                [16, 'D16 ಷೋಡಶಾಂಶ'],
                [20, 'D20 ವಿಂಶಾಂಶ'],
                [24, 'D24 ಚತುರ್ವಿಂಶಾಂಶ'],
                [27, 'D27 ಸಪ್ತವಿಂಶಾಂಶ'],
                [40, 'D40 ಖವೇದಾಂಶ'],
                [45, 'D45 ಅಕ್ಷವೇದಾಂಶ'],
                [60, 'D60 ಷಷ್ಠ್ಯಂಶ'],
              ].map((v) => Column(
                children: [
                  Text(v[1] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kTeal)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 320,
                    child: KundaliChart(
                      result: r,
                      varga: v[0] as int,
                      isBhava: false,
                      showSphutas: false,
                      centerLabel: v[1] as String,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ))),
              if (allPersons.length > 1) const SizedBox(height: 16),
            ]
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 7: BHAVA
  // ─────────────────────────────────────────────
  Widget _buildBhavaTab() {
    var allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];
    allPersons = _filterPersons(allPersons);

    // Planet selector list
    final selectablePlanets = planetOrder.where((p) => p != 'ಲಗ್ನ' && p != 'ಮಾಂದಿ').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Planet selector (for primary person)
          Text(AppLocale.l('bhavaKaksha'), style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              GestureDetector(
                onTap: () => setState(() => _bhavaPlanet = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _bhavaPlanet == null ? kTeal : kCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _bhavaPlanet == null ? kTeal : kBorder),
                  ),
                  child: Text(AppLocale.l('lagna'), style: TextStyle(
                    fontSize: 13,
                    fontWeight: _bhavaPlanet == null ? FontWeight.w900 : FontWeight.w600,
                    color: _bhavaPlanet == null ? Colors.white : kText,
                  )),
                ),
              ),
              ...selectablePlanets.map((p) {
                final isSelected = _bhavaPlanet == p;
                return GestureDetector(
                  onTap: () => setState(() => _bhavaPlanet = isSelected ? null : p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? kTeal : kCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? kTeal : kBorder),
                    ),
                    child: Text(tr(p), style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected ? Colors.white : kText,
                    )),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Multi-person bhava madhya tables
          ...allPersons.map((person) {
            final r = person['result'] as KundaliResult;
            final pName = person['name'] as String;
            final lagnaLong = r.planets['ಲಗ್ನ']?.longitude ?? 0;

            List<double> getMadhyas(String? planet) {
              if (planet == null || !r.planets.containsKey(planet)) return r.bhavas;
              final pDeg = r.planets[planet]!.longitude;
              final offset = (pDeg - lagnaLong + 360.0) % 360.0;
              return List.generate(12, (i) => (r.bhavas[i] + offset) % 360.0);
            }

            final currentMadhyas = getMadhyas(_bhavaPlanet);
            final title = _bhavaPlanet != null
                ? '${AppLocale.l('bhavaRecalc')} (${trAll(_bhavaPlanet!)})'
                : '${AppLocale.l('bhavaRecalcFor')} (${AppLocale.l('lagna')})';

            // Compute Adi (start) and Antya (end) sphuta for each bhava
            String rashiName(double deg) {
              final idx = (deg / 30).floor() % 12;
              return appRashi[idx];
            }

            Widget bhavaCell(double deg) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatDeg(deg), style: TextStyle(fontSize: 11, color: kText)),
                      const SizedBox(height: 2),
                      Text(rashiName(deg), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kPurple2)),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                if (allPersons.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                  ),
                Text(title, style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15,
                  color: _bhavaPlanet != null ? kTeal : kPurple2)),
                const SizedBox(height: 8),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _tableHeader([AppLocale.l('hBhavaNo'), AppLocale.l('hBhavaStart'), AppLocale.l('hBhavaMid'), AppLocale.l('hBhavaEnd')]),
                      ...List.generate(12, (i) {
                        final madhya = currentMadhyas[i];
                        final prevMadhya = currentMadhyas[(i + 11) % 12];
                        final nextMadhya = currentMadhyas[(i + 1) % 12];

                        // Adi = midpoint of previous madhya and current madhya
                        final adiDiff = (madhya - prevMadhya + 360.0) % 360.0;
                        final adi = (prevMadhya + adiDiff / 2.0) % 360.0;

                        // Antya = midpoint of current madhya and next madhya
                        final antyaDiff = (nextMadhya - madhya + 360.0) % 360.0;
                        final antya = (madhya + antyaDiff / 2.0) % 360.0;

                        return Container(
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 36,
                                  child: Center(child: Text('${i+1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText))),
                                ),
                                bhavaCell(adi),
                                bhavaCell(madhya),
                                bhavaCell(antya),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (allPersons.length > 1) Divider(thickness: 2, color: kBorder),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 7.6: GRAHA SHADVARGA
  // ─────────────────────────────────────────────
  Widget _buildGrahaShadvargaTab() {
    var allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];
    allPersons = _filterPersons(allPersons);

    final hGraha = AppLocale.l('hGraha');
    final hD3 = AppLocale.l('hD3');
    final hD2 = AppLocale.l('hD2');
    final hD9 = AppLocale.l('hD9');
    final hD30 = AppLocale.l('hD30');
    final hD12 = AppLocale.l('hD12');
    final hKshetra = AppLocale.l('hKshetra');

    String getRashiLord(String rashiNameKn) {
      int idx = knRashi.indexOf(rashiNameKn);
      if (idx < 0) return rashiNameKn; 
      
      final lordAbbr = const <String, List<String>>{
        'kn': ['ಕು','ಶು','ಬು','ಚ','ರ','ಬು','ಶು','ಕು','ಗು','ಶ','ಶ','ಗು'],
        'hi': ['मं','शु','बु','चं','सू','बु','शु','मं','गु','श','श','गु'],
        'ta': ['செ','சு','பு','சந்','சூ','பு','சு','செ','கு','ச','ச','கு'],
        'te': ['కు','శు','బు','చం','ర','బు','శు','కు','గు','శ','శ','గు'],
        'ml': ['കു','ശു','ബു','ചം','ര','ബു','ശു','കു','ഗു','ശ','ശ','ഗു'],
        'en': ['Ma','Ve','Me','Mo','Su','Me','Ve','Ma','Ju','Sa','Sa','Ju'],
      };
      return (lordAbbr[AppLocale.current] ?? lordAbbr['kn']!)[idx];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pName = person['name'] as String;
          int rowIdx = 0;

          return Column(
            children: [
              if (allPersons.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                ),
              // Title with gradient accent
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [kPurple1.withOpacity(0.12), kPurple2.withOpacity(0.06)]),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14), topRight: Radius.circular(14),
                  ),
                  border: Border(bottom: BorderSide(color: kPurple2.withOpacity(0.3), width: 2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_view_rounded, size: 18, color: kPurple2),
                    const SizedBox(width: 8),
                    Text(AppLocale.l('shadvarga'), style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16, color: kPurple2,
                    )),
                  ],
                ),
              ),
              
              // Table
              Container(
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
                  ),
                  border: Border.all(color: kBorder),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
                  ),
                  child: Table(
                    border: TableBorder.symmetric(
                      inside: BorderSide(color: kBorder.withOpacity(0.6), width: 0.5),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(1.3),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                      4: FlexColumnWidth(1),
                      5: FlexColumnWidth(1),
                      6: FlexColumnWidth(1),
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [kPurple1.withOpacity(0.15), kPurple2.withOpacity(0.08)]),
                        ),
                        children: [hGraha, hD3, hD2, hD9, hD30, hD12, hKshetra].map((h) =>
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(h, textAlign: TextAlign.center, style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 14, color: kPurple2,
                            )),
                          ),
                        ).toList(),
                      ),
                      // Data rows with alternating shading
                      ...planetOrder.map((pNameKey) {
                        final pInfo = r.planets[pNameKey];
                        if (pInfo == null) return const TableRow(children: [SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox()]);
                        
                        final details = AstroCalculator.getPlanetDetail(pNameKey, pInfo.longitude, pInfo.speed, r.planets['ರವಿ']?.longitude ?? 0.0);
                        final displayName = tr(pNameKey);
                        final isEvenRow = rowIdx++ % 2 == 0;

                        return TableRow(
                          decoration: BoxDecoration(
                            color: isEvenRow ? kBg.withOpacity(0.5) : kCard,
                          ),
                          children: [
                            // Planet name column
                            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(
                              displayName, textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kTeal),
                            )),
                            // Varga lord columns
                            ...[details['d3'], details['d2'], details['d9'], details['d30'], details['d12'], details['d1']].map((v) =>
                              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(
                                getRashiLord(v as String), textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText),
                              )),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              if (allPersons.length > 1) const SizedBox(height: 24),

              const SizedBox(height: 24),

              // ── Dashavarga: Additional 10 divisional charts ──
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [kTeal.withOpacity(0.12), kTeal.withOpacity(0.06)]),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14), topRight: Radius.circular(14),
                  ),
                  border: Border(bottom: BorderSide(color: kTeal.withOpacity(0.3), width: 2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dashboard_rounded, size: 18, color: kTeal),
                    const SizedBox(width: 8),
                    Text('ಷೋಡಶವರ್ಗ', style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16, color: kTeal,
                    )),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
                  ),
                  border: Border.all(color: kBorder),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Table(
                      border: TableBorder.symmetric(
                        inside: BorderSide(color: kBorder.withOpacity(0.6), width: 0.5),
                      ),
                      defaultColumnWidth: const FixedColumnWidth(52),
                      columnWidths: const {0: FixedColumnWidth(80)},
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [kTeal.withOpacity(0.15), kTeal.withOpacity(0.08)]),
                          ),
                          children: [
                            for (final h in [hGraha, 'D4', 'D7', 'D10', 'D16', 'D20', 'D24', 'D27', 'D40', 'D45', 'D60'])
                              Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(h, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: kTeal))),
                          ],
                        ),
                        ...planetOrder.map((pNameKey) {
                          final pInfo = r.planets[pNameKey];
                          if (pInfo == null) return TableRow(children: List.generate(11, (_) => const SizedBox()));
                          final details = AstroCalculator.getPlanetDetail(pNameKey, pInfo.longitude, pInfo.speed, r.planets['ರವಿ']?.longitude ?? 0.0);
                          final displayName = tr(pNameKey);
                          final keys = ['d4','d7','d10','d16','d20','d24','d27','d40','d45','d60'];
                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(displayName, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kTeal))),
                              ...keys.map((k) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(getRashiLord(details[k] as String), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
                              )),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Varga Kundali Chart Boxes ──
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [kPurple1.withOpacity(0.12), kPurple2.withOpacity(0.06)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border(bottom: BorderSide(color: kPurple2.withOpacity(0.3), width: 2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_mosaic_rounded, size: 18, color: kPurple2),
                    const SizedBox(width: 8),
                    Text('ವರ್ಗ ಕುಂಡಲಿಗಳು', style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16, color: kPurple2,
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...([
                [4, 'D4 ಚತುರ್ಥಾಂಶ'],
                [7, 'D7 ಸಪ್ತಾಂಶ'],
                [10, 'D10 ದಶಾಂಶ'],
                [16, 'D16 ಷೋಡಶಾಂಶ'],
                [20, 'D20 ವಿಂಶಾಂಶ'],
                [24, 'D24 ಚತುರ್ವಿಂಶಾಂಶ'],
                [27, 'D27 ಸಪ್ತವಿಂಶಾಂಶ'],
                [40, 'D40 ಖವೇದಾಂಶ'],
                [45, 'D45 ಅಕ್ಷವೇದಾಂಶ'],
                [60, 'D60 ಷಷ್ಠ್ಯಂಶ'],
              ].map((v) => Column(
                children: [
                  Text(v[1] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kTeal)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 320,
                    child: KundaliChart(
                      result: r,
                      varga: v[0] as int,
                      isBhava: false,
                      showSphutas: false,
                      centerLabel: v[1] as String,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ))),
            ]
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 8: SHADBALA
  // ─────────────────────────────────────────────
  // ─────────────────────────────────────────────
  // TAB 8: ASHTAKA VARGA (multi-person)
  // ─────────────────────────────────────────────
  Widget _buildAshtakaTab() {
    var allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];
    allPersons = _filterPersons(allPersons);

    if (allPersons.length == 1) {
      return AshtakaVargaWidget(result: _primaryResult);
    }

    return SingleChildScrollView(
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pName = person['name'] as String;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
              ),
              AshtakaVargaWidget(result: r),
              Divider(thickness: 2, color: kBorder),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShadbalaTab() {
    var allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];
    allPersons = _filterPersons(allPersons);

    if (allPersons.length == 1) {
      return ShadbalaWidget(key: UniqueKey(), shadbala: _primaryResult.shadbala);
    }

    return SingleChildScrollView(
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pName = person['name'] as String;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
              ),
              ShadbalaWidget(key: UniqueKey(), shadbala: r.shadbala),
              Divider(thickness: 2, color: kBorder),
            ],
          );
        }).toList(),
      ),
    );
  }



  // ─────────────────────────────────────────────
  // TAB 10: NOTES
  // ─────────────────────────────────────────────
  final Map<String, TextEditingController> _noteControllers = {};

  TextEditingController _getNoteController(String name) {
    if (!_noteControllers.containsKey(name)) {
      _noteControllers[name] = TextEditingController();
    }
    return _noteControllers[name]!;
  }
  
  void _saveIndividualNote(String name, bool isPrimary, PersonEntry? entry, String newNotes) {
    final cId = widget.extraInfo['clientId'] ?? '';
    
    if (isPrimary) {
      StorageService.save(Profile(
        name: widget.name, date: '${widget.dob.year}-${widget.dob.month.toString().padLeft(2, '0')}-${widget.dob.day.toString().padLeft(2, '0')}',
        hour: widget.hour, minute: widget.minute, ampm: widget.ampm, lat: widget.lat, lon: widget.lon, place: widget.place,
        tzOffset: _primaryTz, notes: newNotes, aroodhas: _aroodhas, janmaNakshatraIdx: _janmaNakshatraIdx, clientId: (cId is String && cId.isNotEmpty) ? cId : null,
        prastutaTime: _prastutaTime?.toIso8601String(),
      ));
      if (cId is String && cId.isNotEmpty) {
        ClientService.updateFamilyMember(FamilyMember(clientId: cId, memberName: widget.name, relation: 'Self', dob: '${widget.dob.year}-${widget.dob.month.toString().padLeft(2, '0')}-${widget.dob.day.toString().padLeft(2, '0')}', birthTime: '${widget.hour.toString().padLeft(2,'0')}:${widget.minute.toString().padLeft(2,'0')} ${widget.ampm}', birthPlace: widget.place, lat: widget.lat, lon: widget.lon, notes: newNotes));
      }
    } else if (entry != null) {
       final dateStr = '${entry.dob.year}-${entry.dob.month.toString().padLeft(2, '0')}-${entry.dob.day.toString().padLeft(2, '0')}';
       StorageService.save(Profile(
         name: entry.name, date: dateStr, hour: entry.hour, minute: entry.minute, ampm: entry.ampm, lat: entry.lat, lon: entry.lon, place: entry.place,
         tzOffset: entry.tz, notes: newNotes, clientId: (cId is String && cId.isNotEmpty) ? cId : null,
       ));
       if (cId is String && cId.isNotEmpty) {
         ClientService.updateFamilyMember(FamilyMember(clientId: cId, memberName: entry.name, relation: 'Group Member', dob: dateStr, birthTime: '${entry.hour.toString().padLeft(2,'0')}:${entry.minute.toString().padLeft(2,'0')} ${entry.ampm}', birthPlace: entry.place, lat: entry.lat, lon: entry.lon, notes: newNotes));
       }
    }
  }

  /// Show dialog to configure and generate Tippani PDF
  void _showTippaniPdfDialog(String name, bool isPrimary, PersonEntry? entry, List<Map<String, String>> noteEntries) {
    final dobDate = isPrimary ? widget.dob : entry!.dob;
    final dobStr = '${dobDate.day.toString().padLeft(2, '0')}-${dobDate.month.toString().padLeft(2, '0')}-${dobDate.year}';
    final birthHour = isPrimary ? widget.hour : entry!.hour;
    final birthMin = isPrimary ? widget.minute : entry!.minute;
    final birthAmpm = isPrimary ? widget.ampm : entry!.ampm;
    final birthPlace = isPrimary ? widget.place : entry!.place;
    final timeStr = '${birthHour.toString().padLeft(2, '0')}:${birthMin.toString().padLeft(2, '0')} $birthAmpm';
    final clientId = widget.extraInfo['clientId'] ?? '';
    final activeResult = isPrimary ? _primaryResult : entry!.result;

    // All notes selected by default
    final selectedNotes = List<bool>.filled(noteEntries.length, true);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final selectedCount = selectedNotes.where((s) => s).length;
            return AlertDialog(
              backgroundColor: kCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.deepOrange, size: 24),
                  const SizedBox(width: 8),
                  Expanded(child: Text(AppLocale.l('tippaniPdf'), style: TextStyle(fontWeight: FontWeight.w900, color: kText, fontSize: 18))),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(AppLocale.l('mangalaShloka'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _tippaniInvocationCtrl,
                        decoration: InputDecoration(
                          hintText: 'ಶ್ರೀ ಗಣೇಶಾಯ ನಮಃ',
                          prefixIcon: Icon(Icons.auto_awesome, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => _saveJyotishiDetails(),
                      ),
                      const SizedBox(height: 14),
                      Text(AppLocale.l('jyotishiDetails'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _jyotishiNameCtrl,
                        decoration: InputDecoration(
                          labelText: AppLocale.l('nameLabel'),
                          prefixIcon: Icon(Icons.storefront, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => _saveJyotishiDetails(),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _tippaniAddressCtrl,
                        decoration: InputDecoration(
                          labelText: AppLocale.l('addressLabel'),
                          prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        maxLines: 2,
                        onChanged: (_) => _saveJyotishiDetails(),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _jyotishiPhoneCtrl,
                        decoration: InputDecoration(
                          labelText: AppLocale.l('phoneLabel'),
                          prefixIcon: Icon(Icons.phone, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => _saveJyotishiDetails(),
                      ),
                      const SizedBox(height: 14),

                      // ── Note Selection ──
                      if (noteEntries.isNotEmpty) ...[
                        Row(
                          children: [
                            Text(AppLocale.l('noteSelection'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
                            const Spacer(),
                            Text('$selectedCount/${noteEntries.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kTeal)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                final allSelected = selectedNotes.every((s) => s);
                                setDialogState(() {
                                  for (int i = 0; i < selectedNotes.length; i++) {
                                    selectedNotes[i] = !allSelected;
                                  }
                                });
                              },
                              child: Text(
                                selectedNotes.every((s) => s) ? AppLocale.l('deselectAll') : AppLocale.l('selectAll'),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.deepOrange),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kBorder),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: noteEntries.length,
                            itemBuilder: (_, i) {
                              final note = noteEntries[i];
                              return CheckboxListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                controlAffinity: ListTileControlAffinity.leading,
                                value: selectedNotes[i],
                                onChanged: (v) => setDialogState(() => selectedNotes[i] = v ?? false),
                                activeColor: Colors.deepOrange,
                                title: Text(
                                  note['text'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: kText),
                                ),
                                subtitle: Text(
                                  note['date'] ?? '',
                                  style: TextStyle(fontSize: 10, color: kMuted),
                                ),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kBorder),
                          ),
                          child: Text('ಟಿಪ್ಪಣಿಗಳಿಲ್ಲ', style: TextStyle(fontSize: 12, color: kMuted, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocale.l('cancel'), style: TextStyle(color: kMuted)),
                ),
                ElevatedButton.icon(
                  onPressed: selectedCount == 0 && noteEntries.isNotEmpty ? null : () async {
                    Navigator.pop(ctx);
                    final rashi = activeResult.panchang.chandraRashi;
                    final nakshatra = activeResult.panchang.nakshatra;
                    // Filter only selected notes
                    final filteredNotes = <Map<String, String>>[];
                    for (int i = 0; i < noteEntries.length; i++) {
                      if (selectedNotes[i]) filteredNotes.add(noteEntries[i]);
                    }
                    final data = TippaniData(
                      name: name,
                      dateStr: dobStr,
                      timeStr: timeStr,
                      place: birthPlace,
                      clientId: clientId is String ? clientId : '',
                      rashi: rashi,
                      nakshatra: nakshatra,
                      invocationText: _tippaniInvocationCtrl.text.trim(),
                      astrologerName: _jyotishiNameCtrl.text.trim(),
                      astrologerAddress: _tippaniAddressCtrl.text.trim(),
                      astrologerPhone: _jyotishiPhoneCtrl.text.trim(),
                      notes: filteredNotes,
                    );
                    final selectedTheme = PdfThemes.all.firstWhere((t) => t.id == _selectedThemeId, orElse: () => PdfThemes.traditional);
                    await TippaniPdfService.generateAndPrint(data, theme: selectedTheme);
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: Text('${AppLocale.l('createPdf')} ($selectedCount)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange, foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: selectedCount == 0 && noteEntries.isNotEmpty ? null : () async {
                    Navigator.pop(ctx);
                    final rashi = activeResult.panchang.chandraRashi;
                    final nakshatra = activeResult.panchang.nakshatra;
                    final filteredNotes = <Map<String, String>>[];
                    for (int i = 0; i < noteEntries.length; i++) {
                      if (selectedNotes[i]) filteredNotes.add(noteEntries[i]);
                    }
                    final data = TippaniData(
                      name: name,
                      dateStr: dobStr,
                      timeStr: timeStr,
                      place: birthPlace,
                      clientId: clientId is String ? clientId : '',
                      rashi: rashi,
                      nakshatra: nakshatra,
                      invocationText: _tippaniInvocationCtrl.text.trim(),
                      astrologerName: _jyotishiNameCtrl.text.trim(),
                      astrologerAddress: _tippaniAddressCtrl.text.trim(),
                      astrologerPhone: _jyotishiPhoneCtrl.text.trim(),
                      notes: filteredNotes,
                    );
                    final selectedTheme = PdfThemes.all.firstWhere((t) => t.id == _selectedThemeId, orElse: () => PdfThemes.traditional);
                    await TippaniPdfService.generateAndShare(data, theme: selectedTheme);
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: Text('${AppLocale.l('pdfShareDirect')} ($selectedCount)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(color: Colors.deepOrange, width: 1.5),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildIndividualNoteSection({required String name, required bool isPrimary, required PersonEntry? entry}) {
    final currentNotes = isPrimary ? _notes : (entry?.notes ?? '');
    final entries = _parseNoteEntries(currentNotes);
    final ctrl = _getNoteController(name);
    
    void shareNotes() {
      final dobDate = isPrimary ? widget.dob : entry!.dob;
      final dobStr = '${dobDate.day.toString().padLeft(2, '0')}-${dobDate.month.toString().padLeft(2, '0')}-${dobDate.year}';
      final birthHour = isPrimary ? widget.hour : entry!.hour;
      final birthMin = isPrimary ? widget.minute : entry!.minute;
      final birthAmpm = isPrimary ? widget.ampm : entry!.ampm;
      final birthPlace = isPrimary ? widget.place : entry!.place;
      final timeStr = '${birthHour.toString().padLeft(2, '0')}:${birthMin.toString().padLeft(2, '0')} $birthAmpm';
      final clientId = widget.extraInfo['clientId'] ?? '';
      final buf = StringBuffer();
      buf.writeln('═══════════════════════════');
      buf.writeln('   ✨ ${AppLocale.l('appName')} ✨');
      buf.writeln('═══════════════════════════\n');
      if (clientId.isNotEmpty) buf.writeln('🪪 ${AppLocale.l('idLabel')}: $clientId');
      buf.writeln('👤 ${AppLocale.l('nameLabel')}: $name');
      buf.writeln('📅 ${AppLocale.l('birthDate')}: $dobStr');
      buf.writeln('🕰️ ${AppLocale.l('birthTime')}: $timeStr');
      buf.writeln('📍 ${AppLocale.l('birthPlace')}: $birthPlace\n');
      buf.writeln('───────────────────────────');
      buf.writeln('   📝 ${AppLocale.l('notesLabel')}');
      buf.writeln('───────────────────────────\n');
      if (entries.isEmpty) {
        buf.writeln(AppLocale.l('noNotes'));
      } else {
        for (int i = 0; i < entries.length; i++) {
          buf.writeln('🕐 ${entries[i]['date']}\n   ${entries[i]['text']}');
          if (i < entries.length - 1) buf.writeln();
        }
      }
      buf.writeln('\n═══════════════════════════');
      final text = buf.toString();
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocale.l('copiedToClipboard')} ✅')));
      final encoded = Uri.encodeComponent(text);
      launchUrl(Uri.parse('https://wa.me/?text=$encoded'), mode: LaunchMode.externalApplication);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: isPrimary,
        backgroundColor: kCard,
        collapsedBackgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: kBorder)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: kBorder)),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.w900, color: kTeal)),
        subtitle: Text(isPrimary ? AppLocale.l('primaryPersonNotes') : AppLocale.l('groupMemberNotes'), style: TextStyle(fontSize: 12, color: kMuted)),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: shareNotes,
                  icon: Icon(Icons.share, size: 18),
                  label: Text(AppLocale.l('shareLabel'), style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final dobDate = isPrimary ? widget.dob : entry!.dob;
                    final dobStr = '${dobDate.day.toString().padLeft(2, '0')}-${dobDate.month.toString().padLeft(2, '0')}-${dobDate.year}';
                    final birthHour = isPrimary ? widget.hour : entry!.hour;
                    final birthMin = isPrimary ? widget.minute : entry!.minute;
                    final birthAmpm = isPrimary ? widget.ampm : entry!.ampm;
                    final birthPlace = isPrimary ? widget.place : entry!.place;
                    final timeStr = '${birthHour.toString().padLeft(2, '0')}:${birthMin.toString().padLeft(2, '0')} $birthAmpm';
                    final clientId = widget.extraInfo['clientId'] ?? '';
                    final buf = StringBuffer();
                    buf.writeln('═══════════════════════════');
                    buf.writeln('   ✨ ${AppLocale.l('appName')} ✨');
                    buf.writeln('═══════════════════════════\n');
                    if (clientId.isNotEmpty) buf.writeln('🪪 ${AppLocale.l('idLabel')}: $clientId');
                    buf.writeln('👤 ${AppLocale.l('nameLabel')}: $name');
                    buf.writeln('📅 ${AppLocale.l('birthDate')}: $dobStr');
                    buf.writeln('🕰️ ${AppLocale.l('birthTime')}: $timeStr');
                    buf.writeln('📍 ${AppLocale.l('birthPlace')}: $birthPlace\n');
                    buf.writeln('───────────────────────────');
                    buf.writeln('   📝 ${AppLocale.l('notesLabel')}');
                    buf.writeln('───────────────────────────\n');
                    if (entries.isEmpty) {
                      buf.writeln(AppLocale.l('noNotes'));
                    } else {
                      for (int i = 0; i < entries.length; i++) {
                        buf.writeln('🕐 ${entries[i]['date']}\n   ${entries[i]['text']}');
                        if (i < entries.length - 1) buf.writeln();
                      }
                    }
                    buf.writeln('\n═══════════════════════════');
                    _showPrintPreview(buf.toString());
                  },
                  icon: Icon(Icons.print, size: 18),
                  label: Text(AppLocale.l('printLabel'), style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurple2, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Tippani PDF Export Button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showTippaniPdfDialog(name, isPrimary, entry, entries),
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: Text('ಟಿಪ್ಪಣಿ PDF', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  maxLines: 8,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: AppLocale.l('addNoteHint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                    fillColor: kBg, filled: true, contentPadding: const EdgeInsets.all(12),
                  ),
                  style: TextStyle(fontSize: 14, height: 1.5, color: kText),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final text = ctrl.text.trim();
                  if (text.isEmpty) return;
                  final now = DateTime.now();
                  final stamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                  final newEntry = '[$stamp] $text';
                  setState(() {
                    String updatedNotes = currentNotes.isEmpty ? newEntry : '$newEntry\n---\n$currentNotes';
                    if (isPrimary) {
                      _notes = updatedNotes;
                    } else if (entry != null) {
                      entry.notes = updatedNotes;
                    }
                    ctrl.clear();
                    _saveIndividualNote(name, isPrimary, entry, updatedNotes);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${AppLocale.l('noteSaved')}'), backgroundColor: Colors.green));
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.send, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text(AppLocale.l('noNotes'), style: TextStyle(color: kMuted))))
          else
            ...entries.asMap().entries.map((en) {
              final i = en.key;
              final e = en.value;
              final noteText = e['text'] ?? '';
              final isLong = noteText.length > 120;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    initiallyExpanded: !isLong,
                    dense: true,
                    leading: Icon(Icons.access_time, size: 14, color: kTeal),
                    title: Row(
                      children: [
                        Expanded(child: Text(e['date'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTeal))),
                        GestureDetector(
                          onTap: () {
                            ctrl.text = e['text'] ?? '';
                            final updatedEntries = List<Map<String, String>>.from(entries);
                            updatedEntries.removeAt(i);
                            setState(() {
                              String updatedNotes = updatedEntries.map((enx) => '[${enx['date']}] ${enx['text']}').join('\n---\n');
                              if (isPrimary) _notes = updatedNotes;
                              else if (entry != null) entry.notes = updatedNotes;
                            });
                          },
                          child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: kPurple2)),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            final updatedEntries = List<Map<String, String>>.from(entries);
                            updatedEntries.removeAt(i);
                            setState(() {
                              String updatedNotes = updatedEntries.map((enx) => '[${enx['date']}] ${enx['text']}').join('\n---\n');
                              if (isPrimary) _notes = updatedNotes;
                              else if (entry != null) entry.notes = updatedNotes;
                              _saveIndividualNote(name, isPrimary, entry, updatedNotes);
                            });
                          },
                          child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent)),
                        ),
                      ],
                    ),
                    subtitle: isLong
                        ? Text(noteText.substring(0, 100) + '...', style: TextStyle(fontSize: 12, color: kMuted), maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(noteText, style: TextStyle(fontSize: 14, height: 1.4, color: kText)),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // GOCHAR (Transit) TAB
  // ─────────────────────────────────────────────
  TransitData? _gocharData;
  int _gocharLoadedYear = 0;
  bool _gocharLoading = false;

  void _loadGocharData() async {
    if (_gocharLoading || _gocharLoadedYear == _gocharYear) return;
    setState(() => _gocharLoading = true);
    final data = await TransitCache.getYear(_gocharYear);
    if (mounted) {
      setState(() {
        _gocharData = data;
        _gocharLoadedYear = _gocharYear;
        _gocharLoading = false;
      });
    }
  }

  // ═══════════════════════════════════════════
  // PREDICTION TAB — Bhava & Dasha Phala
  // ═══════════════════════════════════════════

  Widget _buildPredictionTab() {
    const _phalaStrings = <String, Map<String, String>>{
      'keyHighlights': {'kn': 'ಮುಖ್ಯ ಅಂಶಗಳು', 'hi': 'मुख्य बिंदु', 'ta': 'முக்கிய அம்சங்கள்', 'te': 'ముఖ్య అంశాలు', 'ml': 'പ്രധാന കാര്യങ്ങൾ', 'en': 'Key Highlights'},
      'currentDashaBhukti': {'kn': 'ಪ್ರಸ್ತುತ ದಶಾ-ಭುಕ್ತಿ', 'hi': 'वर्तमान दशा-भुक्ति', 'ta': 'நடப்பு தசா-புக்தி', 'te': 'ప్రస్తుత దశా-భుక్తి', 'ml': 'നിലവിലെ ദശാ-ഭുക്തി', 'en': 'Current Dasha-Bhukti'},
      'mahadasha': {'kn': 'ಮಹಾದಶಾ', 'hi': 'महादशा', 'ta': 'மகாதசா', 'te': 'మహాదశా', 'ml': 'മഹാദశా', 'en': 'Mahadasha'},
      'antardasha': {'kn': 'ಅಂತರ್ದಶಾ', 'hi': 'अंतर्दशा', 'ta': 'அந்தர்தசா', 'te': 'అంతర్దశా', 'ml': 'അന്തർദശാ', 'en': 'Antardasha'},
      'pratyantardasha': {'kn': 'ಪ್ರತ್ಯಂತರ್ದಶಾ', 'hi': 'प्रत्यंतर्दशा', 'ta': 'பிரத்யந்தர்தசா', 'te': 'ప్రత్యంతర్దశా', 'ml': 'പ്രത്യംതർദശാ', 'en': 'Pratyantardasha'},
      'sookshmadasha': {'kn': 'ಸೂಕ್ಷ್ಮದಶಾ', 'hi': 'सूक्ष्मदशा', 'ta': 'சூக்ஷ்மதசா', 'te': 'సూక్ష్మదశా', 'ml': 'സൂക്ഷ്മദശാ', 'en': 'Sookshmadasha'},
      'pranadasha': {'kn': 'ಪ್ರಾಣದಶಾ', 'hi': 'प्राणदशा', 'ta': 'பிராணதசா', 'te': 'ప్రాణదశా', 'ml': 'പ്രാണദശാ', 'en': 'Pranadasha'},
      'bhavaPhala': {'kn': 'ಭಾವ ಫಲ', 'hi': 'भाव फल', 'ta': 'பாவ பலன்', 'te': 'భావ ఫలం', 'ml': 'ഭാവ ഫലം', 'en': 'House Predictions'},
      'dashaPhala': {'kn': 'ದಶಾ ಫಲ', 'hi': 'दशा फल', 'ta': 'தசா பலன்', 'te': 'దశా ఫలం', 'ml': 'ദശാ ഫലം', 'en': 'Dasha Predictions'},
      'prasthuta': {'kn': 'ಪ್ರಸ್ತುತ', 'hi': 'वर्तमान', 'ta': 'நடப்பு', 'te': 'ప్రస్తుతం', 'ml': 'നിലവിലെ', 'en': 'Current'},
      'adhipati': {'kn': 'ಅಧಿಪತಿ: ', 'hi': 'अधिपति: ', 'ta': 'அதிபதி: ', 'te': 'అధిపతి: ', 'ml': 'അധിപതി: ', 'en': 'Lord: '},
      'bhavaGrahagalu': {'kn': 'ಭಾವ ಗ್ರಹಗಳು: ', 'hi': 'भाव ग्रह: ', 'ta': 'பாவ கிரகங்கள்: ', 'te': 'భావ గ్రహాలు: ', 'ml': 'ഭാവ ഗ്രഹങ്ങൾ: ', 'en': 'Planets in House: '},
      'drushti': {'kn': 'ದೃಷ್ಟಿ: ', 'hi': 'दृष्टि: ', 'ta': 'திருஷ்டி: ', 'te': 'దృష్టి: ', 'ml': 'ദൃഷ്ടി: ', 'en': 'Aspects: '}, // kept for reference but unused
    };
    String _pl(String key) => _phalaStrings[key]?[AppLocale.current] ?? _phalaStrings[key]?['kn'] ?? key;

    var allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult, 'isPrimary': true},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result, 'isPrimary': false}),
    ];
    allPersons = _filterPersons(allPersons);
    if (allPersons.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final name = person['name'] as String? ?? '';
          final prediction = PredictionEngine.analyze(r);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allPersons.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kOrange)),
                ),

              // ── Key Highlights ──
              if (prediction.highlights.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kPurple2.withOpacity(0.08), kOrange.withOpacity(0.08)]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPurple2.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.auto_awesome, color: kOrange, size: 18),
                        const SizedBox(width: 6),
                        Text(_pl('keyHighlights'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kOrange)),
                      ]),
                      const SizedBox(height: 8),
                      ...prediction.highlights.map((h) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('• ', style: TextStyle(color: kText, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(h, style: TextStyle(fontSize: 12, color: kText))),
                        ]),
                      )),
                    ],
                  ),
                ),

              // ── Current Dasha-Bhukti ──
              if (prediction.currentDasha != null) _buildCurrentDashaCard(prediction.currentDasha!, r.dashas, _pl),

              const SizedBox(height: 12),

              // ── Section: Bhava Phala ──
              Row(children: [
                Icon(Icons.home_work, color: kPurple2, size: 18),
                const SizedBox(width: 6),
                Text(_pl('bhavaPhala'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kPurple2)),
              ]),
              const SizedBox(height: 8),

              // ── 12 Bhava Cards ──
              ...prediction.bhavas.map((b) => _buildBhavaCard(b, _pl)),

              const SizedBox(height: 16),

              // ── Section: All Dasha Phala ──
              Row(children: [
                Icon(Icons.timeline, color: kPurple2, size: 18),
                const SizedBox(width: 6),
                Text(_pl('dashaPhala'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kPurple2)),
              ]),
              const SizedBox(height: 8),

              // ── All Mahadasha periods ──
              ...r.dashas.map((md) => _buildDashaEntryTile(md, 0, prediction, _pl)),

              if (allPersons.length > 1) const Divider(height: 32),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Current running dasha-bhukti card (highlighted at top)
  Widget _buildCurrentDashaCard(DashaPeriodPrediction d, List<DashaEntry> dashas, String Function(String) _pl) {
    final qualityColor = _phalaColor(d.quality);
    final qualityIcon = _phalaIcon(d.quality);
    final now = DateTime.now();
    final adTotal = d.adEnd.difference(d.adStart).inDays;
    final adElapsed = now.difference(d.adStart).inDays;
    final adProgress = adTotal > 0 ? (adElapsed / adTotal).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: qualityColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: qualityColor.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.star, color: qualityColor, size: 20),
          const SizedBox(width: 6),
          Text(_pl('currentDashaBhukti'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: qualityColor)),
          const Spacer(),
          Icon(qualityIcon, color: qualityColor, size: 18),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: kPurple2.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('${trAll(d.mdLord)} ${_pl('mahadasha')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPurple2)),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward, size: 14, color: kMuted),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: kOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('${trAll(d.adLord)} ${_pl('antardasha')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kOrange)),
          ),
        ]),
        const SizedBox(height: 6),
        // ── Deeper levels: PD → SD → PR ──
        Builder(builder: (_) {
          // Walk the dasha tree to find current PD/SD/PR
          final deeper = <String, String>{};
          final levelNames = ['pratyantardasha', 'sookshmadasha', 'pranadasha'];
          DashaEntry? currentMd = dashas.where((e) => e.lord == d.mdLord && now.isAfter(e.start) && now.isBefore(e.end)).firstOrNull;
          DashaEntry? currentAd = currentMd?.antardashas.where((e) => now.isAfter(e.start) && now.isBefore(e.end)).firstOrNull;
          List<DashaEntry>? subEntries = currentAd?.antardashas;
          for (int i = 0; i < 3 && subEntries != null; i++) {
            final current = subEntries!.where((e) => now.isAfter(e.start) && now.isBefore(e.end)).firstOrNull;
            if (current == null) break;
            deeper[levelNames[i]] = current.lord;
            subEntries = current.antardashas.isNotEmpty ? current.antardashas : null;
          }
          if (deeper.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: deeper.entries.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kPurple2.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kPurple2.withOpacity(0.2)),
                ),
                child: Text('${trAll(e.value)} ${_pl(e.key)}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kPurple2)),
              )).toList(),
            ),
          );
        }),
        // Progress bar for current antardasha
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: adProgress,
            backgroundColor: kBorder.withOpacity(0.3),
            color: qualityColor,
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Row(children: [
          Text('${_fmtDate(d.adStart)} → ${_fmtDate(d.adEnd)}',
            style: TextStyle(fontSize: 10, color: kMuted)),
          const Spacer(),
          Text('${d.relationship}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: qualityColor)),
        ]),
        if (d.mdPhala.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(d.mdPhala, style: TextStyle(fontSize: 12, color: kText, height: 1.5)),
        ],
        if (d.adPhala.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(d.adPhala, style: TextStyle(fontSize: 12, color: kText, height: 1.5)),
        ],
        if (d.shloka.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPurple2.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPurple2.withOpacity(0.15)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.menu_book, size: 14, color: kPurple2.withOpacity(0.5)),
              const SizedBox(width: 6),
              Expanded(child: Text(d.shloka, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: kMuted, height: 1.5))),
            ]),
          ),
        ],
      ]),
    );
  }

  /// Expandable bhava prediction card
  Widget _buildBhavaCard(BhavaPrediction b, String Function(String) _pl) {
    final qualityColor = _phalaColor(b.quality);
    final qualityIcon = _phalaIcon(b.quality);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder.withOpacity(0.5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: qualityColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('${b.bhavaNum}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: qualityColor))),
          ),
          title: Row(children: [
            Expanded(child: Text(b.bhavaName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText))),
            Icon(qualityIcon, color: qualityColor, size: 16),
          ]),
          subtitle: Text(b.significations, style: TextStyle(fontSize: 10, color: kMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          children: [
            // Lord info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(_pl('adhipati'), style: TextStyle(fontSize: 11, color: kMuted)),
                  Text(trAll(b.lordName), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kText)),
                  Text(' (${b.bhavaNum} → ${b.lordInHouse})', style: TextStyle(fontSize: 10, color: kMuted)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: qualityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(b.lordDignity, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: qualityColor)),
                  ),
                ]),
                if (b.planetsInHouse.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('${_pl('bhavaGrahagalu')}${b.planetsInHouse.map((p) => trAll(p)).join(', ')}',
                    style: TextStyle(fontSize: 10, color: kText)),
                ],
                // Drishti display removed per user request
              ]),
            ),
            // Phala text
            if (b.phala.isNotEmpty)
              Text(b.phala, style: TextStyle(fontSize: 12, color: kText, height: 1.5)),
            // Shloka
            if (b.shloka.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPurple2.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kPurple2.withOpacity(0.15)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.menu_book, size: 14, color: kPurple2.withOpacity(0.5)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(b.shloka, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: kMuted, height: 1.5))),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Mahadasha card with expandable bhukti list

  /// â”€â”€ Dasha level names for recursive display â”€â”€
  static const _dashaLevelKeys = ['mahadasha', 'antardasha', 'pratyantardasha', 'sookshmadasha', 'pranadasha'];

  /// Check if a DashaEntry is the current running period
  bool _isDashaCurrent(DashaEntry entry) {
    final now = DateTime.now();
    return now.isAfter(entry.start) && now.isBefore(entry.end);
  }

  /// Recursive dasha entry tile â€” works for all 5 levels
  Widget _buildDashaEntryTile(DashaEntry entry, int level, PredictionResult prediction, String Function(String) _pl) {
    final isCurrent = _isDashaCurrent(entry);
    final levelKey = level < _dashaLevelKeys.length ? _dashaLevelKeys[level] : 'pranadasha';
    final levelLabel = _pl(levelKey);

    // Colors get progressively lighter at deeper levels
    final bgOpacity = isCurrent ? 0.06 : (level == 0 ? 0.0 : 0.02 * level);
    final borderOpacity = isCurrent ? 0.6 : 0.3;
    final fontSize = (13.0 - level * 0.5).clamp(10.0, 13.0);
    final dateFontSize = (10.0 - level * 0.3).clamp(8.0, 10.0);

    final hasChildren = entry.antardashas.isNotEmpty;
    final isLeaf = !hasChildren;

    // Phala text shown only in Phala section, not in Dasha drill-down
    // Leaf nodes (Prana level or entries without children) â€” simple row
    if (isLeaf) {
      return Container(
        margin: EdgeInsets.only(bottom: 2, left: level > 0 ? 4.0 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent ? kOrange.withOpacity(0.08) : kBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
          border: isCurrent ? Border.all(color: kOrange.withOpacity(0.4)) : null,
        ),
        child: Row(children: [
          if (isCurrent)
            Icon(Icons.play_arrow, color: kOrange, size: 12)
          else
            Icon(Icons.circle, color: kMuted.withOpacity(0.3), size: 6),
          const SizedBox(width: 6),
          Text('${trAll(entry.lord)} $levelLabel', style: TextStyle(
            fontSize: fontSize, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? kOrange : kText)),
          const Spacer(),
          Text('${_fmtDate(entry.start)} → ${_fmtDate(entry.end)}',
            style: TextStyle(fontSize: dateFontSize, color: kMuted)),
        ]),
      );
    }

    // Expandable tile for levels with children
    return Container(
      margin: EdgeInsets.only(bottom: level == 0 ? 6.0 : 3.0, left: level > 1 ? 4.0 : 0),
      decoration: BoxDecoration(
        color: isCurrent ? kOrange.withOpacity(bgOpacity) : kCard,
        borderRadius: BorderRadius.circular(level == 0 ? 12 : 8),
        border: Border.all(
          color: isCurrent ? kOrange.withOpacity(borderOpacity) : kBorder.withOpacity(0.3 + level * 0.05),
          width: isCurrent && level == 0 ? 1.5 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: level == 0 ? 12 : 8, vertical: 0),
          childrenPadding: EdgeInsets.fromLTRB(level == 0 ? 12 : 6, 0, level == 0 ? 12 : 6, level == 0 ? 12 : 6),
          initiallyExpanded: isCurrent && level < 2, // auto-expand current MD and AD
          leading: level == 0
            ? Icon(isCurrent ? Icons.play_circle_fill : Icons.circle_outlined,
                color: isCurrent ? kOrange : kPurple2, size: 22)
            : (isCurrent
                ? Icon(Icons.play_arrow, color: kOrange, size: 16)
                : Icon(Icons.circle, color: kMuted.withOpacity(0.4), size: 8)),
          title: Row(children: [
            Expanded(child: Text('${trAll(entry.lord)} $levelLabel', style: TextStyle(
              fontSize: fontSize, fontWeight: FontWeight.w800,
              color: isCurrent ? kOrange : kText))),
            if (isCurrent) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(_pl('prasthuta'), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: kOrange)),
              ),
            ],
          ]),
          subtitle: Text('${_fmtDate(entry.start)} → ${_fmtDate(entry.end)}',
            style: TextStyle(fontSize: dateFontSize, color: kMuted)),
          children: [
            // Sub-level entries
            ...entry.antardashas.map((sub) => _buildDashaEntryTile(sub, level + 1, prediction, _pl)),
          ],
        ),
      ),
    );
  }


  /// Quality color helper
  Color _phalaColor(PhalaQuality q) {
    switch (q) {
      case PhalaQuality.shubha: return Colors.green;
      case PhalaQuality.mishra: return Colors.orange;
      case PhalaQuality.ashubha: return Colors.red;
    }
  }

  /// Quality icon helper
  IconData _phalaIcon(PhalaQuality q) {
    switch (q) {
      case PhalaQuality.shubha: return Icons.check_circle;
      case PhalaQuality.mishra: return Icons.warning_amber;
      case PhalaQuality.ashubha: return Icons.error;
    }
  }

  /// Format date as dd/MM/yyyy
  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _buildGocharTab() {
    // Trigger load if year changed
    if (_gocharLoadedYear != _gocharYear && !_gocharLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadGocharData());
    }

    final moonRashi = _primaryResult.planets['ಚಂದ್ರ']?.rashiIndex ?? 0;
    final rashiNames = List.generate(12, (i) => trAll(knRashi[i]));

    // Helper: house from moon
    int houseFromMoon(int planetRashi) => ((planetRashi - moonRashi) % 12) + 1;
    const guruGoodHouses = {1, 2, 4, 5, 7, 9, 10, 11};

    // Build guru & shani segments from transit events
    List<_GocharSegment> guruSegments = [];
    List<_GocharSegment> shaniSegments = [];

    if (_gocharData != null) {
      final guruTransits = _gocharData!.transits.where((t) => t.planetName == 'jupiter').toList();
      final shaniTransits = _gocharData!.transits.where((t) => t.planetName == 'saturn').toList();

      // Build segments for guru
      guruSegments = _buildSegments(guruTransits, _gocharYear, 'jupiter', moonRashi);
      shaniSegments = _buildSegments(shaniTransits, _gocharYear, 'saturn', moonRashi);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ResponsiveCenter(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Year Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: Icon(Icons.chevron_left, color: kPurple1), onPressed: () => setState(() { _gocharYear--; })),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                child: Text('$_gocharYear', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple1)),
              ),
              IconButton(icon: Icon(Icons.chevron_right, color: kPurple1), onPressed: () => setState(() { _gocharYear++; })),
            ],
          ),
          const SizedBox(height: 12),
          Text('${trAll('ಜನ್ಮ ರಾಶಿ')}: ${rashiNames[moonRashi]}', style: TextStyle(fontSize: 13, color: kMuted), textAlign: TextAlign.center),
          const SizedBox(height: 16),

          if (_gocharLoading)
            Padding(padding: const EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: kPurple1)))
          else if (_gocharData != null) ...[
            // ── GURU GOCHAR ──
            Text(AppLocale.l('guruBalaHead'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTeal)),
            const SizedBox(height: 6),
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${AppLocale.l('guruGochara')} — $_gocharYear', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kPurple1)),
              const SizedBox(height: 12),
              ...guruSegments.map((seg) {
                final house = houseFromMoon(seg.rashiIdx);
                final isGood = guruGoodHouses.contains(house);
                return Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isGood ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isGood ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${rashiNames[seg.rashiIdx]} (${trAll('ಭಾವ')} $house)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
                      Text('${seg.fromDate} → ${seg.toDate}', style: TextStyle(fontSize: 11, color: kMuted)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: isGood ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(isGood ? trAll('ಅನುಕೂಲ') : trAll('ಪ್ರತಿಕೂಲ'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isGood ? Colors.green.shade700 : Colors.red.shade700)),
                    ),
                  ]),
                ));
              }),
            ])),
            const SizedBox(height: 12),

            // ── SHANI GOCHAR ──
            Text(AppLocale.l('shaniSadesatiHead'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTeal)),
            const SizedBox(height: 6),
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${AppLocale.l('shaniGochara')} — $_gocharYear', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kPurple1)),
              const SizedBox(height: 12),
              ...shaniSegments.map((seg) {
                final house = houseFromMoon(seg.rashiIdx);
                final isSadeSati = house == 12 || house == 1 || house == 2;
                final isAshtama = house == 8;
                final isPanchama = house == 5;
                final isBad = isSadeSati || isAshtama || isPanchama;
                String label = '✅ ${trAll('ಇಲ್ಲ')}';
                if (isSadeSati) label = '⚠️ ${AppLocale.l('sadeSati')}';
                else if (isAshtama) label = '💀 ${AppLocale.l('ashtamaShani')}';
                else if (isPanchama) label = '⚡ ${AppLocale.l('panchamaShani')}';
                return Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isBad ? Colors.red.withOpacity(0.08) : Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isBad ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${rashiNames[seg.rashiIdx]} (${trAll('ಭಾವ')} $house)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
                      Text('${seg.fromDate} → ${seg.toDate}', style: TextStyle(fontSize: 11, color: kMuted)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: isBad ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isBad ? Colors.red.shade700 : Colors.green.shade700)),
                    ),
                  ]),
                ));
              }),
            ])),
          ],
          const SizedBox(height: 32),
        ],
      )),
    );
  }

  /// Build position segments from transit events for a planet
  List<_GocharSegment> _buildSegments(List<TransitEvent> transits, int year, String planetName, int moonRashi) {
    final segments = <_GocharSegment>[];
    final fmt = (DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year, 12, 31);

    if (transits.isEmpty) {
      // Planet stays in same rashi all year — find it from Ephemeris
      try {
        final jd = Sweph.swe_julday(year, 7, 1, 12.0, CalendarType.SE_GREG_CAL);
        Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
        final body = planetName == 'jupiter' ? HeavenlyBody.SE_JUPITER : HeavenlyBody.SE_SATURN;
        final pos = Sweph.swe_calc_ut(jd, body, SwephFlag.SEFLG_SWIEPH);
        final ayn = Sweph.swe_get_ayanamsa(jd);
        final sid = (pos.longitude - ayn + 360) % 360;
        final rashi = (sid / 30).floor() % 12;
        segments.add(_GocharSegment(rashiIdx: rashi, fromDate: fmt(yearStart), toDate: fmt(yearEnd)));
      } catch (_) {}
      return segments;
    }

    // First segment: from year start to first transit
    final firstToRashi = knRashi.indexOf(transits.first.fromRashi);
    if (firstToRashi >= 0) {
      segments.add(_GocharSegment(rashiIdx: firstToRashi, fromDate: fmt(yearStart), toDate: fmt(transits.first.date)));
    }

    // Middle segments: between consecutive transits
    for (int i = 0; i < transits.length; i++) {
      final toRashi = knRashi.indexOf(transits[i].toRashi);
      if (toRashi < 0) continue;
      final from = transits[i].date;
      final to = (i + 1 < transits.length) ? transits[i + 1].date : yearEnd;
      segments.add(_GocharSegment(rashiIdx: toRashi, fromDate: fmt(from), toDate: fmt(to)));
    }

    return segments;
  }

  Widget _gocharStatusRow(String title, String position, bool isGood, String status) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
        const SizedBox(height: 2),
        Text(position, style: TextStyle(fontSize: 12, color: kMuted)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isGood ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isGood ? Colors.green.shade700 : Colors.red.shade700)),
      ),
    ]);
  }


  Widget _buildNotesTab() {
    var allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'isPrimary': true, 'entry': null},
      ..._extraPersons.map((p) => {'name': p.name, 'isPrimary': false, 'entry': p}),
    ];
    allPersons = _filterPersons(allPersons);

    return ListView.builder(
      itemCount: allPersons.length,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 300),
      itemBuilder: (ctx, i) {
        final pData = allPersons[i];
        return _buildIndividualNoteSection(
           name: pData['name'] as String,
           isPrimary: pData['isPrimary'] as bool,
           entry: pData['entry'] as PersonEntry?,
        );
      },
    );
  }

  void _showPrintPreview(String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBg,
        title: Row(children: [
          Icon(Icons.print, color: kPurple2),
          const SizedBox(width: 8),
          Text(AppLocale.l('printPreview'), style: TextStyle(color: kText)),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                text,
                style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87, fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocale.l('close'), style: TextStyle(color: kMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocale.l('copiedMsg'))),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(AppLocale.l('copyAndPrint')),
            style: ElevatedButton.styleFrom(backgroundColor: kMuted, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _printNotesPdf(text);
            },
            icon: const Icon(Icons.print, size: 18),
            label: Text(AppLocale.l('printLabel')),
            style: ElevatedButton.styleFrom(backgroundColor: kTeal, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Generate and print a PDF from the notes text using screenshot-to-image
  Future<void> _printNotesPdf(String text) async {
    final controller = ScreenshotController();
    const double pageWidth = 793.0;
    const double pageHeight = 1122.0;

    // Build a styled Flutter widget for the notes page
    final notesWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Material(
          color: Colors.white,
          child: Container(
            width: pageWidth,
            height: pageHeight,
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Text(
                    '📝 ${AppLocale.l('notesLabel')}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kPurple2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: kPurple2, thickness: 2),
                const SizedBox(height: 16),
                // Notes content
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final Uint8List imageBytes = await controller.captureFromWidget(
      notesWidget,
      targetSize: const Size(pageWidth, pageHeight),
      pixelRatio: 3.0,
      delay: const Duration(milliseconds: 100),
    );

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'notes',
    );
  }

  /// Parse notes string into list of {date, text} entries
  List<Map<String, String>> _parseNoteEntries(String notes) {
    if (notes.trim().isEmpty) return [];
    final parts = notes.split('\n---\n');
    final entries = <Map<String, String>>[];
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final match = RegExp(r'^\[(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2})\]\s*(.*)$', dotAll: true).firstMatch(trimmed);
      if (match != null) {
        entries.add({'date': match.group(1)!, 'text': match.group(2)!.trim()});
      } else {
        entries.add({'date': AppLocale.l('oldNote'), 'text': trimmed});
      }
    }
    return entries;
  }






  // ─────────────────────────────────────────────
  // TAB: YOGA (Planetary Yogas)
  // ─────────────────────────────────────────────
  Widget _buildYogaTab() {
    var allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult, 'dob': _primaryDob, 'hour': _primaryHour, 'minute': _primaryMinute, 'ampm': _primaryAmpm, 'place': _primaryPlace},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result, 'dob': p.dob, 'hour': p.hour, 'minute': p.minute, 'ampm': p.ampm, 'place': p.place}),
    ];
    allPersons = _filterPersons(allPersons);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pName = person['name'] as String;
          final yogas = YogaEngine.evaluate(r);

          // Separate positive and negative yogas
          final shubha = yogas.where((y) => y.isPositive).toList();
          final ashubha = yogas.where((y) => !y.isPositive).toList();

          // Category icons and colors
          IconData _catIcon(String cat) {
            switch (cat) {
              case 'raja': return Icons.military_tech;
              case 'dhana': return Icons.account_balance;
              case 'pancha': return Icons.stars;
              case 'chandra': return Icons.nightlight_round;
              case 'graha': return Icons.wb_sunny;
              default: return Icons.auto_awesome;
            }
          }
          Color _catColor(String cat) {
            switch (cat) {
              case 'raja': return Colors.deepPurple;
              case 'dhana': return Colors.amber.shade700;
              case 'pancha': return Colors.indigo;
              case 'chandra': return Colors.blue;
              case 'graha': return Colors.orange;
              default: return Colors.teal;
            }
          }
          String _catLabel(String cat) {
            final isKn = AppLocale.current == 'kn';
            switch (cat) {
              case 'raja': return isKn ? 'ರಾಜಯೋಗ' : 'Raja Yoga';
              case 'dhana': return isKn ? 'ಧನಯೋಗ' : 'Dhana Yoga';
              case 'pancha': return isKn ? 'ಪಂಚ ಮಹಾಪುರುಷ' : 'Pancha Mahapurusha';
              case 'chandra': return isKn ? 'ಚಂದ್ರ ಯೋಗ' : 'Chandra Yoga';
              case 'graha': return isKn ? 'ಗ್ರಹ ಯೋಗ' : 'Graha Yoga';
              default: return isKn ? 'ಇತರ ಯೋಗ' : 'Other Yoga';
            }
          }

          Widget yogaCard(YogaResult y) {
            final isPos = y.isPositive;
            // Extract short phala: text after first ". " (condition. phala)
            final desc = AppLocale.current == 'kn' ? y.descKn : y.descEn;
            final dotIdx = desc.indexOf('. ');
            final phala = dotIdx >= 0 ? desc.substring(dotIdx + 2) : desc;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPos ? _catColor(y.category).withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_catIcon(y.category), size: 18, color: isPos ? _catColor(y.category) : Colors.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(AppLocale.current == 'kn' ? y.nameKn : y.nameEn, style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900,
                          color: isPos ? _catColor(y.category) : Colors.red,
                        )),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isPos ? Colors.green : Colors.red).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPos ? AppLocale.l('shubhakara') : AppLocale.l('ashubhakara'),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                            color: isPos ? Colors.green.shade700 : Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(phala, style: TextStyle(fontSize: 12, color: kText, height: 1.4)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allPersons.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                ),

              // Yoga warning notice
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade700.withOpacity(0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocale.l('yogaWarning'),
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade900, height: 1.4, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // Summary card
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPurple2.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [
                      Text('${yogas.length}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kPurple2)),
                      Text(AppLocale.l('totalYoga'), style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
                    ]),
                    Column(children: [
                      Text('${shubha.length}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green)),
                      Text(AppLocale.l('shubha'), style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
                    ]),
                    Column(children: [
                      Text('${ashubha.length}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.red)),
                      Text(AppLocale.l('ashubha'), style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ),
              ),

              // Shubha yogas
              if (shubha.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text('${AppLocale.l('shubhaYogagalu')} (${shubha.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.green.shade700)),
                  ]),
                ),
                ...shubha.map(yogaCard),
              ],

              // Ashubha yogas
              if (ashubha.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    Text('${AppLocale.l('ashubhaYogagalu')} (${ashubha.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.red.shade700)),
                  ]),
                ),
                ...ashubha.map(yogaCard),
              ],

              if (yogas.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(child: Text(AppLocale.l('noYogaFound'), style: TextStyle(color: kMuted, fontSize: 14))),
                ),

              if (allPersons.length > 1) Divider(thickness: 2, color: kBorder),
              const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ),
    );
  }


  // ─────────────────────────────────────────────
  // TAB 11: JANMA PATRIKE (PDF GENERATION)
  // ─────────────────────────────────────────────
  Widget _buildJanmaPatrikeTab() {
    final selectedTheme = PdfThemes.getById(_selectedThemeId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Theme Picker ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette, color: kPurple2),
                    const SizedBox(width: 8),
                    Text(AppLocale.l('pdfThemeSelect'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(AppLocale.l('pdfThemeDesc'), style: TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: PdfThemes.all.map((t) {
                    final isSelected = t.id == _selectedThemeId;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedThemeId = t.id);
                        PdfThemes.save(t.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? t.primaryLight.withOpacity(0.1) : kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? t.primaryLight : kBorder,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: t.primaryLight.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
                          ] : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Mini page preview
                            Container(
                              width: 44,
                              height: 56,
                              decoration: BoxDecoration(
                                color: t.pageBg,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: t.borderColor1, width: 1.5),
                              ),
                              child: Column(
                                children: [
                                  // Mini header
                                  Container(
                                    height: 10,
                                    margin: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: t.headerBg,
                                      borderRadius: BorderRadius.circular(1),
                                      border: Border.all(color: t.primaryDark, width: 0.5),
                                    ),
                                  ),
                                  // Mini table header
                                  Container(
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    color: t.tableHeaderBg,
                                  ),
                                  // Mini rows
                                  Container(
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                    color: t.detailBoxBg,
                                  ),
                                  Container(
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    color: t.tableAltRow,
                                  ),
                                  // Mini border line
                                  const Spacer(),
                                  Container(
                                    height: 2,
                                    margin: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: t.borderColor2, width: 1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(AppLocale.current == 'kn' ? t.nameKn : t.nameEn, style: TextStyle(
                              fontSize: 11, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              color: isSelected ? t.primaryLight : kText,
                            )),
                            Text(t.nameEn, style: TextStyle(fontSize: 9, color: kMuted)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Format Selection ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.style, color: kPurple2),
                    const SizedBox(width: 8),
                    Text(AppLocale.l('pdfFormat'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                  ],
                ),
                const SizedBox(height: 4),
                RadioListTile<String>(
                  value: 'detailed',
                  groupValue: _patrikeFormat,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  activeColor: kPurple2,
                  title: Text(AppLocale.l('pdfDetailed'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
                  subtitle: Text(AppLocale.l('pdfDetailedDesc'), style: TextStyle(fontSize: 10, color: kMuted)),
                  onChanged: (v) => setState(() => _patrikeFormat = v!),
                ),
                RadioListTile<String>(
                  value: 'traditional',
                  groupValue: _patrikeFormat,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  activeColor: kPurple2,
                  title: Text(AppLocale.l('pdfTraditional'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
                  subtitle: Text(AppLocale.l('pdfTraditionalDesc'), style: TextStyle(fontSize: 10, color: kMuted)),
                  onChanged: (v) => setState(() => _patrikeFormat = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Page Selection (always shown) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.checklist, color: kPurple2),
                    const SizedBox(width: 8),
                    Text(AppLocale.l('pdfPageSelect'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(7, (i) {
                  final pageNames = [
                    'ಜನನ ಪತ್ರಿಕಾ (Birth Details)',
                    'ವಿಂಶೋತ್ತರೀ ದಶಾ (Dasha)',
                    'ಅಂತರ್ದಶಾ (Antardasha)',
                    'ವರ್ಗ ಕುಂಡಲಿ (Varga Charts)',
                    'ಅಷ್ಟಕವರ್ಗ (Ashtakavarga)',
                    'ಷಡ್ಬಲ (Shadbala)',
                    'ಫಲ (Predictions)',
                  ];
                  return CheckboxListTile(
                    value: _pdfPageSelection[i],
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    activeColor: kPurple2,
                    title: Text('${i + 1}. ${pageNames[i]}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
                    onChanged: (v) {
                      // Don't allow deselecting all pages
                      if (!v! && _pdfPageSelection.where((p) => p).length <= 1) return;
                      setState(() => _pdfPageSelection[i] = v);
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Form Fields ──
          Container(
            key: const ValueKey('jp_form_fields'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selectedTheme.primaryLight.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: selectedTheme.primaryLight),
                    const SizedBox(width: 8),
                    Text(AppLocale.l('createPatrike'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocale.l('patrikeDesc'),
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
                const SizedBox(height: 16),

                // Family Details
                Text(AppLocale.l('familyDetails'), style: TextStyle(fontWeight: FontWeight.w800, color: kTeal)),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('father_name_field'),
                  controller: _fatherNameCtrl,
                  decoration: InputDecoration(labelText: AppLocale.l('fatherName'), prefixIcon: Icon(Icons.person_outline, size: 18), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('mother_name_field'),
                  controller: _motherNameCtrl,
                  decoration: InputDecoration(labelText: AppLocale.l('motherName'), prefixIcon: Icon(Icons.person_3_outlined, size: 18), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('gotra_field'),
                  controller: _gotraCtrl,
                  decoration: InputDecoration(labelText: AppLocale.l('gotraLabel'), prefixIcon: Icon(Icons.hub_outlined, size: 18), isDense: true),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.wc, size: 18, color: kMuted),
                    const SizedBox(width: 8),
                    Text(AppLocale.l('jpGender'), style: TextStyle(fontSize: 13, color: kMuted)),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: Text(AppLocale.l('jpMale')),
                      selected: _selectedGender == 'male',
                      selectedColor: kPurple2.withOpacity(0.2),
                      onSelected: (_) => setState(() => _selectedGender = 'male'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(AppLocale.l('jpFemale')),
                      selected: _selectedGender == 'female',
                      selectedColor: kPurple2.withOpacity(0.2),
                      onSelected: (_) => setState(() => _selectedGender = 'female'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedTheme.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.print),
                    label: Text('${AppLocale.l('pdfPrint')} — ${AppLocale.current == 'kn' ? selectedTheme.nameKn : selectedTheme.nameEn}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    onPressed: () async {
                      final dateStr = '${widget.dob.day.toString().padLeft(2,'0')}-${widget.dob.month.toString().padLeft(2,'0')}-${widget.dob.year}';
                      final timeStr = '${widget.hour.toString().padLeft(2,'0')}:${widget.minute.toString().padLeft(2,'0')} ${widget.ampm}';

                      final ud = UserDetails(
                        name: widget.name,
                        dateStr: dateStr,
                        timeStr: timeStr,
                        place: widget.place,
                        lat: widget.lat,
                        lon: widget.lon,
                        tz: widget.tz,
                        fatherName: _fatherNameCtrl.text.trim(),
                        motherName: _motherNameCtrl.text.trim(),
                        gotra: _gotraCtrl.text.trim(),
                        jyotishiName: _jyotishiNameCtrl.text.trim(),
                        jyotishiPhone: _jyotishiPhoneCtrl.text.trim(),
                        jyotishiAddress: _tippaniAddressCtrl.text.trim(),
                        gender: _selectedGender,
                      );

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              CircularProgressIndicator(color: kPurple1),
                              const SizedBox(height: 16),
                              Text('${AppLocale.l('pdfCreating')}', style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 14, decoration: TextDecoration.none)),
                            ]),
                          ),
                        ),
                      );

                      try {
                        await Future.delayed(const Duration(milliseconds: 50));
                        await JanmaPatrikeService.generateAndPrint(ud, widget.result, theme: selectedTheme, selectedPages: _pdfPageSelection, firstPageStyle: _patrikeFormat);
                        if (mounted) Navigator.of(context, rootNavigator: true).pop();
                      } catch (e) {
                        if (mounted) Navigator.of(context, rootNavigator: true).pop();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ ${AppLocale.l('errorLabel')}: $e'), backgroundColor: Colors.red)
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Share Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: selectedTheme.primaryLight,
                      side: BorderSide(color: selectedTheme.primaryLight, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.share),
                    label: Text('${AppLocale.l('pdfShareDirect')} — ${AppLocale.current == 'kn' ? selectedTheme.nameKn : selectedTheme.nameEn}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    onPressed: () async {
                      final dateStr = '${widget.dob.day.toString().padLeft(2,'0')}-${widget.dob.month.toString().padLeft(2,'0')}-${widget.dob.year}';
                      final timeStr = '${widget.hour.toString().padLeft(2,'0')}:${widget.minute.toString().padLeft(2,'0')} ${widget.ampm}';

                      final ud = UserDetails(
                        name: widget.name,
                        dateStr: dateStr,
                        timeStr: timeStr,
                        place: widget.place,
                        lat: widget.lat,
                        lon: widget.lon,
                        tz: widget.tz,
                        fatherName: _fatherNameCtrl.text.trim(),
                        motherName: _motherNameCtrl.text.trim(),
                        gotra: _gotraCtrl.text.trim(),
                        jyotishiName: _jyotishiNameCtrl.text.trim(),
                        jyotishiPhone: _jyotishiPhoneCtrl.text.trim(),
                        jyotishiAddress: _tippaniAddressCtrl.text.trim(),
                        gender: _selectedGender,
                      );

                      // Show loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              CircularProgressIndicator(color: kPurple1),
                              const SizedBox(height: 16),
                              Text('${AppLocale.l('pdfCreating')}', style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 14, decoration: TextDecoration.none)),
                            ]),
                          ),
                        ),
                      );

                      try {
                        await Future.delayed(const Duration(milliseconds: 50)); // Let dialog render
                        await JanmaPatrikeService.generateAndShare(ud, widget.result, theme: selectedTheme, selectedPages: _pdfPageSelection, firstPageStyle: _patrikeFormat);
                        if (mounted) Navigator.of(context, rootNavigator: true).pop();
                      } catch (e) {
                        if (mounted) Navigator.of(context, rootNavigator: true).pop();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ ${AppLocale.l('errorLabel')}: $e'), backgroundColor: Colors.red)
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  Widget _tableHeader(List<String> cols, {bool big = false}) {
    final base = TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kText);
    return Container(
      color: kPurple2.withOpacity(0.12),
      child: Row(
        children: cols.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: big
                ? _AdaptiveText(e.value, baseStyle: base, bigStyles: [
                    base.copyWith(fontSize: 13.5, fontWeight: FontWeight.w900),
                    base.copyWith(fontSize: 13, fontWeight: FontWeight.w900),
                    base.copyWith(fontSize: 12.5, fontWeight: FontWeight.w900),
                  ])
                : Text(e.value, style: base),
          ),
        )).toList(),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4, left: 4),
      child: Row(children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }

  Widget _tableRow(List<String> cols, {bool bold0 = false, bool big = false}) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
      child: Row(
        children: cols.asMap().entries.map((e) {
          final base = TextStyle(
            fontSize: 12,
            fontWeight: (e.key == 0 && bold0) ? FontWeight.w700 : FontWeight.normal,
            color: kText,
          );
          // In big mode: first column (label / graha) extra bold, values semi-bold
          final bigWeight = (e.key == 0) ? FontWeight.w800 : FontWeight.w600;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: big
                  ? _AdaptiveText(e.value, baseStyle: base, maxLines: 2, bigStyles: [
                      base.copyWith(fontSize: 13.5, fontWeight: bigWeight),
                      base.copyWith(fontSize: 13, fontWeight: bigWeight),
                      base.copyWith(fontSize: 12.5, fontWeight: bigWeight),
                      base.copyWith(fontWeight: bigWeight),
                    ])
                  : Text(e.value,
                      style: base,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _kv(String k, String v, {bool big = false}) {
    if (!big) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text('$k: ', style: TextStyle(fontWeight: FontWeight.w800, color: kPurple2)),
          Expanded(child: Text(v, style: TextStyle())),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _AdaptiveKv(k, v, keyColor: kPurple2),
    );
  }
}

/// Text that grows to a bigger/bolder style ONLY when doing so does not add
/// extra lines (no new wrapping, no ellipsis cut-off). Otherwise it keeps the
/// original base style, so the existing layout never breaks.
class _AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final List<TextStyle> bigStyles; // ordered from biggest to smallest
  final int maxLines;
  const _AdaptiveText(this.text, {required this.baseStyle, required this.bigStyles, this.maxLines = 2});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      if (!maxW.isFinite) return Text(text, style: baseStyle, maxLines: maxLines, overflow: TextOverflow.ellipsis);
      final scaler = MediaQuery.textScalerOf(context);
      final dir = Directionality.of(context);
      final defStyle = DefaultTextStyle.of(context).style;

      int lines(TextStyle st) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: defStyle.merge(st)),
          textDirection: dir,
          textScaler: scaler,
        )..layout(maxWidth: maxW);
        final n = tp.computeLineMetrics().length;
        tp.dispose();
        return n;
      }

      final baseLines = lines(baseStyle);
      var chosen = baseStyle;
      for (final st in bigStyles) {
        final n = lines(st);
        if (n <= baseLines && n <= maxLines) { chosen = st; break; }
      }
      return Text(text, style: chosen, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    });
  }
}

/// Key: value row that grows bigger/bolder only when the value does not
/// wrap onto more lines than it does at the original size.
class _AdaptiveKv extends StatelessWidget {
  final String k;
  final String v;
  final Color keyColor;
  const _AdaptiveKv(this.k, this.v, {required this.keyColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      final defStyle = DefaultTextStyle.of(context).style;
      final baseSize = defStyle.fontSize ?? 14.0;
      final baseKey = TextStyle(fontWeight: FontWeight.w800, color: keyColor);
      const baseVal = TextStyle();

      Widget row(TextStyle ks, TextStyle vs) => Row(children: [
        Text('$k: ', style: ks),
        Expanded(child: Text(v, style: vs)),
      ]);

      if (!maxW.isFinite) return row(baseKey, baseVal);
      final scaler = MediaQuery.textScalerOf(context);
      final dir = Directionality.of(context);

      TextPainter paint(String t, TextStyle st, double w) => TextPainter(
        text: TextSpan(text: t, style: defStyle.merge(st)),
        textDirection: dir,
        textScaler: scaler,
      )..layout(maxWidth: w);

      // Returns value line count, or -1 if the key itself wouldn't fit.
      int valLines(TextStyle ks, TextStyle vs) {
        final kp = paint('$k: ', ks, double.infinity);
        final kw = kp.width;
        kp.dispose();
        final rem = maxW - kw;
        if (rem <= 20) return -1;
        final vp = paint(v, vs, rem);
        final n = vp.computeLineMetrics().length;
        vp.dispose();
        return n;
      }

      final baseLines = valLines(baseKey, baseVal);
      if (baseLines < 0) return row(baseKey, baseVal);

      for (final delta in const [1.5, 1.0, 0.5, 0.0]) {
        final ks = baseKey.copyWith(fontSize: baseSize + delta, fontWeight: FontWeight.w900);
        final vs = baseVal.copyWith(fontSize: baseSize + delta, fontWeight: FontWeight.w600);
        final n = valLines(ks, vs);
        if (n > 0 && n <= baseLines) return row(ks, vs);
      }
      return row(baseKey, baseVal);
    });
  }
}

/// Swipeable kundali chart viewer with dot indicators
class _KundaliPageView extends StatefulWidget {
  final List<Map<String, dynamic>> charts;
  final KundaliResult personResult;
  final String? bhavaPlanet;
  final void Function(String) onBhavaPlanetToggle;
  final void Function(String) onPlanetTap;
  final bool highlightDashaLords;

  const _KundaliPageView({
    required this.charts,
    required this.personResult,
    required this.bhavaPlanet,
    required this.onBhavaPlanetToggle,
    required this.onPlanetTap,
    this.highlightDashaLords = true,
  });

  @override
  State<_KundaliPageView> createState() => _KundaliPageViewState();
}

class _KundaliPageViewState extends State<_KundaliPageView> {
  int _page = 0;

  Widget _buildChart(int chartIdx) {
    final chart = widget.charts[chartIdx];
    final isBhava = chart['isBhava'] as bool;
    final label = chart['label'] as String;
    // Only highlight in Rashi (D1), Navamsha (D9), and Bhava charts
    final varga = chart['varga'] as int;
    final shouldHighlight = widget.highlightDashaLords && ((varga == 1 || varga == 9) || isBhava);
    return KundaliChart(
      result: widget.personResult,
      varga: varga,
      isBhava: isBhava,
      showSphutas: false,
      centerLabel: label,
      onPlanetTap: widget.onPlanetTap,
      selectedPlanet: isBhava ? widget.bhavaPlanet : null,
      onPlanetLongPress: isBhava ? widget.onBhavaPlanetToggle : null,
      bhavaFromPlanet: isBhava ? widget.bhavaPlanet : null,
      highlightPlanets: shouldHighlight ? _dashaLords : null,
    );
  }

  /// Current Mahadasha + Bhukti lord names with distinct colors
  Map<String, Color> get _dashaLords {
    final now = DateTime.now();
    final lords = <String, Color>{};
    for (final md in widget.personResult.dashas) {
      if (now.isAfter(md.start) && now.isBefore(md.end)) {
        lords[md.lord] = const Color(0xFFFF8C00); // Orange for Dasha
        for (final ad in md.antardashas) {
          if (now.isAfter(ad.start) && now.isBefore(ad.end)) {
            if (!lords.containsKey(ad.lord)) {
              lords[ad.lord] = const Color(0xFF00C853); // Green for Bhukti
            }
            break;
          }
        }
        break;
      }
    }
    return lords;
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (!isLandscape) {
      // ── PORTRAIT: single chart per page ──
      final screenWidth = MediaQuery.of(context).size.width;
      final chartSize = screenWidth - 32;
      return SizedBox(
        height: chartSize + 40,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: widget.charts.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildChart(i),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.charts.length, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _page == i ? 18 : 8, height: 8,
                decoration: BoxDecoration(
                  color: _page == i ? kPurple2 : kBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 6),
          ],
        ),
      );
    } else {
      // ── LANDSCAPE: exactly 2 charts visible, no title labels ──
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;
      final topPad = MediaQuery.of(context).padding.top;
      // Fit exactly 2 charts: each takes half the screen width minus padding
      final chartSize = (screenHeight - topPad - 160).clamp(180.0, screenHeight * 0.65);
      final chartWidth = (screenWidth / 2.0) - 16; // exactly 2 per screen
      return SizedBox(
        height: chartSize + 16,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: widget.charts.length,
            itemBuilder: (context, i) {
              return SizedBox(
                width: chartWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildChart(i),
                ),
              );
            },
          ),
        ),
      );
    }
  }
}

class _GocharSegment {
  final int rashiIdx;
  final String fromDate;
  final String toDate;
  _GocharSegment({required this.rashiIdx, required this.fromDate, required this.toDate});
}
