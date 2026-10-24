import '../../core/error_sanitizer.dart';
import '../../core/result.dart';
import '../../core/utils/formatters.dart';
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
              _buildChart(seed, effective, filters, n),
        ];
        return Enough(TopicCharts(charts: charts, n: n));
      });

  @override
  Future<Result<Gated<ComparisonData>>> getComparison({
    required String topicId,
    required DataFilters filters,
  }) =>
      guardResult(() async {
        await simulateNetwork();
        final nAmg = MockCatalog.countFor(DataSource.amg, filters);
        final nTec = MockCatalog.countFor(DataSource.tec, filters);
        if (nTec < MockCatalog.minSample) {
          return const TooFew<ComparisonData>(MockCatalog.minSample);
        }
        final charts = [
          for (final seed in MockCatalog.chartsOf(topicId))
            if (seed.tec != null) _buildComparison(seed, filters, nAmg, nTec),
        ];
        return Enough(ComparisonData(charts: charts, nAmg: nAmg, nTec: nTec));
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
        return Enough(_buildChart(seed, effective, filters, n));
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
          count: n,
          belowThreshold: effective == DataSource.tec && n < MockCatalog.minSample,
          threshold: MockCatalog.minSample,
        );
      });

  TopicChart _buildChart(
    ChartSeed seed,
    DataSource source,
    DataFilters filters,
    int n,
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
      n: n,
      multipleChoice: seed.multipleChoice,
    );
  }

  ComparisonChart _buildComparison(
    ChartSeed seed,
    DataFilters filters,
    int nAmg,
    int nTec,
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
      nAmg: nAmg,
      nTec: nTec,
      summary: comparisonSummary(rows),
    );
  }

  /// Plantilla: la categoría más común y la que le sigue.
  static String _summaryFor(List<ChartSlice> slices, {required bool multipleChoice}) {
    final sorted = [...slices]..sort((a, b) => b.percent.compareTo(a.percent));
    final first = sorted.first;
    if (multipleChoice) {
      return '“${first.label}” es lo más mencionado: '
          '${Formatters.percent(first.percent)} lo eligió.';
    }
    if (sorted.length < 2) {
      return '“${first.label}” reúne el ${Formatters.percent(first.percent)}.';
    }
    final second = sorted[1];
    return 'La respuesta más común es “${first.label}” '
        '(${Formatters.percent(first.percent)}), seguida de “${second.label}” '
        '(${Formatters.percent(second.percent)}).';
  }

  /// Plantilla: la categoría con la diferencia más grande entre AMG y Tec.
  static String comparisonSummary(List<ComparisonRow> rows) {
    final row = rows.reduce(
      (a, b) => (a.tec - a.amg).abs() >= (b.tec - b.amg).abs() ? a : b,
    );
    final tec = Formatters.percent(row.tec);
    final amg = Formatters.percent(row.amg);
    final diff = row.tec - row.amg;
    if (diff.abs() < 3) {
      return 'En “${row.label}”, el Tec y el AMG están muy parejos '
          '($tec contra $amg).';
    }
    final more = diff > 0 ? 'más' : 'menos';
    return 'En el Tec, $more jóvenes responden “${row.label}” que en el AMG '
        '($tec contra $amg).';
  }
}
