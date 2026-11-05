import 'package:flutter/material.dart';

import 'package:calmcorner/features/levels/level_game.dart';

import 'game.dart';
import 'levels.dart';

class GardenStreamsModule extends LevelGameModule {
  @override
  String get id => 'garden_streams';

  @override
  String get title => 'Garden Streams';

  @override
  String get tagline =>
      'Turn the stones and let the spring reach every flower.';

  @override
  String get howToPlay =>
      'Tap a stone to turn it. Water flows from the spring through every '
      'channel that lines up. When every stone carries water, all the '
      'flowers bloom and the level is done.\n\n'
      'Hint turns one stone the right way for you.';

  @override
  IconData get icon => Icons.local_florist_rounded;

  @override
  List<Color> get gradient => const [Color(0xFFA8D8A0), Color(0xFF4F9C78)];

  @override
  List<LevelChapter> get chapters => const [
    LevelChapter(name: 'Seedling', first: 1, last: 12, tint: Color(0xFFF4A6B8)),
    LevelChapter(name: 'Blossom', first: 13, last: 24, tint: Color(0xFFF6B26B)),
    LevelChapter(name: 'Brook', first: 25, last: 36, tint: Color(0xFFB79DF2)),
    LevelChapter(name: 'Orchard', first: 37, last: 48, tint: Color(0xFFEF8A7A)),
    LevelChapter(
      name: 'Moonpond',
      first: 49,
      last: 60,
      tint: Color(0xFF9FB8F5),
    ),
  ];

  @override
  int get levelCount => GardenStreamsLevels.levelCount;

  @override
  Widget buildThumbnail(BuildContext context) => const _Thumb();

  @override
  Widget buildLevel(BuildContext context, LevelHost host) =>
      GardenStreamsLevel(host: host, tint: chapterOf(host.level).tint);
}

class _Thumb extends StatelessWidget {
  const _Thumb();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ThumbPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  // A tiny solved 4x3 garden.
  static const _cols = 4, _rows = 3;
  static const _n = Dir.n, _e = Dir.e, _s = Dir.s, _w = Dir.w;
  static const _masks = [
    _e, _w | _s | _e, _w | _e, _w | _s, //
    _s | _e, _n | _w | _e, _w | _s, _n | _s, //
    _n, _e, _w | _n, _n, //
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const pal = GardenPalette.light;
    final bg = Offset.zero & size;
    canvas.drawRect(
      bg,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCDE8C2), Color(0xFF8CC58F)],
        ).createShader(bg),
    );
    final t = (size.height * 0.8 / _rows).clamp(0.0, size.width * 0.8 / _cols);
    final origin = Offset(
      (size.width - t * _cols) / 2,
      (size.height - t * _rows) / 2,
    );
    for (var i = 0; i < _masks.length; i++) {
      final c = origin + Offset((i % _cols + 0.5) * t, (i ~/ _cols + 0.5) * t);
      final stone = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: t - 5, height: t - 5),
        Radius.circular(t * 0.2),
      );
      canvas.drawRRect(
        stone.shift(const Offset(0, 2)),
        Paint()..color = pal.stoneShadow,
      );
      canvas.drawRRect(stone, Paint()..color = pal.stone);
      final water = Paint()
        ..color = pal.water
        ..strokeWidth = t * 0.2
        ..strokeCap = StrokeCap.butt;
      canvas.drawCircle(c, t * 0.1, Paint()..color = pal.water);
      for (final d in Dir.all) {
        if (_masks[i] & d == 0) continue;
        final (dx, dy) = Dir.delta(d);
        canvas.drawLine(
          c,
          c + Offset(dx.toDouble(), dy.toDouble()) * (t / 2 - 2.5),
          water,
        );
      }
      if (bitCount(_masks[i]) == 1) {
        for (var k = 0; k < 5; k++) {
          final a = k / 5 * 6.283;
          canvas.drawCircle(
            c + Offset.fromDirection(a, t * 0.11),
            t * 0.08,
            Paint()..color = const Color(0xFFF4A6B8),
          );
        }
        canvas.drawCircle(
          c,
          t * 0.06,
          Paint()..color = const Color(0xFFFFE08A),
        );
      }
    }
    // Spring.
    final sc = origin + Offset(1.5 * t, 0.5 * t);
    canvas.drawCircle(sc, t * 0.22, Paint()..color = pal.waterLight);
    canvas.drawCircle(sc, t * 0.15, Paint()..color = pal.water);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
