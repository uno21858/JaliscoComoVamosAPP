import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcv_app/app.dart';
import 'package:jcv_app/flavors/flavor_config.dart';
import 'package:jcv_app/screens/home/home_screen.dart';
import 'package:jcv_app/screens/onboarding/onboarding_screen.dart';

void main() {
  setUp(() => FlavorConfig.init(const FlavorConfig(
        flavor: Flavor.dev,
          showMockBanner: false,
        mockLatency: Duration.zero,
      )));

  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(const JcvApp());
    await tester.pump(const Duration(milliseconds: 1500)); // splash
    await tester.pumpAndSettle();
  }

  testWidgets('primera vez: bienvenida de 3 pantallas y luego Inicio; ya no vuelve a salir',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await abrirApp(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Lo que viven los jóvenes del AMG'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Explora por tema'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Pregúntale al asistente'), findsOneWidget);
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    // Segunda vez: el splash va directo a Inicio.
    expect(await const FlutterSecureStorage().read(key: OnboardingScreen.seenKey), '1');
    await tester.pumpWidget(const SizedBox.shrink());
    await abrirApp(tester);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('"Saltar" va a Inicio, y el logo de Inicio la vuelve a abrir', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await abrirApp(tester);
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('¿Qué es esta app?'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget); // regresó con pop, no reinició
  });
}
