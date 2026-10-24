import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'jcv_brand.dart';

/// Cabecera de pestaña: título grande, subtítulo y barra multicolor.
class RootHeader extends StatelessWidget {
  const RootHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showMark = false,
  });

  final String title;
  final String subtitle;

  /// Muestra el anillo de JCV a la derecha (solo en Inicio).
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.navy,
            padding: EdgeInsets.fromLTRB(20, top + 12, 20, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: AppTextStyles.tabTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white.withValues(alpha: 0.86),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (showMark) ...[
                  const SizedBox(width: 12),
                  const JcvRing(size: 44, onDark: true),
                ],
              ],
            ),
          ),
          const JcvColorBar(),
        ],
      ),
    );
  }
}

enum HeaderLeading { back, close, none }

/// Cabecera de pantalla: atrás o cerrar, título y una acción a la derecha.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.leading = HeaderLeading.back,
    this.onLeading,
    this.trailing,
  });

  final String title;
  final HeaderLeading leading;

  /// Si es null, regresa a la pantalla anterior.
  final VoidCallback? onLeading;
  final Widget? trailing;

  void _defaultLeading(BuildContext context) {
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final trailingWidget = trailing;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.navy,
            padding: EdgeInsets.fromLTRB(8, top + 4, 8, 8),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  if (leading == HeaderLeading.none)
                    const SizedBox(width: 12)
                  else
                    HeaderIconButton(
                      icon: leading == HeaderLeading.back
                          ? CupertinoIcons.chevron_left
                          : CupertinoIcons.xmark,
                      iconSize: leading == HeaderLeading.back ? 22 : 20,
                      tooltip: leading == HeaderLeading.back ? 'Atrás' : 'Cerrar',
                      onPressed: onLeading ?? () => _defaultLeading(context),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: AppTextStyles.screenTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (trailingWidget != null) trailingWidget,
                ],
              ),
            ),
          ),
          const JcvColorBar(),
        ],
      ),
    );
  }
}

/// Botón de ícono blanco de 44×44 para las cabeceras.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 22,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: iconSize),
      color: AppColors.white,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    );
  }
}

/// Píldora translúcida de la cabecera de encuesta ("Guardar y salir").
class HeaderPillButton extends StatelessWidget {
  const HeaderPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    return Material(
      color: AppColors.white.withValues(alpha: 0.14),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconData != null) ...[
                  Icon(iconData, size: 12, color: AppColors.white),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
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
