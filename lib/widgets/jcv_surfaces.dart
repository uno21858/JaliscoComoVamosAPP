import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../flavors/flavor_config.dart';

/// Tarjeta blanca con radio 16 y sombra suave.
class JcvCard extends StatelessWidget {
  const JcvCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.color = AppColors.white,
    this.onTap,
    this.border,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: border,
        boxShadow: shadow ? AppColors.cardShadow : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Título de sección en mayúsculas ("ACCESOS RÁPIDOS").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text.toUpperCase(), style: AppTextStyles.overline),
    );
  }
}

/// Píldora de 32 de alto que resume la fuente y los filtros activos.
class InfoPill extends StatelessWidget {
  const InfoPill(this.label, {super.key, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.navy : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: filled ? null : Border.all(color: AppColors.grayBlue, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: filled ? FontWeight.w700 : FontWeight.w600,
          color: filled ? AppColors.white : AppColors.navy,
        ),
      ),
    );
  }
}

/// Fila desplazable de píldoras: la primera en azul (fuente), el resto blancas.
class PillRow extends StatelessWidget {
  const PillRow({super.key, required this.first, required this.others});

  final String first;
  final List<String> others;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          InfoPill(first, filled: true),
          for (final label in others) ...[
            const SizedBox(width: 8),
            InfoPill(label),
          ],
        ],
      ),
    );
  }
}

/// Etiqueta de 24 de alto ("NUEVA", "Bienestar subjetivo").
class TagPill extends StatelessWidget {
  const TagPill(
    this.label, {
    super.key,
    this.color = AppColors.lime,
    this.textColor = AppColors.navy,
    this.icon,
  });

  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconData != null) ...[
            Icon(iconData, size: 11, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip seleccionable de los filtros (2.3). Seleccionado = azul con palomita.
class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.navy : AppColors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.navy : AppColors.grayBlue,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 34,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  const Icon(CupertinoIcons.checkmark_alt, size: 12, color: AppColors.white),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? AppColors.white : AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rejilla de columnas iguales, como el `grid` del wireflow.
class EvenGrid extends StatelessWidget {
  const EvenGrid({
    super.key,
    required this.columns,
    required this.children,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  final int columns;
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final cells = <Widget>[];
      for (var i = 0; i < columns; i++) {
        if (i > 0) cells.add(SizedBox(width: spacing));
        final index = start + i;
        cells.add(Expanded(
          child: index < children.length ? children[index] : const SizedBox.shrink(),
        ));
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: runSpacing));
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells),
      ));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

/// Aviso con ícono sobre fondo de color (amarillo informativo, rosa de error).
class NoticeBox extends StatelessWidget {
  const NoticeBox({
    super.key,
    required this.text,
    required this.icon,
    this.background = AppColors.infoBackground,
    this.iconColor = AppColors.navy,
    this.textStyle,
  });

  final String text;
  final IconData icon;
  final Color background;
  final Color iconColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: textStyle ??
                  const TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta para no confundir datos sintéticos con resultados reales.
class MockDataBanner extends StatelessWidget {
  const MockDataBanner({super.key, this.padding = const EdgeInsets.symmetric(horizontal: 20)});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (!FlavorConfig.instance.showMockBanner) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: const NoticeBox(
        icon: CupertinoIcons.info,
        text: 'Datos de ejemplo para desarrollo. No son resultados reales.',
        textStyle: TextStyle(
          fontSize: 11,
          height: 16 / 11,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

/// Barra de avance redondeada (encuestas).
class ProgressTrack extends StatelessWidget {
  const ProgressTrack({
    super.key,
    required this.value,
    this.height = 8,
    this.track = AppColors.grayBlue,
    this.fill = AppColors.navy,
  });

  /// De 0 a 1.
  final double value;
  final double height;
  final Color track;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * value.clamp(0.0, 1.0).toDouble();
        return Container(
          height: height,
          decoration: BoxDecoration(color: track, borderRadius: radius),
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: width,
            height: height,
            decoration: BoxDecoration(color: fill, borderRadius: radius),
          ),
        );
      },
    );
  }
}

/// Manija de las hojas inferiores.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 5,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: AppColors.grayBlue,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// Círculo con ícono para estados (sin datos, error, éxito).
class IconCircle extends StatelessWidget {
  const IconCircle({
    super.key,
    required this.icon,
    this.size = 96,
    this.iconSize = 44,
    this.background = AppColors.white,
    this.iconColor = AppColors.navy,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}
