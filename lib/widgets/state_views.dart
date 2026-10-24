import 'package:flutter/cupertino.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'jcv_buttons.dart';
import 'jcv_surfaces.dart';

/// Pantalla de estado centrada: círculo con ícono, título, texto y acciones.
class CenteredStateView extends StatelessWidget {
  const CenteredStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.note,
    this.actions = const [],
    this.circleColor = AppColors.white,
    this.iconColor = AppColors.navy,
    this.circleSize = 96,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Línea chica con candado ("Por privacidad no mostramos...").
  final String? note;
  final List<Widget> actions;
  final Color circleColor;
  final Color iconColor;
  final double circleSize;

  @override
  Widget build(BuildContext context) {
    final text = message;
    final noteText = note;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: [
          IconCircle(
            icon: icon,
            size: circleSize,
            iconSize: circleSize * 0.46,
            background: circleColor,
            iconColor: iconColor,
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(title, textAlign: TextAlign.center, style: AppTextStyles.stateTitle),
          ),
          if (text != null) ...[
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: AppTextStyles.body),
          ],
          if (noteText != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(CupertinoIcons.lock_fill, size: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    noteText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (actions.isNotEmpty) const SizedBox(height: 28),
          for (final action in actions) ...[
            action,
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// 2.8 Cargando: estado arriba y esqueletos de las tarjetas.
class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, this.message = 'Cargando datos…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const CupertinoActivityIndicator(color: AppColors.textSecondary, radius: 10),
              const SizedBox(width: 10),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const ExcludeSemantics(child: _SkeletonDonutCard()),
        const SizedBox(height: 14),
        const ExcludeSemantics(child: _SkeletonBarsCard()),
      ],
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.width, required this.height, this.light = false, this.circle = false});

  final double width;
  final double height;
  final bool light;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: light ? AppColors.skeletonLight : AppColors.skeleton,
        borderRadius: circle ? null : BorderRadius.circular(height / 2),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}

class _SkeletonDonutCard extends StatelessWidget {
  const _SkeletonDonutCard();

  @override
  Widget build(BuildContext context) {
    return const JcvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bone(width: 200, height: 14),
          SizedBox(height: 20),
          Row(
            children: [
              _Bone(width: 120, height: 120, circle: true),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(width: 140, height: 10),
                    SizedBox(height: 14),
                    _Bone(width: 116, height: 10),
                    SizedBox(height: 14),
                    _Bone(width: 128, height: 10),
                    SizedBox(height: 14),
                    _Bone(width: 96, height: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _Bone(width: double.infinity, height: 52, light: true),
        ],
      ),
    );
  }
}

class _SkeletonBarsCard extends StatelessWidget {
  const _SkeletonBarsCard();

  @override
  Widget build(BuildContext context) {
    return const JcvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bone(width: 220, height: 14),
          SizedBox(height: 10),
          _Bone(width: 150, height: 10, light: true),
          SizedBox(height: 28),
          _Bone(width: 260, height: 12),
          SizedBox(height: 26),
          _Bone(width: 210, height: 12),
          SizedBox(height: 26),
          _Bone(width: 180, height: 12),
          SizedBox(height: 26),
          _Bone(width: 110, height: 12),
        ],
      ),
    );
  }
}

/// 2.9 Sin suficientes respuestas para mostrar una gráfica confiable.
class TooFewStateView extends StatelessWidget {
  const TooFewStateView({
    super.key,
    required this.minSample,
    required this.onClearFilters,
    required this.onChangeFilters,
  });

  final int minSample;
  final VoidCallback onClearFilters;
  final VoidCallback onChangeFilters;

  @override
  Widget build(BuildContext context) {
    return CenteredStateView(
      icon: CupertinoIcons.tray,
      title: 'Aún no hay suficientes respuestas',
      message: 'Con estos filtros hay muy pocas respuestas para mostrar una gráfica confiable.',
      note: 'Por privacidad no mostramos grupos con menos de $minSample respuestas.',
      actions: [
        JcvButton(
          label: 'Quitar filtros',
          variant: JcvButtonVariant.secondary,
          expand: false,
          onPressed: onClearFilters,
        ),
        JcvTextButton(label: 'Cambiar filtros', onPressed: onChangeFilters),
      ],
    );
  }
}

/// 2.10 Error de conexión con botón de reintentar.
class ConnectionErrorView extends StatelessWidget {
  const ConnectionErrorView({
    super.key,
    required this.onRetry,
    this.message = 'Revisa tu conexión a internet e inténtalo de nuevo.',
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return CenteredStateView(
      icon: CupertinoIcons.wifi_slash,
      circleColor: AppColors.errorCircle,
      iconColor: AppColors.raspberry,
      title: 'No pudimos conectarnos',
      message: message,
      actions: [
        JcvButton(
          label: 'Reintentar',
          leadingIcon: CupertinoIcons.arrow_clockwise,
          expand: false,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
