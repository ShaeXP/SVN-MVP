import 'package:get/get.dart';
import '../../../core/app_export.dart';

/// This class is used in the [LoginScreen] screen with GetX.

class LoginModel {
  // Observable variables for reactive state management
  Rx<String> email = "".obs;
  Rx<String> password = "".obs;
  Rx<bool> rememberMe = false.obs;
  Rx<bool> isLoggedIn = false.obs;
  Rx<String> loginType = "email".obs; // email, google, microsoft

  // Simple constructor with no parameters
  LoginModel();
}
