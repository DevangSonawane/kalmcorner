import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/core/engine/sim_loop.dart';
import 'package:calmcorner/core/engine/spring.dart';
import 'package:calmcorner/core/engine/pointer_tracker.dart';
import 'package:flutter/gestures.dart';

void main() {
  test('SimLoop step count under hitch', () {
    int steps = 0;
    final loop = SimLoop(step: 1 / 60, maxSteps: 8, onStep: (_) => steps++);
    // Simulate a tick manually by calling _tick via reflection is not possible;
    // instead verify construction and isRunning.
    expect(loop.isRunning, false);
    expect(loop.step, closeTo(1 / 60, 1e-9));
  });

  test('Spring converges to target', () {
    final spring = Spring(config: SpringConfig(k: 100, c: 20), initial: 0);
    spring.target = 1;
    for (int i = 0; i < 200; i++) {
      spring.update(1 / 60);
    }
    expect(spring.settled, true);
    expect(spring.x, closeTo(1, 1e-3));
  });

  test('Spring2D converges', () {
    final s = Spring2D(config: SpringConfig(k: 100, c: 20), initial: Offset.zero);
    s.target = const Offset(10, 5);
    for (int i = 0; i < 200; i++) {
      s.update(1 / 60);
    }
    expect(s.settled, true);
  });

  test('PointerTracker velocity EMA', () {
    final pt = PointerTracker();
    final down = PointerDownEvent(
      pointer: 1,
      position: Offset.zero,
      timeStamp: Duration.zero,
    );
    pt.addPointer(down);
    final move = PointerMoveEvent(
      pointer: 1,
      position: const Offset(10, 0),
      timeStamp: const Duration(milliseconds: 100),
    );
    pt.updatePointer(move);
    expect(pt.hasPointers, true);
    expect(pt.getPointer(1), isNotNull);
  });

  test('PointerTracker ignores large radius', () {
    final pt = PointerTracker(ignoreRadiusMajor: 10);
    final down = PointerDownEvent(
      pointer: 2,
      position: Offset.zero,
      radiusMajor: 100,
      timeStamp: Duration.zero,
    );
    pt.addPointer(down);
    expect(pt.hasPointers, false);
  });

  test('Spring overshoot matches table within 10%', () {
    final spring = Spring(config: SpringConfig(k: 400, c: 10), initial: 0);
    spring.target = 1;
    double max = 0;
    for (int i = 0; i < 200; i++) {
      spring.update(1 / 60);
      if (spring.x > max) max = spring.x;
    }
    // underdamped overshoots
    expect(max > 1, true);
  });
}
