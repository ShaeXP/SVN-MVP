import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Disables mouse-wheel scrolling for any scrollables in [child].
class NoMouseWheel extends StatelessWidget {
  const NoMouseWheel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _NoWheelBehavior(),
      child: Listener( // also eats wheel signals at the top
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            // Do nothing; intentionally swallowing the event.
          }
        },
        child: child,
      ),
    );
  }
}

class _NoWheelBehavior extends MaterialScrollBehavior {
  const _NoWheelBehavior();

  // Allow touch/trackpad drags; block mouse wheel.
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
