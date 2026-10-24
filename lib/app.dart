import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'flavors/flavor_config.dart';
import 'providers/providers.dart';
import 'repositories/repositories.dart';
import 'screens/donate/mock_payment_sheet.dart';
import 'services/local/local_store.dart';
import 'services/local/survey_draft_storage.dart';
import 'services/mock/mock_assistant_service.dart';
import 'services/mock/mock_data_service.dart';
import 'services/mock/mock_donation_service.dart';
import 'services/mock/mock_speech_input.dart';
import 'services/mock/mock_survey_service.dart';

/// Dependencias de la app. Hoy todo es mock; cuando exista el backend, aquí
/// se cambian las implementaciones sin tocar pantallas.
class AppDependencies {
  AppDependencies._({
    required this.data,
    required this.surveys,
    required this.drafts,
    required this.donations,
    required this.payments,
    required this.assistant,
    required this.speech,
  });

  factory AppDependencies.create(FlavorConfig config) {
    if (!config.useMocks) {
      // TODO(backend): servicios de Supabase en lib/services/supabase/.
      throw UnimplementedError('El backend real todavía no existe; usa useMocks: true.');
    }
    final store = LocalStore();
    final donations = MockDonationService();
    return AppDependencies._(
      data: MockDataService(),
      surveys: MockSurveyService(store),
      drafts: SurveyDraftStorage(store),
      donations: donations,
      payments: MockPaymentPresenter(donations),
      assistant: MockAssistantService(),
      speech: MockSpeechInput(),
    );
  }

  final DataRepository data;
  final SurveyRepository surveys;
  final SurveyDraftStorage drafts;
  final DonationRepository donations;
  final PaymentPresenter payments;
  final AssistantRepository assistant;
  final SpeechInput speech;
}

class JcvApp extends StatefulWidget {
  const JcvApp({super.key});

  @override
  State<JcvApp> createState() => _JcvAppState();
}

class _JcvAppState extends State<JcvApp> {
  late final AppDependencies _deps = AppDependencies.create(FlavorConfig.instance);
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DataRepository>.value(value: _deps.data),
        Provider<SurveyRepository>.value(value: _deps.surveys),
        Provider<SurveyDraftStorage>.value(value: _deps.drafts),
        Provider<DonationRepository>.value(value: _deps.donations),
        Provider<PaymentPresenter>.value(value: _deps.payments),
        Provider<AssistantRepository>.value(value: _deps.assistant),
        Provider<SpeechInput>.value(value: _deps.speech),
        ChangeNotifierProvider<DataFiltersProvider>(create: (_) => DataFiltersProvider()),
        ChangeNotifierProvider<SurveysProvider>(
          create: (_) => SurveysProvider(_deps.surveys, _deps.drafts),
        ),
      ],
      child: MaterialApp.router(
        title: 'Jalisco Cómo Vamos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
        locale: const Locale('es', 'MX'),
        supportedLocales: const [Locale('es', 'MX'), Locale('es')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
