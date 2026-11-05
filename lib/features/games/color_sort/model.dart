import 'dart:math' as math;

/// Color Sort game model (spec section 9.1).
class ColorSortState {
  ColorSortState({
    required this.tubes,
    required this.capacity,
    required this.colorCount,
  });

  final List<List<int>> tubes; // each tube: list of color ids bottom->top
  final int capacity;
  final int colorCount;

  ColorSortState copy() {
    return ColorSortState(
      tubes: [for (final t in tubes) List<int>.from(t)],
      capacity: capacity,
      colorCount: colorCount,
    );
  }

  bool isUniformFull(List<int> tube) {
    if (tube.length != capacity) return false;
    if (tube.isEmpty) return false;
    return tube.every((c) => c == tube.first);
  }

  bool get isWin {
    for (final t in tubes) {
      if (t.isEmpty) continue;
      if (!isUniformFull(t)) return false;
    }
    return true;
  }

  /// Legal move src->dst transfers run of top color, limited by free space.
  /// Returns number moved, or 0 if illegal.
  int legalMoveCount(int src, int dst) {
    if (src < 0 || src >= tubes.length) return 0;
    if (dst < 0 || dst >= tubes.length) return 0;
    if (src == dst) return 0;
    if (tubes[src].isEmpty) return 0;
    if (tubes[dst].isNotEmpty && tubes[dst].last != tubes[src].last) return 0;
    if (tubes[dst].length >= capacity) return 0;
    // run length of top color in src
    final color = tubes[src].last;
    int run = 0;
    for (int i = tubes[src].length - 1; i >= 0; i--) {
      if (tubes[src][i] == color) {
        run++;
      } else {
        break;
      }
    }
    final free = capacity - tubes[dst].length;
    final n = math.min(run, free);
    // pointless move: moving a fully uniform tube into an empty tube
    if (tubes[dst].isEmpty && isUniformFull(tubes[src])) return 0;
    return n;
  }

  bool applyMove(int src, int dst) {
    final n = legalMoveCount(src, dst);
    if (n <= 0) return false;
    final color = tubes[src].last;
    for (int i = 0; i < n; i++) {
      tubes[src].removeLast();
    }
    for (int i = 0; i < n; i++) {
      tubes[dst].add(color);
    }
    return true;
  }

  String key() {
    final parts = <String>[];
    for (final t in tubes) {
      parts.add(t.join(','));
    }
    parts.sort();
    return parts.join('|');
  }
}
