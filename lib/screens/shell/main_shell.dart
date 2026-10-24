import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../widgets/widgets.dart';

/// Contenedor de las 4 pestañas. Cada pestaña conserva su propia pila.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTab(int index) {
    // Tocar la pestaña activa regresa al inicio de su flujo.
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: JcvTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTab,
        onAssistant: () => context.push(AppRoutes.assistant),
      ),
    );
  }
}
