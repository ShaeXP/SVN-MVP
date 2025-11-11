import 'package:get/get.dart';
import '../navigation/bottom_nav_controller.dart';
import '../../presentation/home_screen/controller/home_controller.dart';
import '../../presentation/library/library_controller.dart';
import '../../presentation/settings_screen/controller/settings_controller.dart';
import '../../presentation/active_recording_screen/recording_controller.dart';
import '../../controllers/progress_controller.dart';
import '../../controllers/pipeline_progress_controller.dart';
import '../../controllers/recording_state_coordinator.dart';
import '../../services/unified_realtime_service.dart';

/// Global app binding that ensures all core controllers are registered before any UI builds.
/// This prevents timing issues where controllers are accessed before they're registered.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // BottomNavController - permanent (owns currentIndex + router helpers)
    Get.put(BottomNavController(), permanent: true);
    
    // ProgressController - permanent (global progress tracking)
    Get.put(ProgressController(), permanent: true);
    
    // PipelineProgressController - permanent (pipeline overlay tracking)
    Get.put(PipelineProgressController(), permanent: true);
    
    // Unified status system - permanent (single source of truth for status)
    Get.put(RecordingStateCoordinator(), permanent: true);
    Get.put(UnifiedRealtimeService(), permanent: true);
    
    // Feature controllers - lazy with fenix for tab lifecycle management
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<LibraryController>(() => LibraryController(), fenix: true);
    Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);
    Get.lazyPut<RecordingController>(() => RecordingController(), fenix: true);
  }
}
