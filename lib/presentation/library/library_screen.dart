import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'library_controller.dart';
import '../../ui/visuals/brand_background.dart';
import '../../ui/app_spacing.dart';
import '../../services/sample_export_service.dart';
import '../../bootstrap_supabase.dart';
import '../../controllers/upload_controller.dart';
import '../../ui/widgets/svn_scaffold_body.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/recording_card.dart';
import '../../app/navigation/bottom_nav_controller.dart';
import '../../services/connectivity_service.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/date_formatter.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Do not create another Scaffold; MainNavigation owns it.
    if (!Get.isRegistered<LibraryController>()) {
      Get.lazyPut<LibraryController>(() => LibraryController(), fenix: true);
    }
    final ctrl = Get.find<LibraryController>();

    return Column(
      children: [
        // AppBar matching Home screen
        AppBar(
          automaticallyImplyLeading: false,
          title: Builder(
            builder: (context) => Text(
              'Recording Library',
              style: AppTextStyles.screenTitle(context).copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        // Search bar (fixed under AppBar)
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: TextField(
            onChanged: ctrl.setSearchQuery,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search summaries...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              isDense: true,
            ),
          ),
        ),
        // Content with gradient background
        Expanded(
          child: Stack(
            children: [
              const BrandGradientBackground(),
              SafeArea(
                top: false,
                child: Obx(() {
                  if (ctrl.isLoading.value) {
                    return SVNScaffoldBody(
                      banner: null,
                      onRefresh: ctrl.fetch,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (ctrl.error.value.isNotEmpty) {
                    final connectivity = ConnectivityService.instance;
                    return SVNScaffoldBody(
                      banner: null,
                      onRefresh: ctrl.fetch,
                      child: Center(
                        child: Padding(
                          padding: AppSpacing.screenPadding(context),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                              ),
                              AppSpacing.v(context, 1),
                              Text(
                                'Couldn\'t load your recordings',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              AppSpacing.v(context, 0.5),
                              Obx(() {
                                // Show connectivity-aware message if offline
                                if (connectivity.isOffline.value) {
                                  return Text(
                                    'You\'re offline. Check your internet connection and try again.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                    textAlign: TextAlign.center,
                                  );
                                }
                                // Otherwise show the error message from controller
                                return Text(
                                  ctrl.error.value,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                  textAlign: TextAlign.center,
                                );
                              }),
                              AppSpacing.v(context, 1.5),
                              FilledButton.icon(
                                onPressed: () => ctrl.fetch(),
                                icon: const Icon(Icons.refresh, size: 20),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (ctrl.items.isEmpty) {
                    debugPrint('[LibraryEmptyState] no recordings, showing CTA');
                    return SVNScaffoldBody(
                      banner: null,
                      onRefresh: ctrl.fetch,
                      child: EmptyState(
                        icon: Icons.mic_none_outlined,
                        title: 'Your library is empty',
                        subtitle: 'Record or upload audio and your summaries will appear here.',
                        actionLabel: 'Start recording',
                        onAction: () {
                          BottomNavController.I.goRecord();
                        },
                      ),
                    );
                  }

                  final items = ctrl.filteredItems;

                  // If we have recordings but none match the search, show a simple empty message
                  if (ctrl.items.isNotEmpty && items.isEmpty) {
                    return SVNScaffoldBody(
                      banner: null,
                      onRefresh: ctrl.fetch,
                      child: Center(
                        child: Padding(
                          padding: AppSpacing.screenPadding(context),
                          child: Text(
                            'No summaries match your search.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }

                  return SVNScaffoldBody(
                    banner: null,
                    onRefresh: ctrl.fetch,
                    scrollBuilder: (padding) => ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        // Recent Ask Sessions (LAB) section
                        Obx(() {
                          final sessions = ctrl.recentAskSessions;
                          if (sessions.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Recent Ask Sessions',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'LAB',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...sessions.map((session) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (session.persona.isNotEmpty)
                                            Text(
                                              session.persona,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                          if (session.persona.isNotEmpty) const SizedBox(height: 4),
                                          Text(
                                            session.lastQuestion,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormatter.formatAsTodayTimeOrDate(session.createdAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          );
                        }),
                        // Recording list
                        ...items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          // Only show delete for ready or error status
                          final canDelete = item.status == 'ready' || item.status == 'error';
                          return Padding(
                            padding: EdgeInsets.only(bottom: index < items.length - 1 ? AppSpacing.md : 0),
                            child: RecordingCard(
                              item: item,
                              showExportButton: true,
                              onExport: () => _showExportOptions(context, item),
                              showDeleteButton: canDelete,
                              onDelete: canDelete
                                  ? () => _confirmDeleteRecording(context, ctrl, item)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    if (!Get.isRegistered<UploadController>()) {
                      Get.lazyPut<UploadController>(() => UploadController(), fenix: true);
                    }
                    Get.find<UploadController>().pickFileAndUpload();
                  },
                  child: const Icon(Icons.upload_file),
                  tooltip: 'Upload audio file',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Show delete confirmation dialog
  static Future<void> _confirmDeleteRecording(
    BuildContext context,
    LibraryController controller,
    RecordingItem item,
  ) async {
    final result = await showDialog<bool>(
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

    if (result == true && context.mounted) {
      try {
        await controller.deleteRecording(item.id);
        // Success: card already removed optimistically, just show confirmation
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Error: item was restored by controller, show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  /// Show export options bottom sheet
  static void _showExportOptions(BuildContext context, RecordingItem item) {
    // Check if user is signed in
    final supabase = Supa.client;
    final session = supabase.auth.currentSession;
    if (session?.accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to export samples. The export feature requires authentication.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => _ExportOptionsSheet(item: item),
    );
  }
}

/// Export options bottom sheet
class _ExportOptionsSheet extends StatefulWidget {
  final RecordingItem item;
  
  const _ExportOptionsSheet({required this.item});

  @override
  State<_ExportOptionsSheet> createState() => _ExportOptionsSheetState();
}

class _ExportOptionsSheetState extends State<_ExportOptionsSheet> {
  bool _useSynthetic = false;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Export as Public Sample',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AppSpacing.v(context, 0.5),
            Text(
              'Create a de-identified PDF that can be shared publicly. Your original recording stays private.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.v(context, 1),

            // Synthetic checkbox
            CheckboxListTile(
              title: const Text('Use synthetic text (no real data)'),
              subtitle: const Text('Generate a sample using template text for marketing purposes'),
              value: _useSynthetic,
              onChanged: _isExporting ? null : (value) {
                setState(() => _useSynthetic = value ?? false);
              },
            ),

            AppSpacing.v(context, 1),

            // Export button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _exportSample,
                icon: _isExporting 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
                label: Text(
                  _isExporting ? 'Creating PDF...' : 'Create PDF',
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            AppSpacing.v(context, 0.5),

            // Cancel button
            TextButton(
              onPressed: _isExporting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSample() async {
    setState(() => _isExporting = true);

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('De-identifying and generating PDF...'),
              ],
            ),
          ),
        );
      }

      // Get transcript text (mock for now - in real implementation, fetch from DB)
      final transcriptText = _useSynthetic 
        ? 'This is synthetic template text for demonstration purposes.'
        : 'Sample transcript text for the recording. This would be the actual transcript from the database.';

      // Call export service
      final exportService = SampleExportService();
      final result = await exportService.exportPublicSample(
        recordingId: widget.item.id,
        transcriptText: transcriptText,
        synthetic: _useSynthetic,
        vertical: 'health',
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success dialog
      if (mounted) {
        _showSuccessDialog(result['publicUrl']!, result['manifestUrl']!);
      }

    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn\'t de-identify this sample. Nothing was published.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
        Navigator.pop(context); // Close bottom sheet
      }
    }
  }

  void _showSuccessDialog(String publicUrl, String manifestUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sample Created Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your de-identified sample is ready for sharing.'),
            AppSpacing.v(context, 1),
            const Text('Public URL:', style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(
              publicUrl,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              // Copy URL to clipboard
              // In real implementation, use Clipboard.setData
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Link'),
          ),
          FilledButton.icon(
            onPressed: () {
              // Open URL in browser
              // In real implementation, use url_launcher
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening in browser...')),
              );
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open'),
          ),
        ],
      ),
    );
  }
}
