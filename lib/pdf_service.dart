import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'models.dart';
import 'utils.dart';

// ─── Font cache (persist in memory) ───

pw.Font? _cachedFontRegular;
pw.Font? _cachedFontBold;

int _fontLoadAttempts = 0;
const int _maxFontLoadAttempts = 3;

Future<Uint8List?> _tryDownload(List<String> urls) async {
  for (final url in urls) {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.bodyBytes.length > 50000) {
        return response.bodyBytes;
      }
    } catch (_) {}
  }
  return null;
}

Future<void> _cacheWrite(String filename, Uint8List bytes) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
  } catch (_) {}
}

Future<Uint8List?> _cacheRead(String filename) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      if (bytes.length > 50000) return bytes;
    }
  } catch (_) {}
  return null;
}

pw.Font _fontFromBytes(Uint8List rawBytes) {
  final cleanBytes = Uint8List.fromList(rawBytes);
  final byteData =
      ByteData.view(cleanBytes.buffer, 0, cleanBytes.lengthInBytes);
  return pw.Font.ttf(byteData);
}

Future<void> _ensureFonts() async {
  if (_cachedFontRegular != null) return;

  if (_fontLoadAttempts >= _maxFontLoadAttempts) {
    _cachedFontRegular = pw.Font.helvetica();
    _cachedFontBold = pw.Font.helveticaBold();
    return;
  }

  _fontLoadAttempts++;

  Uint8List? regBytes = await _cacheRead('notosans_regular.ttf');
  Uint8List? boldBytes = await _cacheRead('notosans_bold.ttf');

  if (regBytes == null) {
    regBytes = await _tryDownload([
      'https://cdn.jsdelivr.net/gh/google/fonts/ofl/notosans/static/NotoSans-Regular.ttf',
      'https://github.com/google/fonts/raw/main/ofl/notosans/static/NotoSans-Regular.ttf',
    ]);
    if (regBytes != null) {
      await _cacheWrite('notosans_regular.ttf', regBytes);
    }
  }

  if (boldBytes == null) {
    boldBytes = await _tryDownload([
      'https://cdn.jsdelivr.net/gh/google/fonts/ofl/notosans/static/NotoSans-Bold.ttf',
      'https://github.com/google/fonts/raw/main/ofl/notosans/static/NotoSans-Bold.ttf',
    ]);
    if (boldBytes != null) {
      await _cacheWrite('notosans_bold.ttf', boldBytes);
    }
  }

  if (regBytes != null) {
    _cachedFontRegular = _fontFromBytes(regBytes);
    _cachedFontBold =
        (boldBytes != null) ? _fontFromBytes(boldBytes) : _cachedFontRegular;
    _fontLoadAttempts = 0;
  } else if (_fontLoadAttempts >= _maxFontLoadAttempts) {
    _cachedFontRegular = pw.Font.helvetica();
    _cachedFontBold = pw.Font.helveticaBold();
  }
}

pw.Font get _fontR => _cachedFontRegular ?? pw.Font.helvetica();
pw.Font get _fontB => _cachedFontBold ?? pw.Font.helveticaBold();

// ─── Public API ───

Future<void> printBorehole(Project project, Borehole borehole) async {
  final doc = await _buildPdf(project, borehole);
  await Printing.layoutPdf(onLayout: (format) async => doc.save());
}

Future<void> exportPdf(Project project, Borehole borehole) async {
  final doc = await _buildPdf(project, borehole);
  final dir = await getTemporaryDirectory();
  final safeName = borehole.number
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), '_');
  final file = File('${dir.path}/borehole_$safeName.pdf');
  await file.writeAsBytes(await doc.save());
  await Share.shareXFiles(
    [XFile(file.path)],
    subject: 'Скважина ${borehole.number}',
  );
}

Future<pw.Document> _buildPdf(Project project, Borehole borehole) async {
  await _ensureFonts();

  final doc = pw.Document();
  final totalDepth = borehole.totalDepth;

  final s14b = pw.TextStyle(font: _fontB, fontSize: 14);
  final s12b = pw.TextStyle(font: _fontB, fontSize: 12);
  final s10 = pw.TextStyle(font: _fontR, fontSize: 10);
  final s10b = pw.TextStyle(font: _fontB, fontSize: 10);
  final s10g =
      pw.TextStyle(font: _fontR, fontSize: 10, color: PdfColors.grey600);
  final s9 = pw.TextStyle(font: _fontR, fontSize: 9);
  final s9b = pw.TextStyle(font: _fontB, fontSize: 9);
  final s8 = pw.TextStyle(font: _fontR, fontSize: 8, color: PdfColors.grey);

  final colColors = <PdfColor>[
    PdfColors.amber200,
    PdfColors.lime300,
    PdfColors.green200,
    PdfColors.teal200,
    PdfColors.cyan200,
    PdfColors.blue200,
    PdfColors.indigo200,
    PdfColors.purple200,
    PdfColors.pink200,
    PdfColors.orange200,
  ];

  // ══════════════════════════════════════
  //  PAGE 1 — Info + Visual Column
  // ══════════════════════════════════════
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('ОПИСАНИЕ БУРОВОЙ СКВАЖИНЫ', style: s14b),
            pw.Text('BOREHOLE LOG', style: s8),
            pw.SizedBox(height: 12),
            pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(130),
                1: pw.FlexColumnWidth(),
                2: pw.FixedColumnWidth(130),
                3: pw.FlexColumnWidth(),
              },
              children: [
                _infoRow('Объект:', project.name, 'Скважина:', borehole.number,
                    s10g, s10b),
                _infoRow('Адрес:', project.address, 'Дата:',
                    formatDate(borehole.date), s10g, s10b),
                _infoRow('Описание:', project.description, 'Отметка:',
                    borehole.elevation, s10g, s10b),
              ],
            ),
            pw.SizedBox(height: 16),
            if (borehole.layers.isNotEmpty)
              pw.SizedBox(
                height: 200,
                child: pw.Row(children: [
                  pw.Expanded(
                    child: pw.Column(
                      children: borehole.layers.asMap().entries.map((e) {
                        final layer = e.value;
                        final totalT = borehole.layers.fold<double>(
                            0, (acc, l) => acc + (l.depthTo - l.depthFrom));
                        final pct = totalT > 0
                            ? (layer.depthTo - layer.depthFrom) / totalT
                            : 0.0;
                        final height = (200 * pct).clamp(8.0, 200.0);
                        return pw.Container(
                          height: height,
                          padding: const pw.EdgeInsets.all(3),
                          decoration: pw.BoxDecoration(
                            color: colColors[e.key % colColors.length],
                            border:
                                pw.Border.all(color: PdfColors.white, width: 1),
                          ),
                          child: pw.Text(layer.soilType,
                              style: s9, overflow: pw.TextOverflow.clip),
                        );
                      }).toList(),
                    ),
                  ),
                ]),
              ),
            pw.SizedBox(height: 12),
            if (borehole.hasGroundwater != null)
              pw.Text(
                borehole.hasGroundwater!
                    ? 'Грунтовые воды: ДА (глубина: ${borehole.groundwaterDepth} м)'
                    : 'Грунтовые воды: НЕТ',
                style: s12b,
              ),
            if (borehole.notes.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8),
                child: pw.Text('Примечания: ${borehole.notes}', style: s10),
              ),
            pw.Spacer(),
            pw.Row(children: [
              pw.Expanded(
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                          height: 1,
                          color: PdfColors.grey,
                          margin: const pw.EdgeInsets.only(bottom: 4)),
                      pw.Text('Инженер-геолог', style: s8),
                    ]),
              ),
              pw.SizedBox(width: 40),
              pw.Expanded(
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                          height: 1,
                          color: PdfColors.grey,
                          margin: const pw.EdgeInsets.only(bottom: 4)),
                      pw.Text('Начальник партии', style: s8),
                    ]),
              ),
            ]),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════
  //  PAGE 2 — Layers Table (with pagination)
  // ══════════════════════════════════════
  const rowsPerPage = 25;
  final layers = borehole.layers;
  final totalPages = (layers.length / rowsPerPage).ceil().clamp(1, 100);

  for (var page = 0; page < totalPages; page++) {
    final start = page * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, layers.length);
    final pageLayers = layers.sublist(start, end);
    final isLastPage = page == totalPages - 1;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Таблица слоёв — Скважина ${borehole.number}'
                '${totalPages > 1 ? ' (стр. ${page + 1}/$totalPages)' : ''}',
                style: s14b,
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: const {
                  0: pw.FixedColumnWidth(30),
                  1: pw.FlexColumnWidth(),
                  2: pw.FixedColumnWidth(50),
                  3: pw.FixedColumnWidth(50),
                  4: pw.FixedColumnWidth(60),
                  5: pw.FixedColumnWidth(60),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1e3a5f)),
                    children: [
                      _hCell('№', s9b),
                      _hCell('Грунт', s9b),
                      _hCell('От, м', s9b),
                      _hCell('До, м', s9b),
                      _hCell('Мощн., м', s9b),
                      _hCell('Образец', s9b),
                    ],
                  ),
                  ...pageLayers.asMap().entries.map((e) {
                    final l = e.value;
                    final t = l.thickness;
                    final globalIndex = start + e.key + 1;
                    return pw.TableRow(
                      children: [
                        _dCell('$globalIndex', s9),
                        _dCell(l.soilType, s9),
                        _dCell(l.depthFrom.toStringAsFixed(2), s9),
                        _dCell(l.depthTo.toStringAsFixed(2), s9),
                        _dCell(t > 0 ? t.toStringAsFixed(2) : '—', s9),
                        _dCell(l.sampleDepth.isEmpty ? '—' : l.sampleDepth, s9),
                      ],
                    );
                  }),
                  if (isLastPage)
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _dCell('', s9),
                        _dCell('ИТОГО', s9b),
                        _dCell('', s9),
                        _dCell('', s9),
                        _dCell(totalDepth.toStringAsFixed(2), s9b),
                        _dCell('', s9),
                      ],
                    ),
                ],
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Text(
                'Сгенерировано: ${DateTime.now().toString().substring(0, 19)} | Объект: ${project.name}',
                style: s8,
              ),
            ],
          );
        },
      ),
    );
  }

  return doc;
}

pw.Widget _hCell(String text, pw.TextStyle style) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
  );
}

pw.Widget _dCell(String text, pw.TextStyle style) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
  );
}

pw.TableRow _infoRow(
  String l1,
  String v1,
  String l2,
  String v2,
  pw.TextStyle labelStyle,
  pw.TextStyle valueStyle,
) {
  return pw.TableRow(
    children: [
      pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(l1, style: labelStyle)),
      pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(v1, style: valueStyle)),
      pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(l2, style: labelStyle)),
      pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(v2, style: valueStyle)),
    ],
  );
}
