import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcv_app/core/result.dart';
import 'package:jcv_app/flavors/flavor_config.dart';
import 'package:jcv_app/models/models.dart';
import 'package:jcv_app/providers/providers.dart';
import 'package:jcv_app/repositories/repositories.dart';
import 'package:jcv_app/screens/assistant/assistant_screen.dart';
import 'package:provider/provider.dart';

/// Responde cuando la prueba lo indica, con un texto largo que no cabe.
class _SlowAssistant implements AssistantRepository {
  Completer<void> gate = Completer<void>();

  @override
  Future<Result<AssistantAnswer>> ask(String question, {List<ChatMessage> history = const []}) async {
    await gate.future;
    return Ok(AssistantAnswer(text: List.filled(12, 'Respuesta larga del asistente.').join(' ')));
  }
}

class _NoSpeech implements SpeechInput {
  @override
  Stream<String> listen() => const Stream.empty();

  @override
  Future<void> stop() async {}
}

void main() {
  setUp(() => FlavorConfig.init(
        const FlavorConfig(flavor: Flavor.dev, useMocks: true, showMockBanner: false),
      ));

  testWidgets('al llegar cada respuesta la lista baja hasta el final', (tester) async {
    tester.view.physicalSize = const Size(430, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final assistant = _SlowAssistant();
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<AssistantRepository>.value(value: assistant),
        Provider<SpeechInput>.value(value: _NoSpeech()),
        ChangeNotifierProvider(create: (_) => DataFiltersProvider()),
      ],
      child: const MaterialApp(home: AssistantScreen()),
    ));

    for (var i = 0; i < 3; i++) {
      assistant.gate = Completer<void>();
      await tester.enterText(find.byType(TextField), 'Pregunta $i');
      await tester.pump(); // habilita el botón de enviar
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pump(); // pregunta + "pensando" (animación infinita: no pumpAndSettle)
      await tester.pump(const Duration(milliseconds: 600));
      assistant.gate.complete();
      // Llega la respuesta: reemplaza al globo de "pensando", así que el número
      // de elementos no cambia. Ya sin animación infinita, se puede asentar.
      await tester.pumpAndSettle();

      final position = tester.state<ScrollableState>(find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first).position;
      expect(position.pixels, position.maxScrollExtent, reason: 'respuesta $i fuera de pantalla');
    }
    expect(find.textContaining('Respuesta larga'), findsWidgets);
    expect(find.text('Pregunta 2'), findsOneWidget);
  });
}
