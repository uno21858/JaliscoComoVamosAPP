import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// 1.1 Splash: logo y carga. Pasa solo a Inicio.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), _goHome);
  }

  void _goHome() {
    _timer?.cancel();
    if (mounted) context.go(AppRoutes.home);
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
