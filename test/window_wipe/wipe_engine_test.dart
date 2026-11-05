import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:calmcorner/features/games/window_wipe/wipe_engine.dart';

void main() {
  test('DirtGrid stamping reduces dirt', () {
    final g = DirtGrid(cellSize: 8, maskScale: 1);
    g.ensureSize(const Size(100, 100));
    final before = g.getProgress();
    g.applyStamp(const Offset(50, 50), 20, 1.0, 0.5, 1.0);
    final after = g.getProgress();
    expect(after > before, true);
  });

  test('DirtGrid reset restores full dirt', () {
    final g = DirtGrid(cellSize: 8, maskScale: 1);
    g.ensureSize(const Size(100, 100));
    g.applyStamp(const Offset(50, 50), 20, 1.0, 0.5, 1.0);
    g.reset();
    expect(g.getProgress(), closeTo(0, 1e-6));
  });

  test('DirtGrid mask = 1 - dirt', () {
    final g = DirtGrid(cellSize: 8, maskScale: 1);
    g.ensureSize(const Size(64, 64));
    g.applyStamp(const Offset(32, 32), 16, 1.0, 0.4, 1.0);
    for (int i = 0; i < g.dirt.length; i++) {
      expect((g.mask[i] - (1 - g.dirt[i])).abs() < 1e-6, true);
    }
  });

  test('DirtGrid round-trips bytes', () {
    final g = DirtGrid(cellSize: 8, maskScale: 1);
    g.ensureSize(const Size(64, 64));
    g.applyStamp(const Offset(32, 32), 16, 1.0, 0.4, 1.0);
    final bytes = g.toBytes();
    final g2 = DirtGrid(cellSize: 8, maskScale: 1);
    g2.ensureSize(const Size(64, 64));
    g2.fromBytes(bytes);
    expect(g2.getProgress(), closeTo(g.getProgress(), 1e-3));
  });
}
