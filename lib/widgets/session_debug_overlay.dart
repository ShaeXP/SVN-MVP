import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lashae_s_application/bootstrap_supabase.dart'; // exposes Supa.client

class SessionDebugOverlay extends StatelessWidget {
  const SessionDebugOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supa.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final evt = snapshot.data?.event;
        final uid = Supa.client.auth.currentUser?.id;

        return Positioned(
          left: 8,
          bottom: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: _AuthText(),
            ),
          ),
        );
      },
    );
  }
}

class _AuthText extends StatelessWidget {
  const _AuthText();

  @override
  Widget build(BuildContext context) {
    final user = Supa.client.auth.currentUser;
    return Text(
      'auth: (listening)\nuser: ${user?.id ?? "null"}',
      style: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }
}
