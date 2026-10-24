import 'dart:math';

import '../../core/app_error.dart';
import '../../flavors/flavor_config.dart';

final _random = Random();

/// Simula la latencia de red y, si se configuró, fallas de conexión.
Future<void> simulateNetwork() async {
  final config = FlavorConfig.instance;
  await Future<void>.delayed(config.mockLatency);
  if (config.mockFailureRate > 0 && _random.nextDouble() < config.mockFailureRate) {
    throw const NetworkError();
  }
}
