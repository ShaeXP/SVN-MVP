import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lashae_s_application/app/routes/app_routes.dart';
import 'package:lashae_s_application/ui/visuals/brand_background.dart';
import 'package:lashae_s_application/presentation/navigation/app_bar.dart';
import 'package:lashae_s_application/services/upload_service.dart';
import 'package:lashae_s_application/services/pipeline_service.dart';
import 'package:lashae_s_application/data/recording_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../env.dart';

class UploadRecordingScreen extends StatefulWidget {
  const UploadRecordingScreen({super.key});

  @override
  State<UploadRecordingScreen> createState() => _UploadRecordingScreenState();
}

class _UploadRecordingScreenState extends State<UploadRecordingScreen> {
  final _upload = UploadService();
  final _pipe = PipelineService();
  final _repo = RecordingRepo();

  bool _busy = false;
  String? _status;
  String? _trace;
  double _progress = 0.0;
  String? _selectedFileName;
  bool _useDemoSample = false;

  @override
  void initState() {
    super.initState();
    // Guard: must be signed in
    if (Supabase.instance.client.auth.currentUser == null) {
      // Kick to login outside shell
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(Routes.login);
      });
    }
  }

  Future<void> _pickUploadRun() async {
    setState(() { 
      _busy = true; 
      _status = 'Select a file…'; 
      _trace = null; 
      _progress = 0.0;
      _selectedFileName = null;
    });
    
    try {
      final picked = await _upload.pickAudioOrVideo();
      if (picked == null) {
        setState(() { _busy = false; _status = 'Canceled'; });
        return;
      }

      setState(() { 
        _status = 'Uploading…'; 
        _progress = 0.1;
        _selectedFileName = picked.file.path.split('/').last;
      });

      final relative = await _upload.uploadAudio(picked.file, picked.ext);
      final fullPath = relative.startsWith('recordings/') ? relative : 'recordings/$relative';

      setState(() { 
        _status = 'Creating recording…'; 
        _progress = 0.5;
      });

      final ids = await _repo.createRecordingRow(storagePath: fullPath);
      // ids.recordingId, ids.runId now available

      setState(() { 
        _status = 'Starting pipeline…'; 
        _progress = 0.7;
      });
      
      final trace = await _pipe.runWithId(fullPath, ids.recordingId, runId: ids.runId);

      setState(() {
        _busy = false;
        _trace = trace;
        _status = 'Processing started';
        _progress = 1.0;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload complete. Pipeline started (trace: $trace).')),
      );
      // Return to Library so user can see the row update live
      Get.offNamedUntil(Routes.recordingLibrary, (r) => false, id: 1);
    } catch (e) {
      setState(() { 
        _busy = false; 
        _status = 'Error: $e'; 
        _progress = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _uploadDemoSample() async {
    setState(() { 
      _busy = true; 
      _status = 'Fetching demo sample…'; 
      _trace = null; 
      _progress = 0.0;
      _selectedFileName = 'demo_meeting_2min.m4a';
    });
    
    try {
      // Fetch demo sample from public storage
      final supabase = Supabase.instance.client;
      final demoBytes = await supabase.storage
          .from('public_redacted_samples')
          .download('demo_meeting_2min.m4a');
      
      if (demoBytes.isEmpty) {
        throw Exception('Demo sample not found in storage');
      }

      setState(() { 
        _status = 'Uploading demo sample…'; 
        _progress = 0.1;
      });

      // Create a temporary file for the demo sample
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/demo_meeting_2min.m4a');
      await tempFile.writeAsBytes(demoBytes);

      // Upload using the same flow as regular files
      final relative = await _upload.uploadAudio(tempFile, 'm4a');
      final fullPath = relative.startsWith('recordings/') ? relative : 'recordings/$relative';

      setState(() { 
        _status = 'Processing demo sample…'; 
        _progress = 0.5;
      });

      // Insert Library row and start pipeline
      final res = await _repo.createRecordingRow(storagePath: fullPath);
      final recordingId = res.recordingId;

      await _pipe.runWithId(fullPath, recordingId);

      setState(() { 
        _status = 'Demo sample uploaded successfully!'; 
        _progress = 1.0;
      });

      // Clean up temp file
      try { await tempFile.delete(); } catch (_) {}

      // Navigate to Library after a short delay
      await Future.delayed(const Duration(seconds: 1));
      Get.back();
      
    } catch (e) {
      setState(() { 
        _status = 'Demo upload failed: $e'; 
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BrandGradientBackground(),
        SafeArea(
          child: Column(
            children: [
              svnAppBar(title: 'Upload recording', back: true),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
          Text('Supported: Audio (m4a, mp3, wav, aac, flac, wma, caf, ogg) and Video (mp4, webm, mov, avi, mkv)',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text('Max file size: ${(UploadService.maxFileSizeBytes / 1024 / 1024).toStringAsFixed(0)}MB',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 16),
          // Demo sample option
          if (Env.demoMode) ...[
            CheckboxListTile(
              title: const Text('Use Demo Sample (no PII)'),
              subtitle: const Text('2-minute meeting sample from public storage'),
              value: _useDemoSample,
              onChanged: _busy ? null : (value) {
                setState(() {
                  _useDemoSample = value ?? false;
                });
              },
            ),
            const SizedBox(height: 8),
          ],
          
          FilledButton(
            onPressed: _busy ? null : (_useDemoSample ? _uploadDemoSample : _pickUploadRun),
            child: Text(_busy ? 'Working…' : (_useDemoSample ? 'Upload Demo Sample' : 'Select audio/video file')),
          ),
          const SizedBox(height: 16),
          
          // Progress indicator
          if (_busy && _progress > 0) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
          ],
          
          // Status and file info
          if (_status != null) ...[
            Text(_status!, 
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              )),
            const SizedBox(height: 4),
          ],
          
          if (_selectedFileName != null) ...[
            Text('File: $_selectedFileName', 
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
            const SizedBox(height: 4),
          ],
          
          if (_trace != null) 
            Text('Trace ID: $_trace', 
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
          
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
