import 'package:flutter/material.dart';

/// Wrap any screen body with DesktopClamp to avoid infinite width on desktop.
/// It centers content, clamps max width, and forces a real width for children.
class DesktopClamp extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const DesktopClamp({
    super.key,
    required this.child,
    this.maxWidth = 900, // 720–1000 is fine; 900 is a good default
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // cap width so descendants never see infinite cross-axis
              maxWidth: maxWidth,
            ),
            // SizedBox forces the child to actually take the available width
            child: Padding(
              padding: padding,
              child: SizedBox(
                width: double.infinity,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
