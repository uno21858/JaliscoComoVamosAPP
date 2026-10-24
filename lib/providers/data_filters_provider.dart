import 'package:flutter/foundation.dart';

import '../models/data_filters.dart';
import '../models/data_source.dart';

/// Fuente y filtros activos de la pestaña Datos. Viven a nivel app para que
/// se conserven al cambiar de temática.
class DataFiltersProvider extends ChangeNotifier {
  DataSource _source = DataSource.amg;
  DataFilters _filters = DataFilters.none;

  DataSource get source => _source;
  DataFilters get filters => _filters;

  /// Fuente para pantallas que no son la comparativa (2.2, 2.5).
  DataSource get singleSource => _source == DataSource.tec ? DataSource.tec : DataSource.amg;

  void apply({required DataSource source, required DataFilters filters}) {
    if (source == _source && filters == _filters) return;
    _source = source;
    _filters = filters;
    notifyListeners();
  }

  void setSource(DataSource source) {
    if (source == _source) return;
    _source = source;
    notifyListeners();
  }

  /// "Quitar filtros" de 2.9: deja la fuente, quita lo demográfico.
  void clearFilters() {
    if (_filters.isEmpty) return;
    _filters = DataFilters.none;
    notifyListeners();
  }
}
