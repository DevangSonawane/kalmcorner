import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/garden_streams/levels.dart';

void main() {
  test('rotateMask turns channels clockwise', () {
    expect(rotateMask(Dir.n, 1), Dir.e);
    expect(rotateMask(Dir.w, 1), Dir.n);
    expect(rotateMask(Dir.n | Dir.e, 2), Dir.s | Dir.w);
    expect(rotateMask(Dir.n | Dir.e, 4), Dir.n | Dir.e);
  });

  test('every level is a scrambled, solvable spanning tree', () {
    for (var l = 1; l <= GardenStreamsLevels.levelCount; l++) {
      final p = GardenStreamsLevels.build(l);
      final (c, r) = GardenStreamsLevels.sizeFor(l);
      expect(p.cols, c);
      expect(p.rows, r);
      expect(p.isSolved, isFalse, reason: 'level $l starts solved');

      // Channels in the solution are mutual and form a tree (n-1 edges).
      var halfEdges = 0;
      for (var i = 0; i < p.length; i++) {
        final m = p.solution[i];
        expect(m, isNot(0), reason: 'level $l tile $i has no channel');
        for (final d in Dir.all) {
          if (m & d == 0) continue;
          halfEdges++;
          final (dx, dy) = Dir.delta(d);
          final x = i % p.cols + dx, y = i ~/ p.cols + dy;
          expect(x >= 0 && y >= 0 && x < p.cols && y < p.rows, isTrue);
          expect(p.solution[y * p.cols + x] & Dir.opposite(d), isNot(0));
        }
      }
      expect(halfEdges, 2 * (p.length - 1), reason: 'level $l');

      // Undoing the scramble solves it.
      final solved = p.copy();
      for (var i = 0; i < solved.length; i++) {
        solved.rotations[i] = 0;
      }
      expect(solved.isSolved, isTrue, reason: 'level $l');
    }
  });

  test('levels are deterministic', () {
    final a = GardenStreamsLevels.build(23);
    final b = GardenStreamsLevels.build(23);
    expect(a.solution, b.solution);
    expect(a.rotations, b.rotations);
  });
}
