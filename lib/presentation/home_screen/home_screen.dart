import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller/home_controller.dart';
import 'home_sections.dart';
import 'widgets/editable_card_shell.dart';
import 'widgets/read_only_card_shell.dart';
import '../../ui/widgets/unified_status_chip.dart';
import '../../ui/widgets/svn_app_bar.dart';
import '../../services/pipeline_tracker.dart';
import '../../ui/app_spacing.dart';
import '../../ui/widgets/svn_scaffold_body.dart';

// App bar height constant for consistent spacing calculations
const double _kAppBarHeight = 56.0;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final tracker = PipelineTracker.I;
    final topInset = MediaQuery.of(context).padding.top + _kAppBarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ReactiveSVNAppBar(
        showActions: true,
        isEditing: controller.editing,
        onEditPressed: controller.toggleEditing,
      ),
      body: Stack(
        children: [
          const _HomeGradientBackground(),
          SafeArea(
            top: false, // Don't add top padding - we calculate it ourselves
            child: Padding(
              padding: EdgeInsets.only(top: topInset),
              child: Obx(() {
                final basePadding = AppSpacing.base(context);
                final recordingId = tracker.recordingId.value;
                Widget? banner;
                if (recordingId != null) {
                  banner = Padding(
                    padding: EdgeInsets.fromLTRB(basePadding, 0, basePadding, basePadding),
                    child: SizedBox(
                      height: 80,
                      child: UnifiedPipelineBanner(recordingId: recordingId),
                    ),
                  );
                }

                if (controller.isLoading.value) {
                  return SVNScaffoldBody(
                    banner: banner,
                    onRefresh: controller.refresh,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (controller.errorText.value.isNotEmpty) {
                  return SVNScaffoldBody(
                    banner: banner,
                    onRefresh: controller.refresh,
                    child: _CenterBox(
                      title: 'Welcome',
                      child: Column(
                        children: [
                          Text(controller.errorText.value, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          OutlinedButton(onPressed: controller.refresh, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  );
                }

                final items = controller.sections
                    .where((s) => !controller.hidden.contains(s))
                    .toList();

                if (controller.editing.value) {
                  return SVNScaffoldBody(
                    banner: banner,
                    scrollBuilder: (padding) => _buildEditableSections(
                      context,
                      controller,
                      items,
                      padding,
                    ),
                  );
                }

                return SVNScaffoldBody(
                  banner: banner,
                  onRefresh: controller.refresh,
                  child: _buildReadOnlySections(context, controller, items),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildReadOnlySections(
  BuildContext context,
  HomeController controller,
  List<HomeSection> items,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final section in items) ...[
        ReadOnlyCardShell(
          title: section == HomeSection.welcome
              ? null
              : (HomeSectionRegistry.titles[section] ?? ''),
          child: HomeSectionRegistry.builders[section]!(context),
          menuBuilder: PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'hide') controller.hideSection(section);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'hide', child: Text('Hide this')),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 24),
      _TrustStrip(),
    ],
  );
}

Widget _buildEditableSections(
  BuildContext context,
  HomeController controller,
  List<HomeSection> items,
  EdgeInsets padding,
) {
  return ReorderableListView.builder(
    padding: padding.copyWith(
      bottom: padding.bottom + AppSpacing.base(context),
    ),
    physics: const AlwaysScrollableScrollPhysics(),
    buildDefaultDragHandles: false,
    itemCount: items.length,
    onReorder: controller.reorder,
    itemBuilder: (context, index) {
      final section = items[index];
      return Material(
        key: ValueKey('home_${section.name}'),
        color: Colors.transparent,
        child: EditableCardShell(
          title: section == HomeSection.welcome
              ? null
              : (HomeSectionRegistry.titles[section] ?? ''),
          onMenu: (action) {
            switch (action) {
              case 'hide':
                controller.hideSection(section);
                break;
              case 'up':
                if (index > 0) controller.reorder(index, index - 1);
                break;
              case 'down':
                if (index < items.length - 1) {
                  controller.reorder(index, index + 2);
                }
                break;
            }
          },
          child: HomeSectionRegistry.builders[section]!(context),
          dragHandle: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_indicator, size: 22),
          ),
        ),
      );
    },
  );
}




class _TrustStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Text('Private storage · RLS enforced · Keys stay on the server',
          style: Theme.of(context).textTheme.bodySmall),
    );
  }
}


class _CenterBox extends StatelessWidget {
  const _CenterBox({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ],
    );
  }
}


/// Page background gradient inspired by the marketing site (light: violet→indigo→blue→cyan; dark: deep violet→ink blue)
class _HomeGradientBackground extends StatelessWidget {
  const _HomeGradientBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      position: DecorationPosition.background,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1.0, -0.8),   // top-left-ish
          end: const Alignment(1.0, 0.9),       // bottom-right-ish
          colors: isDark
              ? const [
                  Color(0xFF1C1730),            // deep violet
                  Color(0xFF0E2333),            // ink blue
                ]
              : const [
                  Color(0xFF8B5CF6),            // violet-500
                  Color(0xFF6366F1),            // indigo-500
                  Color(0xFF3B82F6),            // blue-500
                  Color(0xFF22D3EE),            // cyan-400
                ],
          stops: isDark ? const [0.0, 1.0] : const [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: const [
          // soft radial highlights to mimic the site's glow
          _RadialGlow(offset: Offset(0.75, -0.2), color: Color(0x66FFFFFF)),
          _RadialGlow(offset: Offset(-0.4, 0.9), color: Color(0x3344D7FF)),
        ],
      ),
    );
  }
}

class _RadialGlow extends StatelessWidget {
  final Offset offset; // logical alignment space (-1..1)
  final Color color;
  const _RadialGlow({required this.offset, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(offset.dx, offset.dy),
              radius: 0.75,
              colors: [color, color.withValues(alpha: 0.0)],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
