import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jcv_app/core/result.dart';
import 'package:jcv_app/models/models.dart';
import 'package:jcv_app/providers/assistant_controller.dart';
import 'package:jcv_app/repositories/assistant_repository.dart';
import 'package:jcv_app/services/local/report_pdf.dart';

/// Teléfono sin permiso de micrófono: el stream truena de inmediato.
class _NoMic implements SpeechInput {
  @override
  Stream<String> listen() => Stream.error(StateError('sin permiso de micrófono'));

  @override
  Future<void> stop() async {}
}

class _NoAssistant implements AssistantRepository {
  @override
  Future<Result<AssistantAnswer>> ask(String question, {List<ChatMessage> history = const []}) =>
      throw UnimplementedError();
}

const chart = TopicChart(
  id: 'bienestar-vida',
  topicId: 'bienestar',
  title: '¿Qué tan satisfecha(o) estás con tu vida?',
  subtitle: 'AMG 2026',
  kind: ChartKind.donut,
  slices: [ChartSlice('Muy satisfecha(o)', 54.8), ChartSlice('Algo satisfecha(o)', 36.4)],
  summary: 'Más de la mitad está muy satisfecha con su vida.',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('informe: PDF con fuente Montserrat, una temática con datos y otra sin', () async {
    const request = ReportRequest(
      topicIds: ['bienestar', 'seguridad'],
      source: DataSource.amg,
      filters: DataFilters(ageGroup: '20-24'),
      plainSummaries: true,
    );
    final pdf = await buildReportPdf(request, [
      (topicId: 'bienestar', data: const TopicCharts(charts: [chart])),
      (topicId: 'seguridad', data: null),
    ], now: DateTime(2026, 11, 17));
    expect(ascii.decode(pdf.sublist(0, 5)), '%PDF-');
    expect(latin1.decode(pdf), contains('Montserrat'), reason: 'fuente incrustada');
    final out = Platform.environment['JCV_PDF'];
    if (out != null) File(out).writeAsBytesSync(pdf); // para revisarlo a mano
  });

  test('voz: sin permiso de micrófono avisa en el chat y deja de escuchar', () async {
    final controller = AssistantController(_NoAssistant(), _NoMic());
    controller.startListening();
    await pumpEventQueue();
    expect(controller.listening, isFalse);
    expect(controller.messages.single.text, contains('No pude usar el micrófono'));
  });
}
