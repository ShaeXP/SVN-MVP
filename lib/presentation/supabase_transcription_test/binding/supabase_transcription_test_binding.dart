import 'package:get/get.dart';

import '../controller/supabase_transcription_test_controller.dart';

/// Binding class for the SupabaseTranscriptionTestScreen.
///
/// This binding is responsible for dependency injection of the
/// SupabaseTranscriptionTestController. It ensures that the controller
/// is properly initialized when the screen is accessed.
class SupabaseTranscriptionTestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SupabaseTranscriptionTestController());
  }
}
