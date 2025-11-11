import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller/auth_controller.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2563EB),
              Color(0xFF1E40AF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App branding
                  const Icon(
                    Icons.mic,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SmartVoiceNotes',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Transform your voice into organized notes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Auth card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: DefaultTabController(
                      length: 2,
                      initialIndex: 0,
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Sign Up'),
                            ],
                            labelColor: Color(0xFF2563EB),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Color(0xFF2563EB),
                          ),
                          SizedBox(
                            height: 400,
                            child: TabBarView(
                              children: [
                                _SignInForm(),
                                _SignUpForm(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInForm extends GetView<AuthController> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.signInFormKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: controller.validateEmail,
              onChanged: (v) => controller.email.value = v,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: controller.validatePassword,
              onChanged: (v) => controller.password.value = v,
              onFieldSubmitted: (_) => controller.signIn(),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            Obx(() => controller.error.value.isEmpty
              ? const SizedBox.shrink()
              : Text(controller.error.value, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 8),
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.signIn,
                child: controller.isLoading.value
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sign In'),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _SignUpForm extends GetView<AuthController> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.signUpFormKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: controller.validateEmail,
              onChanged: (v) => controller.email.value = v,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: controller.validatePassword,
              onChanged: (v) => controller.password.value = v,
              onFieldSubmitted: (_) => controller.signUp(),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            Obx(() => controller.error.value.isEmpty
              ? const SizedBox.shrink()
              : Text(controller.error.value, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 8),
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.signUp,
                child: controller.isLoading.value
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Account'),
              ),
            )),
          ],
        ),
      ),
    );
  }
}