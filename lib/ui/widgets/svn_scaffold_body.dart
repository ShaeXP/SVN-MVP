import 'package:flutter/material.dart';

import '../app_spacing.dart';

typedef ScrollBuilder = Widget Function(EdgeInsets padding);

class SVNScaffoldBody extends StatefulWidget {
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
  State<SVNScaffoldBody> createState() => _SVNScaffoldBodyState();
}

class _SVNScaffoldBodyState extends State<SVNScaffoldBody> {
  @override
  Widget build(BuildContext context) {
    final padding = widget._padding ?? AppSpacing.screenPadding(context);

    Widget buildScrollable() {
      return LayoutBuilder(
        key: const ValueKey('svn_scaffold_layout'), // Stable key to prevent unnecessary rebuilds
        builder: (context, constraints) {
          // DO NOT mutate any state here - only build widgets from constraints
          // DO NOT call setState, update Rx values, or modify controller state
          // This builder must be pure: compute widgets from constraints and props only
          Widget scrollable;

          if (widget.scrollBuilder != null) {
            scrollable = widget.scrollBuilder!(padding);
          } else {
            scrollable = SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: widget.child!,
              ),
            );
          }

          if (widget.onRefresh != null) {
            scrollable = RefreshIndicator(
              onRefresh: widget.onRefresh!,
              child: scrollable,
            );
          }

          return scrollable;
        },
      );
    }

    // If there's no banner, return scrollable content directly (no Column wrapper)
    if (widget.banner == null) {
      return buildScrollable();
    }

    // When banner exists, use Column layout
    return Column(
      children: [
        widget.banner!,
        Expanded(
          child: buildScrollable(),
        ),
      ],
    );
  }
}
