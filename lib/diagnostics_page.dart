import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'env.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});
  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  String _net = 'Idle';
  String _asr = 'Idle';
  String _llm = 'Idle';

  Future<bool> _online() async {
    final c = await Connectivity().checkConnectivity();
    final ok = c.contains(ConnectivityResult.mobile) ||
        c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.ethernet);
    setState(() => _net = ok ? 'Online' : 'Offline');
    return ok;
  }

  Future<void> _pingASR() async {
    if (!await _online()) return;
    final dg = Env.deepgramKey;
    final aa = Env.assemblyKey;
    if ((dg == null || dg.isEmpty) && (aa == null || aa.isEmpty)) {
      setState(() => _asr = 'Missing ASR key');
      return;
    }
    setState(() => _asr = 'Pinging…');

    try {
      final audio = await http.readBytes(Uri.parse(
          'https://static.radioparadise.com/static/test-audio/short.mp3'));

      if (dg != null && dg.isNotEmpty) {
        final r = await http.post(
          Uri.parse('https://api.deepgram.com/v1/listen?smart_format=true'),
          headers: {
            'Authorization': 'Token $dg',
            'Content-Type': 'audio/mpeg'
          },
          body: audio,
        );
        setState(() => _asr = r.statusCode < 300
            ? 'OK (${r.statusCode})'
            : 'ERR ${r.statusCode}: ${r.body}');
        return;
      }

      final up = await http.post(
        Uri.parse('https://api.assemblyai.com/v2/upload'),
        headers: {'authorization': aa!},
        body: audio,
      );
      setState(() => _asr = up.statusCode < 300
          ? 'Upload OK'
          : 'ERR ${up.statusCode}: ${up.body}');
    } catch (e) {
      setState(() => _asr = 'Error: $e');
    }
  }

  Future<void> _pingLLM() async {
    if (!await _online()) return;
    final oa = Env.openaiKey;
    final orKey = Env.openrouterKey;
    if ((oa == null || oa.isEmpty) && (orKey == null || orKey.isEmpty)) {
      setState(() => _llm = 'Missing LLM key');
      return;
    }
    setState(() => _llm = 'Pinging…');

    try {
      final isOpenAI = oa != null && oa.isNotEmpty;
      final url = isOpenAI
          ? Uri.parse('https://api.openai.com/v1/chat/completions')
          : Uri.parse('https://openrouter.ai/api/v1/chat/completions');

      final headers = {
        'Authorization': 'Bearer ${isOpenAI ? oa! : orKey!}',
        'Content-Type': 'application/json',
        if (!isOpenAI) 'HTTP-Referer': 'https://smartvoicenotes.dev',
        if (!isOpenAI) 'X-Title': 'SVN Diagnostics',
      };

      final body = json.encode({
        'model': isOpenAI ? 'gpt-4o-mini' : 'openrouter/auto',
        'messages': [
          {'role': 'user', 'content': 'Reply with the single word: PONG'}
        ],
        'max_tokens': 5,
        'temperature': 0.2
      });

      final sw = Stopwatch()..start();
      final r = await http.post(url, headers: headers, body: body);
      sw.stop();

      if (r.statusCode >= 300) {
        setState(() => _llm = 'ERR ${r.statusCode}: ${r.body}');
      } else {
        final ok = r.body.toLowerCase().contains('pong');
        setState(() =>
            _llm = ok ? 'OK in ${sw.elapsedMilliseconds} ms' : 'Unexpected response');
      }
    } catch (e) {
      setState(() => _llm = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics (dev only)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ENV: ${Env.appEnv} • max=${Env.maxSummaryTokens}'),
            const SizedBox(height: 12),
            _Row(label: 'Network', value: _net, onTap: _online),
            const SizedBox(height: 12),
            _Row(label: 'ASR', value: _asr, onTap: _pingASR),
            const SizedBox(height: 12),
            _Row(label: 'LLM', value: _llm, onTap: _pingLLM),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Future<void> Function() onTap;
  const _Row(
      {required this.label, required this.value, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 82,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(value)),
        const SizedBox(width: 12),
        ElevatedButton(onPressed: () => onTap(), child: const Text('Ping')),
      ],
    );
  }
}
