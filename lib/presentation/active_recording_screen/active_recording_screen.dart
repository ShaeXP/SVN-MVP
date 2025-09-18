import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:lashae_s_application/core/app_export.dart';
import 'package:get/get.dart';
// lib/presentation/active_recording_screen/active_recording_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lashae_s_application/services/supabase_service.dart';
import 'package:lashae_s_application/widgets/session_debug_overlay.dart';

import '../../core/app_export.dart';
import '../../services/pipeline.dart';
import '../../services/recording.dart';
import 'package:lashae_s_application/bootstrap_supabase.dart' show Supa;

class ActiveRecordingScreen extends StatefulWidget {
  const ActiveRecordingScreen({super.key});

  @override
  State<ActiveRecordingScreen> createState() => _ActiveRecordingScreenState();
}

class _ActiveRecordingScreenState extends State<ActiveRecordingScreen> {
  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ State Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  bool _isRecording = false;
  bool _isSaving = false;

  File? _file; // recorded audio file
  int _durationMs = 0;

  final _pipeline = Pipeline();
  // Real mic on device, mock only for web preview
  final RecordingService recordingService =
      kIsWeb ? MockRecordingService() : RealRecordingService();

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Lifecycle Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Timer helpers Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  void _resetTimer() {
    _ticker?.cancel();
    _elapsed = Duration.zero;
    setState(() {});
  }

  void _startTimer() {
    _ticker?.cancel();
    _elapsed = Duration.zero;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Record control Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Future<void> _start() async {
    try {
      await recordingService.startRecording();
      setState(() {
        _isRecording = true;
        _file = null;
        _durationMs = 0;
      });
      _startTimer();
    } catch (e, st) {
      debugPrint('REC START ERROR: $e\n$st');
      _snack('Failed to start: $e');
    }
  }

  Future<void> _stop() async {
    try {
      final res = await recordingService.stopRecording();
      _ticker?.cancel();

      final f = res.file;
      final durMs = res.durationMs ?? _elapsed.inMilliseconds;

      final len = await f.length();
      debugPrint(
          'REC Ã¢â€ â€™ temp file: ${f.path}  (${len} bytes, ${durMs} ms)');

      setState(() {
        _isRecording = false;
        _file = f;
        _durationMs = durMs;
      });

      _showReviewSheet();
    } catch (e, st) {
      debugPrint('REC STOP ERROR: $e\n$st');
      _snack('Failed to stop: $e');
    }
  }

  void _onRedo() {
    Navigator.pop(context); // close sheet
    _resetTimer();
    setState(() {
      _isRecording = false;
      _file = null;
      _durationMs = 0;
    });
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Save flow Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Future<void> _onSave() async {
    debugPrint(
        'SAVE user=${SupabaseService.instance.client.auth.currentUser?.id}');

    if (_file == null || _durationMs <= 0 || _isSaving) {
      _snack('No recording data');
      return;
    }

    setState(() => _isSaving = true);

    String _step(String s) {
      debugPrint('Ã°Å¸â€Âµ SAVE step Ã¢â€ â€™ $s');
      return s;
    }

    Future<void> _fail(String where, Object e, StackTrace st) async {
      debugPrint('Ã¢ÂÅ’ SAVE FAILED @ $where: $e\n$st');
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Save failed'),
          content: SingleChildScrollView(child: Text('$where\n\n$e')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK')),
          ],
        ),
      );
      _snack('Save failed @ $where');
    }

    try {
      _step('check auth');
      final user =
          SupabaseService.instance.client.auth.currentUser; // unified client
      if (user == null) {
        throw Exception('Not signed in');
      }

      _step('initRun()');
      final runId = await _pipeline.initRun();

      final storagePath = 'user/${user.id}/$runId.m4a';

      _step('signUpload($storagePath)');
      final signedUrl = await _pipeline.signUpload(storagePath);

      final size = await _file!.length();
      _step('upload PUT ($size bytes)');
      await _uploadBytesPut(signedUrl, _file!, contentType: 'audio/m4a');

      _step('insertRecording(runId, storagePathOrUrl, durationMs)');
      await _pipeline.insertRecording(
        runId: runId,
        storagePathOrUrl: storagePath, // MUST match Pipeline signature
        durationMs: _durationMs,
      );

      _step('startAsr(runId, storagePath)');
      await _pipeline.startAsr(runId, storagePath);

      if (!mounted) return;
      Navigator.pop(context); // close sheet
      _step('navigate Ã¢â€ â€™ summary (run_id=$runId)');
      Get.toNamed(
        Routes.recordingSummaryScreen,
        arguments: {'run_id': runId},
      );
    } catch (e, st) {
      await _fail('_onSave()', e, st);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadBytesPut(String signedUrl, File file,
      {required String contentType}) async {
    final response = await http.put(
      Uri.parse(signedUrl),
      headers: {'Content-Type': contentType},
      body: await file.readAsBytes(),
    );
    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ UI helpers Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _showReviewSheet() {
    if (_file == null || _durationMs <= 0) {
      _snack('No recording data');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final canSave = !_isSaving && _file != null && _durationMs > 0;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text('Stop recording?',
                  style: TextStyleHelper.instance.title18MediumInter),
              const SizedBox(height: 4),
              Text(_fmt(Duration(milliseconds: _durationMs))),
              const SizedBox(height: 16),

              // Save
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final ok = !_isSaving && _file != null && _durationMs > 0;
                    debugPrint(
                      'UI Ã¢â€ â€™ Save tapped (canSave=$ok, file=${_file?.path}, dur=$_durationMs, isSaving=$_isSaving)',
                    );
                    if (ok) {
                      _onSave();
                    } else {
                      _snack(
                          'Save disabled: file=${_file?.path}, dur=$_durationMs, isSaving=$_isSaving');
                    }
                  },
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                ),
              ),

              const SizedBox(height: 8),
              // Redo
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _onRedo,
                  child: const Text('Redo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ),
              const SizedBox(height: 8),

              // Cancel
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ),
        );
      },
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Screen Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recorder')),
      body: Stack(
        children: [
          // Your existing content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Text(
                  _fmt(_elapsed),
                  style: TextStyleHelper.instance.display36BoldQuattrocento,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: appTheme.blue_200_01.withAlpha(51),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_isRecording)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                          onPressed: null,
                          child: const Icon(Icons.pause)), // optional
                      const SizedBox(width: 16),
                      ElevatedButton(
                          onPressed: _stop, child: const Icon(Icons.stop)),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.mic),
                    label: const Text('Record'),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Add the debug overlay
          SessionDebugOverlay(),
        ],
      ),
    );
  }
}
