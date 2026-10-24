import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/core.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/widgets.dart';

/// Abre la hoja de filtros (2.3). Devuelve la fuente aplicada, o null si se
/// cerró sin aplicar. Quien la abre decide si navega a la comparativa.
Future<DataSource?> showFiltersSheet(BuildContext context) {
  return showModalBottomSheet<DataSource>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: AppColors.white,
    barrierColor: AppColors.scrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const FiltersSheet(),
  );
}

class FiltersSheet extends StatefulWidget {
  const FiltersSheet({super.key});

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  late DataSource _source;
  late DataFilters _filters;
  MatchCount? _count;
  int _countRequest = 0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DataFiltersProvider>();
    _source = provider.source;
    _filters = provider.filters;
    _refreshCount(showLoading: false);
  }

  Future<void> _refreshCount({bool showLoading = true}) async {
    final request = ++_countRequest;
    if (showLoading) setState(() => _count = null);
    final result = await context.read<DataRepository>().countMatches(
          source: _source,
          filters: _filters,
        );
    if (!mounted || request != _countRequest) return;
    setState(() => _count = result.valueOrNull);
  }

  void _update({DataSource? source, DataFilters? filters}) {
    setState(() {
      _source = source ?? _source;
      _filters = filters ?? _filters;
    });
    _refreshCount();
  }

  void _apply() {
    context.read<DataFiltersProvider>().apply(source: _source, filters: _filters);
    Navigator.of(context).pop(_source);
  }

  String get _countText {
    final count = _count;
    if (count == null) return 'Contando respuestas…';
    if (count.belowThreshold) {
      return 'Menos de ${count.threshold} respuestas con estos filtros';
    }
    if (count.count == 0) return 'No se encontraron resultados';
    final noun = count.count == 1 ? 'respuesta' : 'respuestas';
    return '${Formatters.thousands(count.count)} $noun con estos filtros';
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetGrabber(),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: const Text(
                        'Filtros',
                        style: TextStyle(
                          fontSize: 20,
                          height: 26 / 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                  JcvTextButton(
                    label: 'Limpiar',
                    underline: true,
                    onPressed: () => _update(filters: DataFilters.none),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _GroupLabel('Fuente'),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<DataSource>(
                  groupValue: _source,
                  backgroundColor: AppColors.grayBlue,
                  thumbColor: AppColors.white,
                  padding: const EdgeInsets.all(3),
                  onValueChanged: (value) {
                    if (value != null) _update(source: value);
                  },
                  children: {
                    for (final source in DataSource.values)
                      source: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          source.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: source == _source ? FontWeight.w800 : FontWeight.w600,
                            color: source == _source ? AppColors.navy : AppColors.navyDark,
                          ),
                        ),
                      ),
                  },
                ),
              ),
              const SizedBox(height: 16),
              const _GroupLabel('Municipio'),
              EvenGrid(
                columns: 3,
                children: [
                  for (final option in FilterCatalog.municipalities)
                    SelectChip(
                      label: option.label,
                      selected: _filters.municipality == option.code,
                      onTap: () => _update(
                        filters: _filters.withMunicipality(
                          _filters.municipality == option.code ? null : option.code,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const _GroupLabel('Rango de edad'),
              EvenGrid(
                columns: 3,
                children: [
                  for (final option in FilterCatalog.ageGroups)
                    SelectChip(
                      label: option.label,
                      selected: _filters.ageGroup == option.code,
                      onTap: () => _update(
                        filters: _filters.withAgeGroup(
                          _filters.ageGroup == option.code ? null : option.code,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const _GroupLabel('Sexo'),
              EvenGrid(
                columns: 3,
                children: [
                  SelectChip(
                    label: 'Todos',
                    selected: _filters.sex == null,
                    onTap: () => _update(filters: _filters.withSex(null)),
                  ),
                  for (final option in FilterCatalog.sexes)
                    SelectChip(
                      label: option.label,
                      selected: _filters.sex == option.code,
                      onTap: () => _update(filters: _filters.withSex(option.code)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const _GroupLabel('Estrato socioeconómico'),
              EvenGrid(
                columns: 4,
                children: [
                  SelectChip(
                    label: 'Todos',
                    selected: _filters.stratum == null,
                    onTap: () => _update(filters: _filters.withStratum(null)),
                  ),
                  for (final option in FilterCatalog.strata)
                    SelectChip(
                      label: option.label,
                      selected: _filters.stratum == option.code,
                      onTap: () => _update(filters: _filters.withStratum(option.code)),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.info, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _countText,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_source != DataSource.amg) ...[
                const SizedBox(height: 8),
                const Text(
                  'En los datos del Tec solo se pueden ver grupos de 30 respuestas o más, '
                  'para proteger la privacidad.',
                  style: AppTextStyles.caption,
                ),
              ],
              const SizedBox(height: 28),
              JcvButton(label: 'Aplicar filtros', onPressed: _apply),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.fieldLabel),
    );
  }
}
