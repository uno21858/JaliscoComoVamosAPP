import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';

/// Recuadro gris "En pocas palabras: ..." dentro de una tarjeta.
class PlainSummaryBox extends StatelessWidget {
  const PlainSummaryBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'En pocas palabras: ',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: text),
          ],
        ),
        style: const TextStyle(
          fontSize: 12,
          height: 18 / 12,
          fontWeight: FontWeight.w500,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

/// Tarjeta "En pocas palabras" suelta (2.4, 2.5).
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return JcvCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'En pocas palabras',
            style: TextStyle(
              fontSize: 13,
              height: 17 / 13,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 19 / 13,
              fontWeight: FontWeight.w500,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gráfica de una temática dentro de su tarjeta (2.2).
class TopicChartCard extends StatelessWidget {
  const TopicChartCard({super.key, required this.chart, required this.onDetail});

  final TopicChart chart;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final subtitle = chart.subtitle;
    final first = chart.slices.first;
    return JcvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chart.title, style: AppTextStyles.cardTitle),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.caption),
          ],
          const SizedBox(height: 12),
          if (chart.kind == ChartKind.donut)
            Row(
              children: [
                DonutChart(
                  slices: chart.slices,
                  size: 120,
                  centerValue: Formatters.percent(first.percent),
                  centerLabel: first.label.toLowerCase(),
                  semanticLabel: describeSlices(chart.title, chart.slices),
                ),
                const SizedBox(width: 14),
                Expanded(child: ChartLegend(slices: chart.slices)),
              ],
            )
          else
            BarRows(slices: chart.slices),
          const SizedBox(height: 12),
          PlainSummaryBox(text: chart.summary),
          Align(
            alignment: Alignment.centerRight,
            child: ChevronLink(label: 'Ver detalle', onPressed: onDetail),
          ),
        ],
      ),
    );
  }
}
