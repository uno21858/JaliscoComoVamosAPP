import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';

/// Una temática del informe. data null: con esos filtros hay muy pocas
/// respuestas y no se muestra nada (RF-DAT-06).
typedef ReportSection = ({String topicId, TopicCharts? data});

/// Arma el PDF del informe (RF-DAT-10) en el teléfono, con los mismos
/// agregados del dashboard. Sin n: JCV pidió no mostrar cuántas respuestas hay.
/// Mismas gráficas que la app: dona hasta 6 opciones, anillos en lo demás.
Future<Uint8List> buildReportPdf(
  ReportRequest request,
  List<ReportSection> sections, {
  DateTime? now,
}) async {
  Future<pw.Font> font(String weight) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/Montserrat-$weight.ttf'));
  PdfColor c(Color color) => PdfColor.fromInt(color.toARGB32());

  final black = await font('Black');
  final navy = c(AppColors.navy);
  final gray = c(AppColors.textSecondary);
  final caption = pw.TextStyle(fontSize: 8.5, color: gray);
  final body = pw.TextStyle(fontSize: 9.5, color: navy, lineSpacing: 2);
  final subtitle = [request.source.longLabel, ...request.filters.chipLabels].join(' · ');
  final fecha = Formatters.date(now ?? DateTime.now());

  final doc = pw.Document(
    title: 'Informe · Jalisco Cómo Vamos',
    author: 'Jalisco Cómo Vamos',
    theme: pw.ThemeData.withFont(base: await font('Regular'), bold: await font('Bold')),
  );

  // Arco en sentido horario desde las 12. En el PDF el origen está abajo a la
  // izquierda; se traza con segmentos cortos (3°) en lugar de bezierArc.
  void arc(PdfGraphics g, double r, double size, double from, double sweep) {
    final steps = math.max(2, (sweep / (math.pi / 60)).ceil());
    for (var i = 0; i <= steps; i++) {
      final a = from + sweep * i / steps;
      final x = size / 2 + r * math.sin(a);
      final y = size / 2 + r * math.cos(a);
      if (i == 0) {
        g.moveTo(x, y);
      } else {
        g.lineTo(x, y);
      }
    }
    g.strokePath();
  }

  pw.Widget centered(double size, String text, double fontSize) => pw.SizedBox(
        width: size,
        height: size,
        child: pw.Center(
          child: pw.Text(text, style: pw.TextStyle(font: black, fontSize: fontSize, color: navy)),
        ),
      );

  /// Una respuesta, hasta 6 opciones: dona con hueco y leyenda. Al centro, la más elegida.
  pw.Widget donut(TopicChart chart) {
    final slices = chart.slices;
    const size = 96.0, stroke = 18.0, gap = 0.04;
    return pw.Row(
      children: [
        pw.CustomPaint(
          size: const PdfPoint(size, size),
          painter: (g, _) {
            g
              ..setLineWidth(stroke)
              ..setLineCap(PdfLineCap.butt);
            var start = 0.0;
            for (final (i, slice) in slices.indexed) {
              final sweep = slice.percent / 100 * 2 * math.pi;
              if (sweep > gap) {
                g.setStrokeColor(c(AppColors.series(i)));
                arc(g, (size - stroke) / 2, size, start, sweep - gap);
              }
              start += sweep;
            }
          },
          child: centered(size, Formatters.percent(chart.top.percent), 15),
        ),
        pw.SizedBox(width: 18),
        pw.Expanded(
          child: pw.Column(
            children: [
              for (final (i, slice) in slices.indexed)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 7,
                        height: 7,
                        decoration: pw.BoxDecoration(
                            color: c(AppColors.series(i)), shape: pw.BoxShape.circle),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Expanded(child: pw.Text(slice.label, style: body.copyWith(fontSize: 9))),
                      pw.Text(Formatters.percent(slice.percent),
                          style: body.copyWith(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Un anillo de 0 a 100 % por inciso u opción (grupos y 7 o más opciones).
  pw.Widget ring(ChartSlice slice) {
    const size = 50.0, stroke = size * 0.12;
    return pw.SizedBox(
      width: 122,
      child: pw.Column(
        children: [
          pw.CustomPaint(
            size: const PdfPoint(size, size),
            painter: (g, _) {
              g
                ..setLineWidth(stroke)
                ..setLineCap(PdfLineCap.round)
                ..setLineJoin(PdfLineJoin.round)
                ..setStrokeColor(c(AppColors.divider));
              arc(g, (size - stroke) / 2, size, 0, 2 * math.pi);
              final fraction = (slice.percent / 100).clamp(0.0, 1.0);
              if (fraction > 0) {
                g.setStrokeColor(navy);
                arc(g, (size - stroke) / 2, size, 0, fraction * 2 * math.pi);
              }
            },
            child: centered(size, Formatters.percent(slice.percent), 10.5),
          ),
          pw.SizedBox(height: 4),
          pw.Text(slice.label,
              textAlign: pw.TextAlign.center, maxLines: 3, style: caption.copyWith(color: navy)),
        ],
      ),
    );
  }

  // Inseparable: título, gráfica y resumen van juntos a la siguiente página si no caben.
  pw.Widget chartBlock(TopicChart chart) => pw.Inseparable(
          child: pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 18),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(chart.title,
                style: body.copyWith(fontSize: 11.5, fontWeight: pw.FontWeight.bold)),
            if (chart.subtitle case final sub?) pw.Text(sub, style: caption),
            if (chart.multipleChoice)
              pw.Text('Cada inciso va por separado: los porcentajes no suman 100.', style: caption),
            pw.SizedBox(height: 8),
            if (chart.kind == ChartKind.donut)
              donut(chart)
            else
              pw.Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [for (final slice in chart.slices) ring(slice)],
              ),
            pw.SizedBox(height: 6),
            if (request.plainSummaries)
              pw.Container(
                width: double.infinity,
                margin: const pw.EdgeInsets.only(top: 4),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: c(AppColors.limePale),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(chart.summary, style: body.copyWith(fontSize: 9)),
              ),
          ],
        ),
      ));

  void addPage(List<pw.Widget> content) => doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Informe · Jalisco Cómo Vamos',
                  style: pw.TextStyle(font: black, fontSize: 10, color: navy)),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  for (final color in AppColors.brandBar)
                    pw.Expanded(child: pw.Container(height: 3, color: c(color))),
                ],
              ),
              pw.SizedBox(height: 16),
            ],
          ),
          footer: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Fuente: Encuesta de Bienestar de Jóvenes 2026, Jalisco Cómo Vamos. '
                    'Porcentajes ponderados. Generado el $fecha.',
                    style: caption.copyWith(fontSize: 7.5),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: caption.copyWith(fontSize: 7.5),
                ),
              ],
            ),
          ),
          build: (context) => content,
        ),
      );

  for (final section in sections) {
    final data = section.data;
    addPage([
      pw.Text(Topics.nameOf(section.topicId),
          style: pw.TextStyle(font: black, fontSize: 20, color: navy)),
      pw.SizedBox(height: 2),
      pw.Text(subtitle, style: caption),
      pw.SizedBox(height: 16),
      if (data == null)
        pw.Text(
          'Con estos filtros hay muy pocas respuestas para mostrar esta temática. '
          'Por privacidad no mostramos resultados de grupos muy chicos.',
          style: body,
        )
      else ...[
        if (data.isSmallSample)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Text('Muestra pequeña: interpreta con cuidado.',
                style: body.copyWith(color: c(AppColors.wine), fontWeight: pw.FontWeight.bold)),
          ),
        for (final chart in data.charts) chartBlock(chart),
      ],
    ]);
  }

  addPage([
    pw.Text('¿Cómo se hizo esta encuesta?',
        style: pw.TextStyle(font: black, fontSize: 20, color: navy)),
    for (final section in methodology) ...[
      pw.SizedBox(height: 14),
      pw.Text(section.title, style: body.copyWith(fontSize: 11.5, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      for (final point in section.points)
        pw.Bullet(text: point, style: body, bulletColor: navy, bulletSize: 3),
    ],
  ]);
  return doc.save();
}
