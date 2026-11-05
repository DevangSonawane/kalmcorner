import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:calmcorner/core/persistence/prefs_store.dart';
import 'package:calmcorner/core/providers.dart';

import 'level_game.dart';

/// Saved progress for one level game.
class GameProgress {
  const GameProgress({required this.completed, required this.lastPlayed});

  final Set<int> completed;
  final int lastPlayed;

  /// Levels are unlocked one past the furthest completed level.
  int get unlockedUpTo {
    var max = 0;
    for (final l in completed) {
      if (l > max) max = l;
    }
    return max + 1;
  }

  bool isUnlocked(int level) => level <= unlockedUpTo;
  bool isDone(int level) => completed.contains(level);

  /// The level the "Continue" button should open.
  int nextLevel(int levelCount) {
    final next = unlockedUpTo;
    return next > levelCount ? levelCount : next;
  }
}

/// Stores level progress in SharedPreferences under `levels.<gameId>.*`.
class LevelProgressStore {
  LevelProgressStore(this._store);
  final PrefsStore _store;

  String _doneKey(String id) => 'levels.$id.done';
  String _lastKey(String id) => 'levels.$id.last';

  GameProgress read(String gameId) {
    final raw = _store.getStringList(_doneKey(gameId)) ?? const [];
    final done = <int>{};
    for (final s in raw) {
      final n = int.tryParse(s);
      if (n != null && n > 0) done.add(n);
    }
    return GameProgress(
      completed: done,
      lastPlayed: _store.getInt(_lastKey(gameId)) ?? 1,
    );
  }

  Future<void> markDone(String gameId, int level) async {
    final p = read(gameId);
    final done = {...p.completed, level}.toList()..sort();
    await _store.setStringList(_doneKey(gameId), [for (final l in done) '$l']);
  }

  Future<void> setLastPlayed(String gameId, int level) =>
      _store.setInt(_lastKey(gameId), level);
}

final levelProgressStoreProvider = Provider<LevelProgressStore>(
  (ref) => LevelProgressStore(ref.watch(prefsStoreProvider)),
);

/// Bumped whenever progress changes so screens rebuild.
final progressVersionProvider = NotifierProvider<_Version, int>(_Version.new);

class _Version extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final gameProgressProvider = Provider.family<GameProgress, String>((ref, id) {
  ref.watch(progressVersionProvider);
  return ref.watch(levelProgressStoreProvider).read(id);
});

/// One star per finished level, across every game on Home.
final totalStarsProvider = Provider<int>((ref) {
  ref.watch(progressVersionProvider);
  final store = ref.watch(levelProgressStoreProvider);
  var total = 0;
  for (final g in LevelGames.all) {
    total += store.read(g.id).completed.length;
  }
  return total;
});
