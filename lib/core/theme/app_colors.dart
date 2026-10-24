import 'package:flutter/widgets.dart';

/// Paleta del wireflow "Wireflow App JCV" (hoja de componentes).
abstract final class AppColors {
  // Marca
  static const navy = Color(0xFF0E3B70); // cabeceras, títulos, texto
  static const navyDark = Color(0xFF12375D); // etiquetas de campos
  static const wine = Color(0xFFA31E3E); // texto de error
  static const raspberry = Color(0xFFDD1A4A); // botón +, acentos, alertas
  static const orange = Color(0xFFE88724);
  static const gold = Color(0xFFF5C12D); // secundario, serie Tec
  static const yellow = Color(0xFFF9D808);
  static const lime = Color(0xFFC2D02D); // acción principal
  static const grayBlue = Color(0xFFCFD7DF); // campos, deshabilitado

  // Neutros
  static const background = Color(0xFFF2F2F2);
  static const white = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF4A5B70);
  static const textDisabled = Color(0xFF5C6B7E);
  static const divider = Color(0xFFE1E6EB);
  static const skeleton = Color(0xFFE1E7EC);
  static const skeletonLight = Color(0xFFEEF2F5);

  // Fondos suaves
  static const infoBackground = Color(0xFFFDF3D4);
  static const limePale = Color(0xFFF4F7DA);
  static const errorBackground = Color(0xFFFDE7EC);
  static const errorCircle = Color(0xFFFBE3EA);

  /// Velo detrás de hojas y diálogos: rgba(8,25,48,0.48).
  static const scrim = Color(0x7A081930);

  /// Barra multicolor, en orden.
  static const brandBar = <Color>[
    wine,
    raspberry,
    orange,
    gold,
    yellow,
    lime,
    grayBlue,
    navy,
  ];

  /// Colores de series para gráficas, en el orden del wireflow.
  static const chartSeries = <Color>[
    navy,
    gold,
    raspberry,
    lime,
    orange,
    wine,
    yellow,
    grayBlue,
  ];

  static Color series(int index) => chartSeries[index % chartSeries.length];

  /// Sombra estándar de tarjetas: 0 2px 12px navy al 8%.
  static const cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x140E3B70), blurRadius: 12, offset: Offset(0, 2)),
  ];
}
