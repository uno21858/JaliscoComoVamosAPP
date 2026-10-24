enum ChartKind { donut, bars }

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
    required this.n,
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

  /// Registros sin ponderar detrás de la gráfica.
  final int n;

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
    required this.nAmg,
    required this.nTec,
    required this.summary,
  });

  final String id;
  final String topicId;
  final String title;
  final List<ComparisonRow> rows;
  final int nAmg;
  final int nTec;
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
  const TopicCharts({required this.charts, required this.n});

  final List<TopicChart> charts;
  final int n;

  /// AMG con 1 ≤ n < 30: se muestra con aviso de muestra pequeña (RF-DAT-07).
  bool get isSmallSample => n > 0 && n < 30;
}

/// Comparativas de una temática con los filtros aplicados.
class ComparisonData {
  const ComparisonData({
    required this.charts,
    required this.nAmg,
    required this.nTec,
  });

  final List<ComparisonChart> charts;
  final int nAmg;
  final int nTec;
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

/// Cuántos registros coinciden con los filtros (contador de 2.3).
class MatchCount {
  const MatchCount({required this.count, required this.belowThreshold, required this.threshold});

  final int count;

  /// Para Tec bajo el umbral nunca se muestra el número exacto (RF-DAT-04).
  final bool belowThreshold;
  final int threshold;
}
