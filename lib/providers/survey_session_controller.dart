import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../models/survey.dart';
import '../models/survey_draft.dart';
import '../repositories/survey_repository.dart';
import '../services/local/survey_draft_storage.dart';

enum SubmitOutcome { sent, failed, alreadyCompleted }

/// Estado de una encuesta mientras se responde (3.7 a 3.12).
/// Una pregunta por pantalla; el avance se guarda cifrado en cada paso.
class SurveySessionController extends ChangeNotifier {
  SurveySessionController({
    required this.survey,
    required SurveyRepository repository,
    required SurveyDraftStorage drafts,
    SurveyDraft? draft,
  })  : _repository = repository,
        _drafts = drafts {
    // Un borrador de otra versión de la encuesta no se usa (RF-ENC-14).
    if (draft != null && draft.version == survey.version) {
      _answers.addAll(draft.answers);
      _index = draft.currentIndex.clamp(0, survey.questions.length - 1).toInt();
    }
  }

  final Survey survey;
  final SurveyRepository _repository;
  final SurveyDraftStorage _drafts;

  final Map<String, Object> _answers = {};
  int _index = 0;
  bool _showRequiredError = false;
  bool _submitting = false;
  String? _submitError;

  int get index => _index;
  int get total => survey.questions.length;
  Question get current => survey.questions[_index];
  bool get isFirst => _index == 0;
  bool get isLast => _index == total - 1;
  bool get showRequiredError => _showRequiredError;
  bool get submitting => _submitting;
  String? get submitError => _submitError;
  Map<String, Object> get answers => Map.unmodifiable(_answers);

  /// Avance de la barra: la pregunta actual cuenta como alcanzada.
  double get progress => (_index + 1) / total;

  Object? answerFor(Question question) => _answers[question.id];

  void setAnswer(Object value) {
    _answers[current.id] = value;
    _showRequiredError = false;
    _submitError = null;
    notifyListeners();
  }

  void clearAnswer() {
    _answers.remove(current.id);
    notifyListeners();
  }

  /// Opción múltiple: respeta el máximo y la opción exclusiva ("Ninguna").
  void toggleOption(String code) {
    final question = current;
    final selected = List<String>.of(
      (_answers[question.id] as List<String>?) ?? const <String>[],
    );
    if (selected.contains(code)) {
      selected.remove(code);
    } else if (code == question.exclusiveCode) {
      selected
        ..clear()
        ..add(code);
    } else {
      selected.remove(question.exclusiveCode);
      final limit = question.maxSelections;
      if (limit != null && selected.length >= limit) return;
      selected.add(code);
    }
    if (selected.isEmpty) {
      _answers.remove(question.id);
    } else {
      _answers[question.id] = selected;
    }
    _showRequiredError = false;
    notifyListeners();
  }

  /// La rueda de edad siempre muestra un valor; si la persona avanza sin
  /// moverla, ese valor es su respuesta.
  void _commitPickerDefault() {
    final question = current;
    if (question.type == QuestionType.age && _answers[question.id] == null) {
      _answers[question.id] = question.initialValue ?? question.min;
    }
  }

  bool _currentIsAnswered() {
    final question = current;
    final value = _answers[question.id];
    if (value == null) return !question.required;
    return question.isValidAnswer(value);
  }

  /// Avanza si la pregunta está respondida. Devuelve false y muestra el
  /// error de 3.9 si es obligatoria y falta respuesta.
  Future<bool> next() async {
    _commitPickerDefault();
    if (!_currentIsAnswered()) {
      _showRequiredError = true;
      notifyListeners();
      return false;
    }
    if (isLast) return true;
    _index++;
    _showRequiredError = false;
    notifyListeners();
    await saveDraft();
    return true;
  }

  Future<void> back() async {
    if (isFirst) return;
    _index--;
    _showRequiredError = false;
    _submitError = null;
    notifyListeners();
    await saveDraft();
  }

  Future<void> saveDraft() async {
    await _drafts.save(SurveyDraft(
      surveyId: survey.id,
      version: survey.version,
      currentIndex: _index,
      answers: Map.of(_answers),
      updatedAt: DateTime.now(),
    ));
  }

  Future<SubmitOutcome> submit() async {
    _commitPickerDefault();
    if (!_currentIsAnswered()) {
      _showRequiredError = true;
      notifyListeners();
      return SubmitOutcome.failed;
    }
    _submitting = true;
    _submitError = null;
    notifyListeners();
    await saveDraft();

    final result = await _repository.submit(
      surveyId: survey.id,
      version: survey.version,
      answers: Map.of(_answers),
    );

    _submitting = false;
    switch (result) {
      case Ok():
        await _drafts.delete(survey.id);
        notifyListeners();
        return SubmitOutcome.sent;
      case Err(:final failure) when failure.type == FailureType.conflict:
        await _drafts.delete(survey.id);
        _submitError = failure.message;
        notifyListeners();
        return SubmitOutcome.alreadyCompleted;
      case Err(:final failure):
        // Sin conexión: el borrador se queda para reintentar (RF-ENC-12).
        _submitError = failure.type == FailureType.network
            ? 'No pudimos enviar tus respuestas. Tu avance quedó guardado; '
                'inténtalo de nuevo cuando tengas conexión.'
            : failure.message;
        notifyListeners();
        return SubmitOutcome.failed;
    }
  }
}
