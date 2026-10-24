import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/core.dart';
import '../../core/router/app_routes.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../repositories/repositories.dart';
import '../../services/local/survey_draft_storage.dart';
import '../../widgets/widgets.dart';
import 'widgets/question_views.dart';

/// 3.7 a 3.12: una pregunta por pantalla, progreso, guardar y salir.
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key, required this.surveyId});

  final String surveyId;

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  SurveySessionController? _controller;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_load(initial: true));
  }

  Future<void> _load({bool initial = false}) async {
    if (!initial) setState(() => _loadError = null);
    final repository = context.read<SurveyRepository>();
    final drafts = context.read<SurveyDraftStorage>();
    final result = await repository.getSurvey(widget.surveyId);
    final draft = await drafts.load(widget.surveyId);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _controller = SurveySessionController(
            survey: value,
            repository: repository,
            drafts: drafts,
            draft: draft,
          );
        });
      case Err(:final failure):
        setState(() => _loadError = failure.message);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _confirmExit() async {
    final controller = _controller;
    if (controller == null) {
      context.go(AppRoutes.surveys);
      return;
    }
    final save = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('¿Guardar y salir?'),
        message: const Text(
          'Tu avance se guarda en este teléfono. Si borras la app o cambias de celular, se pierde.',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(true),
            child: const Text('Guardar y salir'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(false),
          child: const Text('Seguir respondiendo'),
        ),
      ),
    );
    if (save != true || !mounted) return;
    await controller.saveDraft();
    if (!mounted) return;
    unawaited(context.read<SurveysProvider>().load(silent: true));
    context.go(AppRoutes.surveys);
  }

  Future<void> _next() async {
    final controller = _controller!;
    if (!controller.isLast) {
      await controller.next();
      return;
    }
    final outcome = await controller.submit();
    if (!mounted) return;
    switch (outcome) {
      case SubmitOutcome.sent:
        unawaited(context.read<SurveysProvider>().load(silent: true));
        context.go(AppRoutes.surveyThanks(widget.surveyId));
      case SubmitOutcome.alreadyCompleted:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.submitError ?? 'Ya respondiste esta encuesta.')),
        );
        unawaited(context.read<SurveysProvider>().load(silent: true));
        context.go(AppRoutes.surveys);
      case SubmitOutcome.failed:
        break; // El error se muestra en pantalla.
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final loadError = _loadError;

    Widget body;
    if (controller != null) {
      body = ChangeNotifierProvider<SurveySessionController>.value(
        value: controller,
        child: _QuestionPage(onNext: () => unawaited(_next())),
      );
    } else if (loadError != null) {
      body = ConnectionErrorView(message: loadError, onRetry: () => unawaited(_load()));
    } else {
      body = const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_confirmExit());
      },
      child: Scaffold(
        body: Column(
          children: [
            ScreenHeader(
              title: 'Encuesta',
              leading: HeaderLeading.none,
              trailing: HeaderPillButton(
                label: 'Guardar y salir',
                icon: CupertinoIcons.xmark,
                onPressed: () => unawaited(_confirmExit()),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SurveySessionController>();
    final question = controller.current;
    final helper = question.helper;
    final submitError = controller.submitError;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey('scroll-${controller.index}'),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.survey.title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    height: 16 / 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.88,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Pregunta ${controller.index + 1} de ${controller.total}',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ExcludeSemantics(child: ProgressTrack(value: controller.progress)),
                const SizedBox(height: 22),
                Semantics(
                  header: true,
                  child: Text(
                    question.text,
                    style: question.type == QuestionType.age
                        ? AppTextStyles.question.copyWith(fontSize: 24, height: 30 / 24)
                        : AppTextStyles.question,
                  ),
                ),
                if (helper != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (question.helperIsPrivacyNote) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(CupertinoIcons.info, size: 16, color: AppColors.navyDark),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          helper,
                          style: question.helperIsPrivacyNote
                              ? AppTextStyles.body
                              : const TextStyle(
                                  fontSize: 13,
                                  height: 18 / 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: ValueKey('question-${question.id}'),
                  child: QuestionInput(
                    question: question,
                    value: controller.answerFor(question),
                    onChanged: controller.setAnswer,
                    onToggle: controller.toggleOption,
                  ),
                ),
                if (controller.showRequiredError) ...[
                  const SizedBox(height: 16),
                  const RequiredAnswerBanner(),
                ],
                if (submitError != null) ...[
                  const SizedBox(height: 16),
                  RequiredAnswerBanner(message: submitError),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: JcvButton(
                    label: 'Atrás',
                    variant: JcvButtonVariant.outline,
                    leadingIcon: CupertinoIcons.chevron_left,
                    onPressed: controller.isFirst || controller.submitting
                        ? null
                        : () => unawaited(controller.back()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: controller.isLast
                      ? JcvButton(
                          label: 'Enviar',
                          leadingIcon: CupertinoIcons.paperplane_fill,
                          busy: controller.submitting,
                          onPressed: onNext,
                        )
                      : JcvButton(
                          label: 'Siguiente',
                          trailingIcon: CupertinoIcons.chevron_right,
                          onPressed: onNext,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
