import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

import '../../repositories/assistant_repository.dart';

/// Dictado con el reconocedor del teléfono. onDevice: el audio nunca sale del
/// teléfono (RF-IA-02). Si no hay permiso o el teléfono no reconoce español
/// sin internet, el stream termina con error y el asistente lo avisa.
class DeviceSpeechInput implements SpeechInput {
  final _speech = SpeechToText();
  StreamController<String>? _controller;

  /// Silencio o nada entendido: no es falla, solo termina.
  static const _sinVoz = {'error_no_match', 'error_speech_timeout'};

  @override
  Stream<String> listen() {
    _close();
    final controller = StreamController<String>();
    _controller = controller;
    unawaited(_start(controller));
    return controller.stream;
  }

  Future<void> _start(StreamController<String> controller) async {
    try {
      // initialize solo registra onError la primera vez: por eso usa _controller.
      final ready = await _speech.initialize(
        onError: (e) => _sinVoz.contains(e.errorMsg) ? _close() : _fail(e.errorMsg),
      );
      if (controller.isClosed) return;
      if (!ready) return _fail('sin permiso de micrófono');
      await _speech.listen(
        onResult: (r) {
          if (!controller.isClosed) controller.add(r.recognizedWords);
        },
        listenOptions: SpeechListenOptions(
          onDevice: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          localeId: 'es_MX',
        ),
      );
    } on Object catch (e) {
      _fail('$e');
    }
  }

  @override
  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
    _close();
  }

  void _fail(String reason) {
    final controller = _controller;
    if (controller != null && !controller.isClosed) controller.addError(StateError(reason));
    _close();
  }

  void _close() {
    final controller = _controller;
    _controller = null;
    if (controller != null && !controller.isClosed) unawaited(controller.close());
  }
}
