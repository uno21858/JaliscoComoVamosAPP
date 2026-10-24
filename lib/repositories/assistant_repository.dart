import '../core/result.dart';
import '../models/models.dart';

/// Asistente de IA. Gemini solo interpreta la pregunta en el servidor;
/// las cifras salen de las mismas funciones del dashboard (RF-IA-04/05).
abstract interface class AssistantRepository {
  Future<Result<AssistantAnswer>> ask(String question);
}

/// Voz a texto. El real usará speech_to_text con onDevice: true para que el
/// audio nunca salga del teléfono (RF-IA-02).
abstract interface class SpeechInput {
  /// Va entregando el texto reconocido hasta ahora. Termina con [stop].
  Stream<String> listen();

  Future<void> stop();
}
