import '../core/result.dart';
import '../models/models.dart';

/// Asistente de IA (Claude Haiku en la Edge Function jcv-asistente). Las
/// cifras salen de jcv.grafica, la misma función que usará el dashboard.
abstract interface class AssistantRepository {
  /// [history]: mensajes anteriores de la conversación, para entender
  /// seguimientos como "¿y en Zapopan?".
  Future<Result<AssistantAnswer>> ask(String question, {List<ChatMessage> history});
}

/// Voz a texto. El real usará speech_to_text con onDevice: true para que el
/// audio nunca salga del teléfono (RF-IA-02).
abstract interface class SpeechInput {
  /// Va entregando el texto reconocido hasta ahora. Termina con [stop].
  Stream<String> listen();

  Future<void> stop();
}
