import 'package:shared_preferences/shared_preferences.dart';
import 'package:lashae_s_application/config/feature_flags.dart';

class AnimFlags {
  static const _riveKey = 'kUseRiveAnimations';
  static const _lottieKey = 'kUseLottieAnimations';

  static Future<bool> riveEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_riveKey) ?? kUseRiveAnimationsDefault;
  }

  static Future<bool> lottieEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_lottieKey) ?? kUseLottieAnimationsDefault;
  }

  static Future<void> setRive(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_riveKey, v);
  }

  static Future<void> setLottie(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_lottieKey, v);
  }
}
