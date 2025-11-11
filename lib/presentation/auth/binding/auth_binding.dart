import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController is managed by AuthGate, no need to register here
  }
}
