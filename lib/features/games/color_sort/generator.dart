import 'dart:math' as math;

import 'model.dart';

class _Rng {
  _Rng(this.seed) : _r = math.Random(seed);
  final int seed;
  final math.Random _r;
  void shuffle<T>(List<T> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = _r.nextInt(i + 1);
      final t = list[i];
      list[i] = list[j];
      list[j] = t;
    }
  }
}

class ColorSortGenerator {
  static ColorSortState generate(int n) {
    int colors = (3 + (n - 1) ~/ 4).clamp(3, 12);
    final cap = n <= 60 ? 4 : 5;
    final seed = n * 7919;

    for (int attempt = 0; ; attempt++) {
      final rng = _Rng(seed + attempt);
      final units = <int>[];
      for (int c = 0; c < colors; c++) {
        for (int i = 0; i < cap; i++) {
          units.add(c);
        }
      }
      rng.shuffle(units);
      final tubes = <List<int>>[];
      int idx = 0;
      for (int c = 0; c < colors; c++) {
        final tube = <int>[];
        for (int i = 0; i < cap; i++) {
          tube.add(units[idx++]);
        }
        tubes.add(tube);
      }
      tubes.add(<int>[]);
      tubes.add(<int>[]);

      final state = ColorSortState(
        tubes: tubes,
        capacity: cap,
        colorCount: colors,
      );

      bool reject = false;
      for (final t in tubes) {
        if (t.length == cap && t.isNotEmpty && t.every((x) => x == t.first)) {
          reject = true;
          break;
        }
      }
      if (reject) continue;

      bool tooEasy = true;
      for (final t in tubes) {
        if (t.isEmpty) {
          tooEasy = false;
          break;
        }
        if (t.length < 2 || t[t.length - 1] != t[t.length - 2]) {
          tooEasy = false;
          break;
        }
      }
      if (tooEasy && tubes.every((t) => t.isNotEmpty)) continue;

      final solver = ColorSortSolver(state);
      final result = solver.solve(nodeLimit: 200000);
      if (result.solvable && result.minMoves >= colors * 2) {
        return state;
      }
    }
  }
}

class SolveResult {
  SolveResult({required this.solvable, required this.minMoves, this.path});
  final bool solvable;
  final int minMoves;
  final List<(int, int)>? path;
}

class ColorSortSolver {
  ColorSortSolver(this.initial);
  final ColorSortState initial;

  SolveResult solve({int nodeLimit = 200000}) {
    final visited = <String>{};
    final path = <(int, int)>[];
    int nodes = 0;
    bool found = false;
    int foundMoves = 0;
    List<(int, int)>? foundPath;

    // working state (mutated in place)
    final work = initial.copy();

    bool dfs(int depth, int prevSrc, int prevDst) {
      if (nodes > nodeLimit) return false;
      nodes++;
      if (work.isWin) {
        found = true;
        foundMoves = depth;
        foundPath = List.from(path);
        return true;
      }
      final key = work.key();
      if (visited.contains(key)) return false;
      visited.add(key);

      // collect moves
      final moves = <(int, int, int)>[];
      for (int s = 0; s < work.tubes.length; s++) {
        for (int d = 0; d < work.tubes.length; d++) {
          if (s == d) continue;
          final n = work.legalMoveCount(s, d);
          if (n <= 0) continue;
          if (s == prevDst && d == prevSrc) continue;
          final srcTube = work.tubes[s];
          final dstTube = work.tubes[d];
          if (dstTube.isEmpty && work.isUniformFull(srcTube)) continue;
          int prio = 3;
          if (dstTube.length + n == work.capacity && srcTube.length - n == 0) {
            prio = 1;
          } else if (dstTube.isNotEmpty) {
            prio = 2;
          }
          moves.add((prio, s, d));
        }
      }
      moves.sort((a, b) => a.$1.compareTo(b.$1));

      for (final m in moves) {
        final s = m.$2, d = m.$3;
        final n = work.legalMoveCount(s, d);
        if (n <= 0) continue;
        // apply
        final color = work.tubes[s].last;
        for (int i = 0; i < n; i++) {
          work.tubes[s].removeLast();
        }
        for (int i = 0; i < n; i++) {
          work.tubes[d].add(color);
        }
        path.add((s, d));
        if (dfs(depth + 1, s, d)) return true;
        path.removeLast();
        // undo
        for (int i = 0; i < n; i++) {
          work.tubes[d].removeLast();
        }
        for (int i = 0; i < n; i++) {
          work.tubes[s].add(color);
        }
      }
      return false;
    }

    final ok = dfs(0, -1, -1);
    if (ok && found) {
      return SolveResult(solvable: true, minMoves: foundMoves, path: foundPath);
    }
    return SolveResult(solvable: false, minMoves: 0);
  }

  static (int, int)? hint(ColorSortState state) {
    final solver = ColorSortSolver(state);
    final res = solver.solve(nodeLimit: 200000);
    if (res.path != null && res.path!.isNotEmpty) return res.path!.first;
    return null;
  }
}
