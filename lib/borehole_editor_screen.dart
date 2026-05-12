import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'pdf_service.dart';

class BoreholeEditorScreen extends StatefulWidget {
  final Project project;
  final Borehole borehole;
  final List<String> soilTypes;

  const BoreholeEditorScreen({
    super.key,
    required this.project,
    required this.borehole,
    required this.soilTypes,
  });

  @override
  State<BoreholeEditorScreen> createState() => _BoreholeEditorScreenState();
}

class _BoreholeEditorScreenState extends State<BoreholeEditorScreen> {
  late Borehole _bh;
  bool _hasChanges = false;

  // Постоянные контроллеры для полей ввода (решают проблему прыгающего курсора)
  late TextEditingController _numberCtrl;
  late TextEditingController _elevationCtrl;
  late TextEditingController _gwDepthCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _bh = widget.borehole;
    _numberCtrl = TextEditingController(text: _bh.number);
    _elevationCtrl = TextEditingController(text: _bh.elevation);
    _gwDepthCtrl = TextEditingController(text: _bh.groundwaterDepth);
    _notesCtrl = TextEditingController(text: _bh.notes);
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _elevationCtrl.dispose();
    _gwDepthCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _update(Borehole bh) {
    setState(() {
      _bh = bh;
      _hasChanges = true;
    });
  }

  void _save() {
    // Обновляем данные из контроллеров перед сохранением
    final finalBh = _bh.copyWith(
      number: _numberCtrl.text,
      elevation: _elevationCtrl.text,
      groundwaterDepth: _gwDepthCtrl.text,
      notes: _notesCtrl.text,
    );
    Navigator.pop(context, finalBh);
  }

  // ─── Layer CRUD ───

  void _addLayer() {
    final lastTo = _bh.layers.isEmpty ? 0.0 : _bh.layers.last.depthTo;
    final fromCtrl = TextEditingController(text: lastTo.toStringAsFixed(2));
    final toCtrl = TextEditingController();
    final sampleCtrl = TextEditingController();
    String selectedSoil = widget.soilTypes.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          final from = double.tryParse(fromCtrl.text) ?? 0;
          final to = double.tryParse(toCtrl.text) ?? 0;
          final thickness = to - from;

          return AlertDialog(
            title: const Row(children: [
              Icon(Icons.add_circle, color: Color(0xFF1e3a5f)),
              SizedBox(width: 8),
              Text('Добавить слой'),
            ]),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Грунт',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSoil,
                        isExpanded: true,
                        isDense: true,
                        items: widget.soilTypes
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedSoil = v ?? ''),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: fromCtrl,
                        decoration: const InputDecoration(
                            labelText: 'От, м', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: toCtrl,
                        decoration: const InputDecoration(
                            labelText: 'До, м', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                        ],
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          thickness > 0 ? Colors.green[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: thickness > 0
                              ? Colors.green[200]!
                              : Colors.grey[300]!),
                    ),
                    child: Text(
                      'Мощность: ${thickness > 0 ? thickness.toStringAsFixed(2) : '—'} м',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: thickness > 0 ? Colors.green[700] : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sampleCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Глубина отбора образца, м',
                        border: OutlineInputBorder()),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена')),
              FilledButton(
                onPressed: () {
                  final layer = Layer(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    soilType: selectedSoil,
                    depthFrom: double.tryParse(fromCtrl.text) ?? 0,
                    depthTo: double.tryParse(toCtrl.text) ?? 0,
                    sampleDepth: sampleCtrl.text.trim(),
                  );
                  _update(_bh.copyWith(layers: [..._bh.layers, layer]));
                  Navigator.pop(ctx);
                },
                child: const Text('Добавить'),
              ),
            ],
          );
        });
      },
    );
  }

  void _editLayer(int index) {
    final layer = _bh.layers[index];
    final fromCtrl =
        TextEditingController(text: layer.depthFrom.toStringAsFixed(2));
    final toCtrl =
        TextEditingController(text: layer.depthTo.toStringAsFixed(2));
    final sampleCtrl = TextEditingController(text: layer.sampleDepth);
    String selectedSoil = layer.soilType;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          final from = double.tryParse(fromCtrl.text) ?? 0;
          final to = double.tryParse(toCtrl.text) ?? 0;
          final thickness = to - from;

          return AlertDialog(
            title: Text('Слой ${index + 1}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Грунт', border: OutlineInputBorder()),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSoil,
                        isExpanded: true,
                        isDense: true,
                        items: widget.soilTypes
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedSoil = v ?? ''),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: fromCtrl,
                        decoration: const InputDecoration(
                            labelText: 'От, м', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: toCtrl,
                        decoration: const InputDecoration(
                            labelText: 'До, м', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                        ],
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          thickness > 0 ? Colors.green[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: thickness > 0
                              ? Colors.green[200]!
                              : Colors.grey[300]!),
                    ),
                    child: Text(
                      'Мощность: ${thickness > 0 ? thickness.toStringAsFixed(2) : '—'} м',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: thickness > 0 ? Colors.green[700] : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sampleCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Глубина отбора образца, м',
                        border: OutlineInputBorder()),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена')),
              FilledButton(
                onPressed: () {
                  final newLayers = List<Layer>.from(_bh.layers);
                  newLayers[index] = layer.copyWith(
                    soilType: selectedSoil,
                    depthFrom: double.tryParse(fromCtrl.text) ?? 0,
                    depthTo: double.tryParse(toCtrl.text) ?? 0,
                    sampleDepth: sampleCtrl.text.trim(),
                  );
                  _update(_bh.copyWith(layers: newLayers));
                  Navigator.pop(ctx);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        });
      },
    );
  }

  void _deleteLayer(int index) {
    final newLayers = List<Layer>.from(_bh.layers)..removeAt(index);
    _update(_bh.copyWith(layers: newLayers));
  }

  void _moveLayer(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _bh.layers.length) return;
    final newLayers = List<Layer>.from(_bh.layers);
    final temp = newLayers[index];
    newLayers[index] = newLayers[target];
    newLayers[target] = temp;
    _update(_bh.copyWith(layers: newLayers));
  }

  // ═══ Build ═══

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final res = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Несохранённые изменения'),
            content: const Text('Сохранить перед выходом?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, 'no'),
                  child: const Text('Не сохранять')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'yes'),
                  child: const Text('Сохранить')),
            ],
          ),
        );
        if (res == 'yes' && context.mounted) {
          _save();
        } else if (res == 'no' && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Скважина ${_bh.number}',
              style: const TextStyle(fontSize: 17)),
          backgroundColor: const Color(0xFF1e3a5f),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
                icon: const Icon(Icons.print),
                tooltip: 'Печать',
                onPressed: () => printBorehole(widget.project, _bh)),
            IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'PDF',
                onPressed: () => exportPdf(widget.project, _bh)),
            IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Сохранить',
                onPressed: _save),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard(
                  title: 'Данные скважины',
                  icon: Icons.info_outline,
                  child: _buildInfoSection()),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Слои грунта (${_bh.layers.length})',
                icon: Icons.layers,
                trailing: FilledButton.icon(
                  onPressed: _addLayer,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Слой'),
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1e3a5f)),
                ),
                child: _buildLayersContent(),
              ),
              const SizedBox(height: 16),
              if (_bh.layers.isNotEmpty) ...[
                _sectionCard(
                    title: 'Колонка',
                    icon: Icons.view_column,
                    child: _buildVisualColumn()),
                const SizedBox(height: 16),
              ],
              _sectionCard(
                  title: 'Грунтовые воды',
                  icon: Icons.water_drop,
                  child: _buildGroundwaterSection()),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Примечания',
                icon: Icons.note,
                child: TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Дополнительные примечания...',
                      border: OutlineInputBorder()),
                  onChanged: (v) => setState(() => _hasChanges = true),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        floatingActionButton: _hasChanges
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить в базу',
                        style: TextStyle(fontSize: 16)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1e3a5f),
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _sectionCard(
      {required String title,
      required IconData icon,
      required Widget child,
      Widget? trailing}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: const Color(0xFF1e3a5f)),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis)),
              const Spacer(),
              if (trailing != null) trailing,
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(children: [
      Row(children: [
        Expanded(
          child: TextField(
            controller: _numberCtrl,
            decoration: const InputDecoration(
                labelText: 'Номер скважины',
                border: OutlineInputBorder(),
                isDense: true),
            onChanged: (v) => setState(() => _hasChanges = true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: _bh.date),
            decoration: const InputDecoration(
                labelText: 'Дата бурения',
                border: OutlineInputBorder(),
                isDense: true,
                suffixIcon: Icon(Icons.calendar_today, size: 18)),
            readOnly: true,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _bh.date.isNotEmpty
                    ? DateTime.tryParse(_bh.date) ?? DateTime.now()
                    : DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (d != null && mounted) {
                setState(() {
                  _bh = _bh.copyWith(date: d.toIso8601String().split('T')[0]);
                  _hasChanges = true;
                });
              }
            },
          ),
        ),
      ]),
      const SizedBox(height: 12),
      TextField(
        controller: _elevationCtrl,
        decoration: const InputDecoration(
            labelText: 'Абс. отметка устья, м',
            border: OutlineInputBorder(),
            isDense: true),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        onChanged: (v) => setState(() => _hasChanges = true),
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: Text('Общая глубина: ${_bh.totalDepth.toStringAsFixed(2)} м',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    ]);
  }

  Widget _buildLayersContent() {
    if (_bh.layers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(children: [
            Icon(Icons.layers_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('Добавьте первый слой',
                style: TextStyle(color: Colors.grey[400])),
          ]),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
            const Color(0xFF1e3a5f).withValues(alpha: 0.08)),
        columnSpacing: 8,
        horizontalMargin: 4,
        dataRowMinHeight: 48,
        columns: const [
          DataColumn(label: Text('№', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('Грунт', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('От,м', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('До,м', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('Мощн.,м', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('Обр.,м', style: TextStyle(fontSize: 12))),
          DataColumn(label: SizedBox(width: 130)),
        ],
        rows: _bh.layers.asMap().entries.map((entry) {
          final i = entry.key;
          final l = entry.value;
          final t = l.thickness;
          return DataRow(cells: [
            DataCell(
                Text('${i + 1}', style: TextStyle(color: Colors.grey[600]))),
            DataCell(Text(l.soilType,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
            DataCell(Text(l.depthFrom.toStringAsFixed(2))),
            DataCell(Text(l.depthTo.toStringAsFixed(2))),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12)),
              child: Text(t > 0 ? t.toStringAsFixed(2) : '—',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      fontSize: 12)),
            )),
            DataCell(Text(l.sampleDepth.isEmpty ? '—' : l.sampleDepth)),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  onPressed: i > 0 ? () => _moveLayer(i, -1) : null,
                  visualDensity: VisualDensity.compact),
              IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  onPressed:
                      i < _bh.layers.length - 1 ? () => _moveLayer(i, 1) : null,
                  visualDensity: VisualDensity.compact),
              IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  color: Colors.orange[700],
                  onPressed: () => _editLayer(i),
                  visualDensity: VisualDensity.compact),
              IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: Colors.red[400],
                  onPressed: () => _deleteLayer(i),
                  visualDensity: VisualDensity.compact),
            ])),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildVisualColumn() {
    final totalT =
        _bh.layers.fold<double>(0, (acc, l) => acc + (l.depthTo - l.depthFrom));
    if (totalT <= 0) return const SizedBox.shrink();
    const colors = [
      Colors.amber,
      Colors.lime,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.lightBlue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.deepOrange
    ];
    return SizedBox(
      height: 200,
      child: Row(children: [
        SizedBox(
          width: 40,
          child: Column(
            children: _bh.layers.asMap().entries.map((e) {
              final l = e.value;
              final pct = (l.depthTo - l.depthFrom) / totalT;
              return Expanded(
                flex: (pct * 100).ceil() > 0 ? (pct * 100).ceil() : 1,
                child: Align(
                    alignment: Alignment.topRight,
                    child: Text(l.depthFrom.toStringAsFixed(1),
                        style:
                            TextStyle(fontSize: 9, color: Colors.grey[500]))),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            children: _bh.layers.asMap().entries.map((e) {
              final i = e.key;
              final l = e.value;
              final pct = (l.depthTo - l.depthFrom) / totalT;
              return Expanded(
                flex: (pct * 100).ceil() > 0 ? (pct * 100).ceil() : 1,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: colors[i % colors.length].shade200,
                      border: Border.all(color: Colors.white, width: 1)),
                  alignment: Alignment.centerLeft,
                  child: Text(l.soilType,
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildGroundwaterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Встречены ли грунтовые воды?'),
        const SizedBox(height: 12),
        ToggleButtons(
          isSelected: [_bh.hasGroundwater == true, _bh.hasGroundwater == false],
          onPressed: (i) {
            setState(() {
              _bh = _bh.copyWith(
                hasGroundwater: i == 0,
                groundwaterDepth: i == 1 ? '' : _bh.groundwaterDepth,
              );
              if (i == 1) _gwDepthCtrl.clear();
              _hasChanges = true;
            });
          },
          borderRadius: BorderRadius.circular(8),
          selectedColor: Colors.white,
          fillColor: const Color(0xFF1e3a5f),
          children: const [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('💧 Да')),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('🚫 Нет')),
          ],
        ),
        if (_bh.hasGroundwater == true) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _gwDepthCtrl,
            decoration: InputDecoration(
              labelText: 'Глубина залегания грунтовых вод, м',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.water_drop),
              filled: true,
              fillColor: Colors.blue[50],
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            onChanged: (v) => setState(() => _hasChanges = true),
          ),
        ],
      ],
    );
  }
}
