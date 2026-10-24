import 'package:flutter/foundation.dart';

class FilterOption {
  const FilterOption(this.code, this.label);
  final String code;
  final String label;
}

/// Opciones de filtro del wireflow (2.3). Los códigos siguen el diccionario
/// del SRS; confirmar con JCV las categorías reales del archivo AMG.
abstract final class FilterCatalog {
  static const municipalities = <FilterOption>[
    FilterOption('GDL', 'Guadalajara'),
    FilterOption('ZAP', 'Zapopan'),
    FilterOption('TLQ', 'Tlaquepaque'),
    FilterOption('TON', 'Tonalá'),
    FilterOption('TLJ', 'Tlajomulco'),
    FilterOption('ELS', 'El Salto'),
  ];

  static const ageGroups = <FilterOption>[
    FilterOption('15-19', '15–19'),
    FilterOption('20-24', '20–24'),
    FilterOption('25-29', '25–29'),
  ];

  /// "Todos" se representa con null.
  static const sexes = <FilterOption>[
    FilterOption('F', 'Mujeres'),
    FilterOption('M', 'Hombres'),
  ];

  /// "Todos" se representa con null.
  static const strata = <FilterOption>[
    FilterOption('BAJO', 'Bajo'),
    FilterOption('MEDIO', 'Medio'),
    FilterOption('ALTO', 'Alto'),
  ];

  static String? labelOf(List<FilterOption> options, String? code) {
    if (code == null) return null;
    for (final option in options) {
      if (option.code == code) return option.label;
    }
    return null;
  }
}

/// Filtros demográficos. null en un campo significa "todos".
@immutable
class DataFilters {
  const DataFilters({this.municipality, this.ageGroup, this.sex, this.stratum});

  static const none = DataFilters();

  final String? municipality;
  final String? ageGroup;
  final String? sex;
  final String? stratum;

  bool get isEmpty =>
      municipality == null && ageGroup == null && sex == null && stratum == null;

  int get activeCount => [municipality, ageGroup, sex, stratum]
      .where((value) => value != null)
      .length;

  DataFilters withMunicipality(String? code) => DataFilters(
      municipality: code, ageGroup: ageGroup, sex: sex, stratum: stratum);

  DataFilters withAgeGroup(String? code) => DataFilters(
      municipality: municipality, ageGroup: code, sex: sex, stratum: stratum);

  DataFilters withSex(String? code) => DataFilters(
      municipality: municipality, ageGroup: ageGroup, sex: code, stratum: stratum);

  DataFilters withStratum(String? code) => DataFilters(
      municipality: municipality, ageGroup: ageGroup, sex: sex, stratum: code);

  String get municipalityLabel =>
      FilterCatalog.labelOf(FilterCatalog.municipalities, municipality) ??
      'Todos los municipios';

  /// "20 a 24 años" o "15 a 29 años" sin filtro.
  String get ageLabel {
    final code = ageGroup;
    if (code == null) return '15 a 29 años';
    final parts = code.split('-');
    return '${parts.first} a ${parts.last} años';
  }

  String get sexLabel => FilterCatalog.labelOf(FilterCatalog.sexes, sex) ?? 'Todos';

  String get stratumLabel =>
      FilterCatalog.labelOf(FilterCatalog.strata, stratum) ?? 'Todos';

  /// Chips blancos que van después del chip de fuente (2.2, 2.4, 2.9).
  List<String> get chipLabels => [
        municipalityLabel,
        ageLabel,
        if (sex != null) sexLabel,
        if (stratum != null) 'Estrato ${stratumLabel.toLowerCase()}',
      ];

  /// "20 a 24 · Todos · Todos" para el resumen del informe (2.6).
  String get ageSexStratumSummary {
    final age = ageGroup == null ? 'Todas' : ageLabel.replaceAll(' años', '');
    return '$age · $sexLabel · $stratumLabel';
  }

  @override
  bool operator ==(Object other) =>
      other is DataFilters &&
      other.municipality == municipality &&
      other.ageGroup == ageGroup &&
      other.sex == sex &&
      other.stratum == stratum;

  @override
  int get hashCode => Object.hash(municipality, ageGroup, sex, stratum);
}
