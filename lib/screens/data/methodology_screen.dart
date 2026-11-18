import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

/// Cómo se hizo la encuesta (JCV pidió la metodología).
class MethodologyScreen extends StatelessWidget {
  const MethodologyScreen({super.key});

  static const _assistant = (
    title: 'El asistente',
    points: [
      'Responde con estos mismos datos. Cada cifra que da se revisa contra la base '
          'antes de mostrarse.',
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          const ScreenHeader(title: 'Metodología'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 28 + MediaQuery.paddingOf(context).bottom),
              children: [
                Semantics(
                  header: true,
                  child:
                      const Text('¿Cómo se hizo esta encuesta?', style: AppTextStyles.stateTitle),
                ),
                for (final section in [...methodology, _assistant]) ...[
                  const SizedBox(height: 22),
                  SectionLabel(section.title),
                  const SizedBox(height: 8),
                  for (final point in section.points)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  ', style: AppTextStyles.body),
                          Expanded(child: Text(point, style: AppTextStyles.body)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
