import '../core/result.dart';
import '../models/models.dart';

/// Micro-encuestas para estudiantes Tec.
abstract interface class SurveyRepository {
  Future<Result<List<SurveySummary>>> getSurveys();

  Future<Result<Survey>> getSurvey(String surveyId);

  /// Envía las respuestas. El servidor guarda la marca de "completó" y la
  /// respuesta por separado, sin ligarlas (RF-ENC-09). Si ya se había
  /// completado, regresa Err con FailureType.conflict.
  Future<Result<void>> submit({
    required String surveyId,
    required int version,
    required Map<String, Object> answers,
  });

  /// Versión del aviso de privacidad vigente.
  String get privacyNoticeVersion;

  Future<bool> hasAcceptedPrivacy();

  Future<Result<void>> acceptPrivacy();
}
