import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../feature_flags.dart';
import '../models/pipeline_progress.dart';
import '../app/routes/app_routes.dart';
import '../domain/recordings/recording_status.dart';
import '../controllers/recording_state_coordinator.dart';
import '../services/unified_realtime_service.dart';

class ProgressController extends GetxController {
  final progress = PipelineProgress.fromStatus('local').obs;
  final visible = false.obs;
  final failed = false.obs;

  RealtimeChannel? _chan;
  String? _recordingId;

  void start(String recordingId) {
    if (!ProgressUI.enabled) return;
    
    _recordingId = recordingId;
    visible.value = true;

    // Use the new unified realtime service
    final realtimeService = Get.find<UnifiedRealtimeService>();
    realtimeService.watchRecording(recordingId);

    // Also maintain backward compatibility with existing progress tracking
    _chan?.unsubscribe();
    final client = Supabase.instance.client;

    // Emit initial snapshot
    client.from('recordings')
      .select('status, summary_id')
      .eq('id', recordingId)
      .maybeSingle()
      .then((row){
        if (row != null) {
          final s = row['status'] as String?;
          progress.value = PipelineProgress.fromStatus(s);
        }
      });

    // Narrow realtime subscription to this row only
    _chan = client.channel('progress-$recordingId');
    _chan!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'recordings',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: recordingId,
      ),
      callback: (payload) {
        final next = payload.newRecord;
        final status = next['status'] as String?;
        final summaryId = next['summary_id'] as String?;
        final p = PipelineProgress.fromStatus(status);
        progress.value = p;
        failed.value = p.stage == 'error';

        if (p.stage == 'ready') {
          visible.value = false;
          // Auto-nav to summary screen; prefer summaryId if available
          if (summaryId is String && summaryId.isNotEmpty) {
            Get.offNamed(Routes.recordingSummaryScreen, arguments: {'summaryId': summaryId});
          } else {
            Get.offNamed(Routes.recordingSummaryScreen, arguments: {'recordingId': recordingId});
          }
          // optional: unsubscribe after nav
          stop();
        }
      },
    );
    _chan!.subscribe();
  }

  void stop() {
    if (_chan != null) {
      final client = Supabase.instance.client;
      client.removeChannel(_chan!);
      _chan = null;
    }
    visible.value = false;
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}
