import 'package:flutter/material.dart';

import '../util/pipeline_step.dart';

class PipelineProgress extends StatelessWidget {
  const PipelineProgress({
    super.key,
    required this.current,
  });

  final PipelineStep current;

  bool _isDone(PipelineStep step, PipelineStep effective) => step.index < effective.index;
  bool _isCurrent(PipelineStep step, PipelineStep effective) => step == effective;

  @override
  Widget build(BuildContext context) {
    final steps = const [
      PipelineStep.uploading,
      PipelineStep.transcribing,
      PipelineStep.summarizing,
      PipelineStep.ready,
    ];

    final hasError = current == PipelineStep.error;
    final effective = hasError ? PipelineStep.summarizing : current;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _PipelineNode(
            label: _labelFor(steps[i]),
            state: _isCurrent(steps[i], effective)
                ? _NodeState.active
                : _isDone(steps[i], effective)
                    ? _NodeState.done
                    : _NodeState.pending,
            showError: hasError && steps[i] == effective,
          ),
          if (i != steps.length - 1)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                    steps[i].index < effective.index ? 0.45 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ],
    );
  }

  String _labelFor(PipelineStep step) {
    switch (step) {
      case PipelineStep.uploading:
        return 'Upload';
      case PipelineStep.transcribing:
        return 'Transcribe';
      case PipelineStep.summarizing:
        return 'Summarize';
      case PipelineStep.ready:
        return 'Ready';
      case PipelineStep.error:
        return 'Error';
    }
  }
}

enum _NodeState { pending, active, done }

class _PipelineNode extends StatelessWidget {
  const _PipelineNode({
    required this.label,
    required this.state,
    this.showError = false,
  });

  final String label;
  final _NodeState state;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final isActive = state == _NodeState.active;
    final isDone = state == _NodeState.done;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withOpacity(0.16)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? Colors.white.withOpacity(0.5)
              : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isDone
                ? const Icon(Icons.check, key: ValueKey('done'), size: 16, color: Colors.white)
                : showError
                    ? const Icon(Icons.error_outline, key: ValueKey('error'), size: 16, color: Color(0xFFFF6B6B))
                    : isActive
                        ? const SizedBox(
                            key: ValueKey('active'),
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            key: ValueKey('pending'),
                            Icons.circle_outlined,
                            size: 14,
                            color: Colors.white38,
                          ),
          ),
          const SizedBox(width: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: showError
                  ? const Color(0xFFFF6B6B)
                  : Colors.white.withOpacity(isActive || isDone ? 1.0 : 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

