import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'flavors/flavor_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Como en CCL. El .env no está en git: pídelo al equipo (ver .env.example).
  await dotenv.load(fileName: '.env');
  FlavorConfig.init(
    FlavorConfig(
      flavor: Flavor.dev,
      showMockBanner: true,
      supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      cognitoUserPoolId: dotenv.env['COGNITO_USER_POOL_ID'] ?? '',
      cognitoClientId: dotenv.env['COGNITO_CLIENT_ID'] ?? '',
      cognitoDomain: dotenv.env['COGNITO_DOMAIN'] ?? '',
    ),
  );
  runApp(const JcvApp());
}
