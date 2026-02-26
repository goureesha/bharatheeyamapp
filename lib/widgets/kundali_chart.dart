import 'package:flutter/material.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import 'common.dart';

class KundaliChart extends StatelessWidget {
  final KundaliResult result;
  final int varga;
  final bool isBhava;
  final bool showSphutas;
  final Map<String, int>? aroodhas;
  final String? centerLabel;

  const KundaliChart({
    super.key, required this.result, required this.varga,
    required this.isBhava, required this.showSphutas,
    this.aroodhas, this.centerLabel,
  });

  static const List<int?> _grid = [
    11, 0, 1, 2, 10, null, null, 3, 9, null, null, 4, 8, 7, 6, 5,
  ];

  int _rashiFor(double deg) {
    switch (varga) {
      case 9:
        final block = (deg / 30).floor() % 4;
        final start = [0, 9, 6, 3][block];
        final steps = ((deg % 30) / 3.33333).floor();
        return (start + steps) % 12;
      case 12: return ((deg / 30).floor() + ((deg % 30) / 2.5).floor()) % 12;
      case 3:  return ((deg / 30).floor() + ((deg % 30) / 10).floor() * 4) % 12;
      default: return (deg / 30).floor() % 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lagnaIdx = ((result.planets['ಲಗ್ನ']?.longitude ?? 0) / 30).floor() % 12;
    final Map<int, List<String>> boxes = {for (int i = 0; i < 12; i++) i: []};

    if (aroodhas != null) {
      for (final e in aroodhas!.entries) boxes[e.value]!.add(e.key);
    } else {
      for (final pName in planetOrder) {
        final info = result.planets[pName];
        if (info == null) continue;
        int ri = isBhava ? ((info.rashiIndex - lagnaIdx + 12) % 12) : _rashiFor(info.longitude);
        if (ri < 0 || ri > 11) continue;
        boxes[ri]!.add(pName);
      }
      if (showSphutas) {
        for (final e in result.advSphutas.entries) {
          final ri = _rashiFor(e.value);
          if (ri >= 0 && ri <= 11) boxes[ri]!.add(e.key);
        }
      }
    }

    bool centerDone = false;
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(3),
        child: GridView.count(
          crossAxisCount: 4,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 3, crossAxisSpacing: 3,
          children: _grid.map((idx) {
            if (idx == null) {
              if (!centerDone) { centerDone = true; return _centerBox(); }
              return const SizedBox.shrink();
            }
            return _rashiBox(idx, boxes[idx]!);
          }).toList(),
        ),
      ),
    );
  }

  Widget _rashiBox(int idx, List<String> planets) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 2),
      child: Stack(children: [
        Positioned(top: -12, left: 2,
          child: Text(knRashi[idx], style: const TextStyle(fontSize: 9, color: Color(0xFF2F855A), fontWeight: FontWeight.w900))),
        Wrap(alignment: WrapAlignment.center, spacing: 1, runSpacing: 1,
          children: planets.map((p) => Text(p, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: (p == 'ಲಗ್ನ' || p == 'ಮಾಂದಿ') ? const Color(0xFFE53E3E) : const Color(0xFF2B6CB0)))).toList()),
      ]),
    );
  }

  Widget _centerBox() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF6D365), Color(0xFFFDA085)]),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(child: Text(centerLabel ?? 'ಭಾರತೀಯಮ್',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF742A2A)))),
    );
  }
}
