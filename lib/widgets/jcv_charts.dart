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

/// Un anillo por opción, cada uno de 0 a 100 %. Para las preguntas de grupo
/// (sus porcentajes no suman 100, así que un pastel mentiría) y para las de 7 o
/// más opciones, donde una dona ya no se lee.
class RingGrid extends StatelessWidget {
  const RingGrid({super.key, required this.slices, this.ringSize = 68, this.columns = 3});

  final List<ChartSlice> slices;
  final double ringSize;
  final int columns;

  @override
  Widget build(BuildContext context) => _RingWrap(
        ringSize: ringSize,
        columns: columns,
        rings: [
          for (final s in slices)
            (
              label: s.label,
              semantics: '${s.label}: ${Formatters.percent(s.percent)}',
              arcs: [(s.percent, AppColors.navy)],
            ),
        ],
      );
}

/// Anillos dobles para la comparativa (2.4): AMG afuera (azul), Tec adentro (dorado).
class ComparisonRings extends StatelessWidget {
  const ComparisonRings({super.key, required this.rows, this.ringSize = 76, this.columns = 3});

  final List<ComparisonRow> rows;
  final double ringSize;
  final int columns;

  @override
  Widget build(BuildContext context) => _RingWrap(
        ringSize: ringSize,
        columns: columns,
        rings: [
          for (final r in rows)
            (
              label: r.label,
              semantics: '${r.label}: AMG ${Formatters.percent(r.amg)}, '
                  'Tec ${Formatters.percent(r.tec)}',
              arcs: [(r.amg, AppColors.navy), (r.tec, AppColors.gold)],
            ),
        ],
      );
}

/// Porcentaje (0 a 100) y color de cada arco, de afuera hacia adentro.
typedef _Ring = ({String label, String semantics, List<(double, Color)> arcs});

class _RingWrap extends StatelessWidget {
  const _RingWrap({required this.rings, required this.ringSize, required this.columns});

  final List<_Ring> rings;
  final double ringSize;
  final int columns;

  static const _value = TextStyle(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w800,
    color: AppColors.navy,
  );

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
              for (final ring in rings)
                Semantics(
                  label: ring.semantics,
                  excludeSemantics: true,
                  child: SizedBox(
                    width: cell,
                    child: Column(
                      children: [
                        SizedBox.square(
                          dimension: size,
                          child: CustomPaint(
                            painter: _RingPainter([for (final (v, c) in ring.arcs) (v / 100 * t, c)]),
                            child: ring.arcs.length == 1
                                ? Center(
                                    child: Text(
                                      Formatters.percent(ring.arcs.single.$1),
                                      style: TextStyle(
                                        fontSize: size * 0.21,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        if (ring.arcs.length > 1) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final (v, c) in ring.arcs)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(Formatters.percent(v), style: _value),
                                  ],
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          ring.label,
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
  const _RingPainter(this.arcs);

  /// Fracción de 0 a 1 y color, de afuera hacia adentro.
  final List<(double, Color)> arcs;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * (arcs.length == 1 ? 0.12 : 0.1);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < arcs.length; i++) {
      final radius = (size.width - stroke) / 2 - i * stroke * 1.4;
      final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: radius);
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = AppColors.divider);
      final sweep = arcs[i].$1.clamp(0.0, 1.0) * 2 * math.pi;
      if (sweep > 0) canvas.drawArc(rect, -math.pi / 2, sweep, false, paint..color = arcs[i].$2);
    }
  }

  // ponytail: se repinta en cada cuadro de la animación de todos modos.
  @override
  bool shouldRepaint(_RingPainter oldDelegate) => true;
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
