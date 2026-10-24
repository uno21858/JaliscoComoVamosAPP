import '../core/result.dart';
import '../models/models.dart';

/// Datos del dashboard (pestaña Datos e Inicio).
///
/// Todas las cifras son agregados calculados en el servidor. La regla del
/// umbral de privacidad Tec (RF-DAT-06) se aplica allá; la app solo pinta
/// [Enough] o [TooFew].
abstract interface class DataRepository {
  Future<Result<List<Topic>>> getTopics();

  Future<Result<SampleInfo>> getSampleInfo();

  Future<Result<List<Highlight>>> getHighlights();

  Future<Result<Gated<TopicCharts>>> getTopicCharts({
    required String topicId,
    required DataSource source,
    required DataFilters filters,
  });

  Future<Result<Gated<ComparisonData>>> getComparison({
    required String topicId,
    required DataFilters filters,
  });

  Future<Result<Gated<TopicChart>>> getChart({
    required String chartId,
    required DataSource source,
    required DataFilters filters,
  });

  /// Contador de la hoja de filtros (2.3).
  Future<Result<MatchCount>> countMatches({
    required DataSource source,
    required DataFilters filters,
  });
}
