import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:lashae_s_application/bootstrap_supabase.dart';
import 'package:lashae_s_application/services/recorder_service.dart';
import 'package:lashae_s_application/services/supabase_upload.dart';
import 'package:lashae_s_application/services/playback_service.dart';

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});
  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  final _rec = RecorderService();
  final _player = PlaybackService();

  Timer? _timer;
  int _seconds = 0;
  String _status = 'idle';
  String? _error;
  String? _result;

  // Inline auth (dev-only)
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  String? _authMsg;

  // Last recording state
  String? _lastLocalPath; // e.g., C:\...\svn_123.wav
  String? _lastStoragePath; // e.g., user/<uid>/<run_id>.wav
  String? _lastRunId;

  // Recent list state
  List<Map<String, dynamic>> _recent = [];
  bool _loadingList = false;

  void _startTimer() {
    setState(() => _seconds = 0);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds += 1);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _signIn() async {
    setState(() => _authMsg = null);
    try {
      final email = _emailCtrl.text.trim();
      final pw = _pwCtrl.text;
      if (email.isEmpty || pw.isEmpty) {
        throw Exception('Enter email and password');
      }
      final resp =
          await Supa.client.auth.signInWithPassword(email: email, password: pw);
      if (resp.user == null) throw Exception('Sign-in failed');
      setState(() => _authMsg = 'Signed in as ${resp.user!.email}');
      await _refreshList();
    } catch (e) {
      setState(() => _authMsg = 'Auth error: $e');
    }
  }

  Future<void> _ensureLoggedIn() async {
    if (Supa.client.auth.currentUser == null) {
      throw Exception('Not authenticated. Sign in below first.');
    }
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _result = null;
      _status = 'starting';
    });
    try {
      await _ensureLoggedIn();
      final ok = await _rec.isAvailable();
      if (!ok) throw Exception('Microphone permission not granted / available');
      await _rec.start();
      _startTimer();
      setState(() => _status = 'recording');
    } catch (e) {
      setState(() {
        _status = 'idle';
        _error = e.toString();
      });
    }
  }

  Future<void> _stop() async {
    setState(() => _status = 'stopping');
    _stopTimer();
    try {
      final res = await _rec.stop(); // file + duration + mime
      final up = await SupaUpload.uploadRecording(
        file: res.file,
        duration: res.duration,
        mime: res.mime,
      );

      setState(() {
        _status = 'idle';
        _result = 'Saved: run_id=${up.runId} path=${up.storagePath}';
        _lastLocalPath = res.file.path;
        _lastStoragePath = up.storagePath;
        _lastRunId = up.runId;
      });

      await _refreshList();
    } catch (e) {
      setState(() {
        _status = 'idle';
        _error = e.toString();
      });
    }
  }

  Future<void> _playLocal() async {
    try {
      setState(() => _error = null);
      final p = _lastLocalPath;
      if (p == null || !File(p).existsSync()) {
        throw Exception('No local recording to play.');
      }
      await _player.playLocalFile(p);
    } catch (e) {
      setState(() => _error = 'Playback error (local): $e');
    }
  }

  Future<void> _playFromCloud() async {
    try {
      setState(() => _error = null);
      final sp = _lastStoragePath;
      if (sp == null) throw Exception('No uploaded path yet.');
      await _player.playFromSupabase(sp);
    } catch (e) {
      setState(() => _error = 'Playback error (cloud): $e');
    }
  }

  Future<void> _deleteLast() async {
    try {
      setState(() {
        _error = null;
        _result = null;
      });
      final rid = _lastRunId;
      final sp = _lastStoragePath;
      if (rid == null || sp == null) throw Exception('Nothing to delete.');
      await SupaUpload.deleteRecording(runId: rid, storagePath: sp);
      setState(() {
        _result = 'Deleted: run_id=$rid';
        _lastRunId = null;
        _lastStoragePath = null;
        _lastLocalPath = null;
      });
      await _refreshList();
    } catch (e) {
      setState(() => _error = 'Delete error: $e');
    }
  }

  Future<void> _refreshList() async {
    setState(() => _loadingList = true);
    try {
      _recent = await SupaUpload.listMyRecordings(limit: 20);
    } catch (e) {
      setState(() => _error = 'List error: $e');
    } finally {
      setState(() => _loadingList = false);
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _rec.dispose();
    _player.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _status == 'recording';
    final user = Supa.client.auth.currentUser;
    final hasLast = _lastStoragePath != null && _lastRunId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('SVN Recorder Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 8),
            Text('Timer: $_seconds s'),
            const SizedBox(height: 16),

            Row(
              children: [
                ElevatedButton(
                  onPressed: isRecording ? null : _start,
                  child: const Text('Record'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isRecording ? _stop : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Stop'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _lastLocalPath != null ? _playLocal : null,
                  child: const Text('Play Last (Local)'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: hasLast ? _playFromCloud : null,
                  child: const Text('Play Last (Cloud)'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: hasLast ? _deleteLast : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete Last'),
                ),
              ],
            ),

            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_result != null)
              Text(_result!, style: const TextStyle(color: Colors.green)),
            if (_lastLocalPath != null)
              Text(_lastLocalPath!, style: const TextStyle(color: Colors.grey)),

            const Divider(height: 32),

            // Auth (dev-only)
            Text('Auth (testing only)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Current user: ${user?.email ?? "(none)"}'),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pwCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                    onPressed: _signIn, child: const Text('Sign in')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await Supa.client.auth.signOut();
                    setState(() {
                      _authMsg = 'Signed out';
                      _lastStoragePath = null;
                      _lastLocalPath = null;
                      _lastRunId = null;
                      _recent = [];
                    });
                  },
                  child: const Text('Sign out'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _refreshList,
                  child: const Text('Refresh List'),
                ),
              ],
            ),
            if (_authMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_authMsg!,
                    style: const TextStyle(color: Colors.blueGrey)),
              ),

            const Divider(height: 32),

            Row(
              children: [
                Text('My recent recordings',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 12),
                if (_loadingList) const Text('Loading...'),
              ],
            ),
            const SizedBox(height: 8),
            if (!_loadingList && _recent.isEmpty)
              const Text('No recordings yet.'),
            if (!_loadingList && _recent.isNotEmpty)
              Column(
                children: _recent.map((r) {
                  final runId = r['run_id'] as String;
                  final path = r['storage_path'] as String;
                  final durMs = (r['duration_ms'] as int?) ?? 0;
                  final secs = (durMs / 1000).toStringAsFixed(1);
                  final status = (r['status'] as String?) ?? 'uploaded';
                  return ListTile(
                    dense: true,
                    title: Text(runId,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('$path  â€”  ${secs}s  â€¢  $status'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Play (cloud)',
                          onPressed: () async {
                            setState(() {
                              _lastStoragePath = path;
                              _lastRunId = runId;
                            });
                            await _playFromCloud();
                          },
                          icon: const Icon(Icons.play_arrow),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () async {
                            setState(() => _error = null);
                            await SupaUpload.deleteRecording(
                                runId: runId, storagePath: path);
                            await _refreshList();
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
