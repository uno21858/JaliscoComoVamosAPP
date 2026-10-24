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
import 'widgets/chart_cards.dart';
import 'widgets/filters_sheet.dart';

/// 2.2 Temática, con sus estados 2.8 (cargando), 2.9 (sin datos) y 2.10
/// (sin conexión).
class TopicScreen extends StatelessWidget {
  const TopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GatedController<TopicCharts>>(
      create: (context) {
        final repository = context.read<DataRepository>();
        final filters = context.read<DataFiltersProvider>();
        return GatedController<TopicCharts>(
          loader: () => repository.getTopicCharts(
            topicId: topicId,
            source: filters.singleSource,
            filters: filters.filters,
          ),
          refreshOn: filters,
        );
      },
      child: _TopicView(topicId: topicId),
    );
  }
}

/// Abre los filtros y, si se eligió "Comparativa", navega a 2.4.
Future<void> openFiltersFor(BuildContext context, String topicId) async {
  final source = await showFiltersSheet(context);
  if (!context.mounted || source != DataSource.comparison) return;
  unawaited(context.push(AppRoutes.comparison(topicId)));
}

class _TopicView extends StatelessWidget {
  const _TopicView({required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GatedController<TopicCharts>>();
    final filters = context.watch<DataFiltersProvider>();
    final pills = PillRow(
      first: filters.singleSource.chipLabel,
      others: filters.filters.chipLabels,
    );

    final Widget body = switch (controller.status) {
      ViewStatus.loading => const LoadingStateView(),
      ViewStatus.error => Column(
          children: [
            const SizedBox(height: 14),
            pills,
            Expanded(
              child: ConnectionErrorView(onRetry: () => unawaited(controller.load())),
            ),
          ],
        ),
      ViewStatus.tooFew => Column(
          children: [
            const SizedBox(height: 14),
            pills,
            Expanded(
              child: TooFewStateView(
                minSample: controller.minSample,
                onClearFilters: filters.clearFilters,
                onChangeFilters: () => unawaited(openFiltersFor(context, topicId)),
              ),
            ),
          ],
        ),
      ViewStatus.ready => _ChartsList(
          topicId: topicId,
          data: controller.data!,
          pills: pills,
        ),
    };

    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: Topics.nameOf(topicId),
            trailing: HeaderIconButton(
              icon: CupertinoIcons.slider_horizontal_3,
              tooltip: 'Filtros',
              onPressed: () => unawaited(openFiltersFor(context, topicId)),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _ChartsList extends StatelessWidget {
  const _ChartsList({required this.topicId, required this.data, required this.pills});

  final String topicId;
  final TopicCharts data;
  final Widget pills;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 14, bottom: 24),
      children: [
        pills,
        const SizedBox(height: 14),
        const MockDataBanner(padding: EdgeInsets.fromLTRB(20, 0, 20, 14)),
        if (data.isSmallSample)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: NoticeBox(
              icon: CupertinoIcons.exclamationmark_circle_fill,
              iconColor: AppColors.wine,
              background: AppColors.errorBackground,
              text: 'Muestra pequeña: interpreta con cuidado.',
            ),
          ),
        if (data.charts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Esta temática todavía no tiene gráficas para esta fuente.',
              style: AppTextStyles.body,
            ),
          ),
        for (final chart in data.charts)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: TopicChartCard(
              chart: chart,
              onDetail: () => context.push(AppRoutes.chart(topicId, chart.id)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: JcvButton(
            label: 'Comparar AMG vs Tec',
            variant: JcvButtonVariant.outline,
            onPressed: () {
              context.read<DataFiltersProvider>().setSource(DataSource.comparison);
              context.push(AppRoutes.comparison(topicId));
            },
          ),
        ),
      ],
    );
  }
}
