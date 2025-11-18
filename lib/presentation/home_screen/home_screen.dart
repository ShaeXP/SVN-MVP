import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller/home_controller.dart';
import 'home_sections.dart';
import 'widgets/editable_card_shell.dart';
import 'widgets/read_only_card_shell.dart';
import '../../ui/widgets/svn_app_bar.dart';
import '../../ui/app_spacing.dart';
import '../../ui/widgets/svn_scaffold_body.dart';
import '../../theme/app_gradients.dart';
import '../../services/onboarding_service.dart';
import '../../ui/widgets/home_onboarding_strip.dart';

// App bar height constant for consistent spacing calculations
const double _kAppBarHeight = 56.0;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
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
              child: _HomeContent(controller: controller),
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
  final onboardingService = Get.find<OnboardingService>();
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final section in items) ...[
        ReadOnlyCardShell(
          title: section == HomeSection.welcome
              ? null
              : (HomeSectionRegistry.titles[section] ?? ''),
          child: HomeSectionRegistry.builders[section]!(context),
          menuBuilder: null, // No menu in normal mode - only show in edit mode
        ),
        SizedBox(height: AppSpacing.md),
        // Show onboarding strip after welcome section and before quickTabs
        if (section == HomeSection.welcome)
          Obx(() {
            if (onboardingService.isHomeOnboardingDismissed) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                HomeOnboardingStrip(
                  onDismiss: () => onboardingService.dismissHomeOnboarding(),
                ),
                SizedBox(height: AppSpacing.md),
              ],
            );
          }),
      ],
      SizedBox(height: AppSpacing.xl),
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
            child: const Icon(Icons.drag_handle, size: 22),
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
    return DecoratedBox(
      position: DecorationPosition.background,
      decoration: BoxDecoration(
        gradient: AppGradients.mainBackgroundFor(context),
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
        ignoring: true, // Explicitly set to true to avoid mutations
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

/// Stable widget that contains the LayoutBuilder, with reactive content inside
class _HomeContent extends StatelessWidget {
  final HomeController controller;
  
  const _HomeContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Keep SVNScaffoldBody stable - it contains LayoutBuilder which must not be rebuilt
    // Use Obx only for the content that changes, passed as child/scrollBuilder
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final errorText = controller.errorText.value;
      final isEditing = controller.editing.value;
      final items = controller.sections
          .where((s) => !controller.hidden.contains(s))
          .toList();

      // Build callbacks and content outside LayoutBuilder to avoid mutations during layout
      ScrollBuilder? scrollBuilderCallback;
      Widget? contentChild;
      
      if (isLoading) {
        contentChild = const Center(child: CircularProgressIndicator());
      } else if (errorText.isNotEmpty) {
        contentChild = _CenterBox(
          title: 'Welcome',
          child: Column(
            children: [
              Text(errorText, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: controller.refresh, child: const Text('Retry')),
            ],
          ),
        );
      } else if (isEditing) {
        // Use scrollBuilder for editable mode - build callback outside LayoutBuilder
        scrollBuilderCallback = (padding) => _buildEditableSections(
          context,
          controller,
          items,
          padding,
        );
        contentChild = const SizedBox.shrink(); // Placeholder when using scrollBuilder
      } else {
        contentChild = _buildReadOnlySections(context, controller, items);
      }

      return SVNScaffoldBody(
        key: const ValueKey('home_scaffold_body'), // Stable key to prevent rebuilds
        onRefresh: controller.refresh,
        child: contentChild,
        scrollBuilder: scrollBuilderCallback,
      );
    });
  }
  
  Widget _buildReadOnlySections(
    BuildContext context,
    HomeController controller,
    List<HomeSection> items,
  ) {
    final onboardingService = Get.find<OnboardingService>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in items) ...[
          ReadOnlyCardShell(
            title: section == HomeSection.welcome
                ? null
                : (HomeSectionRegistry.titles[section] ?? ''),
            child: HomeSectionRegistry.builders[section]!(context),
            menuBuilder: null, // No menu in normal mode - only show in edit mode
          ),
          SizedBox(height: AppSpacing.md),
          // Show onboarding strip after welcome section and before quickTabs
          if (section == HomeSection.welcome)
            Obx(() {
              if (onboardingService.isHomeOnboardingDismissed) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  HomeOnboardingStrip(
                    onDismiss: () => onboardingService.dismissHomeOnboarding(),
                  ),
                  SizedBox(height: AppSpacing.md),
                ],
              );
            }),
        ],
        SizedBox(height: AppSpacing.xl),
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
    // DO NOT mutate any state here - this is called inside LayoutBuilder.builder
    // Only build widgets from the provided parameters
    return ReorderableListView.builder(
      padding: padding.copyWith(
        bottom: padding.bottom + AppSpacing.base(context),
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorder: controller.reorder, // This is safe - it's a callback, not called during build
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
              // This callback is safe - it's not called during build/layout
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
              child: const Icon(Icons.drag_handle, size: 22),
            ),
          ),
        );
      },
    );
  }
}
