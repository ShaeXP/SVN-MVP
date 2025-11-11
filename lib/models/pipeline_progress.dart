import '../domain/recordings/recording_status.dart';
import '../ui/status/status_theme.dart';

/// Legacy PipelineProgress class - now uses unified status system
/// This maintains backward compatibility while delegating to the new system
class PipelineProgress {
  final String stage;   // local|uploading|transcribing|summarizing|ready|error
  final double percent; // 0..1
  final String label;
  const PipelineProgress(this.stage, this.percent, this.label);

  static PipelineProgress fromStatus(String? s) {
    // Convert string to RecordingStatus enum
    final status = RecordingStatus.fromString(s);
    
    // Get theme from unified system
    final theme = StatusTheme.forStatus(status);
    
    // Return legacy format for backward compatibility
    return PipelineProgress(
      status.name,
      theme.progress ?? 0.0,
      theme.label,
    );
  }
}
