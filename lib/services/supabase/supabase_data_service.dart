import 'dart:async';
import 'dart:math';

import 'package:supabase/supabase.dart';

import '../../core/app_error.dart';
import '../../core/error_sanitizer.dart';
import '../../core/result.dart';
import '../../core/utils/summaries.dart';
import '../../models/models.dart';
import '../../repositories/data_repository.dart';
import 'graficas_destacadas.dart';

/// Una gráfica tal como la regresa jcv.grafica.
typedef GraficaJson = Map<String, Object?>;

/// Datos reales: jcv.graficas y jcv.contar con la anon key (solo agregados).
/// Los umbrales los aplica el servidor (v1.02): AMG < 10 y Tec < 30 llegan
/// como "insuficiente" y aquí se vuelven [TooFew] o se omite la gráfica.
class SupabaseDataService implements DataRepository {
  SupabaseDataService(this._client);

  final SupabaseClient _client;
  static const _timeout = Duration(seconds: 15);

  static String _fuente(DataSource source) => source == DataSource.tec ? 'TEC' : 'AMG';

  static Map<String, Object?> _filtros(DataFilters f) => {
        'p_municipio': f.municipality,
        'p_edad': f.ageGroup,
        'p_sexo': f.sex,
        'p_estrato': f.stratum,
      };

  Future<Object?> _rpc(String function, Map<String, Object?> params) async {
    try {
      return await _client.schema('jcv').rpc<Object?>(function, params: params).timeout(_timeout);
    } on PostgrestException catch (e) {
      throw ServerError('jcv.$function ${e.code}');
    } on TimeoutException {
      throw NetworkError('jcv.$function tardó más de 15 s');
    } on Exception catch (e) {
      throw NetworkError('$e'); // ponytail: lo que no es de Postgres aquí es red
    }
  }

  Future<MatchCount> _contar(String fuente, DataFilters filters) async =>
      parseCount(await _rpc('contar', {'p_fuente': fuente, ..._filtros(filters)}));

  Future<Map<String, GraficaJson>> _graficas(List<String> variables, String fuente, DataFilters filters) async =>
      byVariable(await _rpc('graficas', {'p_variables': variables, 'p_fuente': fuente, ..._filtros(filters)}));

  static List<ChartDef> _defsOf(String topicId) =>
      graficasDestacadas.where((d) => d.topicId == topicId).toList();

  static List<String> _variablesOf(List<ChartDef> defs) => [for (final d in defs) ...d.variables];

  @override
  Future<Result<List<Topic>>> getTopics() async => const Ok(Topics.all);

  @override
  Future<Result<SampleInfo>> getSampleInfo() => guardResult(() async {
        final count = await _contar('AMG', DataFilters.none);
        return SampleInfo(total: count.count, minAge: 15, maxAge: 29, edition: 'AMG 2026');
      });

  @override
  Future<Result<List<Highlight>>> getHighlights() => guardResult(() async {
        final data = await _graficas([for (final h in hallazgosInicio) h.variable], 'AMG', DataFilters.none);
        return [
          for (final h in hallazgosInicio)
            if (data[h.variable] case final g? when g['insuficiente'] != true)
              Highlight(
                topicId: g['tema'] as String? ?? '',
                chartId: h.chartId,
                tag: Topics.nameOf(g['tema'] as String? ?? ''),
                percent: sumCodes(g, h.codes),
                text: h.text,
                style: h.style,
              ),
        ];
      });

  @override
  Future<Result<Gated<TopicCharts>>> getTopicCharts({
    required String topicId,
    required DataSource source,
    required DataFilters filters,
  }) =>
      guardResult(() async {
        final fuente = _fuente(source);
        final defs = _defsOf(topicId);
        final (count, data) = await (_contar(fuente, filters), _graficas(_variablesOf(defs), fuente, filters)).wait;
        if (count.belowThreshold) return TooFew<TopicCharts>(count.threshold);
        final charts = [
          for (final d in defs)
            if (buildChart(d, data, source) case final chart?) chart,
        ];
        if (fuente == 'AMG') return Enough(TopicCharts(charts: charts, n: count.count));
        // Tec: cada encuesta contestada cuenta como una persona aparte (no se ligan,
        // RF-ENC-09), así que el total de personas sale inflado. La n real es la
        // de las gráficas, y si ninguna llega al umbral no hay nada que mostrar.
        if (charts.isEmpty) return TooFew<TopicCharts>(count.threshold);
        return Enough(TopicCharts(charts: charts, n: charts.map((c) => c.n).reduce(max)));
      });

  @override
  Future<Result<Gated<ComparisonData>>> getComparison({
    required String topicId,
    required DataFilters filters,
  }) =>
      guardResult(() async {
        final defs = _defsOf(topicId);
        final variables = _variablesOf(defs);
        final (amgCount, tecCount, amg, tec) = await (
          _contar('AMG', filters),
          _contar('TEC', filters),
          _graficas(variables, 'AMG', filters),
          _graficas(variables, 'TEC', filters),
        ).wait;
        if (tecCount.belowThreshold) return TooFew<ComparisonData>(tecCount.threshold);
        if (amgCount.belowThreshold) return TooFew<ComparisonData>(amgCount.threshold);
        final charts = [
          for (final d in defs)
            if (buildComparison(d, amg, tec) case final chart?) chart,
        ];
        // Igual que en getTopicCharts: la n del Tec sale de las gráficas.
        if (charts.isEmpty) return TooFew<ComparisonData>(tecCount.threshold);
        return Enough(ComparisonData(
          charts: charts,
          nAmg: amgCount.count,
          nTec: charts.map((c) => c.nTec).reduce(max),
        ));
      });

  @override
  Future<Result<Gated<TopicChart>>> getChart({
    required String chartId,
    required DataSource source,
    required DataFilters filters,
  }) =>
      guardResult(() async {
        final def = graficasDestacadas.where((d) => d.id == chartId).firstOrNull;
        if (def == null) throw const ValidationError('Esa gráfica ya no existe.');
        final fuente = _fuente(source);
        final (count, data) = await (_contar(fuente, filters), _graficas(def.variables, fuente, filters)).wait;
        final chart = buildChart(def, data, source);
        if (count.belowThreshold || chart == null) return TooFew<TopicChart>(count.threshold);
        return Enough(chart);
      });

  @override
  Future<Result<MatchCount>> countMatches({
    required DataSource source,
    required DataFilters filters,
  }) =>
      guardResult(() => _contar(source == DataSource.amg ? 'AMG' : 'TEC', filters));

  // ---------- JSON -> modelos (públicos para las pruebas) ----------

  static MatchCount parseCount(Object? data) {
    if (data case {'umbral': final num umbral, 'bajo_umbral': final bool bajo}) {
      final n = data['n'];
      return MatchCount(count: n is num ? n.toInt() : 0, belowThreshold: bajo, threshold: umbral.toInt());
    }
    throw const ServerError('contar sin formato');
  }

  static Map<String, GraficaJson> byVariable(Object? data) => {
        if (data is List)
          for (final g in data)
            if (g case {'variable': final String variable}) variable: g as GraficaJson,
      };

  static List<({int codigo, String etiqueta, double porcentaje})> _opciones(GraficaJson g) => [
        if (g['opciones'] case final List<Object?> opciones)
          for (final o in opciones)
            if (o case {'codigo': final num codigo, 'etiqueta': final String etiqueta, 'porcentaje': final num pct})
              (codigo: codigo.toInt(), etiqueta: etiqueta, porcentaje: pct.toDouble()),
      ];

  static int _n(GraficaJson g) => switch (g['n']) { final num n => n.toInt(), _ => 0 };

  /// Suma de los porcentajes de [codes], a un decimal ("algo" + "mucho").
  static double sumCodes(GraficaJson g, List<int> codes) {
    final total = _opciones(g).where((o) => codes.contains(o.codigo)).fold<double>(0, (t, o) => t + o.porcentaje);
    return (total * 10).round() / 10;
  }

  static bool _usable(GraficaJson? g) => g != null && g['insuficiente'] != true && _opciones(g).isNotEmpty;

  /// null si alguna pregunta de la gráfica no tiene suficientes respuestas.
  static TopicChart? buildChart(ChartDef def, Map<String, GraficaJson> data, DataSource source) {
    final sourceLabel = source == DataSource.tec ? 'Tec' : 'AMG 2026';
    final subtitle = def.subtitle == null ? sourceLabel : '${def.subtitle} · $sourceLabel';
    final graficas = [for (final v in def.variables) data[v]];
    if (!graficas.every(_usable)) return null;

    final slices = def.isGroup
        ? [for (var i = 0; i < graficas.length; i++) ChartSlice(def.labels[i], sumCodes(graficas[i]!, def.codes))]
        : [for (final o in _opciones(graficas.single!)) ChartSlice(o.etiqueta, o.porcentaje)];
    return TopicChart(
      id: def.id,
      topicId: def.topicId,
      title: def.title,
      subtitle: subtitle,
      kind: !def.isGroup && slices.length <= 6 ? ChartKind.donut : ChartKind.rings,
      slices: slices,
      summary: Summaries.chart(slices, multipleChoice: def.isGroup),
      n: _n(graficas.first!),
      multipleChoice: def.isGroup,
    );
  }

  static ComparisonChart? buildComparison(
    ChartDef def,
    Map<String, GraficaJson> amg,
    Map<String, GraficaJson> tec,
  ) {
    final a = [for (final v in def.variables) amg[v]];
    final t = [for (final v in def.variables) tec[v]];
    if (!a.every(_usable) || !t.every(_usable)) return null;

    final List<ComparisonRow> rows;
    if (def.isGroup) {
      rows = [
        for (var i = 0; i < a.length; i++)
          ComparisonRow(def.labels[i], sumCodes(a[i]!, def.codes), sumCodes(t[i]!, def.codes)),
      ];
    } else {
      final tecBy = {for (final o in _opciones(t.single!)) o.codigo: o.porcentaje};
      rows = [
        for (final o in _opciones(a.single!)) ComparisonRow(o.etiqueta, o.porcentaje, tecBy[o.codigo] ?? 0),
      ];
    }
    return ComparisonChart(
      id: def.id,
      topicId: def.topicId,
      title: def.title,
      rows: rows,
      nAmg: _n(a.first!),
      nTec: _n(t.first!),
      summary: Summaries.comparison(rows),
    );
  }
}
