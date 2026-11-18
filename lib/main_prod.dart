import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'flavors/flavor_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ponytail: prod lee el mismo .env que dev mientras JCV no tenga proyecto
  // de Supabase propio. Cuando lo tenga: .env.prod, como en CCL.
  await dotenv.load(fileName: '.env');
  FlavorConfig.init(
    FlavorConfig(
      flavor: Flavor.prod,
      showMockBanner: false,
      supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    ),
  );
  runApp(const JcvApp());
}
