import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lashae_s_application/data/recording_repo.dart';
import 'package:lashae_s_application/services/pipeline_service.dart';
import 'package:lashae_s_application/services/function_probe.dart';
import 'package:lashae_s_application/presentation/recording_library_screen/widgets/status_chip.dart' as statusui;
import 'package:lashae_s_application/ui/visuals/brand_background.dart';
import 'package:lashae_s_application/ui/visuals/glass_card.dart';
import 'package:lashae_s_application/ui/theme/svn_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ui/util/safe_ui.dart';
import '../../controllers/recording_summary_controller.dart';
import '../../env.dart';
import '../../ui/util/pipeline_step.dart';
import '../../ui/widgets/pipeline_progress.dart';
import '../../ui/widgets/svn_card.dart';
import '../../ui/app_spacing.dart';
import '../../ui/widgets/svn_page.dart';

// Function name constant to prevent drift
const kFnEmailDocx = 'sv_email_summary_docx';

class RecordingSummaryScreen extends StatefulWidget {
  const RecordingSummaryScreen({super.key});

  @override
  State<RecordingSummaryScreen> createState() => _RecordingSummaryScreenState();
}

class _RecordingSummaryScreenState extends State<RecordingSummaryScreen> {
  final repo = RecordingRepo();
  final pipe = PipelineService();
  final probe = FunctionProbe();

  String recordingId = '';
  Map<String, dynamic>? summary;
  bool summarizing = false;
  bool rerunning = false;
  bool hasInvalidArgs = false;
  bool _sendingDocx = false;
  StreamSubscription<Map<String, dynamic>?>? _recordingSub;
  Map<String, dynamic>? _recordingRow;
  String _recordingStatus = 'processing';

  @override
  void initState() {
    super.initState();
    
    // Defensive argument parsing (supports both new and baseline formats)
    final args = Get.arguments as Map? ?? {};
    final recId = args['recordingId'] as String?;
    final sumId = args['summaryId'] as String?;
    final transcriptId = args['transcript_id'] as String?;
    final runId = args['run_id'] as String?;
    
    debugPrint('[SUMMARY] args recordingId=$recId summaryId=$sumId transcript_id=$transcriptId run_id=$runId');
    
    // Use recordingId if available, otherwise fall back to transcript_id/run_id
    final id = recId ?? transcriptId ?? runId;
    
    if (id == null || id.isEmpty) {
      debugPrint('[SUMMARY] Missing recordingId/transcript_id/run_id. args=$args');
      setState(() {
        hasInvalidArgs = true;
      });
      return;
    }
    
    recordingId = id;
    debugPrint('[SUMMARY] Using recordingId=$recordingId');
    
    // Initialize the summary controller
    if (!Get.isRegistered<RecordingSummaryController>()) {
      Get.put(RecordingSummaryController());
    }
    final controller = Get.find<RecordingSummaryController>();
    if (!controller.hasLoaded.value || controller.recordingId != recordingId) {
      controller.initWith(recordingId);
    }
    
    _loadSummary();
    _subscribeToRecording();
  }

  Future<void> _loadSummary() async {
    if (recordingId.isEmpty) return;
    try {
      final s = await repo.getSummaryByRecording(recordingId);
      if (mounted) {
        setState(() {
          summary = s;
        });
      }
    } catch (e) {
      debugPrint('Failed to load summary: $e');
    }
  }

  Future<void> _summarize() async {
    if (recordingId.isEmpty) return;
    setState(() {
      summarizing = true;
    });
    try {
      await pipe.rerunByRecordingId(recordingId);
      await _loadSummary();
    } catch (e) {
      debugPrint('Failed to summarize: $e');
    } finally {
      if (mounted) {
        setState(() {
          summarizing = false;
        });
      }
    }
  }

  Future<void> _rerun() async {
    if (recordingId.isEmpty) return;
    setState(() {
      rerunning = true;
    });
    try {
      await pipe.rerunByRecordingId(recordingId);
      await _loadSummary();
    } catch (e) {
      debugPrint('Failed to rerun: $e');
    } finally {
      if (mounted) {
        setState(() {
          rerunning = false;
        });
      }
    }
  }

  Future<void> _checkPipelineHealth() async {
    try {
      final health = await FunctionProbe.ping();
      if (mounted) {
        safeSnackBar(
          title: 'Pipeline Health',
          message: health.toString(),
        );
      }
    } catch (e) {
      if (mounted) {
        safeSnackBar(
          title: 'Health Check Failed',
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _deleteRecording(BuildContext context) async {
    if (recordingId.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text('Are you sure you want to delete this recording? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // TODO: Implement summary deletion if needed
        // For now, just show a message that deletion is not available
        Get.snackbar('Info', 'Summary deletion not yet implemented');
      } catch (e) {
        if (mounted) {
          safeSnackBar(
            title: 'Delete Failed',
            message: 'Failed to delete: $e',
          );
        }
      }
    }
  }

  void _subscribeToRecording() {
     _recordingSub?.cancel();
     if (recordingId.isEmpty) return;
 
     _recordingSub = repo.streamRecording(recordingId).listen((row) {
       if (!mounted) return;
       final status = (row?['status'] ?? 'processing').toString();
       final shouldLoadSummary =
           (status == 'uploaded' || status == 'processing' || status == 'ready') && summary == null;
      final hasPrevRow = _recordingRow != null;
      final prevStatus = _recordingStatus;
      final prevUpdated = _recordingRow?['updated_at'];
      final nextUpdated = row?['updated_at'];
 
      if (!(hasPrevRow && prevStatus == status && prevUpdated == nextUpdated)) {
        setState(() {
          _recordingRow = row;
          _recordingStatus = status;
        });
      }
 
       if (shouldLoadSummary) {
         _loadSummary();
       }
     });
   }

  @override
  void dispose() {
    _recordingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show inline error state for invalid arguments
    if (hasInvalidArgs) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Recording Details'),
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            const BrandGradientBackground(),
            Center(
              child: Padding(
                padding: AppSpacing.sectionPadding(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    AppSpacing.v(context, 1),
                    Text(
                      'Can\'t open recording',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    AppSpacing.v(context, 0.5),
                    Text(
                      'Missing recording ID',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    AppSpacing.v(context, 1.5),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // If recordingId is empty, show loading state
    if (recordingId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording Details'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Email DOCX button
          Material(
            type: MaterialType.transparency,
            child: IconButton(
              icon: _sendingDocx
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.email_outlined),
              tooltip: 'Email me a DOCX',
              onPressed: (recordingId.isEmpty || _sendingDocx) ? null : _emailDocx,
            ),
          ),
          // Delete button
          Material(
            type: MaterialType.transparency,
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: recordingId.isEmpty ? null : () => _deleteRecording(context),
            ),
          ),
          // DEV: Pipeline Health Check
          Material(
            type: MaterialType.transparency,
            child: IconButton(
              tooltip: 'Pipeline Health (DEV)',
              onPressed: _checkPipelineHealth,
              icon: const Icon(Icons.health_and_safety),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: IconButton(
              tooltip: 'Re-run',
              onPressed: (recordingId.isEmpty || rerunning) ? null : _rerun,
              icon: rerunning
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const BrandGradientBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: AppSpacing.screenPadding(context).add(
                    EdgeInsets.only(bottom: AppSpacing.base(context) * 0.75),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Live status header
                        SVNCard(
                          child: Builder(
                            builder: (context) {
                              final status = _recordingStatus;
                              final row = _recordingRow;
                              final createdRaw = (row?['created_at'] ?? '').toString();
                              final created = DateTime.tryParse(createdRaw)?.toLocal();
                              final step = mapStatusToStep(status);
                              final showSummarizeAction =
                                  (status.toLowerCase() == 'transcribing' || status.toLowerCase() == 'error') &&
                                      summary == null &&
                                      !summarizing;

                              return LayoutBuilder(
                                builder: (context, statusConstraints) {
                                  final base = AppSpacing.base(context);

                                  Widget buildStatusLabel() {
                                    return Wrap(
                                      spacing: base * 0.5,
                                      runSpacing: base * 0.25,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          'Status',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: SVNTheme.textMuted),
                                        ),
                                        statusui.StatusChip(status: status),
                                      ],
                                    );
                                  }

                                  List<Widget> buildActions() {
                                    final actions = <Widget>[];
                                    if (showSummarizeAction) {
                                      actions.add(
                                        FilledButton.icon(
                                          onPressed: _summarize,
                                          icon: const Icon(Icons.auto_awesome, size: 18),
                                          label: Text(
                                            status.toLowerCase() == 'error' ? 'Retry' : 'Summarize',
                                          ),
                                        ),
                                      );
                                    }
                                    if (summarizing) {
                                      actions.add(
                                        SizedBox(
                                          width: base * 3,
                                          child: const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return actions;
                                  }

                                  final actions = buildActions();
                                  final isCompact = statusConstraints.maxWidth < 400;

                                  if (actions.isEmpty) {
                                    return buildStatusLabel();
                                  }

                                  if (isCompact) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        buildStatusLabel(),
                                        AppSpacing.v(context, 0.5),
                                        Wrap(
                                          spacing: base * 0.5,
                                          runSpacing: base * 0.25,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: actions,
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: buildStatusLabel(),
                                        ),
                                      ),
                                      Wrap(
                                        spacing: base * 0.5,
                                        runSpacing: base * 0.25,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        alignment: WrapAlignment.end,
                                        children: actions,
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),

                      AppSpacing.v(context, 1),

                      // Summary body
                      if (summary == null) ...[
                        GlassCard(
                          child: Text(
                            'Processing… When complete, your summary and notes will appear here.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ] else ...[
                        // Title
                        Text((summary!['title'] ?? 'Summary').toString(),
                            style: Theme.of(context).textTheme.titleLarge),
                        AppSpacing.v(context, 0.75),

                        // Summary text
                        GlassCard(
                          child: Text((summary!['summary'] ?? '—').toString(),
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        AppSpacing.v(context, 1),

                        // Bullets (if present)
                        if (summary!['bullets'] is List &&
                            (summary!['bullets'] as List).isNotEmpty) ...[
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Key Points', style: Theme.of(context).textTheme.titleMedium),
                                AppSpacing.v(context, 0.5),
                                for (final b in (summary!['bullets'] as List))
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: AppSpacing.base(context) * 0.25),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('•  '),
                                        Expanded(child: Text(b.toString())),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          AppSpacing.v(context, 1),
                        ],

                        // Action items
                        if (summary!['action_items'] is List &&
                            (summary!['action_items'] as List).isNotEmpty) ...[
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Action Items', style: Theme.of(context).textTheme.titleMedium),
                                AppSpacing.v(context, 0.5),
                                for (final a in (summary!['action_items'] as List))
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: AppSpacing.base(context) * 0.25),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('✓  '),
                                        Expanded(child: Text(a.toString())),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          AppSpacing.v(context, 1),
                        ],
                      ],

                      // Raw notes
                      Text('Raw Notes', style: Theme.of(context).textTheme.titleLarge),
                      AppSpacing.v(context, 0.75),
                      _rawNotesCard(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _rawNotesCard() {
     final controller = Get.find<RecordingSummaryController>();
     return Obx(() => GlassCard(
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           if (controller.saving.value) 
             Padding(
               padding: EdgeInsets.only(bottom: AppSpacing.base(context) * 0.5),
               child: Text(
                 'Saving…',
                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
                   color: Theme.of(context).colorScheme.primary,
                 ),
               ),
             ),
           TextField(
             key: const Key('notes_editor'),
             controller: TextEditingController.fromValue(
               TextEditingValue(
                 text: controller.notes.value, 
                 selection: TextSelection.collapsed(offset: controller.notes.value.length)
               ),
             ),
             onChanged: controller.onNotesChanged,
             minLines: 2,
             maxLines: 8,
             textInputAction: TextInputAction.newline,
             decoration: const InputDecoration(
               hintText: 'Add your notes…',
               border: OutlineInputBorder(borderSide: BorderSide.none),
               filled: true,
             ),
           ),
           AppSpacing.v(context, 0.5),
           Text(
             controller.saving.value ? 'Saving…' : 'Saved automatically',
             style: Theme.of(context).textTheme.bodySmall?.copyWith(
                   color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                 ),
           ),
         ],
       ),
     ));
   }

  Future<void> _emailDocx() async {
    final client = Supabase.instance.client;
    
    // Use currentSession; optional refresh
    final session = client.auth.currentSession;
    String? token = session?.accessToken;

    if (token == null && session?.refreshToken != null) {
      try {
        await client.auth.refreshSession();
        token = client.auth.currentSession?.accessToken;
      } catch (_) {
        // ignore; fallback to sign-in required
      }
    }

    if (token == null) {
      Get.snackbar('Sign in required', 'Please sign in to email this summary.');
      return;
    }
    
    setState(() => _sendingDocx = true);
    
    const kFnEmailDocx = 'sv_email_summary_docx';
    
    try {
      // Get summaryId if available from the summary data
      String? latestSummaryId;
      if (summary != null && summary!['id'] != null) {
        latestSummaryId = summary!['id'].toString();
      }
      
      debugPrint('[EMAIL_DOCX] invoking $kFnEmailDocx rec=$recordingId sum=$latestSummaryId');
      final resp = await client.functions.invoke(
        kFnEmailDocx,
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'recordingId': recordingId,          // existing screen variable
          'summaryId': latestSummaryId,        // include if available; else omit
        },
      );
      final data = resp.data as Map?;
      final ok = data?['ok'] == true;
      final msgId = data?['id'];
      Get.snackbar(ok ? 'Sent' : 'Failed',
        ok ? 'Check your inbox. ID: $msgId' : '${resp.data}');
    } catch (e) {
      Get.snackbar('Failed', '$e');
    } finally {
      setState(() => _sendingDocx = false);
    }
  }
}

class _ExpandableTextCard extends StatefulWidget {
  final String title;
  final String text;
  final int previewChars;
  const _ExpandableTextCard({
    required this.title, 
    required this.text, 
    this.previewChars = 280
  });

  @override
  State<_ExpandableTextCard> createState() => _ExpandableTextCardState();
}

class _ExpandableTextCardState extends State<_ExpandableTextCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final shown = expanded || widget.text.length <= widget.previewChars
        ? widget.text
        : widget.text.substring(0, widget.previewChars) + '…';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => Clipboard.setData(ClipboardData(text: widget.text)),
              ),
            ],
          ),
          AppSpacing.v(context, 0.5),
          Text(shown),
          if (widget.text.length > widget.previewChars) ...[
            AppSpacing.v(context, 0.5),
            TextButton(
              onPressed: () => setState(() => expanded = !expanded),
              child: Text(expanded ? 'Collapse' : 'Expand'),
            ),
          ],
        ],
      ),
    );
  }
}