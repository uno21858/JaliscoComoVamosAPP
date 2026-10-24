import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../models/chart.dart';
import 'view_status.dart';

/// Carga un dato protegido por el umbral de muestra (Gated) y expone los
/// cuatro estados de las pantallas de Datos: cargando (2.8), listo, sin
/// suficientes respuestas (2.9) y error de conexión (2.10).
///
/// Si se pasa [refreshOn] (por ejemplo DataFiltersProvider), recarga solo
/// cuando cambian los filtros.
class GatedController<T> extends ChangeNotifier {
  GatedController({
    required Future<Result<Gated<T>>> Function() loader,
    this.refreshOn,
  }) : _loader = loader {
    refreshOn?.addListener(_onRefresh);
    unawaited(load());
  }

  final Future<Result<Gated<T>>> Function() _loader;
  final Listenable? refreshOn;

  ViewStatus _status = ViewStatus.loading;
  T? _data;
  int _minSample = 0;
  String _errorMessage = '';
  int _requestId = 0;
  bool _disposed = false;

  ViewStatus get status => _status;
  T? get data => _data;
  int get minSample => _minSample;
  String get errorMessage => _errorMessage;

  void _onRefresh() => unawaited(load());

  Future<void> load() async {
    final requestId = ++_requestId;
    _status = ViewStatus.loading;
    notifyListeners();

    final result = await _loader();
    // Si llegó otra petición mientras tanto, esta respuesta ya no sirve.
    if (_disposed || requestId != _requestId) return;

    switch (result) {
      case Ok(value: Enough(:final data)):
        _data = data;
        _status = ViewStatus.ready;
      case Ok(value: TooFew(:final minSample)):
        _data = null;
        _minSample = minSample;
        _status = ViewStatus.tooFew;
      case Err(:final failure):
        _errorMessage = failure.message;
        _status = ViewStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    refreshOn?.removeListener(_onRefresh);
    super.dispose();
  }
}
