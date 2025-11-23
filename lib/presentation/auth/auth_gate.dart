import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lashae_s_application/presentation/auth/controller/auth_controller.dart';
import 'package:lashae_s_application/presentation/auth/auth_screen.dart';
import 'package:lashae_s_application/app/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Timer? _navigationTimeout;
  String? _navigationError;

  @override
  void initState() {
    super.initState();
    // Subscribe to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        // Check auth and navigate when state changes
        _checkAuthAndNavigate();
      }
    });
    
    // Initial navigation check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _navigationTimeout?.cancel();
    super.dispose();
  }

  void _checkAuthAndNavigate() {
    final supa = Supabase.instance.client;
    final session = supa.auth.currentSession;
    final user = session?.user;

    if (session != null && user?.emailConfirmedAt != null) {
      // User confirmed, navigate to main app shell
      if (Get.isRegistered<AuthController>()) {
        Get.delete<AuthController>();
      }
      // Only navigate if not already on home route
      if (Get.currentRoute != Routes.home) {
        _navigateWithTimeout(Routes.home);
      }
    } else if (session == null) {
      // Signed out - navigate to login
      if (Get.currentRoute != Routes.login) {
        _navigateWithTimeout(Routes.login);
      }
    }
  }

  void _navigateWithTimeout(String route) {
    // Cancel any existing timeout
    _navigationTimeout?.cancel();
    
    // Set navigation timeout (3 seconds)
    _navigationTimeout = Timer(const Duration(seconds: 3), () {
      if (mounted && Get.currentRoute != route) {
        setState(() {
          _navigationError = 'Navigation to $route timed out. Current route: ${Get.currentRoute}';
        });
        debugPrint('[AUTHGATE][ERROR] Navigation timeout: $_navigationError');
      }
    });

    try {
      debugPrint('[AUTHGATE] Navigating to $route from ${Get.currentRoute}');
      Get.offAllNamed(route);
      
      // Cancel timeout if navigation succeeds quickly
      Future.delayed(const Duration(milliseconds: 500), () {
        if (Get.currentRoute == route) {
          _navigationTimeout?.cancel();
          if (mounted) {
            setState(() {
              _navigationError = null;
            });
          }
        }
      });
    } catch (e, stackTrace) {
      _navigationTimeout?.cancel();
      debugPrint('[AUTHGATE][ERROR] Navigation failed: $e');
      debugPrint('[AUTHGATE][ERROR] Stack: $stackTrace');
      if (mounted) {
        setState(() {
          _navigationError = 'Navigation error: $e';
        });
      }
    }
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
        // User confirmed - show loading while navigation happens
        // Navigation will happen in post-frame callback
        if (Get.isRegistered<AuthController>()) {
          Get.delete<AuthController>();
        }
        
        // Show error if navigation failed
        if (_navigationError != null) {
          return Scaffold(
            backgroundColor: Colors.red.shade900,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Navigation Error',
                      style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _navigationError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _navigationError = null;
                        });
                        _checkAuthAndNavigate();
                      },
                      child: const Text('Retry Navigation'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // Show loading state with visible background
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Loading...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Current route: ${Get.currentRoute}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }
}
