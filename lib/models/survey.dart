enum QuestionType {
  /// Rueda de edad (3.7).
  age,

  /// Una opción de una lista (3.8).
  single,

  /// Escala numérica, por ejemplo 0 a 10 (3.10).
  scale,

  /// Varias opciones, con máximo y opción exclusiva opcionales.
  multiple,
}

class QuestionOption {
  const QuestionOption(this.code, this.label);
  final String code;
  final String label;
}

/// Pregunta de la encuesta. [id] es el código de la variable AMG, para que
/// la respuesta Tec se pueda comparar con la misma columna.
class Question {
  const Question({
    required this.id,
    required this.text,
    required this.type,
    this.helper,
    this.helperIsPrivacyNote = false,
    this.required = true,
    this.options = const [],
    this.min = 0,
    this.max = 10,
    this.initialValue,
    this.minLabel,
    this.maxLabel,
    this.maxSelections,
    this.exclusiveCode,
  });

  final String id;
  final String text;
  final QuestionType type;

  /// Texto chico bajo la pregunta ("Elige una opción.").
  final String? helper;

  /// true: el helper va con ícono de información (como en 3.7).
  final bool helperIsPrivacyNote;

  final bool required;
  final List<QuestionOption> options;

  /// Rango para [QuestionType.age] y [QuestionType.scale].
  final int min;
  final int max;

  /// Valor donde arranca la rueda de edad.
  final int? initialValue;

  /// Etiquetas de los extremos de la escala ("Nada satisfecho").
  final String? minLabel;
  final String? maxLabel;

  /// Para [QuestionType.multiple].
  final int? maxSelections;
  final String? exclusiveCode;

  /// Revisa que una respuesta tenga el tipo y el rango correctos.
  bool isValidAnswer(Object? value) {
    switch (type) {
      case QuestionType.age:
      case QuestionType.scale:
        return value is int && value >= min && value <= max;
      case QuestionType.single:
        return value is String && options.any((o) => o.code == value);
      case QuestionType.multiple:
        if (value is! List<String> || value.isEmpty) return false;
        final limit = maxSelections;
        if (limit != null && value.length > limit) return false;
        return value.every((code) => options.any((o) => o.code == code));
    }
  }
}

class Survey {
  const Survey({
    required this.id,
    required this.version,
    required this.title,
    required this.topicId,
    required this.estimatedMinutes,
    required this.sourceLabel,
    required this.questions,
  });

  final String id;
  final int version;
  final String title;

  /// Temática con la que se compara en Datos al terminar.
  final String topicId;
  final int estimatedMinutes;

  /// "Encuesta AMG 2026"
  final String sourceLabel;
  final List<Question> questions;
}

/// Lo que necesita la lista de encuestas (3.4) sin bajar todas las preguntas.
class SurveySummary {
  const SurveySummary({
    required this.id,
    required this.title,
    required this.topicId,
    required this.questionCount,
    required this.estimatedMinutes,
    required this.sourceLabel,
    required this.completed,
  });

  final String id;
  final String title;
  final String topicId;
  final int questionCount;
  final int estimatedMinutes;
  final String sourceLabel;

  /// El servidor guarda la marca de "completó", nunca las respuestas ligadas.
  final bool completed;
}
