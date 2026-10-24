/// Avance guardado en el teléfono (cifrado) para retomar una encuesta.
class SurveyDraft {
  const SurveyDraft({
    required this.surveyId,
    required this.version,
    required this.currentIndex,
    required this.answers,
    required this.updatedAt,
  });

  final String surveyId;
  final int version;

  /// Pregunta donde se quedó, empezando en 0.
  final int currentIndex;

  /// Respuestas por id de pregunta: int, String o List<String>.
  final Map<String, Object> answers;
  final DateTime updatedAt;

  Map<String, Object> toJson() => {
        'surveyId': surveyId,
        'version': version,
        'currentIndex': currentIndex,
        'answers': answers,
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Devuelve null si el JSON viene corrupto o de otra versión del formato.
  static SurveyDraft? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final surveyId = json['surveyId'];
    final version = json['version'];
    final currentIndex = json['currentIndex'];
    final rawAnswers = json['answers'];
    final updatedAt = DateTime.tryParse('${json['updatedAt']}');
    if (surveyId is! String ||
        version is! int ||
        currentIndex is! int ||
        rawAnswers is! Map<String, Object?> ||
        updatedAt == null) {
      return null;
    }

    final answers = <String, Object>{};
    for (final entry in rawAnswers.entries) {
      final value = entry.value;
      if (value is int || value is String) {
        answers[entry.key] = value!;
      } else if (value is List<Object?>) {
        answers[entry.key] = value.whereType<String>().toList();
      }
    }

    return SurveyDraft(
      surveyId: surveyId,
      version: version,
      currentIndex: currentIndex,
      answers: answers,
      updatedAt: updatedAt,
    );
  }
}
