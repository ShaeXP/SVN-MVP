import 'package:flutter/material.dart';
import '../animation/anim_flags.dart';

class PipelineRingLottie extends StatefulWidget {
  final double progress; // 0..1
  final String stage;    // uploading|transcribing|summarizing|ready|error
  const PipelineRingLottie({super.key, required this.progress, required this.stage});

  @override
  State<PipelineRingLottie> createState() => _PipelineRingLottieState();
}

class _PipelineRingLottieState extends State<PipelineRingLottie>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Rotation animation for active states
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // Progress animation for smooth transitions
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: widget.progress,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    _progressController.value = 1.0; // Start at end value
    
    // Start rotation animation if initial stage is active
    final isActive = widget.stage != 'ready' && widget.stage != 'error';
    if (isActive) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(PipelineRingLottie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stage != oldWidget.stage) {
      if (widget.stage == 'ready' || widget.stage == 'error') {
        _rotationController.stop();
        _rotationController.reset();
      } else {
        _rotationController.repeat();
      }
    }
    // Animate progress changes smoothly
    if (widget.progress != oldWidget.progress) {
      final currentValue = _progressAnimation.value;
      _progressAnimation = Tween<double>(
        begin: currentValue,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));
      _progressController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Color _getStageColor() {
    switch (widget.stage) {
      case 'uploading':
        return Colors.blue;
      case 'transcribing':
        return Colors.orange;
      case 'summarizing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AnimFlags.lottieEnabled(),
      builder: (_, snap) {
        final enabled = snap.data ?? false;
        if (!enabled) return _fallback();

        final isActive = widget.stage != 'ready' && widget.stage != 'error';
        
        return AnimatedBuilder(
          animation: Listenable.merge([_rotationAnimation, _progressAnimation]),
          builder: (context, child) {
            return Container(
              width: 112,
              height: 112,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  // Progress arc with smooth animation
                  SizedBox(
                    width: 112,
                    height: 112,
                    child: CircularProgressIndicator(
                      value: _progressAnimation.value,
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(_getStageColor()),
                    ),
                  ),
                  // Rotating indicator for active states
                  if (isActive)
                    Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStageColor(),
                          boxShadow: [
                            BoxShadow(
                              color: _getStageColor().withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Stage text
                  Text(
                    widget.stage.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStageColor(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _fallback() {
    return Container(
      width: 112, height: 112,
      decoration: BoxDecoration(border: Border.all(color: Colors.orangeAccent, width: 2), borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text('Lottie OFF\n${(widget.progress*100).toStringAsFixed(0)}%', textAlign: TextAlign.center),
    );
  }
}