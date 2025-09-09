import '../../../core/app_export.dart';
import '../../../services/recording_store.dart';
import '../models/home_model.dart';

class HomeController extends GetxController {
  Rx<HomeModel> homeModelObj = HomeModel().obs;

  // Recording store instance
  final RecordingStore _recordingStore = RecordingStore.instance;

  @override
  void onInit() {
    super.onInit();

    // Load recordings on app start after auth
    _loadRecordingsOnAppStart();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void navigateToRecording() {
    Get.toNamed(AppRoutes.recordingReadyScreen);
  }

  /// Navigate to recording ready screen
  void onMicTap() {
    Get.toNamed(AppRoutes.recordingReadyScreen);
  }

  /// Navigate to upload screen (if needed)
  void onUploadTap() {
    // Implementation for upload functionality
    // Get.toNamed(AppRoutes.uploadScreen);
  }

  /// Load recordings on app start (after auth)
  Future<void> _loadRecordingsOnAppStart() async {
    try {
      await _recordingStore.fetchAll();
    } catch (e) {
      // Silently handle error on app start, user can manually refresh later
      print('Failed to load recordings on app start: $e');
    }
  }

  /// Start new recording - generate stable recordingId
  void onStartRecording() {
    // Generate stable recordingId when recording starts
    final recordingId = DateTime.now().millisecondsSinceEpoch.toString();

    // Set current recording ID in store
    _recordingStore.setCurrentId(recordingId);

    // Navigate to recording ready screen with the generated ID
    Get.toNamed(
      AppRoutes.recordingReadyScreen,
      arguments: {'recordingId': recordingId},
    );
  }

  /// Navigate to recording library
  void onViewLibrary() {
    Get.toNamed(AppRoutes.recordingLibraryScreen);
  }
}