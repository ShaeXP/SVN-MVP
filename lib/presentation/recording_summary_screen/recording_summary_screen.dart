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
import '../../ui/util/pipeline_step.dart';
import '../../ui/widgets/svn_card.dart';
import '../../ui/app_spacing.dart';
import '../../ui/widgets/recording_error_panel.dart';
import '../../services/connectivity_service.dart';
import '../../services/recording_delete_service.dart';
import '../home_screen/controller/home_controller.dart';
import '../library/library_controller.dart';
import '../../domain/summaries/summary_style.dart';
import '../../models/summary_style_option.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/summary_navigation.dart';

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
  String _searchQuery = '';
  final TextEditingController _questionController = TextEditingController();
  final List<_NoteQaItem> _qaItems = [];

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
    
    // Check offline state
    final connectivity = ConnectivityService.instance;
    if (connectivity.isOffline.value) {
      if (mounted) {
        safeSnackBar(
          title: 'Offline',
          message: 'Please reconnect to finish this step.',
        );
      }
      return;
    }
    
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
    
    // Check offline state
    final connectivity = ConnectivityService.instance;
    if (connectivity.isOffline.value) {
      if (mounted) {
        safeSnackBar(
          title: 'Offline',
          message: 'Please reconnect to finish this step.',
        );
      }
      return;
    }
    
    setState(() {
      rerunning = true;
    });
    try {
      // TODO: Implement pipeline retry hook for this recording
      // For now, use existing rerun logic
      await pipe.rerunByRecordingId(recordingId);
      await _loadSummary();
    } catch (e) {
      debugPrint('Failed to rerun: $e');
      if (mounted) {
        safeSnackBar(
          title: 'Retry Failed',
          message: 'Could not retry processing. Please try again later.',
        );
      }
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
        title: const Text('Delete summary?'),
        content: const Text(
          'This will remove this recording and its summary from your library. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Perform deletion via edge function
        await RecordingDeleteService().deleteRecording(recordingId);
        
        // Refresh HomeController and LibraryController to keep lists in sync
        if (Get.isRegistered<HomeController>()) {
          final homeController = Get.find<HomeController>();
          await homeController.refresh();
        }
        if (Get.isRegistered<LibraryController>()) {
          final libraryController = Get.find<LibraryController>();
          await libraryController.fetch();
        }
        
        // Pop back to previous screen after successful delete
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
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
           (status == 'transcribing' || status == 'summarizing' || status == 'ready' || status == 'processing') && summary == null;
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
    _questionController.dispose();
    super.dispose();
  }

  bool _matchesQuery(String text) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    return text.toLowerCase().contains(q);
  }

  TextSpan _buildHighlightedSpan(String text, TextStyle baseStyle) {
    final q = _searchQuery.trim();
    if (q.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final query = q.toLowerCase();
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lower.indexOf(query, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        }
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: baseStyle.copyWith(fontWeight: FontWeight.w600),
      ));
      start = index + query.length;
    }

    return TextSpan(children: spans);
  }

  List<String> _collectNoteLines() {
    if (summary == null) return const [];
    final s = summary!;
    final lines = <String>[];

    final title = (s['title'] ?? '').toString();
    if (title.trim().isNotEmpty) {
      lines.add(title);
    }

    final main = (s['summary'] ?? '').toString();
    if (main.trim().isNotEmpty) {
      lines.addAll(main.split('\n'));
    }

    if (s['bullets'] is List) {
      for (final b in (s['bullets'] as List)) {
        final t = b.toString();
        if (t.trim().isNotEmpty) {
          lines.add(t);
        }
      }
    }

    if (s['action_items'] is List) {
      for (final a in (s['action_items'] as List)) {
        final t = a.toString();
        if (t.trim().isNotEmpty) {
          lines.add(t);
        }
      }
    }

    return lines;
  }

  void _onAskQuestion() {
    final query = _questionController.text.trim();
    if (query.isEmpty || summary == null) return;

    final qLower = query.toLowerCase();

    // Tokenize and remove simple stopwords
    final tokenPattern = RegExp(r'[^a-z0-9]+');
    final rawTokens = qLower.split(tokenPattern);
    const stopwords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'who',
      'what',
      'when',
      'where',
      'why',
      'how',
      'is',
      'are',
      'was',
      'were',
      'to',
      'of',
      'in',
      'on',
      'for',
      'with',
      'this',
      'that',
    };

    final keywords = rawTokens
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && !stopwords.contains(t))
        .toList();

    final effectiveKeywords = keywords.isEmpty ? [qLower] : keywords;

    final lines = _collectNoteLines();
    final scored = <_ScoredLine>[];

    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final lower = t.toLowerCase();
      int score = 0;
      for (final kw in effectiveKeywords) {
        if (lower.contains(kw)) {
          score++;
        }
      }
      if (score > 0) {
        scored.add(_ScoredLine(text: t, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final topMatches = scored.take(5).toList();

    String answer;
    if (topMatches.isEmpty) {
      answer = 'I couldn\'t find anything in this note that mentions "$query".';
    } else {
      final buffer = StringBuffer();
      buffer.writeln('Here\'s what this note says related to your question:');
      buffer.writeln();
      for (final m in topMatches) {
        buffer.writeln('• ${m.text}');
      }
      answer = buffer.toString().trim();
    }

    setState(() {
      _qaItems.insert(0, _NoteQaItem(question: query, answer: answer));
      _questionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Derive a friendly title from loaded summary data with a safe fallback
    final String appBarTitle = (() {
      final t = (summary?['title'] as String?)?.trim();
      if (t != null && t.isNotEmpty) return t;
      return 'Recording summary';
    })();

    // Show inline error state for invalid arguments
    if (hasInvalidArgs) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Recording summary'),
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
      // Match main screens: allow gradient to paint behind the app bar area
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        title: Text(
          appBarTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: BackButton(
          onPressed: () {
            goToLibraryRoot();
          },
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
          Builder(
            builder: (context) {
              final canDelete = _recordingStatus == 'ready' || _recordingStatus == 'error';
              return Material(
                type: MaterialType.transparency,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: (recordingId.isEmpty || !canDelete) ? null : () => _deleteRecording(context),
                ),
              );
            },
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

                      // Error panel for failed recordings
                      if (_recordingStatus.toLowerCase() == 'error')
                        RecordingErrorPanel(
                          recordingId: recordingId,
                          onRetry: () {
                            // Stub method - will be implemented when backend retry logic is ready
                            _rerun();
                          },
                        ),

                      if (_recordingStatus.toLowerCase() == 'error')
                        AppSpacing.v(context, 1),

                      // Local search within this summary
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search in this note...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          isDense: true,
                        ),
                      ),
                      AppSpacing.v(context, 0.75),

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
                        Builder(
                          builder: (context) {
                            final titleText = (summary!['title'] ?? 'Summary').toString();
                            final baseStyle = Theme.of(context).textTheme.titleLarge ??
                                Theme.of(context).textTheme.titleMedium ??
                                const TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
                            return RichText(
                              text: _buildHighlightedSpan(titleText, baseStyle),
                            );
                          },
                        ),
                        AppSpacing.v(context, 0.75),

                        // Style label
                        Builder(builder: (_) {
                          // Read summary_style_key, summary_style, or summaryStyle (for backward compatibility)
                          final key = (summary!['summary_style_key'] ?? summary!['summary_style'] ?? summary!['summaryStyle'] ?? 'quick_recap_action_items').toString();
                          final styleOption = SummaryStyles.byKey(key);
                          final label = styleOption.label;
                          debugPrint('[SUMMARY_VIEW] id=${summary!['id']} styleKey=$key, label=$label');
                          return Text('Style: $label',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ));
                        }),
                        AppSpacing.v(context, 0.5),

                        // Summary text
                        GlassCard(
                          child: Builder(
                            builder: (context) {
                              final summaryText = (summary!['summary'] ?? '—').toString();
                              final baseStyle = Theme.of(context).textTheme.bodyMedium ??
                                  const TextStyle(fontSize: 14);
                              return RichText(
                                text: _buildHighlightedSpan(summaryText, baseStyle),
                              );
                            },
                          ),
                        ),
                        AppSpacing.v(context, 1),

                        // Bullets (if present)
                        if (summary!['bullets'] is List &&
                            (summary!['bullets'] as List).isNotEmpty) ...[
                          Builder(
                            builder: (context) {
                              final allBullets = (summary!['bullets'] as List)
                                  .map((b) => b.toString())
                                  .toList();
                              final visibleBullets = _searchQuery.trim().isEmpty
                                  ? allBullets
                                  : allBullets.where(_matchesQuery).toList();

                              if (visibleBullets.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Key Points', style: Theme.of(context).textTheme.titleMedium),
                                    AppSpacing.v(context, 0.5),
                                    for (final b in visibleBullets)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: AppSpacing.base(context) * 0.25),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('•  '),
                                            Expanded(
                                              child: Builder(
                                                builder: (context) {
                                                  final baseStyle =
                                                      Theme.of(context).textTheme.bodyMedium ??
                                                          const TextStyle(fontSize: 14);
                                                  return RichText(
                                                    text: _buildHighlightedSpan(b, baseStyle),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          AppSpacing.v(context, 1),
                        ],

                        // Action items
                        if (summary!['action_items'] is List &&
                            (summary!['action_items'] as List).isNotEmpty) ...[
                          Builder(
                            builder: (context) {
                              final allActions = (summary!['action_items'] as List)
                                  .map((a) => a.toString())
                                  .toList();
                              final visibleActions = _searchQuery.trim().isEmpty
                                  ? allActions
                                  : allActions.where(_matchesQuery).toList();

                              if (visibleActions.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Action Items', style: Theme.of(context).textTheme.titleMedium),
                                    AppSpacing.v(context, 0.5),
                                    for (final a in visibleActions)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: AppSpacing.base(context) * 0.25),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('✓  '),
                                            Expanded(
                                              child: Builder(
                                                builder: (context) {
                                                  final baseStyle =
                                                      Theme.of(context).textTheme.bodyMedium ??
                                                          const TextStyle(fontSize: 14);
                                                  return RichText(
                                                    text: _buildHighlightedSpan(a, baseStyle),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          AppSpacing.v(context, 1),
                        ],
                      ],

                      // Ask-a-question section (local, this-note only)
                      Builder(
                        builder: (context) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ask a question about this note',
                                style: AppTextStyles.sectionTitle(context),
                              ),
                              AppSpacing.v(context, 0.25),
                              Text(
                                'We’ll answer using only this note’s transcript and summary.',
                                style: AppTextStyles.bodySecondary(context),
                              ),
                              AppSpacing.v(context, 0.75),
                              GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _questionController,
                                            onSubmitted: (_) => _onAskQuestion(),
                                            decoration: const InputDecoration(
                                              hintText: 'Ask a question about this note...',
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.send),
                                          tooltip: 'Ask',
                                          onPressed: _onAskQuestion,
                                        ),
                                      ],
                                    ),
                                    if (_qaItems.isNotEmpty) ...[
                                      AppSpacing.v(context, 0.75),
                                      for (final item in _qaItems.take(3)) ...[
                                        Text(
                                          'You',
                                          style: AppTextStyles.bodySecondary(context),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceVariant
                                                .withValues(alpha: 0.8),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: Text(item.question),
                                        ),
                                        AppSpacing.v(context, 0.5),
                                        Text(
                                          'Answer',
                                          style: AppTextStyles.bodySecondary(context),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface
                                                .withValues(alpha: 0.9),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: Text(item.answer),
                                        ),
                                        AppSpacing.v(context, 0.75),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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
                    selection: TextSelection.collapsed(offset: controller.notes.value.length),
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
          'recordingId': recordingId, // existing screen variable
          'summaryId': latestSummaryId, // include if available; else omit
        },
      );
      final data = resp.data as Map?;
      final ok = data?['ok'] == true;
      final msgId = data?['id'];
      Get.snackbar(ok ? 'Sent' : 'Failed', ok ? 'Check your inbox. ID: $msgId' : '${resp.data}');
    } catch (e) {
      Get.snackbar('Failed', '$e');
    } finally {
      setState(() => _sendingDocx = false);
    }
  }
}

class _NoteQaItem {
  final String question;
  final String answer;

  _NoteQaItem({required this.question, required this.answer});
}

class _ScoredLine {
  final String text;
  final int score;

  _ScoredLine({required this.text, required this.score});
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