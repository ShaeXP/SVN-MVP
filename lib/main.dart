import 'package:flutter/material.dart';
import 'package:lashae_s_application/theme/app_theme_data.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:lashae_s_application/env.dart';
import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:lashae_s_application/app/routes/app_routes.dart';
import 'package:lashae_s_application/services/supabase_service.dart';
import 'package:sizer/sizer.dart' as su show Sizer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load config + init Supabase BEFORE runApp
  await Env.load();
// await Supa.init(); // disabled (no Supa class found)
  await SupabaseService.instance.initialize();
  runApp(const MyApp());
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return su.Sizer(
      builder: (context, orientation, deviceType) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SmartVoiceNotes',
          theme: AppThemeData.light(),
          darkTheme: AppThemeData.dark(),
          themeMode: ThemeMode.system,
          initialRoute: Routes.initial,
          getPages: AppPages.pages,
          builder: (context, child) {
            ErrorWidget.builder = (details) => MaterialApp(
                  home: Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          details.exceptionAsString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
