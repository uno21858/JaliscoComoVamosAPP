import 'dart:async';

import '../../repositories/assistant_repository.dart';

/// Simula el dictado: va "escuchando" una frase de ejemplo palabra por palabra.
class MockSpeechInput implements SpeechInput {
  static const _phrase = '¿Los del Tec trabajan más o menos que en el AMG?';

  StreamController<String>? _controller;
  Timer? _timer;

  @override
  Stream<String> listen() {
    _cleanup();
    final words = _phrase.split(' ');
    var count = 0;
    final controller = StreamController<String>();
    _controller = controller;
    _timer = Timer.periodic(const Duration(milliseconds: 280), (timer) {
      if (count >= words.length) {
        timer.cancel();
        return;
      }
      count++;
      controller.add(words.take(count).join(' '));
    });
    return controller.stream;
  }

  @override
  Future<void> stop() async => _cleanup();

  void _cleanup() {
    _timer?.cancel();
    _timer = null;
    final controller = _controller;
    _controller = null;
    if (controller != null && !controller.isClosed) {
      unawaited(controller.close());
    }
  }
}
