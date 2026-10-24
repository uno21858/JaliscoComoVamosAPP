import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/theme/app_colors.dart';

/// Barra multicolor de JCV (vino, rojo, naranja, dorado, amarillo, lima,
/// gris azulado y azul marino).
class JcvColorBar extends StatelessWidget {
  const JcvColorBar({super.key, this.height = 6, this.width, this.radius = 0});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Row(
            children: [
              for (final color in AppColors.brandBar)
                Expanded(child: ColoredBox(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Anillo del logo. MARCADOR: reemplazar por el archivo oficial de JCV.
class JcvRing extends StatelessWidget {
  const JcvRing({super.key, this.size = 56, this.onDark = false, this.semanticLabel});

  final double size;

  /// En fondo azul, el primer arco va en blanco.
  final bool onDark;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ring = CustomPaint(
      size: Size.square(size),
      painter: _RingPainter(firstArc: onDark ? AppColors.white : AppColors.navy),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: ring);
    return Semantics(label: label, image: true, child: ring);
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.firstArc});

  final Color firstArc;

  // Geometría del SVG original (caja de 56): radio 16, trazo 6, arcos de
  // 21.6 de largo que empiezan en -83.7°, 6.3°, 96.3° y 186.3°.
  static const _starts = <double>[-83.7, 6.3, 96.3, 186.3];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 56;
    final center = Offset(28 * s, 28 * s);
    final rect = Rect.fromCircle(center: center, radius: 16 * s);
    const sweep = 21.6 / 16; // largo del arco / radio = radianes
    final colors = <Color>[firstArc, AppColors.gold, AppColors.raspberry, AppColors.lime];
    for (var i = 0; i < 4; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * s
        ..color = colors[i];
      canvas.drawArc(rect, _starts[i] * math.pi / 180, sweep, false, paint);
    }
    final dots = <(Offset, Color)>[
      (const Offset(45.7, 10.3), AppColors.orange),
      (const Offset(45.7, 45.7), AppColors.yellow),
      (const Offset(10.3, 45.7), AppColors.wine),
      (const Offset(10.3, 10.3), AppColors.grayBlue),
    ];
    for (final (offset, color) in dots) {
      canvas.drawCircle(offset * s, 2.6 * s, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.firstArc != firstArc;
}

/// Logo completo: anillo + "Jalisco Cómo Vamos / Observatorio Ciudadano".
class JcvLogo extends StatelessWidget {
  const JcvLogo({super.key, this.onDark = false, this.ringSize = 56});

  final bool onDark;
  final double ringSize;

  @override
  Widget build(BuildContext context) {
    final ink = onDark ? AppColors.white : AppColors.navy;
    return Semantics(
      label: 'Jalisco Cómo Vamos, Observatorio Ciudadano',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            JcvRing(size: ringSize, onDark: onDark),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Jalisco Cómo Vamos',
                  style: TextStyle(
                    fontSize: 17,
                    height: 20 / 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.17,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Observatorio Ciudadano',
                  style: TextStyle(
                    fontSize: 11,
                    height: 14 / 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.44,
                    color: ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
