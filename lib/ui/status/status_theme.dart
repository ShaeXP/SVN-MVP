import 'package:flutter/material.dart';
import '../../domain/recordings/recording_status.dart';

/// Status theme mapping - single source of truth for UI appearance
/// Maps each RecordingStatus to its visual representation
class StatusTheme {
  final String label;
  final double? progress; // 0.0 to 1.0, null means no progress bar
  final String animKey; // Key for choosing animation variant
  final Color chipTone; // Light/dark intent for chip styling
  final IconData icon;

  const StatusTheme({
    required this.label,
    this.progress,
    required this.animKey,
    required this.chipTone,
    required this.icon,
  });

  /// Get theme for a specific status
  static StatusTheme forStatus(RecordingStatus status) {
    return _themes[status]!;
  }

  /// All status themes mapped by status
  static const Map<RecordingStatus, StatusTheme> _themes = {
    RecordingStatus.local: StatusTheme(
      label: 'Local',
      progress: 0.0,
      animKey: 'idle',
      chipTone: Colors.blue,
      icon: Icons.file_upload_outlined,
    ),
    RecordingStatus.uploading: StatusTheme(
      label: 'Uploading…',
      progress: 0.15,
      animKey: 'upload',
      chipTone: Colors.orange,
      icon: Icons.cloud_upload_outlined,
    ),
    RecordingStatus.transcribing: StatusTheme(
      label: 'Transcribing…',
      progress: 0.45,
      animKey: 'transcribe',
      chipTone: Colors.purple,
      icon: Icons.mic_outlined,
    ),
    RecordingStatus.summarizing: StatusTheme(
      label: 'Summarizing…',
      progress: 0.75,
      animKey: 'summarize',
      chipTone: Colors.indigo,
      icon: Icons.auto_awesome_outlined,
    ),
    RecordingStatus.ready: StatusTheme(
      label: 'Ready',
      progress: 1.0,
      animKey: 'done',
      chipTone: Colors.green,
      icon: Icons.check_circle_outline,
    ),
    RecordingStatus.error: StatusTheme(
      label: 'Failed',
      progress: null,
      animKey: 'error',
      chipTone: Colors.red,
      icon: Icons.error_outline,
    ),
  };

  /// Get chip color based on theme and brightness
  Color getChipColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark 
        ? chipTone.withValues(alpha: 0.2)
        : chipTone.withValues(alpha: 0.1);
  }

  /// Get chip text color based on theme and brightness
  Color getChipTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark 
        ? chipTone.withValues(alpha: 0.8)
        : chipTone;
  }

  /// Get chip border color based on theme and brightness
  Color getChipBorderColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark 
        ? chipTone.withValues(alpha: 0.3)
        : chipTone.withValues(alpha: 0.2);
  }
}
