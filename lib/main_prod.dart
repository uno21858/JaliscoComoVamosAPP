import 'package:flutter/widgets.dart';

import 'app.dart';
import 'flavors/flavor_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO(backend): cambiar useMocks a false cuando existan los servicios de
  // Supabase. Mientras tanto prod también usa mocks, pero sin el aviso visual.
  FlavorConfig.init(
    const FlavorConfig(
      flavor: Flavor.prod,
      useMocks: true,
      showMockBanner: false,
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    ),
  );
  runApp(const JcvApp());
}
