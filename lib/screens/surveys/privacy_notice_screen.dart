import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/core.dart';
import '../../core/router/app_routes.dart';
import '../../repositories/repositories.dart';
import '../../widgets/widgets.dart';

/// 3.5 / 3.6 Aviso de privacidad. "Acepto" se habilita al llegar al final.
///
/// Los textos entre corchetes son marcadores: van del aviso oficial de JCV.
class PrivacyNoticeScreen extends StatefulWidget {
  const PrivacyNoticeScreen({super.key, required this.surveyId});

  final String surveyId;

  @override
  State<PrivacyNoticeScreen> createState() => _PrivacyNoticeScreenState();
}

class _PrivacyNoticeScreenState extends State<PrivacyNoticeScreen> {
  final _scroll = ScrollController();
  bool _reachedEnd = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_checkEnd);
    // Con texto grande o pantalla alta puede no haber nada que desplazar.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkEnd());
  }

  void _checkEnd() {
    if (_reachedEnd || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 24) {
      setState(() => _reachedEnd = true);
    }
  }

  Future<void> _accept() async {
    setState(() => _saving = true);
    final result = await context.read<SurveyRepository>().acceptPrivacy();
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        context.pushReplacement(AppRoutes.answerSurvey(widget.surveyId));
      case Err(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          const ScreenHeader(title: 'Aviso de privacidad'),
          Expanded(
            child: Scrollbar(
              controller: _scroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 20, 24, 28),
                child: const _NoticeText(),
              ),
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _reachedEnd
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.chevron_down,
                            size: 14,
                            color: _reachedEnd ? AppColors.navy : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _reachedEnd
                                ? 'Leíste todo el aviso'
                                : 'Desliza hasta el final para continuar',
                            style: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              fontWeight: FontWeight.w700,
                              color: _reachedEnd ? AppColors.navy : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    JcvButton(
                      label: 'Acepto',
                      busy: _saving,
                      onPressed: _reachedEnd ? () => unawaited(_accept()) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeText extends StatelessWidget {
  const _NoticeText();

  static const _body = TextStyle(
    fontSize: 14,
    height: 21 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.navyDark,
  );

  static const _placeholder = TextStyle(
    fontSize: 14,
    height: 21 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const _heading = TextStyle(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w800,
    color: AppColors.navy,
  );

  Widget _section(String title, String text, {bool placeholder = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: _heading)),
          const SizedBox(height: 6),
          Text(text, style: placeholder ? _placeholder : _body),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: const Text('Antes de tu primera encuesta', style: AppTextStyles.stateTitle),
        ),
        const SizedBox(height: 10),
        const Text(
          'Jalisco Cómo Vamos usa tus respuestas para comparar a los estudiantes del Tec '
          'con los jóvenes del AMG. Lee cómo cuidamos tus datos antes de empezar.',
          style: _body,
        ),
        _section(
          '¿Quién es responsable de tus datos?',
          '[Nombre y domicilio del responsable, según el aviso oficial de JCV]',
          placeholder: true,
        ),
        _section(
          '¿Qué datos recabamos?',
          'Solo tus respuestas a la encuesta. No guardamos tu nombre ni tu correo junto '
              'con ellas.',
        ),
        _section(
          '¿Para qué los usamos?',
          'Para fines estadísticos: comparar los resultados del Tec con la muestra AMG 2026. '
              'Nunca se muestran grupos de menos de 30 respuestas.',
        ),
        _section(
          '¿Cómo ejercer tus derechos ARCO?',
          '[Medio de contacto del aviso oficial]',
          placeholder: true,
        ),
        _section(
          '¿Compartimos tus datos?',
          '[Transferencias, según el aviso oficial de JCV]',
          placeholder: true,
        ),
        _section(
          'Cambios a este aviso',
          '[Cómo se avisarán los cambios, según el aviso oficial]',
          placeholder: true,
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.limePale,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Al tocar Acepto confirmas que leíste este aviso y que tus respuestas se usen '
            'con fines estadísticos.',
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.info, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text(
                'Llegaste al final del aviso',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
