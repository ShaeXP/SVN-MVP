import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lashae_s_application/app/routes/app_routes.dart';

class AppSplashHandoffScreen extends StatefulWidget {
  const AppSplashHandoffScreen({super.key});

  @override
  State<AppSplashHandoffScreen> createState() => _AppSplashHandoffScreenState();
}

class _AppSplashHandoffScreenState extends State<AppSplashHandoffScreen> {
  @override
  void initState() {
    super.initState();
    _goToMain();
  }

  Future<void> _goToMain() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      Get.offAllNamed(Routes.root);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000068),
      body: const SafeArea(
        child: Align(
          alignment: Alignment(0, -0.05), // slightly above center, device-agnostic
          child: _SplashContent(),
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final iconSize = size.width * 0.35;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/splash/smartvoicenotes_splash.png',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: iconSize,
              height: iconSize,
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'SmartVoiceNotes',
          style: TextStyle(
            color: Color(0xFFFEFEFE), // Soft White
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFEFEFE)), // Soft White
          ),
        ),
      ],
    );
  }
}

