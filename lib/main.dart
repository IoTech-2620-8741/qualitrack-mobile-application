import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependency_injection/injection.dart';
import 'iam/application/session_controller.dart';
import 'shared/infrastructure/configuration/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  final config = sl<ApiConfig>();
  if (!config.isConfigured) {
    runApp(const _MissingConfigurationApp());
    return;
  }
  runApp(QualiTrackApp(session: sl<SessionController>()));
}

/// Shown when the app was built without `--dart-define=API_BASE_URL=...`.
/// There is intentionally no hardcoded fallback URL.
class _MissingConfigurationApp extends StatelessWidget {
  const _MissingConfigurationApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'API_BASE_URL is not configured.\n\n'
              'Run: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
