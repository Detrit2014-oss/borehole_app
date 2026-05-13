import 'package:flutter/material.dart';
import 'database.dart';

class SoilManagerScreen extends StatefulWidget {
  final List<String> initialTypes;
  const SoilManagerScreen({super.key, required this.initialTypes});

  @override
  State<SoilManagerScreen> createState() => _SoilManagerScreenState();
}

class _SoilManagerScreenState extends State<SoilManagerScreen> {
  late List<String> _list;
  int? _editingIndex;
  final _editCtrl = TextEditingController();
  final _addCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _list = List<String>.from(widget.initialTypes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Справочник грунтов'),
        backgroundColor: const Color(0xFF1e3a5f),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _resetToDefaults,
            child:
                const Text('Сбросить', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _addCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Новый грунт', border: OutlineInputBorder()),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _add,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1e3a5f),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.add),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                '${_list.length} позиций · перетаскивайте для порядка',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final item = _list[index];

                if (_editingIndex == index) {
                  return Card(
                    key: ValueKey('edit_${item.hashCode}_$index'),
                    margin: const EdgeInsets.only(bottom: 4),
                    color: Colors.blue[50],
                    child: ListTile(
                      title: TextField(
                        controller: _editCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), isDense: true),
                        onSubmitted: (_) => _saveEdit(),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            onPressed: _saveEdit,
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey),
                            onPressed: _cancelEdit,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  key: ValueKey('soil_${item.hashCode}_$index'),
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          const Color(0xFF1e3a5f).withValues(alpha: 0.1),
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF1e3a5f))),
                    ),
                    title: Text(item),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          color: Colors.orange[700],
                          onPressed: () {
                            _editingIndex = index;
                            _editCtrl.text = item;
                            setState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: Colors.red[400],
                          onPressed: () =>
                              setState(() => _list.removeAt(index)),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.drag_handle, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                );
              },
              itemCount: _list.length,
              onReorder: (old, neu) {
                setState(() {
                  _editingIndex = null;
                  if (neu > old) neu--;
                  final item = _list.removeAt(old);
                  _list.insert(neu, item);
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => Navigator.pop(context, _list),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1e3a5f),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child:
                const Text('Сохранить список', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  void _add() {
    final text = _addCtrl.text.trim();
    if (text.isEmpty) return;
    if (_list.any((s) => s.toLowerCase() == text.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Такой грунт уже есть')),
      );
      return;
    }
    setState(() => _list.add(text));
    _addCtrl.clear();
  }

  void _saveEdit() {
    if (_editingIndex == null) return;
    final text = _editCtrl.text.trim();
    if (text.isEmpty) return;
    if (_list.any((s) =>
        s.toLowerCase() == text.toLowerCase() &&
        _list.indexOf(s) != _editingIndex)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Такой грунт уже есть')),
      );
      return;
    }
    setState(() {
      _list[_editingIndex!] = text;
      _editingIndex = null;
    });
  }

  void _cancelEdit() {
    setState(() => _editingIndex = null);
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сбросить список?'),
        content: const Text('Вернуть стандартный список грунтов?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              setState(() {
                _list = List<String>.from(defaultSoilTypes);
                _editingIndex = null;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}
