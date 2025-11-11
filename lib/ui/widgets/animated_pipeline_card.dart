import 'package:flutter/material.dart';
import 'package:lashae_s_application/services/pipeline_tracker.dart';

class AnimatedPipelineCard extends StatelessWidget {
  const AnimatedPipelineCard({
    super.key,
    required this.stage,
  });

  final PipeStage stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildStage(stage, context),
      ),
    );
  }

  Widget _buildStage(PipeStage stage, BuildContext context) {
    switch (stage) {
      case PipeStage.uploading:
        return const _UploadingView(key: ValueKey('uploading'));
      case PipeStage.transcribing:
        return const _TranscribingView(key: ValueKey('transcribing'));
      case PipeStage.summarizing:
        return const _SummarizingView(key: ValueKey('summarizing'));
      case PipeStage.ready:
        return const _ReadyView(key: ValueKey('ready'));
      case PipeStage.error:
      case PipeStage.local:
      case PipeStage.uploaded:
        return const _ErrorView(key: ValueKey('error'));
    }
  }
}

class _UploadingView extends StatelessWidget {
  const _UploadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          'Uploading...',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          'Uploading your recording',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          height: 36,
          width: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
    );
  }
}

class _TranscribingView extends StatelessWidget {
  const _TranscribingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.graphic_eq, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          'Transcribing...',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          'Converting audio to text',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
        const SizedBox(height: 16),
        const _PulsingDot(),
      ],
    );
  }
}

class _SummarizingView extends StatelessWidget {
  const _SummarizingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.notes_outlined, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          'Summarizing...',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          'Structuring your notes',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
        const SizedBox(height: 16),
        const _ThreeDots(),
      ],
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          'Summary Ready',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          'View in Library',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
        const SizedBox(height: 8),
        Text(
          'Something went wrong',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Retry your upload',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.1).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      )),
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ThreeDots extends StatefulWidget {
  const _ThreeDots();

  @override
  State<_ThreeDots> createState() => _ThreeDotsState();
}

class _ThreeDotsState extends State<_ThreeDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final progress = (_controller.value + index * 0.25) % 1.0;
              final opacity = 0.3 + 0.7 * (1 - (progress - 0.5).abs() * 2);
              final scale = 0.75 + 0.25 * (1 - (progress - 0.5).abs() * 2);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: index == 1 ? 6 : 4),
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale.clamp(0.75, 1.0),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

