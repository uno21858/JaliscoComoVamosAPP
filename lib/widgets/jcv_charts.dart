import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/chart.dart';

/// Texto alterno de una gráfica para lector de pantalla (RNF-ACC-02).
String describeSlices(String title, List<ChartSlice> slices) {
  final parts = slices.map((s) => '${s.label}, ${Formatters.percent(s.percent)}');
  return '$title. ${parts.join('; ')}.';
}

/// Dona con hueco al centro. Geometría del SVG del wireflow: caja de 132,
/// radio 50, trazo 22, separación de 2 entre segmentos, empieza arriba.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.size,
    required this.semanticLabel,
    this.centerValue,
    this.centerLabel,
  });

  final List<ChartSlice> slices;
  final double size;
  final String semanticLabel;
  final String? centerValue;
  final String? centerLabel;

  @override
  Widget build(BuildContext context) {
    final value = centerValue;
    final label = centerLabel;
    final big = size >= 160;
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _DonutPainter([for (final s in slices) s.percent]),
            ),
            Padding(
              padding: EdgeInsets.all(size * 0.27),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    FittedBox(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: big ? 24 : 16,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  if (label != null)
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: big ? 11 : 9,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 132;
    final radius = 50 * s;
    final rect = Rect.fromCircle(center: Offset(66 * s, 66 * s), radius: radius);
    final total = values.fold<double>(0, (sum, v) => sum + v);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22 * s;

    if (total <= 0) {
      canvas.drawArc(rect, 0, 2 * math.pi, false, stroke..color = AppColors.grayBlue);
      return;
    }

    const gapLength = 2.0; // en unidades del SVG
    const gap = gapLength / 50; // en radianes
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final full = values[i] / total * 2 * math.pi;
      final sweep = values.length > 1 ? math.max(0.0, full - gap) : full;
      if (sweep > 0) {
        canvas.drawArc(rect, start, sweep, false, stroke..color = AppColors.series(i));
      }
      start += full;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}

/// Leyenda de colores con porcentaje, en 1 o 2 columnas.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.slices, this.columns = 1, this.fontSize = 11});

  final List<ChartSlice> slices;
  final int columns;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    Widget item(int i) {
      final slice = slices[i];
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.series(i),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              slice.label,
              style: TextStyle(
                fontSize: fontSize,
                height: 14 / 11,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            Formatters.percent(slice.percent),
            style: TextStyle(
              fontSize: fontSize,
              height: 14 / 11,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ],
      );
    }

    final rows = <Widget>[];
    for (var start = 0; start < slices.length; start += columns) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: columns == 1 ? 8 : 12));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var c = 0; c < columns; c++) ...[
            if (c > 0) const SizedBox(width: 16),
            Expanded(
              child: start + c < slices.length ? item(start + c) : const SizedBox.shrink(),
            ),
          ],
        ],
      ));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

/// Barras horizontales con etiqueta a la izquierda y porcentaje a la derecha.
/// Las barras se escalan contra el valor más alto; el número exacto va
/// escrito al lado, así que la lectura no depende del largo.
class BarRows extends StatelessWidget {
  const BarRows({
    super.key,
    required this.slices,
    this.labelWidth = 96,
    this.color = AppColors.navy,
  });

  final List<ChartSlice> slices;
  final double labelWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue = slices.fold<double>(0, (m, s) => math.max(m, s.percent));
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBar = math.max(0.0, constraints.maxWidth - labelWidth - 8 - 8 - 40);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < slices.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 28),
                child: Row(
                  children: [
                    SizedBox(
                      width: labelWidth,
                      child: Text(
                        slices[i].label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: maxValue > 0 ? math.max(2.0, slices[i].percent / maxValue * maxBar) : 2.0,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.percent(slices[i].percent),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Barras pareadas AMG (azul) contra Tec (dorado) para la comparativa (2.4).
class ComparisonBars extends StatelessWidget {
  const ComparisonBars({super.key, required this.rows});

  final List<ComparisonRow> rows;

  @override
  Widget build(BuildContext context) {
    final maxValue = rows.fold<double>(0, (m, r) => math.max(m, math.max(r.amg, r.tec)));
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBar = math.max(0.0, constraints.maxWidth - 8 - 40);
        Widget bar(double value, Color color) {
          return Row(
            children: [
              Container(
                width: maxValue > 0 ? math.max(2.0, value / maxValue * maxBar) : 2.0,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.percent(value),
                style: const TextStyle(
                  fontSize: 11,
                  height: 12 / 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              Semantics(
                label: '${rows[i].label}: AMG ${Formatters.percent(rows[i].amg)}, '
                    'Tec ${Formatters.percent(rows[i].tec)}',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rows[i].label,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    bar(rows[i].amg, AppColors.navy),
                    const SizedBox(height: 4),
                    bar(rows[i].tec, AppColors.gold),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Muestra de color + nombre de la serie + n (leyenda de la comparativa).
class SeriesKey extends StatelessWidget {
  const SeriesKey({super.key, required this.color, required this.title, required this.subtitle});

  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  height: 17 / 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
