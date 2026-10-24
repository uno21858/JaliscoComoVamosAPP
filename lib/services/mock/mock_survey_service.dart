import 'dart:convert';

import '../../core/app_error.dart';
import '../../core/error_sanitizer.dart';
import '../../core/result.dart';
import '../../models/survey.dart';
import '../../repositories/survey_repository.dart';
import '../local/local_store.dart';
import 'mock_network.dart';
import 'mock_surveys.dart';

/// Implementación de [SurveyRepository] sin backend.
///
/// Las marcas de "completó" y el consentimiento se guardan en el teléfono
/// solo para que el mock se comporte igual entre reinicios. En el backend
/// real viven en el servidor (survey_completions y consents).
class MockSurveyService implements SurveyRepository {
  MockSurveyService(this._store);

  final LocalStore _store;

  static const _completedKey = 'mock.completed_surveys';
  static const _privacyKey = 'mock.privacy_accepted_version';

  /// La encuesta de Transporte arranca como completada para ver ese estado.
  static const _seedCompleted = {'transporte-2026'};

  @override
  String get privacyNoticeVersion => '2026-10-v1';

  Future<Set<String>> _completed() async {
    final raw = await _store.read(_completedKey);
    if (raw == null) return {..._seedCompleted};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List<Object?>) return decoded.whereType<String>().toSet();
    } on FormatException {
      // Si está corrupto, se vuelve al estado inicial.
    }
    return {..._seedCompleted};
  }

  @override
  Future<Result<List<SurveySummary>>> getSurveys() => guardResult(() async {
        await simulateNetwork();
        final completed = await _completed();
        return [
          for (final survey in MockSurveys.all)
            SurveySummary(
              id: survey.id,
              title: survey.title,
              topicId: survey.topicId,
              questionCount: survey.questions.length,
              estimatedMinutes: survey.estimatedMinutes,
              sourceLabel: survey.sourceLabel,
              completed: completed.contains(survey.id),
            ),
        ];
      });

  @override
  Future<Result<Survey>> getSurvey(String surveyId) => guardResult(() async {
        await simulateNetwork();
        final survey = MockSurveys.byId(surveyId);
        if (survey == null) throw const ValidationError('Esta encuesta ya no está disponible.');
        return survey;
      });

  @override
  Future<Result<void>> submit({
    required String surveyId,
    required int version,
    required Map<String, Object> answers,
  }) =>
      guardResult(() async {
        await simulateNetwork();
        final survey = MockSurveys.byId(surveyId);
        if (survey == null || survey.version != version) {
          throw const ValidationError('La encuesta cambió. Vuelve a abrirla.');
        }
        final completed = await _completed();
        if (completed.contains(surveyId)) {
          throw const ConflictError('Ya respondiste esta encuesta. ¡Gracias!');
        }
        // El servidor real valida cada respuesta contra la definición
        // (RF-ENC-13). El mock hace lo mismo para atrapar bugs de la app.
        for (final question in survey.questions) {
          final value = answers[question.id];
          if (value == null) {
            if (question.required) {
              throw ValidationError('Falta responder: ${question.text}');
            }
            continue;
          }
          if (!question.isValidAnswer(value)) {
            throw ValidationError('Respuesta no válida en: ${question.text}');
          }
        }
        completed.add(surveyId);
        await _store.write(_completedKey, jsonEncode(completed.toList()));
      });

  @override
  Future<bool> hasAcceptedPrivacy() async =>
      await _store.read(_privacyKey) == privacyNoticeVersion;

  @override
  Future<Result<void>> acceptPrivacy() => guardResult(() async {
        await simulateNetwork();
        await _store.write(_privacyKey, privacyNoticeVersion);
      });
}
