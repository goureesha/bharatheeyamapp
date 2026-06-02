import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/common.dart';
import '../services/pooja_list_service.dart';

/// Default items added to every new pooja list
const List<Map<String, String>> _defaultPoojaItems = [
  {'n': 'ಅಕ್ಕಿ', 'q': '1 kg'},
  {'n': 'ತುಪ್ಪ', 'q': '250 ml'},
  {'n': 'ತೆಂಗಿನಕಾಯಿ', 'q': '2'},
  {'n': 'ಬಾಳೆಹಣ್ಣು', 'q': '1 dozen'},
  {'n': 'ಹೂವು', 'q': ''},
  {'n': 'ಊದುಬತ್ತಿ', 'q': '1 packet'},
  {'n': 'ಕರ್ಪೂರ', 'q': '1 packet'},
  {'n': 'ಅರಿಶಿನ', 'q': '50 gm'},
  {'n': 'ಕುಂಕುಮ', 'q': '1 packet'},
  {'n': 'ವೀಳ್ಯದೆಲೆ', 'q': '10'},
  {'n': 'ಅಡಿಕೆ', 'q': '10'},
  {'n': 'ಬೆಲ್ಲ', 'q': '250 gm'},
  {'n': 'ಎಣ್ಣೆ', 'q': '100 ml'},
  {'n': 'ಬತ್ತಿ', 'q': '1 packet'},
  {'n': 'ಗಂಧ', 'q': ''},
];

List<PoojaItem> _createDefaultItems() {
  return _defaultPoojaItems.map((m) => PoojaItem(
    name: m['n']!,
    quantity: m['q']!,
  )).toList();
}

class PoojaListsScreen extends StatefulWidget {
  const PoojaListsScreen({super.key});

  @override
  State<PoojaListsScreen> createState() => _PoojaListsScreenState();
}

class _PoojaListsScreenState extends State<PoojaListsScreen> {
  List<PoojaList> _lists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lists = await PoojaListService.loadAll();
    if (mounted) setState(() { _lists = lists; _loading = false; });
  }

  Future<void> _save() async {
    await PoojaListService.saveAll(_lists);
  }

  void _createNewList() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('New Pooja List', style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: kText),
          decoration: InputDecoration(
            hintText: 'e.g. Ganesh Pooja, Satyanarayan Pooja...',
            hintStyle: TextStyle(color: kMuted, fontSize: 14),
            filled: true, fillColor: kBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kOrange, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final newList = PoojaList(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                items: _createDefaultItems(),
              );
              setState(() => _lists.insert(0, newList));
              _save();
              _openList(newList);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openList(PoojaList list) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PoojaListDetailScreen(list: list)),
    );
    await _save();
    if (mounted) setState(() {});
  }

  void _renameList(int index) {
    final list = _lists[index];
    final ctrl = TextEditingController(text: list.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Rename List', style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: kText),
          decoration: InputDecoration(
            filled: true, fillColor: kBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kOrange, width: 2)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: kMuted))),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => list.name = name);
              _save();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteList(int index) {
    final list = _lists[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Delete "${list.name}"?', style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: Text('This will delete the list and all its items.', style: TextStyle(color: kMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _lists.removeAt(index));
              _save();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('Pooja Lists', style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: kOrange),
            onPressed: _createNewList,
            tooltip: 'New List',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt_rounded, size: 80, color: kMuted.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('No pooja lists yet', style: TextStyle(fontSize: 18, color: kMuted, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Tap + to create your first list', style: TextStyle(fontSize: 14, color: kMuted)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createNewList,
                        icon: const Icon(Icons.add),
                        label: const Text('Create List'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kOrange, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lists.length,
                  itemBuilder: (context, index) {
                    final list = _lists[index];
                    final total = list.items.length;
                    final checked = list.checkedCount;
                    final progress = total > 0 ? checked / total : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _openList(list),
                        child: Container(
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kBorder),
                            boxShadow: [
                              BoxShadow(color: kOrange.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: kOrange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.temple_hindu_rounded, color: kOrange, size: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(list.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kText)),
                                      const SizedBox(height: 4),
                                      Text(
                                        total == 0 ? 'No items' : '$checked / $total items',
                                        style: TextStyle(fontSize: 13, color: kMuted),
                                      ),
                                      if (total > 0) ...[
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress, minHeight: 4,
                                            backgroundColor: kBorder,
                                            valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? kGreen : kOrange),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Edit button
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: kPurple2, size: 20),
                                  onPressed: () => _renameList(index),
                                  tooltip: 'Rename',
                                ),
                                // Delete button
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7), size: 20),
                                  onPressed: () => _deleteList(index),
                                  tooltip: 'Delete',
                                ),
                                Icon(Icons.chevron_right, color: kMuted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _lists.isNotEmpty
          ? FloatingActionButton(
              onPressed: _createNewList,
              backgroundColor: kOrange,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// ─── Detail Screen: Items inside a single pooja list ───

class _PoojaListDetailScreen extends StatefulWidget {
  final PoojaList list;
  const _PoojaListDetailScreen({required this.list});

  @override
  State<_PoojaListDetailScreen> createState() => _PoojaListDetailScreenState();
}

class _PoojaListDetailScreenState extends State<_PoojaListDetailScreen> {
  late PoojaList _list;
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _list = widget.list;
  }

  void _addItem() {
    _nameCtrl.clear();
    _qtyCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Add Item', style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl, autofocus: true, style: TextStyle(color: kText),
              decoration: _inputDeco('Item name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl, style: TextStyle(color: kText),
              decoration: _inputDeco('Quantity (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: kMuted))),
          ElevatedButton(
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              setState(() {
                _list.items.add(PoojaItem(name: name, quantity: _qtyCtrl.text.trim()));
              });
              _saveList();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addDefaultItems() {
    final defaults = _createDefaultItems();
    // Only add items that don't already exist (by name)
    final existingNames = _list.items.map((i) => i.name).toSet();
    final toAdd = defaults.where((d) => !existingNames.contains(d.name)).toList();

    if (toAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All default items already exist'), backgroundColor: kMuted),
      );
      return;
    }

    setState(() => _list.items.addAll(toAdd));
    _saveList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${toAdd.length} default items'), backgroundColor: kGreen),
    );
  }

  void _removeDefaultItems() {
    final defaultNames = _defaultPoojaItems.map((m) => m['n']!).toSet();
    final before = _list.items.length;
    setState(() {
      _list.items.removeWhere((i) => defaultNames.contains(i.name));
    });
    final removed = before - _list.items.length;
    _saveList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(removed > 0 ? 'Removed $removed default items' : 'No default items to remove'),
        backgroundColor: removed > 0 ? Colors.red : kMuted,
      ),
    );
  }

  void _editItem(int index) {
    final item = _list.items[index];
    _nameCtrl.text = item.name;
    _qtyCtrl.text = item.quantity;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Edit Item', style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameCtrl, autofocus: true, style: TextStyle(color: kText), decoration: _inputDeco('Item name')),
            const SizedBox(height: 12),
            TextField(controller: _qtyCtrl, style: TextStyle(color: kText), decoration: _inputDeco('Quantity (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: kMuted))),
          ElevatedButton(
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              setState(() { item.name = name; item.quantity = _qtyCtrl.text.trim(); });
              _saveList();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    setState(() => _list.items.removeAt(index));
    _saveList();
  }

  void _toggleItem(int index) {
    setState(() => _list.items[index].checked = !_list.items[index].checked);
    _saveList();
  }

  void _uncheckAll() {
    setState(() { for (final item in _list.items) item.checked = false; });
    _saveList();
  }

  void _renameList() {
    final ctrl = TextEditingController(text: _list.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Rename List', style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl, autofocus: true, style: TextStyle(color: kText),
          decoration: _inputDeco('List name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: kMuted))),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _list.name = name);
              _saveList();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPurohitInfo() {
    final nameCtrl = TextEditingController(text: _list.purohitName);
    final phoneCtrl = TextEditingController(text: _list.purohitPhone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Purohit Details', style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl, autofocus: true, style: TextStyle(color: kText),
              decoration: _inputDeco('Purohit name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl, style: TextStyle(color: kText),
              keyboardType: TextInputType.phone,
              decoration: _inputDeco('Mobile number'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: kMuted))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _list.purohitName = nameCtrl.text.trim();
                _list.purohitPhone = phoneCtrl.text.trim();
              });
              _saveList();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveList() async {
    await PoojaListService.updateList(_list);
  }

  /// Format list as readable text
  String _formatListText() {
    final buf = StringBuffer();
    buf.writeln('📋 ${_list.name}');
    if (_list.purohitName.isNotEmpty || _list.purohitPhone.isNotEmpty) {
      buf.writeln('👤 Purohit: ${_list.purohitName}');
      if (_list.purohitPhone.isNotEmpty) buf.writeln('📞 ${_list.purohitPhone}');
    }
    buf.writeln('${'─' * 30}');
    for (int i = 0; i < _list.items.length; i++) {
      final item = _list.items[i];
      final check = item.checked ? '✅' : '⬜';
      final qty = item.quantity.isNotEmpty ? '  (${item.quantity})' : '';
      buf.writeln('$check ${i + 1}. ${item.name}$qty');
    }
    buf.writeln('${'─' * 30}');
    final total = _list.items.length;
    final done = _list.checkedCount;
    buf.writeln('📊 $done / $total items done');
    buf.writeln('\n— Bharatheeyam App');
    return buf.toString();
  }

  /// Share list via WhatsApp or any app
  void _shareList() async {
    final text = _formatListText();
    // Try WhatsApp first
    final waUrl = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl);
    } else {
      // Fallback to system share sheet
      await Share.share(text, subject: _list.name);
    }
  }

  /// Export list as PDF using native print/save dialog
  void _exportPdf() async {
    try {
      // Load Kannada font for PDF rendering
      final fontData = await rootBundle.load('assets/fonts/NotoSansKannada-Regular.ttf');
      final boldFontData = await rootBundle.load('assets/fonts/NotoSansKannada-Bold.ttf');
      final ttf = pw.Font.ttf(fontData);
      final ttfBold = pw.Font.ttf(boldFontData);

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title
                pw.Text(_list.name, style: pw.TextStyle(
                  font: ttfBold, fontSize: 24, fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#4A148C'),
                )),
                pw.SizedBox(height: 6),
                pw.Text('${_list.checkedCount} / ${_list.items.length} items completed',
                  style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey700)),
                if (_list.purohitName.isNotEmpty || _list.purohitPhone.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text('Purohit: ${_list.purohitName}${_list.purohitPhone.isNotEmpty ? '  |  Phone: ${_list.purohitPhone}' : ''}',
                    style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.blue800)),
                ],
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 10),
                // Items table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(35),
                    1: const pw.FixedColumnWidth(30),
                    2: const pw.FlexColumnWidth(3),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F3E5F5')),
                      children: [
                        _pdfCell('#', ttfBold, bold: true),
                        _pdfCell('\u2713', ttfBold, bold: true),
                        _pdfCell('Item', ttfBold, bold: true),
                        _pdfCell('Quantity', ttfBold, bold: true),
                      ],
                    ),
                    // Data rows
                    for (int i = 0; i < _list.items.length; i++)
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: _list.items[i].checked ? PdfColors.green50 : PdfColors.white,
                        ),
                        children: [
                          _pdfCell('${i + 1}', ttf),
                          _pdfCell(_list.items[i].checked ? '\u2714' : '', ttf),
                          _pdfCell(_list.items[i].name, ttf),
                          _pdfCell(_list.items[i].quantity, ttf),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Text('Generated by Bharatheeyam App',
                  style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey500)),
              ],
            );
          },
        ),
      );

      // Use Printing.layoutPdf for native print/save dialog
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: '${_list.name}_list.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  pw.Widget _pdfCell(String text, pw.Font font, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text, style: pw.TextStyle(
        font: font,
        fontSize: 11,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      )),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: kMuted),
    filled: true, fillColor: kBg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kOrange, width: 2)),
  );

  @override
  Widget build(BuildContext context) {
    final total = _list.items.length;
    final checked = _list.checkedCount;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: GestureDetector(
          onTap: _renameList,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(_list.name, style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              Icon(Icons.edit, size: 16, color: kMuted),
            ],
          ),
        ),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
        actions: [
          // Default items menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: kMuted),
            color: kCard,
            onSelected: (val) {
              if (val == 'add_defaults') _addDefaultItems();
              if (val == 'remove_defaults') _removeDefaultItems();
              if (val == 'uncheck') _uncheckAll();
              if (val == 'share') _shareList();
              if (val == 'pdf') _exportPdf();
              if (val == 'view') _viewPlainList();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'share', child: Row(children: [
                Icon(Icons.share, color: kGreen, size: 20), const SizedBox(width: 10),
                Text('Share via WhatsApp', style: TextStyle(color: kText)),
              ])),
              PopupMenuItem(value: 'pdf', child: Row(children: [
                Icon(Icons.picture_as_pdf, color: Colors.red, size: 20), const SizedBox(width: 10),
                Text('Download PDF', style: TextStyle(color: kText)),
              ])),
              PopupMenuItem(value: 'view', child: Row(children: [
                Icon(Icons.view_list, color: Color(0xFF2980B9), size: 20), const SizedBox(width: 10),
                Text('View Plain List', style: TextStyle(color: kText)),
              ])),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'add_defaults', child: Row(children: [
                Icon(Icons.playlist_add, color: kPurple2, size: 20), const SizedBox(width: 10),
                Text('Add Default Items', style: TextStyle(color: kText)),
              ])),
              PopupMenuItem(value: 'remove_defaults', child: Row(children: [
                Icon(Icons.playlist_remove, color: kMuted, size: 20), const SizedBox(width: 10),
                Text('Remove Default Items', style: TextStyle(color: kText)),
              ])),
              if (checked > 0)
                PopupMenuItem(value: 'uncheck', child: Row(children: [
                  Icon(Icons.replay, color: kMuted, size: 20), const SizedBox(width: 10),
                  Text('Uncheck All', style: TextStyle(color: kText)),
                ])),
            ],
          ),
          IconButton(icon: Icon(Icons.add, color: kOrange), onPressed: _addItem, tooltip: 'Add Item'),
        ],
      ),
      body: Column(
        children: [
          // Progress header
          if (total > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: kCard,
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$checked of $total items', style: TextStyle(fontSize: 14, color: kMuted, fontWeight: FontWeight.w600)),
                    if (checked == total)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: kGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text('Complete ✓', style: TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? checked / total : 0, minHeight: 5,
                    backgroundColor: kBorder,
                    valueColor: AlwaysStoppedAnimation(checked == total ? kGreen : kOrange),
                  ),
                ),
              ]),
            ),
          // Purohit info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: kCard,
            child: Row(
              children: [
                Icon(Icons.person, color: kPurple2, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _editPurohitInfo,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _list.purohitName.isNotEmpty ? _list.purohitName : 'Add Purohit Name',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: _list.purohitName.isNotEmpty ? kText : kMuted,
                          ),
                        ),
                        if (_list.purohitPhone.isNotEmpty)
                          Text(_list.purohitPhone, style: TextStyle(fontSize: 13, color: kMuted)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: kPurple2, size: 20),
                  onPressed: _editPurohitInfo,
                  tooltip: 'Edit Purohit',
                  visualDensity: VisualDensity.compact,
                ),
                if (_list.purohitPhone.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.phone, color: kGreen, size: 20),
                    onPressed: () => launchUrl(Uri.parse('tel:${_list.purohitPhone}')),
                    tooltip: 'Call Purohit',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2a2a3a)),

          // Items list
          Expanded(
            child: _list.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.playlist_add, size: 64, color: kMuted.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text('No items yet', style: TextStyle(fontSize: 16, color: kMuted, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addDefaultItems,
                          icon: const Icon(Icons.playlist_add, size: 20),
                          label: const Text('Add Default Items'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('or tap + to add custom items', style: TextStyle(fontSize: 13, color: kMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.items.length,
                    itemBuilder: (context, index) {
                      final item = _list.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => _toggleItem(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: kCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: item.checked ? kGreen.withOpacity(0.4) : kBorder),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  // Checkbox
                                  GestureDetector(
                                    onTap: () => _toggleItem(index),
                                    child: Container(
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(
                                        color: item.checked ? kGreen : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: item.checked ? kGreen : kMuted, width: 2),
                                      ),
                                      child: item.checked ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Name & quantity
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w700,
                                          color: item.checked ? kMuted : kText,
                                          decoration: item.checked ? TextDecoration.lineThrough : null,
                                        )),
                                        if (item.quantity.isNotEmpty)
                                          Text(item.quantity, style: TextStyle(
                                            fontSize: 13, color: kMuted,
                                            decoration: item.checked ? TextDecoration.lineThrough : null,
                                          )),
                                      ],
                                    ),
                                  ),
                                  // Edit button
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, color: kPurple2, size: 20),
                                    onPressed: () => _editItem(index),
                                    tooltip: 'Edit',
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  // Delete button
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7), size: 20),
                                    onPressed: () => _deleteItem(index),
                                    tooltip: 'Delete',
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: kOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _viewPlainList() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _PlainListViewPage(list: _list),
    ));
  }
}

// ─── Plain List View Page ───

class _PlainListViewPage extends StatelessWidget {
  final PoojaList list;
  const _PlainListViewPage({required this.list});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text(list.name, style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Purohit info
            if (list.purohitName.isNotEmpty || list.purohitPhone.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: kPurple2, size: 22),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (list.purohitName.isNotEmpty)
                          Text('Purohit: ${list.purohitName}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
                        if (list.purohitPhone.isNotEmpty)
                          Text(list.purohitPhone, style: TextStyle(fontSize: 14, color: kMuted)),
                      ],
                    ),
                  ],
                ),
              ),

            // Items table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: kOrange.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 35, child: Text('#', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kOrange))),
                        Expanded(flex: 3, child: Text('Item', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kOrange))),
                        Expanded(flex: 2, child: Text('Quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kOrange))),
                      ],
                    ),
                  ),
                  // Rows
                  ...List.generate(list.items.length, (i) {
                    final item = list.items[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: kBorder, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 35, child: Text('${i + 1}', style: TextStyle(fontSize: 14, color: kMuted, fontWeight: FontWeight.w600))),
                          Expanded(flex: 3, child: Text(item.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText))),
                          Expanded(flex: 2, child: Text(item.quantity, style: TextStyle(fontSize: 14, color: kMuted))),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Summary
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Total: ${list.items.length} items',
                style: TextStyle(fontSize: 14, color: kMuted, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
