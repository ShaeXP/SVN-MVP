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
import 'package:lashae_s_application/ui/widgets/pipeline_progress_overlay.dart';
import 'package:lashae_s_application/ui/visuals/brand_background.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late final BottomNavController _nav;
  late final GlobalKey<NavigatorState> _homeKey;
  late final GlobalKey<NavigatorState> _recordKey;
  late final GlobalKey<NavigatorState> _settingsKey;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _nav = BottomNavController.I;
    _homeKey = Get.nestedKey(0) ?? GlobalKey<NavigatorState>();
    _recordKey = Get.nestedKey(1) ?? GlobalKey<NavigatorState>();
    _settingsKey = Get.nestedKey(3) ?? GlobalKey<NavigatorState>();
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
        body: Stack(
          children: [
            const BrandGradientBackground(),
            Obx(() {
              debugPrint('[UI][MainNavigation] body rebuilt @ ${DateTime.now().toIso8601String()} index=${_nav.index.value}');
              return IndexedStack(
                index: _nav.index.value,
                children: _tabs,
              );
            }),
            const PipelineProgressOverlay(),
          ],
        ),
        bottomNavigationBar: Obx(() {
          debugPrint('[UI][MainNavigation] bottom nav rebuilt @ ${DateTime.now().toIso8601String()} index=${_nav.index.value}');
          return NavigationBar(
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
