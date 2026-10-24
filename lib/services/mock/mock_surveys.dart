// Encuestas de ejemplo para desarrollo. Las preguntas salen del catálogo del
// SRS (§12.3) y del wireflow. Las definitivas dependen de D-10 con JCV, y
// cada pregunta debe existir en el cuestionario AMG para poder comparar.

import '../../models/survey.dart';

abstract final class MockSurveys {
  static const _yesNo = [QuestionOption('SI', 'Sí'), QuestionOption('NO', 'No')];

  static const _age = Question(
    id: 'EDAD',
    text: '¿Cuántos años tienes?',
    type: QuestionType.age,
    helper: 'La usamos solo para fines estadísticos.',
    helperIsPrivacyNote: true,
    min: 18,
    max: 29,
    initialValue: 20,
  );

  static const _sex = Question(
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
  );

  static const _municipality = Question(
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
  );

  static const _occupation = Question(
    id: 'OCUPACION',
    text: '¿Actualmente estudias, trabajas o ambos?',
    type: QuestionType.single,
    helper: 'Elige una opción.',
    options: [
      QuestionOption('ESTUDIA', 'Solo estudio'),
      QuestionOption('AMBOS', 'Estudio y trabajo'),
      QuestionOption('TRABAJA', 'Solo trabajo'),
      QuestionOption('NINGUNO', 'Ni estudio ni trabajo'),
    ],
  );

  static const _health = Question(
    id: 'SA01',
    text: 'En general, ¿cómo calificarías tu salud?',
    type: QuestionType.single,
    helper: 'Elige una opción.',
    options: [
      QuestionOption('5', 'Muy buena'),
      QuestionOption('4', 'Buena'),
      QuestionOption('3', 'Regular'),
      QuestionOption('2', 'Mala'),
      QuestionOption('1', 'Muy mala'),
    ],
  );

  static const _safety = Question(
    id: 'SE01',
    text: '¿Qué tan seguro te sientes caminando de noche en tu colonia?',
    type: QuestionType.single,
    helper: 'Elige una opción.',
    options: [
      QuestionOption('5', 'Muy seguro'),
      QuestionOption('4', 'Seguro'),
      QuestionOption('3', 'Ni seguro ni inseguro'),
      QuestionOption('2', 'Inseguro'),
      QuestionOption('1', 'Muy inseguro'),
    ],
  );

  static const _transportMode = Question(
    id: 'TR01',
    text: '¿Qué medio de transporte usas más para ir a la escuela o al trabajo?',
    type: QuestionType.single,
    helper: 'Elige una opción.',
    options: [
      QuestionOption('TP', 'Transporte público'),
      QuestionOption('AUTO', 'Automóvil'),
      QuestionOption('BICI', 'Bicicleta'),
      QuestionOption('PIE', 'A pie'),
      QuestionOption('APP', 'Taxi o plataforma'),
      QuestionOption('MOTO', 'Motocicleta'),
      QuestionOption('NO_TRASLADO', 'No me traslado regularmente'),
    ],
  );

  static const _transportTime = Question(
    id: 'TR02',
    text: 'En promedio, ¿cuánto tardas en llegar a tu escuela o trabajo?',
    type: QuestionType.single,
    helper: 'Solo el viaje de ida.',
    options: [
      QuestionOption('0-15', '15 minutos o menos'),
      QuestionOption('16-30', '16 a 30 minutos'),
      QuestionOption('31-60', '31 a 60 minutos'),
      QuestionOption('61+', 'Más de una hora'),
    ],
  );

  static const educationAndWork = Survey(
    id: 'educacion-trabajo-2026',
    version: 1,
    title: 'Educación y trabajo',
    topicId: 'educacion-trabajo',
    estimatedMinutes: 5,
    sourceLabel: 'Encuesta AMG 2026',
    questions: [
      _age,
      _occupation,
      _sex,
      _municipality,
      Question(
        id: 'ED01',
        text: '¿Actualmente asistes a la escuela?',
        type: QuestionType.single,
        helper: 'Elige una opción.',
        options: _yesNo,
      ),
      Question(
        id: 'ED02',
        text: '¿Actualmente tienes un trabajo con pago?',
        type: QuestionType.single,
        helper: 'Elige una opción.',
        options: _yesNo,
      ),
      Question(
        id: 'ED03',
        text: 'Si trabajas, ¿cuántas horas a la semana?',
        type: QuestionType.single,
        helper: 'Elige una opción.',
        options: [
          QuestionOption('NO_TRABAJA', 'No trabajo'),
          QuestionOption('<10', 'Menos de 10 horas'),
          QuestionOption('10-20', '10 a 20 horas'),
          QuestionOption('21-40', '21 a 40 horas'),
          QuestionOption('>40', 'Más de 40 horas'),
        ],
      ),
      _transportMode,
      _transportTime,
      Question(
        id: 'TL01',
        text: '¿Qué haces con más frecuencia en tu tiempo libre?',
        type: QuestionType.multiple,
        helper: 'Elige hasta 3 opciones.',
        maxSelections: 3,
        exclusiveCode: 'NINGUNA',
        options: [
          QuestionOption('DEPORTE', 'Deporte'),
          QuestionOption('REDES', 'Redes sociales'),
          QuestionOption('VIDEOJUEGOS', 'Videojuegos'),
          QuestionOption('AMIGOS', 'Ver a amigos'),
          QuestionOption('LECTURA', 'Leer'),
          QuestionOption('CULTURA', 'Actividades culturales'),
          QuestionOption('NINGUNA', 'Ninguna de estas'),
        ],
      ),
      _health,
      Question(
        id: 'ED04',
        text: 'Del 0 al 10, ¿qué tan satisfecho estás con tus estudios o tu trabajo?',
        type: QuestionType.scale,
        helper: '0 es nada satisfecho y 10 es muy satisfecho.',
        min: 0,
        max: 10,
        minLabel: 'Nada satisfecho',
        maxLabel: 'Muy satisfecho',
      ),
    ],
  );

  static const wellbeing = Survey(
    id: 'bienestar-2026',
    version: 1,
    title: 'Bienestar subjetivo',
    topicId: 'bienestar',
    estimatedMinutes: 4,
    sourceLabel: 'Encuesta AMG 2026',
    questions: [
      _age,
      _sex,
      _municipality,
      Question(
        id: 'BS01',
        text: 'Del 0 al 10, ¿qué tan satisfecho estás con tu vida en general?',
        type: QuestionType.scale,
        helper: '0 es nada satisfecho y 10 es muy satisfecho.',
        min: 0,
        max: 10,
        minLabel: 'Nada satisfecho',
        maxLabel: 'Muy satisfecho',
      ),
      _health,
      _safety,
      Question(
        id: 'HF01',
        text: '¿Con quién vives actualmente?',
        type: QuestionType.single,
        helper: 'Elige una opción.',
        options: [
          QuestionOption('AMBOS_PADRES', 'Con ambos padres'),
          QuestionOption('UN_PADRE', 'Con mi papá o mi mamá'),
          QuestionOption('PAREJA', 'Con mi pareja'),
          QuestionOption('SOLO', 'Solo o sola'),
          QuestionOption('OTROS', 'Con otras personas'),
        ],
      ),
      Question(
        id: 'HF02',
        text: '¿Qué tan satisfecho estás con tus relaciones familiares?',
        type: QuestionType.single,
        helper: 'Elige una opción.',
        options: [
          QuestionOption('5', 'Totalmente'),
          QuestionOption('4', 'Mucho'),
          QuestionOption('3', 'Algo'),
          QuestionOption('2', 'Poco'),
          QuestionOption('1', 'Nada'),
        ],
      ),
      Question(
        id: 'CO01',
        text: 'En el último año, ¿participaste en alguna actividad comunitaria o de voluntariado?',
        type: QuestionType.single,
        helper: 'Esta pregunta es opcional.',
        required: false,
        options: _yesNo,
      ),
      Question(
        id: 'CO02',
        text: '¿Cuánto confías en tus vecinos?',
        type: QuestionType.single,
        helper: 'Elige una opción.',
        options: [
          QuestionOption('4', 'Mucho'),
          QuestionOption('3', 'Algo'),
          QuestionOption('2', 'Poco'),
          QuestionOption('1', 'Nada'),
        ],
      ),
    ],
  );

  static const transport = Survey(
    id: 'transporte-2026',
    version: 1,
    title: 'Transporte',
    topicId: 'transporte',
    estimatedMinutes: 3,
    sourceLabel: 'Encuesta AMG 2026',
    questions: [_age, _sex, _municipality, _transportMode, _transportTime, _safety],
  );

  static const all = [educationAndWork, wellbeing, transport];

  static Survey? byId(String id) {
    for (final survey in all) {
      if (survey.id == id) return survey;
    }
    return null;
  }
}
