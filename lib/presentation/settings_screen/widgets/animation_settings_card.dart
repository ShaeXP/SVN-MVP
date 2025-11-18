import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../ui/animation/anim_flags.dart';
import '../../../ui/app_spacing.dart';

class AnimationSettingsCard extends StatefulWidget {
  const AnimationSettingsCard({super.key});

  @override
  State<AnimationSettingsCard> createState() => _AnimationSettingsCardState();
}

class _AnimationSettingsCardState extends State<AnimationSettingsCard> {
  bool _riveEnabled = false;
  bool _lottieEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final rive = await AnimFlags.riveEnabled();
    final lottie = await AnimFlags.lottieEnabled();
    setState(() {
      _riveEnabled = rive;
      _lottieEnabled = lottie;
    });
  }

  Future<void> _setRive(bool value) async {
    if (value) {
      // Enable Rive, disable Lottie
      await AnimFlags.setRive(true);
      await AnimFlags.setLottie(false);
      setState(() {
        _riveEnabled = true;
        _lottieEnabled = false;
      });
      Get.snackbar('Animation Setting', 'Rive animations enabled');
    } else {
      // Disable Rive, enable Lottie
      await AnimFlags.setRive(false);
      await AnimFlags.setLottie(true);
      setState(() {
        _riveEnabled = false;
        _lottieEnabled = true;
      });
      Get.snackbar('Animation Setting', 'Lottie animations enabled');
    }
  }

  Future<void> _setLottie(bool value) async {
    if (value) {
      // Enable Lottie, disable Rive
      await AnimFlags.setLottie(true);
      await AnimFlags.setRive(false);
      setState(() {
        _lottieEnabled = true;
        _riveEnabled = false;
      });
      Get.snackbar('Animation Setting', 'Lottie animations enabled');
    } else {
      // Disable Lottie, enable Rive
      await AnimFlags.setLottie(false);
      await AnimFlags.setRive(true);
      setState(() {
        _lottieEnabled = false;
        _riveEnabled = true;
      });
      Get.snackbar('Animation Setting', 'Rive animations enabled');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Animations',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        AppSpacing.v(context, 0.25),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Rive animations'),
          value: _riveEnabled,
          onChanged: _setRive,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Lottie animations'),
          value: _lottieEnabled,
          onChanged: _setLottie,
        ),
      ],
    );
  }
}
