import 'package:flutter_test/flutter_test.dart';
import 'package:jcv_app/models/models.dart';
import 'package:jcv_app/services/supabase/graficas_destacadas.dart';
import 'package:jcv_app/services/supabase/supabase_data_service.dart';

/// Forma de jcv.grafica (v1.02), con porcentajes reales de la base AMG.
GraficaJson grafica(String variable, List<(int, String, double?)> opciones, {int? n = 1207, bool insuficiente = false}) => {
      'variable': variable,
      'tema': 'bienestar',
      'n': n,
      'insuficiente': insuficiente,
      'muestra_pequena': (n ?? 0) < 30,
      'opciones': [
        for (final (codigo, etiqueta, pct) in opciones) {'codigo': codigo, 'etiqueta': etiqueta, 'porcentaje': pct},
      ],
    };

final q6 = grafica('Q_6', [
  (1, 'Nada satisfecha(o)', 0.8),
  (2, 'Poco satisfecha(o)', 0.8),
  (3, 'Ni satisfecha(o), ni insatisfecha(o)', 7.0),
  (4, 'Algo satisfecha(o)', 36.4),
  (5, 'Muy satisfecha(o)', 54.8),
  (6, 'No sabe/No contestó', 0.2),
]);

GraficaJson siNo(String variable, double si) => grafica(variable, [(1, 'Sí', si), (2, 'No', 100 - si)]);

void main() {
  test('pregunta normal: todas sus respuestas, barras si son más de 4', () {
    final def = graficasDestacadas.firstWhere((d) => d.id == 'bienestar-vida');
    final chart = SupabaseDataService.buildChart(def, {'Q_6': q6}, DataSource.amg)!;
    expect(chart.slices, hasLength(6));
    expect(chart.top.label, 'Muy satisfecha(o)');
    expect(chart.top.percent, 54.8);
    expect(chart.kind, ChartKind.bars);
    expect(chart.n, 1207);
    expect(chart.subtitle, 'AMG 2026');
    expect(chart.summary, contains('Muy satisfecha(o)'));
  });

  test('grupo: una barra por inciso con la suma de los códigos', () {
    final def = graficasDestacadas.firstWhere((d) => d.id == 'educacion-actividades');
    final data = {
      for (final (i, v) in def.variables.indexed) v: siNo(v, [37.5, 46.9, 34.6, 40.0, 20.0][i]),
    };
    final chart = SupabaseDataService.buildChart(def, data, DataSource.amg)!;
    expect(chart.multipleChoice, isTrue);
    expect(chart.kind, ChartKind.bars);
    expect(chart.slices.map((s) => s.label).first, 'Estudia');
    expect(chart.slices.first.percent, 37.5);
    expect(chart.subtitle, '% que lo hace a diario o de forma regular · AMG 2026');
  });

  test('"algo o mucho" suma dos códigos a un decimal', () {
    expect(SupabaseDataService.sumCodes(q6, const [4, 5]), 91.2);
  });

  test('si una pregunta no tiene suficientes respuestas, la gráfica se omite', () {
    final def = graficasDestacadas.firstWhere((d) => d.id == 'bienestar-vida');
    final pocas = grafica('Q_6', [(1, 'Nada', null)], n: null, insuficiente: true);
    expect(SupabaseDataService.buildChart(def, {'Q_6': pocas}, DataSource.tec), isNull);
    expect(SupabaseDataService.buildChart(def, const {}, DataSource.amg), isNull);
  });

  test('contador: Tec bajo el umbral no trae número', () {
    final tec = SupabaseDataService.parseCount({'n': null, 'umbral': 30, 'bajo_umbral': true});
    expect(tec.count, 0);
    expect(tec.belowThreshold, isTrue);
    expect(tec.threshold, 30);
    final amg = SupabaseDataService.parseCount({'n': 23, 'umbral': 10, 'bajo_umbral': false});
    expect(amg.count, 23);
    expect(() => SupabaseDataService.parseCount('x'), throwsA(anything));
  });

  test('la lista de destacadas es consistente', () {
    final ids = graficasDestacadas.map((d) => d.id).toSet();
    expect(ids, hasLength(graficasDestacadas.length), reason: 'ids repetidos');
    for (final topic in Topics.all) {
      final defs = graficasDestacadas.where((d) => d.topicId == topic.id).toList();
      expect(defs, isNotEmpty, reason: topic.id);
      expect(defs.expand((d) => d.variables).length, lessThanOrEqualTo(40), reason: 'tope de jcv.graficas');
    }
  });
}
