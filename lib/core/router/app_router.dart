import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../screens/assistant/assistant_screen.dart';
import '../../screens/data/chart_detail_screen.dart';
import '../../screens/data/comparison_screen.dart';
import '../../screens/data/report_preview_screen.dart';
import '../../screens/data/report_screen.dart';
import '../../screens/data/topic_screen.dart';
import '../../screens/data/topics_screen.dart';
import '../../screens/donate/donate_screen.dart';
import '../../screens/donate/donation_result_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/surveys/privacy_notice_screen.dart';
import '../../screens/surveys/survey_list_screen.dart';
import '../../screens/surveys/survey_screen.dart';
import '../../screens/surveys/survey_thanks_screen.dart';
import 'app_routes.dart';

/// Navigator raíz: lo que se abre aquí tapa la barra inferior
/// (asistente, aviso de privacidad y la encuesta en curso).
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.assistant,
        pageBuilder: (context, state) => const MaterialPage<void>(
          fullscreenDialog: true,
          child: AssistantScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.data,
                builder: (context, state) => const TopicsScreen(),
                routes: [
                  GoRoute(
                    path: 'tema/:topicId',
                    builder: (context, state) =>
                        TopicScreen(topicId: state.pathParameters['topicId']!),
                    routes: [
                      GoRoute(
                        path: 'comparativa',
                        builder: (context, state) =>
                            ComparisonScreen(topicId: state.pathParameters['topicId']!),
                      ),
                      GoRoute(
                        path: 'grafica/:chartId',
                        builder: (context, state) => ChartDetailScreen(
                          topicId: state.pathParameters['topicId']!,
                          chartId: state.pathParameters['chartId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'informe',
                    builder: (context, state) => ReportScreen(
                      initialTopicId: state.uri.queryParameters['tema'],
                    ),
                    routes: [
                      GoRoute(
                        path: 'vista-previa',
                        redirect: (context, state) =>
                            state.extra is ReportRequest ? null : AppRoutes.report,
                        builder: (context, state) =>
                            ReportPreviewScreen(request: state.extra! as ReportRequest),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.surveys,
                builder: (context, state) => const SurveyListScreen(),
                routes: [
                  GoRoute(
                    path: ':surveyId/aviso',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        PrivacyNoticeScreen(surveyId: state.pathParameters['surveyId']!),
                  ),
                  GoRoute(
                    path: ':surveyId/responder',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        SurveyScreen(surveyId: state.pathParameters['surveyId']!),
                  ),
                  GoRoute(
                    path: ':surveyId/gracias',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        SurveyThanksScreen(surveyId: state.pathParameters['surveyId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.donate,
                builder: (context, state) => const DonateScreen(),
                routes: [
                  GoRoute(
                    path: 'exito',
                    redirect: (context, state) =>
                        state.extra is DonationReceipt ? null : AppRoutes.donate,
                    builder: (context, state) =>
                        DonationResultScreen(receipt: state.extra! as DonationReceipt),
                  ),
                  GoRoute(
                    path: 'rechazado',
                    redirect: (context, state) =>
                        state.extra is DonationReceipt ? null : AppRoutes.donate,
                    builder: (context, state) =>
                        DonationResultScreen(receipt: state.extra! as DonationReceipt),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
