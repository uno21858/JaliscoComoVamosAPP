import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/core.dart';
import '../../core/router/app_routes.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../widgets/widgets.dart';

/// 1.2 Inicio: saludo, accesos rápidos y hallazgos destacados.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Result<List<Highlight>>> _highlights;

  @override
  void initState() {
    super.initState();
    _highlights = context.read<DataRepository>().getHighlights();
  }

  void _retry() {
    setState(() {
      _highlights = context.read<DataRepository>().getHighlights();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        const RootHeader(
          title: '¡Hola!',
          subtitle: 'Descubre cómo viven los jóvenes del AMG',
          showMark: true,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 20, bottom: 24),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SectionLabel('Accesos rápidos'),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _QuickAccessCard(
                      icon: CupertinoIcons.chart_bar,
                      iconBackground: AppColors.lime,
                      title: 'Explorar datos',
                      subtitle: 'Gráficas de las 8 temáticas',
                      onTap: () => context.go(AppRoutes.data),
                    ),
                    const SizedBox(height: 12),
                    _QuickAccessCard(
                      icon: CupertinoIcons.doc_text,
                      iconBackground: AppColors.gold,
                      title: 'Responder encuestas',
                      subtitle: 'Para estudiantes del Tec',
                      onTap: () => context.go(AppRoutes.surveys),
                    ),
                    const SizedBox(height: 12),
                    _QuickAccessCard(
                      icon: CupertinoIcons.heart,
                      iconBackground: AppColors.raspberry,
                      iconColor: AppColors.white,
                      title: 'Donar a JCV',
                      subtitle: 'Apoya al observatorio ciudadano',
                      onTap: () => context.go(AppRoutes.donate),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 8),
                child: Row(
                  children: [
                    const Expanded(child: SectionLabel('Hallazgos destacados')),
                    JcvTextButton(
                      label: 'Ver todos',
                      onPressed: () => context.go(AppRoutes.data),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              FutureBuilder<Result<List<Highlight>>>(
                future: _highlights,
                builder: (context, snapshot) {
                  final result = snapshot.data;
                  if (result == null) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  }
                  return switch (result) {
                    Ok(:final value) => _HighlightsCarousel(highlights: value),
                    Err() => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: JcvCard(
                          onTap: _retry,
                          child: const Row(
                            children: [
                              Icon(CupertinoIcons.wifi_slash, color: AppColors.raspberry),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No pudimos cargar los hallazgos. Toca para reintentar.',
                                  style: AppTextStyles.body,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  };
                },
              ),
              const SizedBox(height: 12),
              const MockDataBanner(),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = AppColors.navy,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return JcvCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          IconCircle(
            icon: icon,
            size: 44,
            iconSize: 22,
            background: iconBackground,
            iconColor: iconColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 20 / 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.navy),
        ],
      ),
    );
  }
}

class _HighlightsCarousel extends StatefulWidget {
  const _HighlightsCarousel({required this.highlights});

  final List<Highlight> highlights;

  @override
  State<_HighlightsCarousel> createState() => _HighlightsCarouselState();
}

class _HighlightsCarouselState extends State<_HighlightsCarousel> {
  final _controller = PageController(viewportFraction: 0.78);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.highlights;
    return Column(
      children: [
        SizedBox(
          height: 208,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: items.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 20 : 6,
                right: index == items.length - 1 ? 20 : 6,
                top: 4,
                bottom: 4,
              ),
              child: _HighlightCard(highlight: items[index]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.navy : AppColors.grayBlue,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.highlight});

  final Highlight highlight;

  @override
  Widget build(BuildContext context) {
    final (background, ink, tagBackground) = switch (highlight.style) {
      HighlightStyle.gold => (AppColors.gold, AppColors.navy, AppColors.white.withValues(alpha: 0.6)),
      HighlightStyle.navy => (AppColors.navy, AppColors.white, AppColors.white.withValues(alpha: 0.16)),
      HighlightStyle.lime => (AppColors.lime, AppColors.navy, AppColors.white.withValues(alpha: 0.6)),
    };
    final percent = Formatters.percent(highlight.percent);
    return Semantics(
      button: true,
      label: '${highlight.tag}. $percent ${highlight.text}. Ver gráfica.',
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go(AppRoutes.chart(highlight.topicId, highlight.chartId)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TagPill(highlight.tag, color: tagBackground, textColor: ink),
                const SizedBox(height: 12),
                Text(
                  percent,
                  style: TextStyle(
                    fontSize: 44,
                    height: 48 / 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.88,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    highlight.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 19 / 14,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'AMG 2026 · Ver gráfica',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ink),
                    ),
                    const SizedBox(width: 6),
                    Icon(CupertinoIcons.arrow_right, size: 14, color: ink),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
