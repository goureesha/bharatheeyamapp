import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../services/pooja_list_service.dart';

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
            filled: true,
            fillColor: kBg,
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
              );
              setState(() => _lists.insert(0, newList));
              _save();
              // Open the new list immediately
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
    // Save after returning from detail screen
    await _save();
    if (mounted) setState(() {});
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
                          backgroundColor: kOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lists.length,
                  onReorder: (oldIdx, newIdx) {
                    setState(() {
                      if (newIdx > oldIdx) newIdx--;
                      final item = _lists.removeAt(oldIdx);
                      _lists.insert(newIdx, item);
                    });
                    _save();
                  },
                  itemBuilder: (context, index) {
                    final list = _lists[index];
                    final total = list.items.length;
                    final checked = list.checkedCount;
                    final progress = total > 0 ? checked / total : 0.0;

                    return Padding(
                      key: ValueKey(list.id),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _openList(list),
                        child: Container(
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kBorder),
                            boxShadow: [
                              BoxShadow(
                                color: kOrange.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: kOrange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.temple_hindu_rounded, color: kOrange, size: 26),
                                ),
                                const SizedBox(width: 14),
                                // Name & count
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(list.name, style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w800, color: kText,
                                      )),
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
                                            value: progress,
                                            minHeight: 4,
                                            backgroundColor: kBorder,
                                            valueColor: AlwaysStoppedAnimation(
                                              progress >= 1.0 ? kGreen : kOrange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Delete button
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: kMuted, size: 22),
                                  onPressed: () => _deleteList(index),
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
              controller: _nameCtrl,
              autofocus: true,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                hintText: 'Item name',
                hintStyle: TextStyle(color: kMuted),
                filled: true, fillColor: kBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kOrange, width: 2)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                hintText: 'Quantity (optional)',
                hintStyle: TextStyle(color: kMuted),
                filled: true, fillColor: kBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kOrange, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              setState(() {
                _list.items.add(PoojaItem(
                  name: name,
                  quantity: _qtyCtrl.text.trim(),
                ));
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
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                hintText: 'Item name',
                hintStyle: TextStyle(color: kMuted),
                filled: true, fillColor: kBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kOrange, width: 2)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                hintText: 'Quantity (optional)',
                hintStyle: TextStyle(color: kMuted),
                filled: true, fillColor: kBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kOrange, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              setState(() {
                item.name = name;
                item.quantity = _qtyCtrl.text.trim();
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

  void _deleteItem(int index) {
    setState(() => _list.items.removeAt(index));
    _saveList();
  }

  void _toggleItem(int index) {
    setState(() => _list.items[index].checked = !_list.items[index].checked);
    _saveList();
  }

  void _uncheckAll() {
    setState(() {
      for (final item in _list.items) {
        item.checked = false;
      }
    });
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

  Future<void> _saveList() async {
    await PoojaListService.updateList(_list);
  }

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
              Flexible(
                child: Text(_list.name, style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 6),
              Icon(Icons.edit, size: 16, color: kMuted),
            ],
          ),
        ),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
        actions: [
          if (total > 0 && checked > 0)
            IconButton(
              icon: Icon(Icons.replay, color: kMuted),
              onPressed: _uncheckAll,
              tooltip: 'Uncheck All',
            ),
          IconButton(
            icon: Icon(Icons.add, color: kOrange),
            onPressed: _addItem,
            tooltip: 'Add Item',
          ),
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$checked of $total items', style: TextStyle(fontSize: 14, color: kMuted, fontWeight: FontWeight.w600)),
                      if (checked == total)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Complete ✓', style: TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? checked / total : 0,
                      minHeight: 5,
                      backgroundColor: kBorder,
                      valueColor: AlwaysStoppedAnimation(checked == total ? kGreen : kOrange),
                    ),
                  ),
                ],
              ),
            ),

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
                        const SizedBox(height: 8),
                        Text('Tap + to add items to this list', style: TextStyle(fontSize: 13, color: kMuted)),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.items.length,
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        if (newIdx > oldIdx) newIdx--;
                        final item = _list.items.removeAt(oldIdx);
                        _list.items.insert(newIdx, item);
                      });
                      _saveList();
                    },
                    itemBuilder: (context, index) {
                      final item = _list.items[index];
                      return Padding(
                        key: ValueKey('${_list.id}_$index'),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Dismissible(
                          key: ValueKey('dismiss_${_list.id}_$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                          onDismissed: (_) => _deleteItem(index),
                          child: GestureDetector(
                            onTap: () => _toggleItem(index),
                            onLongPress: () => _editItem(index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: kCard,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: item.checked ? kGreen.withOpacity(0.4) : kBorder,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                                          border: Border.all(
                                            color: item.checked ? kGreen : kMuted,
                                            width: 2,
                                          ),
                                        ),
                                        child: item.checked
                                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Name & quantity
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: item.checked ? kMuted : kText,
                                              decoration: item.checked ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                          if (item.quantity.isNotEmpty)
                                            Text(
                                              item.quantity,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: kMuted,
                                                decoration: item.checked ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Drag handle
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Icon(Icons.drag_handle, color: kMuted.withOpacity(0.5)),
                                    ),
                                  ],
                                ),
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
}
