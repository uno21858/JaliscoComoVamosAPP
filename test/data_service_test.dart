import 'package:flutter_test/flutter_test.dart';
import 'package:jcv_app/models/models.dart';
import 'package:jcv_app/services/supabase/graficas_destacadas.dart';
import 'package:jcv_app/services/supabase/supabase_data_service.dart';

/// Forma de jcv.grafica (v1.08, sin n), con porcentajes reales de la base AMG.
GraficaJson grafica(String variable, List<(int, String, double?)> opciones, {bool insuficiente = false}) => {
      'variable': variable,
      'tema': 'bienestar',
      'insuficiente': insuficiente,
      'muestra_pequena': false,
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
  test('pregunta normal: todas sus respuestas, dona hasta 6 opciones', () {
    final def = graficasDestacadas.firstWhere((d) => d.id == 'bienestar-vida');
    final chart = SupabaseDataService.buildChart(def, {'Q_6': q6}, DataSource.amg)!;
    expect(chart.slices, hasLength(6));
    expect(chart.top.label, 'Muy satisfecha(o)');
    expect(chart.top.percent, 54.8);
    expect(chart.kind, ChartKind.donut);
    expect(chart.subtitle, 'AMG 2026');
    expect(chart.summary, contains('Muy satisfecha(o)'));
  });

  test('grupo: un anillo por inciso con la suma de los códigos', () {
    final def = graficasDestacadas.firstWhere((d) => d.id == 'educacion-actividades');
    final data = {
      for (final (i, v) in def.variables.indexed) v: siNo(v, [37.5, 46.9, 34.6, 40.0, 20.0][i]),
    };
    final chart = SupabaseDataService.buildChart(def, data, DataSource.amg)!;
    expect(chart.multipleChoice, isTrue);
    expect(chart.kind, ChartKind.rings);
    expect(chart.slices.map((s) => s.label).first, 'Estudia');
    expect(chart.slices.first.percent, 37.5);
    expect(chart.subtitle, '% que lo hace a diario o de forma regular · AMG 2026');
  });

  test('"algo o mucho" suma dos códigos a un decimal', () {
    expect(SupabaseDataService.sumCodes(q6, const [4, 5]), 91.2);
  });

  test('si una pregunta no tiene suficientes respuestas, la gráfica se omite', () {
    final def = graficasDestacadas.firstWhere((d) => d.id == 'bienestar-vida');
    final pocas = grafica('Q_6', [(1, 'Nada', null)], insuficiente: true);
    expect(SupabaseDataService.buildChart(def, {'Q_6': pocas}, DataSource.tec), isNull);
    expect(SupabaseDataService.buildChart(def, const {}, DataSource.amg), isNull);
  });

  test('contar: solo banderas, nunca cuántas respuestas hay', () {
    final tec = SupabaseDataService.parseCount({'umbral': 30, 'bajo_umbral': true, 'muestra_pequena': false});
    expect(tec.belowThreshold, isTrue);
    expect(tec.threshold, 30);
    final amg = SupabaseDataService.parseCount({'umbral': 10, 'bajo_umbral': false, 'muestra_pequena': true});
    expect(amg.belowThreshold, isFalse);
    expect(amg.smallSample, isTrue);
    expect(() => SupabaseDataService.parseCount('x'), throwsA(anything));
  });

  test('máximo 2 filtros: con 2 activos solo se cambian los que ya tienen valor', () {
    const uno = DataFilters(municipality: 'ZAP');
    expect(uno.canSet(null), isTrue); // cabe otro
    const dos = DataFilters(municipality: 'ZAP', sex: 'F');
    expect(dos.canSet(dos.ageGroup), isFalse); // edad vacía: bloqueada
    expect(dos.canSet(dos.stratum), isFalse);
    expect(dos.canSet(dos.municipality), isTrue); // cambiar Zapopan por Tonalá sí
    expect(dos.canSet(dos.sex), isTrue);
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
