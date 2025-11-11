import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/routes/app_routes.dart';

/// Lightweight gate that decides where to go based on Supabase auth state.
/// - If session exists: go to shell (Routes.homeScreen)
/// - If no session: go to login (Routes.loginScreen)
/// Also listens for sign-out and redirects to login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _sub;

  @override
  void initState() {
    super.initState();

    // Initial decision
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      // Not signed in → login
      // Use offAllNamed so back does not return to gate.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(Routes.login);
      });
    } else {
      // Signed in → shell (home)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(Routes.root);
      });
    }

    // Live redirect on auth changes (sign-in/sign-out)
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedOut || session == null) {
        Get.offAllNamed(Routes.login);
      } else if (event == AuthChangeEvent.signedIn && session != null) {
        Get.offAllNamed(Routes.root);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simple splash while the redirect decision happens.
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}