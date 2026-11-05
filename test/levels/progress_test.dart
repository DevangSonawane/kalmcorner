import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calmcorner/core/persistence/prefs_store.dart';
import 'package:calmcorner/features/levels/level_progress.dart';

void main() {
  test('progress unlocks the next level and survives a reload', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LevelProgressStore(await PrefsStore.create());
    var p = store.read('g');
    expect(p.unlockedUpTo, 1);
    expect(p.isUnlocked(2), isFalse);

    await store.markDone('g', 1);
    await store.markDone('g', 2);
    p = LevelProgressStore(await PrefsStore.create()).read('g');
    expect(p.completed, {1, 2});
    expect(p.nextLevel(60), 3);
    expect(p.isUnlocked(3), isTrue);
    expect(p.isUnlocked(4), isFalse);
    expect(store.read('other').completed, isEmpty);
  });

  test('next level is capped at the last level', () async {
    SharedPreferences.setMockInitialValues({
      'levels.g.done': [for (var i = 1; i <= 60; i++) '$i'],
    });
    final p = LevelProgressStore(await PrefsStore.create()).read('g');
    expect(p.nextLevel(60), 60);
  });
}
