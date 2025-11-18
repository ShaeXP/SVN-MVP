// lib/services/pipeline_trigger_service.dart
// Unified service for triggering the pipeline with consistent style key handling

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../models/summary_style_option.dart';
import '../presentation/settings_screen/controller/settings_controller.dart';
import '../controllers/record_controller.dart';
import 'pipeline_tracker.dart';
import '../debug/metrics_tracker.dart';

/// Unified service for triggering the pipeline with consistent style key handling
class PipelineTriggerService {
  static PipelineTriggerService? _instance;
  static PipelineTriggerService get instance => _instance ??= PipelineTriggerService._();
  
  PipelineTriggerService._();
  
  final _supabase = Supabase.instance.client;

  /// Run pipeline for a recording with the selected summary style
  /// This is the SINGLE entry point for triggering the pipeline from both upload and live recording flows
  Future<void> runPipelineForRecording({
    required String recordingId,
    required String storagePath,
    String? summaryStyleKeyOverride,
  }) async {
    // Resolve style key: override → RecordController → SettingsController → default
    String styleKey = summaryStyleKeyOverride ?? '';
    
    if (styleKey.isEmpty) {
      // Try to get from RecordController if available
      if (Get.isRegistered<RecordController>()) {
        try {
          final recordController = Get.find<RecordController>();
          styleKey = recordController.selectedSummaryStyle.value.key;
        } catch (e) {
          debugPrint('[PIPELINE_TRIGGER] Could not get style from RecordController: $e');
        }
      }
    }
    
    if (styleKey.isEmpty) {
      // Fall back to SettingsController
      if (Get.isRegistered<SettingsController>()) {
        try {
          final settingsController = Get.find<SettingsController>();
          styleKey = settingsController.summarizeStyle.value;
        } catch (e) {
          debugPrint('[PIPELINE_TRIGGER] Could not get style from SettingsController: $e');
        }
      }
    }
    
    // Final fallback to default
    if (styleKey.isEmpty) {
      styleKey = SummaryStyles.quickRecapActionItems.key;
    }
    
    debugPrint('[PIPELINE] run for recording=$recordingId styleKey=$styleKey');
    
    // Generate trace ID
    final traceId = '${DateTime.now().millisecondsSinceEpoch}-${recordingId.substring(0, 8)}';
    
    // Get user email for notifications
    final user = _supabase.auth.currentUser;
    final userEmail = user?.email;
    
    // Start pipeline tracking
    PipelineTracker.I.start(recordingId, openHud: false);
    
    // Track pipeline start time for metrics (debug only)
    if (kDebugMode) {
      MetricsTracker.I.trackPipelineStart(recordingId);
    }
    
    // Invoke edge function with style key
    final payload = {
      'recordingId': recordingId,
      'recording_id': recordingId, // snake_case for compatibility
      'storagePath': storagePath,
      'storage_path': storagePath, // snake_case for compatibility
      'traceId': traceId,
      'trace_id': traceId, // snake_case for compatibility
      'summary_style_key': styleKey, // Primary field
      'summary_style': styleKey, // Legacy field for backward compatibility
      'summaryStyle': styleKey, // Legacy camelCase field
      if (userEmail != null) 'notifyEmail': userEmail,
      if (userEmail != null) 'notify_email': userEmail, // snake_case
    };
    
    debugPrint('[PIPELINE] invoking sv_run_pipeline with payload keys: ${payload.keys.toList()}');
    
    try {
      final resp = await _supabase.functions.invoke(
        'sv_run_pipeline',
        body: payload,
      );
      
      debugPrint('[PIPELINE] sv_run_pipeline response: status=${resp.status}');
      
      if (resp.status >= 300) {
        final errorMsg = resp.data is Map 
            ? (resp.data['message']?.toString() ?? resp.data['error']?.toString() ?? '')
            : resp.data?.toString() ?? 'Unknown error';
        throw Exception('Pipeline trigger failed (${resp.status}): $errorMsg');
      }
      
      debugPrint('[PIPELINE] Pipeline triggered successfully for recording=$recordingId');
    } catch (e, stackTrace) {
      debugPrint('[PIPELINE] Error triggering pipeline: $e');
      debugPrint('[PIPELINE] Stack trace: $stackTrace');
      rethrow;
    }
  }
}

// Note: RecordController will be imported where this service is used

