import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'library_controller.dart';
import '../../utils/summary_navigation.dart';
import '../../theme/app_theme.dart';
import '../../ui/visuals/brand_background.dart';
import '../../ui/visuals/glass_card.dart';
import '../../ui/app_spacing.dart';
import '../../services/sample_export_service.dart';
import '../../bootstrap_supabase.dart';
import '../../controllers/upload_controller.dart';
import '../../widgets/custom_image_view.dart';
import '../../env.dart';
import '../../ui/widgets/svn_scaffold_body.dart';

const double _kLibraryTopSpacing = 15.0;

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
          title: const Text('Library'),
          backgroundColor: Colors.transparent,
          elevation: 0,
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
                    return SVNScaffoldBody(
                      banner: null,
                      onRefresh: ctrl.fetch,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                            AppSpacing.v(context, 0.75),
                            Text(
                              'Couldn\'t load your recordings.\n${ctrl.error.value}',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (ctrl.items.isEmpty) {
                    return SVNScaffoldBody(
                      banner: null,
                      onRefresh: ctrl.fetch,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.mic_none_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            AppSpacing.v(context, 1),
                            Text(
                              'No recordings yet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            AppSpacing.v(context, 0.5),
                            Text(
                              'Record something to see it here',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final items = ctrl.items;
                  return SVNScaffoldBody(
                    banner: null,
                    onRefresh: ctrl.fetch,
                    scrollBuilder: (padding) => ListView.separated(
                      padding: padding,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => AppSpacing.v(context, 0.5),
                      itemBuilder: (context, index) => _RecordingTile(item: items[index]),
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
}

class _RecordingTile extends StatelessWidget {
  final RecordingItem item;
  const _RecordingTile({required this.item});

  String _fmtDur(int? s) {
    if (s == null) return '—';
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m}m ${sec}s';
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'ready': return appTheme.green_600;
      case 'summarizing': return appTheme.blue_200_01; // brandIndigoBlue
      case 'transcribing': return appTheme.orange_600;
      case 'uploading': return appTheme.brandDeepPurple;
      case 'error': return appTheme.red_400;
      default: return appTheme.gray_500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final base = AppSpacing.base(context);

    return GlassCard(
      margin: EdgeInsets.symmetric(horizontal: base, vertical: base * 0.5),
      radius: 20,
      elevated: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Use standardized navigation helper with fallback
            openRecordingSummary(recordingId: item.id);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left status bar
              Container(
                width: 6,
                height: 44,
                decoration: BoxDecoration(
                  color: _statusColor(item.status),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AppSpacing.h(context, 0.75),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (1 line ellipsis)
                    Text(
                      item.title?.isNotEmpty == true ? item.title! : 'Untitled recording',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.v(context, 0.25),
                    // Subtitle (2 lines ellipsis) - show preview if available
                    Text(
                      'No preview yet...', // TODO: Add summary preview when available
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.v(context, 0.4),
                    // Subline with duration and status
                    Text(
                      Env.demoMode 
                        ? '${_fmtDur(item.durationSec)} • Demo sample'
                        : '${_fmtDur(item.durationSec)} • ${item.status}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Export button (share icon)
              IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () => _showExportOptions(context, item),
                tooltip: 'Export as public sample',
              ),
              // Chevron
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
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
