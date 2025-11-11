import '../../services/logger.dart';

/// Canonical recording status enum - single source of truth
/// Maps directly to Postgres enum recording_status
enum RecordingStatus {
  local,
  uploading,
  transcribing,
  summarizing,
  ready,
  error;

  /// Convert string to RecordingStatus with strict validation
  /// If string is not one of the 6 canonical values, returns error and logs
  static RecordingStatus fromString(String? s) {
    if (s == null || s.isEmpty) {
      logx('[STATUS] null/empty status → error', tag: 'STATUS');
      return RecordingStatus.error;
    }

    // Try exact match first
    for (final status in RecordingStatus.values) {
      if (status.name == s) {
        return status;
      }
    }

    // Log unsupported status and return error
    logx('[STATUS] unsupported="$s" → error', tag: 'STATUS');
    return RecordingStatus.error;
  }

  /// Convert to string for database storage
  String toDbString() => name;

  /// Check if this is a terminal state (no further transitions expected)
  bool get isTerminal => this == ready || this == error;

  /// Check if this is an active processing state
  bool get isProcessing => this == uploading || this == transcribing || this == summarizing;

  /// Check if this is the initial state
  bool get isInitial => this == local;
}
