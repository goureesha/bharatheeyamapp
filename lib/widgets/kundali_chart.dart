import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import 'common.dart';

// ─────────────────────────────────────────────
// 4×4 South-Indian style Kundali chart widget
// ─────────────────────────────────────────────

class KundaliChart extends StatelessWidget {
  final KundaliResult result;
  final int varga;
  final bool isBhava;
  final bool showSphutas;
  final Map<String, int>? aroodhas; // for Aroodha tab
  final String? centerLabel;

  const KundaliChart({
    super.key,
    required this.result,
    required this.varga,
    required this.isBhava,
    required this.showSphutas,
    this.aroodhas,
    this.centerLabel,
  });

  // Grid layout: indices into rashi boxes, null = center
  static const List<int?> _grid = [
    11, 0, 1, 2,
    10, null, null, 3,
    9,  null, null, 4,
    8,  7,    6,    5,
  ];

  /// Compute which rashi index each planet falls in for the chosen varga
  int _rashinFor(double deg) {
    switch (varga) {
      case 2: // Hora
        final r = (deg / 30).floor() % 12;
        final dr = deg % 30;
        final isOdd = r % 2 == 0;
        return isOdd ? (dr < 15 ? 4 : 3) : (dr < 15 ? 3 : 4);
      case 3: // Drekkana
        return ((deg / 30).floor() + ((deg % 30) / 10).floor() * 4) % 12;
      case 9: // Navamsa
        final block = (deg / 30).floor() % 4;
        final start = [0, 9, 6, 3][block];
        final steps = ((deg % 30) / 3.33333).floor();
        return (start + steps) % 12;
      case 12: // Dvadashamsa
        return ((deg / 30).floor() + ((deg % 30) / 2.5).floor()) % 12;
      case 30: // Trimshamsa
        final r = (deg / 30).floor() % 12;
        final dr = deg % 30;
        final isOdd = r % 2 == 0;
        if (isOdd) {
          if (dr < 5) return 0;
          if (dr < 10) return 10;
          if (dr < 18) return 8;
          if (dr < 25) return 2;
          return 6;
        } else {
          if (dr < 5) return 5;
          if (dr < 12) return 2;
          if (dr < 20) return 8;
          if (dr < 25) return 10;
          return 0;
        }
      default: // Rashi (D1)
        if (isBhava) {
          // Bhava chart: place based on house number from lagna
          return -1; // handled separately
        }
        return (deg / 30).floor() % 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lagnaRashi = (result.planets['ಲಗ್ನ']?.longitude ?? 0) / 30;
    final lagnaIdx   = lagnaRashi.floor() % 12;

    // Build box contents
    final Map<int, List<Widget>> boxes = {for (int i = 0; i < 12; i++) i: []};

    if (aroodhas != null) {
      // Aroodha chart mode
      for (final entry in aroodhas!.entries) {
        boxes[entry.value]!.add(_planetChip(entry.key, ChipType.lagna));
      }
    } else {
      // Normal planets
      for (final pName in planetOrder) {
        final info = result.planets[pName];
        if (info == null) continue;

        int ri;
        if (isBhava) {
          // Bhava: house number from lagna rashi
          ri = ((info.rashiIndex - lagnaIdx + 12) % 12);
        } else {
          ri = _rashinFor(info.longitude);
        }
        if (ri < 0 || ri > 11) continue;

        final type = (pName == 'ಲಗ್ನ' || pName == 'ಮಾಂದಿ')
            ? ChipType.lagna
            : ChipType.planet;
        boxes[ri]!.add(_planetChip(pName, type));
      }

      // Advanced sphutas overlay
      if (showSphutas) {
        for (final entry in result.advSphutas.entries) {
          final ri = _rashinFor(entry.value);
          if (ri < 0 || ri > 11) continue;
          boxes[ri]!.add(_planetChip(entry.key, ChipType.sphuta));
        }
      }
    }

    // Build grid
    bool centerDone = false;
    final cells = _grid.map((idx) {
      if (idx == null) {
        if (!centerDone) {
          centerDone = true;
          return _centerBox();
        }
        return const SizedBox.shrink();
      }
      return _rashiBox(idx, boxes[idx]!);
    }).toList();

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(3),
        child: GridView.count(
          crossAxisCount: 4,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
          children: cells,
        ),
      ),
    );
  }

  Widget _rashiBox(int rashiIdx, List<Widget> planets) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 2),
      child: Stack(
        children: [
          Positioned(
            top: -14,
            left: 2,
            child: Text(knRashi[rashiIdx],
              style: GoogleFonts.notoSansKannada(
                fontSize: 9, color: const Color(0xFF2F855A), fontWeight: FontWeight.w900)),
          ),
          SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 1,
              runSpacing: 1,
              children: planets,
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerBox() {
    final label = centerLabel ?? 'ಭಾರತೀಯಮ್';
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(label,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKannada(
            fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF742A2A))),
      ),
    );
  }

  Widget _planetChip(String name, ChipType type) {
    Color color;
    switch (type) {
      case ChipType.lagna:  color = const Color(0xFFE53E3E); break;
      case ChipType.sphuta: color = const Color(0xFF805AD5); break;
      default:              color = const Color(0xFF2B6CB0);
    }
    return Text(
      name,
      style: GoogleFonts.notoSansKannada(fontSize: 11, fontWeight: FontWeight.w800, color: color),
    );
  }
}

enum ChipType { lagna, planet, sphuta }
