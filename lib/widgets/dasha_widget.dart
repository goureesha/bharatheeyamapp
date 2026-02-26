import 'package:flutter/material.dart';
import '../core/calculator.dart';
import 'common.dart';

class DashaWidget extends StatelessWidget {
  final List<DashaEntry> dashas;
  const DashaWidget({super.key, required this.dashas});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}-${d.month.toString().padLeft(2,'0')}-${d.year.toString().substring(2)}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: dashas.map((md) => _MahaBlock(md: md, fmt: _fmt)).toList()),
    );
  }
}

class _MahaBlock extends StatelessWidget {
  final DashaEntry md;
  final String Function(DateTime) fmt;
  const _MahaBlock({required this.md, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF9933), Color(0xFFDD6B20)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ExpansionTile(
          title: Row(children: [
            Text(md.lord, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            const Spacer(),
            Text(fmt(md.end), style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          iconColor: Colors.white, collapsedIconColor: Colors.white,
          children: md.antardashas.map((ad) => _AntarBlock(ad: ad, fmt: fmt)).toList(),
        ),
      ),
    );
  }
}

class _AntarBlock extends StatelessWidget {
  final DashaEntry ad;
  final String Function(DateTime) fmt;
  const _AntarBlock({required this.ad, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        color: const Color(0xFFFFFDF7),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 24),
          title: Row(children: [
            Container(width: 4, height: 24, color: kOrange, margin: const EdgeInsets.only(right: 10)),
            Text(ad.lord, style: const TextStyle(color: kOrange2, fontWeight: FontWeight.w800, fontSize: 14)),
            const Spacer(),
            Text(fmt(ad.end), style: const TextStyle(color: kMuted, fontSize: 11)),
          ]),
          children: ad.antardashas.map((pd) => Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEDF2F7))), color: Colors.white),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 9),
            child: Row(children: [
              Container(width: 3, height: 18, color: const Color(0xFF81E6D9), margin: const EdgeInsets.only(right: 10)),
              Text(pd.lord, style: const TextStyle(color: kTeal, fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Text(fmt(pd.end), style: const TextStyle(color: kMuted, fontSize: 11)),
            ]),
          )).toList(),
        ),
      ),
    );
  }
}
