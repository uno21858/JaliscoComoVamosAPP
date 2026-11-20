import '../../core/error_sanitizer.dart';
import '../../core/result.dart';
import '../../core/utils/summaries.dart';
import '../../models/models.dart';
import '../../repositories/data_repository.dart';
import 'mock_catalog.dart';
import 'mock_network.dart';

/// Implementación de [DataRepository] con datos sintéticos.
/// Reglas que imita del servidor real:
/// - Tec bajo el umbral (30) no se muestra: devuelve [TooFew] (RF-DAT-06).
/// - AMG con muestra chica sí se muestra, con aviso (RF-DAT-07).
/// - Los resúmenes salen de plantillas, no de texto libre.
class MockDataService implements DataRepository {
  @override
  Future<Result<List<Topic>>> getTopics() => guardResult(() async {
        await simulateNetwork();
        return MockCatalog.topics;
      });

  @override
  Future<Result<SampleInfo>> getSampleInfo() => guardResult(() async {
        await simulateNetwork();
        return MockCatalog.sampleInfo;
      });

  @override
  Future<Result<List<Highlight>>> getHighlights() => guardResult(() async {
        await simulateNetwork();
        return [
          for (final seed in MockCatalog.highlightSeeds)
            _buildHighlight(seed.chartId, seed.slices, seed.text, seed.style),
        ];
      });

  Highlight _buildHighlight(
    String chartId,
    List<int> slices,
    String text,
    HighlightStyle style,
  ) {
    final chart = MockCatalog.chartById(chartId)!;
    final percent = slices.fold<double>(0, (sum, i) => sum + chart.amg[i]);
    return Highlight(
      topicId: chart.topicId,
      chartId: chart.id,
      tag: MockCatalog.topicById(chart.topicId)!.name,
      percent: percent,
      text: text,
      style: style,
    );
  }

  @override
  Future<Result<Gated<TopicCharts>>> getTopicCharts({
    required String topicId,
    required DataSource source,
    required DataFilters filters,
  }) =>
      guardResult(() async {
        await simulateNetwork();
        final effective = source == DataSource.tec ? DataSource.tec : DataSource.amg;
        final n = MockCatalog.countFor(effective, filters);
        if (effective == DataSource.tec && n < MockCatalog.minSample) {
          return const TooFew<TopicCharts>(MockCatalog.minSample);
        }
        final charts = [
          for (final seed in MockCatalog.chartsOf(topicId))
            if (effective == DataSource.amg || seed.tec != null)
              _buildChart(seed, effective, filters),
        ];
        return Enough(TopicCharts(charts: charts, isSmallSample: n > 0 && n < 30));
      });

  @override
  Future<Result<Gated<ComparisonData>>> getComparison({
    required String topicId,
    required DataFilters filters,
  }) =>
      guardResult(() async {
        await simulateNetwork();
        if (MockCatalog.countFor(DataSource.tec, filters) < MockCatalog.minSample) {
          return const TooFew<ComparisonData>(MockCatalog.minSample);
        }
        final charts = [
          for (final seed in MockCatalog.chartsOf(topicId))
            if (seed.tec != null) _buildComparison(seed, filters),
        ];
        return Enough(ComparisonData(charts: charts));
      });

  @override
  Future<Result<Gated<TopicChart>>> getChart({
    required String chartId,
    required DataSource source,
    required DataFilters filters,
  }) =>
      guardResult(() async {
        await simulateNetwork();
        final seed = MockCatalog.chartById(chartId);
        if (seed == null) throw StateError('Gráfica desconocida: $chartId');
        final effective =
            source == DataSource.tec && seed.tec != null ? DataSource.tec : DataSource.amg;
        final n = MockCatalog.countFor(effective, filters);
        if (effective == DataSource.tec && n < MockCatalog.minSample) {
          return const TooFew<TopicChart>(MockCatalog.minSample);
        }
        return Enough(_buildChart(seed, effective, filters));
      });

  @override
  Future<Result<MatchCount>> countMatches({
    required DataSource source,
    required DataFilters filters,
  }) =>
      guardResult(() async {
        await simulateNetwork();
        final effective = source == DataSource.amg ? DataSource.amg : DataSource.tec;
        final n = MockCatalog.countFor(effective, filters);
        return MatchCount(
          smallSample: n < 30,
          belowThreshold: n == 0 || (effective == DataSource.tec && n < MockCatalog.minSample),
          threshold: MockCatalog.minSample,
        );
      });

  TopicChart _buildChart(
    ChartSeed seed,
    DataSource source,
    DataFilters filters,
  ) {
    final base = source == DataSource.tec ? seed.tec! : seed.amg;
    final values = MockCatalog.perturb(
      base,
      chartId: seed.id,
      source: source,
      filters: filters,
      normalize: !seed.multipleChoice,
    );
    final slices = [
      for (var i = 0; i < seed.labels.length; i++) ChartSlice(seed.labels[i], values[i]),
    ];
    final sourceLabel = source == DataSource.tec ? 'Tec' : 'AMG 2026';
    final subtitle = seed.subtitle == null ? sourceLabel : '${seed.subtitle} · $sourceLabel';
    return TopicChart(
      id: seed.id,
      topicId: seed.topicId,
      title: seed.title,
      subtitle: subtitle,
      kind: seed.kind,
      slices: slices,
      summary: _summaryFor(slices, multipleChoice: seed.multipleChoice),
      multipleChoice: seed.multipleChoice,
    );
  }

  ComparisonChart _buildComparison(
    ChartSeed seed,
    DataFilters filters,
  ) {
    final amg = MockCatalog.perturb(seed.amg,
        chartId: seed.id, source: DataSource.amg, filters: filters, normalize: true);
    final tec = MockCatalog.perturb(seed.tec!,
        chartId: seed.id, source: DataSource.tec, filters: filters, normalize: true);
    final rows = [
      for (var i = 0; i < seed.labels.length; i++) ComparisonRow(seed.labels[i], amg[i], tec[i]),
    ];
    return ComparisonChart(
      id: seed.id,
      topicId: seed.topicId,
      title: seed.title,
      rows: rows,
      summary: comparisonSummary(rows),
    );
  }

  static String _summaryFor(List<ChartSlice> slices, {required bool multipleChoice}) =>
      Summaries.chart(slices, multipleChoice: multipleChoice);

  static String comparisonSummary(List<ComparisonRow> rows) => Summaries.comparison(rows);
}
