import 'package:flutter_test/flutter_test.dart';
import 'package:jcv_app/models/models.dart';
import 'package:jcv_app/services/supabase/graficas_destacadas.dart';
import 'package:jcv_app/services/supabase/supabase_data_service.dart';
import 'package:jcv_app/services/supabase/supabase_survey_service.dart';

/// Como llega de jcv.graficas: texto y opciones del cuestionario de JCV.
GraficaJson g(String variable, String texto, List<String> etiquetas) => {
      'variable': variable,
      'texto': texto,
      'opciones': [
        for (final (i, e) in etiquetas.indexed) {'codigo': i + 1, 'etiqueta': e, 'porcentaje': 10.0},
      ],
    };

List<ChartDef> defsOf(String topic) => graficasDestacadas.where((d) => d.topicId == topic).toList();

const siNo = ['Sí', 'No'];
const confianza = ['Nada', 'Poca', 'Ni algo, ni poca', 'Algo', 'Mucha', 'No sabe/No contestó'];

void main() {
  final educacion = {
    for (final (i, item) in [
      'Estudias (dentro del sistema escolar)',
      'Trabajas de tiempo completo',
      'Trabajas de medio tiempo o jornada parcial',
      'Trabajas en tu hogar (sin remuneración económica)',
      'Cuidas en tu hogar niñas, niños, personas adultas mayores o personas con enfermedad',
    ].indexed)
      'T_Q_13_${i + 1}': g('T_Q_13_${i + 1}',
          'De las siguientes actividades, ¿me podrías decir cuáles de ellas realizas diariamente o de manera regular? $item', siNo),
    'Q_74recode': g('Q_74recode', '¿Cuál es tu nivel de escolaridad?', ['Primaria', 'Secundaria', 'No contestó']),
    'Q_17': g('Q_17', 'Para ti, ¿qué importancia tiene hoy la educación superior?', ['Ninguna', 'Mucha']),
    'Q_14': g('Q_14', 'En una escala del 1 al 5, donde 1 significa "nada", ¿qué tan satisfecha(o) estás actualmente con tus actividades diarias?',
        ['Nada satisfecha(o)', 'Muy satisfecha(o)', 'No sabe/No contestó']),
  };

  test('educación: datos generales, opción múltiple con "Ninguna" y preguntas del AMG', () {
    final s = SupabaseSurveyService.buildSurvey('educacion-trabajo', defsOf('educacion-trabajo'), educacion,
        askDemographics: true);
    expect(s.id, 'tec-educacion-trabajo');
    expect(s.questions.map((q) => q.id).take(2), ['EDAD', 'SEXO']);
    expect(s.questions.any((q) => q.id == 'MUNICIPIO'), isFalse, reason: 'JCV: sin municipio');

    final multiple = s.questions[2];
    expect(multiple.type, QuestionType.multiple);
    expect(multiple.text, '¿Cuáles de estas actividades haces a diario o de forma regular?');
    expect(multiple.options.first.label, 'Estudias (dentro del sistema escolar)');
    expect(multiple.options.last.code, SupabaseSurveyService.noneCode);
    expect(multiple.exclusiveCode, SupabaseSurveyService.noneCode);

    final escolaridad = s.questions.firstWhere((q) => q.id == 'Q_74recode');
    expect(escolaridad.options.map((o) => o.label), ['Primaria', 'Secundaria', 'Prefiero no responder']);

    final actividades = s.questions.firstWhere((q) => q.id == 'Q_14');
    expect(actividades.text, '¿Qué tan satisfecha(o) estás actualmente con tus actividades diarias?');
    expect(actividades.helper, isNull, reason: 'la explicación de la escala sobra');
    expect(actividades.options.last.label, 'Prefiero no responder');
  });

  test('Q_41 viene cortado desde SPSS: usa el texto propio', () {
    final def = graficasDestacadas.firstWhere((d) => d.id == 'salud-mental');
    final q = SupabaseSurveyService.buildSurvey('salud', [def], {
      'Q_41': g('Q_41', 'La salud mental se refiere a tu bienestar emocional. … Considerando es', ['Muy mala', 'Muy buena']),
    }, askDemographics: false).questions.single;
    expect(q.text, '¿Cómo calificarías tu salud mental?');
    expect(q.helper, contains('bienestar emocional'));
  });

  test('preámbulo del encuestador fuera', () {
    final def = graficasDestacadas.firstWhere((d) => d.id == 'salud-satisfaccion');
    final q = SupabaseSurveyService.buildSurvey('salud', [def], {
      'Q_36': g('Q_36', 'Ahora te voy a preguntar sobre tu salud. Por favor dime, en una escala del 1 al 5, ¿qué tan satisfecha(o) te sientes con tu salud?', ['Nada', 'Mucho']),
    }, askDemographics: false).questions.single;
    expect(q.text, '¿Qué tan satisfecha(o) te sientes con tu salud?');
  });

  test('sin datos generales la segunda vez', () {
    final s = SupabaseSurveyService.buildSurvey('educacion-trabajo', defsOf('educacion-trabajo'), educacion,
        askDemographics: false);
    expect(s.questions.first.id, isNot('EDAD'));
  });

  test('el contexto real se queda en la pregunta; "No válido" no se ofrece', () {
    final def = graficasDestacadas.firstWhere((d) => d.id == 'salud-alcohol');
    final s = SupabaseSurveyService.buildSurvey('salud', [def], {
      'Q_38': g('Q_38', 'En caso de que tomes bebidas alcohólicas, ¿cuántos días a la semana, en promedio las consumes?',
          ['1 día a la semana', 'No válido', 'No consumo bebidas alcohólicas']),
    }, askDemographics: false);
    final q = s.questions.single;
    expect(q.text, 'En caso de que tomes bebidas alcohólicas, ¿cuántos días a la semana, en promedio las consumes?');
    expect(q.helper, isNull);
    expect(q.options.map((o) => o.label), ['1 día a la semana', 'No consumo bebidas alcohólicas']);
  });

  test('escala por inciso: con {item} se arma la pregunta; sin {item} el stem es ayuda', () {
    final confianzaDef = graficasDestacadas.firstWhere((d) => d.id == 'comunidad-confianza');
    final data = {
      for (final v in confianzaDef.variables)
        v: g(v, '¿Cuánta confianza tienes en cada una de las siguientes instituciones o grupos? La policía', confianza),
    };
    final q = SupabaseSurveyService.buildSurvey('comunidad', [confianzaDef], data, askDemographics: false).questions;
    expect(q, hasLength(15));
    expect(q.first.text, '¿Cuánta confianza tienes en la policía?');

    final tiempo = graficasDestacadas.firstWhere((d) => d.id == 'tiempo-actividades');
    final sinSeparador = {
      for (final v in tiempo.variables)
        v: g(v, 'Ahora te voy a leer una lista de actividades. Por favor dime con qué frecuencia las realizaste en los últimos tres meses Ir al cine',
            ['Nunca', 'Con mucha frecuencia']),
    };
    final t = SupabaseSurveyService.buildSurvey('tiempo-libre', [tiempo], sinSeparador, askDemographics: false).questions;
    expect(t.first.text, 'Cine');
    expect(t.first.helper, 'En los últimos 3 meses, ¿con qué frecuencia hiciste esto?');
  });

  test('respuestas de la app a códigos del AMG', () {
    final defs = defsOf('educacion-trabajo');
    final codes = SupabaseSurveyService.answersToCodes(defs, {
      'EDAD': 19,
      'educacion-actividades': ['T_Q_13_1', 'T_Q_13_3'],
      'Q_74recode': '2',
      'Q_17': '1',
    });
    expect(codes, {
      'T_Q_13_1': 1, 'T_Q_13_2': 2, 'T_Q_13_3': 1, 'T_Q_13_4': 2, 'T_Q_13_5': 2,
      'Q_74recode': 2, 'Q_17': 1,
    });
    final ninguna = SupabaseSurveyService.answersToCodes(defs, {
      'educacion-actividades': [SupabaseSurveyService.noneCode],
    });
    expect(ninguna.values.toSet(), {2});
  });

  test('datos generales: "otro" y "prefiero no decir"; el municipio no se guarda', () {
    expect(SupabaseSurveyService.demographicsFrom({'EDAD': 21, 'SEXO': 'X', 'MUNICIPIO': 'ZAP'}),
        (edad: 21, sexo: 'O', municipio: null));
    expect(SupabaseSurveyService.demographicsFrom({'EDAD': 18, 'SEXO': 'NR'}),
        (edad: 18, sexo: null, municipio: null));
    expect(SupabaseSurveyService.demographicsFrom({'Q_6': '5'}), isNull);
  });

  test('una encuesta por temática; Comunidad es la más larga', () {
    final cuenta = {for (final t in Topics.all) t.id: SupabaseSurveyService.countQuestions(defsOf(t.id))};
    expect(cuenta.keys, hasLength(8));
    expect(cuenta['comunidad'], 20);
    expect(cuenta['transporte'], 2);
  });
}
