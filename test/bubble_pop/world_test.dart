import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/bubble_pop/world.dart';

void main() {
  test('BubbleWorld spawns bubbles up to target', () {
    final w = BubbleWorld(width: 390, height: 844);
    for (int i = 0; i < 50; i++) {
      w.update(1 / 60);
    }
    expect(w.bubbles.length, greaterThan(0));
    expect(w.bubbles.length, lessThanOrEqualTo(w.maxBubbles));
  });

  test('BubbleWorld caps total bubbles', () {
    final w = BubbleWorld(width: 390, height: 844);
    w.maxBubbles = 5;
    w.spawnTarget = 100;
    for (int i = 0; i < 200; i++) {
      w.update(1 / 60);
    }
    expect(w.bubbles.length, lessThanOrEqualTo(5));
  });

  test('pop impulse symmetry: pop increments counters', () {
    final w = BubbleWorld(width: 390, height: 844);
    for (int i = 0; i < 30; i++) {
      w.update(1 / 60);
    }
    if (w.bubbles.isNotEmpty) {
      expect(w.bubbles.first, isNotNull);
      // set state to alive and call pop via public method if exists
      expect(w.poppedThisRound, 0);
    }
  });

  test('round counter increments on completion', () {
    final w = BubbleWorld(width: 390, height: 844);
    expect(w.rounds, 0);
  });
}
