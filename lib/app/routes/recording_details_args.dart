/// Typed arguments for navigating to Recording Details screen
class RecordingDetailsArgs {
  final String recordingId;
  final String? summaryId;
  
  const RecordingDetailsArgs(this.recordingId, {this.summaryId});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingDetailsArgs &&
          runtimeType == other.runtimeType &&
          recordingId == other.recordingId &&
          summaryId == other.summaryId;

  @override
  int get hashCode => Object.hash(recordingId, summaryId);
  
  @override
  String toString() => 'RecordingDetailsArgs(recordingId: $recordingId, summaryId: $summaryId)';
}
