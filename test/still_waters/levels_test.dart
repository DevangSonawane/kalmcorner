import 'package:flutter_test/flutter_test.dart';
import 'package:calmcorner/features/games/color_sort/generator.dart';
import 'package:calmcorner/features/games/still_waters/levels.dart';

void main() {
  test('all 60 Still Waters levels are solvable and deterministic', () {
    final sw = Stopwatch()..start();
    for (var l = 1; l <= StillWatersLevels.levelCount; l++) {
      final s = StillWatersLevels.build(l);
      expect(s.tubes.length, StillWatersLevels.colorsFor(l) + 2);
      expect(s.isWin, isFalse, reason: 'level $l starts solved');
      final res = ColorSortSolver(s.copy()).solve(nodeLimit: 200000);
      expect(res.solvable, isTrue, reason: 'level $l');
    }
    // ignore: avoid_print
    print('generated 60 levels in ${sw.elapsedMilliseconds} ms');
    final a = StillWatersLevels.build(17).key();
    final b = StillWatersLevels.build(17).key();
    expect(a, b);
  });
}
