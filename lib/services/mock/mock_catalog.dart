// DATOS SINTÉTICOS PARA DESARROLLO. No son resultados de la encuesta AMG ni
// de estudiantes Tec. Sirven para construir y probar la interfaz mientras no
// existe el backend. Las etiquetas siguen el catálogo del SRS (§12.3); las
// preguntas y categorías definitivas dependen de lo que se acuerde con JCV.

import 'dart:math';

import '../../models/models.dart';

class ChartSeed {
  const ChartSeed({
    required this.id,
    required this.topicId,
    required this.title,
    required this.kind,
    required this.labels,
    required this.amg,
    this.tec,
    this.subtitle,
    this.multipleChoice = false,
  });

  final String id;
  final String topicId;
  final String title;
  final String? subtitle;
  final ChartKind kind;
  final List<String> labels;
  final List<double> amg;

  /// null: la pregunta no se aplicó a estudiantes Tec.
  final List<double>? tec;
  final bool multipleChoice;
}

abstract final class MockCatalog {
  static const amgSampleSize = 1200;
  static const tecSampleSize = 150;
  static const minSample = 30;

  static const sampleInfo = SampleInfo(
    total: amgSampleSize,
    minAge: 15,
    maxAge: 29,
    edition: 'AMG 2026',
  );

  static const topics = Topics.all;

  static Topic? topicById(String id) => Topics.byId(id);

  static const charts = <ChartSeed>[
    ChartSeed(
      id: 'bienestar-satisfaccion',
      topicId: 'bienestar',
      title: '¿Qué tan satisfecho estás con tu vida?',
      kind: ChartKind.donut,
      labels: ['Muy satisfecho', 'Satisfecho', 'Más o menos', 'Poco o nada'],
      amg: [28, 41, 20, 11],
      tec: [33, 44, 16, 7],
    ),
    ChartSeed(
      id: 'bienestar-ansiedad',
      topicId: 'bienestar',
      title: '¿Qué tan seguido te sientes nervioso o ansioso?',
      subtitle: 'Últimas dos semanas',
      kind: ChartKind.bars,
      labels: ['Nunca', 'Casi nunca', 'A veces', 'Casi siempre', 'Siempre'],
      amg: [14, 27, 35, 16, 8],
    ),
    ChartSeed(
      id: 'educacion-ocupacion',
      topicId: 'educacion-trabajo',
      title: '¿Estudias, trabajas o ambos?',
      kind: ChartKind.donut,
      labels: ['Solo estudia', 'Estudia y trabaja', 'Solo trabaja', 'Ni estudia ni trabaja'],
      amg: [43, 17, 28, 12],
      tec: [72, 22, 4, 2],
    ),
    ChartSeed(
      id: 'educacion-horas',
      topicId: 'educacion-trabajo',
      title: 'Horas de trabajo a la semana',
      subtitle: 'Solo quienes trabajan',
      kind: ChartKind.bars,
      labels: ['Menos de 10 h', '10 a 20 h', '21 a 40 h', 'Más de 40 h'],
      amg: [18, 24, 38, 20],
    ),
    ChartSeed(
      id: 'tiempo-pantalla',
      topicId: 'tiempo-libre',
      title: 'Horas al día frente a pantallas',
      subtitle: 'Fuera de la escuela o el trabajo',
      kind: ChartKind.donut,
      labels: ['2 o menos', '3 a 4', '5 a 6', '7 o más'],
      amg: [15, 34, 29, 22],
      tec: [12, 38, 32, 18],
    ),
    ChartSeed(
      id: 'tiempo-actividades',
      topicId: 'tiempo-libre',
      title: '¿Qué haces en tu tiempo libre?',
      subtitle: 'Podían elegir hasta 3 opciones',
      kind: ChartKind.bars,
      labels: ['Redes sociales', 'Ver a amigos', 'Deporte', 'Videojuegos', 'Leer'],
      amg: [71, 54, 38, 33, 17],
      multipleChoice: true,
    ),
    ChartSeed(
      id: 'hogar-convivencia',
      topicId: 'hogar-familia',
      title: '¿Con quién vives?',
      kind: ChartKind.donut,
      labels: ['Ambos padres', 'Un padre o madre', 'Pareja', 'Solo o sola', 'Otras personas'],
      amg: [52, 21, 14, 6, 7],
      tec: [61, 18, 3, 12, 6],
    ),
    ChartSeed(
      id: 'hogar-relaciones',
      topicId: 'hogar-familia',
      title: 'Satisfacción con tus relaciones familiares',
      kind: ChartKind.bars,
      labels: ['Nada', 'Poco', 'Algo', 'Mucho', 'Totalmente'],
      amg: [5, 9, 24, 37, 25],
    ),
    ChartSeed(
      id: 'salud-percibida',
      topicId: 'salud',
      title: '¿Cómo calificarías tu salud?',
      kind: ChartKind.donut,
      labels: ['Buena o muy buena', 'Regular', 'Mala o muy mala'],
      amg: [58, 33, 9],
      tec: [66, 29, 5],
    ),
    ChartSeed(
      id: 'salud-tabaco',
      topicId: 'salud',
      title: '¿Fumaste o vapeaste en el último mes?',
      kind: ChartKind.bars,
      labels: ['Sí', 'No'],
      amg: [24, 76],
    ),
    ChartSeed(
      id: 'seguridad-colonia',
      topicId: 'seguridad',
      title: '¿Qué tan seguro te sientes de noche en tu colonia?',
      kind: ChartKind.donut,
      labels: ['Seguro', 'Ni seguro ni inseguro', 'Inseguro'],
      amg: [31, 27, 42],
      tec: [38, 30, 32],
    ),
    ChartSeed(
      id: 'seguridad-victimizacion',
      topicId: 'seguridad',
      title: '¿Fuiste víctima de algún delito en el último año?',
      kind: ChartKind.bars,
      labels: ['Sí', 'No'],
      amg: [27, 73],
    ),
    ChartSeed(
      id: 'comunidad-participacion',
      topicId: 'comunidad',
      title: '¿Participaste en actividades comunitarias el último año?',
      kind: ChartKind.donut,
      labels: ['Sí', 'No'],
      amg: [29, 71],
      tec: [46, 54],
    ),
    ChartSeed(
      id: 'comunidad-confianza',
      topicId: 'comunidad',
      title: '¿Cuánto confías en tus vecinos?',
      kind: ChartKind.bars,
      labels: ['Mucho', 'Algo', 'Poco', 'Nada'],
      amg: [12, 33, 36, 19],
    ),
    ChartSeed(
      id: 'transporte-medio',
      topicId: 'transporte',
      title: 'Medio de transporte principal',
      subtitle: 'Para ir a la escuela o al trabajo',
      kind: ChartKind.donut,
      labels: ['Transporte público', 'Automóvil', 'A pie', 'Bicicleta', 'Taxi o plataforma'],
      amg: [54, 22, 13, 4, 7],
      tec: [21, 58, 6, 3, 12],
    ),
    ChartSeed(
      id: 'transporte-tiempo',
      topicId: 'transporte',
      title: 'Tiempo de traslado, solo ida',
      kind: ChartKind.bars,
      labels: ['15 min o menos', '16 a 30 min', '31 a 60 min', 'Más de 1 hora'],
      amg: [17, 29, 33, 21],
    ),
  ];

  static ChartSeed? chartById(String id) {
    for (final chart in charts) {
      if (chart.id == id) return chart;
    }
    return null;
  }

  static List<ChartSeed> chartsOf(String topicId) =>
      charts.where((chart) => chart.topicId == topicId).toList();

  /// Hallazgos de Inicio: qué categorías se suman y con qué frase.
  static const highlightSeeds = <({String chartId, List<int> slices, String text, HighlightStyle style})>[
    (
      chartId: 'bienestar-satisfaccion',
      slices: [0, 1],
      text: 'de los jóvenes del AMG se siente satisfecho con su vida',
      style: HighlightStyle.gold,
    ),
    (
      chartId: 'transporte-medio',
      slices: [0],
      text: 'usa transporte público para ir a la escuela o al trabajo',
      style: HighlightStyle.navy,
    ),
    (
      chartId: 'salud-percibida',
      slices: [0],
      text: 'considera que su salud es buena o muy buena',
      style: HighlightStyle.lime,
    ),
  ];

  /// Registros que coinciden con los filtros. Simula que cada filtro
  /// reduce la muestra, para poder ver los avisos y el umbral.
  static int countFor(DataSource source, DataFilters filters) {
    var n = source == DataSource.amg ? amgSampleSize : tecSampleSize;
    if (filters.municipality != null) n ~/= 6;
    if (filters.ageGroup != null) n ~/= 3;
    if (filters.sex != null) n ~/= 2;
    if (filters.stratum != null) n ~/= 3;
    return n;
  }

  /// Mueve un poco los porcentajes según los filtros, de forma determinista,
  /// para que al filtrar se note el cambio. Si [normalize], suman 100.
  static List<double> perturb(
    List<double> base, {
    required String chartId,
    required DataSource source,
    required DataFilters filters,
    required bool normalize,
  }) {
    if (filters.isEmpty) return List<double>.of(base);
    final seed = Object.hash(chartId, source, filters);
    final random = Random(seed);
    final moved = [
      for (final value in base)
        max(0.5, value * (0.8 + random.nextDouble() * 0.4)),
    ];
    if (!normalize) return [for (final v in moved) min(100.0, v)];
    final total = moved.fold<double>(0, (sum, v) => sum + v);
    return [for (final v in moved) v * 100 / total];
  }
}
