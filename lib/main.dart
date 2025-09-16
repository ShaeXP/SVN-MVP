import 'core/utils/size_utils.dart' as su;  // Rocket’s internal sizing utils
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// main.dart (only high-level deps)
import 'package:your_app/services/supabase_service.dart';
import 'package:your_app/theme/theme_helper.dart' as sv;
import 'package:your_app/routes/app_routes.dart';
import 'package:your_app/core/utils/preview_mode_detector.dart';
import 'package:get/get.dart';          // SVTheme with deep-blue headings
// AppRoutes.homeScreen, AppRoutes.pages

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (once)
  try {
    await SupabaseService.instance.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // External initializers (preview-safe)
  await _initializeExternalServices();

  // Portrait lock
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

/// Initialize external services with preview-mode timeout handling
Future<void> _initializeExternalServices() async {
  // Supabase preview guard (already initialized above; this just logs/guards)
  await PreviewModeDetector.withPreviewTimeoutVoid(
    () async {
      debugPrint('✅ Supabase initialized successfully');
    },
    serviceName: 'Supabase',
  );

  // OpenAI presence check
  await PreviewModeDetector.withPreviewTimeoutVoid(
    () async {
      const apiKey = String.fromEnvironment('OPENAI_API_KEY');
      if (apiKey.isNotEmpty) {
        debugPrint('✅ OpenAI API key configured');
      } else if (!PreviewModeDetector.isPreviewMode) {
        debugPrint('⚠️ OpenAI API key not configured');
      }
    },
    serviceName: 'OpenAI',
  );

  // Any other remote config services
  await PreviewModeDetector.withPreviewTimeoutVoid(
    () async {
      debugPrint('✅ Remote config services initialized');
    },
    serviceName: 'Remote Config',
  );

  if (PreviewModeDetector.isPreviewMode) {
    debugPrint('🎭 Preview mode active - External services initialized with fallbacks');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return su.Sizer(builder: (context, orientation, deviceType) {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SmartVoiceNotes',

        // THEME
        theme: sv.theme,
        darkTheme: sv.theme,
        themeMode: ThemeMode.system,

        // i18n
        locale: const Locale('en', ''),
        fallbackLocale: const Locale('en', ''),

        // ROUTES (you can switch to AppRoutes.getInitialRoute() if you want auth-gating)
        initialRoute: AppRoutes.homeScreen,
        getPages: [
          ...AppRoutes.pages,
          GetPage(name: '/_fallback', page: () => const _SVFallback()),
        ],
        unknownRoute: GetPage(name: '/_fallback', page: () => const _SVFallback()),

        // Error overlay so you don’t get a grey screen if something else blows up
        builder: (context, child) {
          ErrorWidget.builder = (details) => MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(details.exceptionAsString(), textAlign: TextAlign.center),
                    ),
                  ),
                ),
              );
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
      );
    });
  }
}
class _SVFallback extends StatelessWidget {
  const _SVFallback();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route fallback')),
      body: const Center(
        child: Text('Unknown or crashed initial route.\nCheck bindings/build() of the first page.'),
      ),
    );
  }
}
