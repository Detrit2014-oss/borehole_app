import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'borehole_editor_screen.dart';
import 'pdf_service.dart';
import 'utils.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final List<String> soilTypes;
  final Function(Project) onUpdate;
  final VoidCallback onDelete;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.soilTypes,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  void _update(Project p) {
    setState(() => _project = p);
    widget.onUpdate(p);
  }

  void _addBorehole() {
    final numCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.add_circle, color: Color(0xFF1e3a5f)),
          SizedBox(width: 8),
          Text('Новая скважина'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numCtrl,
              decoration: const InputDecoration(
                  labelText: 'Номер скважины *',
                  hintText: 'СКВ-1',
                  border: OutlineInputBorder()),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Дата бурения',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today, size: 18),
              ),
              readOnly: true,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2040),
                );
                if (d != null) {
                  dateCtrl.text = DateFormat('yyyy-MM-dd').format(d);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (numCtrl.text.trim().isEmpty) return;
              final bh = Borehole.create(
                number: numCtrl.text.trim(),
                date: dateCtrl.text,
              );
              _update(_project.copyWith(
                boreholes: [..._project.boreholes, bh],
                updatedAt: DateTime.now().toIso8601String(),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _deleteBorehole(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить скважину?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              _update(_project.copyWith(
                boreholes: _project.boreholes.where((b) => b.id != id).toList(),
                updatedAt: DateTime.now().toIso8601String(),
              ));
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _openBorehole(Borehole bh) async {
    final result = await Navigator.push<Borehole>(
      context,
      MaterialPageRoute(
        builder: (_) => BoreholeEditorScreen(
          project: _project,
          borehole: bh,
          soilTypes: widget.soilTypes,
        ),
      ),
    );
    if (result != null) {
      _update(_project.copyWith(
        boreholes: _project.boreholes
            .map((b) => b.id == result.id ? result : b)
            .toList(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bhs = _project.boreholes;

    return Scaffold(
      appBar: AppBar(
        title: Text(_project.name),
        backgroundColor: const Color(0xFF1e3a5f),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'delete') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Удалить "${_project.name}"?'),
                    content: const Text('Все скважины будут удалены.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Отмена')),
                      TextButton(
                        onPressed: () {
                          widget.onDelete();
                          Navigator.pop(ctx);
                        },
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Удалить'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child:
                    Text('Удалить объект', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_project.address.isNotEmpty || _project.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_project.address.isNotEmpty)
                    Row(children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(_project.address,
                              style: TextStyle(color: Colors.grey[600]))),
                    ]),
                  if (_project.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_project.description,
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Text('Скважины (${bhs.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              FilledButton.icon(
                onPressed: _addBorehole,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Добавить'),
              ),
            ]),
          ),
          Expanded(
            child: bhs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.science_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('Нет скважин',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 18)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _addBorehole,
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить скважину'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: bhs.length,
                    itemBuilder: (context, i) {
                      final bh = bhs[i];
                      final gw = bh.hasGroundwater == true
                          ? 'УГВ: ${bh.groundwaterDepth} м'
                          : bh.hasGroundwater == false
                              ? 'УГВ: нет'
                              : 'УГВ: —';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openBorehole(bh),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.science,
                                    color: Colors.green, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Скважина ${bh.number}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 10,
                                      children: [
                                        _chip(Icons.calendar_today,
                                            formatDate(bh.date)),
                                        _chip(Icons.layers,
                                            '${bh.layers.length} слоёв'),
                                        _chip(Icons.straighten,
                                            '${bh.totalDepth.toStringAsFixed(1)} м'),
                                        _chip(Icons.water_drop, gw),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.print, size: 22),
                                    color: Colors.green[600],
                                    tooltip: 'Печать',
                                    onPressed: () =>
                                        printBorehole(_project, bh),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.picture_as_pdf,
                                        size: 22),
                                    color: Colors.red[400],
                                    tooltip: 'PDF',
                                    onPressed: () => exportPdf(_project, bh),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete_outline, size: 22),
                                color: Colors.grey[400],
                                tooltip: 'Удалить',
                                onPressed: () => _deleteBorehole(bh.id),
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}
