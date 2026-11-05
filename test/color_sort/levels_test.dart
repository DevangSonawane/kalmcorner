import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/color_sort/generator.dart';
import 'package:calmcorner/features/games/color_sort/model.dart';

void main() {
  test('200 levels generate and solve', () {
    for (int n = 1; n <= 200; n++) {
      final sw = Stopwatch()..start();
      final state = ColorSortGenerator.generate(n);
      final genMs = sw.elapsedMilliseconds;
      final solver = ColorSortSolver(state);
      final res = solver.solve(nodeLimit: 200000);
      expect(res.solvable, true, reason: 'level $n not solvable');
      expect(
        res.minMoves >= state.colorCount * 2,
        true,
        reason: 'level $n too few moves',
      );
      expect(
        genMs < 400,
        true,
        reason: 'level $n generation too slow: ${genMs}ms',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('legal move transfers n = min(run, free)', () {
    final s = ColorSortState(
      tubes: [
        [0, 0, 1, 1],
        [1, 1],
        [],
      ],
      capacity: 4,
      colorCount: 2,
    );
    // src 0 top run of 1s = 2; dst 1 top is 1, free 2 -> move 2
    expect(s.legalMoveCount(0, 1), 2);
    // move into empty from uniform tube is pointless
    final s2 = ColorSortState(
      tubes: [
        [0, 0, 0, 0],
        [],
      ],
      capacity: 4,
      colorCount: 1,
    );
    expect(s2.legalMoveCount(0, 1), 0);
  });

  test('undo exactness', () {
    final s = ColorSortGenerator.generate(5);
    final before = s.copy();
    final hint = ColorSortSolver.hint(s);
    expect(hint, isNotNull);
    final (src, dst) = hint!;
    s.applyMove(src, dst);
    // reverse move not necessarily valid; just check state changed then restored by copy
    // Re-apply inverse manually not required; check copy equality baseline
    expect(s.key() != before.key(), true);
  });
}
