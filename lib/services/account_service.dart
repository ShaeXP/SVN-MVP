import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../presentation/auth/auth_gate.dart';

class AccountService {
  final supa = Supabase.instance.client;

  /// Sign out the current user
  Future<void> signOut() async {
    await supa.auth.signOut();
    Get.offAll(() => const AuthGate());
  }

  /// Request data export - backend emails link to user
  Future<bool> requestDataExport() async {
    try {
      final resp = await supa.functions.invoke('sv_request_export', body: {});
      return resp.status == 200;
    } catch (e) {
      return false;
    }
  }

  /// Request account deletion - backend creates ticket
  Future<bool> requestAccountDeletion() async {
    try {
      final resp = await supa.functions.invoke('sv_request_account_delete', body: {});
      return resp.status == 200;
    } catch (e) {
      return false;
    }
  }
}
