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

/// Crece de 0 a 1 al aparecer. Sin animación si el teléfono pide menos movimiento.
Widget _grow(BuildContext context, Widget Function(double t) builder) {
  final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: still ? Duration.zero : const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (context, t, _) => builder(t),
  );
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
            _grow(
              context,
              (t) => CustomPaint(
                size: Size.square(size),
                painter: _DonutPainter([for (final s in slices) s.percent], t),
              ),
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
  const _DonutPainter(this.values, this.progress);

  final List<double> values;
  final double progress;

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
    final limit = progress * 2 * math.pi;
    var elapsed = 0.0;
    for (var i = 0; i < values.length; i++) {
      final full = values[i] / total * 2 * math.pi;
      final sweep = math.min(values.length > 1 ? math.max(0.0, full - gap) : full, limit - elapsed);
      if (sweep > 0) {
        canvas.drawArc(
            rect, -math.pi / 2 + elapsed, sweep, false, stroke..color = AppColors.series(i));
      }
      elapsed += full;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) {
    if (oldDelegate.progress != progress || oldDelegate.values.length != values.length) return true;
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

/// Riel gris que vale 100 % con el relleno del porcentaje.
class _Track extends StatelessWidget {
  const _Track({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  static const _height = 10.0;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_height / 2);
    return Container(
      height: _height,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(color: AppColors.divider, borderRadius: radius),
      child: FractionallySizedBox(
        widthFactor: fraction.clamp(0.0, 1.0),
        heightFactor: 1,
        child: DecoratedBox(decoration: BoxDecoration(color: color, borderRadius: radius)),
      ),
    );
  }
}

/// Barras para preguntas de 7 o más opciones (donde una dona ya no se lee):
/// etiqueta y porcentaje arriba, riel abajo.
class BarRows extends StatelessWidget {
  const BarRows({super.key, required this.slices, this.color = AppColors.navy});

  final List<ChartSlice> slices;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
        fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w600, color: AppColors.navy);
    return _grow(
      context,
      (t) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < slices.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Semantics(
              label: '${slices[i].label}: ${Formatters.percent(slices[i].percent)}',
              excludeSemantics: true,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(slices[i].label, style: label)),
                      const SizedBox(width: 8),
                      Text(
                        Formatters.percent(slices[i].percent),
                        style: label.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _Track(fraction: slices[i].percent / 100 * t, color: color),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Un anillo por inciso, cada uno de 0 a 100 %. Para las preguntas de grupo:
/// sus porcentajes no suman 100, así que un pastel mentiría.
class RingGrid extends StatelessWidget {
  const RingGrid({super.key, required this.slices, this.ringSize = 68, this.columns = 3});

  final List<ChartSlice> slices;
  final double ringSize;
  final int columns;

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final size = math.min(ringSize, cell);
        return _grow(
          context,
          (t) => Wrap(
            spacing: spacing,
            runSpacing: 16,
            children: [
              for (final slice in slices)
                Semantics(
                  label: '${slice.label}: ${Formatters.percent(slice.percent)}',
                  excludeSemantics: true,
                  child: SizedBox(
                    width: cell,
                    child: Column(
                      children: [
                        SizedBox.square(
                          dimension: size,
                          child: CustomPaint(
                            painter: _RingPainter(slice.percent / 100 * t),
                            child: Center(
                              child: Text(
                                Formatters.percent(slice.percent),
                                style: TextStyle(
                                  fontSize: size * 0.21,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          slice.label,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 14 / 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.12;
    final rect =
        Rect.fromCircle(center: size.center(Offset.zero), radius: (size.width - stroke) / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = AppColors.divider);
    final sweep = fraction.clamp(0.0, 1.0) * 2 * math.pi;
    if (sweep > 0) canvas.drawArc(rect, -math.pi / 2, sweep, false, paint..color = AppColors.navy);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.fraction != fraction;
}

/// Barras pareadas AMG (azul) contra Tec (dorado) para la comparativa (2.4).
class ComparisonBars extends StatelessWidget {
  const ComparisonBars({super.key, required this.rows});

  final List<ComparisonRow> rows;

  @override
  Widget build(BuildContext context) {
    return _grow(context, (t) {
      Widget bar(double value, Color color) {
        return Row(
          children: [
            Expanded(child: _Track(fraction: value / 100 * t, color: color)),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              child: Text(
                Formatters.percent(value),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 11,
                  height: 12 / 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
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
    });
  }
}

/// Muestra de color + nombre de la serie + nota (leyenda de la comparativa).
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
