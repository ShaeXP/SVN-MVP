import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/logger.dart';
import '../../../services/auth.dart';
import '../../../env.dart';
import '../home_sections.dart';

class HomeController extends GetxController {
  final _sb = Supabase.instance.client;

  final isLoading = true.obs;
  final errorText = ''.obs;

  // Data for tiles
  final inProgress = <Map<String, dynamic>>[].obs;    // recordings (transcribing/summarizing)
  final inProgressCount = 0.obs;                      // count of in-progress items
  final recentSummaries = <Map<String, dynamic>>[].obs; // summaries (latest 5)
  final actionInbox = <String>[].obs;                  // merged actionItems
  final pinnedNotes = <Map<String, dynamic>>[].obs;    // optional

  // Customization state
  final sections = <HomeSection>[ // default order
    HomeSection.welcome,
    HomeSection.quickTabs,
    HomeSection.processingSummary,
    HomeSection.recentSummaries,
    HomeSection.actionItems,
  ].obs;

  final hidden = <HomeSection>{}.obs;
  final editing = false.obs;

  StreamSubscription? _initSub;
  RealtimeChannel? _recCh;
  RealtimeChannel? _sumCh;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[DI] HomeController onInit');
    _boot();
    loadLayout();
  }

  @override
  void onClose() {
    _initSub?.cancel();
    _recCh?.unsubscribe();
    _sumCh?.unsubscribe();
    super.onClose();
  }

  Future<void> _boot() async {
    isLoading.value = true;
    errorText.value = '';
    try {
      await AuthX.devAuthIfNeeded(
        email: Env.DEV_EMAIL,
        password: Env.DEV_PASSWORD,
        enabled: Env.DEV_AUTO_AUTH,
      );
    } catch (_) {}

    if (_sb.auth.currentSession?.user == null) {
      isLoading.value = false;
      errorText.value = 'Not signed in';
      return;
    }

    _initSub = _fetchAll().asStream().listen((_) {});
    _wireRealtime();
  }

  void _wireRealtime() {
    final uid = _sb.auth.currentSession!.user.id;
    _recCh = _sb
        .channel('home-recordings-$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'recordings',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: uid),
          callback: (_) => _fetchAll(),
        )
        .subscribe();
    _sumCh = _sb
        .channel('home-summaries-$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'summaries',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'recording_id', value: '*'),
          callback: (_) => _fetchAll(),
        )
        .subscribe();
  }

  Future<void> refresh() => _fetchAll();

  Future<void> _fetchAll() async {
    isLoading.value = true;
    try {
      final uid = await AuthX.requireUserId();
      // In-progress recordings
      final rec = await _sb
          .from('recordings')
          .select('id,status,created_at')
          .eq('user_id', uid)
          .or('status.eq.transcribing,status.eq.uploading')
          .order('created_at', ascending: false)
          .limit(6);
      inProgress.assignAll((rec as List).cast<Map<String, dynamic>>());
      inProgressCount.value = inProgress.length;

      // Recent summaries
      final sums = await _sb
          .from('summaries')
          .select('id,recording_id,title,summary,tags,action_items,created_at')
          .order('created_at', ascending: false)
          .limit(5);
      final sumList = (sums as List).cast<Map<String, dynamic>>();
      recentSummaries.assignAll(sumList);

      // Action inbox: merge & dedupe action_items[] from last 10 summaries
      final sums10 = await _sb
          .from('summaries')
          .select('action_items')
          .order('created_at', ascending: false)
          .limit(10);
      final merged = <String>{};
      for (final m in (sums10 as List)) {
        final ai = (m['action_items'] ?? []) as List<dynamic>;
        for (final v in ai) {
          final s = (v ?? '').toString().trim();
          if (s.isNotEmpty) merged.add(s);
        }
      }
      actionInbox.assignAll(merged.take(5).toList());

      // Pinned notes (if table exists). Optional—fail silently.
      try {
        final notes = await _sb
            .from('notes')
            .select('id,recording_id,text,created_at')
            .eq('pinned', true)
            .order('created_at', ascending: false)
            .limit(5);
        pinnedNotes.assignAll((notes as List).cast<Map<String, dynamic>>());
      } catch (_) {
        pinnedNotes.clear();
      }

      isLoading.value = false;
    } catch (e) {
      logx('[HOME] fetch fail: ${e.toString()}', tag: 'HOME');
      errorText.value = e.toString();
      isLoading.value = false;
    }
  }

  // Customization methods
  static String _prefsKey(String uid) => 'home_layout_$uid';

  Future<void> loadLayout() async {
    try {
      final uid = _sb.auth.currentUser?.id ?? 'local';
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey(uid));
      if (raw == null) return;
      final map = Map<String, dynamic>.from(jsonDecode(raw));
      final ord = (map['order'] as List).cast<String>();
      final hid = (map['hidden'] as List).cast<String>();
      sections
        ..clear()
        ..addAll(ord.map((s) => HomeSection.values.firstWhere((e) => e.name == s, orElse: () => HomeSection.welcome)));
      hidden
        ..clear()
        ..addAll(hid.map((s) => HomeSection.values.firstWhere((e) => e.name == s, orElse: () => HomeSection.actionItems)));
    } catch (e) {
      debugPrint('[HOME] Failed to load layout: $e');
    }
  }

  Future<void> saveLayout() async {
    try {
      final uid = _sb.auth.currentUser?.id ?? 'local';
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'order': sections.map((e) => e.name).toList(),
        'hidden': hidden.map((e) => e.name).toList(),
      });
      await prefs.setString(_prefsKey(uid), payload);
    } catch (e) {
      debugPrint('[HOME] Failed to save layout: $e');
    }
  }

  void toggleEditing() => editing.value = !editing.value;

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = sections.removeAt(oldIndex);
    sections.insert(newIndex, item);
    saveLayout();
  }

  void hideSection(HomeSection s) { 
    hidden.add(s); 
    saveLayout(); 
  }
  
  void showSection(HomeSection s) { 
    hidden.remove(s); 
    saveLayout(); 
  }
}
