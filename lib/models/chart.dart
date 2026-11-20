/// donut: una respuesta, hasta 6 opciones. rings: grupo (cada inciso de 0 a
/// 100 %) o 7 o más opciones. Sin barras: JCV las quiso fuera de la app.
enum ChartKind { donut, rings }

/// Una categoría de respuesta con su porcentaje (0 a 100).
class ChartSlice {
  const ChartSlice(this.label, this.percent);
  final String label;
  final double percent;
}

/// Gráfica de una temática. Solo agregados: la app nunca recibe filas.
class TopicChart {
  const TopicChart({
    required this.id,
    required this.topicId,
    required this.title,
    required this.kind,
    required this.slices,
    required this.summary,
    this.subtitle,
    this.multipleChoice = false,
  });

  final String id;
  final String topicId;
  final String title;
  final String? subtitle;
  final ChartKind kind;
  final List<ChartSlice> slices;

  /// Resumen en lenguaje sencillo. Lo arma el servidor con una plantilla.
  final String summary;

  /// Si se podían elegir varias opciones, los porcentajes no suman 100.
  final bool multipleChoice;

  ChartSlice get top =>
      slices.reduce((a, b) => a.percent >= b.percent ? a : b);
}

class ComparisonRow {
  const ComparisonRow(this.label, this.amg, this.tec);
  final String label;
  final double amg;
  final double tec;
}

/// Misma pregunta en AMG y Tec, lado a lado (2.4).
class ComparisonChart {
  const ComparisonChart({
    required this.id,
    required this.topicId,
    required this.title,
    required this.rows,
    required this.summary,
  });

  final String id;
  final String topicId;
  final String title;
  final List<ComparisonRow> rows;
  final String summary;
}

enum HighlightStyle { gold, navy, lime }

/// Tarjeta de "Hallazgos destacados" en Inicio.
class Highlight {
  const Highlight({
    required this.topicId,
    required this.chartId,
    required this.tag,
    required this.percent,
    required this.text,
    required this.style,
  });

  final String topicId;
  final String chartId;
  final String tag;
  final double percent;
  final String text;
  final HighlightStyle style;
}

/// Gráficas de una temática con los filtros aplicados.
class TopicCharts {
  const TopicCharts({required this.charts, this.isSmallSample = false});

  final List<TopicChart> charts;

  /// AMG con menos de 30 respuestas: se muestra con aviso de muestra pequeña
  /// (RF-DAT-07). El Tec nunca llega aquí con menos de 30.
  final bool isSmallSample;
}

/// Comparativas de una temática con los filtros aplicados.
class ComparisonData {
  const ComparisonData({required this.charts});

  final List<ComparisonChart> charts;
}

/// Resultado que respeta el umbral de privacidad de la muestra Tec
/// (RF-DAT-06): o hay suficientes respuestas, o no se muestra nada.
sealed class Gated<T> {
  const Gated();
}

final class Enough<T> extends Gated<T> {
  const Enough(this.data);
  final T data;
}

final class TooFew<T> extends Gated<T> {
  const TooFew(this.minSample);
  final int minSample;
}

/// Si con los filtros alcanza para mostrar gráficas (2.3). Sin conteo: JCV
/// pidió no mostrar cuántas respuestas hay, y la base ya no lo regresa.
class MatchCount {
  const MatchCount({required this.smallSample, required this.belowThreshold, required this.threshold});

  /// Menos de 30 respuestas, pero sobre el umbral.
  final bool smallSample;
  final bool belowThreshold;
  final int threshold;
}
