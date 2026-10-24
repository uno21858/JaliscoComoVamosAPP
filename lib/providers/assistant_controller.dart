import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../models/assistant.dart';
import '../repositories/assistant_repository.dart';

/// Conversación con el asistente (5.1 a 5.3). No se guarda en el teléfono.
class AssistantController extends ChangeNotifier {
  AssistantController(this._repository, this._speech);

  final AssistantRepository _repository;
  final SpeechInput _speech;

  final List<ChatMessage> _messages = [];
  bool _thinking = false;
  bool _listening = false;
  String _transcript = '';
  StreamSubscription<String>? _speechSub;
  bool _disposed = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get thinking => _thinking;
  bool get listening => _listening;
  String get transcript => _transcript;
  bool get isEmpty => _messages.isEmpty;

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _thinking) return;
    _messages.add(ChatMessage.user(text));
    _thinking = true;
    notifyListeners();

    final result = await _repository.ask(text);
    if (_disposed) return;
    _thinking = false;
    switch (result) {
      case Ok(:final value):
        _messages.add(ChatMessage.assistant(value));
      case Err(:final failure):
        _messages.add(ChatMessage.assistant(AssistantAnswer(text: failure.message)));
    }
    notifyListeners();
  }

  void startListening() {
    if (_listening) return;
    _listening = true;
    _transcript = '';
    notifyListeners();
    _speechSub = _speech.listen().listen((partial) {
      _transcript = partial;
      notifyListeners();
    });
  }

  /// Cierra el micrófono sin enviar.
  Future<void> cancelListening() async {
    await _stopSpeech();
    _transcript = '';
    notifyListeners();
  }

  /// "Toca para terminar": cierra el micrófono y envía lo que se entendió.
  Future<void> finishListening() async {
    final text = _transcript;
    await _stopSpeech();
    _transcript = '';
    notifyListeners();
    if (text.trim().isNotEmpty) await send(text);
  }

  Future<void> _stopSpeech() async {
    _listening = false;
    await _speechSub?.cancel();
    _speechSub = null;
    await _speech.stop();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_speechSub?.cancel());
    unawaited(_speech.stop());
    super.dispose();
  }
}
