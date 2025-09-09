import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './core/utils/preview_mode_detector.dart';
import './services/supabase_service.dart';
import 'core/app_export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🎯 Preview Mode Detection & External Initializers with Timeout
  await _initializeExternalServices();

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    value,
  ) {
    runApp(MyApp());
  });
}

/// Initialize external services with preview mode timeout handling
Future<void> _initializeExternalServices() async {
  // Initialize Supabase with preview mode timeout
  await PreviewModeDetector.withPreviewTimeoutVoid(
    () async {
      await SupabaseService.instance.initialize();
      debugPrint('✅ Supabase initialized successfully');
    },
    serviceName: 'Supabase',
  );

  // Initialize OpenAI service with preview mode timeout
  await PreviewModeDetector.withPreviewTimeoutVoid(
    () async {
      // OpenAI service auto-initializes, just verify API key exists
      const apiKey = String.fromEnvironment('OPENAI_API_KEY');
      if (apiKey.isNotEmpty) {
        debugPrint('✅ OpenAI API key configured');
      } else if (!PreviewModeDetector.isPreviewMode) {
        debugPrint('⚠️ OpenAI API key not configured');
      }
    },
    serviceName: 'OpenAI',
  );

  // Initialize any other remote config services here
  await PreviewModeDetector.withPreviewTimeoutVoid(
    () async {
      // Add any other remote configuration initialization here
      // Example: Firebase Remote Config, Analytics, etc.
      debugPrint('✅ Remote config services initialized');
    },
    serviceName: 'Remote Config',
  );

  if (PreviewModeDetector.isPreviewMode) {
    debugPrint(
        '🎭 Preview mode active - External services initialized with fallbacks');
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: Locale('en', ''),
          fallbackLocale: Locale('en', ''),
          title: 'lashae_s_application',
          // PREVIEW HEALTH CHECK - SET AS INITIAL ROUTE FOR TESTING
          initialRoute: AppRoutes
              .previewHealthCheckScreen, // Health check screen for preview testing
          // NORMAL ROUTES (COMMENTED FOR PREVIEW TESTING)
          // initialRoute: AppRoutes.getInitialRoute(), // Dynamic initial route based on auth state
          // initialRoute: AppRoutes.recordingReadyScreenInitialPage, // Force directory screen for preview testing
          getPages: AppRoutes.pages,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
        );
      },
    );
  }
}
