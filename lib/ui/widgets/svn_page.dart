import 'package:flutter/material.dart';
import '../app_spacing.dart';

/// Shared layout shell for SmartVoiceNotes screens rendered inside the root scaffold.
class SVNPage extends StatelessWidget {
  const SVNPage({
    super.key,
    this.title,
    required this.child,
    this.scrollable = true,
    this.padding,
  });

  final String? title;
  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pad = padding ?? AppSpacing.screenPadding(context);
    final titleSpacing = AppSpacing.base(context) * 0.75;

    Widget buildContent(Widget inner) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: titleSpacing),
          ],
          inner,
        ],
      );
    }

    Widget body;
    if (scrollable) {
      body = LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: pad,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: buildContent(child),
            ),
          );
        },
      );
    } else {
      body = Padding(
        padding: pad,
        child: buildContent(child),
      );
    }

    return SafeArea(
      bottom: false,
      child: body,
    );
  }
}

