import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../models/survey.dart';
import '../models/survey_draft.dart';
import '../repositories/survey_repository.dart';
import '../services/local/survey_draft_storage.dart';
import 'view_status.dart';

enum SurveyState { fresh, inProgress, completed }

class SurveyListItem {
  const SurveyListItem({required this.summary, this.draft});

  final SurveySummary summary;
  final SurveyDraft? draft;

  SurveyState get state {
    if (summary.completed) return SurveyState.completed;
    if (draft != null) return SurveyState.inProgress;
    return SurveyState.fresh;
  }

  /// Número de la pregunta donde se quedó, empezando en 1.
  int get currentQuestion => (draft?.currentIndex ?? 0) + 1;

  /// Avance de 0 a 1, contando las preguntas ya respondidas antes de la actual.
  double get progress {
    final total = summary.questionCount;
    if (total == 0) return 0;
    return ((draft?.currentIndex ?? 0) / total).clamp(0, 1).toDouble();
  }
}

/// Lista de encuestas (3.4) con su estado: nueva, en progreso o completada.
class SurveysProvider extends ChangeNotifier {
  SurveysProvider(this._repository, this._drafts);

  final SurveyRepository _repository;
  final SurveyDraftStorage _drafts;

  ViewStatus _status = ViewStatus.loading;
  List<SurveyListItem> _items = const [];
  String _errorMessage = '';
  bool _loadedOnce = false;

  ViewStatus get status => _status;
  List<SurveyListItem> get items => _items;
  String get errorMessage => _errorMessage;

  /// La encuesta con avance más reciente, para la tarjeta "Continuar donde
  /// te quedaste" (3.13).
  SurveyListItem? get resumeItem {
    SurveyListItem? latest;
    for (final item in _items) {
      final draft = item.draft;
      if (item.state != SurveyState.inProgress || draft == null) continue;
      if (latest == null || draft.updatedAt.isAfter(latest.draft!.updatedAt)) {
        latest = item;
      }
    }
    return latest;
  }

  Future<void> load({bool silent = false}) async {
    if (!silent || !_loadedOnce) {
      _status = ViewStatus.loading;
      notifyListeners();
    }
    final result = await _repository.getSurveys();
    switch (result) {
      case Ok(:final value):
        final drafts = await _drafts.loadAll(value.map((s) => s.id));
        _items = [
          for (final summary in value)
            SurveyListItem(
              summary: summary,
              // Un borrador de una encuesta ya completada no sirve.
              draft: summary.completed ? null : drafts[summary.id],
            ),
        ];
        _status = ViewStatus.ready;
        _loadedOnce = true;
      case Err(:final failure):
        _errorMessage = failure.message;
        if (!_loadedOnce) _status = ViewStatus.error;
    }
    notifyListeners();
  }
}
