import 'dart:convert';

import '../../models/survey_draft.dart';
import 'local_store.dart';

/// Borradores de encuesta, cifrados en el teléfono. Se borran al enviar.
class SurveyDraftStorage {
  SurveyDraftStorage(this._store);

  final LocalStore _store;

  static String _key(String surveyId) => 'survey_draft.$surveyId';

  Future<SurveyDraft?> load(String surveyId) async {
    final raw = await _store.read(_key(surveyId));
    if (raw == null) return null;
    try {
      return SurveyDraft.fromJson(jsonDecode(raw));
    } on FormatException {
      await delete(surveyId);
      return null;
    }
  }

  Future<Map<String, SurveyDraft>> loadAll(Iterable<String> surveyIds) async {
    final drafts = <String, SurveyDraft>{};
    for (final id in surveyIds) {
      final draft = await load(id);
      if (draft != null) drafts[id] = draft;
    }
    return drafts;
  }

  Future<bool> save(SurveyDraft draft) =>
      _store.write(_key(draft.surveyId), jsonEncode(draft.toJson()));

  Future<void> delete(String surveyId) => _store.delete(_key(surveyId));
}
