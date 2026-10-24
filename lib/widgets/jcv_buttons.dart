import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum JcvButtonVariant {
  /// Lima: acción principal.
  primary,

  /// Dorado: acción secundaria.
  secondary,

  /// Blanco con borde azul.
  outline,

  /// Negro: Apple Pay / Google Pay.
  black,
}

/// Botón del design system. onPressed null = deshabilitado (gris).
class JcvButton extends StatelessWidget {
  const JcvButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = JcvButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.small = false,
    this.expand = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final JcvButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  /// 40 de alto, para botones dentro de tarjetas.
  final bool small;

  /// Ocupa todo el ancho disponible.
  final bool expand;

  /// Muestra un indicador y deshabilita el botón.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final height = small ? 40.0 : 52.0;

    var background = AppColors.lime;
    var foreground = AppColors.navy;
    var side = BorderSide.none;
    switch (variant) {
      case JcvButtonVariant.primary:
        background = AppColors.lime;
        foreground = AppColors.navy;
      case JcvButtonVariant.secondary:
        background = AppColors.gold;
        foreground = AppColors.navy;
      case JcvButtonVariant.outline:
        background = AppColors.white;
        foreground = AppColors.navy;
        side = const BorderSide(color: AppColors.navy, width: 1.5);
      case JcvButtonVariant.black:
        background = const Color(0xFF000000);
        foreground = AppColors.white;
    }
    if (!enabled && !busy) {
      foreground = AppColors.textDisabled;
      if (variant == JcvButtonVariant.outline) {
        side = const BorderSide(color: AppColors.grayBlue, width: 1.5);
      } else {
        background = AppColors.grayBlue;
      }
    }

    final textStyle = TextStyle(
      fontSize: small ? 14 : 16,
      height: small ? 18 / 14 : 20 / 16,
      fontWeight: FontWeight.w700,
      color: foreground,
    );
    final leading = leadingIcon;
    final trailing = trailingIcon;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy) ...[
          CupertinoActivityIndicator(color: foreground, radius: 9),
          const SizedBox(width: 10),
        ] else if (leading != null) ...[
          Icon(leading, size: small ? 14 : 18, color: foreground),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          Icon(trailing, size: 14, color: foreground),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: background,
        shape: StadiumBorder(side: side),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: height,
              minWidth: expand ? double.infinity : 0,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Center(widthFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// Enlace de texto azul ("Cambiar filtros", "Volver a encuestas").
class JcvTextButton extends StatelessWidget {
  const JcvTextButton({super.key, required this.label, required this.onPressed, this.underline = false});

  final String label;
  final VoidCallback? onPressed;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          decoration: underline ? TextDecoration.underline : TextDecoration.none,
        ),
      ),
      child: Text(label),
    );
  }
}

/// Enlace con flecha a la derecha ("Ver detalle ›").
class ChevronLink extends StatelessWidget {
  const ChevronLink({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon ?? CupertinoIcons.chevron_right, size: 12, color: AppColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}
