import 'dart:async';
import 'dart:convert';

import 'package:supabase/supabase.dart';

import '../../core/app_error.dart';
import '../../core/error_sanitizer.dart';
import '../../core/result.dart';
import '../../models/models.dart';
import '../../repositories/survey_repository.dart';
import '../local/device_id.dart';
import '../local/local_store.dart';
import 'graficas_destacadas.dart';
import 'supabase_data_service.dart';

typedef Demographics = ({int edad, String? sexo, String? municipio});

/// Encuestas del Tec: una por temática, con las mismas preguntas y opciones de
/// la encuesta AMG que salen en Datos (graficasDestacadas). Se guardan con
/// jcv.guardar_encuesta como fuente TEC, así la comparativa sale sola.
///
/// Edad, sexo y municipio se preguntan una vez y se guardan en el teléfono.
class SupabaseSurveyService implements SurveyRepository {
  SupabaseSurveyService(this._client, this._store);

  final SupabaseClient _client;
  final LocalStore _store;

  static const _completedKey = 'jcv_encuestas_hechas';
  static const _privacyKey = 'jcv_aviso_privacidad';
  static const _demographicsKey = 'jcv_demografia';
  static const _timeout = Duration(seconds: 15);
  static const _version = 1;
  static const _sourceLabel = 'Mismas preguntas que la encuesta AMG 2026';

  /// Código de "Ninguna" en las preguntas de opción múltiple.
  static const noneCode = 'NINGUNA';

  static String surveyIdOf(String topicId) => 'tec-$topicId';

  static String? _topicOf(String surveyId) => surveyId.startsWith('tec-') ? surveyId.substring(4) : null;

  static List<ChartDef> _defsOf(String? topicId) =>
      graficasDestacadas.where((d) => d.topicId == topicId).toList();

  @override
  String get privacyNoticeVersion => '2026-10-v1';

  @override
  Future<bool> hasAcceptedPrivacy() async => await _store.read(_privacyKey) == privacyNoticeVersion;

  @override
  Future<Result<void>> acceptPrivacy() =>
      guardResult(() => _store.write(_privacyKey, privacyNoticeVersion));

  @override
  Future<Result<List<SurveySummary>>> getSurveys() => guardResult(() async {
        final completed = await _completed();
        final extra = await _demographics() == null ? demographicQuestions.length : 0;
        return [
          for (final topic in Topics.all)
            if (_defsOf(topic.id) case final defs when defs.isNotEmpty)
              SurveySummary(
                id: surveyIdOf(topic.id),
                title: topic.name,
                topicId: topic.id,
                questionCount: countQuestions(defs) + extra,
                estimatedMinutes: _minutes(countQuestions(defs) + extra),
                sourceLabel: _sourceLabel,
                completed: completed.contains(surveyIdOf(topic.id)),
              ),
        ];
      });

  @override
  Future<Result<Survey>> getSurvey(String surveyId) => guardResult(() async {
        final topicId = _topicOf(surveyId);
        final defs = _defsOf(topicId);
        if (topicId == null || defs.isEmpty) throw const ValidationError('Esta encuesta ya no está disponible.');
        // Textos y opciones salen de la base (fuente AMG): iguales al cuestionario de JCV.
        final data = SupabaseDataService.byVariable(await _rpc('graficas', {
          'p_variables': [for (final d in defs) ...d.variables],
          'p_fuente': 'AMG',
        }));
        return buildSurvey(topicId, defs, data, askDemographics: await _demographics() == null);
      });

  @override
  Future<Result<void>> submit({
    required String surveyId,
    required int version,
    required Map<String, Object> answers,
  }) =>
      guardResult(() async {
        final defs = _defsOf(_topicOf(surveyId));
        if (defs.isEmpty || version != _version) throw const ValidationError('La encuesta cambió. Vuelve a abrirla.');
        final completed = await _completed();
        if (completed.contains(surveyId)) throw const ConflictError('Ya respondiste esta encuesta. ¡Gracias!');

        final nuevos = demographicsFrom(answers);
        final demo = nuevos ?? await _demographics();
        if (demo == null) throw const ValidationError('Falta contestar tus datos generales.');

        final result = await _rpc('guardar_encuesta', {
          'p_dispositivo': await deviceId(_store),
          'p_encuesta': surveyId,
          'p_edad': demo.edad,
          'p_sexo': demo.sexo,
          'p_municipio': demo.municipio,
          'p_respuestas': answersToCodes(defs, answers),
        });
        if (nuevos != null) {
          await _store.write(_demographicsKey,
              jsonEncode({'edad': nuevos.edad, 'sexo': nuevos.sexo, 'municipio': nuevos.municipio}));
        }
        await _store.write(_completedKey, jsonEncode([...completed, surveyId]));
        if (result == 'ya_contestada') throw const ConflictError('Ya respondiste esta encuesta. ¡Gracias!');
      });

  Future<Object?> _rpc(String function, Map<String, Object?> params) async {
    try {
      return await _client.schema('jcv').rpc<Object?>(function, params: params).timeout(_timeout);
    } on PostgrestException catch (e) {
      if (e.code == 'P0429') {
        throw const ValidationError('Se enviaron muchas encuestas desde esta red. Intenta en un rato.');
      }
      throw ServerError('jcv.$function ${e.code}');
    } on TimeoutException {
      throw NetworkError('jcv.$function tardó más de 15 s');
    } on Exception catch (e) {
      throw NetworkError('$e'); // ponytail: lo que no es de Postgres aquí es red
    }
  }

  Future<Set<String>> _completed() async {
    try {
      final raw = await _store.read(_completedKey);
      return raw == null ? {} : (jsonDecode(raw) as List<Object?>).whereType<String>().toSet();
    } on Object {
      return {}; // corrupto: el servidor igual responde "ya_contestada"
    }
  }

  Future<Demographics?> _demographics() async {
    try {
      final raw = await _store.read(_demographicsKey);
      if (raw == null) return null;
      if (jsonDecode(raw) case {'edad': final int edad, 'sexo': final String? sexo, 'municipio': final String? municipio}) {
        return (edad: edad, sexo: sexo, municipio: municipio);
      }
    } on Object {
      // corrupto: se vuelven a preguntar
    }
    return null;
  }

  // ---------- Armado de la encuesta (público para las pruebas) ----------

  static const demographicQuestions = [
    Question(
      id: 'EDAD',
      text: '¿Cuántos años tienes?',
      type: QuestionType.age,
      helper: 'Solo la preguntamos una vez y se usa para fines estadísticos.',
      helperIsPrivacyNote: true,
      min: 18,
      max: 29,
      initialValue: 20,
    ),
    Question(
      id: 'SEXO',
      text: '¿Cuál es tu sexo?',
      type: QuestionType.single,
      helper: 'Elige una opción.',
      options: [
        QuestionOption('F', 'Mujer'),
        QuestionOption('M', 'Hombre'),
        QuestionOption('X', 'Otro o no binario'),
        QuestionOption('NR', 'Prefiero no decir'),
      ],
    ),
    Question(
      id: 'MUNICIPIO',
      text: '¿En qué municipio vives?',
      type: QuestionType.single,
      helper: 'Elige una opción.',
      options: [
        QuestionOption('GDL', 'Guadalajara'),
        QuestionOption('ZAP', 'Zapopan'),
        QuestionOption('TLQ', 'San Pedro Tlaquepaque'),
        QuestionOption('TON', 'Tonalá'),
        QuestionOption('TLJ', 'Tlajomulco de Zúñiga'),
        QuestionOption('ELS', 'El Salto'),
        QuestionOption('OTRO', 'Otro municipio del AMG'),
        QuestionOption('FUERA', 'Fuera del AMG'),
      ],
    ),
  ];

  /// Grupo Sí/No: 1 pregunta. Grupo de escala: 1 por inciso. Sola: 1.
  static int countQuestions(List<ChartDef> defs) =>
      defs.fold(0, (n, d) => n + (d.isGroup && !d.isYesNoGroup ? d.variables.length : 1));

  static int _minutes(int questions) => (questions * 12 / 60).ceil().clamp(1, 60);

  static Survey buildSurvey(
    String topicId,
    List<ChartDef> defs,
    Map<String, GraficaJson> data, {
    required bool askDemographics,
  }) {
    final questions = [
      if (askDemographics) ...demographicQuestions,
      for (final def in defs) ..._questionsFor(def, data),
    ];
    return Survey(
      id: surveyIdOf(topicId),
      version: _version,
      title: Topics.nameOf(topicId),
      topicId: topicId,
      estimatedMinutes: _minutes(questions.length),
      sourceLabel: _sourceLabel,
      questions: questions,
    );
  }

  static List<Question> _questionsFor(ChartDef def, Map<String, GraficaJson> data) {
    String texto(String variable) => switch (data[variable]?['texto']) {
          final String t => t,
          _ => throw ServerError('sin texto para $variable'),
        };

    if (!def.isGroup) {
      final v = def.variables.single;
      return [
        Question(id: v, text: def.surveyText ?? _pregunta(texto(v)), helper: def.surveyHelper,
            type: QuestionType.single, options: _options(data[v]!)),
      ];
    }
    if (def.isYesNoGroup) {
      return [
        Question(
          id: def.id,
          text: def.surveyStem!,
          helper: 'Marca todas las que apliquen.',
          type: QuestionType.multiple,
          options: [
            for (final (i, v) in def.variables.indexed) QuestionOption(v, _inciso(texto(v), def.labels[i])),
            if (def.exclusive == null) const QuestionOption(noneCode, 'Ninguna'),
          ],
          exclusiveCode: def.exclusive ?? noneCode,
        ),
      ];
    }
    final stem = def.surveyStem!;
    return [
      for (final (i, v) in def.variables.indexed)
        stem.contains('{item}')
            ? Question(id: v, text: stem.replaceAll('{item}', _lowerFirst(_inciso(texto(v), def.labels[i]))),
                type: QuestionType.single, options: _options(data[v]!))
            : Question(id: v, text: _inciso(texto(v), def.labels[i]), helper: stem,
                type: QuestionType.single, options: _options(data[v]!)),
    ];
  }

  /// Opciones del AMG. Lo que en la entrevista era "no leer" se ofrece como
  /// "Prefiero no responder" (cuenta igual en la base); "No válido" no aplica.
  static List<QuestionOption> _options(GraficaJson g) => [
        if (g['opciones'] case final List<Object?> opciones)
          for (final o in opciones)
            if (o case {'codigo': final num codigo, 'etiqueta': final String etiqueta} when etiqueta != 'No válido')
              QuestionOption(
                '${codigo.toInt()}',
                RegExp(r'^No (sabe/No )?contestó$').hasMatch(etiqueta) ? 'Prefiero no responder' : etiqueta,
              ),
      ];

  /// Quita lo que leía el encuestador ("En una escala del 1 al 5…", "Ahora te
  /// voy a preguntar…"): las opciones ya traen la escala. El contexto real se
  /// queda: "En caso de que tomes bebidas alcohólicas, ¿cuántos días…?".
  static String _pregunta(String texto) {
    final i = texto.indexOf('¿');
    if (i < 0 || i + 1 >= texto.length) return texto;
    final antes = texto.substring(0, i).toLowerCase();
    if (!antes.contains('escala') && !antes.contains('te voy a')) return texto;
    return '¿${texto[i + 1].toUpperCase()}${texto.substring(i + 2)}';
  }

  /// "…¿cuánta confianza tienes en…? La policía" -> "La policía". Sin "?" ni ":" -> [fallback].
  static String _inciso(String texto, String fallback) {
    for (final sep in ['?', ':']) {
      final i = texto.lastIndexOf(sep);
      if (i >= 0) {
        final item = texto.substring(i + 1).trim();
        if (item.isNotEmpty && !item.startsWith('(')) return item;
      }
    }
    return fallback;
  }

  static String _lowerFirst(String s) => s.isEmpty ? s : '${s[0].toLowerCase()}${s.substring(1)}';

  /// Respuestas de la app -> {variable AMG: código}. En opción múltiple, cada
  /// inciso vale 1 (Sí) si se marcó y 2 (No) si no.
  static Map<String, int> answersToCodes(List<ChartDef> defs, Map<String, Object> answers) {
    final codes = <String, int>{};
    for (final def in defs) {
      if (def.isYesNoGroup) {
        if (answers[def.id] case final List<String> selected) {
          for (final v in def.variables) {
            codes[v] = selected.contains(v) ? 1 : 2;
          }
        }
        continue;
      }
      for (final v in def.variables) {
        if (answers[v] case final String code) {
          if (int.tryParse(code) case final int value) codes[v] = value;
        }
      }
    }
    return codes;
  }

  /// Edad, sexo y municipio si vienen en estas respuestas (primera encuesta).
  /// "Otro"/"Prefiero no decir" y municipios fuera de los 6 del AMG van como null.
  static Demographics? demographicsFrom(Map<String, Object> answers) {
    if (answers['EDAD'] case final int edad) {
      final sexo = switch (answers['SEXO']) { 'F' => 'F', 'M' => 'M', 'X' => 'O', _ => null };
      final municipio = switch (answers['MUNICIPIO']) {
        final String m when const {'GDL', 'ZAP', 'TLQ', 'TON', 'TLJ', 'ELS'}.contains(m) => m,
        _ => null,
      };
      return (edad: edad, sexo: sexo, municipio: municipio);
    }
    return null;
  }
}
