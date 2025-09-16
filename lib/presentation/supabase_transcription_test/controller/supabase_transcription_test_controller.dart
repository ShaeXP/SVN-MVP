import 'package:get/get.dart';


/// Controller class for the SupabaseTranscriptionTestScreen.
///
/// This controller manages the state for the transcription test functionality.
/// Currently, the screen manages its own state directly, but this controller
/// provides a foundation for future enhancements like state management,
/// navigation, or additional business logic.
class SupabaseTranscriptionTestController extends GetxController {
  /// Observable status of the transcription process
  var status = 'idle'.obs;

  /// Observable flag to track if processing is in progress
  var isProcessing = false.obs;

  /// Observable audio URL after upload
  var audioUrl = ''.obs;

  /// Observable selected file name
  var selectedFileName = ''.obs;

  /// Update the transcription status
  void updateStatus(String newStatus) {
    status.value = newStatus;
  }

  /// Set processing state
  void setProcessing(bool processing) {
    isProcessing.value = processing;
  }

  /// Set audio URL
  void setAudioUrl(String url) {
    audioUrl.value = url;
  }

  /// Set selected file name
  void setSelectedFileName(String fileName) {
    selectedFileName.value = fileName;
  }

  /// Reset all values to initial state
  void reset() {
    status.value = 'idle';
    isProcessing.value = false;
    audioUrl.value = '';
    selectedFileName.value = '';
  }
}
