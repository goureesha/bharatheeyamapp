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

  /// Generate and print Tippani PDF
  static Future<void> generateAndPrint(TippaniData data, {PdfThemeConfig? theme}) async {
    theme ??= PdfThemes.traditional;
    final controller = ScreenshotController();

    const double pageWidth = 793.0;
    const double pageHeight = 1122.0;
    final targetSize = const Size(pageWidth, pageHeight);

    final pageWidget = _buildPageWrapper(
      width: pageWidth,
      height: pageHeight,
      theme: theme,
      child: _buildTippaniContent(data, theme),
    );

    final pageBytes = await controller.captureFromWidget(
      pageWidget,
      targetSize: targetSize,
      pixelRatio: 3.0,
      delay: const Duration(milliseconds: 200),
    );

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(pw.MemoryImage(pageBytes), fit: pw.BoxFit.contain),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${data.name}_tippani',
    );
  }

  /// Page wrapper with theme border
  static Widget _buildPageWrapper({
    required double width,
    required double height,
    required PdfThemeConfig theme,
    required Widget child,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Theme(
          data: ThemeData(fontFamily: _fontForLocale()),
          child: DefaultTextStyle(
            style: TextStyle(color: Colors.black, fontSize: 13, fontFamily: _fontForLocale()),
            child: Material(
              color: Colors.white,
              child: theme.buildPageBorder(
                width: width,
                height: height,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Main content layout
  static Widget _buildTippaniContent(TippaniData data, PdfThemeConfig theme) {
    final now = DateTime.now();
    final todayStr = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Logo + Invocation ──
          Center(
            child: Column(
              children: [
                Image.asset('assets/images/logo.png', width: 56, height: 56),
                const SizedBox(height: 6),
                Text(
                  data.invocationText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.shlokaText,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  trAll(AppLocale.l('appName')),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Astrologer Info Section ──
          if (data.astrologerName.isNotEmpty || data.astrologerAddress.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.headerBg.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primaryDark.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  if (data.astrologerName.isNotEmpty)
                    Text(
                      data.astrologerName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: theme.primaryDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (data.astrologerAddress.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      data.astrologerAddress,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (data.astrologerPhone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '📞 ${data.astrologerPhone}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Divider ──
          _sectionDivider(theme),
          const SizedBox(height: 8),

          // ── Birth Details Section ──
          _buildSectionTitle('ಜನನ ವಿವರ', theme),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.detailBoxBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.detailBorder.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Birth details
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow('👤 ಹೆಸರು', data.name, theme),
                      _detailRow('📅 ಜನ್ಮ ದಿನಾಂಕ', data.dateStr, theme),
                      _detailRow('🕰️ ಜನ್ಮ ಸಮಯ', data.timeStr, theme),
                      _detailRow('📍 ಜನ್ಮ ಸ್ಥಳ', data.place, theme),
                      if (data.rashi.isNotEmpty)
                        _detailRow('🌙 ರಾಶಿ', trAll(data.rashi), theme),
                      if (data.nakshatra.isNotEmpty)
                        _detailRow('⭐ ನಕ್ಷತ್ರ', trAll(data.nakshatra), theme),
                    ],
                  ),
                ),
                // Right: Client ID + Date
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (data.clientId.isNotEmpty)
                        _detailRow('🪪 ID', data.clientId, theme, align: CrossAxisAlignment.end),
                      _detailRow('📋 ದಿನಾಂಕ', todayStr, theme, align: CrossAxisAlignment.end),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Notes Section ──
          _sectionDivider(theme),
          const SizedBox(height: 8),
          _buildSectionTitle('📝 ಟಿಪ್ಪಣಿ', theme),
          const SizedBox(height: 8),

          // Notes content
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.detailBorder.withOpacity(0.2)),
              ),
              child: data.notes.isEmpty
                  ? Center(
                      child: Text(
                        'ಟಿಪ್ಪಣಿಗಳಿಲ್ಲ',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < data.notes.length; i++) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 6, right: 8),
                                decoration: BoxDecoration(
                                  color: theme.primaryDark,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.notes[i]['date'] ?? '',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      data.notes[i]['text'] ?? '',
                                      style: const TextStyle(fontSize: 12, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (i < data.notes.length - 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Divider(height: 1, color: theme.detailBorder.withOpacity(0.15)),
                            ),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Footer ──
          _buildFooter(data, theme),
        ],
      ),
    );
  }

  // ── Helper Widgets ──

  static Widget _buildSectionTitle(String title, PdfThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.sectionTitleBg.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: theme.primaryDark, width: 3)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: theme.sectionTitleText,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static Widget _detailRow(String label, String value, PdfThemeConfig theme, {CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.primaryDark)),
        ],
      ),
    );
  }

  static Widget _sectionDivider(PdfThemeConfig theme) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.primaryDark.withOpacity(0.15), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.auto_awesome, size: 12, color: theme.primaryDark.withOpacity(0.3)),
        ),
        Expanded(child: Divider(color: theme.primaryDark.withOpacity(0.15), thickness: 1)),
      ],
    );
  }

  static Widget _buildFooter(TippaniData data, PdfThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.primaryDark.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (data.astrologerName.isNotEmpty)
            Text(data.astrologerName, style: TextStyle(fontSize: 10, color: theme.footerText, fontWeight: FontWeight.w600)),
          Text(trAll(AppLocale.l('appName')), style: TextStyle(fontSize: 10, color: theme.footerText)),
          if (data.astrologerPhone.isNotEmpty)
            Text('📞 ${data.astrologerPhone}', style: TextStyle(fontSize: 10, color: theme.footerText)),
        ],
      ),
    );
  }
}
