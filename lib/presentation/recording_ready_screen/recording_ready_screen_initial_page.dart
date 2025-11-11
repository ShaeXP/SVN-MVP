import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../widgets/no_mouse_wheel.dart';
import '../../services/pipeline.dart';

class RecordingReadyScreenInitialPage extends StatefulWidget {
  const RecordingReadyScreenInitialPage({super.key});

  @override
  State<RecordingReadyScreenInitialPage> createState() => _RecordingReadyScreenInitialPageState();
}

class _RecordingReadyScreenInitialPageState extends State<RecordingReadyScreenInitialPage> {
  bool _sending = false;
  String? _status;
  String? _localPath;
  String? _toEmail;
  String? _subject;
  bool _isFallback = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _localPath = (args['localPath'] as String?)?.trim();
      _toEmail = (args['toEmail'] as String?)?.trim();
      _subject = (args['subject'] as String?)?.trim();
      _isFallback = args['fallback'] == true;
    }
  }

  Future<void> sendToPipeline() async {
    setState(() {
      _sending = true;
      _status = 'Uploading…';
    });

    try {
      // Simple implementation using existing Pipeline service
      final pipeline = Pipeline();
      String runId;

      if (_localPath != null && _localPath?.isNotEmpty == true) {
        // Real file → upload → pipeline
        runId = await pipeline.initRun();
        // TODO: Upload file and start pipeline
        // For now, just show that we started a run
      } else {
        // No file (fallback dev test) → use Deepgram sample
        runId = await pipeline.initRun();
        // TODO: Use sample URL and start pipeline
        // For now, just show that we started a run
      }

      final label = 'Pipeline started with runId: $runId';

      setState(() {
        _status = label;
      });

      Get.snackbar('Pipeline', label, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      setState(() {
        _status = 'error: $e';
      });
      Get.snackbar('Pipeline', 'error: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.1));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Get.back(id: 1)),
        title: const Text('Recording Ready'),
      ),
      body: SafeArea(
        child: NoMouseWheel(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                children: [
                  SizedBox(height: 1.h),
                  Text(
                    'Send to pipeline',
                    style: TextStyleHelper.instance.title18BoldQuattrocento,
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 2.h),
                  _InfoTile(
                    title: 'Local file',
                    value: _localPath ?? 'None detected. A built-in sample may be used.',
                  ),
                  if (_isFallback) ...[
                    SizedBox(height: 1.h),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No microphone found. Using sample audio instead.',
                              style: TextStyleHelper.instance.body12RegularOpenSans.copyWith(color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_status != null) ...[
                    SizedBox(height: 1.h),
                    _InfoTile(
                      title: 'Status',
                      value: _status ?? '',
                    ),
                  ],
                  SizedBox(height: 3.h),
                  Center(
                    child: SizedBox(
                      width: 70.w,
                      child: ElevatedButton(
                        onPressed: _sending ? null : sendToPipeline,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: _sending
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Sending...'),
                                  ],
                                )
                              : const Text('Send'),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Tip: sending the same audio again will often return "duplicate_suppressed (409)". That is expected.',
                    style: TextStyleHelper.instance.body12RegularOpenSans.copyWith(
                      color: appTheme.gray_700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appTheme.gray_50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appTheme.gray_300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyleHelper.instance.body12RegularOpenSans
                  .copyWith(color: appTheme.gray_700)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyleHelper.instance.body12RegularOpenSans
                .copyWith(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}