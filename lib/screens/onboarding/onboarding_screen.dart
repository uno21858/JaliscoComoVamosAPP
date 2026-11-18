import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/local/local_store.dart';
import '../../widgets/widgets.dart';

/// Bienvenida de 3 pantallas, como el onboarding de CCL. Sale una sola vez
/// después del splash; se vuelve a ver tocando el logo de JCV en Inicio.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  /// Marca en el teléfono de que ya se vio.
  static const seenKey = 'jcv_bienvenida_vista';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  const _Slide(this.icon, this.title, this.text);
  final IconData icon;
  final String title;
  final String text;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      CupertinoIcons.person_3_fill,
      'Lo que viven los jóvenes del AMG',
      'La Encuesta de Bienestar de Jóvenes 2026 de Jalisco Cómo Vamos, '
          'con jóvenes de 15 a 29 años del Área Metropolitana de Guadalajara.',
    ),
    _Slide(
      CupertinoIcons.chart_bar_alt_fill,
      'Explora por tema',
      'Gráficas de 8 temas, con filtros por edad, sexo y estrato.',
    ),
    _Slide(
      CupertinoIcons.chat_bubble_2_fill,
      'Pregúntale al asistente',
      'Responde en segundos con las cifras reales de la encuesta.',
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<LocalStore>().write(OnboardingScreen.seenKey, '1');
    if (!mounted) return;
    // Desde el splash no hay a dónde regresar; desde el logo de Inicio, sí.
    context.canPop() ? context.pop() : context.go(AppRoutes.home);
  }

  void _next() {
    if (_isLast) {
      unawaited(_finish());
      return;
    }
    unawaited(_pages.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            const JcvColorBar(),
            Expanded(
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.paddingOf(context).top),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                      child: Row(
                        children: [
                          const JcvRing(size: 36),
                          const Spacer(),
                          // Mismo alto en la última pantalla para que nada brinque.
                          AnimatedOpacity(
                            opacity: _isLast ? 0 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: JcvTextButton(
                              label: 'Saltar',
                              onPressed: _isLast ? null : () => unawaited(_finish()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pages,
                        itemCount: _slides.length,
                        onPageChanged: (page) => setState(() => _page = page),
                        itemBuilder: (context, index) => _SlideView(slide: _slides[index]),
                      ),
                    ),
                    Semantics(
                      label: 'Pantalla ${_page + 1} de ${_slides.length}',
                      excludeSemantics: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _slides.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == _page ? 22 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _page ? AppColors.navy : AppColors.grayBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: JcvButton(label: _isLast ? 'Empezar' : 'Siguiente', onPressed: _next),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconCircle(
            icon: slide.icon,
            size: 128,
            iconSize: 58,
            background: AppColors.limePale,
          ),
          const SizedBox(height: 32),
          Semantics(
            header: true,
            child: Text(slide.title, style: AppTextStyles.stateTitle, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          Text(slide.text, style: AppTextStyles.body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
