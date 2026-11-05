import 'dart:ui';

import 'scenes.dart';

enum DirtKind { fog, dust, rain, frost, mud, storm }

enum WindowShape { plain, cross, arch, round, sixPane }

class DirtStyle {
  const DirtStyle({
    required this.tint,
    required this.tintAlpha,
    required this.blur,
    required this.hardness,
    this.spots = 0,
    this.drops = false,
    this.streaks = false,
    this.crystals = false,
    this.specks = false,
  });

  final Color tint;
  final double tintAlpha;
  final double blur;

  /// Roughly how many passes a normal patch needs.
  final double hardness;

  /// Number of tough mud splats.
  final int spots;
  final bool drops;
  final bool streaks;
  final bool crystals;
  final bool specks;

  static DirtStyle of(DirtKind k) => switch (k) {
    DirtKind.fog => const DirtStyle(
      tint: Color(0xFFF2F5F8),
      tintAlpha: 0.55,
      blur: 10,
      hardness: 1,
    ),
    DirtKind.dust => const DirtStyle(
      tint: Color(0xFFC9BBA4),
      tintAlpha: 0.6,
      blur: 5,
      hardness: 1.3,
      specks: true,
    ),
    DirtKind.rain => const DirtStyle(
      tint: Color(0xFFD5DEE6),
      tintAlpha: 0.45,
      blur: 7,
      hardness: 1.2,
      drops: true,
      streaks: true,
    ),
    DirtKind.frost => const DirtStyle(
      tint: Color(0xFFEAF4FF),
      tintAlpha: 0.7,
      blur: 12,
      hardness: 1.8,
      crystals: true,
    ),
    DirtKind.mud => const DirtStyle(
      tint: Color(0xFFCDBFA8),
      tintAlpha: 0.4,
      blur: 4,
      hardness: 1.1,
      spots: 6,
      specks: true,
    ),
    DirtKind.storm => const DirtStyle(
      tint: Color(0xFFDDE3EA),
      tintAlpha: 0.55,
      blur: 9,
      hardness: 1.5,
      spots: 4,
      drops: true,
      streaks: true,
    ),
  };
}

class WindowLevel {
  const WindowLevel({
    required this.level,
    required this.scene,
    required this.time,
    required this.dirt,
    required this.shape,
    required this.friend,
  });

  final int level;
  final SceneKind scene;
  final DayTime time;
  final DirtKind dirt;
  final WindowShape shape;
  final FriendSpot friend;
}

class ClearWindowLevels {
  ClearWindowLevels._();

  static const int perChapter = 6;
  static const int levelCount = perChapter * 6;

  static WindowLevel build(int level) {
    final i = level - 1;
    final chapter = i ~/ perChapter;
    final j = i % perChapter;
    final scene = SceneKind.values[(j + chapter) % SceneKind.values.length];
    const times = DayTime.values;
    // Rain and storm look best in moody light; frost likes dawn and night.
    final time = switch (DirtKind.values[chapter]) {
      DirtKind.rain ||
      DirtKind.storm => j.isEven ? DayTime.dusk : DayTime.night,
      _ => times[(j + chapter * 3) % times.length],
    };
    return WindowLevel(
      level: level,
      scene: scene,
      time: time,
      dirt: DirtKind.values[chapter],
      shape: WindowShape.values[(i * 3 + chapter) % WindowShape.values.length],
      friend: ScenePainter.friendFor(scene, i ~/ SceneKind.values.length),
    );
  }

  static double aspect(WindowShape s) => switch (s) {
    WindowShape.plain => 0.74,
    WindowShape.cross => 0.72,
    WindowShape.arch => 0.66,
    WindowShape.round => 1.0,
    WindowShape.sixPane => 0.64,
  };
}
