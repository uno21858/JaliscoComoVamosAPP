import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/core.dart';
import '../../core/router/app_routes.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'widgets/filters_sheet.dart';

/// 2.6 Generar informe: temáticas, filtros y resúmenes sencillos.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.initialTopicId});

  final String? initialTopicId;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final Set<String> _selected = {};
  bool _plainSummaries = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTopicId;
    if (initial != null && Topics.byId(initial) != null) _selected.add(initial);
  }

  void _toggle(String topicId) {
    setState(() {
      if (!_selected.remove(topicId)) _selected.add(topicId);
    });
  }

  void _preview(DataFiltersProvider filters) {
    final request = ReportRequest(
      // Mismo orden que la rejilla, no el orden en que se tocaron.
      topicIds: [
        for (final topic in Topics.all)
          if (_selected.contains(topic.id)) topic.id,
      ],
      source: filters.source,
      filters: filters.filters,
      plainSummaries: _plainSummaries,
    );
    context.push(AppRoutes.reportPreview, extra: request);
  }

  @override
  Widget build(BuildContext context) {
    final filters = context.watch<DataFiltersProvider>();
    return Scaffold(
      body: Column(
        children: [
          const ScreenHeader(title: 'Generar informe'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text(
                  'Elige qué incluir y te armamos un PDF con gráficas y resúmenes sencillos.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(child: Text('Temáticas', style: AppTextStyles.fieldLabel)),
                    Text(
                      '${_selected.length} de ${Topics.all.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                EvenGrid(
                  columns: 2,
                  spacing: 12,
                  children: [
                    for (final topic in Topics.all)
                      _CheckTile(
                        label: topic.name,
                        checked: _selected.contains(topic.id),
                        onTap: () => _toggle(topic.id),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Filtros del informe', style: AppTextStyles.fieldLabel),
                    ),
                    JcvTextButton(
                      label: 'Editar',
                      onPressed: () => unawaited(showFiltersSheet(context)),
                    ),
                  ],
                ),
                JcvCard(
                  radius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Fuente', value: filters.source.longLabel),
                      const SizedBox(height: 6),
                      _SummaryRow(label: 'Municipio', value: filters.filters.municipalityLabel),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Edad · sexo · estrato',
                        value: filters.filters.ageSexStratumSummary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MergeSemantics(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Incluir resúmenes en lenguaje sencillo',
                          style: TextStyle(
                            fontSize: 13,
                            height: 17 / 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CupertinoSwitch(
                        value: _plainSummaries,
                        activeTrackColor: AppColors.navy,
                        onChanged: (value) => setState(() => _plainSummaries = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                JcvButton(
                  label: 'Ver vista previa',
                  onPressed: _selected.isEmpty ? null : () => _preview(filters),
                ),
                if (_selected.isEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Elige al menos una temática.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.label, required this.checked, required this.onTap});

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: checked ? AppColors.navy : AppColors.grayBlue,
            width: checked ? 2 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  _Checkbox(checked: checked),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 15 / 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? AppColors.navy : AppColors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: checked ? AppColors.navy : AppColors.textSecondary,
          width: 1.5,
        ),
      ),
      child: checked
          ? const Icon(CupertinoIcons.checkmark_alt, size: 14, color: AppColors.white)
          : null,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
      ],
    );
  }
}
