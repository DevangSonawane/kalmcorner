import 'dart:math' as math;

/// Channel directions as bits.
class Dir {
  Dir._();
  static const int n = 1;
  static const int e = 2;
  static const int s = 4;
  static const int w = 8;
  static const List<int> all = [n, e, s, w];

  static int opposite(int d) => switch (d) {
    n => s,
    e => w,
    s => n,
    _ => e,
  };

  static (int, int) delta(int d) => switch (d) {
    n => (0, -1),
    e => (1, 0),
    s => (0, 1),
    _ => (-1, 0),
  };
}

/// Rotate a channel mask 90 degrees clockwise [times] times.
int rotateMask(int mask, int times) {
  var m = mask;
  for (var i = 0; i < (times % 4 + 4) % 4; i++) {
    m = ((m << 1) | (m >> 3)) & 15;
  }
  return m;
}

int bitCount(int m) {
  var c = 0;
  for (final d in Dir.all) {
    if (m & d != 0) c++;
  }
  return c;
}

/// A Garden Streams puzzle: a grid of channel tiles plus a spring.
class StreamPuzzle {
  StreamPuzzle({
    required this.cols,
    required this.rows,
    required this.solution,
    required this.rotations,
    required this.source,
  });

  final int cols;
  final int rows;

  /// Solved channel mask for each cell (row-major).
  final List<int> solution;

  /// Current clockwise quarter turns applied to each solved tile.
  final List<int> rotations;

  /// Index of the spring tile.
  final int source;

  int get length => cols * rows;

  int maskAt(int i) => rotateMask(solution[i], rotations[i]);

  StreamPuzzle copy() => StreamPuzzle(
    cols: cols,
    rows: rows,
    solution: solution,
    rotations: List<int>.from(rotations),
    source: source,
  );

  void rotate(int i) => rotations[i] = (rotations[i] + 1) % 4;

  /// Is tile [i] in an orientation that matches the generated solution?
  bool isAligned(int i) => maskAt(i) == solution[i];

  /// Cells that receive water from the spring.
  Set<int> watered() {
    final seen = <int>{source};
    final queue = <int>[source];
    while (queue.isNotEmpty) {
      final i = queue.removeLast();
      final x = i % cols, y = i ~/ cols;
      final m = maskAt(i);
      for (final d in Dir.all) {
        if (m & d == 0) continue;
        final (dx, dy) = Dir.delta(d);
        final nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) continue;
        final j = ny * cols + nx;
        if (seen.contains(j)) continue;
        if (maskAt(j) & Dir.opposite(d) == 0) continue;
        seen.add(j);
        queue.add(j);
      }
    }
    return seen;
  }

  /// Every tile watered. Because the tiles form a spanning tree, this also
  /// means there are no leaking channel ends.
  bool get isSolved => watered().length == length;
}

class GardenStreamsLevels {
  GardenStreamsLevels._();

  static const int levelCount = 60;

  static (int cols, int rows) sizeFor(int level) {
    const table = <(int, int, int)>[
      // (last level, cols, rows)
      (4, 3, 3),
      (8, 3, 4),
      (12, 4, 4),
      (18, 4, 5),
      (24, 5, 5),
      (30, 5, 6),
      (36, 6, 6),
      (42, 6, 7),
      (48, 6, 8),
      (54, 7, 8),
      (60, 7, 9),
    ];
    for (final (last, c, r) in table) {
      if (level <= last) return (c, r);
    }
    return (7, 9);
  }

  /// Deterministic puzzle for [level] (1-based).
  static StreamPuzzle build(int level) {
    final (cols, rows) = sizeFor(level);
    final rng = math.Random(level * 4099 + 17);
    final source = (rows ~/ 2) * cols + cols ~/ 2;
    final solution = _spanningTree(cols, rows, source, rng);

    final rotations = List<int>.filled(cols * rows, 0);
    final p = StreamPuzzle(
      cols: cols,
      rows: rows,
      solution: solution,
      rotations: rotations,
      source: source,
    );
    // Scramble until at least half the tiles that can turn are off.
    for (var attempt = 0; attempt < 50; attempt++) {
      var turnable = 0, off = 0;
      for (var i = 0; i < p.length; i++) {
        rotations[i] = rng.nextInt(4);
        if (_symmetric(solution[i])) continue;
        turnable++;
        if (!p.isAligned(i)) off++;
      }
      if (off * 2 >= turnable && !p.isSolved) break;
    }
    return p;
  }

  /// Straight-through tiles look the same after a half turn and crosses
  /// look the same after any turn.
  static bool _symmetric(int mask) => bitCount(mask) == 4;

  /// "Growing tree" spanning tree. Cells keep at most three channels so
  /// every tile is interesting to rotate.
  static List<int> _spanningTree(
    int cols,
    int rows,
    int start,
    math.Random rng,
  ) {
    for (var maxDeg = 3; maxDeg <= 4; maxDeg++) {
      final mask = List<int>.filled(cols * rows, 0);
      final visited = List<bool>.filled(cols * rows, false);
      final active = <int>[start];
      visited[start] = true;
      var count = 1;
      while (active.isNotEmpty) {
        // Mix newest-first (long winding streams) with random (branches).
        final k = rng.nextDouble() < 0.55
            ? active.length - 1
            : rng.nextInt(active.length);
        final c = active[k];
        final cx = c % cols, cy = c ~/ cols;
        final options = <int>[];
        if (bitCount(mask[c]) < maxDeg) {
          for (final d in Dir.all) {
            final (dx, dy) = Dir.delta(d);
            final nx = cx + dx, ny = cy + dy;
            if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) continue;
            if (!visited[ny * cols + nx]) options.add(d);
          }
        }
        if (options.isEmpty) {
          active.removeAt(k);
          continue;
        }
        final d = options[rng.nextInt(options.length)];
        final (dx, dy) = Dir.delta(d);
        final n = (cy + dy) * cols + (cx + dx);
        mask[c] |= d;
        mask[n] |= Dir.opposite(d);
        visited[n] = true;
        active.add(n);
        count++;
      }
      if (count == cols * rows) return mask;
    }
    throw StateError('could not build spanning tree');
  }
}
