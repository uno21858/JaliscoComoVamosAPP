import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../widgets/widgets.dart';
import '../data/topics_screen.dart';
import '../donate/donate_screen.dart';
import '../home/home_screen.dart';
import '../surveys/survey_list_screen.dart';

/// Las 4 pestañas, como MainScreen de CCL. La activa viene de ?tab= y el
/// IndexedStack las mantiene vivas: cambiar de pestaña no pierde scroll ni datos.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.tab});

  /// 0 Inicio, 1 Datos, 2 Encuestas, 3 Donar.
  final int tab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: const [HomeScreen(), TopicsScreen(), SurveyListScreen(), DonateScreen()],
      ),
      bottomNavigationBar: JcvTabBar(
        currentIndex: tab,
        onTap: (index) => context.go(AppRoutes.tabs[index]),
        onAssistant: () => context.push(AppRoutes.assistant),
      ),
    );
  }
}
