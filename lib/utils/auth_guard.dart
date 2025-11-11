import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

/// Custom exception for auth required errors
class AuthRequiredError implements Exception {
  const AuthRequiredError();
  
  @override
  String toString() => 'Authentication required';
}

/// Utility class for auth guards
class AuthGuard {
  /// Requires a valid session, throws AuthRequiredError if not authenticated
  static Session requireSession() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw const AuthRequiredError();
    }
    return session;
  }

  /// Requires a valid session, shows snackbar and returns null if not authenticated
  static Session? requireSessionOrBounce() {
    try {
      return requireSession();
    } catch (e) {
      Get.snackbar(
        'Authentication Required',
        'Please sign in to continue',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return null;
    }
  }

  /// Checks if user is authenticated
  static bool isAuthenticated() {
    return Supabase.instance.client.auth.currentSession != null;
  }

  /// Gets current user, returns null if not authenticated
  static User? getCurrentUser() {
    return Supabase.instance.client.auth.currentUser;
  }
}
