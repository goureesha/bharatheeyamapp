import 'package:flutter/material.dart';
import '../constants/strings.dart';
import 'common.dart';
import 'kundali_chart.dart';

class AshtakavargaWidget extends StatelessWidget {
  final List<int> savBindus;
  final Map<String, List<int>> bavBindus;

  const AshtakavargaWidget({super.key, required this.savBindus, required this.bavBindus});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SectionTitle('à²¸à²°à³à²µà²¾à²·à³à²Ÿà²•à²µà²°à³à²— (SAV)', color: kOrange),
          _SavGrid(savBindus: savBindus),
          SectionTitle('ðŸ“ à²¬à²¿à²¨à³à²¨à²¾à²·à³à²Ÿà²•à²µà²°à³à²— (BAV)', color: const Color(0xFF2B6CB0)),
          _BavTable(savBindus: savBindus, bavBindus: bavBindus),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SavGrid extends StatelessWidget {
  final List<int> savBindus;
  const _SavGrid({required this.savBindus});

  static const List<int?> _grid = [
    11, 0, 1, 2, 10, null, null, 3, 9, null, null, 4, 8, 7, 6, 5,
  ];

  @override
  Widget build(BuildContext context) {
    bool centerDone = false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
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
            children: _grid.map((idx) {
              if (idx == null) {
                if (!centerDone) {
                  centerDone = true;
                  return _centerBox(savBindus.fold(0, (a, b) => a + b));
                }
                return const SizedBox.shrink();
              }
              return _rashiBox(idx, savBindus[idx]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _rashiBox(int idx, int bindu) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -12, left: 2,
            child: Text(knRashi[idx],
              style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    , fontWeight: FontWeight.w900)),
          ),
          Text(bindu.toString(),
            style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ),
        ],
      ),
    );
  }

  Widget _centerBox(int total) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF6D365), Color(0xFFFDA085)]),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('à²’à²Ÿà³à²Ÿà³', style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    )),
        Text(total.toString(), style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    )),
      ]),
    );
  }
}

class _BavTable extends StatelessWidget {
  final List<int> savBindus;
  final Map<String, List<int>> bavBindus;
  static const _planets = ['à²°à²µà²¿','à²šà²‚à²¦à³à²°','à²•à³à²œ','à²¬à³à²§','à²—à³à²°à³','à²¶à³à²•à³à²°','à²¶à²¨à²¿'];
  static const _short   = ['à²°','à²šà²‚','à²•à³','à²¬à³','à²—à³','à²¶à³','à²¶'];

  const _BavTable({required this.savBindus, required this.bavBindus});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: AppCard(
          padding: EdgeInsets.zero,
          child: DataTable(
            columnSpacing: 10,
            horizontalMargin: 10,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFEDF2F7)),
            columns: [
              DataColumn(label: Text('à²°à²¾à²¶à²¿', style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    )),
              ..._short.map((s) => DataColumn(label: Text(s, style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ))),
              DataColumn(label: Text('à²’à²Ÿà³à²Ÿà³', style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    )),
            ],
            rows: List.generate(12, (i) {
              return DataRow(cells: [
                DataCell(Text(knRashi[i], style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    )),
                ..._planets.map((p) {
                  final v = bavBindus[p]?[i] ?? 0;
                  return DataCell(Text(v.toString(), style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ));
                }),
                DataCell(Text(savBindus[i].toString(),
                  style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ))),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
