import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/core.dart';
import '../../core/router/app_routes.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// 3.11 Gracias: invita a ver resultados o a donar.
class SurveyThanksScreen extends StatelessWidget {
  const SurveyThanksScreen({super.key, required this.surveyId});

  final String surveyId;

  String? _topicIdOf(BuildContext context) {
    for (final item in context.read<SurveysProvider>().items) {
      if (item.summary.id == surveyId) return item.summary.topicId;
    }
    return null;
  }

  void _seeResults(BuildContext context) {
    final topicId = _topicIdOf(context);
    if (topicId == null) {
      context.go(AppRoutes.data);
      return;
    }
    context.read<DataFiltersProvider>().apply(
          source: DataSource.comparison,
          filters: DataFilters.none,
        );
    context.go(AppRoutes.comparison(topicId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 72, 32, 24),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 170,
                      height: 150,
                      child: Stack(
                        children: [
                          Positioned(left: 0, top: 0, child: JcvRing(size: 140)),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: _CheckBadge(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Semantics(
                      header: true,
                      child: const Text(
                        '¡Gracias por responder!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          height: 32 / 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Tus respuestas ya cuentan para comparar a los estudiantes del Tec '
                      'con los jóvenes del AMG.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 22 / 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const JcvColorBar(width: 120, height: 6, radius: 3),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  JcvButton(label: 'Ver resultados', onPressed: () => _seeResults(context)),
                  const SizedBox(height: 12),
                  JcvButton(
                    label: 'Apoyar a JCV',
                    variant: JcvButtonVariant.secondary,
                    leadingIcon: CupertinoIcons.heart_fill,
                    onPressed: () => context.go(AppRoutes.donate),
                  ),
                  const SizedBox(height: 4),
                  JcvTextButton(
                    label: 'Volver a encuestas',
                    onPressed: () => context.go(AppRoutes.surveys),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.lime,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 4),
      ),
      child: const Icon(CupertinoIcons.checkmark_alt, size: 26, color: AppColors.navy),
    );
  }
}
