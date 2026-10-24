import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Escala tipográfica del wireflow. Todo en Montserrat.
abstract final class AppTextStyles {
  static const _family = 'Montserrat';

  /// Título de pestaña · Black 28.
  static const tabTitle = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.28,
    color: AppColors.white,
  );

  /// Título de pantalla · ExtraBold 18.
  static const screenTitle = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
  );

  /// Pregunta de encuesta · Black 22.
  static const question = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w900,
    color: AppColors.navy,
  );

  /// Títulos grandes de estados (sin datos, error, éxito) · Black 20.
  static const stateTitle = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w900,
    color: AppColors.navy,
  );

  /// Título de tarjeta · ExtraBold 15.
  static const cardTitle = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w800,
    color: AppColors.navy,
  );

  /// Botón · Bold 16.
  static const button = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.navy,
  );

  /// Texto · Medium 14.
  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.navyDark,
  );

  /// Pie y etiquetas · Medium 12.
  static const caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Sección en mayúsculas ("ACCESOS RÁPIDOS").
  static const overline = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.96,
    color: AppColors.textSecondary,
  );

  /// Etiqueta de campo o de grupo de filtros.
  static const fieldLabel = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w800,
    color: AppColors.navyDark,
  );

  /// Enlace de texto ("Ver todos", "Cambiar filtros").
  static const link = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w800,
    color: AppColors.navy,
  );

  /// Texto de error en rojo vino.
  static const error = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w800,
    color: AppColors.wine,
  );
}
