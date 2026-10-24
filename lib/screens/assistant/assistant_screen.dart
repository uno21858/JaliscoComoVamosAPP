import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/core.dart';
import '../../core/router/app_routes.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../repositories/repositories.dart';
import '../../widgets/widgets.dart';

/// 5.1 Asistente, 5.2 Escuchando y 5.3 Respuesta.
class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AssistantController>(
      create: (context) => AssistantController(
        context.read<AssistantRepository>(),
        context.read<SpeechInput>(),
      ),
      child: const _AssistantView(),
    );
  }
}

class _AssistantView extends StatefulWidget {
  const _AssistantView();

  @override
  State<_AssistantView> createState() => _AssistantViewState();
}

class _AssistantViewState extends State<_AssistantView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(AssistantController controller, String text) {
    _input.clear();
    FocusScope.of(context).unfocus();
    unawaited(controller.send(text));
  }

  void _scrollToEndIfNeeded(int count) {
    if (count == _lastCount) return;
    _lastCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      unawaited(_scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AssistantController>();
    final itemCount = controller.messages.length + (controller.thinking ? 1 : 0);
    _scrollToEndIfNeeded(itemCount);

    if (controller.listening) {
      return _ListeningView(controller: controller);
    }

    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'Asistente IA',
            leading: HeaderLeading.close,
            onLeading: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          Expanded(
            child: controller.isEmpty && !controller.thinking
                ? _Intro(onAsk: (text) => _send(controller, text))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 18, 20, 18),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index >= controller.messages.length) return const _ThinkingBubble();
                      final message = controller.messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: message.author == MessageAuthor.user
                            ? _UserBubble(text: message.text)
                            : _AnswerBubble(answer: message.answer!),
                      );
                    },
                  ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'La IA puede equivocarse. Revisa las gráficas en Datos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 16 / 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _InputBar(
            controller: _input,
            canSend: _input.text.trim().isNotEmpty && !controller.thinking,
            onSend: () => _send(controller, _input.text),
            onMic: controller.startListening,
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onAsk});

  final ValueChanged<String> onAsk;

  static const _sample = '¿Los del Tec trabajan más o menos que en el AMG?';
  static const _chipTopics = [
    'salud',
    'educacion-trabajo',
    'bienestar',
    'seguridad',
    'transporte',
    'tiempo-libre',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      children: [
        const Center(
          child: IconCircle(
            icon: CupertinoIcons.sparkles,
            size: 64,
            iconSize: 30,
            background: AppColors.raspberry,
            iconColor: AppColors.white,
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: const Text(
            '¡Hola! Hazme una pregunta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              height: 30 / 24,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Pregunta sobre los datos de la encuesta. Te respondo con gráficas.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 28),
        const SectionLabel('Temas'),
        const SizedBox(height: 10),
        EvenGrid(
          columns: 3,
          children: [
            for (final id in _chipTopics)
              _TopicChip(
                label: Topics.byId(id)?.shortName ?? id,
                onTap: () => onAsk('¿Qué dicen los datos sobre ${Topics.nameOf(id).toLowerCase()}?'),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionLabel('Prueba con'),
        const SizedBox(height: 10),
        JcvCard(
          onTap: () => onAsk(_sample),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  _sample,
                  style: TextStyle(
                    fontSize: 14,
                    height: 19 / 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Icon(CupertinoIcons.arrow_up_right, size: 16, color: AppColors.navy),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.grayBlue, width: 1.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 36,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: const BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              height: 21 / 15,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return const IconCircle(
      icon: CupertinoIcons.sparkles,
      size: 32,
      iconSize: 16,
      background: AppColors.raspberry,
      iconColor: AppColors.white,
    );
  }
}

const _assistantBubbleRadius = BorderRadius.only(
  topLeft: Radius.circular(4),
  topRight: Radius.circular(18),
  bottomLeft: Radius.circular(18),
  bottomRight: Radius.circular(18),
);

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble({required this.answer});

  final AssistantAnswer answer;

  @override
  Widget build(BuildContext context) {
    final figure = answer.figure;
    final topicId = answer.topicId;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(top: 4), child: _AssistantAvatar()),
        const SizedBox(width: 8),
        Expanded(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: _assistantBubbleRadius,
              boxShadow: AppColors.cardShadow,
            ),
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer.text,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navy,
                      ),
                    ),
                    if (figure != null) ...[
                      const SizedBox(height: 12),
                      _MiniComparison(figure: figure),
                    ],
                    if (topicId != null) ...[
                      const SizedBox(height: 12),
                      JcvButton(
                        label: 'Ver en Datos',
                        small: true,
                        expand: false,
                        variant: JcvButtonVariant.outline,
                        trailingIcon: CupertinoIcons.arrow_right,
                        onPressed: () {
                          context.read<DataFiltersProvider>().apply(
                                source: DataSource.comparison,
                                filters: DataFilters.none,
                              );
                          context.go(AppRoutes.comparison(topicId));
                        },
                      ),
                    ],
                  ],
                ),
              ),
          ),
        ),
      ],
    );
  }
}

class _MiniComparison extends StatelessWidget {
  const _MiniComparison({required this.figure});

  final AssistantFigure figure;

  @override
  Widget build(BuildContext context) {
    final maxValue = figure.amg > figure.tec ? figure.amg : figure.tec;
    Widget row(String label, double value, Color color) {
      return Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final available = constraints.maxWidth - 44;
                final width = maxValue > 0 ? value / maxValue * available : 0.0;
                return Row(
                  children: [
                    Container(
                      width: width < 2 ? 2.0 : width,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.percent(value),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      );
    }

    return Semantics(
      label: '${figure.caption}: AMG ${Formatters.percent(figure.amg)}, '
          'Tec ${Formatters.percent(figure.tec)}',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              figure.caption,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 10),
            row('AMG', figure.amg, AppColors.navy),
            const SizedBox(height: 8),
            row('Tec', figure.tec, AppColors.gold),
            const SizedBox(height: 8),
            Text(
              'AMG 2026 · n = ${Formatters.thousands(figure.nAmg)} · '
              'Tec · n = ${Formatters.thousands(figure.nTec)}',
              style: const TextStyle(
                fontSize: 10,
                height: 14 / 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'El asistente está pensando',
      child: const Row(
        children: [
          _AssistantAvatar(),
          SizedBox(width: 8),
          CupertinoActivityIndicator(radius: 9),
          SizedBox(width: 8),
          Text(
            'Buscando en los datos…',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.canSend,
    required this.onSend,
    required this.onMic,
  });

  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: Color(0x140E3B70), blurRadius: 20, offset: Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.only(left: 18, right: 4),
                  decoration: BoxDecoration(
                    color: AppColors.grayBlue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (canSend) onSend();
                          },
                          maxLength: 300,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            counterText: '',
                            hintText: 'Escribe tu pregunta',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Enviar',
                        onPressed: canSend ? onSend : null,
                        icon: Icon(
                          CupertinoIcons.arrow_up_circle_fill,
                          size: 28,
                          color: canSend ? AppColors.navy : AppColors.textDisabled,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: 'Hablar',
                excludeSemantics: true,
                child: Material(
                  color: AppColors.navy,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onMic,
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(CupertinoIcons.mic_fill, size: 22, color: AppColors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 5.2 Escuchando: círculos concéntricos, transcripción y botón de detener.
class _ListeningView extends StatelessWidget {
  const _ListeningView({required this.controller});

  final AssistantController controller;

  static const _waveHeights = <double>[12, 20, 32, 24, 40, 28, 18, 30, 14];

  @override
  Widget build(BuildContext context) {
    final transcript = controller.transcript;
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'Asistente IA',
            leading: HeaderLeading.close,
            onLeading: () => unawaited(controller.cancelListening()),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              child: Column(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 220,
                      height: 220,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.raspberry.withValues(alpha: 0.08),
                      ),
                      child: Container(
                        width: 170,
                        height: 170,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.raspberry.withValues(alpha: 0.14),
                        ),
                        child: const IconCircle(
                          icon: CupertinoIcons.mic_fill,
                          size: 120,
                          iconSize: 44,
                          background: AppColors.raspberry,
                          iconColor: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    liveRegion: true,
                    child: const Text(
                      'Escuchando…',
                      style: TextStyle(
                        fontSize: 26,
                        height: 32 / 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    transcript.isEmpty ? 'Habla con naturalidad' : '“$transcript”',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ExcludeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final h in _waveHeights)
                          Container(
                            width: 4,
                            height: h,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: AppColors.navy.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Semantics(
                    button: true,
                    label: 'Terminar y enviar',
                    excludeSemantics: true,
                    child: Material(
                      color: AppColors.navy,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => unawaited(controller.finishListening()),
                        child: const SizedBox(
                          width: 64,
                          height: 64,
                          child: Icon(CupertinoIcons.stop_fill, size: 22, color: AppColors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toca para terminar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
