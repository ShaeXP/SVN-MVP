import 'package:flutter_test/flutter_test.dart';
import 'package:lashae_s_application/domain/recordings/recording_status.dart';
import 'package:lashae_s_application/ui/status/status_theme.dart';

void main() {
  group('Unified Status System Tests', () {
    test('RecordingStatus.fromString handles all valid values', () {
      expect(RecordingStatus.fromString('local'), RecordingStatus.local);
      expect(RecordingStatus.fromString('uploading'), RecordingStatus.uploading);
      expect(RecordingStatus.fromString('transcribing'), RecordingStatus.transcribing);
      expect(RecordingStatus.fromString('summarizing'), RecordingStatus.summarizing);
      expect(RecordingStatus.fromString('ready'), RecordingStatus.ready);
      expect(RecordingStatus.fromString('error'), RecordingStatus.error);
    });

    test('RecordingStatus.fromString handles invalid values', () {
      expect(RecordingStatus.fromString('unknown'), RecordingStatus.error);
      expect(RecordingStatus.fromString('processing'), RecordingStatus.error);
      expect(RecordingStatus.fromString(''), RecordingStatus.error);
      expect(RecordingStatus.fromString(null), RecordingStatus.error);
    });

    test('StatusTheme provides correct mappings', () {
      final localTheme = StatusTheme.forStatus(RecordingStatus.local);
      expect(localTheme.label, 'Local');
      expect(localTheme.progress, 0.0);
      expect(localTheme.animKey, 'idle');

      final uploadingTheme = StatusTheme.forStatus(RecordingStatus.uploading);
      expect(uploadingTheme.label, 'Uploading…');
      expect(uploadingTheme.progress, 0.15);
      expect(uploadingTheme.animKey, 'upload');

      final readyTheme = StatusTheme.forStatus(RecordingStatus.ready);
      expect(readyTheme.label, 'Ready');
      expect(readyTheme.progress, 1.0);
      expect(readyTheme.animKey, 'done');

      final errorTheme = StatusTheme.forStatus(RecordingStatus.error);
      expect(errorTheme.label, 'Failed');
      expect(errorTheme.progress, null);
      expect(errorTheme.animKey, 'error');
    });

    test('RecordingStatus state properties work correctly', () {
      expect(RecordingStatus.local.isInitial, true);
      expect(RecordingStatus.local.isTerminal, false);
      expect(RecordingStatus.local.isProcessing, false);

      expect(RecordingStatus.uploading.isInitial, false);
      expect(RecordingStatus.uploading.isTerminal, false);
      expect(RecordingStatus.uploading.isProcessing, true);

      expect(RecordingStatus.ready.isInitial, false);
      expect(RecordingStatus.ready.isTerminal, true);
      expect(RecordingStatus.ready.isProcessing, false);

      expect(RecordingStatus.error.isInitial, false);
      expect(RecordingStatus.error.isTerminal, true);
      expect(RecordingStatus.error.isProcessing, false);
    });
  });
}
