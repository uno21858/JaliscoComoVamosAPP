import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jcv_app/core/app_error.dart';
import 'package:jcv_app/services/local/device_id.dart';
import 'package:jcv_app/services/supabase/supabase_assistant_service.dart';

void main() {
  group('SupabaseAssistantService.parse', () {
    test('respuesta real de jcv-asistente (sin datos del Tec)', () {
      final answer = SupabaseAssistantService.parse({
        'texto': 'Entre los jóvenes de El Salto, el medio más usado es el camión (30%).',
        'tema': 'transporte',
        'figura': {
          'etiqueta': 'Camión/Macrobús (El Salto)',
          'amg': 29.7,
          'tec': null,
          'n_amg': 23,
          'n_tec': 0,
          'muestra_pequena': true,
        },
      });
      expect(answer.text, startsWith('Entre los jóvenes'));
      expect(answer.topicId, 'transporte');
      expect(answer.figure!.caption, 'Camión/Macrobús (El Salto)');
      expect(answer.figure!.amg, 29.7);
      expect(answer.figure!.tec, isNull);
      expect(answer.figure!.nAmg, 23);
    });

    test('amg entero, tema desconocido y figura nula', () {
      final conFigura = SupabaseAssistantService.parse({
        'texto': 'x',
        'tema': 'no-existe',
        'figura': {'etiqueta': 'Sí', 'amg': 27, 'tec': 31, 'n_amg': 1207, 'n_tec': 40},
      });
      expect(conFigura.topicId, isNull); // no rompe "Ver en Datos"
      expect(conFigura.figure!.amg, 27.0);
      expect(conFigura.figure!.tec, 31.0);

      final sinFigura = SupabaseAssistantService.parse({'texto': 'Hola', 'tema': null, 'figura': null});
      expect(sinFigura.figure, isNull);
      expect(sinFigura.topicId, isNull);
    });

    test('respuesta rota es ServerError, no crash', () {
      expect(() => SupabaseAssistantService.parse(null), throwsA(isA<ServerError>()));
      expect(() => SupabaseAssistantService.parse({'texto': ''}), throwsA(isA<ServerError>()));
      expect(() => SupabaseAssistantService.parse('<html>'), throwsA(isA<ServerError>()));
    });
  });

  test('newDeviceId genera UUID v4 válidos y distintos', () {
    final ids = List.generate(200, (_) => newDeviceId());
    expect(ids.every(uuidPattern.hasMatch), isTrue);
    expect(ids.toSet().length, 200);
    final fijo = newDeviceId(Random(1));
    expect(fijo[14], '4'); // versión
    expect('89ab'.contains(fijo[19]), isTrue); // variante
  });
}
