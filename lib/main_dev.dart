import 'package:flutter/widgets.dart';

import 'app.dart';
import 'flavors/flavor_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.init(
    const FlavorConfig(
      flavor: Flavor.dev,
      useMocks: true,
      showMockBanner: true,
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    ),
  );
  runApp(const JcvApp());
}
