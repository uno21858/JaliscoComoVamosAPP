import 'dart:async';
import 'dart:math';

import 'package:supabase/supabase.dart';

import '../../core/app_error.dart';
import '../../core/error_sanitizer.dart';
import '../../core/result.dart';
import '../../models/models.dart';
import '../../repositories/assistant_repository.dart';
import '../local/device_id.dart';
import '../local/local_store.dart';

/// Asistente real: llama a la Edge Function jcv-asistente (supabase/jcv-asistente).
/// La key de Anthropic vive allá; aquí solo va la anon key, que es pública.
class SupabaseAssistantService implements AssistantRepository {
  SupabaseAssistantService(this._client, this._store);

  final SupabaseClient _client;
  final LocalStore _store;
  String? _deviceId;

  static const _function = 'jcv-asistente';
  static const _maxHistory = 6;
  static const _timeout = Duration(seconds: 30);

  @override
  Future<Result<AssistantAnswer>> ask(String question, {List<ChatMessage> history = const []}) =>
      guardResult(() async {
        final recent = history.skip(max(0, history.length - _maxHistory));
        final FunctionResponse response;
        try {
          response = await _client.functions.invoke(
            _function,
            headers: {'x-jcv-dispositivo': await _device()},
            body: {
              'pregunta': question,
              'historial': [
                for (final m in recent)
                  {'rol': m.author == MessageAuthor.user ? 'usuario' : 'asistente', 'texto': m.text},
              ],
            },
          ).timeout(_timeout);
        } on TimeoutException {
          throw const NetworkError('jcv-asistente tardó más de 30 s');
        } on FunctionsFetchException catch (e) {
          throw NetworkError('$e');
        } on FunctionException catch (e) {
          // 400, 429 y 503 traen un mensaje ya escrito para personas
          // ("Ya hiciste tus 20 preguntas de hoy..."). Lo demás es genérico.
          final details = e.details;
          final message = details is Map ? details['error'] : null;
          if (message is String && message.isNotEmpty) throw ValidationError(message);
          throw ServerError('$_function ${e.status}');
        }
        return parse(response.data);
      });

  /// Convierte `{ texto, tema, figura }` de la Edge Function. Público para las pruebas.
  static AssistantAnswer parse(Object? data) {
    if (data is! Map) throw const ServerError('respuesta sin formato');
    final text = data['texto'];
    if (text is! String || text.trim().isEmpty) throw const ServerError('respuesta sin texto');
    final topic = data['tema'];
    return AssistantAnswer(
      text: text,
      topicId: topic is String && Topics.byId(topic) != null ? topic : null,
      figure: _figure(data['figura']),
    );
  }

  static AssistantFigure? _figure(Object? data) {
    if (data is! Map) return null;
    final amg = data['amg'];
    if (amg is! num) return null;
    final tec = data['tec'];
    final caption = data['etiqueta'];
    return AssistantFigure(
      caption: caption is String ? caption : '',
      amg: amg.toDouble(),
      tec: tec is num ? tec.toDouble() : null,
    );
  }

  Future<String> _device() async => _deviceId ??= await deviceId(_store);
}
