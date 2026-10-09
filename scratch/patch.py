import re

# 1. Update janma_patrike_service.dart
with open('lib/services/janma_patrike_service.dart', 'r', encoding='utf-8') as f:
    jp_content = f.read()

traditional_code = """
  // ── Traditional Single-Page PDF ──

  static Future<Uint8List> _generateTraditionalPdfBytes(UserDetails user, KundaliResult result, {PdfThemeConfig? theme}) async {
    final t = theme ?? PdfThemeConfig();
    final sc = ScreenshotController();
    final pageWidget = _buildPageWrapper(
      width: 793, height: 1122, theme: t,
      child: _buildTraditionalPage(user, result, t),
    );
    final pageBytes = await sc.captureFromWidget(
      pageWidget, targetSize: const Size(793, 1122), pixelRatio: 2.5,
      delay: const Duration(milliseconds: 100),
    );

    final doc = pw.Document();
    final image = pw.MemoryImage(pageBytes);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.FullPage(ignoreMargins: true, child: pw.Image(image, fit: pw.BoxFit.contain)),
    ));
    return doc.save();
  }

  static Future<void> generateTraditionalPdfAndPrint(UserDetails user, KundaliResult result, {PdfThemeConfig? theme}) async {
    final bytes = await _generateTraditionalPdfBytes(user, result, theme: theme);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: '${user.name}_traditional_patrike',
    );
  }

  static Future<void> generateTraditionalPdfAndShare(UserDetails user, KundaliResult result, {PdfThemeConfig? theme}) async {
    final bytes = await _generateTraditionalPdfBytes(user, result, theme: theme);
    await Printing.sharePdf(bytes: bytes, filename: '${user.name}_traditional_patrike.pdf');
  }

  static int _navamshaNumber(double longitude) {
    final posInSign = longitude % 30.0;
    return (posInSign / (30.0 / 9.0)).floor() + 1; // 1-9
  }

  static String _superscript(int n) {
    const digits = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'];
    return digits[n.clamp(0, 9)];
  }

  static List<List<String>> _navamshaSuperChart(KundaliResult result, List<List<String>> Function(KundaliResult) baseChartFunc) {
    final baseChart = List.generate(12, (_) => <String>[]);
    final lagnaInfo = result.planets['ಲಗ್ನ'];
    final lagnaIdx = lagnaInfo != null ? (lagnaInfo.longitude / 30).floor() % 12 : 0;
    
    bool isBhava = baseChartFunc == _bhavaChart;

    List<double> boundaries = List.filled(12, 0.0);
    if (isBhava) {
      final madhyas = result.bhavas;
      for (int i = 0; i < 12; i++) {
        final m1 = madhyas[i];
        final m2 = madhyas[(i + 1) % 12];
        double diff = (m2 - m1 + 360.0) % 360.0;
        boundaries[i] = (m1 + (diff / 2.0)) % 360.0;
      }
    }

    for (final pName in planetOrder) {
      if (pName == 'ಮಾಂದಿ') continue;
      final info = result.planets[pName];
      if (info == null) continue;
      final d = info.longitude;
      final navNum = _navamshaNumber(d);
      final shortName = _shortNames[pName] ?? pName;
      final label = '$shortName${_superscript(navNum)}';

      int ri = 0;
      if (isBhava) {
        int bhavaIdx = 0;
        for (int i = 0; i < 12; i++) {
          final startBoundary = boundaries[(i + 11) % 12];
          final endBoundary = boundaries[i];
          if (startBoundary < endBoundary) {
            if (d >= startBoundary && d < endBoundary) { bhavaIdx = i; break; }
          } else {
            if (d >= startBoundary || d < endBoundary) { bhavaIdx = i; break; }
          }
        }
        ri = (lagnaIdx + bhavaIdx) % 12;
      } else {
        ri = (d / 30).floor() % 12;
      }

      if (ri >= 0 && ri < 12) {
        baseChart[ri].add(label);
      }
    }
    return baseChart;
  }

  static Widget _buildTraditionalPage(UserDetails user, KundaliResult result, PdfThemeConfig t) {
    final p = result.panchang;
    final genderSuffix = user.gender == "female" ? "ಳ" : "ನ";
    
    int shakaYear = 1946;
    if (p.samvatsara.contains('ಶ.ಕ.')) {
      final regex = RegExp(r'ಶ\.ಕ\.\s*(\d+)');
      final match = regex.firstMatch(p.samvatsara);
      if (match != null) {
        shakaYear = int.parse(match.group(1)!);
      }
    } else {
      final parts = user.dateStr.split('-');
      if (parts.length == 3) {
        shakaYear = int.parse(parts.last) - 78;
      }
    }
    
    final samvatsaraName = p.samvatsara.split(' ').first;
    
    final tithiName = trAll(p.tithi);
    String paksha = '';
    if (tithiName.contains('ಶುಕ್ಲ')) paksha = 'ಶುಕ್ಲ';
    else if (tithiName.contains('ಕೃಷ್ಣ')) paksha = 'ಕೃಷ್ಣ';
    else if (p.tithiIndex < 15) paksha = 'ಶುಕ್ಲ';
    else paksha = 'ಕೃಷ್ಣ';

    final moonPada = result.planets['ಚಂದ್ರ']?.pada ?? 1;
    final lagnaInfo = result.planets['ಲಗ್ನ'];
    final lagnaRashi = trAll(lagnaInfo?.rashi ?? '-');

    final para = 'ಶ್ವಸ್ತ ಶ್ರೀ${user.name}${genderSuffix} '
        '${user.fatherName.isNotEmpty ? "${user.fatherName}ರವರ ${user.gender == "female" ? "ಪುತ್ರಿ" : "ಪುತ್ರ"} " : ""}'
        '${user.gotra.isNotEmpty ? "${user.gotra} ಗೋತ್ರ " : ""}'
        'ವೃಷಕಲಾವಾಸನ ರಾಕಶಕವರ್ಷ $shakaYear ಕ್ರಿ.ಶ. '
        '$samvatsaraName ಸಂವತ್ಸರದ '
        '${trAll(p.chandraMasa)} ಮಾಸ $paksha ಪಕ್ಷ ${trAll(p.tithi)} ತಿಥಿ '
        '${trAll(p.vara)}ವಾರದಲ್ಲಿ '
        '${user.timeStr} ಸಮಯದಲ್ಲಿ ${user.place}ದಲ್ಲಿ ಜನಿಸಿರುತ್ತಾರೆ. '
        '${trAll(p.nakshatra)} ನಕ್ಷತ್ರ ${moonPada}ನೇ ಪಾದ '
        '${trAll(p.chandraRashi)} ಚಂದ್ರರಾಶಿ '
        '$lagnaRashi ಲಗ್ನ '
        '${trAll(p.yoga)} ಯೋಗ ${trAll(p.karana)} ಕರಣ. '
        'ಸೂರ್ಯೋದಯ ${p.sunrise} ಸೂರ್ಯಾಸ್ತ ${p.sunset}. '
        'ಉದಯಾದಿ ಘಟಿ ${p.udayadiGhati} ಗತ ಘಟಿ ${p.gataGhati} '
        'ಪರಮ ಘಟಿ ${p.paramaGhati}. '
        '${user.motherName.isNotEmpty ? "ಮಾತೃ ನಾಮ: ${user.motherName}. " : ""}'
        'ಅಕ್ಷಾಂಶ: ${user.lat.toStringAsFixed(4)}° ರೇಖಾಂಶ: ${user.lon.toStringAsFixed(4)}°.';

    final dashaLine = 'ಜ್ಯೋತಿಷ್ಯ ಮೂಲ ದಶಾ ವರ್ಷ: ${trAll(p.dashaLord)}, '
        'ಶೇಷ: ${p.dashaBalance}.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(AppLocale.l('jpTitle'), AppLocale.l('jpSubtitle'), t),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: t.detailBorder),
            borderRadius: BorderRadius.circular(6),
            color: t.detailBoxBg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(para, style: TextStyle(fontSize: 14, height: 1.6, color: t.primaryDark, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Text(dashaLine, style: TextStyle(fontSize: 14, height: 1.6, color: t.primaryDark, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget(AppLocale.l('jpRashiKundali'), _navamshaSuperChart(result, _rashiChart), t))),
              const SizedBox(width: 24),
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget(AppLocale.l('jpBhavaKundali'), _navamshaSuperChart(result, _bhavaChart), t))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (user.jyotishiName.isNotEmpty || user.jyotishiAddress.isNotEmpty || user.jyotishiPhone.isNotEmpty)
          _buildAstrologerSection(user, t),
        _buildFooter(user.jyotishiName, user.jyotishiPhone, t),
      ],
    );
  }
}
"""

jp_content = re.sub(r'}\s*$', traditional_code, jp_content)
with open('lib/services/janma_patrike_service.dart', 'w', encoding='utf-8') as f:
    f.write(jp_content)


# 2. Update dashboard_screen.dart
with open('lib/screens/dashboard_screen.dart', 'r', encoding='utf-8') as f:
    ds_content = f.read()

# Add _patrikeFormat
ds_content = ds_content.replace(
    'List<bool> _pdfPageSelection = [true, true, true, true, true, true, true]; // 7 pages',
    "List<bool> _pdfPageSelection = [true, true, true, true, true, true, true]; // 7 pages\n  String _patrikeFormat = 'detailed'; // 'detailed' or 'traditional'"
)

# Add Format Radio Buttons
radio_code = """                  Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: selectedTheme.primaryLight),
                      const SizedBox(width: 8),
                      Text(AppLocale.l('pdfPageSelect'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'detailed',
                        groupValue: _patrikeFormat,
                        activeColor: kPurple2,
                        onChanged: (val) {
                          if (val != null) setState(() => _patrikeFormat = val);
                        },
                      ),
                      Text('Detailed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: 'traditional',
                        groupValue: _patrikeFormat,
                        activeColor: kPurple2,
                        onChanged: (val) {
                          if (val != null) setState(() => _patrikeFormat = val);
                        },
                      ),
                      Text('Traditional (1 Page)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
                    ],
                  ),
                  if (_patrikeFormat == 'detailed')
"""
ds_content = ds_content.replace(
    """                  Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: selectedTheme.primaryLight),
                      const SizedBox(width: 8),
                      Text(AppLocale.l('pdfPageSelect'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                    ],
                  ),
                  const SizedBox(height: 8),""",
    radio_code
)

# Update print call
print_call = """                        if (_patrikeFormat == 'traditional') {
                          await JanmaPatrikeService.generateTraditionalPdfAndPrint(ud, widget.result, theme: selectedTheme);
                        } else {
                          await JanmaPatrikeService.generateAndPrint(ud, widget.result, theme: selectedTheme, selectedPages: _pdfPageSelection);
                        }"""
ds_content = ds_content.replace(
    "await JanmaPatrikeService.generateAndPrint(ud, widget.result, theme: selectedTheme, selectedPages: _pdfPageSelection);",
    print_call
)

# Update share call
share_call = """                        if (_patrikeFormat == 'traditional') {
                          await JanmaPatrikeService.generateTraditionalPdfAndShare(ud, widget.result, theme: selectedTheme);
                        } else {
                          await JanmaPatrikeService.generateAndShare(ud, widget.result, theme: selectedTheme, selectedPages: _pdfPageSelection);
                        }"""
ds_content = ds_content.replace(
    "await JanmaPatrikeService.generateAndShare(ud, widget.result, theme: selectedTheme, selectedPages: _pdfPageSelection);",
    share_call
)

with open('lib/screens/dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(ds_content)
