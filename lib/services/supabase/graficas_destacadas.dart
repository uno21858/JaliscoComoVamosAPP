import '../../models/chart.dart';

/// Una gráfica de la pestaña Datos, armada con preguntas reales de la encuesta
/// AMG 2026 (las variables de jcv.preguntas).
///
/// - Una variable: la pregunta con todas sus respuestas.
/// - Varias variables (grupo): una barra por variable con el porcentaje de las
///   respuestas en [codes] ("Sí" = [1]; "algo o mucho" = [4, 5]).
class ChartDef {
  const ChartDef(this.id, this.topicId, this.title, this.variables, {this.subtitle})
      : codes = const [],
        labels = const [];

  const ChartDef.group(
    this.id,
    this.topicId,
    this.title,
    this.variables, {
    required this.codes,
    required this.labels,
    required this.subtitle,
  }) : assert(variables.length == labels.length);

  final String id;
  final String topicId;
  final String title;
  final String? subtitle;
  final List<String> variables;
  final List<int> codes;
  final List<String> labels;

  bool get isGroup => variables.length > 1;
}

/// "T_Q_65_" + 3 -> T_Q_65_1, T_Q_65_2, T_Q_65_3.
List<String> _items(String prefix, int count) => [for (var i = 1; i <= count; i++) '$prefix$i'];

const _si = [1];
const _algoOMucho = [4, 5];

/// Lo que se muestra en Datos, en orden, por temática. Para cambiar una
/// gráfica basta editar su línea; el chat sigue contestando sobre las 172.
final graficasDestacadas = <ChartDef>[
  // Bienestar
  const ChartDef('bienestar-vida', 'bienestar', 'Satisfacción con su vida', ['Q_6']),
  const ChartDef('bienestar-felicidad', 'bienestar', '¿Qué tan felices son?', ['Q_8']),
  ChartDef.group('bienestar-emociones', 'bienestar', 'Cómo se sienten seguido', _items('T_Q_11_', 6),
      codes: _algoOMucho,
      labels: const ['Contentos', 'Tranquilos', 'Angustiados', 'Tristes', 'Enojados', 'Problemas para dormir'],
      subtitle: '% que lo siente muchas veces o siempre'),
  const ChartDef('bienestar-afectiva', 'bienestar', 'Satisfacción con su vida afectiva', ['Q_10']),

  // Educación y trabajo
  ChartDef.group('educacion-actividades', 'educacion-trabajo', 'Qué hacen día a día', _items('T_Q_13_', 5),
      codes: _si,
      labels: const [
        'Estudia',
        'Trabaja tiempo completo',
        'Trabaja medio tiempo',
        'Trabajo del hogar sin pago',
        'Cuida a alguien en casa',
      ],
      subtitle: '% que lo hace a diario o de forma regular'),
  const ChartDef('educacion-escolaridad', 'educacion-trabajo', 'Nivel de escolaridad', ['Q_74recode']),
  const ChartDef('educacion-universidad', 'educacion-trabajo', 'Importancia de la universidad hoy', ['Q_17']),
  const ChartDef('educacion-satisfaccion', 'educacion-trabajo', 'Satisfacción con sus actividades diarias', ['Q_14']),

  // Tiempo libre
  const ChartDef('tiempo-satisfaccion', 'tiempo-libre', 'Satisfacción con su tiempo libre', ['Q_20']),
  ChartDef.group('tiempo-actividades', 'tiempo-libre', 'Qué hicieron en los últimos 3 meses', _items('T_Q_23_', 7),
      codes: _algoOMucho,
      labels: const ['Cine', 'Leer', 'Deporte', 'Arte', 'Amigos o familia', 'Videojuegos', 'Streaming'],
      subtitle: '% con cierta o mucha frecuencia'),
  const ChartDef('tiempo-ia', 'tiempo-libre', 'Uso de chatbots de IA', ['Q_25']),
  ChartDef.group('tiempo-mundial', 'tiempo-libre', 'Cómo vivieron el Mundial', _items('Q_29_', 9),
      codes: _si,
      labels: const [
        'Estadio',
        'Fan Fest Guadalajara',
        'Fan Fest Zapopan',
        'Restaurante',
        'Con familia o amigos',
        'La Minerva',
        'TV o radio en casa',
        'Otra',
        'No lo siguió',
      ],
      subtitle: '% que lo hizo'),

  // Hogar y familia
  const ChartDef('hogar-familia', 'hogar-familia', 'Satisfacción con su vida familiar', ['Q_31']),
  const ChartDef('hogar-ingreso', 'hogar-familia', '¿Les alcanza el ingreso?', ['Q_32']),
  const ChartDef('hogar-problema', 'hogar-familia', 'Principal problema en la familia', ['Q_30']),
  const ChartDef('hogar-convivencia', 'hogar-familia', 'Con quién viven', ['Q_34']),
  const ChartDef('hogar-vivienda', 'hogar-familia', '¿Se ven con casa propia?', ['Q_35']),

  // Salud
  const ChartDef('salud-satisfaccion', 'salud', 'Satisfacción con su salud', ['Q_36']),
  const ChartDef('salud-mental', 'salud', 'Cómo califican su salud mental', ['Q_41']),
  const ChartDef('salud-ejercicio', 'salud', 'Días de ejercicio a la semana', ['Q_39']),
  const ChartDef('salud-alcohol', 'salud', 'Días que toman alcohol a la semana', ['Q_38']),
  const ChartDef('salud-drogas', 'salud', 'Qué tan fácil es conseguir drogas', ['Q_37']),

  // Seguridad
  ChartDef.group('seguridad-percepcion', 'seguridad', 'Se sienten seguros viviendo en…', _items('T_Q_43_', 2),
      codes: _algoOMucho, labels: const ['Su ciudad', 'Su colonia'], subtitle: '% algo o muy seguro'),
  const ChartDef('seguridad-amenaza', 'seguridad', 'Se sienten amenazados por la violencia en su colonia', ['Q_45']),
  const ChartDef('seguridad-victimas', 'seguridad', 'Víctimas de un delito', ['Q_46'], subtitle: 'Últimos 12 meses'),
  ChartDef.group('seguridad-colonia', 'seguridad', 'Problemas graves en su colonia', _items('T_Q_44_', 4),
      codes: _algoOMucho,
      labels: const ['Asaltos y robos', 'Drogas', 'Pleitos y violencia', 'Detenciones arbitrarias'],
      subtitle: '% algo o muy grave'),
  const ChartDef('seguridad-crimen', 'seguridad', 'Presencia del crimen organizado', ['Q_49']),

  // Comunidad
  ChartDef.group('comunidad-confianza', 'comunidad', 'Confianza en instituciones', _items('T_Q_65_', 15),
      codes: _algoOMucho,
      labels: const [
        'Iglesias',
        'Congreso local',
        'IEPC Jalisco',
        'INE',
        'Partidos políticos',
        'Gobierno municipal',
        'Gobierno estatal',
        'Gobierno federal',
        'Medios',
        'Ejército',
        'Ministerios públicos',
        'Policía',
        'Marina',
        'Jueces',
        'Empresarios',
      ],
      subtitle: '% algo o mucha confianza'),
  ChartDef.group('comunidad-discriminacion', 'comunidad', 'Discriminación en el último año', _items('T_Q_63_', 11),
      codes: _si,
      labels: const [
        'Apariencia física',
        'Género',
        'Nivel económico',
        'Creencias',
        'Posición política',
        'Orientación sexual',
        'Estado civil',
        'Edad',
        'Discapacidad',
        'Origen étnico',
        'Color de piel',
      ],
      subtitle: '% que la vivió, por motivo'),
  ChartDef.group('comunidad-participacion', 'comunidad', 'Participación en el último año', _items('T_Q_60_', 7),
      codes: _si,
      labels: const [
        'Votar',
        'Firmar peticiones',
        'Protestar',
        'Compartir en redes',
        'Partido u organización política',
        'Colectivos ciudadanos',
        'Causas globales',
      ],
      subtitle: '% que participó'),
  const ChartDef('comunidad-politica', 'comunidad', 'Interés en la política', ['Q_66']),
  const ChartDef('comunidad-democracia', 'comunidad', 'Opinión sobre la democracia', ['Q_67']),
  const ChartDef('comunidad-redes', 'comunidad', 'Red social para informarse de política', ['Q_68']),

  // Transporte
  const ChartDef('transporte-medio', 'transporte', 'Medio de transporte principal', ['Q_69']),
  const ChartDef('transporte-tiempo', 'transporte', 'Tiempo diario de traslado', ['Q_70recode']),
];

/// "Hallazgos destacados" de Inicio: suma de las respuestas [codes] de una pregunta.
class HighlightDef {
  const HighlightDef(this.chartId, this.variable, this.codes, this.text, this.style);
  final String chartId;
  final String variable;
  final List<int> codes;
  final String text;
  final HighlightStyle style;
}

const hallazgosInicio = [
  HighlightDef('bienestar-vida', 'Q_6', [4, 5], 'de los jóvenes del AMG está satisfecho con su vida', HighlightStyle.gold),
  HighlightDef('transporte-medio', 'Q_69', [1, 6], 'se mueve en camión, Macrobús o tren ligero', HighlightStyle.navy),
  HighlightDef('salud-mental', 'Q_41', [4, 5], 'dice que su salud mental es buena o muy buena', HighlightStyle.lime),
];
