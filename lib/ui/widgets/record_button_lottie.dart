import 'package:flutter/material.dart';
import '../animation/anim_flags.dart';

class RecordButtonLottie extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onTap;
  const RecordButtonLottie({super.key, required this.isRecording, required this.onTap});

  @override
  State<RecordButtonLottie> createState() => _RecordButtonLottieState();
}

class _RecordButtonLottieState extends State<RecordButtonLottie>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for recording state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation for recording state
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
  }

  @override
  void didUpdateWidget(RecordButtonLottie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _pulseController.repeat(reverse: true);
        _rotationController.repeat();
      } else {
        _pulseController.stop();
        _rotationController.stop();
        _pulseController.reset();
        _rotationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AnimFlags.lottieEnabled(),
      builder: (_, snap) {
        final enabled = snap.data ?? false;
        if (!enabled) {
          return _fallback();
        }
        
        return GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isRecording ? _pulseAnimation.value : 1.0,
                child: Transform.rotate(
                  angle: widget.isRecording ? _rotationAnimation.value * 2 * 3.14159 : 0.0,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isRecording 
                          ? Colors.red.withOpacity(0.8)
                          : Colors.blue.withOpacity(0.8),
                      border: Border.all(
                        color: widget.isRecording ? Colors.red : Colors.blue,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isRecording 
                              ? Colors.red.withOpacity(0.3)
                              : Colors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isRecording ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _fallback() {
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(48),
          border: Border.all(color: Colors.pinkAccent, width: 2),
        ),
        child: const Text('Lottie OFF', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}
