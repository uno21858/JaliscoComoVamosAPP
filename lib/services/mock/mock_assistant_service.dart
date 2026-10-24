import '../../core/error_sanitizer.dart';
import '../../core/result.dart';
import '../../core/utils/formatters.dart';
import '../../models/assistant.dart';
import '../../models/data_filters.dart';
import '../../models/data_source.dart';
import '../../repositories/assistant_repository.dart';
import 'mock_catalog.dart';
import 'mock_network.dart';

/// Asistente simulado: reconoce palabras clave en lugar de llamar a Gemini.
/// Igual que el real, nunca inventa cifras: todas salen de MockCatalog, que
/// es la misma fuente que usan las gráficas del dashboard mock.
class MockAssistantService implements AssistantRepository {
  static const _intents = <({List<String> keywords, String chartId, int row})>[
    (keywords: ['trabaj', 'empleo', 'chamba'], chartId: 'educacion-ocupacion', row: 1),
    (keywords: ['estudi', 'escuela', 'educaci'], chartId: 'educacion-ocupacion', row: 0),
    (keywords: ['transporte', 'camión', 'camion', 'auto', 'traslado'], chartId: 'transporte-medio', row: 0),
    (keywords: ['salud', 'enferm'], chartId: 'salud-percibida', row: 0),
    (keywords: ['segur', 'insegur', 'delito'], chartId: 'seguridad-colonia', row: 0),
    (keywords: ['bienestar', 'satisf', 'feliz', 'vida'], chartId: 'bienestar-satisfaccion', row: 1),
    (keywords: ['tiempo libre', 'pantalla', 'celular'], chartId: 'tiempo-pantalla', row: 2),
    (keywords: ['familia', 'hogar', 'padres', 'vives'], chartId: 'hogar-convivencia', row: 0),
    (keywords: ['comunidad', 'voluntari', 'vecin'], chartId: 'comunidad-participacion', row: 0),
  ];

  @override
  Future<Result<AssistantAnswer>> ask(String question) => guardResult(() async {
        await simulateNetwork();
        final text = question.toLowerCase();
        for (final intent in _intents) {
          if (intent.keywords.any(text.contains)) {
            return _answer(intent.chartId, intent.row);
          }
        }
        final topics = MockCatalog.topics.map((t) => t.name).join(', ');
        return AssistantAnswer(
          text: 'Todavía no tengo datos para responder eso. '
              'Puedo contarte sobre: $topics.',
        );
      });

  AssistantAnswer _answer(String chartId, int row) {
    final seed = MockCatalog.chartById(chartId)!;
    final amg = MockCatalog.perturb(seed.amg,
        chartId: chartId, source: DataSource.amg, filters: DataFilters.none, normalize: true);
    final tec = MockCatalog.perturb(seed.tec!,
        chartId: chartId, source: DataSource.tec, filters: DataFilters.none, normalize: true);
    final label = seed.labels[row];
    final amgValue = amg[row];
    final tecValue = tec[row];
    final diff = tecValue - amgValue;
    final comparison = diff.abs() < 3
        ? 'el Tec y el AMG están muy parejos'
        : 'en el Tec ${diff > 0 ? 'más' : 'menos'} jóvenes responden así que en el AMG';
    return AssistantAnswer(
      text: 'En “$label”, $comparison: '
          '${Formatters.percent(tecValue)} contra ${Formatters.percent(amgValue)}.',
      topicId: seed.topicId,
      figure: AssistantFigure(
        caption: label,
        amg: amgValue,
        tec: tecValue,
        nAmg: MockCatalog.amgSampleSize,
        nTec: MockCatalog.tecSampleSize,
      ),
    );
  }
}
