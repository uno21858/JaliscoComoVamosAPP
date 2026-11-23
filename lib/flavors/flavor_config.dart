enum Flavor { dev, prod }

/// Configuración por flavor. Se inicializa una sola vez en main_dev/main_prod.
class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.showMockBanner,
    this.mockLatency = const Duration(milliseconds: 700),
    this.mockFailureRate = 0,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.cognitoUserPoolId = '',
    this.cognitoClientId = '',
    this.cognitoDomain = '',
  });

  final Flavor flavor;

  /// Supabase (proyecto CCL DEV, schema jcv), leídos del .env como en CCL.
  /// Vacíos (como en las pruebas): el asistente usa el mock.
  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Pool de Cognito de JCV (públicos: viajan en la app, como en CCL).
  /// Vacíos: no hay login y Encuestas usa el mock.
  final String cognitoUserPoolId;
  final String cognitoClientId;

  /// Hosted UI de Cognito (output HostedUiDomain). Vacío: sin Google.
  final String cognitoDomain;

  bool get hasCognito => cognitoUserPoolId.isNotEmpty && cognitoClientId.isNotEmpty;

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
