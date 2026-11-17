import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jcv_app/app.dart';
import 'package:jcv_app/flavors/flavor_config.dart';
import 'package:jcv_app/models/models.dart';
import 'package:jcv_app/screens/data/topic_screen.dart';
import 'package:jcv_app/screens/data/topics_screen.dart';
import 'package:jcv_app/screens/home/home_screen.dart';
import 'package:jcv_app/screens/onboarding/onboarding_screen.dart';
import 'package:jcv_app/widgets/widgets.dart';

void main() {
  setUp(() {
    // Ya vio la bienvenida: el splash va directo a Inicio.
    FlutterSecureStorage.setMockInitialValues({OnboardingScreen.seenKey: '1'});
    FlavorConfig.init(const FlavorConfig(
      flavor: Flavor.dev,
      useMocks: true,
      showMockBanner: false,
      mockLatency: Duration.zero,
    ));
  });

  testWidgets('las pestañas conservan su estado y el detalle regresa a su pestaña',
      (tester) async {
    await tester.pumpWidget(const JcvApp());
    await tester.pump(const Duration(milliseconds: 1500)); // splash
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    final topics = find.byType(TopicsScreen, skipOffstage: false);
    final topicsState = tester.state(topics);

    await tester.tap(find.descendant(of: find.byType(JcvTabBar), matching: find.text('Datos')));
    await tester.pumpAndSettle();
    expect(find.byType(TopicsScreen), findsOneWidget);
    expect(tester.state(topics), same(topicsState));

    await tester.tap(find.text(Topics.all.first.name).first);
    await tester.pumpAndSettle();
    expect(find.byType(TopicScreen), findsOneWidget);

    tester.element(find.byType(TopicScreen)).pop();
    await tester.pumpAndSettle();
    expect(find.byType(TopicScreen), findsNothing);
    expect(find.byType(TopicsScreen), findsOneWidget);
    expect(tester.state(topics), same(topicsState));
  });
}
