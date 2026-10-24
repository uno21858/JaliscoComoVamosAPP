/// Temática de la encuesta (Bienestar subjetivo, Salud, Transporte...).
class Topic {
  const Topic({required this.id, required this.name, required this.shortName});

  final String id;
  final String name;

  /// Nombre corto para chips del asistente ("Educación", "Bienestar").
  final String shortName;
}

/// Las 8 temáticas de la Encuesta de Bienestar de Jóvenes AMG 2026. Son
/// estructura del producto (el wireflow las fija), no datos de la encuesta.
abstract final class Topics {
  static const all = <Topic>[
    Topic(id: 'bienestar', name: 'Bienestar subjetivo', shortName: 'Bienestar'),
    Topic(id: 'educacion-trabajo', name: 'Educación y trabajo', shortName: 'Educación'),
    Topic(id: 'tiempo-libre', name: 'Tiempo libre', shortName: 'Tiempo libre'),
    Topic(id: 'hogar-familia', name: 'Hogar y familia', shortName: 'Hogar'),
    Topic(id: 'salud', name: 'Salud', shortName: 'Salud'),
    Topic(id: 'seguridad', name: 'Seguridad', shortName: 'Seguridad'),
    Topic(id: 'comunidad', name: 'Comunidad', shortName: 'Comunidad'),
    Topic(id: 'transporte', name: 'Transporte', shortName: 'Transporte'),
  ];

  static Topic? byId(String id) {
    for (final topic in all) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  /// Nombre para mostrar aunque el id venga mal (por ejemplo, un enlace viejo).
  static String nameOf(String id) => byId(id)?.name ?? 'Temática';
}

/// Ficha de la muestra que se muestra en 2.1 y en los pies de gráfica.
class SampleInfo {
  const SampleInfo({
    required this.total,
    required this.minAge,
    required this.maxAge,
    required this.edition,
  });

  final int total;
  final int minAge;
  final int maxAge;
  final String edition; // "AMG 2026"
}
