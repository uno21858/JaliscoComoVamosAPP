import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth/auth_service.dart';
import '../../services/local/local_store.dart';
import '../../widgets/widgets.dart';
import '../onboarding/onboarding_screen.dart';

/// 1.1 Splash: logo y carga. Pasa sola a la bienvenida (primera vez) o a Inicio.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  late final Future<bool> _seenWelcome;
  late final Future<void> _session;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    // Se lee mientras corre el splash, así no se alarga.
    _seenWelcome =
        context.read<LocalStore>().read(OnboardingScreen.seenKey).then((value) => value != null);
    // La sesión guardada también se recupera aquí (refresca el token si venció).
    // Sin red no se queda pegado: a los 5 s sigue (sin sesión por ahora).
    _session = (context.read<AuthService?>()?.restore() ?? Future.value())
        .timeout(const Duration(seconds: 5), onTimeout: () {});
    _timer = Timer(const Duration(milliseconds: 1400), _goHome);
  }

  /// La primera vez va a la bienvenida; después, directo a Inicio.
  Future<void> _goHome() async {
    if (_leaving) return; // el toque y el timer pueden llegar juntos
    _leaving = true;
    _timer?.cancel();
    final seen = await _seenWelcome;
    await _session;
    if (mounted) context.go(seen ? AppRoutes.home : AppRoutes.welcome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _goHome,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        JcvRing(size: 120, semanticLabel: 'Anillo de Jalisco Cómo Vamos'),
                        SizedBox(height: 22),
                        Text(
                          'Jalisco Cómo Vamos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            height: 34 / 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.28,
                            color: AppColors.navy,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Observatorio Ciudadano',
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.84,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 22),
                        JcvColorBar(width: 160, height: 6, radius: 3),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: CupertinoActivityIndicator(radius: 14, color: AppColors.navy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
