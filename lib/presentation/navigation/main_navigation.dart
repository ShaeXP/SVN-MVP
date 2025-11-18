import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lashae_s_application/app/navigation/bottom_nav_controller.dart';
import 'package:lashae_s_application/presentation/home_screen/home_screen.dart';
import 'package:lashae_s_application/presentation/settings_screen/settings_screen.dart';
import 'package:lashae_s_application/presentation/library/library_screen.dart';
import 'package:lashae_s_application/presentation/record_screen/record_screen.dart';
import 'package:lashae_s_application/controllers/record_controller.dart';
import 'package:lashae_s_application/services/pipeline_service.dart';
import 'package:lashae_s_application/services/audio_recorder_service.dart';
import 'package:lashae_s_application/app/routes/app_routes.dart';
import 'package:lashae_s_application/ui/visuals/brand_background.dart';
import 'package:lashae_s_application/ui/widgets/offline_banner.dart';
import '../../theme/app_text_styles.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Static keys to ensure they are created only once, even if MainNavigation is recreated
  static GlobalKey<NavigatorState>? _staticHomeKey;
  static GlobalKey<NavigatorState>? _staticRecordKey;
  static GlobalKey<NavigatorState>? _staticSettingsKey;
  
  late final BottomNavController _nav;
  late final GlobalKey<NavigatorState> _homeKey;
  late final GlobalKey<NavigatorState> _recordKey;
  late final GlobalKey<NavigatorState> _settingsKey;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _nav = BottomNavController.I;
    
    // IMPORTANT: This widget is the ONLY owner of nested keys 0, 1, and 3.
    // These keys are used for nested navigators within the IndexedStack tabs.
    // Do NOT create other navigators using these same keys elsewhere in the app.
    // Use static keys to ensure they are created only once, even if MainNavigation is recreated.
    
    // Create keys only once, reuse if they already exist
    _staticHomeKey ??= Get.nestedKey(0) ?? GlobalKey<NavigatorState>();
    _staticRecordKey ??= Get.nestedKey(1) ?? GlobalKey<NavigatorState>();
    _staticSettingsKey ??= Get.nestedKey(3) ?? GlobalKey<NavigatorState>();
    
    // Assign to instance variables
    _homeKey = _staticHomeKey!;
    _recordKey = _staticRecordKey!;
    _settingsKey = _staticSettingsKey!;
    
    _tabs = [
      _NestedNavigator(
        navigatorKey: _homeKey,
        initialRoute: Routes.home,
        onGenerateRoute: (settings) => GetPageRoute(
          page: () => const HomeScreen(),
          routeName: settings.name ?? Routes.home,
        ),
      ),
      _NestedNavigator(
        navigatorKey: _recordKey,
        initialRoute: Routes.record,
        onGenerateRoute: (settings) {
          _ensureRecordDeps();
          return GetPageRoute(
            page: () => const RecordScreen(),
            routeName: settings.name ?? Routes.record,
          );
        },
      ),
      const LibraryScreen(),
      _NestedNavigator(
        navigatorKey: _settingsKey,
        initialRoute: Routes.settings,
        onGenerateRoute: (settings) => GetPageRoute(
          page: () => const SettingsScreen(),
          routeName: settings.name ?? Routes.settings,
        ),
      ),
    ];
  }

  void _ensureRecordDeps() {
    if (!Get.isRegistered<AudioRecorderService>()) {
      Get.put(AudioRecorderService(), permanent: true);
    }
    if (!Get.isRegistered<PipelineService>()) {
      Get.put(PipelineService(), permanent: true);
    }
    if (!Get.isRegistered<RecordController>()) {
      final recorder = Get.find<AudioRecorderService>();
      final pipeline = Get.find<PipelineService>();
      Get.put(RecordController(recorder: recorder, pipeline: pipeline), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Read non-reactive snapshot to avoid GetX error in callback
        final currentIndex = _nav.index.value;
        if (currentIndex != 0) {
          _nav.goTab(0); // go Home instead of exiting
        } else {
          // allow app to exit
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: Stack(
                children: [
                  const BrandGradientBackground(),
                  Obx(() {
                    debugPrint('[UI][MainNavigation] body rebuilt @ ${DateTime.now().toIso8601String()} index=${_nav.index.value}');
                    return IndexedStack(
                      index: _nav.index.value,
                      children: _tabs,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Obx(() {
          debugPrint('[UI][MainNavigation] bottom nav rebuilt @ ${DateTime.now().toIso8601String()} index=${_nav.index.value}');
          return NavigationBarTheme(
            data: NavigationBarThemeData(
              labelTextStyle: MaterialStateProperty.resolveWith((states) {
                final selected = states.contains(MaterialState.selected);
                return selected
                    ? AppTextStyles.bottomNavLabelSelected(context)
                    : AppTextStyles.bottomNavLabelUnselected(context);
              }),
            ),
            child: NavigationBar(
              selectedIndex: _nav.index.value,
              onDestinationSelected: _nav.goTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.mic_none),
                  selectedIcon: Icon(Icons.mic),
                  label: 'Record',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: 'Library',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

}

class _NestedNavigator extends StatelessWidget {
  const _NestedNavigator({
    required this.navigatorKey,
    required this.initialRoute,
    required this.onGenerateRoute,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final String initialRoute;
  final Route<dynamic> Function(RouteSettings settings) onGenerateRoute;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) => onGenerateRoute(settings),
    );
  }
}
