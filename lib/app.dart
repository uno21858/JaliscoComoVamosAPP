import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase/supabase.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'flavors/flavor_config.dart';
import 'providers/providers.dart';
import 'repositories/repositories.dart';
import 'screens/donate/mock_payment_sheet.dart';
import 'services/auth/auth_service.dart';
import 'services/local/device_speech_input.dart';
import 'services/local/local_store.dart';
import 'services/local/survey_draft_storage.dart';
import 'services/mock/mock_assistant_service.dart';
import 'services/mock/mock_data_service.dart';
import 'services/mock/mock_donation_service.dart';
import 'services/mock/mock_speech_input.dart';
import 'services/mock/mock_survey_service.dart';
import 'services/supabase/supabase_assistant_service.dart';
import 'services/supabase/supabase_data_service.dart';
import 'services/supabase/supabase_survey_service.dart';

/// Dependencias de la app. Aquí se cambian las implementaciones sin tocar
/// pantallas. Con credenciales de Supabase, Datos, Encuestas, el asistente y
/// la voz son reales; sin ellas (pruebas), mocks. Donar sigue en mock.
class AppDependencies {
  AppDependencies._({
    required this.data,
    required this.surveys,
    required this.drafts,
    required this.donations,
    required this.payments,
    required this.assistant,
    required this.speech,
    required this.store,
    required this.auth,
  });

  factory AppDependencies.create(FlavorConfig config) {
    final store = LocalStore();
    final donations = MockDonationService();
    final drafts = SurveyDraftStorage(store);
    final supabase =
        config.hasSupabase ? SupabaseClient(config.supabaseUrl, config.supabaseAnonKey) : null;
    final auth = config.hasCognito
        ? AuthService(
            userPoolId: config.cognitoUserPoolId,
            clientId: config.cognitoClientId,
            hostedUiDomain: config.cognitoDomain,
          )
        : null;
    // Solo Encuestas manda el token de Cognito. Datos y el asistente siguen con
    // la anon key: son públicos y la edge function tiene verify_jwt.
    final surveysClient = supabase != null && auth != null
        ? SupabaseClient(config.supabaseUrl, config.supabaseAnonKey, accessToken: auth.accessToken)
        : null;
    auth?.onSignedOut = () => SupabaseSurveyService.forgetLocal(store, drafts);
    return AppDependencies._(
      data: supabase != null ? SupabaseDataService(supabase) : MockDataService(),
      surveys: surveysClient != null && auth != null
          ? SupabaseSurveyService(surveysClient, store, auth)
          : MockSurveyService(store),
      drafts: drafts,
      donations: donations,
      payments: MockPaymentPresenter(donations),
      assistant: supabase != null ? SupabaseAssistantService(supabase, store) : MockAssistantService(),
      speech: supabase != null ? DeviceSpeechInput() : MockSpeechInput(),
      store: store,
      auth: auth,
    );
  }

  final DataRepository data;
  final SurveyRepository surveys;
  final SurveyDraftStorage drafts;
  final DonationRepository donations;
  final PaymentPresenter payments;
  final AssistantRepository assistant;
  final SpeechInput speech;

  /// Almacenamiento cifrado del teléfono (bienvenida vista, borradores, id).
  final LocalStore store;

  /// Null sin Cognito (pruebas): no hay login y Encuestas no lo pide.
  final AuthService? auth;
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
        Provider<LocalStore>.value(value: _deps.store),
        ChangeNotifierProvider<AuthService?>.value(value: _deps.auth),
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
