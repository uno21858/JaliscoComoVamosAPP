import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jcv_app/core/utils/formatters.dart';
import 'package:jcv_app/core/utils/money.dart';
import 'package:jcv_app/models/models.dart';
import 'package:jcv_app/services/mock/mock_data_service.dart';

void main() {
  group('Money', () {
    test('formatea centavos con miles y moneda', () {
      expect(Money.format(10000), r'$100.00 MXN');
      expect(Money.format(2000), r'$20.00 MXN');
      expect(Money.format(1000000), r'$10,000.00 MXN');
      expect(Money.format(123456789, withCurrency: false), r'$1,234,567.89');
    });

    test('convierte lo que escribe la persona a centavos', () {
      expect(Money.parseCents('100'), 10000);
      expect(Money.parseCents('100.5'), 10050);
      expect(Money.parseCents('1,000.00'), 100000);
      expect(Money.parseCents('20.'), 2000);
      expect(Money.parseCents(''), isNull);
      expect(Money.parseCents('abc'), isNull);
      expect(Money.parseCents('10.123'), isNull);
    });
  });

  group('Formatters', () {
    test('miles y porcentaje', () {
      expect(Formatters.thousands(1200), '1,200');
      expect(Formatters.thousands(999), '999');
      expect(Formatters.percent(42.6), '43%');
    });

    test('correo', () {
      expect(EmailValidator.isValid('a01234567@tec.mx'), isTrue);
      expect(EmailValidator.isValid('sin-arroba.com'), isFalse);
      expect(EmailValidator.isValid('a@b'), isFalse);
    });
  });

  group('DataFilters', () {
    test('etiquetas de chips por defecto', () {
      expect(DataFilters.none.chipLabels, ['Todos los municipios', '15 a 29 años']);
    });

    test('etiquetas con filtros', () {
      const filters = DataFilters(municipality: 'ZAP', ageGroup: '20-24', stratum: 'ALTO');
      expect(filters.chipLabels, ['Zapopan', '20 a 24 años', 'Estrato alto']);
      expect(filters.ageSexStratumSummary, '20 a 24 · Todos · Alto');
      expect(filters.activeCount, 3);
    });

    test('quitar un filtro con null', () {
      const filters = DataFilters(municipality: 'ZAP');
      expect(filters.withMunicipality(null), DataFilters.none);
    });
  });

  group('Question.isValidAnswer', () {
    const single = Question(
      id: 'P',
      text: '¿?',
      type: QuestionType.single,
      options: [QuestionOption('A', 'a'), QuestionOption('B', 'b')],
    );
    const multiple = Question(
      id: 'M',
      text: '¿?',
      type: QuestionType.multiple,
      maxSelections: 2,
      options: [QuestionOption('A', 'a'), QuestionOption('B', 'b'), QuestionOption('C', 'c')],
    );
    const scale = Question(id: 'S', text: '¿?', type: QuestionType.scale, min: 0, max: 10);

    test('opción única', () {
      expect(single.isValidAnswer('A'), isTrue);
      expect(single.isValidAnswer('Z'), isFalse);
      expect(single.isValidAnswer(1), isFalse);
    });

    test('opción múltiple respeta el máximo', () {
      expect(multiple.isValidAnswer(<String>['A', 'B']), isTrue);
      expect(multiple.isValidAnswer(<String>['A', 'B', 'C']), isFalse);
      expect(multiple.isValidAnswer(<String>[]), isFalse);
    });

    test('escala respeta el rango', () {
      expect(scale.isValidAnswer(0), isTrue);
      expect(scale.isValidAnswer(10), isTrue);
      expect(scale.isValidAnswer(11), isFalse);
    });
  });

  group('SurveyDraft', () {
    test('ida y vuelta por JSON', () {
      final draft = SurveyDraft(
        surveyId: 'x',
        version: 1,
        currentIndex: 3,
        answers: const {'EDAD': 20, 'OCUPACION': 'AMBOS', 'TL01': <String>['DEPORTE']},
        updatedAt: DateTime(2026, 11, 4, 10, 30),
      );
      final restored = SurveyDraft.fromJson(jsonDecode(jsonEncode(draft.toJson())));
      expect(restored, isNotNull);
      expect(restored!.currentIndex, 3);
      expect(restored.answers['EDAD'], 20);
      expect(restored.answers['OCUPACION'], 'AMBOS');
      expect(restored.answers['TL01'], ['DEPORTE']);
    });

    test('JSON corrupto regresa null', () {
      expect(SurveyDraft.fromJson('nada'), isNull);
      expect(SurveyDraft.fromJson(<String, Object?>{'surveyId': 1}), isNull);
    });
  });

  group('Plantilla de comparativa', () {
    test('menciona la categoría con más diferencia', () {
      final text = MockDataService.comparisonSummary(const [
        ComparisonRow('Solo estudia', 43, 72),
        ComparisonRow('Solo trabaja', 28, 4),
      ]);
      expect(text, contains('Solo estudia'));
      expect(text, contains('72%'));
    });
  });
}
