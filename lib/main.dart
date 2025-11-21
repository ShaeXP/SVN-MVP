import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:lashae_s_application/env.dart';
import 'package:lashae_s_application/services/supabase_service.dart';
import 'package:lashae_s_application/services/onboarding_service.dart';
import 'package:lashae_s_application/services/pipeline_tracker.dart';
import 'package:lashae_s_application/bootstrap_supabase.dart';
import 'package:lashae_s_application/core/utils/preview_mode_detector.dart';
import 'package:lashae_s_application/theme/app_theme_data.dart';
import 'package:lashae_s_application/app/bindings/app_binding.dart';
import 'package:lashae_s_application/app/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enhanced error handling with full stack trace logging
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    debugPrint('[FlutterError] Stack: ${details.stack}');
    FlutterError.presentError(details);
  };

  try {
    // Load config first
    await Env.load();

    // Initialize Supabase with preview mode timeout handling
    await PreviewModeDetector.withPreviewTimeoutVoid(
      () async {
        await Supa.init();
        await SupabaseService.instance.initialize();
      },
      serviceName: 'Supabase',
    );

    // Initialize OnboardingService (async initialization required)
    await Get.putAsync<OnboardingService>(
      () async => OnboardingService().init(),
      permanent: true,
    );

    // Initialize PipelineTracker (async initialization required)
    await Get.putAsync<PipelineTracker>(
      () async => PipelineTracker().init(),
      permanent: true,
    );

    // Set up global error widget to prevent white screen crashes
    ErrorWidget.builder = (details) {
      FlutterError.dumpErrorToConsole(details);
      debugPrint('[WIDGET_ERROR] ${details.exceptionAsString()}');
      debugPrint('[WIDGET_ERROR] Stack: ${details.stack}');

      return Scaffold(
        backgroundColor: Colors.orange,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'WIDGET ERROR',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    };

    // Call runApp
    runApp(const MyApp());
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } catch (e) {
    debugPrint('Error during initialization: $e');
    // Run a fallback app
    runApp(GetMaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'INIT ERROR',
                style: TextStyle(fontSize: 32, color: Colors.white),
              ),
              Text('$e', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartVoiceNotes',
      navigatorKey: Get.key,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 260),
      theme: AppThemeData.light(),
      darkTheme: AppThemeData.dark(),
      themeMode: ThemeMode.system,
      initialBinding: AppBinding(),
      getPages: AppPages.pages,
      initialRoute: AppPages.initial,
      unknownRoute: GetPage(
        name: '/404',
        page: () => Scaffold(
          body: Center(
            child: Text('Route not found: ${Get.currentRoute}'),
          ),
        ),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
