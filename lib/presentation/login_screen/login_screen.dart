import 'package:lashae_s_application/core/app_export.dart';
import 'package:sizer/sizer.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // AUTH-GATE: Added for kDebugMode
import 'package:supabase_flutter/supabase_flutter.dart'; // AUTH-GATE: Added for guest sign-in

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_image_view.dart';
import './controller/login_controller.dart';

class LoginScreen extends GetWidget<LoginController> {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('LoginScreen build() called');
    return Scaffold(
      // AUTH-GATE: No AppBar - LoginScreen is standalone outside shell
      body: Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to SmartVoiceNotes',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Sign in to access your voice recordings',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: controller.emailController,
                          validator: controller.validateEmail,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: controller.passwordController,
                          validator: controller.validatePassword,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 20),
                        Obx(() => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value 
                                ? null 
                                : () => controller.onSignInTap(),
                            child: controller.isLoading.value
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text('Sign In'),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    print('Go Back pressed');
                    Get.back();
                  },
                  child: Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
