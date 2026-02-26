import 'package:flutter/material.dart';
import '../widgets/common.dart';

class PlanetDetailSheet extends StatelessWidget {
  final String pName;
  final Map<String, dynamic> detail;

  const PlanetDetailSheet({super.key, required this.pName, required this.detail});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('à²—à³à²°à²¹à²¦ à²¸à²‚à²ªà³‚à²°à³à²£ à²µà²¿à²µà²° â€” $pName',
                style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _section('ðŸ“Œ à²®à³‚à²² à²µà²¿à²µà²°', [
                    ['à²¸à³à²«à³à²Ÿ',  detail['degFmt']],
                    ['à²—à²¤à²¿',   detail['gati']],
                    ['à²…à²¸à³à²¤',  detail['isAsta'] == true ? 'à²¹à³Œà²¦à³' : (detail['isAsta'] == false ? 'à²‡à²²à³à²²' : 'à²…à²¨à³à²µà²¯à²¿à²¸à³à²µà³à²¦à²¿à²²à³à²²')],
                  ]),
                  const SizedBox(height: 8),
                  _section('ðŸ“Š à²µà²°à³à²—à²—à²³à³', [
                    ['à²°à²¾à²¶à²¿ (D1)',      detail['d1']],
                    ['à²¹à³‹à²°à²¾ (D2)',     detail['d2']],
                    ['à²¦à³à²°à³‡à²•à³à²•à²¾à²£ (D3)', detail['d3']],
                    ['à²¨à²µà²¾à²‚à²¶ (D9)',    detail['d9']],
                    ['à²¦à³à²µà²¾à²¦à²¶à²¾à²‚à²¶ (D12)',detail['d12']],
                    ['à²¤à³à²°à²¿à²‚à²¶à²¾à²‚à²¶ (D30)',detail['d30']],
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<List<String>> rows) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(title, style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    )),
          ),
          ...rows.map((r) => Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEDF2F7)))),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Text(r[0], style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    )),
              const Spacer(),
              Text(r[1], style:  
        param($m)
        $inner = $m.Groups[1].Value
        if ($inner -eq "") { "const TextStyle()" }
        else { "TextStyle($inner)" }
    ),
            ]),
          )),
        ],
      ),
    );
  }
}
