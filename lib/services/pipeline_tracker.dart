import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger.dart';

enum PipeStage { local, uploading, uploaded, transcribing, summarizing, ready, error }

PipeStage stageFrom(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'local': return PipeStage.local;
    case 'uploading': return PipeStage.uploading;
    case 'uploaded': return PipeStage.uploaded;
    case 'transcribing': return PipeStage.transcribing;
    case 'summarizing': return PipeStage.summarizing;
    case 'ready': return PipeStage.ready;
    case 'error': return PipeStage.error;
    default: return PipeStage.local;
  }
}

class PipelineTracker extends GetxService {
  static PipelineTracker get I => Get.find<PipelineTracker>();

  final _sb = Supabase.instance.client;
  bool _transcriptColumnWarningLogged = false;

  // public observables (for one active run UI)
  final recordingId = RxnString();
  final status = Rx<PipeStage>(PipeStage.local);
  final message = ''.obs;
  
  // Debug: Track instance to verify singleton
  final String _instanceId = DateTime.now().millisecondsSinceEpoch.toString();

  RealtimeChannel? _chan;
  Timer? _poll;
  Timer? _fallbackPoll;
  DateTime? _lastRealtimeEvent;

  Future<PipelineTracker> init() async {
    logx('[PIPEHUD] PipelineTracker initialized', tag: 'PIPE');
    return this;
  }

  /// Start tracking a recording row by id.
  void start(String recId, {bool openHud = true}) {
    debugPrint('[PIPEHUD] start() called for $recId');
    logx('[PIPEHUD] start() called for $recId (instance=$_instanceId)', tag: 'PIPE');
    stop();
    recordingId.value = recId;
    status.value = PipeStage.local;
    message.value = 'Starting…';
    debugPrint('[PIPEHUD] Tracking started for $recId, initial status=local');
    logx('[PIPEHUD] Tracking started for $recId, initial status=local', tag: 'PIPE');
    _subscribe(recId);
    // Immediately fetch current status to avoid showing stale "local" state
    // Use Future.microtask to ensure it runs after the current frame
    debugPrint('[PIPEHUD] Starting initial fetch for $recId...');
    Future.microtask(() async {
      try {
        await _fetch(recId);
        debugPrint('[PIPEHUD] Initial fetch completed, status=${status.value}');
        logx('[PIPEHUD] Initial fetch completed, status=${status.value} (instance=$_instanceId)', tag: 'PIPE');
      } catch (e) {
        debugPrint('[PIPEHUD] Initial fetch failed: $e');
        logx('[PIPEHUD] Initial fetch failed', tag: 'PIPE', error: e);
      }
    });
    _poll = Timer.periodic(const Duration(seconds: 2), (_) {
      debugPrint('[PIPEHUD] Periodic poll triggered');
      _fetch(recId);
    });
  }

  /// Mark that function invoke has started (function timing fallback)
  void markInvokeStarted() {
    if (status.value == PipeStage.uploaded) {
      status.value = PipeStage.transcribing;
      logx('[PIPEHUD] stage: uploaded -> transcribing (driver=function)', tag: 'PIPE');
      
      // Set summarizing after 5s if still transcribing
      Timer(const Duration(seconds: 5), () {
        if (status.value == PipeStage.transcribing) {
          status.value = PipeStage.summarizing;
          logx('[PIPEHUD] stage: transcribing -> summarizing (driver=timer)', tag: 'PIPE');
        }
      });
    }
  }

  void stop() {
    _chan?.unsubscribe();
    _chan = null;
    _poll?.cancel();
    _poll = null;
    _fallbackPoll?.cancel();
    _fallbackPoll = null;
    _lastRealtimeEvent = null;
    logx('[PIPEHUD] Tracking stopped', tag: 'PIPE');
  }


  void _onRecordingsUpdate(Map<String, dynamic>? row) {
    if (row == null) return;
    _lastRealtimeEvent = DateTime.now();
    
    final recordingStatus = row['status'] as String?;
    logx('[PIPEHUD] recordings update: status=$recordingStatus, current=${status.value}', tag: 'PIPE');
    
    // Derive stage based on recordings status (consistent with _fetch logic)
    if (recordingStatus == 'error') {
      status.value = PipeStage.error;
      // Try to get error message from available columns
      final errorMsg = row['error_msg'] ?? row['last_error'] ?? row['error_message'] ?? 'Unknown error';
      message.value = errorMsg.toString();
      logx('[PIPEHUD] stage: error', tag: 'PIPE');
    } else if (recordingStatus == 'uploading') {
      status.value = PipeStage.uploading;
      logx('[PIPEHUD] stage: uploading (driver=realtime)', tag: 'PIPE');
    } else if (recordingStatus == 'transcribing') {
      status.value = PipeStage.transcribing;
      logx('[PIPEHUD] stage: transcribing (driver=realtime)', tag: 'PIPE');
    } else if (recordingStatus == 'uploaded') {
      // Check if we have summary to determine if ready
      // If not, we'll rely on _fetch to check for transcripts/summaries
      // For now, advance to transcribing if we were uploading
      if (status.value == PipeStage.uploading) {
        status.value = PipeStage.transcribing;
        logx('[PIPEHUD] stage: uploading -> transcribing (status=uploaded, driver=realtime)', tag: 'PIPE');
      }
    }
  }

  void _onTranscriptInserted() {
    _lastRealtimeEvent = DateTime.now();
    if (status.value == PipeStage.transcribing) {
      status.value = PipeStage.summarizing;
      logx('[PIPEHUD] stage: transcribing -> summarizing (driver=realtime)', tag: 'PIPE');
    }
  }

  void _onSummaryInserted() {
    _lastRealtimeEvent = DateTime.now();
    if (status.value == PipeStage.summarizing) {
      status.value = PipeStage.ready;
      logx('[PIPEHUD] stage: summarizing -> ready (driver=realtime)', tag: 'PIPE');
    }
  }

  void _subscribe(String recId) {
    final uid = _sb.auth.currentSession?.user.id;
    if (uid == null) {
      logx('[PIPEHUD] Cannot subscribe - no user', tag: 'PIPE');
      return;
    }

    _chan = _sb
        .channel('pipe-$recId')
        // Watch recordings table for status updates
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'recordings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: recId,
          ),
          callback: (payload) {
            try {
              final row = payload.newRecord;
              logx('[PIPEHUD] recordings update ${row['status']}', tag: 'PIPE');
              _onRecordingsUpdate(row);
            } catch (e) {
              logx('[PIPEHUD] recordings callback error', tag: 'PIPE', error: e);
            }
          },
        )
        // Watch transcripts table for inserts (transcribing -> summarizing)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'transcripts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recording_id',
            value: recId,
          ),
          callback: (payload) {
            try {
              logx('[PIPEHUD] transcript inserted', tag: 'PIPE');
              _onTranscriptInserted();
            } catch (e) {
              logx('[PIPEHUD] transcript callback error', tag: 'PIPE', error: e);
            }
          },
        )
        // Watch summaries table for inserts (summarizing -> ready)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'summaries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recording_id',
            value: recId,
          ),
          callback: (payload) {
            try {
              logx('[PIPEHUD] summary inserted', tag: 'PIPE');
              _onSummaryInserted();
            } catch (e) {
              logx('[PIPEHUD] summary callback error', tag: 'PIPE', error: e);
            }
          },
        )
        .subscribe((status, err) {
          if (err != null) {
            logx('[PIPEHUD] sub err $err', tag: 'PIPE');
          } else {
            logx('[PIPEHUD] subscribed successfully', tag: 'PIPE');
          }
        });

    // kick one fetch immediately
    _fetch(recId);
    
    // Start fallback polling after 20s if no realtime events
    _fallbackPoll = Timer(const Duration(seconds: 20), () {
      _startFallbackPolling(recId);
    });
  }

  Future<void> _fetch(String recId) async {
    try {
      // Get recording status (only select columns that exist)
      final row = await _sb
          .from('recordings')
          .select('status')
          .eq('id', recId)
          .maybeSingle();
      
      if (row != null) {
        debugPrint('[PIPEHUD] poll: status=${row['status']}, recId=$recId');
        logx('[PIPEHUD] poll ${row['status']}', tag: 'PIPE');
        
        // Check for transcripts and summaries to determine actual stage
        // Wrap in try-catch in case tables/columns don't exist
        bool? hasTranscript;
        bool? hasSummary;
        
        try {
          final transcriptRow = await _sb
              .from('transcripts')
              .select('id')
              .eq('recordingId', recId) // TODO: align with actual transcripts schema (maybe 'recordingId')
              .maybeSingle();
          hasTranscript = transcriptRow != null;
        } on PostgrestException catch (e) {
          if ((e.code == '42703' || e.message?.contains('recordingId') == true) && !_transcriptColumnWarningLogged) {
            _transcriptColumnWarningLogged = true;
            debugPrint('[PIPEHUD] transcripts.recordingId missing – falling back to snake_case');
          }
          try {
            final transcriptRow = await _sb
                .from('transcripts')
                .select('id')
                .eq('recording_id', recId)
                .maybeSingle();
            hasTranscript = transcriptRow != null;
          } on PostgrestException catch (inner) {
            if ((inner.code == '42703' || inner.message?.contains('recording_id') == true) && !_transcriptColumnWarningLogged) {
              _transcriptColumnWarningLogged = true;
              debugPrint('[PIPEHUD] transcripts.recording_id missing – skipping transcript probe');
            }
            hasTranscript = null;
          }
        } catch (e) {
          if (!_transcriptColumnWarningLogged) {
            _transcriptColumnWarningLogged = true;
            debugPrint('[PIPEHUD] Could not check transcripts table: $e');
          }
          hasTranscript = null; // Unknown
        }
            
        try {
          final summaryRow = await _sb
              .from('summaries')
              .select('id')
              .eq('recording_id', recId)
              .maybeSingle();
          hasSummary = summaryRow != null;
        } catch (e) {
          debugPrint('[PIPEHUD] Could not check summaries table: $e');
          hasSummary = null; // Unknown
        }
        
        debugPrint('[PIPEHUD] poll result: status=${row['status']}, hasTranscript=$hasTranscript, hasSummary=$hasSummary');
        
        // Derive stage based on what exists
        final recordingStatus = row['status'] as String?;
        PipeStage derivedStage = PipeStage.local; // Default to local if status unclear
        debugPrint('[PIPEHUD] Current stage=${status.value}, recordingStatus=$recordingStatus');
        
        if (recordingStatus == 'error') {
          derivedStage = PipeStage.error;
        } else if (recordingStatus == 'uploading') {
          derivedStage = PipeStage.uploading; // Keep uploading stage to show proper UI
        } else if (recordingStatus == 'transcribing') {
          derivedStage = PipeStage.transcribing;
        } else if (recordingStatus == 'uploaded') {
          // Status is 'uploaded' - check if we have transcripts/summaries to determine next stage
          if (hasSummary == true) {
            derivedStage = PipeStage.ready;
          } else if (hasTranscript == true && hasSummary == false) {
            derivedStage = PipeStage.summarizing;
          } else {
            // Can't determine from tables, but status says uploaded, so likely transcribing next
            derivedStage = PipeStage.transcribing;
          }
        } else if (hasTranscript == true && hasSummary == false) {
          // Have transcript but no summary yet
          derivedStage = PipeStage.summarizing;
        } else if (hasSummary == true) {
          // Have summary - ready
          derivedStage = PipeStage.ready;
        } else if (recordingStatus == null || recordingStatus.isEmpty) {
          // If no status, check if we have any related records
          if (hasTranscript == true) {
            derivedStage = hasSummary == true ? PipeStage.ready : PipeStage.summarizing;
          } else {
            derivedStage = PipeStage.uploading; // Assume still uploading if no status
          }
        }
        
        // Always update if different (fix for stuck status)
        if (derivedStage != status.value) {
          final oldStage = status.value;
          status.value = derivedStage;
          debugPrint('[PIPEHUD] stage: $oldStage -> $derivedStage (driver=poll, status=$recordingStatus)');
          logx('[PIPEHUD] stage: $oldStage -> $derivedStage (driver=poll, status=$recordingStatus)', tag: 'PIPE');
          // Force reactive update - trigger notification even if value is same enum
          status.refresh();
          recordingId.refresh(); // Also refresh recordingId to ensure reactive chain updates
          
          if (derivedStage == PipeStage.error) {
            // Try to get error message from available columns
            final errorMsg = row['error_msg'] ?? row['last_error'] ?? row['error_message'] ?? 'Unknown error';
            message.value = errorMsg.toString();
          } else {
            message.value = '';
          }
        } else {
          debugPrint('[PIPEHUD] poll stage unchanged: $derivedStage (current=${status.value})');
          logx('[PIPEHUD] poll stage unchanged: $derivedStage', tag: 'PIPE');
        }
      } else {
        debugPrint('[PIPEHUD] poll: row is null for recId=$recId');
      }
    } catch (e) {
      debugPrint('[PIPEHUD] poll err: $e');
      logx('[PIPEHUD] poll err', tag: 'PIPE', error: e);
    }
  }

  void _startFallbackPolling(String recId) {
    // Only start fallback if we haven't received realtime events recently
    if (_lastRealtimeEvent != null && 
        DateTime.now().difference(_lastRealtimeEvent!).inSeconds < 15) {
      logx('[PIPEHUD] realtime working, skipping fallback', tag: 'PIPE');
      return;
    }
    
    logx('[PIPEHUD] starting fallback polling', tag: 'PIPE');
    var pollCount = 0;
    const maxPolls = 12; // 12 * 5s = 60s max
    
    _fallbackPoll?.cancel();
    _fallbackPoll = Timer.periodic(const Duration(seconds: 5), (timer) async {
      pollCount++;
      
      // Stop if we've reached ready or error, or max polls
      if (status.value == PipeStage.ready || 
          status.value == PipeStage.error || 
          pollCount >= maxPolls) {
        timer.cancel();
        logx('[PIPEHUD] fallback polling stopped (stage: ${status.value}, polls: $pollCount)', tag: 'PIPE');
        return;
      }
      
      await _fetch(recId);
    });
  }

  // Helper methods for progress indicator
  double get progressPercentage {
    switch (status.value) {
      case PipeStage.local: return 0.0;
      case PipeStage.uploading: return 0.1;
      case PipeStage.uploaded: return 0.25;
      case PipeStage.transcribing: return 0.50;
      case PipeStage.summarizing: return 0.75;
      case PipeStage.ready: return 1.0;
      case PipeStage.error: return 0.0;
    }
  }

  String get stageLabel {
    switch (status.value) {
      case PipeStage.local: return 'Local';
      case PipeStage.uploading: return 'Uploading...';
      case PipeStage.uploaded: return 'Uploaded';
      case PipeStage.transcribing: return 'Transcribing...';
      case PipeStage.summarizing: return 'Summarizing...';
      case PipeStage.ready: return 'Ready!';
      case PipeStage.error: return 'Error';
    }
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}

