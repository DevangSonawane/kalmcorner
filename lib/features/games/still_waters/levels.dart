import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:calmcorner/features/games/color_sort/colors.dart';
import 'package:calmcorner/features/games/color_sort/generator.dart'
    show ColorSortSolver;
import 'package:calmcorner/features/games/color_sort/model.dart';

/// Difficulty and layout for Still Waters levels.
class StillWatersLevels {
  StillWatersLevels._();

  static const int levelCount = 60;
  static const int capacity = 4;

  /// Palette indices ordered so that early levels use the most distinct hues.
  static const List<int> _paletteOrder = [0, 5, 2, 3, 7, 1, 4, 9, 11];

  static String symbolFor(int colorId) =>
      colorSortPalette[_paletteOrder[colorId % _paletteOrder.length]].symbol;

  static Color colorFor(int colorId) =>
      colorSortPalette[_paletteOrder[colorId % _paletteOrder.length]].hex;

  /// 3 colours for the first levels, growing to 9 by level 43.
  static int colorsFor(int level) => math.min(9, 3 + (level - 1) ~/ 7);

  static const int emptyTubes = 2;

  static final Map<int, ColorSortState> _cache = {};

  /// Deterministic, solver-checked puzzle for [level] (1-based).
  static ColorSortState build(int level) {
    final cached = _cache[level];
    if (cached != null) return cached.copy();
    final colors = colorsFor(level);
    final state = _generate(level, colors);
    _cache[level] = state.copy();
    return state;
  }

  static ColorSortState _generate(int level, int colors) {
    for (var attempt = 0; attempt < 400; attempt++) {
      final rng = math.Random(level * 7919 + attempt * 104729);
      final units = <int>[
        for (var c = 0; c < colors; c++)
          for (var i = 0; i < capacity; i++) c,
      ]..shuffle(rng);

      final tubes = <List<int>>[
        for (var c = 0; c < colors; c++)
          units.sublist(c * capacity, (c + 1) * capacity),
        for (var e = 0; e < emptyTubes; e++) <int>[],
      ];
      final state = ColorSortState(
        tubes: tubes,
        capacity: capacity,
        colorCount: colors,
      );

      if (!_isInteresting(state)) continue;
      final res = ColorSortSolver(state.copy()).solve(nodeLimit: 60000);
      if (res.solvable) return state;
    }
    // Practically unreachable; fall back to a trivially solvable layout.
    return ColorSortState(
      tubes: [
        for (var c = 0; c < colors; c++) List<int>.filled(capacity, c),
        for (var e = 0; e < emptyTubes; e++) <int>[],
      ],
      capacity: capacity,
      colorCount: colors,
    );
  }

  /// No tube may start already sorted, and not too many same-colour neighbours.
  static bool _isInteresting(ColorSortState s) {
    var pairs = 0;
    for (final t in s.tubes) {
      if (t.isEmpty) continue;
      if (t.every((c) => c == t.first)) return false;
      for (var i = 1; i < t.length; i++) {
        if (t[i] == t[i - 1]) pairs++;
      }
    }
    return pairs <= s.colorCount ~/ 2 + 1;
  }
}
