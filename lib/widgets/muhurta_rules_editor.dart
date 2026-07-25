import 'package:flutter/material.dart';
import '../core/muhurta_rules.dart';
import '../core/user_muhurta_rules.dart';
import '../constants/strings.dart';
import '../widgets/common.dart';

/// ──────────────────────────────────────────────────────────────
/// Rules Editor Widget — collapsible section for editing muhurta rules
/// ──────────────────────────────────────────────────────────────
class MuhurtaRulesEditor extends StatefulWidget {
  final MuhurtaEvent event;
  final VoidCallback? onRulesChanged;

  const MuhurtaRulesEditor({
    super.key,
    required this.event,
    this.onRulesChanged,
  });

  @override
  State<MuhurtaRulesEditor> createState() => _MuhurtaRulesEditorState();
}

class _MuhurtaRulesEditorState extends State<MuhurtaRulesEditor> {
  bool _isExpanded = false;
  late UserMuhurtaRules _rules;

  // Color constants (matching app theme)
  static const kPurple1 = Color(0xFF6C3FA5);
  static const kTeal = Color(0xFF009688);
  static const kText = Color(0xFFE0E0E0);
  static const kMuted = Color(0xFF9E9E9E);
  static const kBg = Color(0xFF1A1A2E);
  static const kCard = Color(0xFF16213E);
  static const kBorder = Color(0xFF2A2A4A);

  static const knTithi = [
    'ಪ್ರತಿಪದಾ','ದ್ವಿತೀಯಾ','ತೃತೀಯಾ','ಚತುರ್ಥೀ','ಪಂಚಮೀ',
    'ಷಷ್ಠೀ','ಸಪ್ತಮೀ','ಅಷ್ಟಮೀ','ನವಮೀ','ದಶಮೀ',
    'ಏಕಾದಶೀ','ದ್ವಾದಶೀ','ತ್ರಯೋದಶೀ','ಚತುರ್ದಶೀ','ಪೂರ್ಣಿಮಾ',
    'ಪ್ರತಿಪದಾ','ದ್ವಿತೀಯಾ','ತೃತೀಯಾ','ಚತುರ್ಥೀ','ಪಂಚಮೀ',
    'ಷಷ್ಠೀ','ಸಪ್ತಮೀ','ಅಷ್ಟಮೀ','ನವಮೀ','ದಶಮೀ',
    'ಏಕಾದಶೀ','ದ್ವಾದಶೀ','ತ್ರಯೋದಶೀ','ಚತುರ್ದಶೀ','ಅಮಾವಾಸ್ಯಾ',
  ];

  static const knVaraShort = ['ರವಿ','ಸೋಮ','ಮಂಗಳ','ಬುಧ','ಗುರು','ಶುಕ್ರ','ಶನಿ'];

  @override
  void initState() {
    super.initState();
    _rules = UserRulesManager.instance.getRules(widget.event);
  }

  @override
  void didUpdateWidget(MuhurtaRulesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event != widget.event) {
      _rules = UserRulesManager.instance.getRules(widget.event);
    }
  }

  void _onChanged() {
    UserRulesManager.instance.saveRules(widget.event, _rules);
    widget.onRulesChanged?.call();
  }

  Future<void> _resetToDefaults() async {
    await UserRulesManager.instance.resetToDefaults(widget.event);
    setState(() {
      _rules = UserRulesManager.instance.getRules(widget.event);
    });
    widget.onRulesChanged?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ಡೀಫಾಲ್ಟ್ ನಿಯಮಗಳಿಗೆ ಮರಳಿದೆ'), backgroundColor: kTeal, duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header — tap to expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Icon(_isExpanded ? Icons.tune : Icons.tune, color: kPurple1, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'ನಿಯಮಗಳನ್ನು ಸಂಪಾದಿಸಿ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kPurple1),
                )),
                if (_isExpanded)
                  TextButton(
                    onPressed: _resetToDefaults,
                    child: Text('ಡೀಫಾಲ್ಟ್', style: TextStyle(fontSize: 11, color: Colors.orange)),
                  ),
                Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: kMuted),
              ],
            ),
          ),

          if (_isExpanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── 1. Tithi ──
            _buildSectionTitle('ತಿಥಿ', Icons.calendar_today),
            const SizedBox(height: 6),
            _buildChipGroup(
              itemCount: 30,
              labelBuilder: (i) => '${knTithi[i]}${i < 15 ? " ಶು" : " ಕೃ"}',
              shortLabelBuilder: (i) => '${(i % 15) + 1}${i < 15 ? "ಶು" : "ಕೃ"}',
              selectedIndices: _rules.allowedTithis,
              onChanged: (selected) {
                setState(() => _rules.allowedTithis = selected.isEmpty ? null : selected);
                _onChanged();
              },
            ),
            const SizedBox(height: 14),

            // ── 2. Nakshatra ──
            _buildSectionTitle('ನಕ್ಷತ್ರ', Icons.star),
            const SizedBox(height: 6),
            _buildChipGroup(
              itemCount: 27,
              labelBuilder: (i) => knNak[i],
              shortLabelBuilder: (i) => knNak[i].substring(0, knNak[i].length > 4 ? 4 : knNak[i].length),
              selectedIndices: _rules.allowedNakshatras,
              onChanged: (selected) {
                setState(() => _rules.allowedNakshatras = selected.isEmpty ? null : selected);
                _onChanged();
              },
            ),
            const SizedBox(height: 14),

            // ── 3. Vara ──
            _buildSectionTitle('ವಾರ', Icons.today),
            const SizedBox(height: 6),
            _buildChipGroup(
              itemCount: 7,
              labelBuilder: (i) => knVaraShort[i],
              shortLabelBuilder: (i) => knVaraShort[i],
              selectedIndices: _rules.allowedVaras,
              onChanged: (selected) {
                setState(() => _rules.allowedVaras = selected.isEmpty ? null : selected);
                _onChanged();
              },
            ),
            const SizedBox(height: 14),

            // ── 4. Yoga (blocked) ──
            _buildSectionTitle('ಯೋಗ (ನಿಷೇಧಿತ)', Icons.block),
            const SizedBox(height: 6),
            _buildChipGroup(
              itemCount: 27,
              labelBuilder: (i) => knYoga[i],
              shortLabelBuilder: (i) => knYoga[i].substring(0, knYoga[i].length > 4 ? 4 : knYoga[i].length),
              selectedIndices: _rules.blockedYogas,
              isBlockedMode: true,
              onChanged: (selected) {
                setState(() => _rules.blockedYogas = selected.isEmpty ? null : selected);
                _onChanged();
              },
            ),
            const SizedBox(height: 14),

            // ── 5. Toggle switches ──
            _buildSectionTitle('ಇತರ ನಿಯಮಗಳು', Icons.settings),
            const SizedBox(height: 6),

            _buildToggle('ವಿಷ್ಟಿ/ಭದ್ರಾ ಕರಣ ತಪ್ಪಿಸಿ', _rules.avoidVishti, (v) {
              setState(() => _rules.avoidVishti = v);
              _onChanged();
            }),
            _buildToggle('ಶುಕ್ಲ ಪಕ್ಷ ಮಾತ್ರ', _rules.requireShukla, (v) {
              setState(() => _rules.requireShukla = v);
              _onChanged();
            }),
            _buildToggle('ಉತ್ತರಾಯಣ ಅಗತ್ಯ', _rules.requireUttarayana, (v) {
              setState(() => _rules.requireUttarayana = v);
              _onChanged();
            }),
            _buildToggle('ತಾರಾ ಬಲ ಅಗತ್ಯ', _rules.requireTaraBala, (v) {
              setState(() => _rules.requireTaraBala = v);
              _onChanged();
            }),
            _buildToggle('ಗುರು ಬಲ ಅಗತ್ಯ', _rules.requireGuruBala, (v) {
              setState(() => _rules.requireGuruBala = v);
              _onChanged();
            }),
            _buildToggle('ಲಗ್ನಕ್ಕೆ ಗುರು ಅನುಕೂಲ', _rules.requireGuruAnukoolaForLagna, (v) {
              setState(() => _rules.requireGuruAnukoolaForLagna = v);
              _onChanged();
            }),
            _buildToggle('ಪೂರ್ಣ ದಿನ ಲಗ್ನ ಸ್ಕ್ಯಾನ್', _rules.fullDayScan, (v) {
              setState(() => _rules.fullDayScan = v);
              _onChanged();
            }),
            const SizedBox(height: 14),

            // ── 6. Lagna Shuddhi ──
            _buildSectionTitle('ಲಗ್ನ ಶುದ್ಧಿ ಅಗತ್ಯಗಳು', Icons.verified),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: ShuddhiType.values.map((s) {
                final labels = {
                  ShuddhiType.lagna: 'ಲಗ್ನ',
                  ShuddhiType.saptama: 'ಸಪ್ತಮ',
                  ShuddhiType.ashtama: 'ಅಷ್ಟಮ',
                  ShuddhiType.dashama: 'ದಶಮ',
                  ShuddhiType.chandraSaptama: 'ಚಂದ್ರ ಸಪ್ತಮ',
                };
                final selected = _rules.requiredShuddhis.contains(s);
                return FilterChip(
                  label: Text(labels[s] ?? s.name, style: TextStyle(fontSize: 11, color: selected ? Colors.white : kText)),
                  selected: selected,
                  selectedColor: kTeal,
                  backgroundColor: kBg,
                  checkmarkColor: Colors.white,
                  side: BorderSide(color: selected ? kTeal : kBorder),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _rules.requiredShuddhis.add(s);
                      } else {
                        _rules.requiredShuddhis.remove(s);
                      }
                    });
                    _onChanged();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // ── 7. Lagna Rashi ──
            _buildSectionTitle('ಅನುಮತಿಸಿದ ಲಗ್ನ ರಾಶಿ', Icons.grid_view),
            const SizedBox(height: 6),
            _buildChipGroup(
              itemCount: 12,
              labelBuilder: (i) => knRashi[i],
              shortLabelBuilder: (i) => knRashi[i],
              selectedIndices: _rules.allowedLagnas,
              onChanged: (selected) {
                setState(() => _rules.allowedLagnas = selected.isEmpty ? null : selected);
                _onChanged();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 14, color: kMuted),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
    ]);
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: kText))),
          SizedBox(
            height: 28,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: kTeal,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipGroup({
    required int itemCount,
    required String Function(int) labelBuilder,
    required String Function(int) shortLabelBuilder,
    required List<int>? selectedIndices,
    required ValueChanged<List<int>> onChanged,
    bool isBlockedMode = false,
  }) {
    // If null, select all (or none for blocked mode)
    final selected = selectedIndices ?? (isBlockedMode ? <int>[] : List.generate(itemCount, (i) => i));

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(itemCount, (i) {
        final isSelected = selected.contains(i);
        final chipColor = isBlockedMode
            ? (isSelected ? Colors.red.shade700 : kBg)
            : (isSelected ? kPurple1 : kBg);
        final textColor = isSelected ? Colors.white : kMuted;

        return GestureDetector(
          onTap: () {
            final newSelected = List<int>.from(selected);
            if (isSelected) {
              newSelected.remove(i);
            } else {
              newSelected.add(i);
            }
            newSelected.sort();
            onChanged(newSelected);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? chipColor : kBorder, width: 1),
            ),
            child: Text(
              shortLabelBuilder(i),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
        );
      }),
    );
  }
}
