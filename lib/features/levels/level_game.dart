import 'package:flutter/material.dart';

import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';

/// A named group of consecutive levels (e.g. "Dawn", levels 1-12).
class LevelChapter {
  const LevelChapter({
    required this.name,
    required this.first,
    required this.last,
    required this.tint,
  });

  final String name;
  final int first;
  final int last;
  final Color tint;

  bool contains(int level) => level >= first && level <= last;
}

/// What a running level can use from the host screen.
class LevelHost {
  const LevelHost({
    required this.audio,
    required this.haptics,
    required this.level,
    required this.reduceMotion,
    this.colorblind = false,
    this.fastPour = false,
    required this.onSolved,
    required this.onRestart,
  });

  final AudioService audio;
  final HapticService haptics;
  final int level;
  final bool reduceMotion;

  /// Draw symbols on colours (Settings > Look > Colour-blind symbols).
  final bool colorblind;

  /// Quicker pour animation in Still Waters.
  final bool fastPour;

  /// Call exactly once when the puzzle is finished. [note] is shown on the
  /// completion card (e.g. "You met a fox.").
  final void Function({String? note}) onSolved;

  /// Ask the host to rebuild this level from scratch.
  final VoidCallback onRestart;
}

/// A calm game made of numbered levels. Shown on the home screen.
abstract class LevelGameModule {
  String get id;
  String get title;
  String get tagline;
  String get howToPlay;
  IconData get icon;
  List<Color> get gradient;
  List<LevelChapter> get chapters;

  /// Background music while this game is open. The same calm track plays
  /// everywhere so it never restarts when you move between screens.
  MusicId get music => MusicId.calm;

  int get levelCount => chapters.last.last;

  LevelChapter chapterOf(int level) => chapters.firstWhere(
    (c) => c.contains(level),
    orElse: () => chapters.last,
  );

  /// Small decorative preview for cards and the level map header.
  Widget buildThumbnail(BuildContext context);

  /// The playable level. Must call [LevelHost.onSolved] when finished.
  Widget buildLevel(BuildContext context, LevelHost host);
}

/// Registry of the games shown on Home, in display order.
class LevelGames {
  LevelGames._();
  static final List<LevelGameModule> _games = [];

  static List<LevelGameModule> get all => List.unmodifiable(_games);

  static void register(LevelGameModule game) {
    if (_games.any((g) => g.id == game.id)) return;
    _games.add(game);
  }

  static LevelGameModule? byId(String id) {
    for (final g in _games) {
      if (g.id == id) return g;
    }
    return null;
  }
}
