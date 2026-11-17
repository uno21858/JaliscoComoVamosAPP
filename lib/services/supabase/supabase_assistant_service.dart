import 'dart:async';
import 'dart:math';

import 'package:supabase/supabase.dart';

import '../../core/app_error.dart';
import '../../core/error_sanitizer.dart';
import '../../core/result.dart';
import '../../models/models.dart';
import '../../repositories/assistant_repository.dart';
import '../local/local_store.dart';

/// Asistente real: llama a la Edge Function jcv-asistente (supabase/jcv-asistente).
/// La key de Anthropic vive allá; aquí solo va la anon key, que es pública.
class SupabaseAssistantService implements AssistantRepository {
  SupabaseAssistantService(this._client, this._store);

  final SupabaseClient _client;
  final LocalStore _store;
  String? _deviceId;

  static const _function = 'jcv-asistente';
  static const _deviceKey = 'jcv_dispositivo';
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
    final nAmg = data['n_amg'];
    final nTec = data['n_tec'];
    return AssistantFigure(
      caption: caption is String ? caption : '',
      amg: amg.toDouble(),
      tec: tec is num ? tec.toDouble() : null,
      nAmg: nAmg is num ? nAmg.toInt() : 0,
      nTec: nTec is num ? nTec.toInt() : 0,
    );
  }

  /// Id aleatorio del teléfono para el límite de 20 preguntas al día.
  /// No identifica a la persona; el servidor solo guarda su hash.
  Future<String> _device() async {
    final cached = _deviceId;
    if (cached != null) return cached;
    final stored = await _store.read(_deviceKey);
    if (stored != null && uuidPattern.hasMatch(stored)) return _deviceId = stored;
    final id = newDeviceId();
    await _store.write(_deviceKey, id); // si falla, dura lo que dure la sesión
    return _deviceId = id;
  }
}

final uuidPattern =
    RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

/// UUID v4 con Random.secure. ponytail: no vale un paquete por 6 líneas.
String newDeviceId([Random? random]) {
  final r = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // versión 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC 4122
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
