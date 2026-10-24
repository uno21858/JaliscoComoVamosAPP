enum Flavor { dev, prod }

/// Configuración por flavor. Se inicializa una sola vez en main_dev/main_prod.
class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.useMocks,
    required this.showMockBanner,
    this.mockLatency = const Duration(milliseconds: 700),
    this.mockFailureRate = 0,
  });

  final Flavor flavor;

  /// true: los repositorios usan los servicios de lib/services/mock.
  final bool useMocks;

  /// Muestra la etiqueta "Datos de ejemplo" para que nadie confunda los
  /// números sintéticos con resultados reales en una demo.
  final bool showMockBanner;

  /// Retardo artificial de los mocks, para ver los estados de carga.
  final Duration mockLatency;

  /// Probabilidad (0 a 1) de que un mock falle como si no hubiera conexión.
  /// Súbelo a 0.3 para probar la pantalla 2.10 y los reintentos.
  final double mockFailureRate;

  bool get isDev => flavor == Flavor.dev;

  static FlavorConfig? _instance;

  static FlavorConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError('FlavorConfig.init() no se llamó antes de runApp');
    }
    return config;
  }

  static void init(FlavorConfig config) {
    _instance = config;
  }
}
