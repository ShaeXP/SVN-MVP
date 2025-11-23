import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:lashae_s_application/env.dart';
import 'package:lashae_s_application/services/supabase_service.dart';
import 'package:lashae_s_application/services/pipeline_tracker.dart';
import 'package:lashae_s_application/bootstrap_supabase.dart';
import 'package:lashae_s_application/ui/theme/svn_theme.dart';
import 'package:lashae_s_application/app/navigation/bottom_nav_controller.dart';
import 'package:lashae_s_application/app/bindings/app_binding.dart';
import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:lashae_s_application/presentation/navigation/main_navigation.dart';
import 'package:lashae_s_application/services/connectivity_service.dart';
import 'package:lashae_s_application/services/permission_service.dart';
import 'package:lashae_s_application/services/onboarding_service.dart';
import 'package:sizer/sizer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enhanced error handling with full stack trace logging
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details); // Ensures full console output
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    debugPrint('[FlutterError] Stack: ${details.stack}');
    FlutterError.presentError(details);
  };

  try {
    // Load config + init Supabase BEFORE runApp
    await Env.load();
    await Supa.init(); // Initialize bootstrap client
    await SupabaseService.instance.initialize();
    
    // Auth is now handled by AuthGate widget
    
    // Install pipeline tracker service
    await Get.putAsync<PipelineTracker>(() async => PipelineTracker().init(), permanent: true);
    
    // Initialize connectivity service
    ConnectivityService.instance;
    
    // Initialize permission service
    Get.put(PermissionService(), permanent: true);
    
    // Initialize onboarding service
    await Get.putAsync<OnboardingService>(() async => OnboardingService().init(), permanent: true);
    
    // Set up global error widget to prevent white screen crashes
    ErrorWidget.builder = (details) {
      // Log full error details BEFORE showing UI
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
                Text(
                  'WIDGET ERROR',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    };
    
    // Call runApp directly in the default zone
    runApp(const MyApp());
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } catch (e) {
    print('Error during initialization: $e');
    // Run a fallback app
    runApp(GetMaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'INIT ERROR',
                style: TextStyle(fontSize: 32, color: Colors.white),
              ),
              Text('$e', style: TextStyle(color: Colors.white)),
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
    return Sizer(
      builder: (context, orientation, deviceType) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SmartVoiceNotes',
          navigatorKey: Get.key,
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          theme: SVNTheme.theme(context),
          initialBinding: AppBinding(),
          // Temporarily disabled route-based startup to bypass black screen
          // getPages: AppPages.pages,
          // initialRoute: AppPages.initial,
          home: const MainNavigation(),
          unknownRoute: GetPage(
            name: '/404',
            page: () => Scaffold(
              body: Center(
                child: Text('Route not found: ${Get.currentRoute}'),
              ),
            ),
          ),
          navigatorObservers: [
            GetObserver((routing) {
              // Defer bottom nav updates until after build cycle
              Future.microtask(() {
                final nav = BottomNavController.I;
                nav.onRouteChanged(routing?.current ?? Get.currentRoute);
              });
            }),
          ],
          builder: (context, child) {
            ErrorWidget.builder = (details) {
              // Log full error details BEFORE showing UI
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
                        Text(
                          'WIDGET ERROR',
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                        SizedBox(height: 20),
                        Text(
                          details.exceptionAsString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            };
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child ?? Container(
                color: Colors.purple,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'NO CHILD WIDGET',
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'This indicates a routing issue',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
