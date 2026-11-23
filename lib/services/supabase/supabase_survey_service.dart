import 'dart:async';
import 'dart:convert';

import 'package:supabase/supabase.dart';

import '../../core/app_error.dart';
import '../../core/error_sanitizer.dart';
import '../../core/result.dart';
import '../../models/models.dart';
import '../../repositories/survey_repository.dart';
import '../auth/auth_service.dart';
import '../local/device_id.dart';
import '../local/local_store.dart';
import '../local/survey_draft_storage.dart';
import 'graficas_destacadas.dart';
import 'supabase_data_service.dart';

typedef Demographics = ({int edad, String? sexo, String? municipio});

/// Una fila de jcv.encuestas_activas(): qué preguntas del AMG lleva la encuesta.
typedef Encuesta = ({String id, String topicId, String title, int version, List<ChartDef> defs});

/// Encuestas del Tec. Desde v1.10 la lista y sus preguntas vienen de la base
/// (jcv.encuestas): JCV las cambia sin publicar la app. Textos y opciones son
/// los del AMG (jcv.preguntas), así se comparan con Jalisco. Se guardan con
/// jcv.guardar_encuesta como fuente TEC, así la comparativa sale sola.
///
/// Edad y sexo se preguntan una vez y se guardan en el teléfono. El municipio
/// no se pregunta: JCV pidió no filtrar por municipio.
///
/// Desde v1.09 pide sesión: una vez por persona. Qué encuestas ya contestó sale
/// del servidor (jcv.mis_encuestas), no del teléfono. [_client] manda el token.
class SupabaseSurveyService implements SurveyRepository {
  SupabaseSurveyService(this._client, this._store, this._auth);

  final SupabaseClient _client;
  final LocalStore _store;
  final AuthService _auth;

  /// Lista local de v1.05 (por teléfono). Ya no se usa; se borra al salir.
  static const _legacyCompletedKey = 'jcv_encuestas_hechas';
  static const _privacyKey = 'jcv_aviso_privacidad';
  static const _demographicsKey = 'jcv_demografia';
  static const _timeout = Duration(seconds: 15);
  static const _sourceLabel = 'Mismas preguntas que la encuesta AMG 2026';

  /// Código de "Ninguna" en las preguntas de opción múltiple.
  static const noneCode = 'NINGUNA';

  Future<List<Encuesta>> _activas() async => switch (await _rpc('encuestas_activas', {})) {
        final List<Object?> rows => [for (final row in rows.whereType<Map<String, dynamic>>()) encuestaFromJson(row)],
        _ => const [],
      };

  Future<Encuesta?> _encuesta(String id) async => (await _activas()).where((e) => e.id == id).firstOrNull;

  @override
  String get privacyNoticeVersion => '2026-11-v2'; // v2: cuenta con correo (v1.09)

  @override
  Future<bool> hasAcceptedPrivacy() async => await _store.read(_privacyKey) == privacyNoticeVersion;

  @override
  Future<Result<void>> acceptPrivacy() =>
      guardResult(() => _store.write(_privacyKey, privacyNoticeVersion));

  @override
  Future<Result<List<SurveySummary>>> getSurveys() => guardResult(() async {
        final completed = _auth.isSignedIn ? await _completed() : const <String>{};
        final extra = await _demographics() == null ? demographicQuestions.length : 0;
        return [
          for (final e in await _activas())
            SurveySummary(
              id: e.id,
              title: e.title,
              topicId: e.topicId,
              questionCount: countQuestions(e.defs) + extra,
              estimatedMinutes: _minutes(countQuestions(e.defs) + extra),
              sourceLabel: _sourceLabel,
              completed: completed.contains(e.id),
            ),
        ];
      });

  @override
  Future<Result<Survey>> getSurvey(String surveyId) => guardResult(() async {
        final e = await _encuesta(surveyId);
        if (e == null) throw const ValidationError('Esta encuesta ya no está disponible.');
        // Textos y opciones salen de la base (fuente AMG): iguales al cuestionario de JCV.
        final data = SupabaseDataService.byVariable(await _rpc('graficas', {
          'p_variables': [for (final d in e.defs) ...d.variables],
          'p_fuente': 'AMG',
        }));
        return buildSurvey(e, data, askDemographics: await _demographics() == null);
      });

  @override
  Future<Result<void>> submit({
    required String surveyId,
    required int version,
    required Map<String, Object> answers,
  }) =>
      guardResult(() async {
        if (!_auth.isSignedIn) throw const ValidationError('Inicia sesión para responder.');
        final e = await _encuesta(surveyId);
        if (e == null || e.version != version) throw const ValidationError('La encuesta cambió. Vuelve a abrirla.');

        final nuevos = demographicsFrom(answers);
        final demo = nuevos ?? await _demographics();
        if (demo == null) throw const ValidationError('Falta contestar tus datos generales.');

        final result = await _rpc('guardar_encuesta', {
          'p_dispositivo': await deviceId(_store),
          'p_encuesta': surveyId,
          'p_edad': demo.edad,
          'p_sexo': demo.sexo,
          'p_municipio': demo.municipio,
          'p_respuestas': answersToCodes(e.defs, answers),
        });
        if (nuevos != null) {
          await _store.write(_demographicsKey,
              jsonEncode({'edad': nuevos.edad, 'sexo': nuevos.sexo, 'municipio': nuevos.municipio}));
        }
        if (result == 'ya_contestada') throw const ConflictError('Ya respondiste esta encuesta. ¡Gracias!');
      });

  Future<Object?> _rpc(String function, Map<String, Object?> params) async {
    try {
      return await _client.schema('jcv').rpc<Object?>(function, params: params).timeout(_timeout);
    } on PostgrestException catch (e) {
      if (e.code == 'P0401') {
        throw const ValidationError('Tu sesión terminó. Vuelve a entrar.');
      }
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

  Future<Set<String>> _completed() async =>
      switch (await _rpc('mis_encuestas', {})) { final List<Object?> ids => ids.whereType<String>().toSet(), _ => {} };

  @override
  Future<Result<void>> deleteMyData() => guardResult(() => _rpc('borrar_mis_datos', {}));

  /// Al cerrar sesión: lo que el teléfono guardó de esa persona (edad, sexo,
  /// aviso aceptado, borradores) no debe verlo quien entre después.
  static Future<void> forgetLocal(LocalStore store, SurveyDraftStorage drafts) async {
    for (final key in [_demographicsKey, _privacyKey, _legacyCompletedKey]) {
      await store.delete(key);
    }
    await drafts.deleteAll();
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
  ];

  /// Grupo Sí/No: 1 pregunta. Grupo de escala: 1 por inciso. Sola: 1.
  static int countQuestions(List<ChartDef> defs) =>
      defs.fold(0, (n, d) => n + (d.isGroup && !d.isYesNoGroup ? d.variables.length : 1));

  static int _minutes(int questions) => (questions * 12 / 60).ceil().clamp(1, 60);

  /// Fila de jcv.encuestas_activas() -> Encuesta. Formato de cada pregunta en
  /// SQLScripts/v1.10_jcv_encuestas_en_base.sql (la base ya lo validó).
  static Encuesta encuestaFromJson(Map<String, dynamic> row) {
    final tema = row['tema'] as String;
    List<T> list<T>(Object? v) => (v as List<Object?>? ?? const []).cast<T>();
    ChartDef def(Map<String, dynamic> p, List<String> variables) => variables.length == 1
        ? ChartDef(variables.single, tema, '', variables,
            surveyText: p['text'] as String?, surveyHelper: p['helper'] as String?)
        : ChartDef.group(p['id'] as String, tema, '', variables,
            codes: p['multiple'] == true ? const [1] : const [],
            labels: list<String>(p['labels']),
            subtitle: null,
            surveyStem: p['stem'] as String?,
            exclusive: p['exclusive'] as String?);
    return (
      id: row['id'] as String,
      topicId: tema,
      title: row['titulo'] as String,
      version: row['version'] as int,
      defs: [for (final p in list<Map<String, dynamic>>(row['preguntas'])) def(p, list<String>(p['variables']))],
    );
  }

  static Survey buildSurvey(Encuesta e, Map<String, GraficaJson> data, {required bool askDemographics}) {
    final questions = [
      if (askDemographics) ...demographicQuestions,
      for (final def in e.defs) ..._questionsFor(def, data),
    ];
    return Survey(
      id: e.id,
      version: e.version,
      title: e.title,
      topicId: e.topicId,
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

  /// Edad y sexo si vienen en estas respuestas (primera encuesta). "Otro" va
  /// como O y "Prefiero no decir" como null. El municipio ya no se pregunta.
  static Demographics? demographicsFrom(Map<String, Object> answers) {
    if (answers['EDAD'] case final int edad) {
      final sexo = switch (answers['SEXO']) { 'F' => 'F', 'M' => 'M', 'X' => 'O', _ => null };
      return (edad: edad, sexo: sexo, municipio: null);
    }
    return null;
  }
}
