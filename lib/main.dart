import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';
import 'diagnostics_page.dart';
import 'recorder_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load your existing environment values (may be nullable)
  await Env.load();

  // Fallback to --dart-define if Env fields are null/empty
  final url = (Env.supabaseUrl ?? const String.fromEnvironment('SUPABASE_URL')).trim();
  final anon = (Env.supabaseAnonKey ?? const String.fromEnvironment('SUPABASE_ANON_KEY')).trim();

  if (url.isEmpty || anon.isEmpty) {
    // Fail early with a clear message instead of a cryptic crash
    throw Exception(
      'Supabase URL or anon key is missing.\n'
      'Provide them via Env.supabaseUrl / Env.supabaseAnonKey or --dart-define.',
    );
  }

  await Supabase.initialize(
    url: url,
    anonKey: anon,
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartVoiceNotes',
      debugShowCheckedModeBanner: false,
      home: const HomeGate(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/dev/diagnostics':
            return MaterialPageRoute(builder: (_) => const DiagnosticsPage());
          case '/dev/record':
            return MaterialPageRoute(builder: (_) => const RecorderPage());
          default:
            return MaterialPageRoute(builder: (_) => const HomeGate());
        }
      },
    );
  }
}

class HomeGate extends StatelessWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartVoiceNotes')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ENV: ${Env.appEnv}'),
            if (kDebugMode)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/dev/diagnostics'),
                child: const Text('Open Diagnostics (dev only)'),
              ),
            if (kDebugMode)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/dev/record'),
                child: const Text('Open Recorder (dev)'),
              ),
          ],
        ),
      ),
    );
  }
}
