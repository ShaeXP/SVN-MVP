import 'package:flutter/material.dart';

import '../app_spacing.dart';

typedef ScrollBuilder = Widget Function(EdgeInsets padding);

class SVNScaffoldBody extends StatelessWidget {
  const SVNScaffoldBody({
    super.key,
    this.banner,
    this.child,
    this.scrollBuilder,
    this.onRefresh,
    EdgeInsets? padding,
  })  : assert(child != null || scrollBuilder != null,
            'Provide either child or scrollBuilder.'),
        _padding = padding;

  final Widget? banner;
  final Widget? child;
  final ScrollBuilder? scrollBuilder;
  final RefreshCallback? onRefresh;
  final EdgeInsets? _padding;

  @override
  Widget build(BuildContext context) {
    final padding = _padding ?? AppSpacing.screenPadding(context);

    return Column(
      children: [
        if (banner != null) banner!,
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              Widget scrollable;

              if (scrollBuilder != null) {
                scrollable = scrollBuilder!(padding);
              } else {
                scrollable = SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: padding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: child!,
                  ),
                );
              }

              if (onRefresh != null) {
                scrollable = RefreshIndicator(
                  onRefresh: onRefresh!,
                  child: scrollable,
                );
              }

              return scrollable;
            },
          ),
        ),
      ],
    );
  }
}
