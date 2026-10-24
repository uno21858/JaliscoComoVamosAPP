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
    ),
  );
  runApp(const JcvApp());
}
