import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/core.dart';
import '../../core/router/app_routes.dart';
import '../../providers/providers.dart';
import '../../repositories/repositories.dart';
import '../../widgets/widgets.dart';

/// 3.4 Lista de encuestas y 3.13 "Continuar donde te quedaste".
class SurveyListScreen extends StatefulWidget {
  const SurveyListScreen({super.key});

  @override
  State<SurveyListScreen> createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends State<SurveyListScreen> {
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    // Fuera del build: load() avisa a los listeners al empezar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<SurveysProvider>().load(silent: true));
    });
  }

  /// Abre la encuesta: primero el aviso de privacidad si no se ha aceptado.
  Future<void> _open(String surveyId) async {
    if (_opening) return;
    _opening = true;
    final accepted = await context.read<SurveyRepository>().hasAcceptedPrivacy();
    _opening = false;
    if (!mounted) return;
    unawaited(context.push(
      accepted ? AppRoutes.answerSurvey(surveyId) : AppRoutes.privacyNotice(surveyId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SurveysProvider>();
    final resume = provider.resumeItem;

    final Widget body = switch (provider.status) {
      ViewStatus.loading => const Center(child: CupertinoActivityIndicator(radius: 14)),
      ViewStatus.error || ViewStatus.tooFew => ConnectionErrorView(
          message: provider.errorMessage,
          onRetry: () => unawaited(provider.load()),
        ),
      ViewStatus.ready => RefreshIndicator(
          color: AppColors.navy,
          onRefresh: () => provider.load(silent: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              if (resume != null) ...[
                _ResumeCard(item: resume, onContinue: () => unawaited(_open(resume.summary.id))),
                const SizedBox(height: 18),
              ],
              const SectionLabel('Disponibles'),
              const SizedBox(height: 10),
              for (final item in provider.items)
                if (item != resume) ...[
                  _SurveyCard(item: item, onOpen: () => unawaited(_open(item.summary.id))),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
    };

    return Scaffold(
      body: Column(
        children: [
          const RootHeader(
            title: 'Encuestas',
            subtitle: 'Responde a tu ritmo, puedes pausar cuando quieras',
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.value, required this.track, required this.fill});

  final double value;
  final Color track;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Avance',
      value: Formatters.percent(value * 100),
      child: ProgressTrack(value: value, height: 6, track: track, fill: fill),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.item, required this.onContinue});

  final SurveyListItem item;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final summary = item.summary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x400E3B70), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTINUAR DONDE TE QUEDASTE',
            style: TextStyle(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.88,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary.title,
            style: const TextStyle(
              fontSize: 18,
              height: 22 / 18,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pregunta ${item.currentQuestion} de ${summary.questionCount} · '
            'guardado en este teléfono',
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: AppColors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ProgressLine(
                  value: item.progress,
                  track: AppColors.white.withValues(alpha: 0.22),
                  fill: AppColors.lime,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                Formatters.percent(item.progress * 100),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 132,
                child: JcvButton(label: 'Continuar', small: true, onPressed: onContinue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurveyCard extends StatelessWidget {
  const _SurveyCard({required this.item, required this.onOpen});

  final SurveyListItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final summary = item.summary;
    final state = item.state;

    final Widget badge = switch (state) {
      SurveyState.fresh => const TagPill('NUEVA'),
      SurveyState.inProgress => const TagPill('EN PROGRESO', color: AppColors.gold),
      SurveyState.completed => const TagPill(
          'COMPLETADA',
          color: AppColors.grayBlue,
          icon: CupertinoIcons.checkmark_alt,
        ),
    };

    final String subtitle = switch (state) {
      SurveyState.fresh => '${summary.questionCount} preguntas · ${summary.sourceLabel}',
      SurveyState.inProgress =>
        '${summary.questionCount} preguntas · vas en la ${item.currentQuestion}',
      SurveyState.completed => 'Respondida · gracias por participar',
    };

    return JcvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              badge,
              const Spacer(),
              if (state != SurveyState.completed) ...[
                const Icon(CupertinoIcons.clock, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${summary.estimatedMinutes} min',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary.title,
            style: const TextStyle(
              fontSize: 17,
              height: 22 / 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.caption),
          if (state == SurveyState.fresh) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 132,
                child: JcvButton(label: 'Empezar', small: true, onPressed: onOpen),
              ),
            ),
          ],
          if (state == SurveyState.inProgress) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ProgressLine(
                    value: item.progress,
                    track: AppColors.grayBlue,
                    fill: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  Formatters.percent(item.progress * 100),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 132,
                  child: JcvButton(
                    label: 'Continuar',
                    small: true,
                    variant: JcvButtonVariant.outline,
                    onPressed: onOpen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
