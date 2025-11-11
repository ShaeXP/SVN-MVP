import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lashae_s_application/presentation/auth/controller/auth_controller.dart';
import 'package:lashae_s_application/presentation/auth/auth_screen.dart';
import 'package:lashae_s_application/presentation/navigation/main_navigation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Subscribe to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final supa = Supabase.instance.client;
    final session = supa.auth.currentSession;
    final user = session?.user;

    debugPrint('[AUTHGATE] session=${session != null} email=${user?.email} confirmedAt=${user?.emailConfirmedAt}');

    if (session == null) {
      if (!Get.isRegistered<AuthController>()) {
        Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
      }
      return const AuthScreen();
    } else {
      // Check if email is confirmed
      final isConfirmed = user?.emailConfirmedAt != null;
      
      if (!isConfirmed) {
        // User exists but email not confirmed
        if (Get.isRegistered<AuthController>()) {
          Get.delete<AuthController>();
        }
        return const AuthScreen();
      } else {
        // User confirmed, proceed to app
        if (Get.isRegistered<AuthController>()) {
          Get.delete<AuthController>();
        }
        return const MainNavigation();
      }
    }
  }
}
