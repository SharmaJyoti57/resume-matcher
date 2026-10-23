import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_store.dart';
import 'match_models.dart';

// Plain (non-generated) provider on purpose: no build_runner step needed.
final profileProvider =
    NotifierProvider<ProfileNotifier, CandidateProfile>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<CandidateProfile> {
  late final Future<void> _ready = _load();
  bool _disposed = false;

  @override
  CandidateProfile build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_ready); // start loading the saved profile
    return const CandidateProfile();
  }

  Future<void> _load() async {
    final loaded = await LocalStore.loadProfile();
    if (_disposed) return;
    state = loaded;
  }

  /// The profile once it has finished loading from storage.
  Future<CandidateProfile> current() async {
    await _ready;
    return state;
  }

  Future<void> save(CandidateProfile profile) async {
    await _ready; // never let a slow load overwrite what the user just saved
    if (_disposed) return;
    state = profile;
    await LocalStore.saveProfile(profile);
  }
}
