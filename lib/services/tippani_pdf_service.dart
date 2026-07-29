import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import 'pdf_theme.dart';
import '../widgets/common.dart';

/// Data container for Tippani PDF generation
class TippaniData {
  final String name;
  final String dateStr;       // Birth date
  final String timeStr;       // Birth time
  final String place;         // Birth place
  final String clientId;
  final String rashi;
  final String nakshatra;
  final String invocationText;
  final String astrologerName;
  final String astrologerAddress;
  final String astrologerPhone;
  final List<Map<String, String>> notes; // [{date: '...', text: '...'}]

  TippaniData({
    required this.name,
    required this.dateStr,
    required this.timeStr,
    required this.place,
    this.clientId = '',
    this.rashi = '',
    this.nakshatra = '',
    this.invocationText = 'ಶ್ರೀ ಗಣೇಶಾಯ ನಮಃ',
    this.astrologerName = '',
    this.astrologerAddress = '',
    this.astrologerPhone = '',
    this.notes = const [],
  });
}

class TippaniPdfService {
  static String _fontForLocale() => 'NotoSansKannada';

  static const double _pw = 793.0;
  static const double _ph = 1122.0;

  /// Estimate "weight" of a note (how many lines it takes)
  static int _noteWeight(Map<String, String> note) {
    final text = note['text'] ?? '';
    // Count actual lines (newlines + 1 for the text itself)
    final lineCount = '\n'.allMatches(text).length + 1;
    return lineCount;
  }

  /// Split notes into pages using weight estimation
  static List<List<Map<String, String>>> _splitNotesIntoPages(List<Map<String, String>> allNotes) {
    if (allNotes.isEmpty) return [[]];
    const int page1Capacity = 18;  // Page 1 has header+birth details
    const int contCapacity = 28;   // Continuation pages have more space
    final pages = <List<Map<String, String>>>[];
    int i = 0;

    // Page 1
    int weight = 0;
    final page1 = <Map<String, String>>[];
    while (i < allNotes.length && weight + _noteWeight(allNotes[i]) <= page1Capacity) {
      weight += _noteWeight(allNotes[i]);
      page1.add(allNotes[i]);
      i++;
    }
    pages.add(page1);

    // Continuation pages
    while (i < allNotes.length) {
      weight = 0;
      final page = <Map<String, String>>[];
      while (i < allNotes.length && weight + _noteWeight(allNotes[i]) <= contCapacity) {
        weight += _noteWeight(allNotes[i]);
        page.add(allNotes[i]);
        i++;
      }
      // If a single note exceeds capacity, add it alone to avoid infinite loop
      if (page.isEmpty && i < allNotes.length) {
        page.add(allNotes[i]);
        i++;
      }
      pages.add(page);
    }
    return pages;
  }

  /// Generate and print Tippani PDF (multi-page)
  static Future<void> generateAndPrint(TippaniData data, {PdfThemeConfig? theme}) async {
    theme ??= PdfThemes.traditional;
    final controller = ScreenshotController();
    final targetSize = const Size(_pw, _ph);
    final doc = pw.Document();

    // Split notes into pages based on content weight
    final notePages = _splitNotesIntoPages(data.notes);

    // Page 1: header + birth details + first batch of notes
    final widget1 = _wrap(theme, _buildPage1(data, theme, notePages[0]));
    final bytes1 = await controller.captureFromWidget(widget1, targetSize: targetSize, pixelRatio: 3.0, delay: const Duration(milliseconds: 200));
    _addPage(doc, bytes1);

    // Continuation pages (if any)
    for (int p = 1; p < notePages.length; p++) {
      final widget = _wrap(theme, _buildContinuationPage(data, theme, notePages[p], p + 1));
      final bytes = await controller.captureFromWidget(widget, targetSize: targetSize, pixelRatio: 3.0, delay: const Duration(milliseconds: 200));
      _addPage(doc, bytes);
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${data.name}_tippani',
    );
  }

  static void _addPage(pw.Document doc, Uint8List bytes) {
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context c) => pw.FullPage(ignoreMargins: true, child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain)),
    ));
  }

  static Widget _wrap(PdfThemeConfig theme, Widget child) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(data: const MediaQueryData(), child: Theme(
        data: ThemeData(fontFamily: _fontForLocale()),
        child: DefaultTextStyle(
          style: TextStyle(color: Colors.black, fontSize: 13, fontFamily: _fontForLocale()),
          child: Material(color: Colors.white, child: theme.buildPageBorder(width: _pw, height: _ph, child: child)),
        ),
      )),
    );
  }

  // ═══════════════ PAGE 1: Header + Birth + Notes ═══════════════
  static Widget _buildPage1(TippaniData data, PdfThemeConfig theme, List<Map<String, String>> notes) {
    final now = DateTime.now();
    final todayStr = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── TOP ROW: Jyotishi (left) | Logo+Title (center) | Date (right) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Jyotishi details
              Expanded(flex: 3, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.astrologerName.isNotEmpty)
                    Text(data.astrologerName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: theme.primaryDark)),
                  if (data.astrologerAddress.isNotEmpty)
                    Text(data.astrologerAddress, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, height: 1.3)),
                  if (data.astrologerPhone.isNotEmpty)
                    Text('📞 ${data.astrologerPhone}', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                ],
              )),
              // Center: Logo + Invocation + App name
              Expanded(flex: 4, child: Column(
                children: [
                  Image.asset('assets/images/logo.png', width: 44, height: 44),
                  const SizedBox(height: 3),
                  Text(data.invocationText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: theme.shlokaText, letterSpacing: 0.8)),
                  Text(trAll(AppLocale.l('appName')), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.primaryDark)),
                ],
              )),
              // Right: Date
              Expanded(flex: 3, child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('ದಿನಾಂಕ', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  Text(todayStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: theme.primaryDark)),
                ],
              )),
            ],
          ),
          const SizedBox(height: 8),
          _divider(theme),
          const SizedBox(height: 6),

          // ── COMPACT BIRTH DETAILS: single row ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.detailBoxBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.detailBorder.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                // Name
                Expanded(flex: 3, child: Row(children: [
                  Text('👤 ', style: TextStyle(fontSize: 11)),
                  Expanded(child: Text(data.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.primaryDark), overflow: TextOverflow.ellipsis)),
                ])),
                // DOB + Time
                Expanded(flex: 3, child: Text(
                  '📅 ${data.dateStr}  🕰️ ${data.timeStr}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.primaryDark),
                  textAlign: TextAlign.center,
                )),
                // Place
                Expanded(flex: 2, child: Text(
                  '📍 ${data.place}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                )),
              ],
            ),
          ),
          // Rashi / Nakshatra compact row
          if (data.rashi.isNotEmpty || data.nakshatra.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (data.rashi.isNotEmpty)
                    Text('🌙 ರಾಶಿ: ${trAll(data.rashi)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.primaryDark)),
                  if (data.rashi.isNotEmpty && data.nakshatra.isNotEmpty)
                    Text('  |  ', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                  if (data.nakshatra.isNotEmpty)
                    Text('⭐ ನಕ್ಷತ್ರ: ${trAll(data.nakshatra)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.primaryDark)),
                  if (data.clientId.isNotEmpty) ...[
                    Text('  |  ', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    Text('🪪 ${data.clientId}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 10),

          // ── NOTES SECTION ──
          _divider(theme),
          const SizedBox(height: 6),
          _sectionTitle('📝 ಟಿಪ್ಪಣಿ', theme),
          const SizedBox(height: 6),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.detailBorder.withOpacity(0.2)),
              ),
              child: notes.isEmpty
                  ? Center(child: Text('ಟಿಪ್ಪಣಿಗಳಿಲ್ಲ', style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic)))
                  : _buildNotesList(notes, theme),
            ),
          ),
          const SizedBox(height: 8),
          _buildFooter(data, theme),
        ],
      ),
    );
  }

  // ═══════════════ CONTINUATION PAGES: Mini header + Notes ═══════════════
  static Widget _buildContinuationPage(TippaniData data, PdfThemeConfig theme, List<Map<String, String>> notes, int pageNum) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mini header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 28, height: 28),
              const SizedBox(width: 8),
              Text('📝 ಟಿಪ್ಪಣಿ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: theme.primaryDark)),
              const SizedBox(width: 12),
              Text('ಪುಟ $pageNum', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 8),
          _divider(theme),
          const SizedBox(height: 8),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.detailBorder.withOpacity(0.2)),
              ),
              child: _buildNotesList(notes, theme),
            ),
          ),
          const SizedBox(height: 8),
          _buildFooter(data, theme),
        ],
      ),
    );
  }

  // ═══════════════ NOTES LIST WIDGET ═══════════════
  static Widget _buildNotesList(List<Map<String, String>> notes, PdfThemeConfig theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < notes.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6, height: 6,
                margin: const EdgeInsets.only(top: 6, right: 8),
                decoration: BoxDecoration(color: theme.primaryDark, shape: BoxShape.circle),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notes[i]['date'] ?? '', style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(notes[i]['text'] ?? '', style: const TextStyle(fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          if (i < notes.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Divider(height: 1, color: theme.detailBorder.withOpacity(0.15)),
            ),
        ],
      ],
    );
  }

  // ═══════════════ COMMON HELPERS ═══════════════

  static Widget _sectionTitle(String title, PdfThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: theme.sectionTitleBg.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: theme.primaryDark, width: 3)),
      ),
      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: theme.sectionTitleText, letterSpacing: 0.5)),
    );
  }

  static Widget _divider(PdfThemeConfig theme) {
    return Row(children: [
      Expanded(child: Divider(color: theme.primaryDark.withOpacity(0.15), thickness: 1)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.auto_awesome, size: 10, color: theme.primaryDark.withOpacity(0.3))),
      Expanded(child: Divider(color: theme.primaryDark.withOpacity(0.15), thickness: 1)),
    ]);
  }

  static Widget _buildFooter(TippaniData data, PdfThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.primaryDark.withOpacity(0.2)))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        if (data.astrologerName.isNotEmpty)
          Text(data.astrologerName, style: TextStyle(fontSize: 9, color: theme.footerText, fontWeight: FontWeight.w600)),
        Text(trAll(AppLocale.l('appName')), style: TextStyle(fontSize: 9, color: theme.footerText)),
        if (data.astrologerPhone.isNotEmpty)
          Text('📞 ${data.astrologerPhone}', style: TextStyle(fontSize: 9, color: theme.footerText)),
      ]),
    );
  }
}
