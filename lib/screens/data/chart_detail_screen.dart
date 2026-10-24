import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// 2.5 Detalle de gráfica: dona grande, resumen, fuente y acciones.
class ChartDetailScreen extends StatelessWidget {
  const ChartDetailScreen({super.key, required this.topicId, required this.chartId});

  final String topicId;
  final String chartId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GatedController<TopicChart>>(
      create: (context) {
        final repository = context.read<DataRepository>();
        final filters = context.read<DataFiltersProvider>();
        return GatedController<TopicChart>(
          loader: () => repository.getChart(
            chartId: chartId,
            source: filters.singleSource,
            filters: filters.filters,
          ),
          refreshOn: filters,
        );
      },
      child: _DetailView(topicId: topicId),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.topicId});

  final String topicId;

  Future<void> _share(BuildContext context, TopicChart chart, String meta) async {
    // TODO(fase 2): compartir con share_plus. Por ahora se copia el texto.
    final text = '${chart.title}\n${chart.summary}\n$meta\n'
        'Fuente: Encuesta de Bienestar de Jóvenes AMG 2026, Jalisco Cómo Vamos';
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiamos el dato y su fuente para que los compartas.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GatedController<TopicChart>>();
    final filters = context.watch<DataFiltersProvider>();
    final source = filters.singleSource;

    final Widget body = switch (controller.status) {
      ViewStatus.loading => const LoadingStateView(),
      ViewStatus.error => ConnectionErrorView(onRetry: () => unawaited(controller.load())),
      ViewStatus.tooFew => TooFewStateView(
          minSample: controller.minSample,
          onClearFilters: filters.clearFilters,
          onChangeFilters: () => unawaited(showFiltersSheet(context)),
        ),
      ViewStatus.ready => () {
          final chart = controller.data!;
          final meta = '${source.longLabel} · ${filters.filters.ageLabel} · '
              'n = ${Formatters.thousands(chart.n)}';
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TagPill(Topics.nameOf(topicId)),
              ),
              const SizedBox(height: 10),
              Semantics(
                header: true,
                child: Text(chart.title, style: AppTextStyles.stateTitle),
              ),
              const SizedBox(height: 6),
              Text(meta, style: AppTextStyles.caption),
              const SizedBox(height: 14),
              JcvCard(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: chart.kind == ChartKind.donut
                    ? Column(
                        children: [
                          DonutChart(
                            slices: chart.slices,
                            size: 180,
                            centerValue: Formatters.percent(chart.slices.first.percent),
                            centerLabel: chart.slices.first.label.toLowerCase(),
                            semanticLabel: describeSlices(chart.title, chart.slices),
                          ),
                          const SizedBox(height: 16),
                          ChartLegend(slices: chart.slices, columns: 2, fontSize: 12),
                        ],
                      )
                    : BarRows(slices: chart.slices, labelWidth: 110),
              ),
              const SizedBox(height: 14),
              SummaryCard(text: chart.summary),
              const SizedBox(height: 10),
              Text(
                source == DataSource.tec
                    ? 'Fuente: micro-encuesta a estudiantes del Tec, 2026. Muestra voluntaria.'
                    : 'Fuente: Encuesta de Bienestar de Jóvenes AMG 2026, Jalisco Cómo Vamos',
                style: const TextStyle(
                  fontSize: 11,
                  height: 16 / 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const MockDataBanner(padding: EdgeInsets.only(top: 12)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: JcvButton(
                      label: 'Compartir',
                      variant: JcvButtonVariant.outline,
                      leadingIcon: CupertinoIcons.square_arrow_up,
                      onPressed: () => unawaited(_share(context, chart, meta)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: JcvButton(
                      label: 'Informe',
                      variant: JcvButtonVariant.secondary,
                      leadingIcon: CupertinoIcons.arrow_down_doc,
                      onPressed: () => context.push(
                        Uri(path: AppRoutes.report, queryParameters: {'tema': topicId}).toString(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }(),
    };

    return Scaffold(
      body: Column(
        children: [
          const ScreenHeader(title: 'Detalle de gráfica'),
          Expanded(child: body),
        ],
      ),
    );
  }
}
