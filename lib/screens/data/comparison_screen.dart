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

/// 2.4 Comparativa AMG vs Tec de una temática.
class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GatedController<ComparisonData>>(
      create: (context) {
        final repository = context.read<DataRepository>();
        final filters = context.read<DataFiltersProvider>();
        return GatedController<ComparisonData>(
          loader: () => repository.getComparison(topicId: topicId, filters: filters.filters),
          refreshOn: filters,
        );
      },
      child: _ComparisonView(topicId: topicId),
    );
  }
}

class _ComparisonView extends StatelessWidget {
  const _ComparisonView({required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GatedController<ComparisonData>>();
    final filters = context.watch<DataFiltersProvider>();
    final pills = PillRow(
      first: DataSource.comparison.chipLabel,
      others: filters.filters.chipLabels,
    );

    final Widget body = switch (controller.status) {
      ViewStatus.loading => const LoadingStateView(),
      ViewStatus.error => ConnectionErrorView(onRetry: () => unawaited(controller.load())),
      ViewStatus.tooFew => Column(
          children: [
            const SizedBox(height: 14),
            pills,
            Expanded(
              child: TooFewStateView(
                minSample: controller.minSample,
                onClearFilters: filters.clearFilters,
                onChangeFilters: () => unawaited(_openFilters(context)),
              ),
            ),
          ],
        ),
      ViewStatus.ready => _ComparisonList(
          topicId: topicId,
          data: controller.data!,
          pills: pills,
        ),
    };

    // Al salir de la comparativa, la fuente vuelve a AMG para que la hoja
    // de filtros y la temática digan lo mismo.
    final filtersProvider = context.read<DataFiltersProvider>();
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && filtersProvider.source == DataSource.comparison) {
          filtersProvider.setSource(DataSource.amg);
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            ScreenHeader(
              title: 'AMG vs Tec',
              trailing: HeaderIconButton(
                icon: CupertinoIcons.slider_horizontal_3,
                tooltip: 'Filtros',
                onPressed: () => unawaited(_openFilters(context)),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  /// Si en los filtros se elige AMG o Tec, se regresa a la temática.
  Future<void> _openFilters(BuildContext context) async {
    final source = await showFiltersSheet(context);
    if (!context.mounted || source == null || source == DataSource.comparison) return;
    if (context.canPop()) context.pop();
  }
}

class _ComparisonList extends StatelessWidget {
  const _ComparisonList({required this.topicId, required this.data, required this.pills});

  final String topicId;
  final ComparisonData data;
  final Widget pills;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 14, bottom: 24),
      children: [
        pills,
        const SizedBox(height: 14),
        const MockDataBanner(padding: EdgeInsets.fromLTRB(20, 0, 20, 14)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: JcvCard(
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: SeriesKey(
                    color: AppColors.navy,
                    title: 'AMG 2026',
                    subtitle: 'n = ${Formatters.thousands(data.nAmg)}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SeriesKey(
                    color: AppColors.gold,
                    title: 'Estudiantes Tec',
                    subtitle: 'n = ${Formatters.thousands(data.nTec)}',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final chart in data.charts) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: JcvCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chart.title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 14),
                  ComparisonBars(rows: chart.rows),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ChevronLink(
                      label: 'Ver detalle',
                      onPressed: () => context.push(AppRoutes.chart(topicId, chart.id)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (data.charts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SummaryCard(text: data.charts.first.summary),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            'La muestra Tec es voluntaria y no representa a todos los estudiantes. '
            'Del lado AMG se usa el mismo rango de edad que la muestra Tec.',
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}
