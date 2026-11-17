import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../screens/assistant/assistant_screen.dart';
import '../../screens/data/chart_detail_screen.dart';
import '../../screens/data/comparison_screen.dart';
import '../../screens/data/report_preview_screen.dart';
import '../../screens/data/report_screen.dart';
import '../../screens/data/topic_screen.dart';
import '../../screens/donate/donation_result_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/surveys/privacy_notice_screen.dart';
import '../../screens/surveys/survey_screen.dart';
import '../../screens/surveys/survey_thanks_screen.dart';
import 'app_routes.dart';

/// Rutas planas, como CCL: todo lo que no es pestaña se abre encima de MAIN.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // SPLASH
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // BIENVENIDA (primera vez, o desde el logo de Inicio)
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // MAIN (las 4 pestañas)
      GoRoute(
        path: AppRoutes.main,
        builder: (context, state) => MainShell(
          tab: (int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0).clamp(0, 3),
        ),
      ),

      // ASISTENTE
      GoRoute(
        path: AppRoutes.assistant,
        pageBuilder: (context, state) => const MaterialPage<void>(
          fullscreenDialog: true,
          child: AssistantScreen(),
        ),
      ),

      // DATOS
      GoRoute(
        path: '/datos/tema/:topicId',
        builder: (context, state) => TopicScreen(topicId: state.pathParameters['topicId']!),
      ),
      GoRoute(
        path: '/datos/tema/:topicId/comparativa',
        builder: (context, state) =>
            ComparisonScreen(topicId: state.pathParameters['topicId']!),
      ),
      GoRoute(
        path: '/datos/tema/:topicId/grafica/:chartId',
        builder: (context, state) => ChartDetailScreen(
          topicId: state.pathParameters['topicId']!,
          chartId: state.pathParameters['chartId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.report,
        builder: (context, state) =>
            ReportScreen(initialTopicId: state.uri.queryParameters['tema']),
      ),
      GoRoute(
        path: AppRoutes.reportPreview,
        redirect: (context, state) => state.extra is ReportRequest ? null : AppRoutes.report,
        builder: (context, state) =>
            ReportPreviewScreen(request: state.extra! as ReportRequest),
      ),

      // ENCUESTAS
      GoRoute(
        path: '/encuestas/:surveyId/aviso',
        builder: (context, state) =>
            PrivacyNoticeScreen(surveyId: state.pathParameters['surveyId']!),
      ),
      GoRoute(
        path: '/encuestas/:surveyId/responder',
        builder: (context, state) =>
            SurveyScreen(surveyId: state.pathParameters['surveyId']!),
      ),
      GoRoute(
        path: '/encuestas/:surveyId/gracias',
        builder: (context, state) =>
            SurveyThanksScreen(surveyId: state.pathParameters['surveyId']!),
      ),

      // DONAR
      GoRoute(
        path: AppRoutes.donationSuccess,
        redirect: (context, state) => state.extra is DonationReceipt ? null : AppRoutes.donate,
        builder: (context, state) =>
            DonationResultScreen(receipt: state.extra! as DonationReceipt),
      ),
      GoRoute(
        path: AppRoutes.donationFailed,
        redirect: (context, state) => state.extra is DonationReceipt ? null : AppRoutes.donate,
        builder: (context, state) =>
            DonationResultScreen(receipt: state.extra! as DonationReceipt),
      ),
    ],
  );
}
