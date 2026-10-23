import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_store.dart';
import 'match_models.dart';

const int kMaxHistory = 100;

// Plain (non-generated) provider on purpose: no build_runner step needed.
final historyProvider =
    NotifierProvider<HistoryNotifier, List<HistoryEntry>>(HistoryNotifier.new);

class HistoryNotifier extends Notifier<List<HistoryEntry>> {
  late final Future<void> _ready = _load();
  bool _disposed = false;

  @override
  List<HistoryEntry> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_ready); // start loading saved history
    return const [];
  }

  Future<void> _load() async {
    final loaded = await LocalStore.loadHistory();
    if (_disposed) return;
    state = loaded;
  }

  void _persist() => unawaited(LocalStore.saveHistory(state));

  Future<void> add(String label, MatchResult result) async {
    await _ready; // never overwrite history that is still loading
    if (_disposed) return;
    final entry = HistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: label,
      createdAt: DateTime.now(),
      status: 'saved',
      result: result,
    );
    state = [entry, ...state].take(kMaxHistory).toList();
    _persist();
  }

  void setStatus(String id, String status) {
    state = [for (final e in state) e.id == id ? e.copyWith(status: status) : e];
    _persist();
  }

  void rename(String id, String label) {
    state = [for (final e in state) e.id == id ? e.copyWith(label: label) : e];
    _persist();
  }

  void remove(String id) {
    state = [for (final e in state) if (e.id != id) e];
    _persist();
  }

  void restore(HistoryEntry entry, int index) {
    final list = [...state];
    final at = index < 0 ? 0 : (index > list.length ? list.length : index);
    list.insert(at, entry);
    state = list;
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }
}
